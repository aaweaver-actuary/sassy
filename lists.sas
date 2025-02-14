%macro foreach(list, codeblock);
    %local i item count;
    %let count = %len(&list);

    %do i = 1 %to &count;
        %let item = %nth(&list, &i);
        &codeblock
    %end;
%mend foreach;

%macro transform(list, surrounded_by=, delimited_by=);
    %local i item count transformedList;
    %let count = %len(&list);

    %do i = 1 %to &count;
        %let item = %nth(&list, &i);
        %let transformedList = &transformedList &surrounded_by&item&surrounded_by;
        %if &i < &count %then %let transformedList = &transformedList &delimited_by;
    %end;

    &transformedList
%mend transform;

%macro len(list, delimiters);
    %local count;
    %if %sysfunc(length(&delimiters.)) = 0 %then 
        %let count = %sysfunc(countw(&list));
    %else
        %let count = %sysfunc(countw(&list, &delimiters));
    &count
%mend len;

%macro nth(list, n);
    %local item;
    %let item = %scan(&list, &n);
    &item
%mend nth;

%macro first(list);
    %local item;
    %let item = %nth(&list, 1);
    &item
%mend first;

%macro last(list);
    %local count item;
    %let count = %len(&list);
    %let item = %nth(&list, &count);
    &item
%mend last;

%macro unique(list);
    %local i item count uniqueList;
    %let count = %len(&list);

    %do i = 1 %to &count;
        %let item = %nth(&list, &i);
        %if not %index(&uniqueList, &item) %then %do;
            %let uniqueList = &uniqueList &item;
        %end;
    %end;

    &uniqueList
%mend unique;;

%macro sorted(list);
    %local i item count sortedList;
    %let count = %len(&list);

    %do i = 1 %to &count;
        %let item = %nth(&list, &i);
        %let sortedList = &sortedList &item;
    %end;

    %let sortedList = %sysfunc(sortn(&sortedList));
    &sortedList
%mend sorted;

%macro push(list, item);
    &list &item
%mend push;

%macro pop(list);
    %local count;
    %let count = %len(&list);
    %let list = %substr(&list, 1, %eval(%length(&list) - %length(%nth(&list, &count)) - 1));
    &list
%mend pop;

%macro concat(list1, list2);
    &list1 &list2
%mend concat;

%macro list_err(type);
    %global has_err;
    %if &type.=len %then %put ERROR: The list is empty.;

    %let has_err = 1;
%mend list_err;