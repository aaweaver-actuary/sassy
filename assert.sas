
%sbmod(sbfuncs);




%macro _log_styles;
	%global logPASS logFAIL logERROR;
	%let logPASS=NOTE: [PASS];
	%let logFAIL=ERROR: [FAIL];
	%let logERROR=ERROR: [ERROR];
%mend;

%_log_styles;

%macro symbol_dne(symbol);
	%if %symexist(%unquote(%str(&symbol.)))=0 %then %let out=1;
	%else %if "%sysfunc(strip(%unquote(%str(&symbol.))))"="" %then %let out=1;
	%else %let out=0;
	&out. 
%mend;

%macro __initAssert(verbose=0);
	%global __PRINT_ASSERTIONS_TESTS;
	%let __PRINT_ASSERTIONS_TESTS=&verbose.;

	%if &__PRINT_ASSERTIONS_TESTS.=1 %then
		%put======================>> Loading assert.sas;
%mend __initAssert;

%__initAssert;

%macro test_symbol_dne;
	%test_suite(Symbol DNE tests);

	%test_summary;
%mend test_symbol_dne;

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
	%let result=0;

	%let testPass=%eval(&testCount - &testFailures);
	%let testCount=%eval(&testCount + 1);

	%if %eval(&condition)=1 %then %do;
		%let result=1;
		%let testPass=%eval(&testPass + 1);
		%if &__PRINT_ASSERTIONS_TESTS.=1 %then %do;
			%put &logPASS. - &testPass.|&testFailures.|&testErrors. - &message;
		%end;
	%end;
	%else %if %eval(&condition)=0 %then %do;
		%let testFailures=%eval(&testFailures + 1);
		%if &__PRINT_ASSERTIONS_TESTS.=1 %then %do;
			%put &logFAIL. - &testPass.|&testFailures.|&testErrors. - &message;
		%end;
	%end;
	%else %do;
		%let result=-1;
		%let testErrors=%eval(&testErrors + 1);
		%if &__PRINT_ASSERTIONS_TESTS.=1 %then %do;
			%put &logERROR. - &testPass.|&testFailures.|&testErrors. - &message.;
			%put &logERROR. - &testPass.|&testFailures.|&testErrors. - &condition.
				evaluates to %eval(&condition);
			%put &logERROR. - &testPass.|&testFailures.|&testErrors. - &condition.
				must evaluate to either 0 or 1;
		%end;
	%end;

	%if &isCurrentlyInTestCase.=1 %then %do;
		%let testCaseCount=%eval(&testCaseCount + 1);
		%if %eval(&result=0) %then %let testCaseFailures=%eval(&testCaseFailures + 1);
		%else %if %eval(&result=-1) %then %let testCaseErrors=%eval(&testCaseErrors + 1);
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

options nonotes nosource nodetails; /* Suppress warnings that these functions were previously compiled */

proc fcmp outlib=sbfuncs.fn.assert;
	/* These subroutines are otherwise identical to the macros, but
	   are compiled	subroutines that can test data in a data step.*/
	subroutine assertTrue(condition $, message $);
	length cmd $ 32767;
		cmd=strip(cats('%nrstr(%assertTrue)(', condition, ', "', message, '")'));
	put cmd=;
	call execute(cmd);
	endsub;

	subroutine assertFalse(condition $, message $);
	length cmd $ 32767;
	cmd=cats('%nrstr(%assertFalse)(', condition, ', "', message, '")');
	put cmd=;
	call execute(cmd);
	/* call execute(cats('%nrstr(%assertFalse)(', condition, ', "', message,
	'")')); */
	endsub;

	subroutine assertEqual(actual $, expected $);
	length cmd $ 32767;
	cmd=cats('%nrstr(%assertEqual)(', actual, ', ', expected, ')');
	put cmd=;
	call execute(cmd);
	/* call execute(cats('%nrstr(%assertEqual)(', actual, ', ', expected')')); */
	endsub;

	subroutine assertNotEqual(actual $, expected $);
	length cmd $ 32767;
	cmd=cats('%nrstr(%assertNotEqual)(', actual, ', ', expected, ')');
	put cmd=;
	call execute(cmd);
	/* call execute(cats('%nrstr(%assertNotEqual)(', actual, ', ', expected')')); */
	endsub;
