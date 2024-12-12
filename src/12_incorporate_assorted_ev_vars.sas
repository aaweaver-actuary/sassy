
%Let BCommVars= b.paymentmethoddescription, b.premiumpaymentplandescription;
%Let PropVars= risktypecode;
%Let BPropVars= b.risktypecode;
%Let BGLVars= b.generalaggregatelimitamount, b.productaggregatelimitamount, b.occurrencelimitamount;

Proc SQL;
	Create Table PROP_EV_Vars as
	Select Distinct b.cfxmlid, b.ghost, &BCommVars., &BPropVars., b.billingmethoddescription
					 
	FROM smbizhal.&prop_ev. as b
	Where(b.ghost=0)
	Order by cfxmlid, &BCommVars., &BPropVars.
	;
Quit;

Proc SQL;
	Create Table PROP_w_Add_EvVars_0 as
	Select a.*, &BCommVars.,  &BPropVars., b.billingmethoddescription
	FROM Prj.PROP_Rerated_w_TTTnPPT as a left join PROP_EV_Vars as b
	ON a.cfxmlid=b.cfxmlid 
	Order By cfxmlid;
Quit;

Proc SQL;
	Create Table BuildingsPerLoc as
	Select Distinct cfxmlid, locationnumber, NumberBuildingsLoc, state, zipcode
					 
	FROM PROP_w_Add_EvVars_0
	Order by cfxmlid
	;
Quit;

Proc SQL;
	Create Table PROP_Buildings_n_Loc_Cnts as
	Select Distinct cfxmlid, count(Distinct locationnumber) as NumberLocationsPol, sum(NumberBuildingsLoc) as NumberBuildingsPol
					 
	FROM BuildingsPerLoc
	Group by cfxmlid
	Order by cfxmlid
	;
Quit;

Proc SQL;
	Create Table PROP_w_Add_EvVars_1 as
	Select a.*, b.NumberLocationsPol,  b.NumberBuildingsPol
					,Count(Distinct a.state) as NumberStatesPol, Count(Distinct a.zipcode) as NumberZipsPol
					,sum(a.BuildingLOI,a.BPPLOI) as Bld_n_BPP_LOI_Key_Level
					,sum(a.BOP_Bldg_Earned_Manual_Premium,a.BOP_BPP_Earned_Manual_Premium) as Prop_EP_KeyLevel
			
	FROM PROP_w_Add_EvVars_0 as a left join PROP_Buildings_n_Loc_Cnts as b
	ON a.cfxmlid=b.cfxmlid 
	Group by a.cfxmlid
	Order By a.cfxmlid;
Quit;

Proc SQL;
	Create Table Auto_EV_Pols as
	Select Distinct cfxmlid
					 
	FROM smbizhal.&auto_ev.
	Order by cfxmlid
	;
Quit;

Proc SQL;
	Create Table PROP_w_Add_EvVars_2 as
	Select a.*, Case When(Missing(b.cfxmlid)) Then 'NoAutoPolicy' Else 'YesAutoPolicy' End as AutoPolicyIndicator
				,sum(a.BOP_Bldg_Annual_Manual_Premium) as Bldg_Annual_ManPrem_PolLevel
				,sum(a.BOP_BPP_Annual_Manual_Premium) as BPP_Annual_ManPrem_PolLevel 
				,Case 
					When((Calculated Bldg_Annual_ManPrem_PolLevel >0)AND(Calculated BPP_Annual_ManPrem_PolLevel =0)) Then 'BuildingOnly'
					When((Calculated Bldg_Annual_ManPrem_PolLevel =0)AND(Calculated BPP_Annual_ManPrem_PolLevel >0)) Then 'BPPOnly'
					When((Calculated Bldg_Annual_ManPrem_PolLevel >0)AND(Calculated BPP_Annual_ManPrem_PolLevel >0)) Then 'BothBldgnBPP'
					Else 'None' 
				End as CoverageInd_PolLevel
	FROM PROP_w_Add_EvVars_1 as a left join Auto_EV_Pols as b
	ON a.cfxmlid=b.cfxmlid 
	Group by a.cfxmlid
	Order By a.cfxmlid;
Quit;

