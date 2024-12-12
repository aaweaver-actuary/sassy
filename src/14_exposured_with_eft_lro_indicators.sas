
Proc SQL;
	Create Table EFT_Data_0 as
	Select distinct policy_sym, policy_numb, policy_eff_date, policy_module, pay_service_code
			,case 
				when missing(pay_service_code) then . 
				when pay_service_code = 'E' then 1 
				else 0
			 end as EFT_indicator
								
	FROM common.all_comm_policy_info
	Order By policy_sym, policy_numb, policy_eff_date, policy_module, pay_service_code
;
Quit;

%Macro IncorporateEFT(LOB);

Proc SQL;
	Create Table &LOB._w_EFT as
	Select a.*, b.EFT_indicator
				,Case When (Cin_BOP_Class in (10151,10156,10157)) Then 1 Else 0 End as LRO_Indicator

	FROM &LOB._w_Pcts as a 
			left join EFT_Data_0 as b
					ON input (a.statisticalpolicymodulenumber,2.)= b.policy_module
				and input (a.policynumber,7.) = b.policy_numb
				and a.policyeffectivedate = b.policy_eff_date
				and a.policysymbol=b.policy_sym

	Order By a.cfxmlid;
Quit;

%Mend IncorporateEFT;

%IncorporateEFT(PROP);
%IncorporateEFT(GL);



/*Incorporation of the BusCat split by LRO and incorporating the building age at record level*/
Proc SQL;
	Create Table Prj.Prop_w_EFT as
	Select * 
			,Case When (LRO_Indicator=1) Then 'Real_Estate_LRO_1'
				When ((LRO_Indicator=0)AND(Business_Category in('Construction'))) Then 'Construction_LRO_0'
				When ((LRO_Indicator=0)AND(Business_Category in('Real Estate','Services'))) Then 'RealEstate_N_Services_LRO_0'
				Else 'AllOther_BusCat_LRO_0' End format $30. as BusCat_LRO_Grps
			,Case When (buildingage_Banded ='50+') then 50 
							When(buildingage_Banded ='Default') Then . 
							Else input (buildingage_Banded,2.) End as BuildingAge
			,Case When(buildingage_Banded ='Default') Then 29 
							Else (calculated BuildingAge) End as BuildingAge_2
			,Case When(buildingage_Banded ='Default') Then 0 
							Else 1 End as BuildingAge_Source

	FROM Prop_w_EFT 
	Order By cfxmlid;
Quit;

Proc SQL;
	Create Table Prj.GL_w_EFT as
	Select * 
			,Case When (LRO_Indicator=1) Then 'Real_Estate_LRO_1'
				When ((LRO_Indicator=0)AND(Business_Category in('Construction'))) Then 'Construction_LRO_0'
				When ((LRO_Indicator=0)AND(Business_Category in('Services'))) Then 'Services_LRO_0'
				Else 'AllOther_BusCat_LRO_0' End format $30. as BusCat_LRO_Grps

	FROM GL_w_EFT 
	Order By cfxmlid;
Quit;



Proc Datasets Nolist;
	Delete PEFT_DATA_0 Prop_w_EFT GL_w_EFT
			GL_w_Pcts Prop_w_Pcts
			;
Run;

