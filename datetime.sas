%macro now();
    %sysfunc(datetime(), datetime20.)
%mend now;

%macro today();
    %sysfunc(date(), date9.)
%mend today;
