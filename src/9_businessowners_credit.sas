
Proc SQL;
	Create Table Owner_Cred as
	Select Distinct *

	FROM My_Ref.Clean_OwnerScore 
	Where (NAME_SRC='OWNER')
	Order By policynumber, policysymbol, POLICYEFFECTIVEDATE, policyexpirationdate;
Quit;

Proc SQL;
	Create Table Business_Cred as
	Select Distinct *

	FROM My_Ref.Clean_OwnerScore 
	Where (NAME_SRC='BUSINESS')
	Order By policynumber, policysymbol, POLICYEFFECTIVEDATE, policyexpirationdate;
Quit;

%Macro OwnerCredit(Source,LOB);
	Proc SQL;
		Create Table Rerated_w_BusScore_B505 as
		Select a.*, b.B505 as B505_Owner, b.LexisNexisCreditInd as OwnerLexNexIndicator

		FROM &Source. as a left join Owner_Cred as b
		ON a.policynumber=b.policynumber AND a.policyeffectivedate=b.POLICYEFFECTIVEDATE 
			AND a.policyexpirationdate=b.policyexpirationdate AND a.statisticalpolicymodulenumber=b.statisticalpolicymodulenumber
		Order By cfxmlid;
	Quit;

	Proc SQL;
		Create Table Prj.&LOB._Rerated_w_BusScore_B505 as
		Select a.*, b.B505 as B505_Business, b.LexisNexisCreditInd as BusinessLexNexIndicator
					,coalesce(B505_Owner, B505_Business) as B505_Coalesced_Ow_Bus
					,coalesce(B505_Owner, B505_Business,999) as B505_Coalesced_Ow_Bus_2
					, Case When ((OwnerLexNexIndicator='Available')OR(BusinessLexNexIndicator='Available')) Then 'Available'
 							When ((OwnerLexNexIndicator<>'Available')AND(Not Missing(OwnerLexNexIndicator))) Then OwnerLexNexIndicator
 							When ((BusinessLexNexIndicator<>'Available')AND(Not Missing(BusinessLexNexIndicator))) Then BusinessLexNexIndicator
							Else BusinessLexNexIndicator End
					   as B505CoalescedCreditInfo
					,Case When (((OwnerLexNexIndicator='Available')OR(BusinessLexNexIndicator='Available'))AND(Calculated B505_Coalesced_Ow_Bus ne 999)) Then 1
							Else 0 End
					 as B505CoalescedSource

		FROM Rerated_w_BusScore_B505 as a left join Business_Cred as b
		ON a.policynumber=b.policynumber AND a.policyeffectivedate=b.POLICYEFFECTIVEDATE 
			AND a.policyexpirationdate=b.policyexpirationdate AND a.statisticalpolicymodulenumber=b.statisticalpolicymodulenumber
		Order By cfxmlid;
	Quit;

%Mend OwnerCredit;

%OwnerCredit(Prj.PROP_Rerated_w_AAL,PROP);
%OwnerCredit(Prj.GL_Rerated_w_Driver,GL);



Proc Datasets Nolist;
	Delete 	BUILDING_AGE BUILDING_AGE_0
			;
Run;




/*	Proc SQL;*/
/*		Create Table Prop_Cnt_B505 as*/
/*		Select  OwnerLexNexIndicator, Count(policynumber) as Ow_Cnt, BusinessLexNexIndicator, Count(policynumber) as BI_Cnt*/
/*					,B505CoalescedCreditInfo, Count(policynumber) as Coal_Cnt*/
/**/
/*		FROM Prj.Prop_Rerated_w_BusScore_B505*/
/*			Group by OwnerLexNexIndicator, BusinessLexNexIndicator, B505CoalescedCreditInfo;*/
/*	Quit;*/
/**/
/*	Proc SQL;*/
/*		Create Table GL_Cnt_B505 as*/
/*		Select Distinct OwnerLexNexIndicator, Count(policynumber) as Ow_Cnt, BusinessLexNexIndicator, Count(policynumber) as BI_Cnt*/
/*					,B505CoalescedCreditInfo, Count(policynumber) as Coal_Cnt*/
/**/
/*		FROM Prj.GL_Rerated_w_BusScore_B505*/
/*			Group by OwnerLexNexIndicator, BusinessLexNexIndicator, B505CoalescedCreditInfo;*/
/*	Quit;*/
/**/
