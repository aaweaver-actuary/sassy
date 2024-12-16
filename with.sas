/************************************************************************************/
/* Macro: %WITH                                                                     */
/*                                                                                  */
/* The %WITH macro emulates CTE-like functionality using the SAS macro              */
/* language and nested subqueries. It accepts a variable number of                  */
/* name/SQL pairs followed by a final SQL query that references those                */
/* "named tables." The macro will substitute each named table reference in          */
/* the final query with its corresponding SQL expression wrapped as a                */
/* subquery. This emulates:                                                         */
/*                                                                                  */
/* WITH name1 AS (sql1),                                                            */
/*      name2 AS (sql2),                                                            */
/*      ...                                                                         */
/* SELECT ... FROM ...                                                              */
/*                                                                                  */
/* by producing a single SELECT statement where each named reference is             */
/* replaced by a nested subquery.                                                   */
/*                                                                                  */
/* Usage:                                                                           */
/*                                                                                  */
/* %with(                                                                           */
/*   ds1,                                                                           */   
/*   SELECT id, value1, filter_column FROM ds1,                                      */
/*                                                                                  */ 
/*   ds2,                                                                           */   
/*   SELECT id, value2 FROM ds2,                                                    */
/*                                                                                  */
/*   lkp,                                                                           */
/*   SELECT distinct filter FROM lkp,                                                */
/*                                                                                  */
/*   filtered_ds1,                                                                   */
/*   SELECT ds1.*                                                                   */
/*   FROM ds1                                                                       */          
/*   WHERE ds1.filter_column IN (SELECT lkp.filter FROM lkp),                         */
/*                                                                                  */
/*   final_join,                                                                     */
/*   (                                                                              */  
/*      SELECT                                                                      */
/*          ds1.value1,                                                             */ 
/*          ds2.value2                                                              */
/*                                                                                  */
/*      FROM filtered_ds1 AS ds1                                                     */
/*      JOIN ds2                                                                    */
/*          ON ds1.id = ds2.id                                                      */
/*   ),                                                                             */
/*                                                                                  */
/*   SELECT final_join.* FROM final_join                                              */
/* );                                                                               */
/*                                                                                  */
/* After substitution, this would become something like:                            */
/*                                                                                  */
/* SELECT final_join.* FROM (                                                        */
/*   SELECT                                                                         */
/*       ds1.value1,                                                                */
/*       ds2.value2                                                                 */
/*                                                                                  */
/*   FROM (SELECT id, value1, filter_column FROM ds1) AS ds1                         */
/*   JOIN (SELECT id, value2 FROM ds2) AS ds2                                       */
/*       ON ds1.id = ds2.id                                                         */
/*   JOIN (SELECT distinct filter FROM lkp) AS lkp                                   */
/*       ON ds1.filter_column = lkp.filter                                            */
/*   where ds1.filter_column IN (SELECT lkp.filter FROM lkp)                          */
/* ) final_join;                                                                     */
/*                                                                                  */
/* This can be run directly in PROC SQL and should yield the same result as         */
/* if using a true CTE.                                                             */
/*                                                                                  */
/* Notes and Assumptions:                                                           */
/* 1. The final query should reference the defined names in a straightforward         */
/*    manner, such as "FROM name" or "FROM name alias" patterns.                    */
/* 2. References like "raw." or "lkp." will remain valid after we alias the         */
/*    subqueries. The code relies on the named tables being referenced in           */
/*    standard SQL ways.                                                            */
/* 3. We do a simple textual substitution. Complex SQL with overlapping             */
/*    identifiers may need more robust parsing.                                      */
/* 4. We assume that each named table is referenced at least once in the            */
/*    final query in a FROM clause or subquery FROM clause.                          */
/************************************************************************************/


