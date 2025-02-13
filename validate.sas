%macro validate_exists(x, required=1);
    %let is_len_0=%eval(%length(&x.)=0);
    %let is_required=%eval(&required.=1);

    %if &is_len_0. * &is_required. %then %return(0);
    %else %return(1);
%mend validate_exists;