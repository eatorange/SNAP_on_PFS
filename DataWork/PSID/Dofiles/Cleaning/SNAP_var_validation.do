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
		
		*	To compare with post-1993, make it into wky expenditure
		cap	drop	foodexp_home_wk_pre1993
		gen	foodexp_home_wk_pre1993=foodexp_home_annual/52
		svy, subpop(if ${PFS_sample}): mean foodexp_home_wk_pre1993, over(year)	//	NO clear discontinuity in raw variable
		
		
		*	Used at home excluding food stamp (1994-2019)
		*	Since they are collected with different recall period, restrict sample to weekly responses which are major responses
		cap drop foodexp_nonFS_raw
		svy, subpop(if ${PFS_sample} & year!=1994 & foodexp_home_nostamp_recall==3): mean foodexp_home_nostamp, over(year)	//	NO clear discontinuity in raw variable
		*	We not only observe huge discontinuity between pre-1993 and post-1993, but also within pre-1993 periods.
		*	Need to see where these discontinuities came from
		
		*	First, let's see raw family-level data to see any discontinuity across pre-1993 priods
		
			*	At-home expenditure
			*	Note that at-home expenditure in pre-1993 include "food delivered"
		
			*	1991
			use	"${SNAP_dtRaw}/Unpacked/fam1991.dta", clear
			local	foodexp_athome_yr		V19107
			local	famnum					V19348
			local	stamp_ppl_month			V19104
			
			summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data	(foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
			gen		foodexp_athome_wk_pc	=	(`foodexp_athome_yr'/52)/`famnum'	//	Convert into wkly value per capita
			summ	foodexp_athome_wk_pc	if	`foodexp_athome_yr'!=0	//	Mean is 27.15
			
				*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
				*	We determine it by "the number of ppl redeemed FS"
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 1865.5
				summ	foodexp_athome_wk_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 13.24
				
				*	Those who didn't redeem food stamp
				*	Value here is much greater here, since this is not extra value but pure food expenditure
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 3739.29
				summ	foodexp_athome_wk_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 28.85
			
			
			
			
			*	1992
			use	"${SNAP_dtRaw}/Unpacked/fam1992.dta", clear
			local	foodexp_athome_yr		V20407
			local	famnum					V20650
			local	stamp_ppl_month			V20404
			
			summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data (foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
			gen		foodexp_athome_wk_pc	=	(`foodexp_athome_yr'/52)/`famnum'	//	Convert into wkly value per capita
			summ	foodexp_athome_wk_pc	if	`foodexp_athome_yr'!=0	//	Mean is 28.86
			
				*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
				*	We determine it by "the number of ppl redeemed FS"
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 2,078.38
				summ	foodexp_athome_wk_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 14.08
				
				*	Those who didn't redeem food stamp
				*	Value here is much greater here, since this is not extra value but pure food expenditure
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 3,945.62
				summ	foodexp_athome_wk_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 30.78
				
				
				
			*	1993
			use	"${SNAP_dtRaw}/Unpacked/fam1993.dta", clear
			local	foodexp_athome_yr		V21707
			local	famnum					V22405
			local	stamp_ppl_month			V21702
		
			summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data (foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
			gen		foodexp_athome_wk_pc	=	(`foodexp_athome_yr'/52)/`famnum'	//	Convert into wkly value per capita
			summ	foodexp_athome_wk_pc	if	`foodexp_athome_yr'!=0	//	Mean is 29.39
			
				*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
				*	We determine it by "the number of ppl redeemed FS"
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 1,872.85
				summ	foodexp_athome_wk_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 13.17
				
				*	Those who didn't redeem food stamp
				*	Value here is much greater here, since this is not extra value but pure food expenditure
				summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 3,979.93
				summ	foodexp_athome_wk_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 31.34
				
			
			**	No clear discontinuity b/w 1991-1993, both FS and non-FS families
		
			
			*	Now we move on to post-1994
			*	1994
			use	"${SNAP_dtRaw}/Unpacked/fam1994er.dta", clear
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
			
			tab	`foodexp_home_FS_recall'	`foodexp_deli_FS_recall'	if	`foodexp_home_FS_recall'!=0	&	`foodexp_deli_FS_recall'!=0
			
			
				*	FS
				summ	`foodexp_home_extra_amt'	if	!inlist(`foodexp_home_extra_amt',0,99998,99999)	//	Matches raw data
				
					*	At-home exp per capita 
					gen		foodexp_home_FS_pc	=	`foodexp_home_extra_amt'/`famnum'
					
					*	Delivered per capita
					gen		foodexp_deli_FS_pc	=	`foodexp_deli_FS_amt'/`famnum'
					
					
					*	At-home + delivered to compare with pre-1994
					*	Make it as wkly value
					gen		foodexp_hode_FS_pc	=	foodexp_home_FS_pc	+	foodexp_home_FS_pc	///
						if	`foodexp_home_FS_recall'==1	&	`foodexp_deli_FS_recall'==1
					replace	foodexp_hode_FS_pc	=	(foodexp_home_FS_pc/4.3)	+	foodexp_home_FS_pc	///
						if	`foodexp_home_FS_recall'==3	&	`foodexp_deli_FS_recall'==1
					replace	foodexp_hode_FS_pc	=	foodexp_home_FS_pc	+	(foodexp_home_FS_pc/4.3)	///
						if	`foodexp_home_FS_recall'==1	&	`foodexp_deli_FS_recall'==3
					replace	foodexp_hode_FS_pc	=	(foodexp_home_FS_pc	+	foodexp_home_FS_pc)/4.3	///
						if	`foodexp_home_FS_recall'==3	&	`foodexp_deli_FS_recall'==3	
					
					
					*	Summarize 
					
					br	foodexp_home_FS_pc	foodexp_deli_FS_pc	foodexp_hode_FS_pc	if	!mi(foodexp_hode_FS_pc)
					
					*	HH answered wkly exp
					summ	foodexp_hode_FS_pc 	///	/*	Restrict response to wky responses	*/
						if	(!inlist(`foodexp_home_extra_amt',0,99998,99999)	&	///
							!inlist(`foodexp_deli_FS_amt',0,99998,99999))	//	Mean of wkly is 21.56
						
						
						
					*	HH answered mthly exp
					summ	foodexp_home_FS_pc	///	/*	Restrict response to wky responses	*/
						if	!inlist(`foodexp_home_extra_amt',0,99998,99999)		&	`foodexp_home_FS_recall'==3	//	Mean of mthly is 41.01, leads to 9.54 when convered into wky (41.01/4.3)
					
					*	We already observe discontinuity among FS participants b/w 1993 and 1994
						*	Huge jump among wkly responses (13.17 in 1993 => 21.56 in 1994)
						*	Huge dip among monthly responses (13.17 in 1993 => 9.54 in 1994)
				
				
				*	
				
				
				
				
			
			
			*	1992
			use	"${SNAP_dtRaw}/Unpacked/fam1992.dta", clear
			summ	V19107	if	V19107!=0	//	Matches raw data
			gen		V19107_wk_pc	=	(V19107/52)/V19348	//	Convert into wkly value per capita
			summ	V19107_wk_pc	if	V19107!=0	//	Mean is 27.15
			
			
			
			
			*	1994
			use	"${SNAP_dtRaw}/Unpacked/fam1994er.dta", clear
			summ	ER3085	if	!inlist(ER3085,0,99997,99998,99999)	//	mean and st.dev matches with PSID raw summary stat
			summ	ER3085	if	!inlist(ER3085,0,9998, 9999, 88888, 99996, 99997,99998,99999)	//	Further exclude questionable answers
			summ	ER3085	if	!inlist(ER3085,0,9998, 9999, 88888, 99996, 99997,99998,99999)	&	ER3086==1 // Wkly response only
			
			
		
