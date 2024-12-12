Proc SQL;
	/*There are 21 policies (26 records) wo AAL info	*/
	Create Table Prj.PROP_Rerated_w_AAL as
	Select a.*, b.hu_aal, b.hu_load
	FROM Prj.PROP_Rerated_w_Driver as a left join Gen15_20.hu_load_simple2 as b
	ON a.cfxmlid=b.cfxmlid AND a.locationnumber=b.locationnumber AND a.buildingnumber=b.buildingnumber
	Order By cfxmlid;
Quit;

/*Thefollowing lines check the synchronization between EV and the rerated data*/

/*Proc SQL;*/
/*	Create Table PROP_Rerated_w_AAL_Test as*/
/*	Select cfxmlid, policyeffectivedate, locationnumber,buildingnumber, state, zipcode, hu_aal, hu_load*/
/*	FROM Prj.PROP_Rerated_w_AAL*/
/*	Where (Missing(hu_aal) OR Missing(hu_load))*/
/*	Order By cfxmlid;*/
/*Quit;*/
/**/
/*Proc SQL;*/
/*	Create Table PROP_Rerated_w_AAL_ghost as*/
/*	Select Distinct a.*, b.ghost*/
/*	FROM PROP_Rerated_w_AAL_Test as a left join smbizhal.&prop_ev. as b*/
/*	ON a.cfxmlid=b.cfxmlid */
/*	Order By cfxmlid;*/
/*Quit;*/
/**/
/* Proc sql;*/
/*	Create Table Pol_in_Retates_Not_in_EV as*/
/*	select DISTINCT cfxmlid, policyeffectivedate from Exps_B15.&prop_rerated.*/
/*	except*/
/*   select DISTINCT cfxmlid, policyeffectivedate from smbizhal.&prop_ev.*/
/*	;*/
/*Quit;*/
/**/
/*Proc SQL;*/
/*	Create Table PROP_EV_1Pol as*/
/*	Select Distinct **/
/*	FROM smbizhal.&prop_ev. */
/*	Where (cfxmlid='CPP.1722673.20') */
/*;*/
/*Quit;*/
/**/
/*Proc SQL;*/
/*	Create Table PROP_Rerated_w_AAL_ghost_1Pol as*/
/*	Select Distinct **/
/*	FROM Exps_B15.&prop_rerated. */
/*	Where (cfxmlid='CPP.1722673.20') */
/*;*/
/*Quit;*/


