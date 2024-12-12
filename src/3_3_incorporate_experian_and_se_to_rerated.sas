%Macro Rerated_w_Experian_n_SE(Rerared_TBL,LOB);

	Proc SQL;
		Create Table &LOB._Rerated_w_Exp_n_SE as 
		Select a.*, b.*
		,coalesce(b.commercial_intelliscore,60) as commercial_intelliscore_2
		,Case When Missing(b.commercial_intelliscore) Then 0 Else 1 End as Comm_intelliscore_Source

		FROM Exps_B15.&Rerared_TBL. as a left join &LOB._master_data_3 as b 
		ON a.cfxmlid=b.cfxmlid;
	Quit;

%Mend Rerated_w_Experian_n_SE;

%Rerated_w_Experian_n_SE(&prop_rerated.,PROP);
%Rerated_w_Experian_n_SE(&gl_rerated.,GL);


