%put ======================>> Loading py.sas;

/* 
This file defines the set of py_* macros. These macros abstract away the complexity
of registering Python functions with PROC FCMP. The macros are designed to be used to
define Python functions on columns of a data set, and are able to be called from within
a DATA step. 

The macros are designed to be used in the following way:
1. Define a Python function using the py_register macro
   Example:
     This will register the Python function `py_add` and its in-line definition:
        %py_register(
            def py_add(a, b):
                return a + b
        );
*/

/* 1. `py_register(<FUNCTION>)` */
%MACRO py__get_fn_name(buff);
    %local fn_name;
    %let fn_name = %sysfunc(scan(&buff, 2, ' '));
    %let fn_name = %sysfunc(scan(&fn_name, 1, '('));
    &fn_name
%MEND;

%MACRO py__get_fn_args(buff);
    %local args;
    %let args = %sysfunc(scan(&buff, 2, '('));
    %let args = %sysfunc(scan(&args, 1, ')'));
    &args
%MEND;

%MACRO py__get_fn_def(buff);
    %local def;
    %let def = %sysfunc(substr(&buff, %sysfunc(index(&buff, ':')) + 1));
    &def
%MEND;

%MACRO py__initialize_py_fns_table(buff);
    data work.py_fn_register;
        length function_name $32 python_def $1000;
        stop;
    run;
    
    %let _py_fn_name = %py__get_fn_name(&buff);
    data work.py_fn_register;
        length function_name $32 python_def $1000;
        function_name = "&_py_fn_name";
        python_def = "&buff";
    run;
%MEND;

%MACRO py__define_variables;
    %global _py_fn_name _py_fn_def _py_fn_args _py_fn_args_list _py_fn_output;
    /* 
    PARMBUFF:
    (         def test_add(a, b):             return a + b     ) 
    */
    %let clean_buff = %sysfunc(strip(&syspbuff));
    %let split_buff = 
    /* %let _py_fn_def = &syspbuff; */
    %let _py_fn_name = %py__get_fn_name(&_py_fn_def);
    %let _py_fn_args = %py__get_fn_args(&_py_fn_def);
    %let _py_fn_args_list = %sysfunc(translate(&_py_fn_args, $, ,));
    %let _py_fn_output = &_py_fn_name._x;
%MEND;

%macro py__strip_parens(buff);
    %local cleaned;
    /* Remove leading/trailing spaces first */
    %let cleaned = %sysfunc(strip(&buff));
	%let len = %length(&cleaned);
	%let first_char=%substr(&cleaned., 1, 1);
	%let last_char=%substr(&cleaned., &len., 1);
	%let left_paren=%str(%();
	%let right_paren=%str(%));
    
    /* If starts with ( and ends with ), remove them */
    %if "&first_char." = "&left_paren." and 
        "&last_char." = "&right_paren." 
	%then
        %let cleaned = %substr(&cleaned., 2, &len. - 2);
    
    &cleaned
%mend;

%macro py__get_fn_name(buff);
    %local fn_name;
	%put buff1: &buff.;
	%let buff=%py__strip_parens(&buff.);
	%put buff2: &buff.;
    /* Remove leading/trailing spaces first */
    %let fn_name = %sysfunc(strip(&buff));
    %put buff2a: &fn_name.;
    /* Remove the string 'def ' */
    %let fn_name=%sysfunc(substr(&fn_name, 5));
	%put buff3: &fn_name.;
    /* Split at opening parenthesis */
    %let fn_name = %sysfunc(scan(&fn_name, 1, '('));
	%put buff4: &fn_name.;
    &fn_name
%mend;

%MACRO py_register / parmbuff;
	%put PARMBUFF:;
	%put &syspbuff.;
    %let syspbuff = %py__strip_parens(&syspbuff);

    %local _py_fn_name _py_fn_def _py_fn_args _py_fn_args_list _py_fn_output;
    %py__define_variables;
    
    %if %table_exists(lib=work, table=py_fn_register)=0 %then %py__initialize_py_fns_table(&syspbuff);

    %put Registering Python function &_py_fn_name;
    %put &_py_fn_def;

    proc fcmp outlib=work.py_fns.funcs;
        function &_py_fn_name.(&_py_fn_args_list);
            declare object py_fn(python);
            submit into py_fn;
                def &_py_fn_name.(&_py_fn_args_list):
                    "Output: &_py_fn_output"
                    &_py_fn_def
            endsubmit;
            
            rc = py_fn.publish();
            rc = py_fn.call("&_py_fn_name.", &_py_fn_args_list);
            return(py_fn.results["&_py_fn_output"]);
        endsub;
    run;
%MEND;


%MACRO table_exists(lib=WORK, table=);
    %local exists;
    %let exists = 0;
    %let dsid = %sysfunc(open(&lib..&table));
    %if &dsid %then %do;
        %let exists = 1;
        %let rc = %sysfunc(close(&dsid));
    %end;
    &exists
%MEND table_exists;

/* Unit Tests -- py.sas */
%macro test_py;

    %put ==========================>> Running unit tests for py.sas;
    %include "/sas/data/project/EG/aweaver/macros/assert.sas";

    %let test_report_buffer = '';

    /* Test helper macro: py__get_fn_name */
    %let test_fn = def my_func(x, y): return x + y;
    %let fn_name = %py__get_fn_name(&test_fn);
    %assertEqual(&fn_name, my_func, Extract function name);

    /* Test helper macro: py__get_fn_args */
    %let args = %py__get_fn_args(&test_fn);
    %assertEqual(&args, x, y, Extract function arguments);

    /* Test helper macro: py__get_fn_def */
    %let def = %py__get_fn_def(&test_fn);
    %assertEqual(&def, return x + y, Extract function definition);

    /* Test function registration */
    %py_register(
        def test_add(a, b):
            return a + b
    );
    %assertTrue(%sysfunc(exist(work.py_fn_register)), Function table created);
    
    /* Test Python function execution */
    options cmplib=work.py_fns;
    data _null_;
        result = test_add(2, 3);
        call symputx('test_result', result);
    run;
    %assertEqual(&test_result, 5, Python function execution);

    %test_summary;

	%put ==========================>> Running unit tests for py.sas [DONE];
%mend;

%test_py;

%put ======================>> Loading py.sas [DONE];