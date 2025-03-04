/* This module defines macros for lazy evaluation inside SAS macros. */
%macro lazy( cmd /* Command to execute lazily */ );

    %local cmd;
    %let cmd=&cmd;

    /* Lazy execute the command */
    %let out=%nbrquote(&cmd);
    &out. %mend lazy;

%macro collect( lazy_cmd /* Command previously defined with the lazy macro */ );

    %local lazy_cmd;
    %let lazy_cmd=&lazy_cmd;

    /* Execute the lazy command */
    %let out=%unquote(&lazy_cmd.);
    &out. %mend collect;

%macro collect_in_place( lazy_cmd
    /* Command previously defined with the lazy macro */ );

    %local lazy_cmd;
    %let lazy_cmd=&lazy_cmd;

    /* Execute the lazy command */
    %unquote(&lazy_cmd.);

%mend collect_in_place;
