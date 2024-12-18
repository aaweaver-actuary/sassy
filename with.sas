%include "/sas/data/project/EG/ActShared/aw/assertions.sas";

%reset_test_counts;

/************************************************************************************/
/* Macro: %WITH                                                                     */
/*                                                                                  */
/* The %WITH macro emulates CTE-like functionality using the SAS macro              */
/* language and nested subqueries. It accepts a variable number of                  */
/* name/SQL pairs followed by a final SQL query that references those               */
/* "named tables." The macro will substitute each named table reference in          */
/* the final query with its corresponding SQL expression wrapped as a               */
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
/*   ds1 := SELECT id, value1, filter_column FROM tbl1 |>                           */
/*   ds2 := SELECT id, value2 FROM tbl2 |>                                          */
/*   lkp := SELECT distinct filter_col FROM lkp |>                                  */
/*   filtered_ds1 := (                                                              */
/*       SELECT ds1.*                                                               */
/*       FROM ds1                                                                   */
/*       WHERE ds1.filter_column IN (SELECT lkp.filter FROM lkp)                    */ 
/*   ) |>                                                                           */
/*                                                                                  */
/*   final_join := (                                                                */  
/*      SELECT                                                                      */
/*          ds1.value1,                                                             */ 
/*          ds2.value2                                                              */
/*                                                                                  */
/*      FROM filtered_ds1 AS ds1                                                    */
/*      JOIN ds2                                                                    */
/*          ON ds1.id = ds2.id                                                      */
/*   ) |>                                                                           */
/*                                                                                  */
/*   SELECT final_join.* FROM final_join                                            */
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


%global verbose execute;
%let verbose=0;
%let execute=1;

%macro logger(msg, level=INFO);
%put [&level.] - &msg.;
%mend;

%macro with / parmbuff;
%if %symexist(verbose) %then %do;
	%if &verbose eq 0 %then %put verbose is turned off;
	%else %put verbose is turned on;
%end;
%else %let verbose=0;

%if verbose=1 %then %logger(Entering initialize_parameters);
   %initialize_parameters;

%if verbose=1 %then %logger(Entering validate_input_arguments);
   %validate_input_arguments;

%if verbose=1 %then %logger(Entering parse_parameters_into);
   %parse_parameters_into_variables;

%if verbose=1 %then %logger(Entering gen_hash_to_id_query);
   %gen_hash_to_id_query;

%if verbose=1 %then %logger(Entering file_already_exists);
   %if %file_already_exists %then %return;

%if verbose=1 %then %logger(Entering sub_named_with_subqueries);
   %sub_named_with_subqueries;

%if verbose=1 %then %logger(Entering save_final_query_to_file);
   %save_final_query_to_file;

%if verbose=1 %then %logger(Entering execute_final_query);
   %execute_final_query;

%mend;

%macro initialize_parameters;
   %global all_params count n_param_pairs hash_file hash final_query;
   %let all_params = %qsubstr(&syspbuff, 2, %length(&syspbuff) - 2);
   %let count = 1;

   %do %while(%length(%scan(&all_params, &count, |>,)) > 0);
      %let count = %eval(&count + 1);
   %end;
   %let count = %eval(&count - 1);
%mend;

%macro test_init_params;
   %let syspbuff = (ds1 := SELECT id, value1, filter_column FROM tbl1 |> ds2 := SELECT id, value2 FROM tbl2 |> lkp := SELECT distinct filter_col FROM lkp |> filtered_ds1 := (SELECT ds1.* FROM ds1 WHERE ds1.filter_column IN (SELECT lkp.filter FROM lkp)) |> final_join := (SELECT ds1.value1, ds2.value2 FROM filtered_ds1 AS ds1 JOIN ds2 ON ds1.id = ds2.id) |> SELECT final_join.* FROM final_join);
   %initialize_parameters;
   %assertEq(&all_params, "&syspbuff.");
   %assertEq(&count, 5);
%mend;

%test_init_params;

%macro validate_input_arguments;
   %global is_valid;
   %let is_valid = 1;
   %if &count < 1 %then %do;
      %put ERROR: No parameters provided to %WITH_PREPROCESSOR macro.;
      %let is_valid = 0;
      %abort;
   %end;
   %if %sysfunc(mod(&count, 2)) ne 1 %then %do;
      %put ERROR: Parameters do not form valid name/definition pairs.;
      %let is_valid = 0;
      %abort;
   %end;
   %if %length(%scan(&all_params, &count, |>,)) eq 0 %then %do;
      %put ERROR: No final query provided.;
      %let is_valid = 0;
      %abort;
   %end;

   &is_valid
%mend;

