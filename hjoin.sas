%sbmod(validate);
%sbmod(lists);

%macro extract_from_variable(x);
    /*
    The `extract_from_variable` macro is used to parse a variable name and its length
    from a string. The variable name should be followed by a pipe `|` character
    and the variable length. The variable name and length are returned as separate
    macro variables.

    Usage:

    %extract_from_variable(var_name|length);

    Example:

    %extract_from_variable(var1|20);

    After calling the macro, the following macro variables will be defined:

    - &__temp_var_name: var1
    - &__temp_var_len: 20
     */
    /* Is there a pipe in this string? */
    %let is_num=%index(&x., |)=0;
    %let is_char=%index(&x., |) ne 0;

    %if &is_num. %then %do;
        %let __temp_var_name=&x.;
        %let __temp_var_len=0;
        %let __num_var_len=&__temp_var_name.;
    %end;
    %else %if &is_char. %then %do;
        %let __temp_var_name=%scan(&x., 1, |);
        %let __temp_var_len=%scan(&x., 2, |);
        %let __char_var_len=&__temp_var_name.;
        %let __char_len_len=&__temp_var_len.;
    %end;

%mend extract_from_variable;

%macro parse_variable(x);

    %extract_from_variable(&x.);
%mend parse_variable;

%macro hjoin(in=, out=, map=, key=, data=, filter=0, default_missing=.);
    /*
    The `hjoin` macro is used to perform a hash join between two datasets. The
    `input_ds` dataset is the primary dataset, and the `lookup_ds` dataset is the
    secondary dataset. The `shared_keys` variable is a list of variables that are
    common between the two datasets. The optional `data_to_append` variable
    is a list of data variables from the `lookup_ds` dataset that will be appended
    to the output dataset. If the `filter` parameter is set to 1, only the rows
    that match between the two datasets will be included in the output dataset.
    If the `filter` parameter is set to 0 (the default), all rows from the primary
    dataset will be included in the output dataset, with missing values for the
    appended data if no match is found in the secondary dataset determined by the
    `missing_default` parameter.


    If no `output_ds` is provided, the `input_ds` dataset will be modified in place.

    If no `data_to_append` is provided, no additional data will be appended to the
    output dataset.

    Usage:

    # This will perform a hash join between `ds` and `lkp` on the numeric variable `a`.
    # The numeric variables `d` and `e` from `lkp` will be appended to the output dataset.
    # A new dataset `ds_out` will be created with the results.
    # Only rows that match between the two datasets will be included in the output dataset.
    %hjoin(
    in=ds,
    out=ds_out,
    map=lkp,
    key=a,
    data=d e,
    filter=1
    );

    # This will perform a hash join between `ds` and `lkp` on the numeric variable `a`.
    # The numeric variables `d` and `e` from `lkp` will be appended to the output dataset.
    # The output dataset will be the same as the input dataset `ds`.
    # All rows from the primary dataset will be included in the output dataset.
    # Missing values of 0 will be used for the appended data if no match is found in
    # the secondary dataset.
    %hjoin(
    in=ds,
    map=lkp,
    key=a,
    data=d e,
    default_missing=0
    );

    Note on character variables:

    If any character variables are passed to this macro, they _must_ be annotated with
    an integer length as follows:

    %hjoin(
    in=ds,
    map=lkp,
    key=a,
    data=d e|20
    );

    This hash join uses a numeric variable `a` as the key, and joins a numeric variable `d`
    and a character variable `e` with a length of 20 from the `lkp` dataset to the `ds`.

    Lengths for character variables are required to ensure that the hash join works correctly.

     */
    %local data_stmnt data_list data_var i key_list key_stmnt data_types;

    /* Initialize global variables */
    %let globals=__temp_var_len __temp_var_name __num_var_len __char_len_len
        __char_var_len __keys __data;
    %do i=1 %to %sysfunc(countw(&globals.));
        %let global_var=%scan(&globals., &i);
        %global &global_var.;
        %let &global_var.=;
    %end;

    /* Validate the input parameters */
    %if %validate_exists(&in.)=0 %then %do;
        %put ERROR: The `in` parameter is required.;
        %return;
    %end;

    %if %validate_exists(&out.)=0 %then %do;
        %put NOTE: The `out` parameter was not provided. Defaulting to modifying
            the current dataset in place.;
        %let out=&in.;
    %end;

    %if %validate_exists(&map.)=0 %then %do;
        %put ERROR: The `map` parameter is required.;
        %return;
    %end;

    %if %validate_exists(&key.)=0 %then %do;
        %put ERROR: The `key` parameter is required.;
        %return;
    %end;
    %else %do;
        %do i=1 %to %sysfunc(countw(&key.));
            %let cur_key=%scan(&key., &i);
            %if &i.=1 %then %let __keys=&cur_key.;
            %else %let __keys=&__keys. &cur_key.;
            %parse_variable(&cur_key.);
            %if &i=1 %then %let key_stmnt="&cur_key.";
            %else %let key_stmnt=&key_stmnt ", &cur_key.";

            %if &i=1 %then %let missing_key_stmnt=&cur_key.;
            %else %let missing_key_stmnt=&missing_key_stmnt, &cur_key.;

        %end;
    %end;

    %if %validate_exists(&data.)=0 %then %do;
        %let data_stmnt=;
        %put NOTE: The `data` parameter was not provided. No additional data
            will be appended to &out.;
        %let data.=;
    %end;
    %else %do;
        %do i=1 %to %sysfunc(countw(&data.));
            %let cur_data=%scan(&data., &i);
            %if &i.=1 %then %let __data=&cur_data.;
            %else %let __data=&__data. &cur_data.;
            %parse_variable(&cur_data.);
            %if &i=1 %then %let data_stmnt="&cur_data.";
            %else %let data_stmnt=&data_stmnt ", &cur_data.";

            %if &i=1 %then %let missing_data_stmnt=&cur_data.;
            %else %let missing_data_stmnt=&missing_data_stmnt, &cur_data.;
        %end;
    %end;

    data &out.;
        if _n_=1 then do;
            length &__num_var_len 8.;
            %if %validate_exists(&__char_len_len.)=1 %then %do;
                %do i=1 %to %sysfunc(countw(&__char_len_len.));
                    %let cur_len=%scan(&__char_len_len., &i);
                    length %scan(&__char_var_len., &i) $&cur_len.;
                %end;
            %end;

            dcl hash h(dataset: "&map.", multidata: "yes");
            h.defineKey(&key_stmnt.);
            %if "&data_stmnt." ne "" %then %do;
                h.defineData(&data_stmnt.);
            %end;

            h.defineDone();
            call missing(&missing_key_stmnt.);
            %if "&missing_data_stmnt." ne "" %then %do;
                call missing(&missing_data_stmnt.);
            %end;
        %end;

        set &in.;

        rc=h.find();

        %if &filter. %then %do;
            if rc=0 then output;
        %end;
        %else %do;
            if rc ne 0 then do;
                %if "&data_stmnt." ne "" %then %do;
                    %do i=1 %to %sysfunc(countw(&__char_var_len.));
                        %let cur_var=%scan(&__char_var_len., &i);
                        &cur_var="&default_missing.";
                    %end;
                    %do i=1 %to %sysfunc(countw(&__num_var_len.));
                        %let cur_var=%scan(&__num_var_len., &i);
                        &cur_var=&default_missing.;
                    %end;
                %end;
                output;
            end;
        %end;

    run;

%mend hjoin;
