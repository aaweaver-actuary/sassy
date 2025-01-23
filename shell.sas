%MACRO shell(cmd);

filename unxcmd1 pipe "&cmd.";

data work._null_;
infile unxcmd1;
input;
put _infile_;
run;

%MEND shell;