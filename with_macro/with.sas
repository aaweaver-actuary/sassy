%macro with() / parmbuff;
   %_initialize_parameters();

   %_validate_input_arguments();

   %_parse_parameters_into_variables();

   %_generate_hash_for_iding_the_query();

   %if %_preprocessed_file_already_exists() %then %return;

   %_substitute_named_tables_with_subqueries();

   %_save_final_query_to_file();

   %_execute_final_query();

%mend;

%macro _initialize_parameters;
   %global allparams count numPairs hashFile hash finalQuery;
   %let allparams = %qsubstr(&syspbuff, 2, %length(&syspbuff) - 2);
   %let count = 1;

   %do %while(%length(%scan(&allparams, &count, |>,)) > 0);
      %let count = %eval(&count + 1);
   %end;
   %let count = %eval(&count - 1);
%mend;

%macro _validate_input_arguments;
   %if &count < 1 %then %do;
      %put ERROR: No parameters provided to %WITH_PREPROCESSOR macro.;
      %abort;
   %end;
   %if %sysfunc(mod(&count, 2)) ne 0 %then %do;
      %put ERROR: Parameters do not form valid name/definition pairs.;
      %abort;
   %end;
%mend;

%macro _parse_parameters_into_variables;
   %global numPairs;
   %let numPairs = %eval(&count / 2);

   %local i j;
   %let j = 1;
   %do i = 1 %to &numPairs;
      %global name&i sql&i;
      %let name&i = %qtrim(%scan(%scan(&allparams, &j, |>,), 1, :=));
      %let sql&i = %qtrim(%scan(%scan(&allparams, &j, |>,), 2, :=));
      %let j = %eval(&j + 1);
   %end;

   %global finalQuery;
   %let finalQuery = %qtrim(%scan(&allparams, &j, |>,));
%mend;

%macro _generate_hash_for_iding_the_query;
   filename hashfile temp;
   data _null_;
      file hashfile;
      put "&allparams";
   run;
   %global hash;
   %let hash = %sysfunc(sha256(&hashfile));
   filename hashfile clear;
   %global hashFile;
   %let hashFile = compiled_queries/&hash..sas;
%mend;

%macro _preprocessed_file_already_exists;
   %if %sysfunc(fileexist(&hashFile)) %then %do;
      %put NOTE: Preprocessed query already exists as &hashFile.;
      %if %symexist(execute) and &execute eq 1 %then %do;
         %include "&hashFile";
      %end;
      %return 1;
   %end;
   %return 0;
%mend;

%macro _substitute_named_tables_with_subqueries;
   %local currentQuery tmpQuery i;
   %let currentQuery = &finalQuery;

   %do i = &numPairs %to 1 %by -1;
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

%macro _save_final_query_to_file;
   filename outFile "&hashFile";
   data _null_;
      file outFile;
      put "proc sql;";
      put "&expandedQuery;";
      put "quit;";
   run;
   %put NOTE: Preprocessed query saved to &hashFile.;
%mend;

%macro _execute_final_query;
   %if %symexist(execute) and &execute eq 1 %then %do;
      %include "&hashFile";
   %end;
%mend;