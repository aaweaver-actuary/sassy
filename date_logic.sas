%include "loader.sas";

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



