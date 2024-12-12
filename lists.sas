%macro foreach(list, codeblock);
    %local i item count;
    %let count = %len(&list);

    %do i = 1 %to &count;
        %let item = %nth(&list, &i);
        &codeblock
    %end;
%mend foreach;

%macro len(list);
    %local count;
    %let count = %sysfunc(countw(&list));
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
%mend unique;

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