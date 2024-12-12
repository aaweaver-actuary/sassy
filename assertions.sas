%macro assertTrue(condition, message=, resultDir=results, debugLevel=2);
    %local rc programName resultFile timestamp headerFlag callStack;
    
    /* Step 1: Determine the calling program name */
    %if %symexist(SYSIN) and %length(&SYSIN) > 0 %then %do;
        %let programName = %scan(&SYSIN, -1, /);
    %end;
    %else %if %symexist(SYSPROCESSNAME) %then %do;
        %let programName = %scan(&SYSPROCESSNAME, -1, /);
    %end;
    %else %do;
        %let programName = unknown_program;
    %end;

    /* Step 2: Ensure result directory exists */
    %if not %sysfunc(fileexist(&resultDir)) %then %do;
        options dlcreatedir;
        libname results "&resultDir";
        libname results clear;
    %end;

    /* Step 3: Construct the result file path */
    %let resultFile = &resultDir/&programName.__testResults.txt;

    /* Step 4: Add a timestamp */
    %let timestamp = %sysfunc(datetime(), datetime20.);

    /* Step 5: Check if the result file exists */
    %let headerFlag = %sysfunc(fileexist(&resultFile));

    /* Step 6: Capture the macro call stack (debug level 2+) */
    %if &debugLevel >= 2 %then %do;
        %let callStack = %sysfunc(sysget(SAS_EXECFILENAME));
    %end;
    %else %do;
        %let callStack = -;
    %end;

    /* Step 7a: Get line to add to log */
    %let logLine = "&timestamp, %if &condition %then PASS %else FAIL, &message, &condition, &programName, &callStack";

    /* Step 7: Evaluate the condition and log results */
    filename resultFile "&resultFile";
    data _null_;
        file resultFile mod;
        /* Write header if the file does not exist */
        %if &headerFlag = 0 %then %do;
            put "Timestamp, Test Status, Message, Condition, Program, Call Stack";
        %end;
        put &logLine;
    run;

    %if not (&condition) %then %let rc = 1; /* Failure */
    %else %let rc = 0; /* Success */

    &rc
%mend;