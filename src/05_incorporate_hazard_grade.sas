
/*HAZARD_GRADE_BY_CLASS. Constructed in EV and join to the rerated data*/
/*Because neither classification premium nor code exists in the rerated data and the HG is given in terms of the */
/*gl_class_code*/
Proc sql;
	create table GL_Ev_w_Haz_0 as 
	Select cfxmlid,	classificationcode,	firstinsurednaicscode, classifcationtotalpremium, b.*
	FROM smbizhal.&gl_ev. as a left join common.HAZARD_GRADE_BY_CLASS as b 
	ON a.classificationcode=Put(gl_class_code,5.)
	Order by cfxmlid, classificationcode
	; 
quit;

proc sql;
	create table GL_Ev_w_Haz_1 as 
	Select cfxmlid,	classificationcode,	firstinsurednaicscode,	classifcationtotalpremium,
				 	gl_premises_hg, Round(sum(gl_premises_hg*classifcationtotalpremium)/sum(classifcationtotalpremium),1) as GL_HG_Premises_W_Av, 
				 	gl_products_hg, Round(sum(gl_products_hg*classifcationtotalpremium)/sum(classifcationtotalpremium),1) as GL_HG_Products_W_Av, 
				 	prop_hg, Round(sum(prop_hg*classifcationtotalpremium)/sum(classifcationtotalpremium),1) as Prop_HG_W_Av,
					auto_hg, Round(sum(auto_hg*classifcationtotalpremium)/sum(classifcationtotalpremium),1) as Auto_HG_W_Av
	FROM GL_Ev_w_Haz_0
	Group by cfxmlid
	Order by cfxmlid, classificationcode
	; 
quit;

proc sql;
	create table GL_Ev_w_Haz_2 as 
	Select Distinct cfxmlid, GL_HG_Premises_W_Av, GL_HG_Products_W_Av, Prop_HG_W_Av, Auto_HG_W_Av
	FROM GL_Ev_w_Haz_1
	Order by cfxmlid
	; 
quit;


%Macro Rerated_w_HG(EV_TBL,LOB);

	proc sql;
		create table &LOB._InsuredNAICs as 
		Select Distinct cfxmlid, firstinsurednaicscode
		FROM smbizhal.&EV_TBL.
		Order by cfxmlid
		; 
	quit;

	/*Incorporate firstinsurednaicscode to the rerated data	*/
	Proc sql;
		create table &LOB._Rerated_w_Haz_3 as 
		Select a.*, b.firstinsurednaicscode
		FROM Prj.&LOB._w_PrevailingZipCode as a left join &LOB._InsuredNAICs as b 
		ON a.cfxmlid=b.cfxmlid
		Order by cfxmlid
		; 
	quit;

	/*Incorporate HG to the rerated data. Both PROP & GL use GL_Rerated_w_Haz_2 (not by LOB) because the HG is determined by gl_class_code*/
	Proc sql;
		create table &LOB._Rerated_w_Haz_4 as 
		Select  a.*, b.GL_HG_Premises_W_Av, b.GL_HG_Products_W_Av, b.Prop_HG_W_Av, b.Auto_HG_W_Av
		FROM &LOB._Rerated_w_Haz_3 as a left join GL_Ev_w_Haz_2 as b 
		ON a.cfxmlid=b.cfxmlid
		Order by cfxmlid
		; 
	quit;
%Mend Rerated_w_HG;

%Rerated_w_HG(&gl_ev.,GL);
%Rerated_w_HG(&prop_ev.,PROP);


