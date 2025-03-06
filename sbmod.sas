/* Upon loading this module define the following global vars: */
%macro __define_globals;
    %global __SBMOD_HOME; /* A list of directories to search for modules */
    %global __SBMOD_ALIASES; /* A list of the same size as __SBMOD_HOME, containing aliases for the directories */
    %global __SBMOD_DEFAULT_ALIAS; /* The default alias to use when none is provided */
    %global __SBMOD_DEFAULT_ALIAS; /* The current list of imports */

    %let __SBMOD_HOME = /sas/data/project/EG/ActShared/SmallBusiness/Modeling/sas_modules /sas/data/project/EG/aweaver/macros;
    %let __SBMOD_ALIASES = sb aw;
    %let __SBMOD_DEFAULT_ALIAS = sb;
    %let __SBMOD_IMPORTS = sb::sbmod;

%mend __define_globals;

%__define_globals;

%macro add_repo(alias, path, make_default=0);
    /* Add a repository to the list of repositories */
    %let __SBMOD_HOME = &__SBMOD_HOME. &path.;
    %let __SBMOD_ALIASES = &__SBMOD_ALIASES. &alias.;
    %if &make_default.=1 %then
        %let __SBMOD_DEFAULT_ALIAS = &alias.;
%mend add_repo;

%macro publish_module(module_name, from_alias, to_alias=sb);
    /* Publish a module from one alias to another (defaulting to sb) */

    %sbmod(sb::shell);

    %_validate_alias(&from_alias.);
    %_validate_alias(&to_alias.);

    %let from_file = %_get_resolved_filename(&from_alias.:&module_name.);
    %let to_file = %_get_resolved_filename(&to_alias.:&module_name.);

    %if %sysfunc(fileexist(&from_file.)) %then %do;
        %let rc = %sysfunc(filename(from, &from_file.));
        %let rc = %sysfunc(filename(to, &to_file.));
        %let rc = %sysfunc(fcopy(from, to));
        %let rc = %sysfunc(filename(from));
        %let rc = %sysfunc(filename(to));
        %put NOTE: Module &module_name. published from &from_alias. to &to_alias.;
    %end;
    %else %do;
        %put ERROR: Module &module_name. not found at &from_file.;
    %end;

%macro _define_dynamic_macro_variable(varname, value);
    data _null_;
        call execute('%let ' || "&varname." || " = " || "&value.");
    run;
%mend _define_dynamic_macro_variable;

%macro _truncate_varname(varname);
/* Truncate a macro variable name >32 characters down to 
   32 characters */
    %substr(&varname., 1, 31)
%mend _truncate_varname;

%macro _import_variable(varname);
/* This is the main import code block. It runs when all the applicable
   conditions pass. */
    %global &varname.;
    %let file=&base_path/&module..sas;

    %if %sysfunc(fileexist(&file.)) %then %do;
        %include "&file.";
        %_define_dynamic_macro_variable(&varname., 1);
        %put NOTE: Module &module. imported successfully.;
    %end;

    %else %do;
        %put ERROR: Module &module. not found at &file.;
    %end;
%mend _import_variable;

%macro _extract_alias(module);
    /* If the module is prefixed by an alias, return the alias, otherwise return the default alias */
    %local alias;
    %let alias = %scan(&module., 1, :);
    %if %length(&alias.) = 0 %then
        %let alias = &__SBMOD_DEFAULT_ALIAS.;
    &alias.
%mend _extract_alias;

%macro _is_alias_known(alias);
    /* Check if the alias is known */
    %local known;
    %let known = 0;
    %do i = 1 %to %sysfunc(countw(&__SBMOD_ALIASES.));
        %if %scan(&__SBMOD_ALIASES., &i.) = &alias. %then
            %let known = 1;
    %end;
    &known.
%mend _is_alias_known;

%macro _validate_alias(module);
    /* Validate the alias */
    %local alias;
    %let alias = %_extract_alias(&module.);
    %if %_is_alias_known(&alias.) = 0 %then %do;
        %put ERROR: Alias &alias. is not known.;
        %return;
    %end;
%mend _validate_alias;

