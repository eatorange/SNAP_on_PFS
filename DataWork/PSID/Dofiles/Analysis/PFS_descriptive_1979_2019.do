*	This do-file constructs spells and generates descriptive analyses for historical PFS data, from 1979 to 2019 (with some years missing)


	/****************************************************************
		SECTION 1: Data prep		 									
	****************************************************************/		 
	
	use	"${SNAP_dtInt}/SNAP_long_PFS", clear
 

	*	Keep relevant study sample only
	keep	if	!mi(PFS_glm_noCOLI)
	
	
	*	Construct spell length
		**	IMPORANT NOTE: Since the PFS data has (1) gap period b/w 1988-1991 and (2) changed frequency since 1997, it is not clear how to define "spell"
		**	Based on 2023-7-25 discussion, we decide to define spell as "the number of consecutive 'OBSERVATIONS' experiencing food insecurity", regardless of gap period and updated frequency
			**	We can do robustness check with the updated spell (i) splitting pre-gap period and post-gap period, and (ii) Multiplying spell by 2 for post-1997		
		cap drop	_seq	_spell	_end
		tsspell, cond(year>=1979 & PFS_FI_glm_noCOLI==1)

	*	Create additional indicators
	
		*	FI indicators using FSSS
			
			*	Treat marginally FS as FS
			loc	var	FSSS_FI
			cap	drop	`var'
			gen		`var'=0	if	inrange(HFSM_cat,1,2)
			replace	`var'=1	if	inrange(HFSM_cat,3,4)
			lab	var	`var'	"Food insecure (FSSS)"
			
			*	Treat marginally FS as FI
			loc	var	FSSS_FI_v2
			cap	drop	`var'
			gen		`var'=0	if	inrange(HFSM_cat,1,1)
			replace	`var'=1	if	inrange(HFSM_cat,2,4)
			lab	var	`var'	"Food insecure (FSSS) - ver2"

		*	Create "unique" variable that has only one value for individual (need to generate individual-level summary stats)
			
			*	Gender
			local	var	ind_female
			cap	drop	`var'_uniq
			bys x11101ll	live_in_FU:	gen `var'_uniq=`var' if _n==1	&	live_in_FU==1	
			summ `var'_uniq	
			label	var	`var'_uniq "Gender (ind)"
			
			*	Number of waves living in FU
			loc	var	num_waves_in_FU
			cap	drop	`var'
			cap	drop	`var'_temp
			cap	drop	`var'_uniq
			bys	x11101ll:	egen	`var'=total(live_in_FU)	if	live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
			bys x11101ll:	egen	`var'_temp	=	max(`var')
			bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
			drop	`var'
			rename	`var'_temp	`var'
			summ	`var'_uniq,d
			label	var	`var'_uniq "\# of waves surveyed"
			
			*	Ever-used FS over stuy period
			loc	var	FS_ever_used
			cap	drop	`var'
			cap	drop	`var'_uniq
			cap	drop	`var'_temp
			bys	x11101ll:	egen	`var'=	max(FS_rec_wth)	if live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
			bys x11101ll:	egen	`var'_temp	=	max(`var')
			bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
			drop	`var'
			rename	`var'_temp	`var'
			summ	`var'_uniq ,d
			label var	`var'		"FS ever used throughouth the period"
			label var	`var'_uniq	"FS ever used throughouth the period"
			
			*	# of waves FS redeemed	(if ever used)
			loc	var	total_FS_used
			cap	drop	`var'
			cap	drop	`var'_temp
			cap	drop	`var'_uniq
			bys	x11101ll:	egen	`var'=	total(FS_rec_wth)	if	live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
			bys x11101ll:	egen	`var'_temp	=	max(`var')
			bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
			summ	`var'_uniq if `var'_uniq>=1,d
			label var	`var'		"Total FS used throughouth the period"
			label var	`var'_uniq	"Total FS used throughouth the period"
			
			*	% of FS redeemed (# FS redeemed/# surveyed)		
			loc	var	share_FS_used
			cap	drop	`var'
			cap	drop	`var'_uniq
			gen	`var'	=	total_FS_used_uniq	/	num_waves_in_FU_uniq
			bys x11101ll:	gen 	`var'_uniq	=	`var' if _n==1
			label var	`var'		"\% of FS used throughouth the period"
			label var	`var'_uniq	"\% of FS used throughouth the period"
			
	*	Re-scale annual income per capita
		replace	fam_income_pc_real	=	fam_income_pc_real / 1000
		lab	var	fam_income_pc_real		"Annual family income per capita (K) (Jan 2019 dollars)"
	
	*	Additional cleaning	
		lab	var	foodexp_tot_exclFS_pc_real	"Monthly food expenditure per capita (Jan 2019 dollars)"
		lab	var	FS_rec_amt_capita_real	"SNAP benefit amount (Jan 2019 dollars)"
		lab	var	FS_rec_wth				"Received SNAP"
		
		*	Replace food stamp amount received with missing if didn't receive stamp (FS_rec_wth==0), for summary stats
			*	There are only two obs with non-zero amount, so should be safe to clean.
			*	This code can be integrated into "cleaning" part later (moved as of 2023/7/17)
			*replace	FS_rec_amt_capita_real=.n	if	FS_rec_wth==0
			*replace	FS_rec_amt_capita=.n	if	FS_rec_wth==0
						
		
		
		*	Label variables
			lab	define	rp_female	0	"Male"	1	"Female", replace
			lab	val	rp_female	rp_female
			
			lab	var	ind_female	"Female (ind)"
			label	value	ind_female	rp_female
			
			lab	define	rp_nonWhite	0	"White"	1	"Non-White", replace
			lab	val	rp_nonWhte	rp_nonWhite
			
			lab	define	rp_disabled	0	"NOT disabled"	1	"Disabled", replace
			lab	val	rp_disabled	rp_disabled
			
			

			/*
			*	RP age group (to compare with the Census data)
			*	(Moved to clean.do file as of 2023/7/17)
				*	Below 30.
				loc	var	rp_age_below30
				cap	drop	var
				gen		`var'=0	if	!mi(rp_age)
				replace	`var'=1	if	inrange(rp_age,1,29)
				lab	var	`var'	"RP age below 30"
				
				*	Over 65
				loc	var	rp_age_over65
				cap	drop	var
				gen		`var'=0	if	!mi(rp_age)
				replace	`var'=1	if	inrange(rp_age,66,120)
				lab	var	`var'	"RP age over 65"
			*/
			
			/*
			*	4-year college degree
			*	Current variable (rp_col) also set value to 1 if RP said "yes" to "do you have a college degree?" and has less than 16 years of education.
			*	This could imply that community college degree (2-year) is also included, which might be the reason for sudden jump in 2009
			*	So I create a separate variable recognizing 4-year college degree only
			*	Disabled as of 2023/7/17, as we cannot distinguish whether people has 16-year education and college degree ans 2-year degree or 4-year degree.
			
			loc	var	rp_col_4yr
			cap	drop	`var'
			gen		`var'=.
			
			replace	`var'=0	if	inrange(year,1968,1990)	&	!mi(rp_gradecomp)	&	!inrange(rp_gradecomp,7,8)
			replace	`var'=1	if	inrange(year,1968,1990)	&	!mi(rp_gradecomp)	&	inrange(rp_gradecomp,7,8)	&	rp_coldeg==1
			
			replace	`var'=0	if	inrange(year,1991,2019)	&	!mi(rp_gradecomp)	&	!inrange(rp_gradecomp,16,17)
			replace	`var'=1	if	inrange(year,1991,2019)	&	!mi(rp_gradecomp)	&	inrange(rp_gradecomp,16,17)	&	rp_coldeg==1
			
			replace	`var'=.n	if	inrange(year,1968,1990)	&	inrange(rp_gradecomp,9,9)
			replace	`var'=.n	if	inrange(year,1991,2019)	&	inrange(rp_gradecomp,99,99)
			
			lab	var	`var'	"4-year college degree (RP)"
			*/
			
		*	Save
		save	"${SNAP_dtInt}/SNAP_descdta_1979_2019", replace	//	Inermediate descriptive data for 1979-2019


		
	/****************************************************************
		SECTION 2: Annual trend (including comparison with the census data)
	****************************************************************/		 
			
		
	use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
	assert	!mi(PFS_glm_noCOLI)
		
	*	Basic sample information
		di	_N	// # of observations (non-missing PFS)
		distinct	year	//	26 waves
			
		*	Number of individuals
			distinct	x11101ll	//	# of unique individuals in sample
			distinct	x11101ll	if	baseline_indiv==1	//	# of baseline individuals
			distinct	x11101ll	if	splitoff_indiv==1	//	# of splitoff individuals
	
	
	
	*	Summary stats, pooled

		*	Additional macros are added for summary stats
		
		global	indvars			ind_female	baseline_indiv	splitoff_indiv	num_waves_in_FU_uniq	FS_ever_used_uniq	total_FS_used_uniq	share_FS_used_uniq	//	Individual-level variables
		
		*global	statevars		l2_foodexp_tot_inclFS_pc_1_real l2_foodexp_inclFS_pc_2_real_K
		global	demovars		rp_age /*rp_age_sq*/	rp_female	rp_nonWhte	rp_married	
		global	eduvars_all		rp_NoHS	rp_HS rp_somecol rp_col	//	Include "High school diploma" which was excluded as a reference category in "eduvars" macro (thus in regression)
		global	empvars			rp_employed
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child
		global	regionvars		rp_region_NE rp_region_MidAt rp_region_South rp_region_MidWest rp_region_West
		global	foodvars		FS_rec_wth	//	Should I use prected FS redemption from 1st-stage IV?, or even drop it for exclusion restriction?
		
		*	Monetary variables
		global	econvars		fam_income_pc_real	
		global	foodamtvars		foodexp_tot_exclFS_pc_real	FS_rec_amt_capita_real	
		
		*	State- and Year-FE, which are absorbed in "ppmlhdfe"
		global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1979) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
		
		*	Outcome var (PFS)
		global	outcomevars		PFS_glm	NME	PFS_FI_glm	NME_below_1
		
		*	Set of macros used to generate summary stats
		global	summvars_obs		${demovars}	${eduvars_all}	${empvars}	${healthvars}	${familyvars}	${regionvars}	${foodvars}	${econvars}	${foodamtvars}	${outcomevars}
		
		
		*	Individual-vars
		estpost tabstat	${indvars}	[aw=wgt_long_fam_adj]	if	!mi(num_waves_in_FU_uniq),	statistics(count	mean	sd	min		/*median	p95*/	max) columns(statistics)		// save
		est	store	sumstat_ind
		*estpost tabstat	${indvars}	[aw=wgt_long_fam_adj]	if	!mi(num_waves_in_FU_uniq) & income_below_200==1,	statistics(count	mean	sd	min	median	p95	max) columns(statistics)		// save
		*est	store	sumstat_ind_incbelow200
		
		*	Ind-year vars (observation level)
		estpost tabstat	${summvars_obs}	[aw=wgt_long_fam_adj],	statistics(count	mean	sd	min	median	/*p95*/	max) columns(statistics)		// save
		est	store	sumstat_indyear

		
		esttab	sumstat_ind	sumstat_indyear	using	"${SNAP_outRaw}/Sumstats_desc_7919.csv",  ///
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) p50(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
		
		
		
		*	Scatter plot of survey waves and SNAP frequency
		
		*	First, collapse data to individual-level (should be unweighted)
		preserve
			collapse	(count)	num_waves_in_sample=PFS_FI_glm_noCOLI	///	//	# of waves in sample
						(sum)	total_SNAP_used=FS_rec_wth	///	# of SNAP redemption
						(mean)	wgt_long_fam_adj_avg=wgt_long_fam_adj ///	//	weighted family wgt
							if !mi(PFS_FI_glm_noCOLI), by(x11101ll)
			lab	var	num_waves_in_sample	"# of waves in sample"
			lab	var	total_SNAP_used		"# of SNAP participation in sample"
			lab	var	wgt_long_fam_adj_avg	"Avg longitudinal family wgt - adjusted"
			
			tempfile	col1
			save	`col1', replace
			
		*	Second, collapse data into (# of waves x # of SNAP) level. This can be weighted or unweighted (NOT sure which one is correct)
			
			*	weighted
			collapse	(count) wgt_long_fam_adj_avg [pw=wgt_long_fam_adj_avg], by(num_waves_in_sample total_SNAP_used)
			
			*twoway	contour	wgt_long_fam_adj_avg	total_SNAP_used	num_waves_in_sample // contour plot - looks very odd
			
			twoway	(scatter total_SNAP_used num_waves_in_sample [pw=wgt_long_fam_adj_avg], msymbol(circle_hollow)),	///
				title(Joint distribution of survey waves and SNAP participation)	///
				note(Weighted by longitudinal individual survey weight.)
			graph	export	"${SNAP_outRaw}/joint_waves_SNAP_w.png", replace	
			graph	close
			
			twoway	(scatter total_SNAP_used num_waves_in_sample [pw=wgt_long_fam_adj_avg] if total_SNAP_used>=1, msymbol(circle_hollow)),	///
				title(Joint distribution of survey waves and SNAP participation)	///
				note(Weighted by longitudinal individual survey weight. Zero SNAP participation excluded.)
			graph	export	"${SNAP_outRaw}/joint_waves_SNAP_w_nozero.png", replace	
			graph	close
			
			*	Unweighted
			use	`col1', clear
			
			collapse	(count) wgt_long_fam_adj_avg /*[pw=wgt_long_fam_adj_avg]*/, by(num_waves_in_sample total_SNAP_used)
			
			*twoway	contour	wgt_long_fam_adj_avg	total_SNAP_used	num_waves_in_sample // contour plot - still looks very odd
			twoway	(scatter total_SNAP_used num_waves_in_sample [pw=wgt_long_fam_adj_avg], msymbol(circle_hollow)),	///
				title(Joint distribution of survey waves and SNAP participation)	///
				note(Unweighted.)
			graph	export	"${SNAP_outRaw}/joint_waves_SNAP_uw.png", replace	
			graph	close
			
			twoway	(scatter total_SNAP_used num_waves_in_sample [pw=wgt_long_fam_adj_avg] if total_SNAP_used>=1, msymbol(circle_hollow)),	///
				title(Joint distribution of survey waves and SNAP participation)	///
				note(Zero SNAP participation excluded. Unweighted)
			graph	export	"${SNAP_outRaw}/joint_waves_SNAP_uw_nozero.png", replace	
			graph	close
	restore
	
	
	
	
	
	
	
	
	
	*	Aggregate data into yearly-level

				
		*	Variablest to be collapsed
		local	collapse_vars	foodexp_tot_exclFS_pc	foodexp_tot_inclFS_pc	foodexp_tot_exclFS_pc_real	foodexp_tot_inclFS_pc_real	foodexp_W_TFP_pc foodexp_W_TFP_pc_real	///	//	Food expenditure and TFP cost per capita (nominal and real)
								rp_age	rp_age_below30 rp_age_over65	rp_female	rp_nonWhte	rp_HS	rp_somecol	rp_col	rp_disabled	famnum	FS_rec_wth	FS_rec_amt_capita	FS_rec_amt_capita_real	part_num	///	//	Gender, race, education, FS participation rate, FS amount
								PFS_glm	PFS_glm_noCOLI	NME	PFS_FI_glm	PFS_FI_glm_noCOLI	NME_below_1	FSSS_FI	FSSS_FI_v2	//	Outcome variables	
		
		*	All population
			collapse (mean) `collapse_vars' (median)	rp_age_med=rp_age	[pw=wgt_long_fam_adj], by(year)
			
			lab	var	rp_female	"Female (RP)"
			lab	var	rp_nonWhte	"Non-White (RP)"
			*lab	var	rp_HS_GED	"HS or GED (RP)"
			lab	var	rp_col		"College degree (RP)"
			*lab	var	rp_col_4yr	"4-year College degree (RP)"
			lab	var	rp_disabled	"Disabled (RP)"
			lab	var	FS_rec_wth	"FS received"
			lab	var	PFS_glm		"PFS"
			lab	var	NME			"NME"
			lab	var	PFS_FI_glm	"PFS < 0.5"
			lab	var	NME_below_1	"NME < 1"
			lab	var	foodexp_W_TFP_pc		"Monthly TFP cost per capita"
			lab	var	foodexp_W_TFP_pc_real	"Monthly TFP cost per capita (Jan 2019 dollars)"
			lab	var	foodexp_tot_exclFS_pc		"Monthly Food exp per capita (w/o FS)"
			lab	var	foodexp_tot_inclFS_pc		"Monthly Food exp per capita (with FS)"
			lab	var	foodexp_tot_exclFS_pc_real	"Monthly Food exp per capita (w/o FS)	(Jan 2019 dollars) "
			lab	var	foodexp_tot_inclFS_pc_real	"Monthly Food exp per capita (with FS)	(Jan 2019 dollars) "
			lab	var	FS_rec_amt_capita			"Monthly FS amount per capita"
			lab	var	FS_rec_amt_capita_real		"Monthly FS amount per capita (Jan 2019 dollars)"
		
			
		*	Import Census data
		merge	1:1	year	using	"${SNAP_dtInt}/HH_census_1979_2019.dta", nogen assert(2 3) // Missing years in the PSID data will be imported
					
		*	Import unemploymen rate (national)
		merge	1:1	year	using	"${SNAP_dtInt}/Unemployment Rate_nation.dta", nogen assert(2 3) keep(3) // keep only study period.
		
				
		*	Fraction of population in SNAP
		**	NOTE: This is NOT the same as the official SNAP participation rate issued by the USDA
		loc	var	frac_SNAP_person
		gen	`var'	=	(part_num*1000000)/US_est_pop
		lab	var	`var'	"\% of ppl in US in SNAP"
		
		*	Additional cleaning
		replace	pov_rate_national	=	pov_rate_national/100	//	re-scale poverty rate to vary from 0 to 1
	
		
	
		
		*	Manually plug in FI prevalence rate from the USDA report
		loc	var	FSSS_FI_official
		cap	drop	`var'
		gen		`var'=.
		replace	`var'=0.101	if	year==1999	// 1999: 10.1% are food insecure (7.1% are low food secure, 3.0% are very low food secure)
		replace	`var'=0.107	if	year==2001	// 2001: 10.7% are food insecure (7.4% are low food secure, 3.3% are very low food secure)
		replace	`var'=0.112	if	year==2003	// 2003: 11.2% are food insecure (7.7% are low food secure, 3.5% are very low food secure)
		replace	`var'=0.110	if	year==2005	// 2005: 11.0% are food insecure (7.1% are low food secure, 3.9% are very low food secure)
		replace	`var'=0.111	if	year==2007	// 2007: 11.1% are food insecure (7.0% are low food secure, 4.1% are very low food secure)
		replace	`var'=0.147	if	year==2009	// 2009: 14.7% are food insecure (9.0% are low food secure, 5.7% are very low food secure)
		replace	`var'=0.149	if	year==2011	// 2011: 14.9% are food insecure (9.2% are low food secure, 5.7% are very low food secure)
		replace	`var'=0.143	if	year==2013	// 2013: 14.3% are food insecure (8.7% are low food secure, 5.6% are very low food secure)
		replace	`var'=0.127	if	year==2015	// 2015: 12.7% are food insecure (7.7% are low food secure, 5.0% are very low food secure)
		replace	`var'=0.118	if	year==2017	// 2017: 11.8% are food insecure (7.3% are low food secure, 4.5% are very low food secure)
		replace	`var'=0.105	if	year==2019	// 2019: 10.5% are food insecure (6.6% are low food secure, 3.9% are very low food secure)
		lab	var	`var'	"Official FI Prevalence"
		
		sort	year
		
		*	Save	
		compress
		save	"${SNAP_dtInt}/SNAP_1979_2019_census_annual", replace
		


	*	Annual plots
	use	"${SNAP_dtInt}/SNAP_1979_2019_census_annual", clear
	
		*	Gender (RP) 
		graph	twoway	(line rp_female 			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Study Sample (PSID)")))	///
						(line pct_rp_female_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census"))),	///
						/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
						xline(1987 1992 /*2007*/, axis(1) lcolor(black) lpattern(dash))	///
						xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2019)  ///
						xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Fraction", axis(1)) ///
						ytitle("Percentage", axis(1)) title(Female)	bgcolor(white)	graphregion(color(white)) 	name(gender_annual, replace)	
						/*note("Source: U.S. Census." "All married couple households in the Census are treated as male householder")*/
		
		graph	export	"${SNAP_outRaw}/gender_annual.png", replace	
		graph	close	
		
		*	Race (RP)
		graph	twoway	(line rp_nonWhte 			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Study Sample (PSID)")))	///
						(line pct_rp_nonWhite_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census"))),	///
						/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
						xline(1987 1992 /*2007*/, axis(1) lcolor(black) lpattern(dash))	///
						xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2019)  ///
						xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Fraction", axis(1)) ///
						ytitle("Percentage", axis(1)) title(non-White)	bgcolor(white)	graphregion(color(white)) 	name(race_annual, replace)	
						/*note("Source: U.S. Census." "Shaded region (1988-1991) are missing in the sample" "All households without White householder are treated as non-White in Census")*/
		
		graph	export	"${SNAP_outRaw}/race_annual.png", replace	
		graph	close	
		
		
		grc1leg gender_annual race_annual, rows(1) cols(2) legendfrom(gender_annual)	graphregion(color(white)) position(6)	graphregion(color(white))	///
				title(Gender and Racial Composition of Reference Person) name(gender_race, replace) 	///
				note("Source: U.S. Census" "Shaded region (1988-1991) are missing in the sample" 	"All married couple households are treated as male RP in Census" ///
					"All households without White RP are treated as non-White in Census")  
				
		graph display gender_race, ysize(4) xsize(9.0)
		graph	export	"${SNAP_outRaw}/gender_race_annual.png", as(png) replace
		graph	close
		
		*	Age (RP)
		*	Since Census data does NOT release average age, we use the median age instead	
		graph	twoway	(line rp_age_med			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Study Sample (PSID)")))	///
						(line HH_age_median_Census_int	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census"))),	///
						/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
						xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
						xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
						xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Percent", axis(1)) ///
						ytitle("Age", axis(1)) title(Median of RP age)	bgcolor(white)	graphregion(color(white)) 	name(age_annual, replace)	///
						note(Source: U.S. Census. Median age in Census is rounded up to integer.)
		graph	export	"${SNAP_outRaw}/age_annual.png", replace	
		graph	close
		
		*	Share of HH RP age below 30.
		graph	twoway	(line rp_age_below30 			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Sample")))	///
					(line pct_HH_age_below_30_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census"))),	///	///
					/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
					xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
					xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
					xtitle(Year)	ytitle("Percentage", axis(1)) title(Percentage of RP age below 30) ///
					bgcolor(white)	graphregion(color(white)) 	name(college_annual, replace)	///
					note(Source: U.S. Census.)
		graph	export	"${SNAP_outRaw}/age_below30_annual.png", replace	
		graph	close
		
		*	HH size (RP)
		graph	twoway	(line famnum 			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Study Sample (PSID)")))	///
						(line HH_size_avg_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census"))),	///
						/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
						xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
						xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
						xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Percent", axis(1)) ///
						ytitle("Percentage", axis(1)) title(Aveage Household Size)	bgcolor(white)	graphregion(color(white)) 	name(hhsize_annual, replace)	///
						note(Source: U.S. Census.)
		
		graph	export	"${SNAP_outRaw}/hhsize_annual.png", replace	
		graph	close
		
		*	Educational attainment (college degree) and share of HH
		graph	twoway	(line rp_col 			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Sample; RP")))	///
						(line pct_col_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census; population"))),	///
						/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
						xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
						xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
						xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Percentage (college)", axis(1)) ///
						ytitle("Percentage (age)", axis(1)) title(Educational attainment - college degree )	bgcolor(white)	graphregion(color(white)) 	name(college_annual, replace)	///
						note(Source: U.S. Census. In Census I treat 'completed 4-year of college' as college degree)

		graph	export	"${SNAP_outRaw}/college_annual.png", replace	
		graph	close
		
		
		*	SNAP participation rate and poverty rate
		graph	twoway	(line FS_rec_wth	 	year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "SNAP - Sample")))	///
						(line frac_SNAP_person	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "SNAP - Census and USDA")))	///
						(line pov_rate_national	year, lpattern(dot) xaxis(1 2) yaxis(1)  legend(label(3 "Poverty Rate"))),  ///
						xline(1987 1992 /*2007*/, axis(1) lcolor(black) lpattern(dash))	///
						xline(1989 1990, lwidth(20) lc(gs12)) xlabel(1980(10)2010 2019)  ///
						xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Percent", axis(1)) ///
						ytitle("Age", axis(1)) title(SNAP Participation and Poverty Rate)	bgcolor(white)	graphregion(color(white)) 	name(snap_annual, replace)	///
						note("Source: US Census and USDA." "SNAP - Census and USDA is imputed by dividing the population estimates (Census) by the population in SNAP (USDA)")
		graph display snap_annual, ysize(4) xsize(9.0)
		graph	export	"${SNAP_outRaw}/SNAP_rate_sample_Census_USDA.png", replace	
		graph	close
		
					   
		*	Food expenditure per capita (including stamp benefit), TFP cost (real)
		graph	twoway	(line foodexp_tot_inclFS_pc_real	year, lpattern(dash) xaxis(1 2) yaxis(1)  legend(label(1 "Food exp")))  ///
						(line foodexp_W_TFP_pc_real			year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(2 "TFP cost"))),	///						
						xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
						xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
						xtitle(Year)	xtitle("", axis(2))	ytitle("Food exp with stamp benefit ($)", axis(1)) ///
						/*ytitle("Stamp benefit ($)", axis(2))*/ title(Food expenditure and TFP cost (monthly per capita))	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_TFP_annual, replace)
		
		graph	export	"${SNAP_outRaw}/foodexp_TFP_annual.png", replace	
		graph	close	
		
		
		*	PFS and FSSS dummies with unemployment rate
		graph	twoway	(line PFS_FI_glm_noCOLI	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(1 "PFS < 0.5")))  ///
						(line FSSS_FI_official	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(1)  legend(label(2 "By FSSS")))  ///
						(line unemp_rate	year, lpattern(dot) xaxis(1 2) yaxis(2)  legend(label(3 "Unemployment Rate (%)"))),  ///
						xline(1987 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
						xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
						/*xline(2007 2009, lwidth(28) lc(gs12)) xlabel(1980(10)2010 2007)*/  ///
						xtitle(Year)	xtitle("", axis(2))	ytitle("Scale", axis(1)) 		///
						title(Food Insecurity with Unemployment Rate)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFS_FSSS_annual, replace)
		graph	export	"${SNAP_outRaw}/PFS_FSSS_official_dummies_annual.png", replace	
		graph	close	
			
		*graph	export	"${SNAP_outRaw}/foodexp_FSamt_byyear.png", replace
		*graph	close	








	
	
		
		
		
					
		*	Outcomes over different categories
		
			*	PFS and NME
				
				*	By gender and race
				graph	box	PFS_glm	NME	[aw=wgt_long_fam_adj], over(rp_female) over(rp_nonWhte) nooutsides name(outcome_gen_race, replace) title(Outcomes by Gender and Race)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_gen_race.png", replace	
				graph	close
				
				*	By educational attainment
				graph	box	PFS_glm	NME	[aw=wgt_long_fam_adj], over(rp_edu_cat) nooutsides name(outcome_edu, replace) title(Outcomes by Education)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_edu.png", replace
				graph	close
				
				*	By region
				graph	box	PFS_glm	NME	[aw=wgt_long_fam_adj], over(rp_region) nooutsides name(outcome_region, replace) title(Outcomes by Region)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_region.png", replace
				graph	close
				
				*	By disability
				graph	box	PFS_glm	NME	[aw=wgt_long_fam_adj], over(rp_disabled) nooutsides name(outcome_region, replace) title(Outcomes by Disability)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_disab.png", replace
				graph	close
			
			*	Dummies (PFS<0.5 and NME<1)
				
				*	By Gender and Race
				graph bar PFS_FI_glm NME_below_1	[aw=wgt_long_fam_adj], over(rp_female) over(rp_nonWhte) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Gender and Race)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_gen_race.png", replace	
				graph	close
					
				*	By Educational attainment
				graph bar PFS_FI_glm NME_below_1	[aw=wgt_long_fam_adj], over(rp_edu_cat) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Education)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_edu.png", replace
				graph	close
					
				*	By Region
				graph bar PFS_FI_glm NME_below_1	[aw=wgt_long_fam_adj], over(rp_region) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Region)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_region.png", replace
				graph	close
				
				*	By disability
				graph bar PFS_FI_glm NME_below_1	[aw=wgt_long_fam_adj], over(rp_disabled) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Disability)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_disab.png", replace
				graph	close	
		
			
			*	Food stamp redemption
				
				*	By Gender and Race
				graph bar FS_rec_wth	[aw=wgt_long_fam_adj], over(rp_female) over(rp_nonWhte) blabel(total, format(%12.2f))	///
						legend(lab (1 "Participated in FS") rows(1))	title(Food Stamp Participation by Gender and Race)
				graph	export	"${SNAP_outRaw}/FS_by_gen_race.png", replace	
				graph	close
				
				*	By Educational attainment
				graph bar FS_rec_wth	[aw=wgt_long_fam_adj], over(rp_edu_cat) blabel(total, format(%12.2f))	///
						legend(lab (1 "Participated in FS") rows(1))	title(Food Stamp Participation by Education)
				graph	export	"${SNAP_outRaw}/FS_by_edu.png", replace	
				graph	close
				
				*	Region
				graph bar FS_rec_wth	[aw=wgt_long_fam_adj], over(rp_region) blabel(total, format(%12.2f))	///
						legend(lab (1 "Participated in FS") rows(1))	title(Food Stamp Participation by Region)
				graph	export	"${SNAP_outRaw}/FS_by_region.png", replace	
				graph	close
				
				*	Disability
				graph bar FS_rec_wth	[aw=wgt_long_fam_adj], over(rp_disabled) blabel(total, format(%12.2f))	///
						legend(lab (1 "Participated in FS") rows(1))	title(Food Stamp Participation by Disability)
				graph	export	"${SNAP_outRaw}/FS_by_disab.png", replace	
				graph	close	
		
			
			*	Newly became RP
			sort	x11101ll	year
			cap	drop	newly_RP
			gen	newly_RP=.
			replace	newly_RP=0	if	inrange(year,1968,1997)	&	(!mi(l.RP) | !mi(RP))	//	existed at least one in two consecutive periods.
			replace	newly_RP=0	if	inrange(year,1999,2019)	&	(!mi(l2.RP) | !mi(RP))	//	existed at least one in two consecutive periods.
			replace	newly_RP=1	if	inrange(year,1968,1997)	&	l.RP!=1 & RP==1
			replace	newly_RP=1	if	inrange(year,1999,2019)	&	l2.RP!=1 & RP==1
			lab	var	newly_RP	"Newly became RP"
	

			
			
			
			*	Distribution of PFS over time, by category
			*	"lgraph" ssc ins required
			 use	"${SNAP_dtInt}/SNAP_const", clear
			 	 
				*	Overall 
				lgraph PFS_glm year [aw=wgt_long_fam_adj], errortype(iqr) separate(0.01) title(PFS) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual.png", replace
				graph	close
				
				*	By gender
				lab	define	rp_female	0	"Male"	1	"Female", replace
				lab	val	rp_female	rp_female
				lgraph PFS_glm year rp_female	[aw=wgt_long_fam_adj], errortype(iqr) separate(0.01)  title(PFS by Gender) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual_gender.png", replace
				graph	close
			
				*	By race
				lab	define	rp_nonWhte	0	"White"	1	"non-White", replace
				lab	val	rp_nonWhte	rp_nonWhte
				lgraph PFS_glm year rp_nonWhte	[aw=wgt_long_fam_adj], errortype(iqr) separate(0.01)  title(PFS by Race) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual_race.png", replace
				graph	close
			
				*	By educational attainment
				lgraph PFS_glm year rp_edu_cat	[aw=wgt_long_fam_adj], separate(0.01)  title(PFS by Education) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual_education.png", replace
				graph	close
			
			
				*	By marital status
				lab	define	rp_married	0	"Single or spouse-absent"	1	"Spouse present", replace
				lab	val	rp_married	rp_married
				lgraph PFS_glm year rp_married	[aw=wgt_long_fam_adj], errortype(iqr)	separate(0.01)  title(PFS by marital status) note(25th and 75th percentile)
			
				graph	export	"${SNAP_outRaw}/PFS_annual_marital.png", replace
				graph	close
			
			
			
			*	FSD analysis
				*	PFS threshold value: 0.5
			
			
				*	Define years we will use for dynamics analyses
				*	Due to the lack of data and change in survey frequency, the following year do not have the full 3 observations over 5-year reference period
					*	1977, 1978, 1984-1987, 1994, 1996, 2017, 2019
				*	We tag the years where full dynamics variable can be constructed
				*	(2023-08-03) I no longer consider it, based on the discussion at the AAEA 2023
				/*
				loc	var	dyn_sample_5yr
				cap	drop	`var'
				gen		`var'=0	if	inlist(year,1977,1978,1984,1985,1986,1987,1994,1996,2017,2019)
				replace	`var'=1	if	!inlist(year,1977,1978,1984,1985,1986,1987,1994,1996,2017,2019)
				lab	var	`var'	"Years with full 5-year reference period."
				*	Exclude unbalanced sample
				replace	`var'=0	if	(mi(PFS_glm) | mi(f2.PFS_glm) | mi(f4.PFS_glm))
				*	Missing if PFS is missing
				replace	`var'=.	if	mi(PFS_glm)
				*/
				
				*	Spell length (# of consecutive years experiencing FI)
					
					
					*	Overall
					lgraph SL_5 year [aw=wgt_long_fam_adj] if PFS_FI_glm==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
				
					graph	export	"${SNAP_outRaw}/SL5_annual.png", replace
					graph	close
				
					*	By gender
					lab	define	rp_female	0	"Male"	1	"Female", replace
					lab	val	rp_female	rp_female
					lgraph SL_5 year rp_female [aw=wgt_long_fam_adj] if PFS_FI_glm==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length by gender) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
					graph	export	"${SNAP_outRaw}/SL5_annual_gender.png", replace
					graph	close
			
					
					*	By race
					lab	define	rp_nonWhte	0	"White"	1	"non-White", replace
					lab	val	rp_nonWhte	rp_nonWhte
					lgraph SL_5 year rp_nonWhte [aw=wgt_long_fam_adj] if PFS_FI_glm==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length by race) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
					graph	export	"${SNAP_outRaw}/SL5_annual_race.png", replace
					graph	close
			
					*	By educational attainment
					loc	var	rp_HS_less
					cap	drop	`var'
					gen		`var'=1	if	inlist(rp_edu_cat,1,2)
					replace	`var'=0	if	inlist(rp_edu_cat,3,4)
					replace	`var'=.	if	mi(rp_edu_cat)
					lab	define	`var'	0	"Some college or above"	1	"High school or less", replace
					lab	val	`var'	`var'
					
					lgraph SL_5 year rp_HS_less [aw=wgt_long_fam_adj] if PFS_FI_glm==1 & dyn_sample_5yr==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length by education) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
					graph	export	"${SNAP_outRaw}/SL5_annual_education.png", replace
					graph	close
			
			
			
			
			
			
			
			
			
			
			*	HS, College degree and the age of RP
				*	We observer greater jump of college graduates around the Great Recession 2008
				*	Note: https://hechingerreport.org/how-the-2008-great-recession-affected-higher-education-will-history-repeat/
			graph	twoway	(line rp_HS 		year, lpattern(dash) xaxis(1 2) yaxis(1) legend(label(1 "High school (RP)")))	///
							(line rp_col				year, lpattern(dot) xaxis(1 2) yaxis(1) legend(label(2 "College degree (RP)")))	///
							(line rp_age	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)  legend(label(3 "Age (RP)")))  ,  ///
							/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Share", axis(1)) ///
							/*ytitle("Stamp benefit ($)", axis(2))*/ title(Sample Demographics)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(demographic_annual, replace)
			
			graph	export	"${SNAP_outRaw}/education_age.png", replace	
			graph	close	
			
		
		
	 
			
			*	PFS, NME and Dummies
			graph	twoway	(line PFS_glm 		year, lpattern(dash) xaxis(1 2) yaxis(1) legend(label(1 "PFS")))	///
							(line NME				year, lpattern(dot) xaxis(1 2) yaxis(1) legend(label(2 "NME")))	///
							(line PFS_FI_glm	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)  legend(label(3 "PFS < 0.5")))  ///
							(line NME_below_1			year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(2)  legend(label(4 "NME < 1"))),  ///
							/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Scale", axis(1)) 	ytitle("Share", axis(2))	///
							title(PFS and NME)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFS_NME_annual, replace)
			graph	export	"${SNAP_outRaw}/PFS_NME_annual.png", replace	
			graph	close	
				
			*graph	export	"${SNAP_outRaw}/foodexp_FSamt_byyear.png", replace
			*graph	close	
		
			
		*	Regression
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		
		lab	var	rp_married	"Married (RP)"
		lab	var	rp_NoHS		"Less than HS (RP)"
		lab	var	rp_HS		"High School (RP)"
		lab	var	rp_somecol	"Some college (RP)"
		lab	var	rp_col		"College (RP)"
		lab	var	rp_employed	"Employed (RP)"
		lab	var	rp_disabled	"Disabled (RP)"
		
		lab	var	age_ind		"Age (ind)"
		lab	var	ind_NoHS	"Less than HS (ind)"
		lab	var	ind_HS		"High School (ind)"
		lab	var	ind_somecol	"Some college (ind)"
		lab	var	ind_col		"College (ind)"
		
		*	We do three different outcomes: PFS, FSSS (re-scaled) and NME
		lab	var	PFS_glm_noCOLI	"PFS (w/o COLI)"
		lab	var	HFSM_scale		"FSSS (scaled)"
		lab	var	NME				"Normalized Monetary Score"
		*	For each variable, I will use two different verions; raw variable and standardized variable
		
			foreach	var	in		PFS_glm_noCOLI	HFSM_scale	NME	{
			    
				cap	drop	`var'_std
				summ	`var'
				gen	`var'_std	=	(`var'-r(mean))/r(sd)
				
				
			}
			
		lab	var	PFS_glm_noCOLI_std	"PFS (w/o COLI) - standardized"
		lab	var	HFSM_scale_std		"FSSS (scaled) - standardized"
		lab	var	NME_std				"NME - standardized"
		
		*	We do three different specifications; year FE, year and state-FE, and region+year+indiv FE
		loc	outcome_PFS		PFS_glm_noCOLI
		loc	outcome_FSSS	HFSM_scale
		loc	outcome_NME		NME
		
		global	indvars			/*ind_female*/ age_ind ind_NoHS ind_somecol ind_col /* ind_employed_dummy*/
		
			foreach	depvar	in	PFS	FSSS	NME	{
			   
				
				*	Year FE
					
					*	OLS
					reghdfe	`outcome_`depvar''	/*${statevars}*/ ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${indvars}	[pweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll) /*noabsorb*/	absorb(year)
					est	store	`depvar'_yFE_OLS
					
					/*
					*	Poisson quasi-MLE
					qui	ppmlhdfe	`outcome_`depvar''	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[pweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll)	d
					est	store	`depvar'_noFE_MLE
					
						*	Save marginal effects
						cap	drop	`outcome'hat_noFE
						predict	`outcome'hat_noFE_MLE, mu
						*estadd	matrix	r2_p	=	e(r2_p)	//	Incomplete. Will do this later
						qui	margins, dydx(${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}) post
						est	store	`depvar'_noFE_MLE_margins
					*/
					
				*	State- and Year-FE
					
					*	OLS
					reghdfe	`outcome_`depvar''	/*${statevars}*/ ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${indvars}			[pweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll)	absorb(rp_state year)
						est	store	`depvar'_ysFE_OLS
					/*
					*	MLE
					qui	ppmlhdfe	`outcome_`depvar''	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[pweight=wgt_long_fam_adj],	///
						absorb(rp_state year)	vce(cluster x11101ll)	d
					est	store	`depvar'_noindFE_MLE
						
						*	Save marginal effects
						cap	drop	`outcome'hat_noindFE
						predict	`outcome'hat_noindFE_MLE, mu
						qui	margins, dydx(${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}) post
						est	store	`depvar'_noindFE_MLE_margins
					*/
					
				*	State-, Year- and Indiv-FE
					
					*	OLS
					reghdfe	`outcome_`depvar''	/*${statevars}*/ ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		${indvars}	[pweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll)	absorb(rp_state year x11101ll)
						est	store	`depvar'_ysiFE_OLS
					/*	
					*	MLE
					qui	ppmlhdfe	`outcome_`depvar''	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[pweight=wgt_long_fam_adj],	///
						absorb(rp_state year	x11101ll)	vce(cluster x11101ll)	d
					est	store	`depvar'_indFE_MLE
					
						*	Save marginal effects
						cap	drop	`outcome'hat_indFE
						predict	`outcome'hat_indFE_MLE, mu
						qui	margins, dydx(${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}) post
						est	store	`depvar'_indFE_MLE_margins
					*/
					
					
				*	Report
				
					*	Regression coefficients
						
					*	OLS
					esttab	`depvar'_yFE_OLS	`depvar'_ysFE_OLS		`depvar'_ysiFE_OLS	using "${SNAP_outRaw}/`depvar'_on_HH X_OLS.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(`depvar' on HH Characteristics)		replace	
					/*
					*	MLE
					esttab	`depvar'_noFE_MLE	`depvar'_noindFE_MLE		`depvar'_indFE_MLE		using "${SNAP_outRaw}/`depvar'_on_HH X_MLE.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2_p, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(`depvar' on HH Characteristics)		replace	
							
						*	MLE Marginal effects
						esttab	`depvar'_noFE_margins	`depvar'_noindFE_margins	`depvar'_indFE_margins	using "${SNAP_outRaw}/`depvar'_on_HH X_MLE ME.csv", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2_p, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(`depvar' on HH Characteristics)		replace	
								
					*/
			}
			
			*	Report output in an order I want
			foreach	spec	in	yFE	ysFE	ysiFE	{
			    
				esttab	PFS_`spec'_OLS	FSSS_`spec'_OLS	NME_`spec'_OLS	using "${SNAP_outRaw}/outcomes_on_HH X_OLS_`spec'.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(Food security indicators on HH Characteristics)		replace	
				
			}
	
	