%Let WbXLS = '/sas/data/project/EG/ActShared/SmallBusiness/BOP_modeling/BOP1_5ModelingData/Reference/RangeChangeBin.xls';
/*The source of this file is Dan's email dated on March 16/2021*/

PROC IMPORT OUT= RangeChangeBinTBL
			DATAFILE= &WbXLS. 
            DBMS=XLS REPLACE;
			SHEET = "BIN";
     GETNAMES=YES;
RUN;

%Let WbXLS = '/sas/data/project/EG/ActShared/SmallBusiness/BOP_modeling/BOP1_5ModelingData/Reference/RateChange.xls';
/*The source of this file is Dan's email dated on March 16/2021*/

PROC IMPORT OUT= RateChangeTBL
			DATAFILE= &WbXLS. 
            DBMS=XLS REPLACE;
			SHEET = "RateChange";
     GETNAMES=YES;
RUN;

Proc SQL;
	Create Table RatenRangeChangeBinTBL as
	Select a.*, b.RateChange
				, Case When(b.RateChange='N/A') Then 'Missing' Else 'Available' End as RateChangeIndicator 
							
	FROM RangeChangeBinTBL as a left join RateChangeTBL as b
	ON a.BOPClass=b.BOPClass
	Order By a.state, a.BOPClass;
Quit;

Proc SQL;
	Create Table PROP_w_Add_EvVars_3 as
	Select a.*, b.RangeChangeBin, b.RateChange, b.RateChangeIndicator
				, Case When(Missing(b.RangeChangeBin)) Then 'Missing' Else 'Available' End as RangeChangeBinIndicator 
							
	FROM PROP_w_Add_EvVars_2 as a left join RatenRangeChangeBinTBL as b
	ON a.State=b.State  AND a.BOPClass=b.BOPClass
	Order By a.cfxmlid;
Quit;

%Let WbXLS = '/sas/data/project/EG/ActShared/SmallBusiness/BOP_modeling/BOP1_5ModelingData/Reference/20190507_Compare_ISO_CIC.xls';
/*The source of this file is Dan's email dated on August 28/2020*/

PROC IMPORT OUT= AutoTerritorialTBL
			DATAFILE= &WbXLS. 
            DBMS=XLS REPLACE;
			SHEET = "COMPARE_ISO_CIC";
     GETNAMES=YES;
RUN;

Proc SQL;
	Create Table PROP_w_Add_EvVars_4 as
	Select a.*
				,Case When(Missing(b.AutoTerritorialRel)) Then 'Missing' Else 'Available' End as AutoTerritorialIndicator 
				,Case When(Missing(b.AutoTerritorialRel)) Then 1 Else b.AutoTerritorialRel End as AutoTerritorialRel 
/*1 is the default used by Doug; see Dan's email dated on July 23/2020*/
				,Case 
						When(Calculated AutoTerritorialRel<0.5) Then '1) LT0.5'
						When(Calculated AutoTerritorialRel<0.6) Then '2) HE0.5 - LT0.6'
						When(Calculated AutoTerritorialRel<0.7) Then '3) HE0.6 - LT0.7'
						When(Calculated AutoTerritorialRel<0.8) Then '4) HE0.7 - LT0.8'
						When(Calculated AutoTerritorialRel<0.9) Then '5) HE0.8 - LT0.9'
						When(Calculated AutoTerritorialRel<1.0) Then '6) HE0.9 - LT1.0'
						When(Calculated AutoTerritorialRel=1.0) Then '7) E1.0'
						When(Calculated AutoTerritorialRel<1.1) Then '8) HE1.0 - LT1.1'
						When(Calculated AutoTerritorialRel<1.2) Then '9) HE1.1 - LT1.2'
						When(Calculated AutoTerritorialRel<1.3) Then '10) HE1.2 - LT1.3'
						When(Calculated AutoTerritorialRel<1.4) Then '11) HE1.3 - LT1.4'
						When(Calculated AutoTerritorialRel<1.5) Then '12) HE1.4 - LT1.5'
						When(Calculated AutoTerritorialRel<1.6) Then '13) HE1.7 - LT1.6'
						When(Calculated AutoTerritorialRel<1.7) Then '14) HE1.6 - LT1.7'
						When(Calculated AutoTerritorialRel<1.8) Then '15) HE1.7 - LT1.8'
						When(Calculated AutoTerritorialRel<1.9) Then '16) HE1.8 - LT1.9'
						When(Calculated AutoTerritorialRel<2.0) Then '17) HE1.9 - LT2.0'
						Else '18) HTE2.0'
					End as 	AutoTerritorialBracket

	FROM PROP_w_Add_EvVars_3 as a left join AutoTerritorialTBL as b
	ON a.zipcode=b.zip  AND a.state=b.state
	Order By a.cfxmlid;