run;

options notes source details; 
options cmplib=sbfuncs.fn;

%macro test_suite(name);
	%global testSuite isCurrentlyInTestCase;
	%let isCurrentlyInTestCase=0;
	%let testSuite=&name.;
	%if &__PRINT_ASSERTIONS_TESTS.=1 %then 
		%put======================>> Running unit tests for &name.;
	%reset_test_counts;
%mend test_suite;

%macro test_case(title);
	%global currentTestCaseName isCurrentlyInTestCase testCaseCount testCaseFailures testCaseErrors;
	%let currentTestCaseName=&title.;

	%if &__PRINT_ASSERTIONS_TESTS.=1 %then 
		%put======================>> Running test case: [&currentTestCaseName.];

	%let isCurrentlyInTestCase=1;
	%let testCaseCount=0;
	%let testCaseFailures=0;
	%let testCaseErrors=0;
%mend test_case;

%macro test_summary;

	%if &isCurrentlyInTestCase.=1 %then %do;

		%if &__PRINT_ASSERTIONS_TESTS.=1 %then %do;

			%put======================>> Test Case Summary;
			%put ;
			%put |----------------------------------|;
			%put | &currentTestCaseName;
			%put |----------------------------------|;
			%put |----------------------------------|;
			%put | Test Count: | &testCaseCount;
			%put |----------------------------------|;
			%put | Test Failures: | &testCaseFailures;
			%put |----------------------------------|;
			%put | Test Errors: | &testCaseErrors;
			%put |----------------------------------|;
			%put |----------------------------------|;
			%put ;

		%end;

		%if &testCaseFailures=0 and &testCaseErrors=0 %then %put &logPASS. - All tests for [&currentTestCaseName.] passed;
		%else %put &logFAIL. - Some tests for [&currentTestCaseName.] failed;

		%if &__PRINT_ASSERTIONS_TESTS.=1 %then 
			%put======================>> Test Case Summary [DONE];

		%let isCurrentlyInTestCase=0;
	%end;
	%else %do;

		%if &__PRINT_ASSERTIONS_TESTS.=1 %then %do;
			%put======================>> Test Summary;
			%put ;
			%put |----------------------------------|;
			%put | &testSuite;
			%put |----------------------------------|;
			%put |----------------------------------|;
			%put | Test Count: | &testCount;
			%put |----------------------------------|;
			%put | Test Failures: | &testFailures;
			%put |----------------------------------|;
			%put | Test Errors: | &testErrors;
			%put |----------------------------------|;
			%put |----------------------------------|;
			%put ;
		%end;	

		%if &testFailures=0 and &testErrors=0 %then %put &logPASS. - All tests
			passed;
		%else %put &logFAIL. - Some tests failed;


		%if &__PRINT_ASSERTIONS_TESTS.=1 %then 	
			%put======================>> Test Summary [DONE];

	%end;
	%if &__PRINT_ASSERTIONS_TESTS.=1 %then 
		%put======================>> Running unit tests for &testSuite [DONE];
%mend test_summary;

%put======================>> Loading assert.sas [DONE];

/* Test these assertion macros */
%macro test_assertions(verbose=0);
	%global __PRINT_ASSERTIONS_TESTS;
	%if &verbose.=1 %then %let __PRINT_ASSERTIONS_TESTS=1;
	%else %let __PRINT_ASSERTIONS_TESTS=0;

	%test_suite(Testing assert);

		%test_case(Testing macro versions of assertions);
			%assertTrue(1, 1 is true);
			%assertFalse(0, 0 is false);
			%assertEqual(1, 1);
			%assertNotEqual(1, 0);

			%assertTrue(%symbol_dne(asdafasdf), 'asdafasdf' was not previously defined);

		%test_summary;

		%test_case(Testing DATA STEP versions of assertions);
			data _null_;
				length result $ 32767.;

				call assertTrue('1', "1 is true DATA STEP ASSERTIONS");
				call assertFalse('0', "0 is false");
				call assertEqual('1', '1');
				call assertNotEqual('1', '0');
			run;
		%test_summary;

	%test_summary;
%mend test_assertions;

%test_assertions;
