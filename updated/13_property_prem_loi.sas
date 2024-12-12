
Proc SQL;
	Create Table PROP_Man_annual_Prem_KeyLevel as
	Select cfxmlid, sum(BOP_Bldg_Annual_Manual_Premium,BOP_BPP_Annual_Manual_Premium) format comma20. as BOP_PROP_Annual_ManPrem_KeyLevel
								
	FROM Prj.PROP_w_Add_EvVars
	Group By cfxmlid
	Order By cfxmlid
;
Quit;

Proc SQL;
	Create Table PROP_Man_annual_Prem_PolLevel as
	Select cfxmlid, sum(BOP_PROP_Annual_ManPrem_KeyLevel) format comma20. as BOP_PROP_Annual_ManPrem_PolLevel 
								
	FROM PROP_Man_annual_Prem_KeyLevel
	Group By cfxmlid
	Order By cfxmlid
;
Quit;

Proc SQL;
	Create Table PROP_Pols_Step13 as
	Select Distinct cfxmlid
								
	FROM PROP_Man_annual_Prem_PolLevel
	Order By cfxmlid
;
Quit;

Proc SQL;
	Create Table GL_Man_annual_Prem_PolLevel as
	Select cfxmlid, sum(BOP_GL_Annual_Manual_Premium) format comma20. as BOP_GL_Annual_ManPrem_PolLevel 
								
	FROM Prj.GL_w_Add_EvVars
	Group By cfxmlid
	Order By cfxmlid
;
Quit;

Proc SQL;
	Create Table GL_Pols_Step13 as
	Select Distinct cfxmlid
								
	FROM GL_Man_annual_Prem_PolLevel
	Order By cfxmlid
;
Quit;

Proc Append Base=PROP_Pols_Step13 data=GL_Pols_Step13;
Run;

Proc SQL;
	Create Table Prop_n_GL_Pols as
	Select Distinct cfxmlid
								
	FROM PROP_Pols_Step13
	Order By cfxmlid
;
Quit;


Proc SQL;
	Create Table Prop_n_GL_Pol_Premiums as
	Select a.*, b.BOP_PROP_Annual_ManPrem_PolLevel format comma20.2, c.BOP_GL_Annual_ManPrem_PolLevel format comma20.2
				,sum(b.BOP_PROP_Annual_ManPrem_PolLevel,c.BOP_GL_Annual_ManPrem_PolLevel) format comma20.2 as PROPnGL_AnnualManPrem_PolLevel
				,Case 
						When (calculated PROPnGL_AnnualManPrem_PolLevel ne 0) 
							Then b.BOP_PROP_Annual_ManPrem_PolLevel/(calculated PROPnGL_AnnualManPrem_PolLevel) 
							Else 0
				 End format percent10.2 as BOPPropPremPct_PolLevel
				,Case 
						When (calculated PROPnGL_AnnualManPrem_PolLevel ne 0) 
							Then c.BOP_GL_Annual_ManPrem_PolLevel/(calculated PROPnGL_AnnualManPrem_PolLevel) 
							Else 0
				 End format percent10.2 as BOPGLPremPct_PolLevel

	FROM Prop_n_GL_Pols as a 
			left join PROP_Man_annual_Prem_PolLevel as b
					ON a.cfxmlid=b.cfxmlid 
			left join GL_Man_annual_Prem_PolLevel as c
					ON a.cfxmlid=c.cfxmlid 
	Order By a.cfxmlid;
Quit;

%Macro AddPropGlPcts(LOB);
	Proc SQL;
		Create Table &LOB._w_Pcts as
		Select a.*, b.BOP_PROP_Annual_ManPrem_PolLevel format comma20.2, b.BOP_GL_Annual_ManPrem_PolLevel format comma20.2
					,b.PROPnGL_AnnualManPrem_PolLevel format comma20.2
					,b.BOPPropPremPct_PolLevel format percent10.2
					,b.BOPGLPremPct_PolLevel format percent10.2

		FROM Prj.&LOB._w_Add_EvVars as a 
				left join Prop_n_GL_Pol_Premiums as b
						ON a.cfxmlid=b.cfxmlid 
		Order By a.cfxmlid;
	Quit;

%MEnd AddPropGlPcts;

%AddPropGlPcts(Prop);
%AddPropGlPcts(GL);



Proc Datasets Nolist;
	Delete PROP_MAN_ANNUAL_PREM_KEYLEVEL PROP_MAN_ANNUAL_PREM_POLLEVEL GL_MAN_ANNUAL_PREM_POLLEVEL PROP_N_GL_POLS
			PROP_POLS_STEP13 GL_POLS_STEP13 PROP_N_GL_POL_PREMIUMS
			;
Run;