Quit;


Proc SQL;
	Create Table PROP_w_Add_EvVars_5 as
	Select * 
			,Case 
				When((BOP_Bldg_Annual_Manual_Premium>0)AND(BOP_BPP_Annual_Manual_Premium=0)) Then  'BuildingOnly'
				When((BOP_Bldg_Annual_Manual_Premium=0)AND(BOP_BPP_Annual_Manual_Premium>0)) Then  'BPPOnly'
				When((BOP_Bldg_Annual_Manual_Premium>0)AND(BOP_BPP_Annual_Manual_Premium>0)) Then  'BothBldgnBPP'
			Else 'None' End as CoverageInd_RecordLevel
	
			,Case 
				When((BOP_Bldg_Annual_Manual_Premium>0)) Then  BOP_Bldg_Annual_Manual_Premium/sum(BOP_Bldg_Annual_Manual_Premium,BOP_BPP_Annual_Manual_Premium)
			Else 0 End format percent10.2 as CFPremPctBlg_RecordLevel
	
			,Case 
				When((BOP_BPP_Annual_Manual_Premium>0)) Then  BOP_BPP_Annual_Manual_Premium/sum(BOP_Bldg_Annual_Manual_Premium,BOP_BPP_Annual_Manual_Premium)
			Else 0 End format percent10.2 as CFPremPctBPP_RecordLevel

			,Case 
				When((BuildingLOI>0)) Then  BuildingLOI/sum(BuildingLOI,BPPLOI)
			Else 0 End format percent10.2 as CFLOIPctBlg_RecordLevel
	
			,Case 
				When((BPPLOI>0)) Then  BPPLOI/sum(BuildingLOI,BPPLOI)
			Else 0 End format percent10.2 as CFLOIPctBPP_RecordLevel	

	FROM PROP_w_Add_EvVars_4 
	Order By cfxmlid;
Quit;

/*Incorporating Square Footage variables*/
Proc SQL;
	Create Table EV_SqrtF as 
	Select Distinct Cfxmlid, locationnumber, buildingnumber, Input(square_footage,20.) as Sqrt_Footage, ghost

	FROM smbizhal.&prop_ev. as a
	Where (ghost=0)

	Order by cfxmlid, locationnumber, buildingnumber
;
Quit;

Proc SQL;
	Create Table PROP_w_Add_EvVars_6 as 
	Select a.*, b.Sqrt_Footage

			, Case When (b.Sqrt_Footage>0) Then BOP_Bldg_Annual_Manual_Premium/b.Sqrt_Footage
				Else .  end as BldgAMP_SqrtFoot

			,case 
					when(((calculated BldgAMP_SqrtFoot)=0)OR(Missing(calculated BldgAMP_SqrtFoot))) Then 3
					when(((calculated BldgAMP_SqrtFoot)>0)AND((calculated BldgAMP_SqrtFoot)<=0.11)) Then 1
					when(((calculated BldgAMP_SqrtFoot)>0.11)AND((calculated BldgAMP_SqrtFoot)<=0.19)) Then 2
					when(((calculated BldgAMP_SqrtFoot)>0.19) AND((calculated BldgAMP_SqrtFoot)<=0.29)) Then 3
					when(((calculated BldgAMP_SqrtFoot)>0.29) AND((calculated BldgAMP_SqrtFoot)<=0.45)) Then 4
					when(((calculated BldgAMP_SqrtFoot)>0.45)) Then 5
					Else -1 End as BldgAMP_SqrtF_Grp

			,case 
					when(((calculated BldgAMP_SqrtFoot)=0)OR(Missing(calculated BldgAMP_SqrtFoot))) Then 0
					Else 1 End as BldgAMP_SqrtF_Source

			,Case When (b.Sqrt_Footage>0) Then (BOP_Bldg_Annual_Manual_Premium+BOP_BPP_Annual_Manual_Premium)/b.Sqrt_Footage
				Else .  end as BldgNBPPAMP_SqrtFoot

			, Case When (b.Sqrt_Footage>0) Then BuildingLOI/b.Sqrt_Footage
				Else .  end as BldgLOI_SqrtFoot


	FROM PROP_w_Add_EvVars_5 as a
		Left join EV_SqrtF as b
			On((a.cfxmlid=b.cfxmlid)AND(a.locationnumber=b.locationnumber)AND(a.buildingnumber=b.buildingnumber))

	Order by a.cfxmlid, a.locationnumber, a.buildingnumber
