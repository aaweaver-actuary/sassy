/***************************************************************************
 * File: replace_with_policy_key.sas
 *
 * Purpose:
 *   Provides a structured approach to replacing five policy columns with
 *   a single policy_key from a lookup table, with optional filtering and
 *   basic validation checks. Follows a pseudo "private" (h__) and
 *   "public" (main macro) design for clarity.
 *
 * Macro (PUBLIC):
 *   - %replace_with_policy_key(inputds=, outputds=, lookuptable=, filter_matched=NO)
 *
 * Macros (PRIVATE):
 *   - %h__error_msg(macro=, msg=)
 *   - %h__verify_dataset_exists(ds=)
 *   - %h__verify_columns_exist(ds=, columns=)
 *   - %h__check_duplicates(ds=, keyvars=)
 *   - %h__validate_data_types(ds=, columns=)          [Placeholder Only]
 *   - %h__determine_hashexp(lookup=, default_hexp=20)
 *   - %h__validate(inputds=, outputds=, lookuptable=)
 *
 * Usage Example:
 *   %replace_with_policy_key(
 *       inputds=mydata.raw,
 *       outputds=mydata.prepped,
 *       lookuptable=mydata.policy_lookup,
 *       filter_matched=YES
 *   );
 *
 * Status:
 *   This script is tested for basic usage. Additional checks or expansions
 *   (like advanced data-type validation, logging, etc.) may be implemented
 *   later.
 ***************************************************************************/

/*-------------------------------------------------------------------------
%h__error_msg(macro=, msg=)

Prints an error message with the macro name and the given message.
-------------------------------------------------------------------------*/
%macro h__error_msg(macro, msg);
    %put ERROR: (&macro) &msg;
    %let h__abort=1;
%mend h__validate_data_types;

/*-------------------------------------------------------------------------
%h__verify_dataset_exists(ds=)
Checks if a given dataset exists. Prints an ERROR and sets a macro
variable h__abort=1 if the dataset does not exist.
-------------------------------------------------------------------------*/
%macro h__verify_dataset_exists(ds=);
    %local dsid rc;
    %let dsid=%sysfunc(open(&ds));
    %if &dsid=0 %then %do;
        %h__error_msg(h__verify_dataset_exists, Dataset &ds does not exist.);
        %return;
    %end;
    %let rc=%sysfunc(close(&dsid));
%mend h__verify_dataset_exists;

/*-------------------------------------------------------------------------
%h__verify_columns_exist(ds=, columns=)
Checks if a list of columns (space-delimited) exists in a dataset.
Prints an ERROR and sets a macro variable h__abort=1 if any column
is missing.
-------------------------------------------------------------------------*/
%macro h__verify_columns_exist(ds=, columns=);
    %local col col_uc n i dsid rc colfound;

    %let libname=%scan(&ds,1,.);
    %if %length(&libname)=0 %then %let libname=WORK;
    %let memname=%scan(&ds,2,.);
    %if &libname

    /* We will loop through each column in &columns */
    %let i=1;
    %let col=%scan(&columns,&i,%str( ));
    %do %while(%length(&col) > 0);
        %let col_uc=%upcase(&col);

        /* Access dictionary for the dataset's columns: */
        proc sql noprint;
            select count(*) into :colfound from dictionary.columns where
                libname=&libname and memname=&memname ;
        quit;

        %if &colfound=0 %then %do;
            %h__error_msg( h__verify_columns_exist, Column &col not found in
                &ds. );
            %return;
        %end;

        /* Next column */
        %let i=%eval(&i+1);
        %let col=%scan(&columns,&i,%str( ));
    %end;
%mend h__verify_columns_exist;

/*-------------------------------------------------------------------------
%h__check_duplicates(ds=, keyvars=)
Checks if the given dataset has duplicates on the set of keyvars.
If duplicates exist, sets h__abort=1 and prints an ERROR.
-------------------------------------------------------------------------*/
%macro h__check_duplicates(ds=, keyvars=);
    %local dupCount;

    proc sql noprint;
        select count(*) into :dupCount from ( select &keyvars from &ds group by
            &keyvars having count(*) > 1 );
    quit;

    %if &dupCount > 0 %then %do;
        %h__error_msg( h__check_duplicates, Dataset &ds has &dupCount duplicates
            on keyvars &keyvars. );
    %end;
%mend h__check_duplicates;

/*-------------------------------------------------------------------------
%h__validate_data_types(ds=, columns=)

PLACEHOLDER ONLY. This macro would compare data types in the
input vs. lookup to ensure matching numeric/character. For now,
it's a stub that can be implemented later.
-------------------------------------------------------------------------*/
%macro h__validate_data_types(ds=, columns=);
    /*
    TODO: Implementation example
    - For each column in &columns, get its type from dictionary.columns
    - Compare with the expected type or with the corresponding column
    in the other dataset
    - If mismatch, set h__abort=1 and print an ERROR
     */
    %put NOTE: (h__validate_data_types) Placeholder. Not implemented yet.;
