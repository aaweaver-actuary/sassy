%macro ifelse(cond=, if_true=, if_false=);
%local out cond_val;

/* Check required parameters */
%if not %length(&cond.) or not %length(&if_true.) or not %length(&if_false.) %then %do;
  %put ERROR: All parameters (cond, if_true, if_false) are required.;
  %return;
%end;

%let cond_val = %sysevalf(&cond.);

/* Execute if/else logic */
%if &cond_val. = 1 %then %do;
  %let out = %bquote(&if_true.);
%end;
%else %do;
  %let out = %bquote(&if_false.);
%end;

/* Return final value */
%unquote(&out.)
%mend ifelse;