/*  RUN ONCE  */
/*=======================================================================*/
/* Code to grab relevant Experian data to calculate SB credit 			 */
/* score variable.														 */
/*																		 */
/* Final output table is credit_vars, which contains policy identifiers, */
/* Experian snapshot variables, and calcuated credit score variables.	 */
/*=======================================================================*/

%Macro Credit_Model(Rerated_TBL,LOB);

	/*	Obtain all cfxmlids from current EV  */
	proc sql;
	create table &LOB._pols as 
	select distinct
		cfxmlid
		,%policy_5_key
		,imageeffectivedate format=yymmddd10.
		,imageexpirationdate format=yymmddd10.

	from Exps_B15.&Rerated_TBL.; 
	quit;


	proc sql;
	create table &LOB._credit_vars as 
	select distinct
		t1.*
		,t2.date_of_data_dt format=yymmddd10. 

		,%column_is_not_missing(t2.bin) as bin_hit
		,%is_between_1_and_100(t2.commercial_intelliscore) as exp_hit

		/*	Raw variables from snapshot */
		,t2.bin
		,t2.yearsinfile
		,t2.commercial_intelliscore
		,t2.alltrades
		,t2.baltot
		,t2.ballate_all_dbt
		,t2.numtot_combined
		,t2.baltot_combined
		,t2.judgmentcount
		,t2.liencount
		,input(t2.bkc006,8.) as bankruptcy_cnt
		,date_of_data

		/* Calculated variables */

		,%is_column_positive(t2.alltrades) as &LOB._alltrades_positive
		,%is_column_positive(t2.baltot) as &LOB._baltot_positive
		,%is_column_positive(t2.numtot_combined) as &LOB._numtot_combined_positive
		,%is_column_positive(t2.baltot_combined) as &LOB._baltot_combined_positive

		,%safe_ratio(t2.ttc039, t2.ttc038) as pay_sat

			/* Median-imputed variables */
			/* 0 means Missing and 1 Available			*/
		,coalesce(t2.bin,t3.EXPERIAN_BIN_m1,t3.EXPERIAN_BIN_0) as BIN_2
		,case when missing(Calculated BIN_2) Then 0 Else 1 End as BIN_2_Source

		,coalesce(t2.baltot,t3.BAL_TOT_m1,t3.BAL_TOT_0) as &LOB._BalTot_2
		,case when missing(t2.baltot) Then 0 Else 1 End as &LOB._BalTot_Source

		,coalesce(t2.alltrades,t3.ALL_TRADE_CNT_m1,t3.ALL_TRADE_CNT_0) as &LOB._AllTrades_2
		,case when missing(t2.alltrades) Then 0 Else 1 End as &LOB._AllTrades_Source

		,coalesce(t2.commercial_intelliscore,t3.COML_INTELSCR_m1,t3.COML_INTELSCR_0,60) as &LOB._commercial_intelliscore_2
		,Max(coalesce(t2.commercial_intelliscore,t3.COML_INTELSCR_m1,t3.COML_INTELSCR_0,60),25) as &LOB._Floor25_Intelliscore_2
			/*The EP WAv of Prop_commercial_intelliscore_2 with hits is 56.215584018 & for GL is 59.612505395*/
			/*We decided to set the default for missing values to the lower multiple of 5, i. 55 and floored at 25*/
		,Case When Missing(coalesce(t2.commercial_intelliscore,t3.COML_INTELSCR_m1,t3.COML_INTELSCR_0)) Then 0 Else 1 End as &LOB._Comm_intelliscore_Source

		,coalesce(t2.yearsinfile,t3.NBR_YR_IN_FILE_m1,t3.NBR_YR_IN_FILE_0,21) as &LOB._yearsinfile_2
		,Case When Missing(coalesce(t2.yearsinfile,t3.NBR_YR_IN_FILE_m1,t3.NBR_YR_IN_FILE_0)) Then 0 Else 1 End as &LOB._yearsinfile_Source

		,coalesce(t2.ballate_all_dbt,.0071) as &LOB._ballate_all_dbt_2
		,Case When Missing(ballate_all_dbt) Then 0 Else 1 End as &LOB._ballate_all_dbt_Source

		,coalesce(t2.numtot_combined,5) as &LOB._numtot_combined_2
		,Case When Missing(t2.numtot_combined) Then 0 Else 1 End as &LOB._numtot_combined_Source

		,coalesce(pay_sat,.9444) as &LOB._pay_sat_2
		,Case When Missing(pay_sat) Then 0 Else 1 End as &LOB._pay_sat_Source
	
		,coalesce(t2.judgmentcount,0) as &LOB._judgmentcount_2
		,Case When Missing(t2.judgmentcount) Then 0 Else 1 End as &LOB._judgmentcount_Source

		,coalesce(t2.liencount,0) as &LOB._liencount_2
		,Case When Missing(t2.liencount) Then 0 Else 1 End as &LOB._liencount_Source

		,coalesce(calculated bankruptcy_cnt,0) as &LOB._bankruptcy_cnt_2
		,Case When Missing(calculated bankruptcy_cnt) Then 0 Else 1 End as &LOB._bankruptcy_cnt_Source

			/* Additional manipulations of median-imputed variables */

				/* YIF-normalized baltot_combined */
		,case when calculated &LOB._yearsinfile_2 le 1 then t2.baltot_combined else t2.baltot_combined / calculated &LOB._yearsinfile_2 end as &LOB._baltot_combined_y
		
		 			/* Median-imputed version */
	 	,coalesce(calculated &LOB._baltot_combined_y,127.78) as &LOB._baltot_combined_y_2	

					/* Median-imputed version, in thousands */
		,calculated &LOB._baltot_combined_y_2 / 1000 as &LOB._baltotk_combined_y_2			

					/* Median-imputed version, in thousands, capped at 10 */
		,min(calculated &LOB._baltotk_combined_y_2, 10) as &LOB._baltotk_combined_y_2_cap10	

				/* Capped version of numtot_combined */
		,min(calculated &LOB._numtot_combined_2,10) as &LOB._numtot_combined_2_cap10

				/* Positive-value indicators for judgments, liens, and bankruptcies */
		,case when calculated &LOB._judgmentcount_2 > 0 then 1 else 0 end as &LOB._judgmentcount_2_yn
		,case when calculated &LOB._liencount_2 > 0 then 1 else 0 end as &LOB._liencount_2_yn
		,case when calculated &LOB._bankruptcy_cnt_2 > 0 then 1 else 0 end as &LOB._bankruptcy_cnt_2_yn

			/*	Log credit score calculated from model; this is the original version that will be missing for BIN no-hits  */
		,case when calculated bin_hit = 0 then .
			  else 0.2856 * calculated &LOB._alltrades_positive
					- 0.2987 * calculated &LOB._alltrades_positive * calculated &LOB._pay_sat_2
					+ 0.0588 * calculated &LOB._baltot_positive
					+ 0.0724 * calculated &LOB._baltot_positive * calculated &LOB._ballate_all_dbt_2
					- 0.0216 * calculated &LOB._numtot_combined_positive * calculated &LOB._numtot_combined_2_cap10
					+ 0.0116 * calculated &LOB._baltot_combined_positive * calculated &LOB._baltotk_combined_y_2_cap10
					+ 0.2204 * calculated &LOB._judgmentcount_2_yn
					+ 0.1311 * calculated &LOB._liencount_2_yn
					+ 0.1514 * calculated &LOB._bankruptcy_cnt_2_yn
		 end as &LOB._log_credit_score

			/*  Credit score */
		,exp(calculated &LOB._log_credit_score) as &LOB._credit_score

			/*  Imputed log credit score and imputed credit score; the imputed log credit score should be used for LOB modeling  */
		,coalesce(calculated &LOB._log_credit_score,0) as &LOB._log_credit_score_2
		,case when (Missing (calculated &LOB._log_credit_score)) then 0 else 1 End as &LOB._LogCredit_Source
		,coalesce(calculated &LOB._credit_score,1) as &LOB._credit_score_2

	from &LOB._pols as t1
	left join ACTCOV28.&exp_data. as t2
		 on case when t1.historical_company = 'CID' then 3
		 		 when t1.historical_company = 'CIC' then 5
				 when t1.historical_company = 'CCC' then 7 end = t2.company_numb
		and t1.policysymbol = t2.policy_sym
		and input(t1.policynumber,7.) = t2.policy_numb
