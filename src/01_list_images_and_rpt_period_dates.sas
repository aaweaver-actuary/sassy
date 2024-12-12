/*	Construct list of distinct images from Property EV and identify relevant SE report period dates
	-- Note: 1st observed RPD is 04/01/2011
	-- 		 RPDs in 2011 fall on 1st of the month
	-- 		 RPDs 2012 and later fall on 2nd of the month
*/

%Macro Images(EV_TBL,LOB);
	proc sql;
	create table images_&LOB. as select distinct
		cfxmlid
		,historical_company
		,policysymbol
		,policynumber
/*		,statisticalpolicymodulenumber Do we need this field with the rerated data?*/
		,policyeffectivedate
		,imageeffectivedate
		,imageexpirationdate

		/*	Find first report period date on or after the image effective date  */
		,case
			/* 1st or 2nd of month, 2010 or later */
			when year(imageeffectivedate) ge 2010
			 and day(imageeffectivedate) le 2
			then mdy(month(imageeffectivedate),2,year(imageeffectivedate))

			/* 3rd or later of non-December, 2010 or later */
			when year(imageeffectivedate) ge 2010
			 and day(imageeffectivedate) ge 3
			 and month(imageeffectivedate) < 12
			then mdy(month(imageeffectivedate) + 1,2,year(imageeffectivedate))

			/* 3rd or later of December, 2010 or later */
			when year(imageeffectivedate) ge 2010
			 and day(imageeffectivedate) ge 3
			 and month(imageeffectivedate) = 12
			then mdy(1,2,year(imageeffectivedate)+1)

			/* 1st of month, 2009, September or later */
			when year(imageeffectivedate) = 2009
			 and month(imageeffectivedate) ge 9
			 and day(imageeffectivedate) = 1
			then mdy(month(imageeffectivedate),1,2009)

			/* 2nd or later of non-December, 2009, April or later */
			when year(imageeffectivedate) = 2009
			 and 9 le month(imageeffectivedate) < 12
			 and day(imageeffectivedate) > 1
			then mdy(month(imageeffectivedate) + 1,1,2009)

			/* 2nd or later of December 2011 */
			when year(imageeffectivedate) = 2009
			 and month(imageeffectivedate) = 12
			 and day(imageeffectivedate) > 1
			then mdy(1,2,2010)
			
		 end format yymmddd10. as rpd

		 /*	 Find first report period date before the image effective date  */
		 ,case
		 	
		 	/* 3rd or later of month, 2010 or later */
		 	when year(imageeffectivedate) ge 2010
			 and day(imageeffectivedate) > 2
			then mdy(month(imageeffectivedate),2,year(imageeffectivedate))

			/* 1st or 2nd of non-January month, 2010 or later */
			when year(imageeffectivedate) ge 2010
			 and month(imageeffectivedate) > 1
			 and day(imageeffectivedate) le 2
			then mdy(month(imageeffectivedate)-1,2,year(imageeffectivedate))

			/* 1st or 2nd of January. 2011 or later */
			when year(imageeffectivedate) ge 2011
			 and month(imageeffectivedate) = 1
			 and day(imageeffectivedate) le 2
			then mdy(12,2,year(imageeffectivedate)-1)

			/* 1st or 2nd of January, 2010 */
			when year(imageeffectivedate) = 2010
			 and month(imageeffectivedate) = 1
			 and day(imageeffectivedate) le 2
			then mdy(12,1,2009)

			/* 2nd or later of month, 2009, Spetember or later */
			when year(imageeffectivedate) = 2009
			 and month(imageeffectivedate) ge 9
			 and day(imageeffectivedate) > 1
			then mdy(month(imageeffectivedate),1,2009)

			/* 1st of month, 2009, Sept or later */
			when year(imageeffectivedate) = 2009
			 and month(imageeffectivedate) ge 9
			 and day(imageeffectivedate) = 1
			then mdy(month(imageeffectivedate)-1,1,2009)

		  end format yymmddd10. as rpd_m1

	from Exps_B15.&EV_TBL.
	; quit;
%Mend Images;

%Images(&prop_rerated., Prop);
%Images(&gl_rerated., GL);
