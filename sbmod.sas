%macro sbmod(module, base_path=/sas/data/project/EG/aweaver/macros);
    /*
    The `sbmod` macro is used to import a module into the global scope.
    The module is only imported once, and subsequent calls to `sbmod` with the
    same module name will not re-import the module. (This is the goal of the varname)
    variable. The module is assumed to be located in the directory
    `/sas/data/project/EG/aweaver/macros/` and have the file extension `.sas`.

    Usage:
    %sbmod(module_name);
    Includes the module `module_name` into the global scope, assuming you are
    using Andy's macro repository.

    %sbmod(module_name, base_path=/path/to/modules);
    Includes the module `module_name` into the global scope, where the module
    is located at `/path/to/modules/module_name.sas`.
    */
    %let varname=_imported__&module.;
    %if %symexist(&varname.) ne 1 %then %do;
        %global &varname.;
        %let file=&base_path/&module..sas;

        %if %sysfunc(fileexist(&file.)) %then %do;
            %include "&file.";

            data _null_;
                call execute('%let ' || "&varname." || ' = 1;');
            run;
            %put NOTE: Module &module. imported successfully.;
        %end;
        %else %do;
            %put ERROR: Module &module. not found at &file.;
        %end;
    %end;
    %else %do;
        %put NOTE: Module &module. already imported.;
    %end;
%mend sbmod;