;
Quit;


Proc SQL;
	Create Table Prj.PROP_w_Add_EvVars as
	Select Distinct *, sum(BuildingLOI) as Bld_LOI_Policy, sum(BPPLOI) as BPP_LOI_Policy
					 , sum(BOP_Bldg_Annual_Manual_Premium) as CF_Bldg_AnnualMP_Policy
					 , sum(BOP_BPP_Annual_Manual_Premium) as CF_BPP_AnnualMP_Policy
						, Coalesce(sum(Bld_n_BPP_LOI_Key_Level),0) as Bld_n_BPP_LOI_Policy

						,case When ((Calculated Bld_n_BPP_LOI_Policy = 0)) Then  0
								Else (Calculated Bld_LOI_Policy)/(Calculated Bld_n_BPP_LOI_Policy) 
							End format percent10.2 as CFBuildLOIPct_PolLevel

						,case When ((Calculated Bld_n_BPP_LOI_Policy = 0)) Then  0
								Else (Calculated BPP_LOI_Policy)/(Calculated Bld_n_BPP_LOI_Policy) 
							End format percent10.2 as CFBPPLOIPct_PolLevel

						,case When ((Calculated CF_Bldg_AnnualMP_Policy = 0)) Then  0
								Else (Calculated CF_Bldg_AnnualMP_Policy)/sum((Calculated CF_Bldg_AnnualMP_Policy),(Calculated CF_BPP_AnnualMP_Policy))
							End format percent10.2 as CFBldgPremPct_PolLevel

						,case When ((Calculated CF_BPP_AnnualMP_Policy = 0)) Then  0
								Else (Calculated CF_BPP_AnnualMP_Policy)/sum((Calculated CF_Bldg_AnnualMP_Policy),(Calculated CF_BPP_AnnualMP_Policy))
							End format percent10.2 as CFBPPPremPct_PolLevel

						,sum(Prop_EP_KeyLevel) as PROP_EP_Policy
						,Case 
							When(Calculated PROP_EP_Policy LT 10000) Then 'a) LT10'
							When(Calculated PROP_EP_Policy lt 15000) Then 'b) GE10_LT15'
							When(Calculated PROP_EP_Policy lt 20000) Then 'c) GE15_LT20'
							When(Calculated PROP_EP_Policy lt 25000) Then 'd) GE20_LT25'
							When(Calculated PROP_EP_Policy lt 30000) Then 'e) GE25_LT30'
							When(Calculated PROP_EP_Policy lt 40000) Then 'f) GE30_LT40'
							When(Calculated PROP_EP_Policy lt 50000) Then 'g) GE40_LT50'
							When(Calculated PROP_EP_Policy lt 75000) Then 'h) GE50_LT75'
							When(Calculated PROP_EP_Policy lt 100000) Then 'i) GE75_LT100'
							When(Calculated PROP_EP_Policy lt 125000) Then 'j) GE100_LT125'
							When(Calculated PROP_EP_Policy lt 150000) Then 'k) GE125_LT150'
							When(Calculated PROP_EP_Policy lt 175000) Then 'l) GE150_LT175'
							When(Calculated PROP_EP_Policy lt 200000) Then 'm) GE175_LT200'
							When(Calculated PROP_EP_Policy lt 300000) Then 'n) GE200_LT300'
						   	Else 'o) 300+' 
						End as EP_Bracket
					 
	FROM PROP_w_Add_EvVars_6
	Group by cfxmlid
	Order by cfxmlid
	;
