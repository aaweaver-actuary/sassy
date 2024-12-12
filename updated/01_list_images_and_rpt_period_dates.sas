%Macro images(EV_TBL,LOB);
	proc sql;
	create table images_&LOB. as select distinct
		cfxmlid
		,historical_company as company_numb
		,policysymbol as policy_sym
		,policynumber as policy_numb
		,statisticalpolicymodulenumber as policy_module
		,policyeffectivedate as policy_eff_date
		,imageeffectivedate as image_eff_date
		,imageexpirationdate as image_exp_date

		,%first_rpt_period_date_after(imageeffectivedate) format yymmddd10. as rpd
		,%first_rpt_period_date_before(imageeffectivedate) format yymmddd10. as rpd_m1

	from Exps_B15.&EV_TBL.
	; quit;
%Mend Images;

%Images(&prop_rerated., Prop);
%Images(&gl_rerated., GL);
