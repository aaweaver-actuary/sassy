/*Obtain all the zip codes for each county and construct the FIPS code*/
Proc SQL;
	create table FIPS5_ZIP as 
	Select Distinct CITY,	CITY2,	COUNTY, Input(Cat(STATE,Put(COUNTY,Z3.)),5.) as FIPS_N5, COUNTYNM, STATE, STATECODE,	STATENAME,	STATENAME2,	ZIP
	FROM SASHELP.ZIPCODE
	Order by STATE, COUNTY
	; 
Quit;

/*Assign the Hail info and wind/hail indices to each county based on the FIPS code*/
/*R_SToRM_Index has low values for high hazard, as does R_SToRM_Index_and_AAL_DR, while R_AAL_damage_ratio is the opposite.*/
/*R_SToRM_Index is based on the SToRM index from Guy Carpenter. R_AAL_damage_ratio is based on Severe Convective Storm catastrophe model output.*/
/*R_SToRM_Index_and_AAL_DR is based on a weighted average of a ranking of the other two, adjusting for the order difference between them. */

Proc SQL;
	create table FIPS5_ZIP_HAIL as 
	Select Distinct a.*,	b.FIPS_NUM5D, b.R_HAILRDCMDLPSM009_2, b.R_HAILRDCMDLPSM100_2, b.R_HAILRDCMDLPSM119_2, 
				b.R_HAILRDCMDLPSM200_2,	b.R_HAILRDCMDLPSMTOT_2,	b.R_Smoothed_HAILRDCMDLPSM009_2, b.R_Smoothed_HAILRDCMDLPSM100_2, 
				b.R_Smoothed_HAILRDCMDLPSM119_2,	b.R_Smoothed_HAILRDCMDLPSM200_2,	b.R_Smoothed_HAILRDCMDLPSMTOT_2
					/*The following 3 indices come from Sara via Dan*/
				,c.R_SToRM_Index, c.R_AAL_damage_ratio, c.R_SToRM_Index_and_AAL_DR 

	FROM FIPS5_ZIP as a 
		left join Gen15_20.&NOAA_RANK. as b ON a.FIPS_N5=b.FIPS_NUM5D
		left join Gen15_20.WIND_HAIL_INDEX_VALUES as c ON a.FIPS_N5=c.County_FIPS

	Order by STATE, COUNTY
	; 
Quit;


%MACRO Rerated_w_Hail(LOB);
Proc SQL;
	Create Table Prj.&LOB._Rerated_w_Hail as
		/*CW defaults were used when a zip code was not available */
		/*For property and GL 1,146 and 1,472 did nor have the info*/
		/*The defaults were determined using the Suport below for each varianble and the respective premium	*/
		/*For all variables it was found that the default is 10*/
	Select a.*, b.FIPS_N5, Coalesce(b.R_HAILRDCMDLPSM009_2,10) as R_HAILRDCMDLPSM009_2, Coalesce(b.R_HAILRDCMDLPSM100_2,10) as R_HAILRDCMDLPSM100_2, 
				Coalesce(b.R_HAILRDCMDLPSM119_2,10) as R_HAILRDCMDLPSM119_2, Coalesce(b.R_HAILRDCMDLPSM200_2,10) as R_HAILRDCMDLPSM200_2, 
				Coalesce(b.R_HAILRDCMDLPSMTOT_2,10) as R_HAILRDCMDLPSMTOT_2, Coalesce(b.R_Smoothed_HAILRDCMDLPSM009_2,10) as R_Smoothed_HAILRDCMDLPSM009_2, 
				Coalesce(b.R_Smoothed_HAILRDCMDLPSM100_2,10) as R_Smoothed_HAILRDCMDLPSM100_2, Coalesce(b.R_Smoothed_HAILRDCMDLPSM119_2,10)as R_Smoothed_HAILRDCMDLPSM119_2, 	
				Coalesce(b.R_Smoothed_HAILRDCMDLPSM200_2,10) as R_Smoothed_HAILRDCMDLPSM200_2, Coalesce(b.R_Smoothed_HAILRDCMDLPSMTOT_2,10) as R_Smoothed_HAILRDCMDLPSMTOT_2
				,b.R_SToRM_Index, b.R_AAL_damage_ratio, b.R_SToRM_Index_and_AAL_DR 

	FROM Prj.&LOB._Rerated_w_Haz as a left join FIPS5_ZIP_HAIL as b 
	ON a.zipcode=b.ZIP
	Order By cfxmlid;
Quit;

%Mend Rerated_w_Hail;

%Rerated_w_Hail(PROP);
%Rerated_w_Hail(GL);



Proc Datasets Nolist;
	Delete 	FIPS5_ZIP_HAIL FIPS5_ZIP
			;
Run;


/*Support*/
/**/
/*Proc Summary Data = Prj.GL_Rerated_w_Hail Missing Nonobs Nway;*/
/*	Class R_Smoothed_HAILRDCMDLPSM009_2;*/
/*/*	Var BOP_Bldg_Annual_Manual_Premium BOP_BPP_Annual_Manual_Premium;*/*/
/*	Var BOP_GL_Annual_Manual_Premium;*/
/*Output Out = GL_Rerated_w_Hail_SUMM (Drop = _TYPE_) sum=;*/
/*Run;*/


