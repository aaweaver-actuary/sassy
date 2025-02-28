%sbmod(shell);

%let output_file = "performance_testing.csv";

%macro reorder_to_random_order(ds);
    data &ds;
        set &ds;
        call streaminit(12345);
        current_order = _n_;
        random_order = rand("uniform");
    run;

    proc sort data = &ds out = &ds;
        by random_order;
    run;

    data &ds;
        set &ds;
        drop random_order;
    run;
%mend reorder_to_random_order;

%macro test_with_setting(test_name, method, ds_size, lkp_size, setting_option=, setting_value=, setup_macro=, test_macro=, teardown_macro=);
    %put Running Test with &setting_option = &setting_value...;

    /* Store Original Setting */
    %let original_setting = %sysfunc(getoption(&setting_option));

    /* Apply New Setting */
    options &setting_option = &setting_value;

    /* Run Setup Macro */
    %&setup_macro;

    /* Run Test Macro */
    %let start_time = %sysfunc(datetime());
        %&test_macro;
    %let end_time = %sysfunc(datetime());

    /* Run Teardown Macro */
    %&teardown_macro;

    /* Restore Original Setting */
    options &setting_option = &original_setting;

    /* Export time stats */
    data datExport;
        length test_name $ 100 method $ setting $ setting_option $ start_time $ 20 end_time $ 20 elapsed_seconds 8 dataset_size_in_million_rows 8 lookup_size_in_million_rows 8;
        test_name = "&test_name";
        method = "&method";
        setting = "&setting_option";
        setting_value = "&setting_value";
        start_time = "&start_time";
        end_time = "&end_time";
        elapsed_seconds = %sysfunc(intck(SECOND, &start_time, &end_time));
        dataset_size_in_million_rows = &ds_size;
        lookup_size_in_million_rows = &lkp_size;

        output datExport;
    run;

    /* Append to the fiile if it exists, create it if it doesn't */
    %let file_exists = %sysfunc(fileexist(&output_file));
    %if &file_exists %then %do;
        proc append base = "&output_file" data = datExport;
        run;
    %end;
    %else %do;
        data datExport;
            set datExport;
        run;

        proc export data = datExport
            outfile = "&output_file"
            dbms = csv
            replace;
        run;
    %end;

    /* If a table called test* was created, delete it */
    proc datasets lib = work nolist;
        delete test:;
    quit;
%mend test_with_setting;


%macro test_proc_sql_join(ds1, ds2, key);
    proc sql;
        create table test as
        select *
        from &ds1 a
        inner join &ds2 b
        on a.&key = b.&key;
    quit;
%mend test_proc_sql_join;

%macro test_data_step_merge(ds1, ds2, key);
    data test;
        merge &ds1 (in=a) &ds2 (in=b);
        by &key;
    run;
%mend test_data_step_merge;

%macro test_hash_obj_join(ds1, ds2, key);
    data test;
        if _n_ = 1 then do;
            if 0 then set &ds2;
            declare hash h(dataset:"&ds2");
            h.definekey("&key");
            h.definedata(all:"yes");
            h.definedone();
        end;

        set &ds1;
        rc = h.find();
        if rc = 0 then output;
        drop rc;
    run;
%mend test_hash_obj_join;

%macro test_proc_sql_orderby(ds, key);
    proc sql;
        create table test as
        select *
        from &ds
        order by &key;
    quit;
%mend test_proc_sql_orderby;

%macro test_data_step_sort(ds, key);
    data test;
        set &ds;
        by &key;
    run;
%mend test_data_step_sort;

%macro test_hash_obj_sort(ds, key, composite_key);
    data test;
        if _n_ = 1 then do;
            declare hash h(dataset:"&ds");
            %if %length(&key) > 0 %then %do;
                h.definekey("&key");
            %end;
            %else %if %length(&composite_key) > 0 %then %do;
                %let ck_quote_comma=;
                %do i=1 %to %sysfunc(countw(&composite_key, %str( )));
                    %let ck_quote_comma = &ck_quote_comma %sysfunc(quote(%scan(&composite_key, &i, %str( )))) %str(,);
                %end;
                h.definekey(&ck_quote_comma);
            %end;
            h.definedata(all:"yes");
            h.definedone();
        end;

        do while(h.next() = 0);
            output;
        end;
    run;
%mend test_hash_obj_sort;

%macro get_key(key, composite_key);
    %if %length(&key) > 0 %then &key;
    %else %if %length(&composite_key) > 0 %then &composite_key;
    %else _all_;
%mend get_key;

%macro test_proc_sort(ds, key, composite_key);
    proc sort data = &ds out = test;
        by %get_key(&key, &composite_key);
    run;
%mend test_proc_sort;

%macro test_data_step_sort_nodup(ds, key, composite_key);
    data test;
        set &ds;
        by %get_key(&key, &composite_key);
        if first.%get_key(&key, &composite_key) then output;
    run;
%mend test_data_step_sort_nodup;

%macro test_proc_sort_nodup(ds, key, composite_key);
    proc sort data = &ds out = test nodupkey;
        by %get_key(&key, &composite_key);
    run;
%mend test_proc_sort_nodup;