%mend h__validate_data_types;

/*-------------------------------------------------------------------------
%h__determine_hashexp(lookup=, default_hexp=20)

Heuristic for setting the hashexp, based on row count of lookup table.
If the row count is quite large, set a higher hashexp; otherwise use
smaller. If you have no memory constraints, we can just default to
20 or 17. This function sets a macro variable H__RECOMMENDED_HASH_EXP.
-------------------------------------------------------------------------*/
%macro h__determine_hashexp(lookup=, default_hexp=20);
    %global h__recommended_hash_exp;
    /* Default value in case the logic fails */
    %let h__recommended_hash_exp=&default_hexp;

    %local dsid nobs rc;
    %let dsid=%sysfunc(open(&lookup));
    %if &dsid %then %do;
        %let nobs=%sysfunc(attrn(&dsid,nlobs)); /* # of logical obs */
        %let rc=%sysfunc(close(&dsid));

        %if &nobs > 1000000 %then %let h__recommended_hash_exp=20;
        %else %if &nobs > 100000 %then %let h__recommended_hash_exp=17;
        %else %let h__recommended_hash_exp=15;
    %end;
    %else %do;
        %put WARNING: (h__determine_hashexp) Could not open &lookup. Using
            default &default_hexp.;
    %end;

    %put NOTE: (h__determine_hashexp) Using hashexp=&h__recommended_hash_exp for
        &lookup..;
%mend h__determine_hashexp;

/*-------------------------------------------------------------------------
%h__validate(inputds=, outputds=, lookuptable=)

-------------------------------------------------------------------------*/
%macro h__validate( inputds=, outputds=, lookuptable=);

    %let columns=company_numb policy_sym policy_numb policy_module
        policy_eff_date;

    %h__verify_dataset_exists(ds=&inputds);
    %if &h__abort=1 %then %return;

    %h__verify_dataset_exists(ds=&lookuptable);
    %if &h__abort=1 %then %return;

    %h__verify_columns_exist(ds=&inputds, columns=&columns);
    %if &h__abort=1 %then %return;

    %h__verify_columns_exist(ds=&lookuptable, columns=&columns);
    %if &h__abort=1 %then %return;

    %h__validate_data_types(ds=&inputds, columns=&columns);
    %if &h__abort=1 %then %return;

    %h__validate_data_types(ds=&lookuptable, columns=&columns);
    %if &h__abort=1 %then %return;

    %h__check_duplicates(ds=&lookuptable, keyvars=&columns);
    %if &h__abort=1 %then %return;

    %h__determine_hashexp(lookup=&lookuptable, default_hexp=20);
    %if &h__abort=1 %then %return;

%mend h__validate;

/*-------------------------------------------------------------------------
MAIN (PUBLIC) MACRO:

%replace_with_policy_key(inputds=, outputds=, lookuptable=, filter_matched=NO)

Replaces the five columns:
- company_numb
- policy_sym
- policy_numb
- policy_module
- policy_eff_date

with a single policy_key column, from a lookup table that must have:
company_numb, policy_sym, policy_numb, policy_module, policy_eff_date, policy_key

By default, keeps all rows from inputds, setting policy_key to missing
if there's no match. If filter_matched=YES, only keeps matched rows.
-------------------------------------------------------------------------*/
%macro replace_with_policy_key( inputds=, outputds=, lookuptable=policy_lookup,
    filter_matched=NO, company_numb=company_numb, policy_sym=policy_sym,
    policy_numbe=policy_numb, policy_module=policy_module,
    policy_eff_date=policy_eff_date);

    %global h__abort;
    %let h__abort=0;

    %let columns=&company_numb &policy_sym &policy_numb &policy_module
        &policy_eff_date;
    %let renamed_columns=company_numb policy_sym policy_numb policy_module
        policy_eff_date;

    /* Validate inputs */
    %h__validate( inputds=&inputds, outputds=&outputds,
        lookuptable=&lookuptable);
    %if &h__abort=1 %then %goto exit;

    /*****************************************************
    MAIN DATA STEP LOGIC

    - Creates &outputds
    - Replaces the five columns with policy_key
    - Optionally filters to matched rows only
     *****************************************************/
    data &outputds;
        /* Create hash object */
        if _N_=1 then do;
            declare hash h(dataset:"&lookuptable",
                hashexp=&h__recommended_hash_exp);
            rc=h.defineKey("company_numb", "policy_sym", "policy_numb",
                "policy_module", "policy_eff_date");
            rc=h.defineData("policy_key");
            rc=h.defineDone();
            call missing(policy_key);
        end;

        /* Start with the input dataset */
        set &inputds;

        /* Rename columns to ensure they match the hash object */
        rename &columns=&renamed_columns;

        /* Find the policy_key for the current row */
        rc=h.find();

        /* Filter or keep logic */
        %if %upcase(&filter_matched)=NO %then %do;
            /* If no filtering, output all rows */
            drop rc &columns;
            output;
        %end;
        %else %do;
            /* If filtering, only output matched rows (eg policy_key is not missing and thus rc=0) */
            if rc=0 then do;
                drop rc &columns;
                output;
            end;
        %end;
    run;

    %exit: %if &h__abort=1 %then %do;
    %put ERROR: (replace_with_policy_key) Macro aborted due to prior errors.;
    %end;
