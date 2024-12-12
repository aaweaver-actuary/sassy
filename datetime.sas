/**
 * =====
 * # now
 * =====
 * Returns the current date and time.
 *
 * @returns datetime - the current date and time in the format ddMMMYYYY:HH:MM:SS
*/
%macro now();
    %sysfunc(datetime(), datetime20.)
%mend now;

/**
 * =======
 * # today
 * =======
 * Returns the current date.
 *
 * @returns date - the current date in the format ddMMMYYYY
*/
%macro today();
    %sysfunc(date(), date9.)
%mend today;


/**
 * =================
 * # is_1st_of_month
 * =================
 * Returns true if the day is the 1st of the month. False otherwise.
 *
 * @param `date_value` - a date to test.
 * @returns boolean
*/
%macro is_1st_of_month(date_value);
day(&date_value.) le 1
%mend is_1st_of_month;

/**
 * ========================
 * # is_1st_or_2nd_of_month
 * ========================
 * Returns true if the day is the 1st or the 2nd of the month. False otherwise.
 *
 * @param `date_value` - a date to test.
 * @returns boolean
*/
%macro is_1st_or_2nd_of_month(date_value);
day(&date_value.) le 2
%mend is_1st_or_2nd_of_month;

/**
 * ========================
 * # is_1st_or_2nd_of_month
 * ========================
 * Returns true if the day is the 1st or the 2nd of the month. False otherwise.
 *
 * @param `date_value` - a date to test.
 * @returns boolean
*/
%macro is_1st_or_2nd_of_month(date_value);
day(&date_value.) le 2
%mend is_1st_or_2nd_of_month;

/**
 * ===============
 * # is_after_2009
 * ===============
 * Returns true if the year is 2010 or after. False otherwise.
 *
 * @param `date_value` - a date to test.
 * @returns boolean
*/
%macro is_after_2009(date_value);
year(&date_value.) gt 2009
%mend is_after_2009;

/**
 * ================
 * # is_before_2010
 * ================
 * Returns true if the year is 2009 or before. False otherwise.
 *
 * @param `date_value` - a date to test.
 * @returns boolean
*/
%macro is_before_2010(date_value);
year(&date_value.) lt 2010
%mend is_before_2010;

/**
 * ==========================
 * # is_1st_or_2nd_after_2009
 * ==========================
 * Returns true if the day is the 1st or the 2nd, from 2010 or after. False otherwise.
 *
 * @param `date_value` - a date to test.
 * @returns boolean
*/
%macro is_1st_or_2nd_after_2009(date_value);
%is_after_2009(&date_value.)
and %is_1st_or_2nd_of_month(&date_value.)
%mend is_1st_or_2nd_after_2009;

/**
 * ====================
 * # is_1st_before_2009
 * ====================
 * Returns true if the day is the 1st from 2009 or before. False otherwise.
 *
 * @param `date_value` - a date to test.
 * @returns boolean
*/
%macro is_1st_before_2009(date_value);
(not %is_after_2009(&date_value.))
and %is_1st_of_month(&date_value.)
%mend is_1st_before_2009;

/**
 * ======================
 * # get_month_next_month
 * ======================
 * Returns the month following the month in the input date.
 *
 * @param `date_value` - a date to test.
 * @returns int - next integer in the cycle from 1 - 12
*/
%macro get_month_next_month(date_value);
%let m=%sysfunc(month(&date_value.));
%if &m.=12 %then %let result=1;
%else %let result=%eval(&m. + 1);
&result.
%mend get_month_next_month;

/**
 * ======================
 * # get_month_last_month
 * ======================
 * Returns the month preceding the month in the input date.
 *
 * @param `date_value` - a date to test.
 * @returns int - previous integer in the cycle from 1 - 12
*/
%macro get_month_last_month(date_value);
%let m=%sysfunc(month(&date_value.));
%if &m.=1 %then %let result=12;
%else %let result=%eval(&m. - 1);
&result.
%mend get_month_last_month;

/**
 * =====================
 * # get_year_next_month
 * =====================
 * Returns the year corresponding to the month following the month in the input date.
 *
 * @param `date_value` - a date to test.
 * @returns int - equal to the current year if the month is not 12, otherwise adds one to current year
*/
%macro get_year_next_month(date_value);
%let y=%sysfunc(year(&date_value.));
%let m=%sysfunc(month(&date_value.));
%if &m.=12 %then %let result=%eval(&y. + 1);
%else %let result=&y.;
&result.
%mend get_year_next_month;

/**
 * =====================
 * # get_year_last_month
 * =====================
 * Returns the year corresponding to the month preceding the month in the input date.
 *
 * @param `date_value` - a date to test.
 * @returns int - equal to the current year if the month is not 1, otherwise subtracts
 * one from the current year
*/
%macro get_year_last_month(date_value);
%let y=%sysfunc(year(&date_value.));
%let m=%sysfunc(month(&date_value.));
%if &m.=1 %then %let result=%eval(&y. - 1);
%else %let result=&y.;
&result.
%mend get_year_last_month;
