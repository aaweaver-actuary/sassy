%MACRO is_numeric(a);
%if %sysfunc(vtype(&a)) = N %then %let out = 1;
%else %let out = 0;
&out
%MEND is_numeric;

%MACRO is_varchar(a);
%if %sysfunc(vtype(&a)) = V %then %let out = 1;
%else %let out = 0;
&out
%MEND is_varchar;

%MACRO is_char(a);
%if %sysfunc(vtype(&a)) = C %then %let out = 1;
%else %let out = 0;
&out
%MEND is_char;

%MACRO get_dtype(a);
%if %sysfunc(vtype(&a)) = N %then %let out = numeric;
%else %if %sysfunc(vtype(&a)) = V %then %let out = varchar;
%else %if %sysfunc(vtype(&a)) = C %then %let out = char;
%else %let out = unknown;
&out
%MEND get_dtype;