%macro test_validate_input_arguments;
   /*  Valid input */
   %let is_valid = 1;
   %let all_params = (ds1 := SELECT id, value1, filter_column FROM tbl1 |> ds2 := SELECT id, value2 FROM tbl2 |> lkp := SELECT distinct filter_col FROM lkp |> filtered_ds1 := (SELECT ds1.* FROM ds1 WHERE ds1.filter_column IN (SELECT lkp.filter FROM lkp)) |> final_join := (SELECT ds1.value1, ds2.value2 FROM filtered_ds1 AS ds1 JOIN ds2 ON ds1.id = ds2.id) |> SELECT final_join.* FROM final_join);
   %let count = 5;
   %assertTrue(%validate_input_arguments);

   /* Does not have final query */
   %let all_params = (ds1 := SELECT id, value1, filter_column FROM tbl1 |> ds2 := SELECT id, value2 FROM tbl2 |> lkp := SELECT distinct filter_col FROM lkp |> filtered_ds1 := (SELECT ds1.* FROM ds1 WHERE ds1.filter_column IN (SELECT lkp.filter FROM lkp)) |> final_join := (SELECT ds1.value1, ds2.value2 FROM filtered_ds1 AS ds1 JOIN ds2 ON ds1.id = ds2.id) |>);
   %let count = 4;
   %assertFalse(%validate_input_arguments);

   /* No parameters */
   %let all_params = ();
   %let count = 6;
   %assertFalse(%validate_input_arguments);

   /* Odd number of parameters */
   %let all_params = (ds1 := SELECT id, value1, filter_column FROM tbl1 |> ds2 := SELECT id, value2 FROM tbl2 |> lkp := SELECT distinct filter_col FROM lkp |> filtered_ds1 := (SELECT ds1.* FROM ds1 WHERE ds1.filter_column IN (SELECT lkp.filter FROM lkp)) |> final_join := (SELECT ds1.value1, ds2.value2 FROM filtered_ds1 AS ds1 JOIN ds2 ON ds1.id = ds2.id) |> SELECT final_join.* FROM final_join);
   %let count = 6;
   %assertFalse(%validate_input_arguments);
%mend;

%test_validate_input_arguments;

%macro parse_parameters_into_variables;
   %global n_param_pairs final_query;
   %let n_param_pairs = %eval(&count / 2);

   %local i j;
   %let j = 1;

   %do i = 1 %to &n_param_pairs;
      %global name&i sql&i;
      %let name&i = %qtrim(%qscan(%qscan(&all_params, &j, |>,), 1, :=));
      %let sql&i = %qtrim(%qscan(%qscan(&all_params, &j, |>,), 2, :=));
      %let j = %eval(&j + 1);
   %end;

   %let final_query = %qtrim(%qscan(&all_params, &j, |>,));
%mend;

%macro test_parse_params;
   %let input1=(ds1 := select * from tbl |> ids := select distinct id from tbl2 |> select * from ds1 where ds1.id in (select id from ids));
   %parse_parameters_into_variables;

   %assertEq(&n_param_pairs1, 2);
   %assertEq(&name1, ds1);
   %assertEq(&sql1, select * from tbl);
   %assertEq(&name2, ids);
   %assertEq(&sql2, select distinct id from tbl2);
   %assertEq(&final_query1, select * from ds1 where ds1.id in (select id from ids));

   %let input2=(ds1 := select * from tbl |> ids := select distinct id from tbl2 |> ds3 := select * from ds1 where ds1.id in (select id from ids) |> select * from ds3);
   %parse_parameters_into_variables;

   %assertEq(&n_param_pairs2, 3);
   %assertEq(&name1, ds1);
   %assertEq(&sql1, select * from tbl);
   %assertEq(&name2, ids);
   %assertEq(&sql2, select distinct id from tbl2);
   %assertEq(&name3, ds3);
   %assertEq(&sql3, select * from ds1 where ds1.id in (select id from ids));
   %assertEq(&final_query2, select * from ds3);

%mend;

%macro gen_hash_to_id_query;
   filename hash_file temp;
   data _null_;
      file hash_file;
      put "&all_params";
   run;
   %global hash;
   %let hash = %sysfunc(sha256(&hash_file));
   filename hash_file clear;
   %global hash_file;
   %let hash_file = &hash..sas;
/*   %let hash_file = %sysfunc(pathname(work))/&hash..sas;*/
%mend;

%macro file_already_exists;
   %if %sysfunc(fileexist(&hash_file)) %then %do;
      %put NOTE: Preprocessed query already exists as &hash_file.;
      %if %symexist(execute) and &execute eq 1 %then %do;
         %include "&hash_file";
      %end;
      %return 1;
   %end;
   %return 0;
%mend;

%macro sub_named_with_subqueries;
   %local currentQuery tmpQuery i;
   %let currentQuery = &final_query;

   %do i = &n_param_pairs %to 1 %by -1;
      %local curName curSQL;
      %let curName = %superq(name&i);
      %let curSQL = %superq(sql&i);

      /* Substitute named tables in FROM, JOIN, and comma-separated lists */
      %let tmpQuery = %qsysfunc(transtrn(&currentQuery, %str(FROM &curName), %str(FROM (&curSQL) &curName)));
      %let currentQuery = &tmpQuery;

      %let tmpQuery = %qsysfunc(transtrn(&currentQuery, %str(JOIN &curName), %str(JOIN (&curSQL) &curName)));
      %let currentQuery = &tmpQuery;

      %let tmpQuery = %qsysfunc(transtrn(&currentQuery, %str(, &curName), %str(, (&curSQL) &curName)));
      %let currentQuery = &tmpQuery;
   %end;

   %global expandedQuery;
   %let expandedQuery = &currentQuery;
%mend;

%macro save_final_query_to_file;
   filename outFile "&hash_file";
   data _null_;
      file outFile;
      put "proc sql;";
      put "&expandedQuery;";
      put "quit;";
   run;
   %put NOTE: Preprocessed query saved to &hash_file.;
%mend;

%macro execute_final_query;
   %if %symexist(execute) and &execute eq 1 %then %do;
      %include "&hash_file";
   %end;
%mend;
