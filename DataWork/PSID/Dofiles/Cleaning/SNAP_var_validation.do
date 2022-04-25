*	This variable is to validate imputed variables
*	As of 2022/4/23, there are huge discontinuity in imputed variables (ex. foodexp_tot_inclFS_pc), implying invalidity in imputation
	
	*	Discontinuity in imputed variable (foodexp_tot_inclFS_pc)
	use    "${SNAP_dtInt}/SNAP_long_const",	clear
	global	PFS_sample in_sample==1 & inrange(year,1975,2019)
	svy, subpop(if ${PFS_sample}): mean foodexp_tot_inclFS_pc, over(year)	//	Huge discontinuity around 77/78 and 93/34
	
	*	We MUST see what has gone wrong in imputation
	

*	First, we start with raw variables to see if there are any discontinuity in raw variables in "constructed panel data"

	*	At-home food exp
	
		*	Used at home (1975-1993)
		*	Not that they do NOT include food stamp value
		svy, subpop(if ${PFS_sample}): mean foodexp_home_annual, over(year)	//	NO clear discontinuity in raw variable
		
		*	To compare with post-1993, make it into mthy expenditure
		cap	drop	foodexp_home_mth_pre1993
		gen	foodexp_home_mth_pre1993=foodexp_home_annual/12
		svy, subpop(if ${PFS_sample}): mean foodexp_home_mth_pre1993, over(year)	//	NO clear discontinuity in raw variable
		
		
		*	Used at home excluding food stamp (1994-2019)
		*	Since they are collected with different recall period, restrict sample to weekly responses which are major responses
		cap drop foodexp_nonFS_raw
		svy, subpop(if ${PFS_sample} & year!=1994 & foodexp_home_nostamp_recall==3): mean foodexp_home_nostamp, over(year)	//	NO clear discontinuity in raw variable
		*	We not only observe huge discontinuity between pre-1993 and post-1993, but also within pre-1993 periods.
		*	Need to see where these discontinuities came from
		
		*	First, let's see raw family-level data to see any discontinuity across pre-1993 priods
		
			*	At-home expenditure
			*	Note that at-home expenditure in pre-1994 include "food delivered"
		
			*	1991
			use	"${SNAP_dtRaw}/Unpacked/fam1991.dta", clear
			local	svydate					V19346
			local	foodexp_athome_yr		V19107
			local	famnum					V19348
			local	stamp_ppl_month			V19104
			
			*	Month of interview
			gen	svymonth	=	floor(`svydate'/100)	
			
			summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data	(foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
			gen		foodexp_athome_mth_pc	=	(`foodexp_athome_yr'/12)/`famnum'	//	Convert into mthly value per capita
			summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	//	Mean is 117.62
			
				*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
				*	We determine it by "the number of ppl redeemed FS"
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 1865.5
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 57.36
				
				*	Those who didn't redeem food stamp
				*	Value here is much greater here, since this is not extra value but pure food expenditure
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 3739.29
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 125.02
				
				*	Food stamp redemption by month
				gen		FS_lastmonth	=	0	if	`stamp_ppl_month'==0
				replace	FS_lastmonth	=	1	if	inrange(`stamp_ppl_month',1,12)
				
				bys	svymonth:	summ	FS_lastmonth
				
				*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'!=0 // FS
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'==0 //non-FS
			
			
			*	1992
			use	"${SNAP_dtRaw}/Unpacked/fam1992.dta", clear
			local	svydate					V20648
			local	foodexp_athome_yr		V20407
			local	famnum					V20650
			local	stamp_ppl_month			V20404
			
			*	Month of interview
			gen	svymonth	=	floor(`svydate'/100)	
			
			summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data (foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
			gen		foodexp_athome_mth_pc	=	(`foodexp_athome_yr'/12)/`famnum'	//	Convert into mthly value per capita
			summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	//	Mean is 125.04
			
				*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
				*	We determine it by "the number of ppl redeemed FS"
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 2,078.38
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 61.01
				
				*	Those who didn't redeem food stamp
				*	Value here is much greater here, since this is not extra value but pure food expenditure
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 3,945.62
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 133.36
				
				*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)
				
			*	1993
			use	"${SNAP_dtRaw}/Unpacked/fam1993.dta", clear
			local	svydate					V22403
			local	foodexp_athome_yr		V21707
			local	famnum					V22405
			local	stamp_ppl_month			V21702
			
			*	Month of interview
			gen	svymonth	=	floor(`svydate'/100)	
		
			summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data (foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
			gen		foodexp_athome_mth_pc	=	(`foodexp_athome_yr'/12)/`famnum'	//	Convert into mthly value per capita
			summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	//	Mean is 127.36
				
				*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
				*	We determine it by "the number of ppl redeemed FS"
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 1,872.85
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 57.07
				
				*	Those who didn't redeem food stamp
				*	Value here is much greater here, since this is not extra value but pure food expenditure
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 3,979.93
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 135.79
					
				*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)
				
			**	No clear discontinuity b/w 1991-1993, both FS and non-FS families
		
			
			*	Now we move on to post-1994
				*	People choose recall period freely

			*	1994
			use	"${SNAP_dtRaw}/Unpacked/fam1994er.dta", clear
			local	svydate					ER2005
			local	FS_used_lastmnth		ER3074	//	Whether used FS last month (dummy)
			local	foodexp_home_extra_wth	ER3077	//	Whether used extra amount in addition to FS (dummy)
			local	foodexp_home_extra_amt	ER3078	//	Amount spent at-home in addition to FS (only those who answered "Yes" to above)
			local	foodexp_home_FS_recall	ER3079	//	Recall period of home food exp (FS)	
			local	foodexp_home_amt		ER3085	//	Amount spent at home (non-FS)
			local	foodexp_home_nFS_recall	ER3086	//	Recall period (non-FS)
			local	foodexp_deli_FS_amt		ER3081	//	Amt food delivered (FS)
			local	foodexp_deli_FS_recall	ER3082	//	Recall  period of delivered food exp (FS)
			local	foodexp_deli_nFS_amt	ER3088	//	Amt food delivered (non-FS)
			local	foodexp_deli_nFS_recall	ER3089	//	Recall  period of delivered food exp (non-FS)	
			local	famnum					ER2006	//	Number of family members
			
			*	Date of interview
			gen	svymonth	=	floor(`svydate'/100)	
			
			*	Impute monthly food expenditures
			
				*	FS
				summ	`foodexp_home_extra_amt'	if	!inlist(`foodexp_home_extra_amt',0,99998,99999)	//	Matches raw data
				
					*	At-home exp per capita (converted into monthly value)
					gen	double	foodexp_home_FS_mth_pc	=	`foodexp_home_extra_amt'/`famnum'	//	default is monthly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*4.3	if	`foodexp_home_FS_recall'==1	//	Wkly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*2.15	if	`foodexp_home_FS_recall'==2	//	Bi-wkly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc/12	if	`foodexp_home_FS_recall'==4	//	Yearly
					replace		foodexp_home_FS_mth_pc	=	0	if	inlist(`foodexp_home_FS_recall',0,8,9)	
					
					
					*	Delivered per capita 
					gen	double	foodexp_deli_FS_mth_pc		=	`foodexp_deli_FS_amt'/`famnum'
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*4.3	if	`foodexp_deli_FS_recall'==1
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*2.15	if	`foodexp_deli_FS_recall'==2
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc/12	if	`foodexp_deli_FS_recall'==4
					replace		foodexp_deli_FS_mth_pc	=	0	if	inlist(`foodexp_deli_FS_recall',0,8,9)
					
					*	At-home + delivered to compare with pre-1994
					egen	foodexp_hode_FS_pc	=	rowtotal(foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc)
					
					br	`FS_used_lastmnth'	`foodexp_home_extra_amt'	`famnum'	`foodexp_home_FS_recall'	foodexp_home_FS_mth_pc	`foodexp_deli_FS_amt'	`foodexp_deli_FS_recall'	foodexp_deli_FS_mth_pc	foodexp_hode_FS_pc
					
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	//	Mean of mthly is 58.18 (997 obs)	=>	Smooth when compared with 1993! (57.07)
									
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_FS_recall'==1	//	Mean of mthly is 96.39 (276 obs)	=>	Those who report wkly recall period report their food expenditure nearly double the amount than those who report monthly recall.
						
						*	HH answered mthly exp (exclude irrational responses)		
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_FS_recall'==3	//	Mean of mthly is 42.97 (651 obs)
								
						
				*	Non-FS
				summ	`foodexp_home_amt'	if	!inlist(`foodexp_home_amt',0,99997,99998,99999)	//	Matches raw data, but for follow-up analysis I will exclude values greater than or equal to 9997
						
					*	At-home exp per capita (converted into monthly value)
					gen	double	foodexp_home_nFS_mth_pc	=	`foodexp_home_amt'/`famnum'	//	default is monthly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*4.3		if	`foodexp_home_nFS_recall'==1	//	Wkly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*2.15	if	`foodexp_home_nFS_recall'==2	//	Bi-wkly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc/12		if	`foodexp_home_nFS_recall'==4	//	Yearly
					replace		foodexp_home_nFS_mth_pc	=	0	if	inlist(`foodexp_home_nFS_recall',0,8,9)	
					
					
					*	Delivered per capita 
					gen	double	foodexp_deli_nFS_mth_pc		=	`foodexp_deli_nFS_amt'/`famnum'
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*4.3		if	`foodexp_deli_nFS_recall'==1
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*2.15	if	`foodexp_deli_nFS_recall'==2
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc/12		if	`foodexp_deli_nFS_recall'==4
					replace		foodexp_deli_nFS_mth_pc	=	0	if	inlist(`foodexp_deli_nFS_recall',0,8,9)
					
					*	At-home + delivered to compare with pre-1994
					egen	foodexp_hode_nFS_pc	=	rowtotal(foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc)
					
					br	`FS_used_lastmnth'	`foodexp_home_amt'	`famnum'	`foodexp_home_nFS_recall'	foodexp_home_nFS_mth_pc	`foodexp_deli_nFS_amt'	`foodexp_deli_nFS_recall'	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_pc
					
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
									
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==1	//	Mean of mthly is 176.97 (8,374 obs)	=>	Those who report wkly value report much higher expenditure than monthly expenditure
						
						*	HH answered mthly exp (exclude irrational responses)		
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==3	//	Mean of mthly is 107.27 (465 obs)
				
				*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
				bys	svymonth:	summ	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
				
				
				
			
				
				
				
				
				
				
				
				
	