Quit;

Proc SQL;
	Create Table GL_EV_Vars as
	Select Distinct b.cfxmlid, b.ghost, &BCommVars., &BGLVars., b.billingmethoddescription
					,sum(b.generalaggregatelimitamount, b.productaggregatelimitamount,b.occurrencelimitamount) as TotalGL_limitamount
	FROM smbizhal.&gl_ev. as b
	Where(b.ghost=0)
	Order by cfxmlid, &BCommVars., &BGLVars.
	;
Quit;

Proc SQL;
	Create Table GL_w_Add_EvVars_0  as
	Select a.*, &BCommVars.,  &BGLVars., b.TotalGL_limitamount
				, BOP_GL_Annual_Manual_Premium*numberofexposuredays/365.25 as EP_Calc_Key_Level, b.billingmethoddescription

	FROM Prj.GL_Rerated_w_TTTnPPT as a left join GL_EV_Vars as b
	ON a.cfxmlid=b.cfxmlid 
	Order By cfxmlid;
Quit;

Proc SQL;
	Create Table GL_w_Add_EvVars_1 as
	Select a.*, Case When(Missing(b.cfxmlid)) Then 'NoAutoPolicy' Else 'YesAutoPolicy' End as AutoPolicyIndicator 
							
	FROM GL_w_Add_EvVars_0 as a left join Auto_EV_Pols as b
	ON a.cfxmlid=b.cfxmlid 
	Group by a.cfxmlid
	Order By a.cfxmlid;
Quit;


Proc SQL;
	Create Table GL_w_Add_EvVars_2 as
	Select a.*
				,Case When(Missing(b.AutoTerritorialRel)) Then 'Missing' Else 'Available' End as AutoTerritorialIndicator 
				,Case When(Missing(b.AutoTerritorialRel)) Then 1 Else b.AutoTerritorialRel End as AutoTerritorialRel 
/*1 is the default used by Doug; see Dan's email dated on July 23/2020*/
				,Case 
						When(Calculated AutoTerritorialRel<0.5) Then '1) LT0.5'
						When(Calculated AutoTerritorialRel<0.6) Then '2) HE0.5 - LT0.6'
						When(Calculated AutoTerritorialRel<0.7) Then '3) HE0.6 - LT0.7'
						When(Calculated AutoTerritorialRel<0.8) Then '4) HE0.7 - LT0.8'
						When(Calculated AutoTerritorialRel<0.9) Then '5) HE0.8 - LT0.9'
						When(Calculated AutoTerritorialRel<1.0) Then '6) HE0.9 - LT1.0'
						When(Calculated AutoTerritorialRel=1.0) Then '7) E1.0'
						When(Calculated AutoTerritorialRel<1.1) Then '8) HE1.0 - LT1.1'
						When(Calculated AutoTerritorialRel<1.2) Then '9) HE1.1 - LT1.2'
						When(Calculated AutoTerritorialRel<1.3) Then '10) HE1.2 - LT1.3'
						When(Calculated AutoTerritorialRel<1.4) Then '11) HE1.3 - LT1.4'
						When(Calculated AutoTerritorialRel<1.5) Then '12) HE1.4 - LT1.5'
						When(Calculated AutoTerritorialRel<1.6) Then '13) HE1.7 - LT1.6'
						When(Calculated AutoTerritorialRel<1.7) Then '14) HE1.6 - LT1.7'
						When(Calculated AutoTerritorialRel<1.8) Then '15) HE1.7 - LT1.8'
						When(Calculated AutoTerritorialRel<1.9) Then '16) HE1.8 - LT1.9'
						When(Calculated AutoTerritorialRel<2.0) Then '17) HE1.9 - LT2.0'
						Else '18) HTE2.0'
					End as 	AutoTerritorialBracket

	FROM GL_w_Add_EvVars_1 as a left join AutoTerritorialTBL as b
	ON a.zipcode=b.zip  AND a.state=b.state
	Order By a.cfxmlid;
