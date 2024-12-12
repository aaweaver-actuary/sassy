
Proc SQL;
	Create Table Building_Age_0 as
	Select *
			, case When (buildingage_Banded ='50+') then 50 
					When(buildingage_Banded ='Default') Then . 
					Else input (buildingage_Banded,2.) End as BuildingAge
			, case When (buildingage_Banded ='50+') then 50 
					When(buildingage_Banded ='Default') Then 29 
					Else input (buildingage_Banded,2.) End as BuildingAge_2
			,Case When(buildingage_Banded ='Default') Then 0 
					Else 1 End as BuildingAge_Source
					 
	FROM Prj.PROP_Rerated_w_BusScore_B505
/*	FROM Exps_B15.&prop_rerated. */

	Order By  cfxmlid, locationnumber, buildingnumber;
Quit;

Proc SQL;
	Create Table Building_Age_1 as
	Select Distinct cfxmlid, locationnumber,buildingnumber, buildingage_Banded
					,Min(BuildingAge_2) as MinBuildingAgeLoc_2
					,Max(BuildingAge_2) as MaxBuildingAgeLoc_2
					,mean(BuildingAge_2) as AverageBuildingAgeLoc_2
					,count(buildingnumber) as NumberBuildingsLoc
					 
	FROM Building_Age_0 

	Group By  cfxmlid, locationnumber	
	Order By  cfxmlid, locationnumber, buildingnumber;
Quit;

Proc SQL;
	Create Table Building_Age as
	Select Distinct cfxmlid, locationnumber
					,MinBuildingAgeLoc_2
					,MaxBuildingAgeLoc_2
					,AverageBuildingAgeLoc_2
					,NumberBuildingsLoc
					 
	FROM Building_Age_1

	Order By  cfxmlid, locationnumber;
Quit;

%Macro IncludeBuildingAge(LOB);
	Proc SQL;
		Create Table Prj.&LOB._Rerated_w_BuildingAge as
		Select a.*, b.MinBuildingAgeLoc_2, b.MaxBuildingAgeLoc_2,  b.AverageBuildingAgeLoc_2
					, b.NumberBuildingsLoc
					,Case When(Missing(MinBuildingAgeLoc_2)OR
								Missing(MaxBuildingAgeLoc_2)OR
								Missing(AverageBuildingAgeLoc_2)) Then 'Missing' Else 'Available' End as BuildingAgeInfo
		FROM Prj.&LOB._Rerated_w_BusScore_B505 as a left join Building_Age as b
			ON a.cfxmlid=b.cfxmlid AND a.locationnumber=b.locationnumber
		Order By cfxmlid, locationnumber;
	Quit;
%Mend IncludeBuildingAge;

%IncludeBuildingAge(GL);
%IncludeBuildingAge(PROP);

Proc Datasets Nolist;
	Delete 	Building_Age_0 Building_Age_1 Building_Age
			;
Run;
