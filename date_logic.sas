/* 
Start with utility macros to abstract away some of the logic in the main macros below.
The goal is that everything does pretty much what you expect given the name of the macro.
*/

/**
 * =================
 * # is_1st_of_month
 * =================
 * Returns true if the day is the 1st of the month. False otherwise.
 *
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns boolean
*/
%macro is_1st_of_month(date_col);
day(&date_col.) le 1
%mend is_1st_of_month;

/**
 * ========================
 * # is_1st_or_2nd_of_month
 * ========================
 * Returns true if the day is the 1st or the 2nd of the month. False otherwise.
 *
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns boolean
*/
%macro is_1st_or_2nd_of_month(date_col);
day(&date_col.) le 2
%mend is_1st_or_2nd_of_month;

/**
 * ========================
 * # is_after
 * ========================
 * Returns true if the day is the 1st or the 2nd of the month. False otherwise.
 *
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns boolean
*/
%macro is_1st_or_2nd_of_month(date_col);
day(&date_col.) le 2
%mend is_1st_or_2nd_of_month;

/**
 * ===============
 * # is_after_2009
 * ===============
 * Returns true if the year is 2010 or after. False otherwise.
 *
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns boolean
*/
%macro is_after_2009(date_col);
year(&date_col.) gt 2009
%mend is_after_2009;

/**
 * ================
 * # is_before_2010
 * ================
 * Returns true if the year is 2009 or before. False otherwise.
 *
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns boolean
*/
%macro is_before_2010(date_col);
year(&date_col.) lt 2010
%mend is_before_2010;

/**
 * ==========================
 * # is_1st_or_2nd_after_2009
 * ==========================
 * Returns true if the day is the 1st or the 2nd, from 2010 or after. False otherwise.
 *
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns boolean
*/
%macro is_1st_or_2nd_after_2009(date_col);
%is_after_2009(&date_col.)
and %is_1st_or_2nd_of_month(&date_col.)
%mend is_1st_or_2nd_after_2009;

/**
 * ====================
 * # is_1st_before_2009
 * ====================
 * Returns true if the day is the 1st from 2009 or before. False otherwise.
 *
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns boolean
*/
%macro is_1st_before_2009(date_col);
(not %is_after_2009(&date_col.))
and %is_1st_of_month(&date_col.)
%mend is_1st_before_2009;

/**
 * ======================
 * # get_month_next_month
 * ======================
 * Returns the month following the month in the input date.
 *
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns int - next integer in the cycle from 1 - 12
*/
%macro get_month_next_month(date_col);
%let m=%sysfunc(month(&date_col.));
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
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns int - previous integer in the cycle from 1 - 12
*/
%macro get_month_last_month(date_col);
%let m=%sysfunc(month(&date_col.));
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
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns int - equal to the current year if the month is not 12, otherwise adds one to current year
*/
%macro get_year_next_month(date_col);
%let y=%sysfunc(year(&date_col.));
%let m=%sysfunc(month(&date_col.));
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
 * @private
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns int - equal to the current year if the month is not 1, otherwise subtracts
 * one from the current year
*/
%macro get_year_last_month(date_col);
%let y=%sysfunc(year(&date_col.));
%let m=%sysfunc(month(&date_col.));
%if &m.=1 %then %let result=%eval(&y. - 1);
%else %let result=&y.;
&result.
%mend get_year_last_month;

/**
 * =============================
 * # first_rpt_period_date_after
 * =============================
 * Returns the report period date either directly on, or immediately following the input
 * date. Encapsulates the logic contained in the original version of the SAS program:
 *   - '(1 - Images) List images and report period dates.sas'
 * 
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns int - equal to the current year if the month is not 12, otherwise adds one to current year
 * @examples
 * 1/2/2021 -> 1/2/2021
 * 12/3/2021 -> 1/2/2022
 * 
 * @note Each arm of the case statement is evaluated in series. As soon as a match is found, the statement
 * stops looking. This means that you can think of there being an implicit test for NOT 1st or 2nd after
 * 2009 for every case statement after the first one below. This lets me combine a few of the original
 * cases from the first version of this. Similar logic means that these NOT conditions start stacking,
 * and get combined to ensure that all the cases are filtered appropriately. 
*/
%macro first_rpt_period_date_after(date_col);
%let yr=year(&date_col.);
%let yr_next_month=%get_year_next_month(&date_col.);
%let same_month=month(&date_col.);
%let next_month=%get_month_next_month(&date_col.);

case
	when %is_1st_or_2nd_after_2009(&date_col.)
		then mdy(&same_month.,2,&yr.)

	when %is_after_2009(&date_col.)
		then mdy(&next_month.,2,&yr_next_month.)
	
	when %is_1st_of_month(&date_col.) 
		then mdy(&same_month., 1, &yr.)

	else mdy(&next_month., 1, &yr_next_month)

end
%mend first_rpt_period_date_after;

/**
 * ==============================
 * # first_rpt_period_date_before
 * ==============================
 * Returns the nearest report period date occurring before the input date. Encapsulates
 * the logic contained in the original version of the SAS program:
 *   - '(1 - Images) List images and report period dates.sas'
 * 
 *
 * @param `date_col` - a column with dates used to determine nearest batch run dates.
 * @returns int - equal to the current year if the month is not 12, otherwise adds one to current year
 * @examples
 * 1/2/2021 -> 12/2/2020
 * 12/3/2021 -> 1/2/2022
 * 
 * @note See the above discussion about SQL CASE statement execution.  
*/
%macro first_rpt_period_date_before(date_col);
%let yr=year(&date_col.);
%let yr_prev_month=%get_year_last_month(&date_col.);
%let same_month=month(&date_col.);
%let prev_month=%get_month_last_month(&date_col.);

case
	when %is_3rd_or_after_and_2010_or_after(&date_col.)
		then mdy(&same_month.,2,&yr.)

	when %is_2010_or_after(&date_col.)
		then mdy(&prev_month.,2,&yr_last_month.)
	
	when %is_1st_of_month(&date_col.) 
		then mdy(&prev_month., 1, &yr_last_month.)

	else mdy(&same_month., 1, &yr)

end
%mend first_rpt_period_date_before;



