%Macro Experian_Snapshots(LOB);
	/*	Pull relevant Experian variables from 6-month snapshots  */
	proc sql;
	create table &LOB._experian_snapshots as select distinct 
			*
			,case
				when not missing(date_of_data_dt) then date_of_data_dt
				when date_of_data = '092006' then '01Sep2006'd
				when date_of_data = '032007' then '01Mar2007'd
				when date_of_data = '092007' then '01Sep2007'd
				when date_of_data = '032008' then '01Mar2008'd
				when date_of_data = '092008' then '01Sep2008'd
				when date_of_data = '032009' then '01Mar2009'd
				when date_of_data = '092009' then '01Sep2009'd
				when date_of_data = '032010' then '01Mar2010'd
				when date_of_data = '092010' then '01Sep2010'd
				when date_of_data = '032011' then '01Mar2011'd
				when date_of_data = '092011' then '01Sep2011'd
				when date_of_data = '032012' then '01Mar2012'd
				when date_of_data = '092012' then '01Sep2012'd
				when date_of_data = '032013' then '01Mar2013'd
				when date_of_data = '092013' then '01Sep2013'd
				when date_of_data = '032014' then '01Mar2014'd
				when date_of_data = '092014' then '01Sep2014'd
				when date_of_data = '032015' then '01Mar2015'd
				when date_of_data = '092015' then '01Sep2015'd
				when date_of_data = '032016' then '01Mar2016'd
				when date_of_data = '092016' then '01Sep2016'd
				when date_of_data = '032017' then '01Mar2017'd
				when date_of_data = '092017' then '01Sep2017'd
				when date_of_data = '032018' then '01Mar2018'd
				when date_of_data = '092018' then '01Sep2018'd
				when date_of_data = '032019' then '01Mar2019'd
				when date_of_data = '092019' then '01Sep2019'd
				when date_of_data = '032020' then '01Mar2020'd
			 end format=yymmddd10. as date_of_data_dt

		from my_exp.&LOB._credit_vars_Final
		order by
			historical_company
			,policysymbol
			,policynumber
			,policyeffectivedate
			,date_of_data
			,calculated date_of_data_dt
		; quit;
%Mend Experian_Snapshots;

%Experian_Snapshots(PROP);
%Experian_Snapshots(GL);

%Macro MergeTo_Rerated (Rerated,LOB);
/*	Merge snapshot data with rerated data  */
	proc sql;
	create table tmp_&LOB._master_data_1 as select distinct
		t1.cfxmlid
		,t1.historical_company
		,t1.policysymbol
		,t1.policynumber
/*		,t1.statisticalpolicymodulenumber*/
		,t1.policyeffectivedate
		,t1.imageeffectivedate
		,t1.imageexpirationdate
		,t3.*
		,t3.date_of_data_dt - t1.imageeffectivedate as expr_diff_days
		,abs(calculated expr_diff_days) as abs_expr_diff_days
		/*	Could also bring in annual premium to normalize some variables.
			We will do this after ISO OCP premium is available.  */
	from Exps_B15.&Rerated. as t1
	left join &LOB._experian_snapshots as t3
		 on t1.historical_company = t3.historical_company
		and t1.policysymbol = t3.policysymbol
		and t1.policynumber = t3.policynumber
/*		and input(t1.statisticalpolicymodulenumber,4.) = t3.policy_module*/
		and t1.policyeffectivedate = t3.policyeffectivedate
	order by
		cfxmlid
		,abs_expr_diff_days
		,expr_diff_days
	; quit;

	/*	Take only the closest Experian snapshot per cfxmlid */
	proc sort data=tmp_&LOB._master_data_1 out=tmp_&LOB._master_data_2 nodupkey;
	by cfxmlid;
	run;

%Mend MergeTo_Rerated;


%MergeTo_Rerated (&prop_rerated., PROP);
%MergeTo_Rerated (&gl_rerated., GL);



Proc Datasets Nolist;
	Delete 	TMP_PROP_MASTER_DATA_1 
				TMP_GL_MASTER_DATA_1 
			;
Run;
