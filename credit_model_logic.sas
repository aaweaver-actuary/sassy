%include "loader.sas";

%macro column_is_not_missing(column_name);
case
    when %is_missing(&column_name.) then 0
    else 1
end
%mend column_is_not_missing;

%macro is_between_1_and_100(column_name);
case
    when 0 < &column_name. < 101 then 1
    else 0
end
%mend is_between_1_and_100;

%macro safe_ratio(numerator, denominator);
%let num=%ifelse(%is_numeric(&numerator.), &numerator., input(&numerator., 8.));
%let den=%ifelse(%is_numeric(&denominator.), &denominator., input(&denominator., 8.));

case
    when %is_positive(&den.) then &num. / &den.
    when %is_missing_number(&den.) then 0
    when %is_missing_number(&num.) then 0
    when &den. = 0 then 0
    else 0
end
%mend safe_ratio;