%sbmod(validate);
%sbmod(lists);
%sbmod(logger);

%let log_level=DEBUG;
%clean_logger;

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
    %let is_char=%eval(%index(&x., |) ne 0);
    %if &is_char. %then %do;
		%dbg(EXTRACT - Inside is_char block since:);
		%dbg(EXTRACT - x: &x.);
		%dbg(EXTRACT - is_char: &is_char.);
        %let __temp_var_name=%scan(&x., 1, |);
        %let __temp_var_len=%scan(&x., 2, |);
        %let __char_var_len=&__temp_var_name.;
        %let __char_len_len=&__temp_var_len.;
		%dbg(EXTRACT - __temp_var_name: &__temp_var_name.);
		%dbg(EXTRACT - __temp_var_len: &__temp_var_len.);
		%dbg(EXTRACT - __char_var_len: &__char_var_len.);
		%dbg(EXTRACT - __char_len_len: &__char_len_len.);
    %end;
    %else %do;
		%dbg(EXTRACT - Inside is_num block since:);
		%dbg(EXTRACT - x: &x.);
		%dbg(EXTRACT - is_char: &is_char.);
        %let __temp_var_name=&x.;
        %let __temp_var_len=0;
        %let __num_var_len=&__temp_var_name.;
		%dbg(EXTRACT - __temp_var_name: &__temp_var_name.);
		%dbg(EXTRACT - __temp_var_len: &__temp_var_len.);
		%dbg(EXTRACT - __num_var_len: &__num_var_len.);
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
        __has_data __char_var_len __keys __data;
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
		%info(Unable to validate the key parameter);
		%info(Expected key: &key.);
        %put ERROR: The `key` parameter is required.;
		%put ERROR: Expected key: &key.;
        %return;
    %end;
    %else %do;
        %do i=1 %to %sysfunc(countw(&key.));
            %let cur_key=%scan(&key., &i);
            %if &i.=1 %then %let __keys=&cur_key.;
            %else %let __keys=&__keys. &cur_key.;
            %parse_variable(&cur_key.);

			%dbg(at key stmnt create:);
			%dbg(i: &i.);
			%dbg(cur_key: &cur_key.);
			%dbg(key_stmnt before: &key_stmnt.);

            %if &i=1 %then %let key_stmnt=%str(%")&cur_key.%str(%");
            %else %let key_stmnt=&key_stmnt, %str(%")&cur_key.%str(%");
			
			%dbg(key_stmnt after: &key_stmnt.);

            %if &i=1 %then %let missing_key_stmnt=&cur_key.;
            %else %let missing_key_stmnt=&missing_key_stmnt, &cur_key.;

        %end;
    %end;

    /* Default expectation is no data variables */
    %let __has_data=0;
    %if %validate_exists(&data.)=0 %then %do;
		%dbg(Not able to validate that the data input exists:);
		%dbg(data: &data.);
        %let data_stmnt=;
        %put NOTE: The `data` parameter was not provided. No additional data
            will be appended to &out.;
        %let data.=;
    %end;
    %else %do;
        %let __has_data=1;
		%dbg(Able to validate that the data input exists:);
		%dbg(data: &data.);

		%let data_adj=%sysfunc(tranwrd(%str(%")&data.%str(%"), %str(%")|%str(%"), %str(%")ZZZ%str(%")));
		%dbg(data_adj: &data_adj.);
        %do i=1 %to %sysfunc(countw(&data_adj.));
			%let cur_data=%scan(&data_adj., &i);

			%dbg(current data before parse: &cur_data.);
			%parse_variable(&cur_data.);
			%dbg(current data after parse: &cur_data.);


			%let var=%nth(&cur_data., 1);
			%let var_len=%nth(&cur_data., 2);

			%dbg(var: &var.);
			%dbg(var_len: &var_len.);

            %if &i.=1 %then %do;
				%let idx=%index("|", "&var.");
				%dbg(idx: &idx.);

				%let nm=&var.;
				%if &idx. ne 0 %then 
					%let nm=%substr(&var., 1, &idx.);

				%dbg(nm: &nm.);

				%let __data=&nm.;
			
				%let data_stmnt=%str(%")&nm.%str(%");
				%let missing_data_stmnt=&cur_data.;
			%end;
			%else %do;
				%let idx=%index("|", "&var.");
				%dbg(idx: &idx.);

				%let nm=&var.;
				%if &idx. ne 0 %then 
					%let nm=%substr(&var., &idx, &idx.);

				%dbg(nm: &nm.);

            	%let __data=&__data. &var.;
				%let data_stmnt=&data_stmnt., %str(%")&var.%str(%");
				%let missing_data_stmnt=&missing_data_stmnt., &cur_data.;
			%end;
        %end;
    %end;

    %dbg(HJOIN - Input parameters validated);
    %dbg(HJOIN - in: &in.);
    %dbg(HJOIN - out: &out.);
    %dbg(HJOIN - map: &map.);
	%dbg(HJOIN - key: &key.);
	%dbg(HJOIN - __keys: &__keys.);
    %dbg(HJOIN - key_stmnt: &key_stmnt.);
	%dbg(HJOIN - __data: &__data.);
    %dbg(HJOIN - data: &data_stmnt.);
    %dbg(HJOIN - filter: &filter.);
    %dbg(HJOIN - default_missing: &default_missing.);

    data &out.;
        if _n_=1 then do;
            %make_length_statements;
            %declare_hash_object;
            %initialize_variables;
        end;

        set &in.;
        rc=h.find();
        %handle_defaults(rc, filter);
	run;