/*		and input(t1.statisticalpolicymodulenumber,3.) = t2.policy_module*/
		and t1.policyeffectivedate = t2.policy_eff_date
	left join my_mosum.&LOB._se_vars as t3
		on t1.cfxmlid=t3.cfxmlid

	order by cfxmlid, policyeffectivedate, BIN
/*	order by policyeffectivedate, input(scan(cfxmlid,2,'.'),9.), input(scan(cfxmlid,3,'.'),4.)*/
	; quit;
	
	proc sql;
		create table &LOB._credit_vars_Sorted as select
		*
		from &LOB._credit_vars
		Order by cfxmlid, policyeffectivedate, BIN
		; 
	quit;

	data  my_exp.&LOB._credit_vars_Final; 
		/*There are 673 records with more than one BIN in PROP & GL*/ 
		/*We are taking only the first one*/
	     set &LOB._credit_vars_Sorted;     
	     by cfxmlid;     
	     if (first.cfxmlid)   then Output;     
	run;

%Mend Credit_Model;

%Credit_Model(&prop_rerated., Prop);
%Credit_Model(&gl_rerated., GL);


Proc Datasets Nolist;
	Delete 	PROP_POLS GL_POLS PROP_CREDIT_VARS GL_CREDIT_VARS
				PROP_CREDIT_VARS_SORTED GL_CREDIT_VARS_SORTED
			;
Run;