%mend replace_with_policy_key;

%macro test_replace_policy_key;
    %include "/sas/data/project/EG/aweaver/macros/assert.sas";

    %test_suite( replace_with_policy_key );
    %put WARNING: The following tests are testing the filter_matched=NO option.;

    data test_lookup;
        input company_numb policy_sym policy_numb policy_module policy_eff_date
            policy_key;
        datalines;
            5 ECP 1234 1 01JAN2020 1
            5 ECP 1235 1 01JAN2020 2
            5 ECP 1236 1 01JAN2020 3
            5 ECP 1237 1 01JAN2020 4
;
    run;

    data test_input_ds;
        input company_numb policy_sym policy_numb policy_module policy_eff_date
            other_data;
        datalines;
            5 ECP 1234 1 01JAN2020 100
            5 ECP 1235 1 01JAN2020 101
            5 ECP 1236 1 01JAN2020 102
            5 ECP 1237 1 01JAN2020 103
            5 ECP 1238 1 01JAN2020 104
;
    run;

    %replace_with_policy_key( inputds=test_input_ds, outputds=test_output_ds,
        lookuptable=test_lookup );

    /* Check the output dataset */
    /* Number of columns: */
    %let n_cols=%sysfunc(attrn(test_output_ds,nvars));
    %assertEqual(&n_cols, 2);

    /* Check the columns are policy_key and other_data */
    %let col1=%qscan(%sysfunc(varname(test_output_ds,1)),1,%str( ));
    %let col2=%qscan(%sysfunc(varname(test_output_ds,2)),1,%str( ));

    %assertEqual(&col1, policy_key);
    %assertEqual(&col2, other_data);

    /* Did not use filtering, so there should be 5 rows */
    proc sql noprint;
        select count(*) into :nobs from test_output_ds;
    quit;
    %assertEqual(&nobs, 5);

    /* Sum of the other_data column should be 100+101+102+103+104=510 */
    proc sql noprint;
        select sum(other_data) into :other_col_sum from test_output_ds;
    quit;
    %assertEqual(&other_col_sum, 510);

    /* Check the policy_key values */
    proc sql noprint;
        select policy_key into :policy_keys separated by ' ' from
            test_output_ds;
    quit;
    %assertEqual(&policy_keys, 1 2 3 4 .);

    /* -------------- Repeat the tests with filtering */
    %put WARNING: The following tests are testing the filter_matched=YES
        option.;
    %replace_with_policy_key( inputds=test_input_ds,
        outputds=test_output_ds_filtered, lookuptable=test_lookup,
        filter_matched=YES );

    /* Check the output dataset */
    /* Number of columns: */
    %let n_cols=%sysfunc(attrn(test_output_ds_filtered,nvars));
    %assertEqual(&n_cols, 2);

    /* Check the columns are policy_key and other_data */
    %let col1=%qscan(%sysfunc(varname(test_output_ds_filtered,1)),1,%str( ));
    %let col2=%qscan(%sysfunc(varname(test_output_ds_filtered,2)),1,%str( ));

    %assertEqual(&col1, policy_key);
    %assertEqual(&col2, other_data);

    /* Used filtering, so there should be 4 rows */
    proc sql noprint;
        select count(*) into :nobs from test_output_ds_filtered;
    quit;
    %assertEqual(&nobs, 4);

    /* Sum of the other_data column should be 100+101+102+103=406 */
    proc sql noprint;
        select sum(other_data) into :other_col_sum from test_output_ds_filtered;
    quit;

    %assertEqual(&other_col_sum, 406);

    /* Check the policy_key values */
    proc sql noprint;
        select policy_key into :policy_keys separated by ' ' from
            test_output_ds_filtered;
    quit;
    %assertEqual(&policy_keys, 1 2 3 4);

    %test_summary;

%mend test_replace_policy_key;

%test_replace_policy_key;
