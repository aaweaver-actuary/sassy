%sbmod(strings);

%macro __updateIterVars( delim );
    %let __strIterNextIdx=%eval(&__strIterNextIdx.+1);
    %let __strIterNextWord=%scan(&__strIterString., &__strIterNextIdx., &delim.);
%mend __updateIterVars;

/* Initializes an iterator over the words in a string, where words are the substrings separated by a delimiter */
%macro str__iterInit( s /* String to iterate over */, , delim
    /* Delimiter to split the string on. Default is a space */ );

    %global __strIterString __strIterNumbWords __strIterNextIdx
        __strIterNextWord ;

    %if %length(&delim)=0 %then %do;
        %let delim=%str( );
    %end;

    /* Replace instances of actual delim with pipe char | */
    %let adjS=%str__replace(&s, &delim, |);
    %let delim=%str(|);

    %let __strIterString=&adjS.;
    %let __strIterNextIdx=1;

    %let __strIterNumbWords=%sysfunc(countw(&adjS., &delim.));

    %if &__strIterNumbWords=0 %then %do;
        %put ERROR: No words found in the string: [&adjS.];
        %return;
    %end;

    %let __strIterNextWord=%scan(&adjS., &__strIterNextIdx, &delim.);

%mend str__initIter;

/* Returns a 1 if the iterator successfully advances to the next word, 0 otherwise */
%macro str__iterNext;

    %if &__strIterNextIdx.>&__strIterNumbWords. %then %do;
        %return 0;
    %end;

    %__updateIterVars(&delim.);
    %return 1;

%mend str__iterNext;