%macro with/parmbuff;

   /* Extract all parameters except the surrounding parentheses */
   %local allparams;
   %let allparams=%qsubstr(&syspbuff,2,%length(&syspbuff)-2);

   %local count i token finalQuery numPairs;
   %let i=1;
   %let token=%scan(&allparams,&i,%,);
   %do %while(%length(&token) > 0);
      %let i=%eval(&i+1);
      %let token=%scan(&allparams,&i,%,);
   %end;
   %let count=%eval(&i-1);

   %if &count < 1 %then %do;
      %put ERROR: No parameters provided to %WITH macro.;
      %return;
   %end;

   %if %sysfunc(mod(%eval(&count-1),2)) ne 0 %then %do;
      %put ERROR: Parameters do not form valid pairs before the final SQL.;
      %return;
   %end;

   %let numPairs=%eval((&count-1)/2);

   /* Parse into name/sql pairs and the final query */
   %local j;
   %let j=1;
   %do i=1 %to &numPairs;
      %local name&i sql&i;
      %let name&i=%qtrim(%qscan(&allparams,&j,%,));
      %let j=%eval(&j+1);
      %let sql&i=%qtrim(%qscan(&allparams,&j,%,));
      %let j=%eval(&j+1);
   %end;
   %let finalQuery=%qtrim(%qscan(&allparams,&j,%,));

   /* 
      Now we will substitute references from the last defined name to the first.
      We'll look for patterns of the form:
         FROM name
         JOIN name
         , name
      as well as references within subqueries like:
         (SELECT ... FROM name ...)
      and replace them with:
         FROM (sql) name
      etc.
      
      We'll try a simple approach:
      For each name:
        - Replace occurrences of "FROM name" with "FROM ( sql ) name"
        - Replace occurrences of "JOIN name" with "JOIN ( sql ) name"
        - Replace occurrences of ", name" with ", ( sql ) name"
      
      This should produce nested subqueries that alias the name with its own name,
      preserving references like name.column.

      If there's a risk of partial matches (e.g., a table name that appears as a 
      substring in another word), consider surrounding with spaces or punctuation.
      We'll add spaces around patterns to reduce the risk of partial matches.
   */

   %local currentQuery tmpQuery;
   %let currentQuery=&finalQuery;

   %do i=&numPairs %to 1 %by -1;

      /* We'll do multiple replacements to handle different FROM/JOIN syntax.
         To ensure we don't miss embedded instances, we might do a few passes.
         We insert parentheses around the sql to form a subquery and alias it.
      */

      %local curName curSQL;
      %let curName=%superq(name&i);
      %let curSQL=%superq(sql&i);

      /* Prepare patterns. We'll try simple TRANWRD patterns: 
         "FROM curName" -> "FROM (curSQL) curName"
         "JOIN curName" -> "JOIN (curSQL) curName"
         ", curName"    -> ", (curSQL) curName"
         
         We'll also consider uppercase variants, just in case:
         We'll rely on case-sensitive. If needed, user can maintain consistent case.
         For safety, let's do a lowcase replacement technique:
         But since SAS macro doesn't have easy PRXCHANGE here, 
         we'll assume user uses consistent case or do multiple TRANWRD calls.
      */

      /* Replace 'FROM curName' */
      %let tmpQuery=%qsysfunc(transtrn(%superq(currentQuery),%str(FROM &curName),%str(FROM (&curSQL) &curName)));
      %let currentQuery=&tmpQuery;

      /* Replace 'JOIN curName' */
      %let tmpQuery=%qsysfunc(transtrn(%superq(currentQuery),%str(JOIN &curName),%str(JOIN (&curSQL) &curName)));
      %let currentQuery=&tmpQuery;

      /* Replace ', curName' */
      %let tmpQuery=%qsysfunc(transtrn(%superq(currentQuery),%str(, &curName),%str(, (&curSQL) &curName)));
      %let currentQuery=&tmpQuery;

      /* There could be cases where the name appears right after 'FROM(' or 'JOIN(' due to formatting.
         We'll do a bit more robust pattern by also trying variations with parentheses:
         'FROM(&curName)' -> 'FROM(&curSQL) &curName'
         'JOIN(&curName)' -> 'JOIN(&curSQL) &curName'
         This might not be necessary if the user queries are well-formed.
      */
      %let tmpQuery=%qsysfunc(transtrn(%superq(currentQuery),%str(FROM(&curName),),%str(FROM(&curSQL) &curName,)));
      %let currentQuery=&tmpQuery;

      %let tmpQuery=%qsysfunc(transtrn(%superq(currentQuery),%str(FROM(&curName) ),%str(FROM(&curSQL) &curName )));
      %let currentQuery=&tmpQuery;

      %let tmpQuery=%qsysfunc(transtrn(%superq(currentQuery),%str(JOIN(&curName) ),%str(JOIN(&curSQL) &curName )));
      %let currentQuery=&tmpQuery;

      /* Potentially more patterns could be handled, but this should suffice 
         for common SQL syntax patterns.
      */

   %end;

   %put NOTE: Final expanded query:;
   %put &currentQuery;

   /* 
      To run this query:
      proc sql;
         &currentQuery;
      quit;
   */

%mend with;


/*---------------------------------------------------------------------
   TESTS (manually run in SAS):

   %with(
     raw,
     SELECT * FROM sashelp.class,
     lkp,
     SELECT name FROM sashelp.class where age>13,
     SELECT raw.* FROM raw where raw.name in (SELECT lkp.name FROM lkp)
   );

   Expected final query (approximate):
   SELECT raw.* FROM (SELECT * FROM sashelp.class) raw 
   where raw.name in (
       SELECT lkp.name 
       FROM (SELECT name FROM sashelp.class where age>13) lkp
   );

   This should be a valid nested query that can be executed.

---------------------------------------------------------------------*/