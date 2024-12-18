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
	%put [PASS] - &testPass.|&testFailures.|&testErrors. - &message;
%end;
%else %if %eval(&condition)=0 %then %do;
	%let testFailures=%eval(&testFailures + 1);
	%put [FAIL] - &testPass.|&testFailures.|&testErrors. - &message;
%end;
%else %do;
	%let testErrors=%eval(&testErrors + 1);
	%put [ERROR] - &testPass.|&testFailures.|&testErrors. - &message.;
	%put [ERROR] - &testPass.|&testFailures.|&testErrors. - &condition. evaluates to %eval(&condition);
	%put [ERROR] - &testPass.|&testFailures.|&testErrors. - &condition. must evaluate to either 0 or 1;
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
