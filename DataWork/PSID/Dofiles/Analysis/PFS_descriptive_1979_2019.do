*	This do-file constructs spells and generates descriptive analyses for historical PFS data, from 1979 to 2019 (with some years missing)


	/****************************************************************
		SECTION 1: Data prep		 									
	****************************************************************/		 
	
	*	Open 1979-2019 PFS data, which does NOT have spell constructed
	
	use	"${SNAP_dtInt}/SNAP_long_PFS", clear
	
	lab	var	PFS_ppml_noCOLI		"PFS"
	lab	var	PFS_FI_ppml_noCOLI	"Food insecure (PFS < 0.5)"

	*	Keep relevant study sample only
	keep	if	!mi(PFS_ppml_noCOLI)
	
	
	*	Construct spell length
		**	IMPORANT NOTE: Since the PFS data has (1) gap period b/w 1988-1991 and (2) changed frequency since 1997, it is not clear how to define "spell"
		**	Based on 2023-7-25 discussion, we decide to define spell as "the number of consecutive 'OBSERVATIONS' experiencing food insecurity", regardless of gap period and updated frequency
			**	We can do robustness check with the updated spell (i) splitting pre-gap period and post-gap period, and (ii) Multiplying spell by 2 for post-1997		
		cap drop	_seq	_spell	_end
		tsspell, cond(year>=1979 & PFS_FI_ppml_noCOLI==1)

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
		SECTION 2: Summary and Descriptive stats
	****************************************************************/		 
			
		
	use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
	assert	!mi(PFS_ppml_noCOLI)
	
		
	*	Basic sample information
		di	_N	// # of observations (non-missing PFS)
		distinct	year	//	26 waves
			
		*	Number of individuals
			distinct	x11101ll	//	# of unique individuals in sample
			distinct	x11101ll	if	baseline_indiv==1	//	# of baseline individuals
			distinct	x11101ll	if	splitoff_indiv==1	//	# of splitoff individuals
	
	
	
	*	Summary stats, pooled

		*	Additional macros are added for summary stats
		
		global	indvars			ind_female	baseline_indiv	/*splitoff_indiv*/	num_waves_in_FU_uniq	FS_ever_used_uniq	total_FS_used_uniq	/*share_FS_used_uniq*/	//	Individual-level variables
		
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
		global	outcomevars		PFS_ppml_noCOLI	NME	PFS_FI_ppml_noCOLI	NME_below_1
		
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
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
		
		
		
		
		
		
		*	Figure 1: Scatter plot of survey waves and SNAP frequency
		
			*	First, collapse data to individual-level (should be unweighted)
			preserve
				collapse	(count)	num_waves_in_sample=PFS_FI_ppml_noCOLI	///	//	# of waves in sample
							(sum)	total_SNAP_used=FS_rec_wth	///	# of SNAP redemption
							(mean)	wgt_long_fam_adj_avg=wgt_long_fam_adj ///	//	weighted family wgt
								if !mi(PFS_FI_ppml_noCOLI), by(x11101ll)
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
				
				/*	disable other version not used.
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
				*/
			restore
			
	
	
		
	
	
	
	
	
	*	Annual trend

				
		*	Variablest to be collapsed
		local	collapse_vars	foodexp_tot_exclFS_pc	foodexp_tot_inclFS_pc	foodexp_tot_exclFS_pc_real	foodexp_tot_inclFS_pc_real	foodexp_W_TFP_pc foodexp_W_TFP_pc_real	///	//	Food expenditure and TFP cost per capita (nominal and real)
								rp_age	rp_age_below30 rp_age_over65	rp_female	rp_nonWhte	rp_HS	rp_somecol	rp_col	rp_disabled	famnum	FS_rec_wth	FS_rec_amt_capita	FS_rec_amt_capita_real	part_num	///	//	Gender, race, education, FS participation rate, FS amount
								PFS_ppml_noCOLI	NME	PFS_FI_ppml_noCOLI	NME_below_1	FSSS_FI	FSSS_FI_v2	//	Outcome variables	
		
		*	All population
			collapse (mean) `collapse_vars' (median)	rp_age_med=rp_age	[pw=wgt_long_fam_adj], by(year)
			
			lab	var	rp_female	"Female (RP)"
			lab	var	rp_nonWhte	"Non-White (RP)"
			*lab	var	rp_HS_GED	"HS or GED (RP)"
			lab	var	rp_col		"College degree (RP)"
			*lab	var	rp_col_4yr	"4-year College degree (RP)"
			lab	var	rp_disabled	"Disabled (RP)"
			lab	var	FS_rec_wth	"FS received"
			lab	var	PFS_ppml_noCOLI		"PFS"
			lab	var	NME			"NME"
			lab	var	PFS_FI_ppml_noCOLI	"PFS < 0.5"
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
							ytitle("Percentage", axis(1)) title(Female)	yscale(r(0 0.5)) ylabel(0(0.1)0.5)	bgcolor(white)	graphregion(color(white)) 	name(gender_annual, replace)	
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
							ytitle("Percentage", axis(1)) title(non-White)		yscale(r(0 0.5)) ylabel(0(0.1)0.5)	bgcolor(white)	graphregion(color(white)) 	name(race_annual, replace)	
							/*note("Source: U.S. Census." "Shaded region (1988-1991) are missing in the sample" "All households without White householder are treated as non-White in Census")*/
			
			graph	export	"${SNAP_outRaw}/race_annual.png", replace	
			graph	close	
			
			*	Figure 2
			grc1leg gender_annual race_annual, rows(1) cols(2) legendfrom(gender_annual)	graphregion(color(white)) position(6)	graphregion(color(white))	///
					title(Gender and Racial Composition of Reference Person) name(gender_race, replace) 	///
					note("Source: U.S. Census" "Shaded region (1988-1991) are missing in the sample" 	"All married couple households are treated as male RP in Census" ///
						"All households without White RP are treated as non-White in Census")  
					
			graph display gender_race, ysize(4) xsize(9.0)
			graph	export	"${SNAP_outRaw}/gender_race_annual.png", as(png) replace
			graph	close
			
			
			*	Figure 3: SNAP participation rate and poverty rate
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
			
			
			*	Figure A1: Food expenditure per capita (including stamp benefit), TFP cost (real)
			graph	twoway	(line foodexp_tot_inclFS_pc_real	year, lpattern(dash) xaxis(1 2) yaxis(1)  legend(label(1 "Food exp")))  ///
							(line foodexp_W_TFP_pc_real			year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(2 "TFP cost"))),	///						
							xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
							xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Food exp with stamp benefit ($)", axis(1)) ///
							/*ytitle("Stamp benefit ($)", axis(2))*/ title(Food expenditure and TFP cost (monthly per capita))	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_TFP_annual, replace)
			
			graph	export	"${SNAP_outRaw}/foodexp_TFP_annual.png", replace	
			graph	close	
			
			
				*	PFS and FSSS dummies with unemployment rate
			graph	twoway	(line PFS_FI_ppml_noCOLI	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(1 "PFS < 0.5")))  ///
							(line FSSS_FI_official	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(1)  legend(label(2 "By FSSS")))  ///
							(line unemp_rate	year, lpattern(dot) xaxis(1 2) yaxis(2)  legend(label(3 "Unemployment Rate (%)"))),  ///
							xline(1987 1992 /*2007*/, axis(1) lcolor(black) lpattern(solid))	///
							xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
							/*xline(2007 2009, lwidth(28) lc(gs12)) xlabel(1980(10)2010 2007)*/  ///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Fraction", axis(1)) 		///
							title(Food Insecurity with Unemployment Rate)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFS_FSSS_annual, replace)
			graph	export	"${SNAP_outRaw}/PFS_FSSS_official_dummies_annual.png", replace	
			graph	close	
			
			/*	No longer used.
			{		
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
			graph	twoway	(line PFS_ppml_noCOLI 		year, lpattern(dash) xaxis(1 2) yaxis(1) legend(label(1 "PFS")))	///
							(line NME				year, lpattern(dot) xaxis(1 2) yaxis(1) legend(label(2 "NME")))	///
							(line PFS_FI_ppml	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)  legend(label(3 "PFS < 0.5")))  ///
							(line NME_below_1			year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(2)  legend(label(4 "NME < 1"))),  ///
							/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Scale", axis(1)) 	ytitle("Share", axis(2))	///
							title(PFS and NME)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFS_NME_annual, replace)
			graph	export	"${SNAP_outRaw}/PFS_NME_annual.png", replace	
			graph	close	
				
			*graph	export	"${SNAP_outRaw}/foodexp_FSamt_byyear.png", replace
			*graph	close	
		
			
			
				}
			
	
	*/
	
					
		*	Outcomes over different categories
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		
		
			*	PFS by RP's gender and race and education
			graph	box	PFS_ppml_noCOLI		[aw=wgt_long_fam_adj], over(rp_female) over(rp_nonWhte)	over(rp_edu_cat) nooutsides name(outcome_subgroup_rp, replace) title(Food Security by Subgroup) note("")
			graph	export	"${SNAP_outRaw}/PFS_by_rp_subgroup.png", replace	
			graph	close
			
			*	PFS by individual's gender and race and education
				
				*	Cleaning for label
				lab	define	ind_nonWhite	0	"White"	1	"Non-White", replace
				lab	val	ind_nonWhite	ind_nonWhite
				
				*	Temporarily replace "inapp(education)" as missing
				recode	ind_edu_cat	(0=.)	
				
			graph	box	PFS_ppml_noCOLI		[aw=wgt_long_fam_adj], over(ind_female, sort(1)) over(ind_nonWhite, sort(1))	over(ind_edu_cat, sort(1)) nooutsides name(outcome_subgroup_ind, replace) title(Food Security by Subgroup) note("")
			
			graph display outcome_subgroup_ind, ysize(4) xsize(9.0)
			graph	export	"${SNAP_outRaw}/PFS_by_ind_subgroup.png", replace	
			graph	close
			
			*	PFS by individual's gender, race and education
			
			*	Temporarily contruct individual race variable
			
			
			*	PFS and NME
			{	/*
				*	By gender and race
				graph	box	PFS_ppml_noCOLI	NME	[aw=wgt_long_fam_adj], over(rp_female) over(rp_nonWhte) nooutsides name(outcome_gen_race, replace) title(Food Security by Gender and Race)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_gen_race.png", replace	
				graph	close
				
				*	By educational attainment
				graph	box	PFS_ppml_noCOLI	NME	[aw=wgt_long_fam_adj], over(rp_edu_cat) nooutsides name(outcome_edu, replace) title(Food Security by Education)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_edu.png", replace
				graph	close
				
				*	By region
				graph	box	PFS_ppml_noCOLI	NME	[aw=wgt_long_fam_adj], over(rp_region) nooutsides name(outcome_region, replace) title(Food Security by Region)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_region.png", replace
				graph	close
				
				*	By disability
				graph	box	PFS_ppml_noCOLI	NME	[aw=wgt_long_fam_adj], over(rp_disabled) nooutsides name(outcome_region, replace) title(Food Security by Disability)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_disab.png", replace
				graph	close
			
			*	Dummies (PFS<0.5 and NME<1)
				
				*	By Gender and Race
				graph bar PFS_FI_ppml NME_below_1	[aw=wgt_long_fam_adj], over(rp_female) over(rp_nonWhte) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Gender and Race)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_gen_race.png", replace	
				graph	close
					
				*	By Educational attainment
				graph bar PFS_FI_ppml NME_below_1	[aw=wgt_long_fam_adj], over(rp_edu_cat) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Education)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_edu.png", replace
				graph	close
					
				*	By Region
				graph bar PFS_FI_ppml NME_below_1	[aw=wgt_long_fam_adj], over(rp_region) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Region)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_region.png", replace
				graph	close
				
				*	By disability
				graph bar PFS_FI_ppml NME_below_1	[aw=wgt_long_fam_adj], over(rp_disabled) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Disability)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_disab.png", replace
				graph	close	
		
			
			*	SNAP redemption
				
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
			*/	}

			
			
			
			*	Distribution of PFS over time, by category
			*	"lgraph" ssc ins required	 
				*	Overall 
				lgraph PFS_ppml_noCOLI year [aw=wgt_long_fam_adj], errortype(iqr) separate(0.01) title(PFS) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual.png", replace
				graph	close
				
				{	/*
				*	By gender
				lab	define	rp_female	0	"Male"	1	"Female", replace
				lab	val	rp_female	rp_female
				lgraph PFS_ppml_noCOLI year rp_female	[aw=wgt_long_fam_adj], errortype(iqr) separate(0.01)  title(PFS by Gender) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual_gender.png", replace
				graph	close
			
				*	By race
				lab	define	rp_nonWhte	0	"White"	1	"non-White", replace
				lab	val	rp_nonWhte	rp_nonWhte
				lgraph PFS_ppml_noCOLI year rp_nonWhte	[aw=wgt_long_fam_adj], errortype(iqr) separate(0.01)  title(PFS by Race) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual_race.png", replace
				graph	close
			
				*	By educational attainment
				lgraph PFS_ppml_noCOLI year rp_edu_cat	[aw=wgt_long_fam_adj], separate(0.01)  title(PFS by Education) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual_education.png", replace
				graph	close
			
			
				*	By marital status
				lab	define	rp_married	0	"Single or spouse-absent"	1	"Spouse present", replace
				lab	val	rp_married	rp_married
				lgraph PFS_ppml_noCOLI year rp_married	[aw=wgt_long_fam_adj], errortype(iqr)	separate(0.01)  title(PFS by marital status) note(25th and 75th percentile)
			
				graph	export	"${SNAP_outRaw}/PFS_annual_marital.png", replace
				graph	close
				
				*/	}
			
			
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
				replace	`var'=0	if	(mi(PFS_ppml_noCOLI) | mi(f2.PFS_ppml_noCOLI) | mi(f4.PFS_ppml_noCOLI))
				*	Missing if PFS is missing
				replace	`var'=.	if	mi(PFS_ppml_noCOLI)
				*/
				
				*	(2023-08-26) We do not use it
				*	Spell length (# of consecutive years experiencing FI)
				
				{	/*
					
					*	Overall
					lgraph SL_5 year [aw=wgt_long_fam_adj] if PFS_FI_ppml==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
				
					graph	export	"${SNAP_outRaw}/SL5_annual.png", replace
					graph	close
				
					*	By gender
					lab	define	rp_female	0	"Male"	1	"Female", replace
					lab	val	rp_female	rp_female
					lgraph SL_5 year rp_female [aw=wgt_long_fam_adj] if PFS_FI_ppml==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length by gender) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
					graph	export	"${SNAP_outRaw}/SL5_annual_gender.png", replace
					graph	close
			
					
					*	By race
					lab	define	rp_nonWhte	0	"White"	1	"non-White", replace
					lab	val	rp_nonWhte	rp_nonWhte
					lgraph SL_5 year rp_nonWhte [aw=wgt_long_fam_adj] if PFS_FI_ppml==1, separate(0.01)  ///
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
					
					lgraph SL_5 year rp_HS_less [aw=wgt_long_fam_adj] if PFS_FI_ppml==1 & dyn_sample_5yr==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length by education) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
					graph	export	"${SNAP_outRaw}/SL5_annual_education.png", replace
					graph	close
			
					*/	}
			
			
		
	/****************************************************************
		SECTION 3: Regression
	****************************************************************/		 
					
		
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
		*	No longer used
		/*
		{	
		lab	var	PFS_ppml_noCOLI	"PFS (w/o COLI)"
		lab	var	HFSM_scale		"FSSS (scaled)"
		lab	var	NME				"Normalized Monetary Score"
		*	For each variable, I will use two different verions; raw variable and standardized variable
		
			foreach	var	in		PFS_ppml_noCOLI	HFSM_scale	NME	{
			    
				cap	drop	`var'_std
				summ	`var'
				gen	`var'_std	=	(`var'-r(mean))/r(sd)
				
				
			}
			
		lab	var	PFS_ppml_noCOLI_std	"PFS (w/o COLI) - standardized"
		lab	var	HFSM_scale_std		"FSSS (scaled) - standardized"
		lab	var	NME_std				"NME - standardized"
			}
		*/
		*	We do three different specifications; year FE, year and state-FE, and region+year+indiv FE
		loc	outcome_PFS		PFS_ppml_noCOLI
		loc	outcome_FSSS	HFSM_scale
		loc	outcome_NME		NME
		
			*	Set globals
		*global	statevars		l2_foodexp_tot_inclFS_pc_1_real	l2_foodexp_tot_inclFS_pc_2_real 
		global	demovars		rp_age rp_age_sq	rp_nonWhte	rp_married	rp_female	
		global	econvars		ln_fam_income_pc_real	
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child	change_RP
		global	empvars			rp_employed
		global	eduvars			rp_NoHS rp_somecol rp_col
		global	foodvars		FS_rec_wth
		global	macrovars		unemp_rate	CPI
		global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		*global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1978) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
		global	timevars		year_enum4-year_enum11 year_enum14-year_enum30	//	Using year_enum18 (1996) as a base year, when regressing with SNAP index IV (1996-2013)
		global	indvars			/*ind_female*/ age_ind	age_ind_sq ind_NoHS ind_somecol ind_col /* ind_employed_dummy*/
		

				*	State and year FE, no individual vars
					
					*	No individual vars
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	/*${indvars}*/		[aweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll) absorb(rp_state year)	/*noabsorb*/
					est	store	PFS_ysFE_noind
					
					*	Individual vars
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	${indvars}		[aweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll) absorb(rp_state year)	/*noabsorb*/
					est	store	PFS_ysFE_ind
				
				*	State- and Year-FE, Individual FE
					
					*	OLS
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	/*${indvars}*/		[aweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll) absorb(rp_state year	x11101ll)	/*noabsorb*/
					est	store	PFS_ysiFE_noind
					
					*	Individual vars
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	${indvars}		[aweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll) absorb(rp_state year	x11101ll)	/*noabsorb*/
					est	store	PFS_ysiFE_ind
				
					
				*	Report
				
					*	Regression coefficients
						
					*	OLS
					esttab	PFS_ysFE_noind	PFS_ysFE_ind	PFS_ysiFE_noind		PFS_ysiFE_ind	using "${SNAP_outRaw}/PFS_on_HH X.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(`depvar' on HH Characteristics)		replace	
				
			
	/****************************************************************
		SECTION 4: Dynamics analyses
	****************************************************************/		 
					
		
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		svyset	sampcls [pweight=wgt_long_fam_adj] ,strata(sampstr)   singleunit(scaled)	
		
			*	Spell length by subgroup
			cap	mat	drop	summstat_spell_length
			svy, subpop(if _end==1): mean _seq
			estat sd
			mat	summstat_spell_length	=	e(N_sub), r(mean), r(sd)
			mat	list	summstat_spell_length

			
			*	By category (gender, race, education, region, disability)
			foreach	catvar	in	rp_female rp_nonWhte	rp_edu_cat	rp_region rp_disabled	{
						
				di	"catvar is `catvar'"
				
				if	inlist("`catvar'","rp_region")	{	//	region (1-5)
					
					loc	catval	1	2	3	4	5
					
				}	//	region
				
				else	if	inlist("`catvar'","rp_edu_cat")	{	//	edu (1-4)
					
					loc	catval	1	2	3	4		
				
				}	//	edu
				
				else	{	//	binary (0-1)
					
					loc	catval	0	1		
					
				}	//	binary
				
				foreach	val	of	local	catval	{		
					
					di	"value is `val'"
					qui	svy, subpop(if _end==1	&	`catvar'==`val'): mean _seq
					estat	sd
					mat	summstat_spell_length	=	summstat_spell_length	\		(e(N_sub), r(mean), r(sd))
					
				}	//	val		
				
			}	//	catvar
			
			mat	colnames	summstat_spell_length	=	"N"	"Mean"	"SD"
			mat	rownames	summstat_spell_length	=	"All"	"Male"	"Female"	"White"	"Non-White"	"Less than HS"	"HS"	"Some college"	"College"	///
														"Northeast"	"Mid-Atlantic"	"South"	"Midwest"	"West"	"NOT disabled"	"Disabled"
				
			mat	list	summstat_spell_length
			
			putexcel	set	"${SNAP_outRaw}/spell_length_table", sheet(summstat) replace
			putexcel	A5	=	matrix(summstat_spell_length), names overwritefmt nformat(number_d1)
			
			
			
			
		*	Distribution of spell length	
		*	Since "hist" does not accept aweight, we use the percentage in frequency table
		*	Note (2023-08-03) I eyeballed that the percentage in weighted tabluate "tab [aw=]" is equal to the proportion with svy previs "svy: proportion"
		*	Thus if I am interested in that percentage, I can use "tab aw" which is more convenient.
	
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		cap	mat	drop	spell_pct_all
		
		*	All sample
		tab	_seq	[aw=wgt_long_fam_adj]	if	_end==1,	matcell(spell_freq_w)
		mat	list	spell_freq_w
		local	N=r(N)
		mat	spell_pct_tot	=	spell_freq_w	/	r(N)
		
		mat	spell_pct_all		=	nullmat(spell_pct_all),	spell_pct_tot
		
		*	By category
		*	We use categories by - gender, race and college degree (dummy for each category)
		*	I do NOT use individual-information for two reasons; (i) individual-level race not available. (ii) individual-education not available for indivdiual 16-years or less
		
		foreach	catvar	in	rp_female rp_White rp_col	{
			
			foreach	val	in	0 1	{
				
				tab	_seq	[aw=wgt_long_fam_adj]	if	_end==1	&	`catvar'==`val',	matcell(spell_freq_`catvar'_`val')
				mat	list	spell_freq_`catvar'_`val'
				local	N=r(N)
				mat	spell_pct_`catvar'_`val'	=	spell_freq_`catvar'_`val'	/	r(N)	
				mat	list	spell_pct_`catvar'_`val'
				
				mat	spell_pct_all		=	nullmat(spell_pct_all),	spell_pct_`catvar'_`val'
			}
			
		}
		
	
		
	*preserve
	
	
	*	Figures
	
	preserve
	
		clear
		set	obs	26
		gen	spell_length	=	_n
		
		svmat	spell_pct_all
		
		rename	spell_pct_all?	(spell_pct_all	spell_pct_male	spell_pct_female	spell_pct_nonWhite	spell_pct_White	spell_pct_nocol	spell_pct_col)
		
		
		*	Figures
			
			*	All population
			graph hbar spell_pct_all, over(spell_length, sort(spell_percent_w) /*descending*/	label(labsize(vsmall)))	legend(lab (1 "Fraction") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) /*bar(2, fcolor(gs10*0.6))*/	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist.png", replace
			graph	close
			
			*	By gender
			graph hbar spell_pct_male	spell_pct_female, over(spell_length, /*descending*/	label(labsize(vsmall)))	legend(lab (1 "Male") lab(2 "Female") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) bar(2, fcolor(gs10*0.6))	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length - By Gender) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist_gender.png", replace
			graph	close
			
			*	By race
			graph hbar spell_pct_White	spell_pct_nonWhite, over(spell_length, /*descending*/	label(labsize(vsmall)))	legend(lab (1 "White") lab(2 "Non-White") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) bar(2, fcolor(gs10*0.6))	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length - By Race) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist_race.png", replace
			graph	close
			
			*	By education (college degree)
			graph hbar spell_pct_col	spell_pct_nocol, over(spell_length, /*descending*/	label(labsize(vsmall)))	legend(lab (1 "College degree") lab(2 "No college degree") size(small) rows(1))	///
				bar(1, fcolor(gs03*0.5)) bar(2, fcolor(gs10*0.6))	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length - By College) ytitle(Fraction)
		
			graph	export	"${SNAP_outRaw}/Spell_length_dist_college.png", replace
			graph	close
					
	restore
	
			
		
		
		
		
	*	 (2023-08-10) Transition matrix
	sort	x11101ll	year
	
		*	Generate FS variable (the opposite of FI)
		foreach	var	in	ppml_noCOLI	{
			
			cap	drop	PFS_FS_`var'
			clonevar	PFS_FS_`var'	=	PFS_FI_`var'
			recode		PFS_FS_`var'	(1=0)	(0=1)
			
		}
		
		*lab	var	PFS_FS_ppml			"HH is food secure (PFS)"
		lab	var	PFS_FS_ppml_noCOLI	"HH is food secure (PFS w/o COLI)"
				
		*	Generate lagged PFS variable
		foreach	var	in		PFS_FI_ppml_noCOLI	PFS_FS_ppml_noCOLI	{
			
			cap	drop	l2_`var'
			local	label:	variable	label	`var'
			di	"`label'"
			gen	l2_`var'	=	l2.`var'
			lab	var	l2_`var'	"Lagged `label'"
			
		}
		*	Gender
		
		*	Declare macros for each categorical condition
		local	female_cond	rp_female==1
		local	male_cond	rp_female==0
		
		local	nonWhite_cond	rp_White==0
		local	White_cond		rp_White==1
		
		local	NE_cond			rp_region_NE==1 
		local	MidAt_cond		rp_region_MidAt==1
		local	South_cond		rp_region_South==1
		local	MidWest_cond	rp_region_MidWest==1
		local	West_cond		rp_region_West==1
		
		local	NoHS_cond		rp_NoHS==1 
		local	HS_cond			rp_HS==1
		local	somecol_cond	rp_somecol==1 
		local	col_cond		rp_col==1
		
		local	disab_cond		rp_disabled==1
		local	nodisab_cond	rp_disabled==0
		
		local	SNAP_cond		FS_rec_wth==1
		local	noSNAP_cond		FS_rec_wth==0
		
		lab	var	FS_rec_wth	"Received SNAP"
		
		loc	categories	female	male	nonWhite	White	NE	MidAt	South	MidWest	West	NoHS	HS	somecol	col	disab	nodisab	SNAP	noSNAP
		
		*	Loop over categories
		*	NOTE: the joint tabulate command below generates the same relative frequency to the one using "svy:". I use this one for computation speed.
		cap	mat	drop	trans_2by2_combined
		mat	define	blankrow	=	J(1,7,.)
		mat	rownames	blankrow	=	""
		
		foreach	cat	of	local	categories	{
			
		
			*	Joint
			tab		l2_PFS_FS_ppml_noCOLI	PFS_FS_ppml_noCOLI	[aw=wgt_long_fam_adj]		if	``cat'_cond'	& inrange(year,1981,2019), cell matcell(trans_2by2_joint_`cat')
			scalar	samplesize_`cat'	=	trans_2by2_joint_`cat'[1,1] + trans_2by2_joint_`cat'[1,2] + trans_2by2_joint_`cat'[2,1] + trans_2by2_joint_`cat'[2,2]	//	calculate sample size by adding up all
			mat trans_2by2_joint_`cat' = trans_2by2_joint_`cat'[1,1], trans_2by2_joint_`cat'[1,2], trans_2by2_joint_`cat'[2,1], trans_2by2_joint_`cat'[2,2]	//	Make it as a row matrix
			mat trans_2by2_joint_`cat' = trans_2by2_joint_`cat'/samplesize_`cat'	//	Divide it by sample size to compute relative frequency
			mat	list	trans_2by2_joint_`cat'	
			
			*	Marginal
			tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_fam_adj]			if	l2_PFS_FS_ppml_noCOLI==0	& inrange(year,1981,2019)	&	``cat'_cond', matcell(temp)	//	Previously FI
			scalar	persistence_`cat'	=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Persistence rate (FI, FI)
			tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_fam_adj]			if	l2_PFS_FS_ppml_noCOLI==1	& inrange(year,1981,2019)	&	``cat'_cond', matcell(temp)	//	Previously FS
			scalar	entry_`cat'			=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Persistence rate (FI, FI)
				
			*	Combined (Joint + marginal)
			mat	trans_2by2_`cat'	=	samplesize_`cat',	trans_2by2_joint_`cat',	persistence_`cat',	entry_`cat'	
			mat	rownames	trans_2by2_`cat'	=	"`cat'"
			*	Acuumulate rows
			
			if	inlist("`cat'","female","nonWhite","NE","NoHS","disab","SNAP")	{
				
				mat		trans_2by2_combined	=	nullmat(trans_2by2_combined) \ 	blankrow	\	trans_2by2_`cat'	//	Add a blank row at the beginning of subcategory.
				
			}
			else	{
				
				mat		trans_2by2_combined	=	nullmat(trans_2by2_combined) \ trans_2by2_`cat'	//	Add a blank row at the end of subcategory.
				
			}
			
		}
		
		mat	colnames	trans_2by2_combined	=	"N"	"Insecure in both rounds" "Insecure in 1st round only" "Insecure in 2nd round only" "Secure in both rounds" "Persistence" "Entry"
		mat	list	trans_2by2_combined
		
		*	Export
		putexcel	set "${SNAP_outRaw}/Trans_matrix_7919", sheet(Fig_3) replace /*modify*/
		putexcel	A5	=	matrix(trans_2by2_combined), names overwritefmt nformat(number_d2)	//	3a
		
		/*	Equivalent, but takes longer time to run. I just leave it as a reference
		svy, subpop(if rp_female==0):	tab	l2_PFS_FS_ppml_noCOLI	PFS_FS_ppml
		mat	trans_2by2_joint_male = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
		*/
		
			
			
		
		
			
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		*keep	x11101ll	year	wgt_long_fam_adj	sampstr sampcls year	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI
		*	2 X 2 (FS, FI)	-	FS status over two subsequent periods
		
		*svy:	tab	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI  if inrange(year,1981,2019), missing
		*tab year if mi(l2_PFS_FI_ppml_noCOLI) & inrange(year,1981,2019)
		*svy, subpop(if year==1983): tab 	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
		*tab	l2_PFS_FI_ppml PFS_FI_ppml [aw=wgt_long_fam_adj] if year==1999	, missing // give the same ratio
		*local	sample_popsize_total=e(N_subpop)
		*mat	trans_change_1999 = e(b)[1,5], e(b)[1,2], e(b)[1,8]
		*mat list trans_change_1999
		**mat	list	e(b)
		cap	mat	drop	trans_years
		cap	mat	drop	trans_2by2_year
		cap	mat	drop	trans_change_year
		cap	mat	drop	FI_still_year_all
		cap	mat	drop	FI_newly_year_all
		cap	mat	drop	FI_persist_rate*
		cap	mat	drop	FI_entry_rate*
	
		*	Year
		global	transyear	1981 1982 1983 1984 1985 1986 1987 1994 1995 1996 1997 1999 2001 2003 2005 2007 2009 2011 2013 2015 2017 2019	//	Years I will use to generate figures
		*	Make a matrix of year matrix
		
		local	run_fig3=0	//	Estimates sub-group level persistence. Takes a long time to run.
		
		
		
		foreach	year	of	global	transyear	{			

			*	Make a matrix of years
			mat	trans_years	=	nullmat(trans_years)	\	`year'
		
			*	Change in Status - entire population
			**	Note: here we do NOT limit our sample to non-missing values, as we need the ratio of those with missing values.
			svy, subpop(if year==`year'): tab 	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
			local	sample_popsize_total=e(N_subpop)
			mat	trans_change_`year' = e(b)[1,5], e(b)[1,2], e(b)[1,8]
			mat	trans_change_year	=	nullmat(trans_change_year)	\	trans_change_`year'
			
			
			*	Change in status - by group
			if	`run_fig3'==1	{	
			cap	mat	drop	Pop_ratio
			cap	mat	drop	FI_still_`year'	FI_newly_`year'	FI_persist_rate_`year'	FI_entry_rate_`year'
				
				
				foreach	edu	in	0	1	{	//	College, no college
					foreach	race	in	0	1	{	//	People of colors, white
						foreach	gender	in	1	0	{	//	Female, male
							
								
							qui	svy, subpop(if	rp_female==`gender' & rp_White==`race' & rp_col==`edu'	&	year==`year'):	tab l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
												
							local	Pop_ratio	=	e(N_subpop)/`sample_popsize_total'
							local	FI_still_`year'		=	e(b)[1,5]*`Pop_ratio'	//	% of still FI HH in specific group x share of that population in total sample = fraction of HH in that group still FI in among total sample
							local	FI_newly_`year'		=	e(b)[1,2]*`Pop_ratio'	//	% of newly FI HH in specific group x share of that population in total sample = fraction of HH in that group newly FI in among total sample
							local	FI_persist_rate_`year'		=	e(b)[1,5]
							local	FI_entry_rate_`year'		=	e(b)[1,2]
							
							*mat	Pop_ratio	=	nullmat(Pop_ratio)	\	`Pop_ratio'	//	(2023-07-21) Disable it, as we don't need to stack population ratio over years.
							mat	FI_still_`year'	=	nullmat(FI_still_`year')	\	`FI_still_`year''
							mat	FI_newly_`year'	=	nullmat(FI_newly_`year')	\	`FI_newly_`year''
							mat	FI_persist_rate_`year'	=	nullmat(FI_persist_rate_`year')	\	`FI_persist_rate_`year''
							mat	FI_entry_rate_`year'	=	nullmat(FI_entry_rate_`year')	\	`FI_entry_rate_`year''
							
						}	//	gender
					}	//	race
				}	//	education
				
				mat	FI_still_year_all			=	nullmat(FI_still_year_all),	FI_still_`year'
				mat	FI_newly_year_all			=	nullmat(FI_newly_year_all),	FI_newly_`year'
				mat	FI_persist_rate_year_all	=	nullmat(FI_persist_rate_year_all),	FI_persist_rate_`year'
				mat	FI_entry_rate_year_all		=	nullmat(FI_entry_rate_year_all),	FI_entry_rate_`year'
			
			}	//	run_fig3
		
		}	//	year
			
			
			
			*	Figure 2 & 3
			*	Need to plot from matrix, thus create a temporary dataset to do this
			preserve
			
				clear
				
				set	obs	22
				
				*	Matrix for Figure 2
				svmat	trans_years
				svmat	trans_change_year
				rename	(trans_years1 trans_change_year1 trans_change_year2 trans_change_year3)	(year	still_FI	newly_FI	status_unknown)
				drop	status_unknown
				label var	still_FI		"Still food insecure"
				label var	newly_FI		"Newly food insecure"
				
				egen	FI_prevalence	=	rowtotal(still_FI	newly_FI)
				label	var	FI_prevalence	"Annual FI prevalence (<0.5)"
				
				*	Matrix for Figure 3
				**	(FI_still_year_all, FI_newly_year_all) have years in column and category as row, so they need to be transposed)
				foreach	fs_category	in	FI_still_year_all	FI_newly_year_all	{
					
					mat		`fs_category'_tr=`fs_category''
					svmat 	`fs_category'_tr
				}
				
				*	Figure 2	(Change in food security status by year)
					
					*	B&W 
					graph bar still_FI newly_FI, over(year, label(angle(vertical))) stack legend(lab (1 "Still FI") lab(2 "Newly FI")	rows(1))	///
					graphregion(color(white)) bgcolor(white)  bar(1, fcolor(gs11)) bar(2, fcolor(gs6)) bar(3, fcolor(gs1))	///
					ytitle(Fraction of Population) title(Change in Food Security Status)	ylabel(0(.025)0.125) 	
					graph	export	"${SNAP_outRaw}/change_in_status_7919.png", replace
					graph	close
					
					/*
					*	Color
					graph bar still_FI newly_FI	status_unknown, over(year) stack legend(lab (1 "Still FI") lab(2 "Newly FI") lab(3 "Previous status unknown") rows(1))	///
								graphregion(color(white)) bgcolor(white) asyvars bar(1, fcolor(blue*0.5)) bar(2, fcolor(orange)) bar(3, fcolor(gs12))	///
								ytitle(Fraction of Population)	ylabel(0(.025)0.153)
					graph	export	"${PSID_outRaw}/Fig_3_FI_change_status_byyear.png", replace
					graph	close
					*/
				
				*	Figure 3
				*	Figure 3a
				graph bar FI_newly_year_all_tr?, over(year, label(labsize(small))) stack	graphregion(color(white)) bgcolor(white)	ytitle(Fraction of Population)	ylabel(0(.025)0.05)	///
							legend(lab (1 "Col/Non-White/Female ") lab(2 "Col/Non-White/Male") lab(3 "Col/White/Female")	lab(4 "Col/White/Male") 	///
							lab (5 "HS/Non-White/Female") lab(6 "HS/Non-White/Male") lab(7 "HS/White/Female")	lab(8 "HS/White/Male") size(vsmall) rows(3))	///
							bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((a) Newly Food Insecure)	name(Newly_FI, replace) scale(0.8)     
				
				
				*	Figure 3b
				graph bar FI_still_year_all_tr?, over(year, label(labsize(small))) stack	graphregion(color(white)) bgcolor(white)	/*ytitle(Population prevalence(%))*/	ylabel(0(.025)0.1)	///
							legend(lab (1 "Col/Non-White/Female ") lab(2 "Col/Non-White/Male") lab(3 "Col/White/Female")	lab(4 "Col/White/Male") 	///
							lab (5 "HS/Non-White/Female") lab(6 "HS/Non-White/Male") lab(7 "HS/White/Female")	lab(8 "HS/White/Male") size(vsmall) rows(3))	///
							bar(1, fcolor(blue*0.5)) bar(2, fcolor(green*0.6)) bar(3, fcolor(emerald))	bar(4, fcolor(navy*0.5)) bar(5, fcolor(orange)) bar(6, fcolor(black))	///
							bar(7, fcolor(gs14)) bar(8, fcolor(yellow))	title((b) Still Food Insecure)	name(Still_FI, replace)	scale(0.8)  
							
							
				grc1leg Newly_FI Still_FI, rows(2) legendfrom(Newly_FI)	graphregion(color(white)) /*(white)*/
				graph	export	"${SNAP_outRaw}/change_in_status_by_group.png", replace
				graph	close
				
			
			restore
			