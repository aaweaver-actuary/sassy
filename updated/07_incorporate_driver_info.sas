
Proc SQL;
	Create Table Driver_Min_Max_Avg as
	Select Distinct POLICY_NBR, EFF_DT,	Min(C118) as Min_DriverScore_C118, Max(C118) as Max_DriverScore_C118
					,Mean(C118) as Avg_DriverScore_C118
	FROM GEN20.for_rich 
	/*One policy can have many drivers (or none) with diffent score then we use the Min, Max and Avg values*/
	/*Accordig to Weinting "998 is no hit or no scores, and 999 is missing or thin file"*/
	/*therefore we remove them from the average*/
	Where ((C118 <>998)AND(C118 <>999))
	Group By POLICY_NBR, EFF_DT	
	Order By POLICY_NBR, EFF_DT;
Quit;


%MACRO Rerated_w_Driver(LOB);
Proc SQL;
	Create Table Prj.&LOB._Rerated_w_Driver as
	Select a.*, b.Min_DriverScore_C118, b.Max_DriverScore_C118, b.Avg_DriverScore_C118
			,Case When (Missing( b.Min_DriverScore_C118) OR Missing(b.Max_DriverScore_C118) 
								OR Missing(b.Avg_DriverScore_C118)) Then 'Missing' 
							Else  'Available' end as DriverInfo
	FROM Prj.&LOB._Rerated_w_Hail as a left join Driver_Min_Max_Avg as b
	ON a.policynumber=b.POLICY_NBR AND a.policyeffectivedate=b.EFF_DT
	Order By cfxmlid;
Quit;

%Mend Rerated_w_Driver;

%Rerated_w_Driver(PROP);
%Rerated_w_Driver(GL);



Proc Datasets Nolist;
	Delete 	Driver_Min_Max_Avg
			;
Run;

