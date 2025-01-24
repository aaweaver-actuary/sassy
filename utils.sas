%MACRO table_exists(lib=WORK, table=);
    %local exists;
    %let exists = 0;
    %let dsid = %sysfunc(open(&lib..&table));
    %if &dsid %then %do;
        %let exists = 1;
        %let rc = %sysfunc(close(&dsid));
    %end;
    &exists
%MEND table_exists;