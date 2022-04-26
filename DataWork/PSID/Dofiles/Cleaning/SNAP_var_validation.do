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
		
			cap	mat	drop	foodexp_home_mth_pc_all
			cap	mat	drop	foodexp_home_mth_pc_FS
			cap	mat	drop	foodexp_home_mth_pc_nFS
						
			cap	mat	drop	foodexp_deli_mth_pc_all
			cap	mat	drop	foodexp_deli_mth_pc_FS
			cap	mat	drop	foodexp_deli_mth_pc_nFS
			
			cap	mat	drop	foodexp_hode_mth_pc_all
			cap	mat	drop	foodexp_hode_mth_pc_FS
			cap	mat	drop	foodexp_hode_mth_pc_nFS
			
			cap	mat	drop	foodexp_out_mth_pc_all
			cap	mat	drop	foodexp_out_mth_pc_FS
			cap	mat	drop	foodexp_out_mth_pc_nFS
						
			*	At-home expenditure
			*	Note that at-home expenditure in pre-1994 include "food delivered"
		
			*	1990
			use	"${SNAP_dtRaw}/Unpacked/fam1990.dta", clear
			local	svydate					V18046
			local	foodexp_athome_yr		V17807
			local	foodexp_out_yr			V17809
			local	famnum					V18048
			local	stamp_ppl_month			V17804
		*[90]V17809 [91]V19109 [92]V20409 [93]V21711
		
			{
				*	Month of interview
				gen	svymonth	=	floor(`svydate'/100)	
			
				*	At-home food exp_all
				summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data	(foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
				gen		foodexp_athome_mth_pc	=	(`foodexp_athome_yr'/12)/`famnum'	//	Convert into mthly value per capita
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	//	Mean is 
				mat	foodexp_home_mth_pc_all	=	nullmat(foodexp_home_mth_pc_all),	r(mean)
				mat	list	foodexp_home_mth_pc_all
			
					*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
					*	We determine it by "the number of ppl redeemed FS"
					summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 
					summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is
					mat	foodexp_home_mth_pc_FS	=	nullmat(foodexp_home_mth_pc_FS),	r(mean)
					mat	list	foodexp_home_mth_pc_FS
					
					*	Those who didn't redeem food stamp
					*	Value here is much greater here, since this is not extra value but pure food expenditure
					summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					mat	foodexp_home_mth_pc_nFS	=	nullmat(foodexp_home_mth_pc_nFS),	r(mean)
					mat	list	foodexp_home_mth_pc_nFS
				
				*	Food eaten out
				summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	//	Matches raw data	
				gen		foodexp_out_mth_pc	=	(`foodexp_out_yr'/12)/`famnum'	//	Convert into mthly value per capita
				summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	//	Mean is 
				mat	foodexp_out_mth_pc_all	=	nullmat(foodexp_out_mth_pc_all),	r(mean)
				mat	list	foodexp_out_mth_pc_all
				
					*	Those who redeemed food stamp
					summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 
					summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is
					mat	foodexp_out_mth_pc_FS	=	nullmat(foodexp_out_mth_pc_FS),	r(mean)
					mat	list	foodexp_out_mth_pc_FS
					
					*	Those who didn't redeem food stamp
					summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					mat	foodexp_out_mth_pc_nFS	=	nullmat(foodexp_out_mth_pc_nFS),	r(mean)
					mat	list	foodexp_out_mth_pc_nFS
				
				*	Food stamp redemption by month
				gen		FS_lastmonth	=	0	if	`stamp_ppl_month'==0
				replace	FS_lastmonth	=	1	if	inrange(`stamp_ppl_month',1,12)
				
				bys	svymonth:	summ	FS_lastmonth
				
				*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
				*statsby,  by(svymonth) clear: summ	foodexp_athome_mth_pc
				summ	foodexp_athome_mth_pc
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'!=0 // FS
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'==0 //non-FS
			}
			
			*	1991
			use	"${SNAP_dtRaw}/Unpacked/fam1991.dta", clear
			local	svydate					V19346
			local	foodexp_athome_yr		V19107
			local	foodexp_out_yr			V19109
			local	famnum					V19348
			local	stamp_ppl_month			V19104
			
			{
				*	Month of interview
				gen	svymonth	=	floor(`svydate'/100)	
			
				*	At-home food exp_all
				summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data	(foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
				gen		foodexp_athome_mth_pc	=	(`foodexp_athome_yr'/12)/`famnum'	//	Convert into mthly value per capita
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	//	Mean is 
				mat	foodexp_home_mth_pc_all	=	nullmat(foodexp_home_mth_pc_all),	r(mean)
				mat	list	foodexp_home_mth_pc_all
			
					*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
					*	We determine it by "the number of ppl redeemed FS"
					summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 
					summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is
					mat	foodexp_home_mth_pc_FS	=	nullmat(foodexp_home_mth_pc_FS),	r(mean)
					mat	list	foodexp_home_mth_pc_FS
					
					*	Those who didn't redeem food stamp
					*	Value here is much greater here, since this is not extra value but pure food expenditure
					summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					mat	foodexp_home_mth_pc_nFS	=	nullmat(foodexp_home_mth_pc_nFS),	r(mean)
					mat	list	foodexp_home_mth_pc_nFS
				
				*	Food eaten out
				summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	//	Matches raw data	
				gen		foodexp_out_mth_pc	=	(`foodexp_out_yr'/12)/`famnum'	//	Convert into mthly value per capita
				summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	//	Mean is 
				mat	foodexp_out_mth_pc_all	=	nullmat(foodexp_out_mth_pc_all),	r(mean)
				mat	list	foodexp_out_mth_pc_all
				
					*	Those who redeemed food stamp
					summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 
					summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is
					mat	foodexp_out_mth_pc_FS	=	nullmat(foodexp_out_mth_pc_FS),	r(mean)
					mat	list	foodexp_out_mth_pc_FS
					
					*	Those who didn't redeem food stamp
					summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					mat	foodexp_out_mth_pc_nFS	=	nullmat(foodexp_out_mth_pc_nFS),	r(mean)
					mat	list	foodexp_out_mth_pc_nFS
				
				*	Food stamp redemption by month
				gen		FS_lastmonth	=	0	if	`stamp_ppl_month'==0
				replace	FS_lastmonth	=	1	if	inrange(`stamp_ppl_month',1,12)
				
				bys	svymonth:	summ	FS_lastmonth
				
				*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
				*statsby,  by(svymonth) clear: summ	foodexp_athome_mth_pc
				summ	foodexp_athome_mth_pc
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'!=0 // FS
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'==0 //non-FS
			}
					
			*	1992
			use	"${SNAP_dtRaw}/Unpacked/fam1992.dta", clear
			local	svydate					V20648
			local	foodexp_athome_yr		V20407
			local	foodexp_out_yr			V20409
			local	famnum					V20650
			local	stamp_ppl_month			V20404
			
			{
				*	Month of interview
				gen	svymonth	=	floor(`svydate'/100)	
			
				*	At-home food exp_all
				summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data	(foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
				gen		foodexp_athome_mth_pc	=	(`foodexp_athome_yr'/12)/`famnum'	//	Convert into mthly value per capita
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	//	Mean is 
				mat	foodexp_home_mth_pc_all	=	nullmat(foodexp_home_mth_pc_all),	r(mean)
				mat	list	foodexp_home_mth_pc_all
			
					*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
					*	We determine it by "the number of ppl redeemed FS"
					summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 
					summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is
					mat	foodexp_home_mth_pc_FS	=	nullmat(foodexp_home_mth_pc_FS),	r(mean)
					mat	list	foodexp_home_mth_pc_FS
					
					*	Those who didn't redeem food stamp
					*	Value here is much greater here, since this is not extra value but pure food expenditure
					summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					mat	foodexp_home_mth_pc_nFS	=	nullmat(foodexp_home_mth_pc_nFS),	r(mean)
					mat	list	foodexp_home_mth_pc_nFS
				
				*	Food eaten out
				summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	//	Matches raw data	
				gen		foodexp_out_mth_pc	=	(`foodexp_out_yr'/12)/`famnum'	//	Convert into mthly value per capita
				summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	//	Mean is 
				mat	foodexp_out_mth_pc_all	=	nullmat(foodexp_out_mth_pc_all),	r(mean)
				mat	list	foodexp_out_mth_pc_all
				
					*	Those who redeemed food stamp
					summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 
					summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is
					mat	foodexp_out_mth_pc_FS	=	nullmat(foodexp_out_mth_pc_FS),	r(mean)
					mat	list	foodexp_out_mth_pc_FS
					
					*	Those who didn't redeem food stamp
					summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					mat	foodexp_out_mth_pc_nFS	=	nullmat(foodexp_out_mth_pc_nFS),	r(mean)
					mat	list	foodexp_out_mth_pc_nFS
				
				*	Food stamp redemption by month
				gen		FS_lastmonth	=	0	if	`stamp_ppl_month'==0
				replace	FS_lastmonth	=	1	if	inrange(`stamp_ppl_month',1,12)
				
				bys	svymonth:	summ	FS_lastmonth
				
				*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
				*statsby,  by(svymonth) clear: summ	foodexp_athome_mth_pc
				summ	foodexp_athome_mth_pc
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'!=0 // FS
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'==0 //non-FS
			}
					
			*	1993
			use	"${SNAP_dtRaw}/Unpacked/fam1993.dta", clear
			local	svydate					V22403
			local	foodexp_athome_yr		V21707
			local	foodexp_out_yr			V21711
			local	famnum					V22405
			local	stamp_ppl_month			V21702
			
			{
				*	Month of interview
				gen	svymonth	=	floor(`svydate'/100)	
			
				*	At-home food exp_all
				summ	`foodexp_athome_yr'	if	`foodexp_athome_yr'!=0	//	Matches raw data	(foodexp_athome_yr!=0 to exclude those who didn't respond to this value)
				gen		foodexp_athome_mth_pc	=	(`foodexp_athome_yr'/12)/`famnum'	//	Convert into mthly value per capita
				summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	//	Mean is 
				mat	foodexp_home_mth_pc_all	=	nullmat(foodexp_home_mth_pc_all),	r(mean)
				mat	list	foodexp_home_mth_pc_all
			
					*	Those who redeemed food stamp => Value is the amount "in addition to" food stamp value redeemed.
					*	We determine it by "the number of ppl redeemed FS"
					summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 
					summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is
					mat	foodexp_home_mth_pc_FS	=	nullmat(foodexp_home_mth_pc_FS),	r(mean)
					mat	list	foodexp_home_mth_pc_FS
					
					*	Those who didn't redeem food stamp
					*	Value here is much greater here, since this is not extra value but pure food expenditure
					summ	`foodexp_athome_yr'		if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					summ	foodexp_athome_mth_pc	if	`foodexp_athome_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					mat	foodexp_home_mth_pc_nFS	=	nullmat(foodexp_home_mth_pc_nFS),	r(mean)
					mat	list	foodexp_home_mth_pc_nFS
				
				*	Food eaten out
				summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	//	Matches raw data	
				gen		foodexp_out_mth_pc	=	(`foodexp_out_yr'/12)/`famnum'	//	Convert into mthly value per capita
				summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	//	Mean is 
				mat	foodexp_out_mth_pc_all	=	nullmat(foodexp_out_mth_pc_all),	r(mean)
				mat	list	foodexp_out_mth_pc_all
				
					*	Those who redeemed food stamp
					summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is 
					summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'!=0	//	Mean is
					mat	foodexp_out_mth_pc_FS	=	nullmat(foodexp_out_mth_pc_FS),	r(mean)
					mat	list	foodexp_out_mth_pc_FS
					
					*	Those who didn't redeem food stamp
					summ	`foodexp_out_yr'	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					summ	foodexp_out_mth_pc	if	`foodexp_out_yr'!=0	&	`stamp_ppl_month'==0	//	Mean is 
					mat	foodexp_out_mth_pc_nFS	=	nullmat(foodexp_out_mth_pc_nFS),	r(mean)
					mat	list	foodexp_out_mth_pc_nFS
				
				*	Food stamp redemption by month
				gen		FS_lastmonth	=	0	if	`stamp_ppl_month'==0
				replace	FS_lastmonth	=	1	if	inrange(`stamp_ppl_month',1,12)
				
				bys	svymonth:	summ	FS_lastmonth
				
				*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
				*statsby,  by(svymonth) clear: summ	foodexp_athome_mth_pc
				summ	foodexp_athome_mth_pc
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'!=0 // FS
				bys	svymonth:	summ	foodexp_athome_mth_pc	if	inrange(svymonth,1,12)	&	`stamp_ppl_month'==0 //non-FS
			}
			
			**	No clear discontinuity b/w 1991-1993, both FS and non-FS families
			
				*	No delivered exp in pre-1994; make it as zero value
				mat	foodexp_deli_mth_pc_all	=	0,	0,	0,	0
				mat	foodexp_deli_mth_pc_FS	=	0,	0,	0,	0
				mat	foodexp_deli_mth_pc_nFS	=	0,	0,	0,	0
				
				*	Make a set of matrix to store "home" and "home and dlievered" exp separately
				mat	foodexp_hode_mth_pc_all	=	foodexp_home_mth_pc_all
				mat	foodexp_hode_mth_pc_FS	=	foodexp_home_mth_pc_FS
				mat	foodexp_hode_mth_pc_nFS	=	foodexp_home_mth_pc_nFS
		
			
			*	Now we move on to post-1994
				*	People choose recall period freely

			*	1994
			use	"${SNAP_dtRaw}/Unpacked/fam1994er.dta", clear
			local	svydate					ER2005
			local	famnum					ER2006	//	Number of family members
			
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
			
			local	foodexp_out_FS_amt		ER3083	//	Amt food delivered (FS)
			local	foodexp_out_FS_recall	ER3084	//	Recall  period of delivered food exp (FS)
			local	foodexp_out_nFS_amt		ER3090	//	Amt food delivered (non-FS)
			local	foodexp_out_nFS_recall	ER3091	//	Recall  period of delivered food exp (non-FS)	
				
			{
				*	Date of interview
				*gen	svymonth	=	floor(`svydate'/100)	
				
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
					egen	foodexp_hode_FS_mth_pc	=	rowtotal(foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc)
					
					*br	`FS_used_lastmnth'	`foodexp_home_extra_amt'	`famnum'	`foodexp_home_FS_recall'	foodexp_home_FS_mth_pc	`foodexp_deli_FS_amt'	`foodexp_deli_FS_recall'	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc
					
					
					*	Eaten out
					gen	double	foodexp_out_FS_mth_pc		=	`foodexp_out_FS_amt'/`famnum'
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*4.3	if	`foodexp_out_FS_recall'==1
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*2.15	if	`foodexp_out_FS_recall'==2
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc/12	if	`foodexp_out_FS_recall'==4
					replace		foodexp_out_FS_mth_pc	=	0	if	inlist(`foodexp_out_FS_recall',0,8,9)
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						foreach	var	in	home	deli	hode	out	{
						
							summ	foodexp_`var'_FS_mth_pc	///	
								if	`FS_used_lastmnth'==1	&	foodexp_`var'_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero expenditure
									!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
									!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	//	Mean of mthly is 58.18 (997 obs)	=>	Smooth when compared with 1993! (57.07)
									!inrange(`foodexp_out_FS_amt',9997,99999)
							
							mat	foodexp_`var'_mth_pc_FS	=	nullmat(foodexp_`var'_mth_pc_FS),	r(mean)
							
						}
									
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc	foodexp_out_FS_mth_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_FS_recall'==1	//	Mean of mthly is 96.39 (276 obs)	=>	Those who report wkly recall period report their food expenditure nearly double the amount than those who report monthly recall.
						
						*	HH answered mthly exp (exclude irrational responses)		
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc foodexp_out_FS_mth_pc	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
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
					egen	foodexp_hode_nFS_mth_pc	=	rowtotal(foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc)
					
					*br	`FS_used_lastmnth'	`foodexp_home_amt'	`famnum'	`foodexp_home_nFS_recall'	foodexp_home_nFS_mth_pc	`foodexp_deli_nFS_amt'	`foodexp_deli_nFS_recall'	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc
					
					*	Eaten out
					gen	double	foodexp_out_nFS_mth_pc	=	`foodexp_out_nFS_amt'/`famnum'
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*4.3	if	`foodexp_out_nFS_recall'==1
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*2.15	if	`foodexp_out_nFS_recall'==2
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc/12	if	`foodexp_out_nFS_recall'==4
					replace		foodexp_out_nFS_mth_pc	=	0	if	inlist(`foodexp_out_nFS_recall',0,8,9)
					
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						foreach	var	in	home	deli	hode	out	{
						
							summ	foodexp_`var'_nFS_mth_pc	///	
								if	`FS_used_lastmnth'==5	&	foodexp_`var'_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
									!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
									!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
									!inrange(`foodexp_out_nFS_amt',9997,99999)
							
							mat	foodexp_`var'_mth_pc_nFS	=	nullmat(foodexp_`var'_mth_pc_nFS),	r(mean)
							
						}
							
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc	foodexp_out_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==1	//	Mean of mthly is 176.97 (8,374 obs)	=>	Those who report wkly value report much higher expenditure than monthly expenditure
						
						*	HH answered mthly exp (exclude irrational responses)		
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc	foodexp_out_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==3	//	Mean of mthly is 107.27 (465 obs)
				
				
								
				
				
				*	FS and non-FS (combined)
		
				/*
				*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
						bys	svymonth:	summ	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
				*/
				
				
			}
				
			
			*	1995
			use	"${SNAP_dtRaw}/Unpacked/fam1995er.dta", clear
			local	svydate					ER5004
			local	famnum					ER5005	//	Number of family members
			
			local	FS_used_lastmnth		ER6073	//	Whether used FS last month (dummy)
			
			local	foodexp_home_extra_wth	ER6076	//	Whether used extra amount in addition to FS (dummy)
			local	foodexp_home_extra_amt	ER6077	//	Amount spent at-home in addition to FS (only those who answered "Yes" to above)
			local	foodexp_home_FS_recall	ER6078	//	Recall period of home food exp (FS)	
			local	foodexp_home_amt		ER6084	//	Amount spent at home (non-FS)
			local	foodexp_home_nFS_recall	ER6085	//	Recall period (non-FS)
			
			local	foodexp_deli_FS_amt		ER6080	//	Amt food delivered (FS)
			local	foodexp_deli_FS_recall	ER6081	//	Recall  period of delivered food exp (FS)
			local	foodexp_deli_nFS_amt	ER6087	//	Amt food delivered (non-FS)
			local	foodexp_deli_nFS_recall	ER6088	//	Recall  period of delivered food exp (non-FS)	
			
			local	foodexp_out_FS_amt		ER6082	//	Amt food delivered (FS)	[94]ER3083 [95]ER6082 [96]ER8179 [97]ER11073 
			local	foodexp_out_FS_recall	ER6083	//	Recall  period of delivered food exp (FS)	[94]ER3084 [95]ER6083 [96]ER8180 [97]ER11074
			local	foodexp_out_nFS_amt		ER6089	//	Amt food delivered (non-FS)		[94]ER3090 [95]ER6089 [96]ER8186 [97]ER11081
			local	foodexp_out_nFS_recall	ER6090	//	Recall  period of delivered food exp (non-FS)	[94]ER3091 [95]ER6090 [96]ER8187 [97]ER11082 
			
			
			{
			
				*	Date of interview
				*gen	svymonth	=	floor(`svydate'/100)	
				
				*	Impute monthly food expenditures
			
				*	FS
				summ	`foodexp_home_extra_amt'	if	!inlist(`foodexp_home_extra_amt',0,99998,99999)	//	Matches raw data
				
					*	At-home exp per capita (converted into monthly value)
					gen	double	foodexp_home_FS_mth_pc	=	`foodexp_home_extra_amt'/`famnum'	//	default is monthly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*30.5	if	`foodexp_home_FS_recall'==2	//	Daily (95-96 only)
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*4.3	if	`foodexp_home_FS_recall'==3	//	Wkly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*2.15	if	`foodexp_home_FS_recall'==4	//	Bi-wkly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc/12	if	`foodexp_home_FS_recall'==6	//	Yearly
					replace		foodexp_home_FS_mth_pc	=	0	if	inlist(`foodexp_home_FS_recall',0,7,8,9)	
					
					
					*	Delivered per capita (converted into monthly value)
					gen	double	foodexp_deli_FS_mth_pc		=	`foodexp_deli_nFS_amt'/`famnum'
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*30.5	if	`foodexp_deli_FS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*4.3	if	`foodexp_deli_FS_recall'==3	//	Wkly
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*2.15	if	`foodexp_deli_FS_recall'==4	//	Bi-Wkly
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc/12	if	`foodexp_deli_FS_recall'==6	//	Yearly
					replace		foodexp_deli_FS_mth_pc	=	0	if	inlist(`foodexp_deli_FS_recall',0,7,8,9)
					
					*	At-home + delivered to compare with pre-1994
					egen	foodexp_hode_FS_mth_pc	=	rowtotal(foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc)
					
					*br	`FS_used_lastmnth'	`foodexp_home_extra_amt'	`famnum'	`foodexp_home_FS_recall'	foodexp_home_FS_mth_pc	`foodexp_deli_FS_amt'	`foodexp_deli_FS_recall'	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc
					
					*	Eaten out (converted into monthly value)
					gen	double	foodexp_out_FS_mth_pc		=	`foodexp_out_FS_amt'/`famnum'
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*30.5	if	`foodexp_out_FS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*4.3	if	`foodexp_out_FS_recall'==3	//	Wkly
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*2.15	if	`foodexp_out_FS_recall'==4	//	Bi-Wkly
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc/12	if	`foodexp_out_FS_recall'==6	//	Yearly
					replace		foodexp_out_FS_mth_pc	=	0	if	inlist(`foodexp_out_FS_recall',0,7,8,9)
					
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						foreach	var	in	home	deli	hode	out	{
						
							summ	foodexp_`var'_FS_mth_pc	///	
								if	`FS_used_lastmnth'==1	&	foodexp_`var'_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
									!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
									!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	//	Mean of mthly is 58.18 (997 obs)	=>	Smooth when compared with 1993! (57.07)
									!inrange(`foodexp_out_FS_amt',9997,99999)
							
							mat	foodexp_`var'_mth_pc_FS	=	nullmat(foodexp_`var'_mth_pc_FS),	r(mean)
							
						}
									
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_FS_recall'==1	//	Mean of mthly is 96.39 (276 obs)	=>	Those who report wkly recall period report their food expenditure nearly double the amount than those who report monthly recall.
						
						*	HH answered mthly exp (exclude irrational responses)		
						/*
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_FS_recall'==3	//	Mean of mthly is 42.97 (651 obs)
						*/	
						
				*	Non-FS
				summ	`foodexp_home_amt'	if	!inlist(`foodexp_home_amt',0,99997,99998,99999)	//	Matches raw data, but for follow-up analysis I will exclude values greater than or equal to 9997
						
					*	At-home exp per capita (converted into monthly value)
					gen	double	foodexp_home_nFS_mth_pc	=	`foodexp_home_amt'/`famnum'	//	default is monthly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*30.5	if	`foodexp_home_nFS_recall'==2	//	Daily (95-96 only)
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*4.3		if	`foodexp_home_nFS_recall'==3	//	Wkly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*2.15	if	`foodexp_home_nFS_recall'==4	//	Bi-wkly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc/12		if	`foodexp_home_nFS_recall'==6	//	Yearly
					replace		foodexp_home_nFS_mth_pc	=	0	if	inlist(`foodexp_home_nFS_recall',0,7,8,9)	
					
					
					*	Delivered per capita (converted into monthly value)
					gen	double	foodexp_deli_nFS_mth_pc		=	`foodexp_deli_FS_amt'/`famnum'
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*30.5	if	`foodexp_deli_nFS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*4.3		if	`foodexp_deli_nFS_recall'==3	//	Wkly
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*2.15	if	`foodexp_deli_nFS_recall'==4	//	Bi-Wkly
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc/12		if	`foodexp_deli_nFS_recall'==6	//	Yearly
					replace		foodexp_deli_nFS_mth_pc	=	0	if	inlist(`foodexp_deli_nFS_recall',0,7,8,9)
					
					*	At-home + delivered to compare with pre-1994
					egen	foodexp_hode_nFS_mth_pc	=	rowtotal(foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc)
					
					*br	`FS_used_lastmnth'	`foodexp_home_amt'	`famnum'	`foodexp_home_nFS_recall'	foodexp_home_nFS_mth_pc	`foodexp_deli_nFS_amt'	`foodexp_deli_nFS_recall'	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc
					
					*	Eaten out (converted into monthly value)
					gen	double	foodexp_out_nFS_mth_pc		=	`foodexp_out_nFS_amt'/`famnum'
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*30.5	if	`foodexp_out_nFS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*4.3	if	`foodexp_out_nFS_recall'==3	//	Wkly
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*2.15	if	`foodexp_out_nFS_recall'==4	//	Bi-Wkly
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc/12	if	`foodexp_out_nFS_recall'==6	//	Yearly
					replace		foodexp_out_nFS_mth_pc	=	0	if	inlist(`foodexp_out_nFS_recall',0,7,8,9)
					
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						foreach	var	in	home	deli	hode	out	{
						
							summ	foodexp_`var'_nFS_mth_pc	///	
								if	`FS_used_lastmnth'==5	&	foodexp_`var'_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
									!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
									!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
									!inrange(`foodexp_out_nFS_amt',9997,99999)
							
							mat	foodexp_`var'_mth_pc_nFS	=	nullmat(foodexp_`var'_mth_pc_nFS),	r(mean)
							
						}
							
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==1	//	Mean of mthly is 176.97 (8,374 obs)	=>	Those who report wkly value report much higher expenditure than monthly expenditure
						
						*	HH answered mthly exp (exclude irrational responses)		
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==3	//	Mean of mthly is 107.27 (465 obs)
				
					/*
					*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
						bys	svymonth:	summ	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
					*/
					
			}
				

			*	1996
			use	"${SNAP_dtRaw}/Unpacked/fam1996er.dta", clear
			local	svydate					ER7004
			local	famnum					ER7005	//	Number of family members
			
			local	FS_used_lastmnth		ER8170	//	Whether used FS last month (dummy)
			
			local	foodexp_home_extra_wth	ER8173	//	Whether used extra amount in addition to FS (dummy)
			local	foodexp_home_extra_amt	ER8174	//	Amount spent at-home in addition to FS (only those who answered "Yes" to above)
			local	foodexp_home_FS_recall	ER8175	//	Recall period of home food exp (FS)	
			local	foodexp_home_amt		ER8181	//	Amount spent at home (non-FS)
			local	foodexp_home_nFS_recall	ER8182	//	Recall period (non-FS)
			
			local	foodexp_deli_FS_amt		ER8177	//	Amt food delivered (FS)
			local	foodexp_deli_FS_recall	ER8178	//	Recall  period of delivered food exp (FS)
			local	foodexp_deli_nFS_amt	ER8184	//	Amt food delivered (non-FS)
			local	foodexp_deli_nFS_recall	ER8185	//	Recall  period of delivered food exp (non-FS)	
			
			local	foodexp_out_FS_amt		ER8179	//	Amt food delivered (FS)	[94]ER3083 [95]ER6082 [96]ER8179 [97]ER11073 
			local	foodexp_out_FS_recall	ER8180	//	Recall  period of delivered food exp (FS)	[94]ER3084 [95]ER6083 [96]ER8180 [97]ER11074
			local	foodexp_out_nFS_amt		ER8186	//	Amt food delivered (non-FS)		[94]ER3090 [95]ER6089 [96]ER8186 [97]ER11081
			local	foodexp_out_nFS_recall	ER8187	//	Recall  period of delivered food exp (non-FS)	[94]ER3091 [95]ER6090 [96]ER8187 [97]ER11082 
			
			
			{
			
				*	Date of interview
				*gen	svymonth	=	floor(`svydate'/100)	
				
				*	Impute monthly food expenditures
			
				*	FS
				summ	`foodexp_home_extra_amt'	if	!inlist(`foodexp_home_extra_amt',0,99998,99999)	//	Matches raw data
				
					*	At-home exp per capita (converted into monthly value)
					gen	double	foodexp_home_FS_mth_pc	=	`foodexp_home_extra_amt'/`famnum'	//	default is monthly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*30.5	if	`foodexp_home_FS_recall'==2	//	Daily (95-96 only)
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*4.3	if	`foodexp_home_FS_recall'==3	//	Wkly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*2.15	if	`foodexp_home_FS_recall'==4	//	Bi-wkly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc/12	if	`foodexp_home_FS_recall'==6	//	Yearly
					replace		foodexp_home_FS_mth_pc	=	0	if	inlist(`foodexp_home_FS_recall',0,7,8,9)	
					
					
					*	Delivered per capita (converted into monthly value)
					gen	double	foodexp_deli_FS_mth_pc		=	`foodexp_deli_nFS_amt'/`famnum'
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*30.5	if	`foodexp_deli_FS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*4.3	if	`foodexp_deli_FS_recall'==3	//	Wkly
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*2.15	if	`foodexp_deli_FS_recall'==4	//	Bi-Wkly
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc/12	if	`foodexp_deli_FS_recall'==6	//	Yearly
					replace		foodexp_deli_FS_mth_pc	=	0	if	inlist(`foodexp_deli_FS_recall',0,7,8,9)
					
					*	At-home + delivered to compare with pre-1994
					egen	foodexp_hode_FS_mth_pc	=	rowtotal(foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc)
					
					*br	`FS_used_lastmnth'	`foodexp_home_extra_amt'	`famnum'	`foodexp_home_FS_recall'	foodexp_home_FS_mth_pc	`foodexp_deli_FS_amt'	`foodexp_deli_FS_recall'	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc
					
					*	Eaten out (converted into monthly value)
					gen	double	foodexp_out_FS_mth_pc		=	`foodexp_out_FS_amt'/`famnum'
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*30.5	if	`foodexp_out_FS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*4.3	if	`foodexp_out_FS_recall'==3	//	Wkly
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*2.15	if	`foodexp_out_FS_recall'==4	//	Bi-Wkly
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc/12	if	`foodexp_out_FS_recall'==6	//	Yearly
					replace		foodexp_out_FS_mth_pc	=	0	if	inlist(`foodexp_out_FS_recall',0,7,8,9)
					
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						foreach	var	in	home	deli	hode	out	{
						
							summ	foodexp_`var'_FS_mth_pc	///	
								if	`FS_used_lastmnth'==1	&	foodexp_`var'_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
									!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
									!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	//	Mean of mthly is 58.18 (997 obs)	=>	Smooth when compared with 1993! (57.07)
									!inrange(`foodexp_out_FS_amt',9997,99999)
							
							mat	foodexp_`var'_mth_pc_FS	=	nullmat(foodexp_`var'_mth_pc_FS),	r(mean)
							
						}
									
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_FS_recall'==1	//	Mean of mthly is 96.39 (276 obs)	=>	Those who report wkly recall period report their food expenditure nearly double the amount than those who report monthly recall.
						
						*	HH answered mthly exp (exclude irrational responses)		
						/*
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_FS_recall'==3	//	Mean of mthly is 42.97 (651 obs)
						*/	
						
				*	Non-FS
				summ	`foodexp_home_amt'	if	!inlist(`foodexp_home_amt',0,99997,99998,99999)	//	Matches raw data, but for follow-up analysis I will exclude values greater than or equal to 9997
						
					*	At-home exp per capita (converted into monthly value)
					gen	double	foodexp_home_nFS_mth_pc	=	`foodexp_home_amt'/`famnum'	//	default is monthly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*30.5	if	`foodexp_home_nFS_recall'==2	//	Daily (95-96 only)
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*4.3		if	`foodexp_home_nFS_recall'==3	//	Wkly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*2.15	if	`foodexp_home_nFS_recall'==4	//	Bi-wkly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc/12		if	`foodexp_home_nFS_recall'==6	//	Yearly
					replace		foodexp_home_nFS_mth_pc	=	0	if	inlist(`foodexp_home_nFS_recall',0,7,8,9)	
					
					
					*	Delivered per capita (converted into monthly value)
					gen	double	foodexp_deli_nFS_mth_pc		=	`foodexp_deli_FS_amt'/`famnum'
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*30.5	if	`foodexp_deli_nFS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*4.3		if	`foodexp_deli_nFS_recall'==3	//	Wkly
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*2.15	if	`foodexp_deli_nFS_recall'==4	//	Bi-Wkly
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc/12		if	`foodexp_deli_nFS_recall'==6	//	Yearly
					replace		foodexp_deli_nFS_mth_pc	=	0	if	inlist(`foodexp_deli_nFS_recall',0,7,8,9)
					
					*	At-home + delivered to compare with pre-1994
					egen	foodexp_hode_nFS_mth_pc	=	rowtotal(foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc)
					
					*br	`FS_used_lastmnth'	`foodexp_home_amt'	`famnum'	`foodexp_home_nFS_recall'	foodexp_home_nFS_mth_pc	`foodexp_deli_nFS_amt'	`foodexp_deli_nFS_recall'	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc
					
					*	Eaten out (converted into monthly value)
					gen	double	foodexp_out_nFS_mth_pc		=	`foodexp_out_nFS_amt'/`famnum'
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*30.5	if	`foodexp_out_nFS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*4.3	if	`foodexp_out_nFS_recall'==3	//	Wkly
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*2.15	if	`foodexp_out_nFS_recall'==4	//	Bi-Wkly
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc/12	if	`foodexp_out_nFS_recall'==6	//	Yearly
					replace		foodexp_out_nFS_mth_pc	=	0	if	inlist(`foodexp_out_nFS_recall',0,7,8,9)
					
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						foreach	var	in	home	deli	hode	out	{
						
							summ	foodexp_`var'_nFS_mth_pc	///	
								if	`FS_used_lastmnth'==5	&	foodexp_`var'_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
									!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
									!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
									!inrange(`foodexp_out_nFS_amt',9997,99999)
							
							mat	foodexp_`var'_mth_pc_nFS	=	nullmat(foodexp_`var'_mth_pc_nFS),	r(mean)
							
						}
							
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==1	//	Mean of mthly is 176.97 (8,374 obs)	=>	Those who report wkly value report much higher expenditure than monthly expenditure
						
						*	HH answered mthly exp (exclude irrational responses)		
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==3	//	Mean of mthly is 107.27 (465 obs)
				
					/*
					*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
						bys	svymonth:	summ	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
					*/
					
			}
				
			
			*	1997
			use	"${SNAP_dtRaw}/Unpacked/fam1997er.dta", clear
			
			local	svydate					ER2005
			local	famnum					ER10008	//	Number of family members	
			
			local	FS_used_lastmnth		ER11064	//	Whether used FS last month (dummy)
			
			local	foodexp_home_extra_wth	ER11067	//	Whether used extra amount in addition to FS (dummy)
			local	foodexp_home_extra_amt	ER11068	//	Amount spent at-home in addition to FS (only those who answered "Yes" to above)
			local	foodexp_home_FS_recall	ER11069	//	Recall period of home food exp (FS)	
			local	foodexp_home_amt		ER11076	//	Amount spent at home (non-FS)
			local	foodexp_home_nFS_recall	ER11077	//	Recall period (non-FS)
			
			local	foodexp_deli_FS_amt		ER11071	//	Amt food delivered (FS)
			local	foodexp_deli_FS_recall	ER11072	//	Recall  period of delivered food exp (FS)
			local	foodexp_deli_nFS_amt	ER11079	//	Amt food delivered (non-FS)
			local	foodexp_deli_nFS_recall	ER11080	//	Recall  period of delivered food exp (non-FS)	
			
			local	foodexp_out_FS_amt		ER11073	//	Amt food delivered (FS)	[94]ER3083 [95]ER6082 [96]ER8179 [97]ER11073 
			local	foodexp_out_FS_recall	ER11074	//	Recall  period of delivered food exp (FS)	[94]ER3084 [95]ER6083 [96]ER8180 [97]ER11074
			local	foodexp_out_nFS_amt		ER11081	//	Amt food delivered (non-FS)		[94]ER3090 [95]ER6089 [96]ER8186 [97]ER11081
			local	foodexp_out_nFS_recall	ER11082	//	Recall  period of delivered food exp (non-FS)	[94]ER3091 [95]ER6090 [96]ER8187 [97]ER11082 
			
			
			{
				*	Date of interview
				*gen	svymonth	=	floor(`svydate'/100)	
				
				*	Impute monthly food expenditures
			
				*	FS
				summ	`foodexp_home_extra_amt'	if	!inlist(`foodexp_home_extra_amt',0,99998,99999)	//	Matches raw data
				
					*	At-home exp per capita (converted into monthly value)
					gen	double	foodexp_home_FS_mth_pc	=	`foodexp_home_extra_amt'/`famnum'	//	default is monthly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*30.5	if	`foodexp_home_FS_recall'==2	//	Daily (95-96 only)
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*4.3	if	`foodexp_home_FS_recall'==3	//	Wkly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc*2.15	if	`foodexp_home_FS_recall'==4	//	Bi-wkly
					replace		foodexp_home_FS_mth_pc	=	foodexp_home_FS_mth_pc/12	if	`foodexp_home_FS_recall'==6	//	Yearly
					replace		foodexp_home_FS_mth_pc	=	0	if	inlist(`foodexp_home_FS_recall',0,7,8,9)	
					
					
					*	Delivered per capita (converted into monthly value)
					gen	double	foodexp_deli_FS_mth_pc		=	`foodexp_deli_nFS_amt'/`famnum'
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*30.5	if	`foodexp_deli_FS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*4.3	if	`foodexp_deli_FS_recall'==3	//	Wkly
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc*2.15	if	`foodexp_deli_FS_recall'==4	//	Bi-Wkly
					replace		foodexp_deli_FS_mth_pc	=	foodexp_home_FS_mth_pc/12	if	`foodexp_deli_FS_recall'==6	//	Yearly
					replace		foodexp_deli_FS_mth_pc	=	0	if	inlist(`foodexp_deli_FS_recall',0,7,8,9)
					
					*	At-home + delivered to compare with pre-1994
					egen	foodexp_hode_FS_mth_pc	=	rowtotal(foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc)
					
					*br	`FS_used_lastmnth'	`foodexp_home_extra_amt'	`famnum'	`foodexp_home_FS_recall'	foodexp_home_FS_mth_pc	`foodexp_deli_FS_amt'	`foodexp_deli_FS_recall'	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc
					
					*	Eaten out (converted into monthly value)
					gen	double	foodexp_out_FS_mth_pc		=	`foodexp_out_FS_amt'/`famnum'
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*30.5	if	`foodexp_out_FS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*4.3	if	`foodexp_out_FS_recall'==3	//	Wkly
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc*2.15	if	`foodexp_out_FS_recall'==4	//	Bi-Wkly
					replace		foodexp_out_FS_mth_pc	=	foodexp_out_FS_mth_pc/12	if	`foodexp_out_FS_recall'==6	//	Yearly
					replace		foodexp_out_FS_mth_pc	=	0	if	inlist(`foodexp_out_FS_recall',0,7,8,9)
					
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						foreach	var	in	home	deli	hode	out	{
						
							summ	foodexp_`var'_FS_mth_pc	///	
								if	`FS_used_lastmnth'==1	&	foodexp_`var'_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
									!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
									!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	//	Mean of mthly is 58.18 (997 obs)	=>	Smooth when compared with 1993! (57.07)
									!inrange(`foodexp_out_FS_amt',9997,99999)
							
							mat	foodexp_`var'_mth_pc_FS	=	nullmat(foodexp_`var'_mth_pc_FS),	r(mean)
							
						}
									
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_FS_recall'==1	//	Mean of mthly is 96.39 (276 obs)	=>	Those who report wkly recall period report their food expenditure nearly double the amount than those who report monthly recall.
						
						*	HH answered mthly exp (exclude irrational responses)		
						/*
						summ	foodexp_home_FS_mth_pc	foodexp_deli_FS_mth_pc	foodexp_hode_FS_mth_pc 	///	
							if	`FS_used_lastmnth'==1	&	foodexp_hode_FS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_extra_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_FS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_FS_recall'==3	//	Mean of mthly is 42.97 (651 obs)
						*/	
						
				*	Non-FS
				summ	`foodexp_home_amt'	if	!inlist(`foodexp_home_amt',0,99997,99998,99999)	//	Matches raw data, but for follow-up analysis I will exclude values greater than or equal to 9997
						
					*	At-home exp per capita (converted into monthly value)
					gen	double	foodexp_home_nFS_mth_pc	=	`foodexp_home_amt'/`famnum'	//	default is monthly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*30.5	if	`foodexp_home_nFS_recall'==2	//	Daily (95-96 only)
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*4.3		if	`foodexp_home_nFS_recall'==3	//	Wkly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*2.15	if	`foodexp_home_nFS_recall'==4	//	Bi-wkly
					replace		foodexp_home_nFS_mth_pc	=	foodexp_home_nFS_mth_pc/12		if	`foodexp_home_nFS_recall'==6	//	Yearly
					replace		foodexp_home_nFS_mth_pc	=	0	if	inlist(`foodexp_home_nFS_recall',0,7,8,9)	
					
					
					*	Delivered per capita (converted into monthly value)
					gen	double	foodexp_deli_nFS_mth_pc		=	`foodexp_deli_FS_amt'/`famnum'
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*30.5	if	`foodexp_deli_nFS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*4.3		if	`foodexp_deli_nFS_recall'==3	//	Wkly
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc*2.15	if	`foodexp_deli_nFS_recall'==4	//	Bi-Wkly
					replace		foodexp_deli_nFS_mth_pc	=	foodexp_home_nFS_mth_pc/12		if	`foodexp_deli_nFS_recall'==6	//	Yearly
					replace		foodexp_deli_nFS_mth_pc	=	0	if	inlist(`foodexp_deli_nFS_recall',0,7,8,9)
					
					*	At-home + delivered to compare with pre-1994
					egen	foodexp_hode_nFS_mth_pc	=	rowtotal(foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc)
					
					*br	`FS_used_lastmnth'	`foodexp_home_amt'	`famnum'	`foodexp_home_nFS_recall'	foodexp_home_nFS_mth_pc	`foodexp_deli_nFS_amt'	`foodexp_deli_nFS_recall'	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc
					
					*	Eaten out (converted into monthly value)
					gen	double	foodexp_out_nFS_mth_pc		=	`foodexp_out_nFS_amt'/`famnum'
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*30.5	if	`foodexp_out_nFS_recall'==2	//	Daily (95-96 only)	
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*4.3	if	`foodexp_out_nFS_recall'==3	//	Wkly
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc*2.15	if	`foodexp_out_nFS_recall'==4	//	Bi-Wkly
					replace		foodexp_out_nFS_mth_pc	=	foodexp_out_nFS_mth_pc/12	if	`foodexp_out_nFS_recall'==6	//	Yearly
					replace		foodexp_out_nFS_mth_pc	=	0	if	inlist(`foodexp_out_nFS_recall',0,7,8,9)
					
					*	Summarize 
									
						*	HH with all recall periods (exclude irrational responses)
						foreach	var	in	home	deli	hode	out	{
						
							summ	foodexp_`var'_nFS_mth_pc	///	
								if	`FS_used_lastmnth'==5	&	foodexp_`var'_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
									!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
									!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
									!inrange(`foodexp_out_nFS_amt',9997,99999)
							
							mat	foodexp_`var'_mth_pc_nFS	=	nullmat(foodexp_`var'_mth_pc_nFS),	r(mean)
							
						}
							
						*	HH answered wkly exp (exclude irrational responses)
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==1	//	Mean of mthly is 176.97 (8,374 obs)	=>	Those who report wkly value report much higher expenditure than monthly expenditure
						
						*	HH answered mthly exp (exclude irrational responses)		
						summ	foodexp_home_nFS_mth_pc	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	&	///	exclude irrational delivered food exp
								`foodexp_home_nFS_recall'==3	//	Mean of mthly is 107.27 (465 obs)
				
					/*
					*	Food exp (nFS) by survey month, to see whether there is substantial variation in food exp
						bys	svymonth:	summ	foodexp_deli_nFS_mth_pc	foodexp_hode_nFS_mth_pc 	///	
							if	`FS_used_lastmnth'==5	&	foodexp_hode_nFS_mth_pc!=0	&	///	Those who used food stamp last month with non-zero extra at-home exp
								!inrange(`foodexp_home_amt',9997,99999)	&	///	exclude irrational at-home food exp
								!inrange(`foodexp_deli_nFS_amt',9997,99999)	//	Mean of mthly is 172.00 (9,002 obs)	=>	Huge jump compared to 1993 (135.79)
					*/
					
			}
				
				
				
			*	Append and export matrix
			mat	foodexp_home_1990_1996	=	foodexp_home_mth_pc_nFS	\	foodexp_hode_mth_pc_nFS	\	foodexp_home_mth_pc_FS	\	foodexp_hode_mth_pc_FS
			mat	foodexp_out_1990_1996	=	foodexp_out_mth_pc_nFS	\	foodexp_out_mth_pc_FS
			
			putexcel	set "${SNAP_outRaw}/Foodexp_raw", sheet(byyear) replace	/*modify*/
			putexcel	A3	=	matrix(foodexp_home_1990_1996), names overwritefmt nformat(number_d1)	//	At-home only (no delivered)
			putexcel	A10	=	matrix(foodexp_out_1990_1996), names overwritefmt nformat(number_d1)	//	At-home only (no delivered)