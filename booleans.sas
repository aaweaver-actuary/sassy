%macro ifelse(condition, trueBlock, falseBlock);
    %if &condition %then %do;
        &trueBlock
    %end;
    %else %do;
        &falseBlock
    %end;
%mend ifelse;

%macro is_int(value);
    %ifelse(%sysfunc(inputn(&value, best32.)) = %sysfunc(round(&value)), 1, 0)
%mend is_int;

%macro is_float(value);
    %ifelse(%sysfunc(inputn(&value, best32.)) = %sysfunc(round(&value)), 0, 1)
%mend is_float;

%macro is_numeric(value);
    %ifelse(%is_int(&value) + %is_float(&value) > 0, 1, 0)
%mend is_numeric;

%macro is_date(value);
    %ifelse(%sysfunc(inputn(&value, date9.)) = ., 0, 1)
%mend is_date;

%macro is_time(value);
    %ifelse(%sysfunc(inputn(&value, time.), time.) = ., 0, 1)
%mend is_time;

%macro is_datetime(value);
    %ifelse(%sysfunc(inputn(&value, datetime.), datetime.) = ., 0, 1)
%mend is_datetime;

%macro is_temporal(value);
    %let condition = %eval(%is_date(&value) + %is_time(&value) + %is_datetime(&value));
    %ifelse(&condition. > 0, 1, 0)
%mend is_temporal;

%macro is_string(value);
    %ifelse(%is_numeric(&value) + %is_temporal(&value) > 0, 0, 1)
%mend is_string;

%macro is_positive(number);
    %local pos is_numeric condition;
    %let pos = %eval(&number > 0);
    %let is_numeric = %is_numeric(&number);
    %let condition = %eval(&pos + &is_numeric);
    %ifelse(&condition = 2, 1, 0)
%mend is_positive;