Quit;


Proc SQL;
	Create Table Prj.GL_w_Add_EvVars (Drop=NumberBuildingsLoc) as
		/*The number of buildings from the property dataset does not agree with the number of locations from GL*/
		/*Therefore it is eliminated to avoid contradictions*/
	Select *, count(Distinct locationnumber) as NumberLocationsPol
				,Count(Distinct state) as NumberStatesPol, Count(Distinct zipcode) as NumberZipsPol
				,sum(EP_Calc_Key_Level) as GL_EP_Policy
				,Case 
					When(Calculated GL_EP_Policy LT 10000) Then 'a) LT10'
					When(Calculated GL_EP_Policy lt 15000) Then 'b) GE10_LT15'
					When(Calculated GL_EP_Policy lt 20000) Then 'c) GE15_LT20'
					When(Calculated GL_EP_Policy lt 25000) Then 'd) GE20_LT25'
					When(Calculated GL_EP_Policy lt 30000) Then 'e) GE25_LT30'
					When(Calculated GL_EP_Policy lt 40000) Then 'f) GE30_LT40'
					When(Calculated GL_EP_Policy lt 50000) Then 'g) GE40_LT50'
					When(Calculated GL_EP_Policy lt 75000) Then 'h) GE50_LT75'
					When(Calculated GL_EP_Policy lt 100000) Then 'i) GE75_LT100'
					When(Calculated GL_EP_Policy lt 125000) Then 'j) GE100_LT125'
					When(Calculated GL_EP_Policy lt 150000) Then 'k) GE125_LT150'
					When(Calculated GL_EP_Policy lt 175000) Then 'l) GE150_LT175'
					When(Calculated GL_EP_Policy lt 200000) Then 'm) GE175_LT200'
					When(Calculated GL_EP_Policy lt 300000) Then 'n) GE200_LT300'
				   	Else 'o) 300+' 
				End as EP_Bracket

	FROM GL_w_Add_EvVars_2
	Group By cfxmlid
	Order By cfxmlid;
Quit;


Proc Datasets Nolist;
	Delete 	PROP_BUILDINGS_N_LOC_CNTS 
		PROP_EV_VARS EV_SqrtF
		PROP_W_ADD_EVVARS_0 PROP_W_ADD_EVVARS_1 PROP_W_ADD_EVVARS_2 PROP_W_ADD_EVVARS_3 PROP_W_ADD_EVVARS_4 PROP_W_ADD_EVVARS_5 PROP_W_ADD_EVVARS_6
		GL_EV_VARS 
		GL_W_ADD_EVVARS_0 GL_W_ADD_EVVARS_1 GL_W_ADD_EVVARS_2 
		BUILDINGSPERLOC AUTO_EV_POLS RANGECHANGEBINTBL RATECHANGETBL RATENRANGECHANGEBINTBL AUTOTERRITORIALTBL
			;
Run;




/*GL*/
/**/
/*Proc SQL;*/
/*	Create Table GL_Add_Var_0 as*/
/*	Select Distinct cfxmlid, paymentmethoddescription, ghost*/
/*					,premiumpaymentplandescription*/
/*					,generalaggregatelimitamount*/
/*					,productaggregatelimitamount*/
/*					,occurrencelimitamount*/
/*					,medicalpaymentslimitamount*/
/*					,Count(Distinct premiumpaymentplandescription) as PrDesCnt*/
/*					,Count(Distinct generalaggregatelimitamount) as GLimCnt*/
/*					,Count(Distinct productaggregatelimitamount) as ProdLCnt*/
/*					,Count(Distinct occurrencelimitamount) as OccCnt*/
/*					,Count(Distinct medicalpaymentslimitamount) as MedCnt*/
/*					 */
/*	FROM smbizhal.&gl_ev.*/
/*	Group by cfxmlid*/
/**/
/*	HAVING ((calculated PrDesCnt>1)OR(calculated GLimCnt>1)OR(calculated ProdLCnt>1)OR(calculated OccCnt>1)OR (calculated MedCnt>1))*/
/**/
/*	Order by cfxmlid*/
/*	;*/
/*Quit;*/