%macro _get_base_path(alias);
    /* Get the base path for the alias. This assumes that the alias has already been extracted and is known */
    %local base_path;
    %let base_path = %scan(&__SBMOD_HOME., %sysfunc(findw(&__SBMOD_ALIASES., &alias.)));
    &base_path.
%mend _get_base_path;

%macro _get_resolved_filename(module);

    %_validate_alias(&module.);
    %let alias = %_extract_alias(&module.);
    %let base_path = %_get_base_path(&alias.);
    %let file = &base_path./&module..sas;
    &file.
%mend _get_resolved_filename;

%macro _get_module_name(module);
    /* Get the module name without the alias */
    %let alias = %_extract_alias(&module.);
%mend _get_module_name;

%macro _add_mod_to_glbl_scp(module);
    /* Add the imported module to the global scope */
    %let cur_imports=&__SBMOD_IMPORTS.;
    %let __SBMOD_IMPORTS = &cur_imports. &module.;
%mend _add_mod_to_glbl_scp;

%macro check_if_module_already_imported(module);
    /* Check if the module has already been imported */
    %let varname=_imported__&module.;
    %if %length(&varname.) >= 32 %then
        %let varname=%_truncate_varname(&varname.);

    %if %symexist(&varname.) ne 1 %then
        %return 0;
    %else
        %return 1;

%mend check_if_module_already_imported;

%macro sbmod(
    module /* Module name to import, potentially prefixed by an alias and two colons */
    , base_path /* Folder containing the module to import */
    , reload=NO /* If the module has already been defined in this session, should it be redefined? Generally no, but during macro development this could make sense. */
);
    /*
        The `sbmod` macro is used to import a module into the global scope.
        The module is only imported once, and subsequent calls to `sbmod` with the
        same module name will not re-import the module. (This is the goal of the varname)
        variable. The module is assumed to be located in the directory
        `/sas/data/project/EG/aweaver/macros/` and have the file extension `.sas`.

        Usage:
        %sbmod(module_name);
        Includes the module `module_name` into the global scope, assuming you are
        using the default `sb` repository.

        %sbmod(module_name, base_path=/path/to/modules);
        Includes the module `module_name` into the global scope, where the module
        is located at `/path/to/modules/module_name.sas`.

        %sbmod(module_name, reload=YES);
        Includes the module `module_name` into the global scope, even if it has
        already been imported. This is useful for development purposes.

        %sbmod(aw::shell);
        Includes the module `shell` into the global scope, but loading the version inside
        the `aw` directory instead of the default `sb` directory.
    */
    %let varname=_imported__&module.;
	%if %length(&varname.) >= 32 %then
		%let varname=%_truncate_varname(&varname.);

    %if %symexist(&varname.) ne 1 %then %do;
        %_import_variable(&varname.);
    %end;
    %else %do;
        %if (%symexist(&varname.)=1)
            and ("&reload." ne "NO") %then %do;
            %_import_variable(&varname.);
        %end;
        %else %do;
            %put NOTE: Module &module. already imported.;
        %end;
    %end;
%mend sbmod;


%macro sbmod_imports;
    /* Import all the modules in the __SBMOD_IMPORTS list */
    %do i = 1 %to %sysfunc(countw(&__SBMOD_IMPORTS.));
        %sbmod(%scan(&__SBMOD_IMPORTS., &i.));
    %end;
%mend sbmod_imports;

%sbmod_imports;

%macro test_sbmod_helper_macros;
    %sbmod(sb::assert);
    %sbmod(sb::shell);

    %test_suite(Testing the sbmod helper macros);
        %let cur_sbmod_home = &__SBMOD_HOME.;
        %let cur_sbmod_aliases = &__SBMOD_ALIASES.;
        %let cur_sbmod_default_alias = &__SBMOD_DEFAULT_ALIAS.;
        %let cur_sbmod_imports = &__SBMOD_IMPORTS.;
        
        %assertEqual(&cur_sbmod_home., /sas/data/project/EG/ActShared/SmallBusiness/Modeling/sas_modules /sas/data/project/EG/aweaver/macros);
        %assertEqual(&cur_sbmod_aliases., sb aw);
        %assertEqual(&cur_sbmod_default_alias., sb);
        %assertEqual(&cur_sbmod_imports., sb::sbmod sb::assert sb::shell);
        
    %test_summary;

%mend test_sbmod_helper_macros;