%sbmod(strings);

%macro hash__dcl(hashObj, dataset=);
    %if %length(&dataset.)=0 %then
        %let out=dcl hash &hashObj.();
    %else
        %let out=dcl hash &hashObj.(dataset: "&dataset.");
    &out.
%mend hash__dcl;

%macro hash__key(hashObj, cols, isOne=0);
    %if &isOne.=1 %then 
        %let keyList="&cols.";
    %else %do;
        %do i=1 %to %sysfunc(countw(&cols.));
            %let cur=%scan(&cols., &i.);
            %if &i.=1 %then 
                %let keyList="&cur.";
            %else 
                %let keyList=&keyList., "&cur.";
        %end;
    %end;

    &hashObj..defineKey(&keyList.);
%mend hash__key;

%macro hash__data(hashObj, cols, isOne=0);
    %if &isOne.=1 %then 
        %let dataList="&cols.";
    %else %do;
        %do i=1 %to %sysfunc(countw(&cols.));
            %let cur=%scan(&cols., &i.);
            %if &i.=1 %then 
                %let dataList="&cur.";
            %else 
                %let dataList=&dataList., "&cur.";
        %end;
    %end;

    &hashObj..defineData(&dataList.);
%mend hash__data;

%macro hash__done(hashObj);
    &hashObj..defineDone();
%mend hash__done;

%macro hash__missing(hashObj, cols, isOne=0);
    %if &isOne.=1 %then 
        %let missingList=&cols.;
    %else %do;
        %do i=1 %to %sysfunc(countw(&cols.));
            %let cur=%scan(&cols., &i.);
            %if &i.=1 %then 
                %let missingList=&cur.;
            %else 
                %let missingList=&missingList., &cur.;
        %end;
    %end;

    call missing(&missingList.);
%mend hash__missing;

%macro hash__add(hashObj, key, value);
    &hashObj..add(key: "&key.", data: "&value.");
%mend hash__add;

%macro _get_char_vars(char);
        %put char: &char;
    %let items=%str__replace(&char., |, %str( ) ) );
    %let nItems=%scan(&items., 2, %str( ));
    %let nPairs=%eval(&nItems. / 2);
        %put nPairs: &nPairs.;
    %if %length(&nPairs.)>1 %then %do;
        %do i=1 %to %length(&char.);
            %let cur=%scan(&char., &i., ' ');
            %_one_char_length_stmnt(&cur.);
        %end;
    %end;
    %else %do;
        %_one_char_length_stmnt(&char.);
    %end;
%mend _get_char_vars;

%macro _one_char_length_stmnt(current);
    %let var=%scan(&current., 1, '|');
    %let len=%scan(&current., 2, '|');
    length &var. $ &len.;
%mend _one_char_length_stmnt;

%macro make_hash_obj(hashObj, key=, num=, char=, dataset=, isOne=0);
    %if %length(&num.)>0 %then %do;
        length &num. 8.;
    %end;

    %hash__dcl(&hashObj., dataset=&dataset.);
    %hash__key(&hashObj., &key., isOne=&isOne.);

%mend make_hash_obj;

%macro test_hash_macros;
%if &__unit_tests.=1 %then %do;
    %sbmod(assert);

    %test_suite(hash.sas macro tests);
        %let charVarsFromOneCharLenStmnt=%_one_char_length_stmnt( singleVar|5 );
        %assertEqual("&charVarsFromOneCharLenStmnt.", "length singleVar $ 5;");

        %let charVarsFromGetCharVars=%_get_char_vars( singleVar|5 );
        %assertEqual("&charVarsFromGetCharVars.", "length singleVar $ 5;");
    %test_summary;

%end;
%else %do;

%end;
%mend test_hash_macros;

%test_hash_macros;