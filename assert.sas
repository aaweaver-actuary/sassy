%macro create_test_summary_tbl_if_not_exists;
	%if %symexist(test_summary) %then %do;
		%put NOTE: test_summary table already exists;
	%end;
	%else %do;
		%put NOTE: Creating test_summary table;
		proc sql;
			create table WORK.test_summary (
				test_suite char(255),
				test_count num,
				test_passes num,
				test_failures num,
				test_errors num
			);
		quit;
	%end;
%mend create_test_summary_tbl_if_not_exists;

%macro insert_test_summary(test_suite, test_count, test_passes, test_failures, test_errors);
	proc sql;
		insert into WORK.test_summary
		values ("&test_suite.", &test_count., &test_passes., &test_failures., &test_errors.);
	quit;
%mend insert_test_summary;

%create_test_summary_tbl_if_not_exists;

/* %macro _check_color_support;
    %global HAS_COLOR;
    %let HAS_COLOR = 0;
    
    /* Check for common environment variables that indicate color support */
    /* %if %symexist(TERM) %then %do;
        %if %upcase(&TERM) = XTERM %then %let HAS_COLOR = 1;
        %else %if %upcase(&TERM) = XTERM-256COLOR %then %let HAS_COLOR = 1;
    %end; */
/* %mend; */ */

%macro _log_styles;
    /* Colors */
    %global LOG_GREEN LOG_RED LOG_YELLOW LOG_RESET;
    %global logPASS logFAIL logERROR;
    
    /* Define styles based on color support */
	/* %let LOG_GREEN=;
	%let LOG_RED=;
	%let LOG_YELLOW=;
	%let LOG_RESET=; */

	/* %let logPASS=&LOG_GREEN.[PASS]&LOG_RESET;
	%let logFAIL=&LOG_RED.[FAIL]&LOG_RESET;
	%let logERROR=&LOG_RED.[ERROR]&LOG_RESET; */

	%let logPASS=NOTE: [PASS];
	%let logFAIL=ERROR: [FAIL];
	%let logERROR=ERROR: [ERROR];
%mend;

%macro symbol_dne(symbol);
((%symexist(&symbol.)=0 + ("&symbol."="")) gt 0)
%mend;

%macro itit_globals;
%if %symbol_dne(testCount) %then %do;
	%global testCount;
	%let testCount=0;
%end;
%if %symbol_dne(testFailures) %then %do;
	%global testFailures;
	%let testFailures=0;
%end;
%if %symbol_dne(testErrors) %then %do;
	%global testErrors;
	%let testErrors=0;
%end;
%mend;

%macro reset_test_counts;
%global testCount testErrors testFailures;
%let testCount=0;
%let testFailures=0;
%let testErrors=0;
%mend;

%macro assertTrue(condition, message);
/*
Assert that the given condition that evaluates to either 0 
(for false) or 1 (for true) is true.

Logs a PASS if 1, FAIL if 0, and ERROR if anything else.

@param condition : Macro expression resolving to 1 for true
or 0 for false
@param message : A message that prints regardless of whether the 
test passes to identify and describe the test.
*/

%itit_globals;

%let testPass=%eval(&testCount - &testFailures);
%let testCount=%eval(&testCount + 1);

%if %eval(&condition)=1 %then %do;
	%let testPass=%eval(&testPass + 1);
	%put  &logPASS. - &testPass.|&testFailures.|&testErrors. - &message;
%end;
%else %if %eval(&condition)=0 %then %do;
	%let testFailures=%eval(&testFailures + 1);
	%put &logFAIL. - &testPass.|&testFailures.|&testErrors. - &message;
%end;
%else %do;
	%let testErrors=%eval(&testErrors + 1);
	%put &logERROR. - &testPass.|&testFailures.|&testErrors. - &message.;
	%put &logERROR. - &testPass.|&testFailures.|&testErrors. - &condition. evaluates to %eval(&condition);
	%put &logERROR. - &testPass.|&testFailures.|&testErrors. - &condition. must evaluate to either 0 or 1;
%end;
%mend;

%macro assertFalse(condition, message);
%if %eval(&condition)=0 %then %let cond=1;
%else %let cond=0;
%assertTrue(%eval(&cond.), &message.);
%mend;

%macro assertEqual(actual, expected);
%let message=Asserted that [&actual.]=[&expected.];
%assertTrue(%eval(&actual=&expected), &message.);
%mend;

%macro assertNotEqual(actual, expected);
%let message=Asserted that [&actual.]!=[&expected.];
%assertFalse(%eval(&actual=&expected), &message.);
%mend;

%MACRO test_suite(name);
	%global testSuite;
	%let testSuite=&name.;
	%put ======================>> Running unit tests for &name.;
	%reset_test_counts;
%MEND test_suite;

%MACRO test_summary;
	%put ======================>> Test Summary;
	%put ;
	%put |----------------------------------|;
	%put | &testSuite;
    %put |----------------------------------|;
	%put |----------------------------------|;
	%put | Test Count:    | &testCount;
	%put |----------------------------------|;
	%put | Test Failures: | &testFailures;
	%put |----------------------------------|;
	%put | Test Errors:   | &testErrors;
	%put |----------------------------------|;
	%put |----------------------------------|;
	%put ;
	%if &testFailures=0 and &testErrors=0 %then %put &logPASS. - All tests passed;
	%else %put &logFAIL. - Some tests failed;

	%insert_test_summary(&testSuite, &testCount, &testCount - &testFailures - &testErrors, &testFailures, &testErrors);

	%put ======================>> Test Summary [DONE];

	%put ======================>> Running unit tests for &testSuite [DONE];
%MEND test_summary;

%put ======================>> Loading assert.sas [DONE];


/* Test these assertion macros */
%MACRO test_assertions;
	%test_suite(Testing assert);

		%assertTrue(1, "1 is true");
		%assertFalse(0, "0 is false");
		%assertEqual(1, 1);
		%assertNotEqual(1, 0);

	%test_summary;
%MEND test_assertions;

%test_assertions;