%mend hjoin;

%macro make_length_statements;
    length &__num_var_len. 8.;
    %let has_char_vars=%validate_exists(&__char_var_len.);
    %if &has_char_vars. %then %do;
        %let char_vars=&__char_var_len.;
        %let char_lens=&__char_len_len.;

        %do i=1 %to %sysfunc(countw(&char_vars.));
            %let cur_var=%scan(&char_vars., &i);
            %let cur_len=%scan(&char_lens., &i);
            length &cur_var. $&cur_len.;
        %end;
    %end;
%mend make_length_statements;

%macro declare_hash_object;
    %dbg(HJOIN - Inside declare_hash_object macro);
    /* Declare the hash object */
    dcl hash h(dataset: "&map.", multidata: "yes");
	
    /* KEY */
    %dbg(HJOIN - Defining key to be [&key_stmnt.]);
    h.defineKey(&key_stmnt.);

    /* DATA (IF PROVIDED) */
    %if "&data_stmnt." ne "" %then %do;
        %dbg(HJOIN - Defining data to be [&data_stmnt.]);
        h.defineData(&data_stmnt.);
    %end;

    /* DONE WITH DEFINITIONS */
    %dbg(HJOIN - Done defining hash object);
    h.defineDone();
%mend declare_hash_object;

%macro initialize_variables;
    %dbg(HJOIN - Inside initialize_variables macro);
    /* Always initialize key variables */
    call missing(&missing_key_stmnt.);

    /*  Initialize data variables if provided */
    %if "&missing_data_stmnt." ne "" %then %do;
        call missing(&missing_data_stmnt.);
    %end;
%mend initialize_variables;

%macro add_missing_defaults__num;
    %dbg(HJOIN - Inside add_missing_defaults__num macro);
    %do i=1 %to %sysfunc(countw(&__num_var_len.));
        %let cur_var=%scan(&__num_var_len., &i);
        &cur_var=&default_missing.;
    %end;
%mend add_missing_defaults__num;

%macro add_missing_defaults__char;
    %dbg(HJOIN - Inside add_missing_defaults__char macro);
    %do i=1 %to %sysfunc(countw(&__char_var_len.));
        %let cur_var=%scan(&__char_var_len., &i);
        &cur_var="&default_missing.";
    %end;
%mend add_missing_defaults__char;

%macro handle_defaults(rc, filter);
    %dbg(HJOIN - Inside handle_defaults macro);
    %if &filter. %then %do;
        if rc=0 then output;
    %end;
    %else %do;
        if rc ne 0 then do;
            %dbg(HJOIN - Adding missing defaults for numeric variables);
            %add_missing_defaults__num;
            %if "&data_stmnt." ne "" %then %do;
                %dbg(HJOIN - Adding missing defaults for character variables);
                %add_missing_defaults__char;
            %end;
            output;
        end;
    %end;
%mend handle_defaults;


data test;
input sb_policy_key b c d $ e;
datalines;
1 10 100 a 1000
100 10 100 b 1000
1000 10 100 c 1000
10000 10 100 d 1000
25000 10 100 e 1000
;

%hjoin(in=test, out=test_out, map=decfile.policy_lookup, key=sb_policy_key, data=policy_numb policy_sym|3);