%Macro Rerated_w_HG(LOB);

	Proc sql;
		create table &LOB._Rerated_w_Haz_5 as 
		Select Distinct a.*, b.gl_premises_hg as NAICS_GL_Premises_HG, b.gl_products_hg as NAICS_GL_Products_HG
		FROM &LOB._Rerated_w_Haz_4 as a left join common.HAZARD_GRADE_BY_NAICS_GL_BOTH as b 
		ON a.firstinsurednaicscode=b.NAICS
		Order by cfxmlid, firstinsurednaicscode
		; 
	quit;

	Proc sql;
		create table &LOB._Rerated_w_Haz_6 as 
		Select Distinct a.*, b.AUTO_HAZ_GRADE as NAICS_Auto_HG, b.PROP_HAZ_GRADE as NAICS_PROP_HG
		FROM &LOB._Rerated_w_Haz_5 as a left join common.HAZ_GRADE_NAICS_XREF_NEW as b 
		ON a.firstinsurednaicscode=b.NAICS_CD
		Order by cfxmlid, firstinsurednaicscode
		; 
	quit;

	Proc sql;
		create table Prj.&LOB._Rerated_w_Haz as 
		Select *, Coalesce(Prop_HG_W_Av,NAICS_PROP_HG,5) as Prop_HG_Final,
					Coalesce(Auto_HG_W_Av,NAICS_Auto_HG,5) as Auto_HG_Final, 
					Coalesce(GL_HG_Premises_W_Av,NAICS_GL_Premises_HG,8) as GL_Premises_HG_Final, 
					Coalesce(GL_HG_Products_W_Av,NAICS_GL_Products_HG,7) as GL_Products_HG_Final
			/* The defaults in the coalescesce function below have been selected based on the premium*/
			/*according to the HG_Av (see the Proc Summaries below)*/
			/*For Property and Auto the maximum for both premium and frequency occurs at 5	*/
			/*For Products the maximum for both premium and frequency occurs at 7	*/
			/*For Premises the maximum for premium occurs at 7 but for frequency occurs at 8, I selected 7.	*/
		FROM &LOB._Rerated_w_Haz_6 
		Order by cfxmlid
		; 
	quit;	
%Mend Rerated_w_HG;

%Rerated_w_HG(PROP);
%Rerated_w_HG(GL);


Proc Datasets Nolist;
	Delete 	GL_EV_W_HAZ_0 GL_EV_W_HAZ_1 GL_EV_W_HAZ_2 GL_INSUREDNAICS GL_RERATED_W_HAZ_3 GL_RERATED_W_HAZ_4 GL_RERATED_W_HAZ_5 GL_RERATED_W_HAZ_6
			PROP_INSUREDNAICS PROP_RERATED_W_HAZ_3 PROP_RERATED_W_HAZ_4 PROP_RERATED_W_HAZ_5 PROP_RERATED_W_HAZ_6
			;
Run;



/*3,360 out of the 1,266,199 records go to the default HG for property*/
/*	Proc sql;*/
/*		create table GL_HG_Test as */
/*		Select Distinct **/
/*		FROM Prj.GL_Rerated_w_Haz */
/*		Where (Missing(Prop_HG_W_Av)OR Missing(Auto_HG_W_Av)OR Missing(GL_HG_Premises_W_Av)OR Missing(GL_HG_Products_W_Av))*/
/*		Order by cfxmlid, firstinsurednaicscode*/
/*		; */
/*	quit;*/

/*3,361 out of the 1,248,197 records go to the default HG for property*/
/*	Proc sql;*/
/*		create table Prop_HG_Test as */
/*		Select Distinct **/
/*		FROM Prj.PROP_Rerated_w_Haz */
/*		Where (Missing(Prop_HG_W_Av)OR Missing(Auto_HG_W_Av)OR Missing(GL_HG_Premises_W_Av)OR Missing(GL_HG_Products_W_Av))*/
/*		Order by cfxmlid, firstinsurednaicscode*/
/*		; */
/*	quit;*/


/*Support*/
/**/
/*Proc Summary Data = GL_Ev_w_Haz_1 Missing Nonobs Nway;*/
/*	Class Prop_HG_W_Av;*/
/*	Var classifcationtotalpremium;*/
/*Output Out = HG_Prop_SUMM (Drop = _TYPE_ ) sum=;*/
/*Run;*/
/**/
/*Proc Summary Data = GL_Ev_w_Haz_1 Missing Nonobs Nway;*/
/*	Class GL_HG_Premises_W_Av;*/
/*	Var classifcationtotalpremium;*/
/*Output Out = HG_GL_Prem_SUMM (Drop = _TYPE_ ) sum=;*/
/*Run;*/
/**/
/*Proc Summary Data = GL_Ev_w_Haz_1 Missing Nonobs Nway;*/
/*	Class GL_HG_Products_W_Av;*/
/*	Var classifcationtotalpremium;*/
/*Output Out = HG_GL_Prod_SUMM (Drop = _TYPE_ ) sum=;*/
/*Run;*/
/*/**/*/
/*Proc Summary Data = GL_Ev_w_Haz_1 Missing Nonobs Nway;*/
/*	Class Auto_HG_W_Av;*/
/*	Var classifcationtotalpremium;*/
/*Output Out = HG_GL_Prod_SUMM (Drop = _TYPE_ ) sum=;*/
/*Run;*/
/**/

