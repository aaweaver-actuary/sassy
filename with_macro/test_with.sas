%include "with.sas";

%macro test_initialize_parameters;
   %local testParams expectedCount;
   %let testParams = ds1 := SELECT id FROM table |> ds2 := SELECT col FROM another |> SELECT * FROM ds1 JOIN ds2;
   %with_preprocessor(&testParams);

   %if &count ne 3 %then %put FAIL: Expected count=3 but got &count.;
   %else %put PASS: Count matches expectation.;
%mend;

%macro test_substitute_ctes_with_subqueries;
   %local testFinalQuery expectedExpanded;
   %let name1 = ds1;
   %let sql1 = SELECT id FROM table;
   %let name2 = ds2;
   %let sql2 = SELECT col FROM another;
   %let finalQuery = SELECT * FROM ds1 JOIN ds2;

   %_substitute_named_tables_with_subqueries;

   %let expectedExpanded = SELECT * FROM (SELECT id FROM table) ds1 JOIN (SELECT col FROM another) ds2;
   %if &expandedQuery ne &expectedExpanded %then %put FAIL: Expected &expectedExpanded but got &expandedQuery.;
   %else %put PASS: Query matches expectation.;
%mend;

%macro test_generate_hash;
   %let allparams = ds1 := SELECT id FROM table |> ds2 := SELECT col FROM another |> SELECT * FROM ds1 JOIN ds2;
   %_generate_hash_for_iding_the_query;

   %if %length(&hash) eq 64 %then %put PASS: Hash generated correctly.;
   %else %put FAIL: Hash generation failed.;
%mend;