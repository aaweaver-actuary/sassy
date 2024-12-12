

proc Sql;
	create table Prop_Prem_BCat_BServ as
	select cfxmlid,	Business_Category, Business_Service
			,Sum(BOP_Bldg_Annual_Manual_Premium) as Bldg_Annual_ManPrem_PolNBCBS, Sum(BOP_BPP_Annual_Manual_Premium) format comma20.2 as BPP_Annual_ManPrem_PolNBCBS
			,sum(calculated Bldg_Annual_ManPrem_PolNBCBS, calculated BPP_Annual_ManPrem_PolNBCBS) format comma20.2 as Bldg_n_BPP_Ann_ManPrem_PolNBCBs			
			,sum(Prop_EP_KeyLevel) as Prop_EP_PolNBCBS

	from Prj.PROP_w_EFT
	Where ((Business_Category<>'')AND(NOt Missing(Business_Category))AND (Business_Service<>'')AND(NOt Missing(Business_Service)))
	group by cfxmlid,	Business_Category, Business_Service
	Order by cfxmlid,	Business_Category, Business_Service;
quit;

proc Sql;
	create table GL_Prem_BCat_BServ as
	select cfxmlid,	Business_Category, Business_Service
			,Sum(BOP_GL_Annual_Manual_Premium) as GL_Annual_ManPrem_PolNBCBS			
			,sum(EP_Calc_Key_Level) as GL_EP_PolNBCBS

	from Prj.GL_w_EFT 
	Where ((Business_Category<>'')AND(NOt Missing(Business_Category))AND (Business_Service<>'')AND(NOt Missing(Business_Service)))
	group by cfxmlid,	Business_Category, Business_Service
	Order by cfxmlid,	Business_Category, Business_Service;
quit;

proc Sql;
	create table Prop_cfx  as
	select Distinct	cfxmlid, Business_Category, Business_Service

	from Prop_Prem_BCat_BServ
	Order by cfxmlid, Business_Category, Business_Service;
quit;

proc Sql;
	create table GL_cfx  as
	select Distinct	cfxmlid, Business_Category, Business_Service

	from GL_Prem_BCat_BServ
	Order by cfxmlid, Business_Category, Business_Service;
quit;


Proc Append Base=Prop_cfx data=GL_cfx;
Run;

proc Sql;
	create table Prop_n_GL_cfx  as
	select Distinct	cfxmlid, Business_Category, Business_Service

	from Prop_cfx
	Order by cfxmlid, Business_Category, Business_Service;
quit;

Proc SQL;
	Create Table PropGL_Prem_BC_BS_0 as 
	Select a.*
			, b.Bldg_n_BPP_Ann_ManPrem_PolNBCBs
			, b.Prop_EP_PolNBCBS
			, c.GL_Annual_ManPrem_PolNBCBS
			, c.GL_EP_PolNBCBS
			, Sum(b.Bldg_n_BPP_Ann_ManPrem_PolNBCBs, c.GL_Annual_ManPrem_PolNBCBS) format comma20.2 as Prop_GL_Annual_ManPrem_PolNBCBS
			, Sum(b.Prop_EP_PolNBCBS, c.GL_EP_PolNBCBS) as Prop_GL_EP_PolNBCBS

	FROM Prop_n_GL_cfx as a 
		left join Prop_Prem_BCat_BServ as b 
			ON a.cfxmlid=b.cfxmlid AND a.Business_Category=b.Business_Category AND a.Business_Service=b.Business_Service
		left join GL_Prem_BCat_BServ as c 
			ON a.cfxmlid=c.cfxmlid AND a.Business_Category=c.Business_Category AND a.Business_Service=c.Business_Service

	Order by a.cfxmlid, Calculated Prop_GL_Annual_ManPrem_PolNBCBS DESC
;
Quit;


Data PropGL_Prem_BC_BS; 
     set PropGL_Prem_BC_BS_0;     
     by cfxmlid Descending Prop_GL_Annual_ManPrem_PolNBCBS;     
     if (first.cfxmlid)   then Output;     
Run;

%Macro BC_BS(LOB);
Proc SQL;
	Create Table &LOB._w_BC_BS as 
	Select a.*
			, b.Business_Category as Business_Category_PolLevel
			, b.Business_Service as Business_Service_PolLevel
			,Year(imageeffectivedate) as YrCtl
			,Case When (Calculated YrCtl<=2013) Then 1 Else 0 End As YrCtl_LE2013
			,Case When (Calculated YrCtl=2014) Then 1 Else 0 End As YrCtl_E2014
			,Case When (Calculated YrCtl=2015) Then 1 Else 0 End As YrCtl_E2015
			,Case When (Calculated YrCtl=2016) Then 1 Else 0 End As YrCtl_E2016
			/*2017 is the base Yr, so no level*/
			,Case When (Calculated YrCtl=2018) Then 1 Else 0 End As YrCtl_E2018
			,Case When (Calculated YrCtl=2019) Then 1 Else 0 End As YrCtl_E2019

	FROM Prj.&LOB._w_EFT as a 
		left join PropGL_Prem_BC_BS as b 
			ON a.cfxmlid=b.cfxmlid 

	Order by a.cfxmlid
;
Quit;
%Mend BC_BS;

%BC_BS(PROP);
%BC_BS(GL);


Proc datasets Nolist;
	Delete PROP_PREM_BCAT_BSERV PROP_N_GL_CFX PROPGL_PREM_BC_BS_0 PROPGL_PREM_BC_BS PROP_CFX
			GL_PREM_BCAT_BSERV GL_CFX
			;
Run;


