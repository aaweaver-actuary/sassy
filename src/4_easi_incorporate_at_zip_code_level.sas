/*Correct the zip codes in the rerated data*/

%Macro Correct_Zips(EV_TBL,LocationVar,LOB);
	proc sql;
		create table &LOB._EV_Ins_ZIPs_0
		as select Distinct cfxmlid, &LocationVar., input(insured_address_zip_5,5.) as Insured_zip5
		from smbizhal.&EV_TBL.
		Order by cfxmlid, locationnumber
		; 
	quit;

	Data &LOB._EV_Ins_ZIPs; 
		Set &LOB._EV_Ins_ZIPs_0;
		By cfxmlid locationnumber;	
		If (First.cfxmlid) Then output;
		/*In GL there are few insurers using during some time the mailing address for the company*/
		/*and then they switched to PO Box or viceversa producing several zip codes associatted to a location.*/
		/*This step avoids this unusual situation*/
	Run;

	Proc SQL;
		Create Table &LOB._Rerated_w_Ins_Zip_0 as 
		Select a.*, b.Insured_zip5
		FROM &LOB._Rerated_w_Exp_n_SE as a left join &LOB._EV_Ins_ZIPs as b 
		ON a.cfxmlid=b.cfxmlid AND a.locationnumber=b.locationnumber;
	Quit;

	Data &LOB._Rerated_w_Ins_Zip; 
		Set &LOB._Rerated_w_Ins_Zip_0;
		/*There are 30 records wo zip code for GL. In these cases we used the insured zip*/
		If (Missing(zipcode)) Then zipcode=Insured_zip5;
	Run;

%Mend Correct_Zips;

%Correct_Zips(&prop_ev.,locationnumber,PROP);

%Let LocVar=input(locationnumber,8.) as locationnumber;
%Correct_Zips(&gl_ev.,&LocVar.,GL);


%Macro Incorporate_Easy(LOB);
	Proc SQL;
		Create Table &LOB._Rerated_w_Easi_0 as 
		Select a.*, &EasiVars.
		FROM &LOB._Rerated_w_Ins_Zip as a left join actcolib.&EasiInfo. as b 
		ON a.zipcode=input(b.ZIP_CD,5.);
	Quit;

	Proc SQL;
		Create Table &LOB._Rerated_w_Easi as 
		Select a.*, &EasiVarsV21.
		FROM &LOB._Rerated_w_Easi_0 as a left join actcolib.&EasiInfo_V21. as b 
		ON a.zipcode=input(b.ZIP_CD,5.);
	Quit;


%Mend Incorporate_Easy;

%Incorporate_Easy(PROP);
%Incorporate_Easy(GL);

/*Calculation and incorporation of Prevailing Zip codes*/

%Macro Include_Prev_Zip(PremiumVars,LOB);
	proc sql;
		create table &LOB._Prem_By_Zip
		as select * , sum(&PremiumVars.) as PremZip
		from &LOB._Rerated_w_Easi
		group by cfxmlid, zipcode
		order by cfxmlid, calculated PremZip Desc
		; 
	quit;	

	Data PremByLoc_FirstZip; 
		Set &LOB._Prem_By_Zip;
		By cfxmlid  Descending PremZip;	
		If (First.cfxmlid) Then output;
	Run;

	Proc SQL;
		Create Table &LOB._w_PrevailingZipCode_0 as 
		Select a.*, b.zipcode as PrevailingZipCode
		FROM &LOB._Rerated_w_Easi as a left join PremByLoc_FirstZip as b 
		ON a.cfxmlid=b.cfxmlid;
	Quit;

	Proc SQL;
		Create Table &LOB._w_PrevailingZipCode_1 as
		Select a.*, &EasiVarsPrev.
		FROM &LOB._w_PrevailingZipCode_0 as a left join actcolib.&EasiInfo. as b 
		ON a.PrevailingZipCode=input(b.ZIP_CD,5.);
	Quit;

	Proc SQL;
		Create Table Prj.&LOB._w_PrevailingZipCode as
		Select a.*, &EasiVarsPrev., &EasiVarsPrev21.
		FROM &LOB._w_PrevailingZipCode_1 as a left join actcolib.&EasiInfo_V21. as b 
		ON a.PrevailingZipCode=input(b.ZIP_CD,5.);
	Quit;
	
%Mend Include_Prev_Zip;

%Include_Prev_Zip(BOP_Bldg_Annual_Manual_Premium + BOP_BPP_Annual_Manual_Premium,PROP);
%Include_Prev_Zip(BOP_GL_Annual_Manual_Premium,GL);


Proc Datasets Nolist;
	Delete 	PROP_EV_INS_ZIPS_0 PROP_EV_INS_ZIPS PROP_RERATED_W_INS_ZIP_0 PROP_RERATED_W_INS_ZIP
			GL_EV_INS_ZIPS_0 GL_EV_INS_ZIPS GL_RERATED_W_INS_ZIP_0 GL_RERATED_W_INS_ZIP
			PROP_RERATED_W_EASI PROP_PREM_BY_ZIP PROP_W_PREVAILINGZIPCODE_0 PROP_W_PREVAILINGZIPCODE_1
			GL_RERATED_W_EASI GL_PREM_BY_ZIP GL_W_PREVAILINGZIPCODE_0 GL_W_PREVAILINGZIPCODE_1
			PREMBYLOC_FIRSTZIP
			GL_Rerated_w_Easi_0 Prop_Rerated_w_Easi_0


			;
Run;
