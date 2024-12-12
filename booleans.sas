
/**
 * ========
 * # ifelse
 * ========
 * Implements a ternary operator in SAS.
 *
 * @param condition - the condition to evaluate. Must evaluate to 1 or 0.
 * @param trueBlock - the block to execute if the condition is true.
 * @param falseBlock - the block to execute if the condition is false.
 * @returns datetime - the current date and time in the format ddMMMYYYY:HH:MM:SS
*/
%macro ifelse(condition, trueBlock, falseBlock);
    %if &condition %then %do;
        &trueBlock
    %end;
    %else %do;
        &falseBlock
    %end;
%mend ifelse;

/**
 * ========
 * # is_int
 * ========
 * Returns true if the value is an integer. False otherwise.
 *
 * @param value - the value to test.
 * @returns boolean - 1 if the value is an integer, 0 otherwise.
*/
%macro is_int(value);
    %ifelse(%sysfunc(inputn(&value, best32.)) = %sysfunc(round(&value)), 1, 0)
%mend is_int;

/**
 * =========
 * # is_float
 * =========
 * Returns true if the value is a numeric value that is not an integer. False otherwise.
 *
 * @param value - the value to test.
 * @returns boolean - 1 if the value is a float, 0 otherwise.
*/
%macro is_float(value);
    %ifelse(%sysfunc(inputn(&value, best32.)) = %sysfunc(round(&value)), 0, 1)
%mend is_float;

/**
 * ============
 * # is_numeric
 * ============
 * Returns true if the value is a numeric value. False otherwise.
 *
 * @param value - the value to test.
 * @returns boolean - 1 if the value is numeric, 0 otherwise.
 * @see is_int
 * @see is_float
 * @note This macro is a wrapper for is_int and is_float.
*/
%macro is_numeric(value);
    %ifelse(%is_int(&value) + %is_float(&value) > 0, 1, 0)
%mend is_numeric;

/**
 * =========
 * # is_date
 * =========
 * Returns true if the value is a date. False otherwise.
 *
 * @param value - the value to test.
 * @returns boolean - 1 if the value is a date, 0 otherwise.
*/
%macro is_date(value);
    /* Check whether or not the value can be coerced into a SAS date value. */
    %ifelse(%sysfunc(inputn(&value, date9.)) = ., 0, 1)
%mend is_date;

/**
 * =========
 * # is_time
 * =========
 * Returns true if the value is a time. False otherwise.
 *
 * @param value - the value to test.
 * @returns boolean - 1 if the value is a time, 0 otherwise.
*/
%macro is_time(value);
    /* Check whether or not the value can be coerced into a SAS time value. */
    %ifelse(%sysfunc(inputn(&value, time.), time.) = ., 0, 1)
%mend is_time;

/**
 * =============
 * # is_datetime
 * =============
 * Returns true if the value is a datetime. False otherwise.
 *
 * @param value - the value to test.
 * @returns boolean - 1 if the value is a datetime, 0 otherwise.
*/
%macro is_datetime(value);
    /* Check whether or not the value can be coerced into a SAS datetime value. */
    %ifelse(%sysfunc(inputn(&value, datetime.), datetime.) = ., 0, 1)
%mend is_datetime;

/**
 * =============
 * # is_temporal
 * =============
 * Returns true if the value is a datetime, date, or time. False otherwise.
 *
 * @param value - the value to test.
 * @returns boolean - 1 if the value is a datetime, date, or time, 0 otherwise.
*/
%macro is_temporal(value);
    %local condition;

    /* Check whether or not the value can be coerced into at least on of a 
    SAS date, time, or datetime value. */
    %let condition = %eval(%is_date(&value) + %is_time(&value) + %is_datetime(&value));

    %ifelse(&condition. > 0, 1, 0)
%mend is_temporal;

/**
 * ===========
 * # is_string
 * ===========
 * Returns true if the value is a string. False otherwise.
 *
 * @param value - the value to test.
 * @returns boolean - 1 if the value is a string, 0 otherwise.
*/
%macro is_string(value);
    /* Assume the value is a string if it is neither numeric nor 
    temporal. */
    %ifelse(%is_numeric(&value) + %is_temporal(&value) > 0, 0, 1)
%mend is_string;

/**
 * =============
 * # is_positive
 * =============
 * Returns true if the value is a number greater than 0. False otherwise.
 *
 * @param value - the value to test.
 * @returns boolean - 1 if the value is a number greater than 0, 0 otherwise.
*/
%macro is_positive(number);
    %local pos is_numeric condition;
    %let pos = %eval(&number > 0);
    %let is_numeric = %is_numeric(&number);
    %let condition = %eval(&pos + &is_numeric);
    %ifelse(&condition = 2, 1, 0)
%mend is_positive;