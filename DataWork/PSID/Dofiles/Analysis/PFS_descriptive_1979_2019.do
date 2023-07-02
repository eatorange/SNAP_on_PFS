*	This do-file generates descriptive analyses for historical PFS data, from 1979 to 2019 (with some years missing)


 use	"${SNAP_dtInt}/SNAP_const", clear
 
	
	*	Preamble

		*	Keep relevant study sample only
		keep	if	!mi(PFS_glm)
		
		*	Additional cleaning
		lab	var	fam_income_pc_real		"Annual family income per capita (Jan 2019 dollars)"
		lab	var	foodexp_tot_exclFS_pc_real	"Monthly food expenditure per capita (Jan 2019 dollars)"
		lab	var	FS_rec_amt_capita_real	"stamp amount received (Jan 2019 dollars)"
		
		*	Replace food stamp amount received with missing if didn't receive stamp (FS_rec_wth==0), for summary stats
			*	There are only two obs with non-zero amount, so should be safe to clean.
			*	This code can be integrated into "cleaning" part later
			replace	FS_rec_amt_capita_real=.n	if	FS_rec_wth==0
			replace	FS_rec_amt_capita=.n	if	FS_rec_wth==0
						
		*	Label variables
			lab	define	rp_female	0	"Male"	1	"Female", replace
			lab	val	rp_female	rp_female
			lab	define	rp_nonWhite	0	"White"	1	"Non-White", replace
			lab	val	rp_nonWhte	rp_nonWhite
			lab	define	rp_disabled	0	"NOT disabled"	1	"Disabled", replace
			lab	val	rp_disabled	rp_disabled
			
		
		*	Create individual-level variables
			
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
			
			

	*	Save
	save	"${SNAP_dtInt}/SNAP_descdta_1979_2019", replace	//	Inermediate descriptive data for 1979-2019


	
	*************** Descriptive stats
	use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
	
			
		*	Declare macros
		*	Additional macros are added for summary stats
		
		global	indvars			ind_female	num_waves_in_FU_uniq	FS_ever_used_uniq	total_FS_used_uniq	share_FS_used_uniq	baseline_indiv	splitoff_indiv	//	Individual-level variables
		
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
		
	
	
	
		*	We start with basic sample information
			di	_N	// # of observations (non-missing PFS)
			count if 	income_below_200==1			//	# of observations, with income below 200% PL
			count if 	income_below_200==1		&	baseline_indiv==1	//	Baseline individual in sapmle
			count if 	income_below_200==1		&	splitoff_indiv==1	//	Splitoff individual in sapmle
				
			*	Number of individuals
				distinct	x11101ll	//	# of unique individuals in sample
				distinct	x11101ll	if	baseline_indiv==1	//	# of baseline individuals
				distinct	x11101ll	if	splitoff_indiv==1	//	# of splitoff individuals

			*	Number of waves
			distinct	year	//	26 waves
			
		
		*	Summary stats, pooled
			
			*	Individual-vars
			estpost tabstat	${indvars}	[aw=wgt_long_fam_adj]	if	!mi(num_waves_in_FU_uniq),	statistics(count	mean	sd	min	median	/*p95*/	max) columns(statistics)		// save
			est	store	sumstat_ind_all
			*estpost tabstat	${indvars}	[aw=wgt_long_fam_adj]	if	!mi(num_waves_in_FU_uniq) & income_below_200==1,	statistics(count	mean	sd	min	median	p95	max) columns(statistics)		// save
			*est	store	sumstat_ind_incbelow200
			
			*	Ind-year vars (observation level)
			estpost tabstat	${summvars_obs}	[aw=wgt_long_fam_adj],	statistics(count	mean	sd	min	median	/*p95*/	max) columns(statistics)		// save
			est	store	sumstat_obs_all
			estpost tabstat	${summvars_obs}	[aw=wgt_long_fam_adj]	if	income_below_200==1,	statistics(count	mean	sd	min	median	/*p95*/	max) columns(statistics)		// save
			est	store	sumstat_obs_lowinc
			
			esttab	sumstat_ind_all	sumstat_obs_all		sumstat_obs_lowinc	using	"${SNAP_outRaw}/Sumstats_desc.csv",  ///
					cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) p50(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
					
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
		
	
	
	*	Prepare annually-aggregated data for annual trend plot
	
	use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		
		*	We aggregate data for two different populations: (1) All population  (2) Income below 200%
				*	For now I construct all population sample only
						
				*	Variablest to be collapsed
				local	collapse_vars	foodexp_tot_exclFS_pc	foodexp_tot_inclFS_pc	foodexp_tot_exclFS_pc_real	foodexp_tot_inclFS_pc_real	foodexp_W_TFP_pc foodexp_W_TFP_pc_real	///	//	Food expenditure and TFP cost per capita (nominal and real)
										rp_female	rp_nonWhte	rp_col	rp_disabled	FS_rec_wth	FS_rec_amt_capita	FS_rec_amt_capita_real	///	//	Gender, race, education, FS participation rate, FS amount
										PFS_glm	NME	PFS_FI_glm	NME_below_1	//	Outcome variables	
				
				*	All population
					collapse (mean) `collapse_vars' [aw=wgt_long_fam_adj], by(year)
					
					lab	var	rp_female	"Female (RP)"
					lab	var	rp_nonWhte	"Non-White (RP)"
					*lab	var	rp_HS_GED	"HS or GED (RP)"
					lab	var	rp_col		"College degree (RP)"
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
					
					
					tempfile	annual_agg_all
					save		`annual_agg_all'
			

		
		*	Annual plots
		use	`annual_agg_all', clear
		
			*	Gender, race, HS and college degree
			graph	twoway	(line rp_female 		year, lpattern(dash) xaxis(1 2) yaxis(1) legend(label(1 "Female (RP)")))	///
							(line rp_nonWhte				year, lpattern(dot) xaxis(1 2) yaxis(1) legend(label(2 "Non-White (RP)")))	///
							(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled")))  ///
							(line rp_col			year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(1)  legend(label(4 "College degree"))),  ///
							/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Share", axis(1)) ///
							/*ytitle("Stamp benefit ($)", axis(2))*/ title(Sample Demographics)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(demographic_annual, replace)
			
			graph	export	"${SNAP_outRaw}/demographic_annual.png", replace	
			graph	close	
			
			   
			*	Food expenditure (including stamp benefit), TFP cost (nominal and real)
			graph	twoway	(line foodexp_tot_inclFS_pc 		year, lpattern(dash) xaxis(1 2) yaxis(1) legend(label(1 "Food exp (nominal)")))	///
							(line foodexp_W_TFP_pc				year, lpattern(dot) xaxis(1 2) yaxis(1) legend(label(2 "TFP cost (nominal)")))	///
							(line foodexp_tot_inclFS_pc_real	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Food exp (real)")))  ///
							(line foodexp_W_TFP_pc_real			year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(1)  legend(label(4 "TFP cost (real)"))),  ///
							/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Food exp with stamp benefit ($)", axis(1)) ///
							/*ytitle("Stamp benefit ($)", axis(2))*/ title(Food expenditure and TFP cost (monthly per capita))	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_TFP_annual, replace)
			graph	export	"${SNAP_outRaw}/foodexp_TFP_annual.png", replace	
			graph	close	
		
			*	FS participation rate and FS amount				
			graph	twoway	(line FS_rec_wth 	year, lpattern(dash) xaxis(1 2) yaxis(1) legend(label(1 "FS participation (%)")))	///
							(line FS_rec_amt_capita year, lpattern(dot) xaxis(1 2) yaxis(2) legend(label(2 "FS amount ($) (nominal)")))	///
							(line FS_rec_amt_capita_real	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(2)  legend(label(3 "FS amount ($) (Jan 2019 dollars)"))),  ///
							/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Share (%)", axis(1)) 	ytitle("Amount ($)", axis(2)) ///
							title(FS participation and monthly benefit amount)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(FS_rate_amt_annual, replace)
			graph	export	"${SNAP_outRaw}/FS_rate_amt_annual.png", replace	
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
		
		*	We do three different specifications; no FE at all, region and year FE, and region+year+indiv FE
		*	We do three different outcomes: food expenditure, PFS and NME
				local	outcome_foodexp	foodexp_tot_inclFS_pc_real
				local	outcome_PFS		PFS_glm
				local	outcome_NME		NME
		
			foreach	depvar	in	foodexp	PFS	NME	{
			   
				
				*	No FE at all
					
					*	OLS
					reghdfe	`outcome_`depvar''	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[pweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll) noabsorb
					est	store	`depvar'_noFE_OLS
					
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
					reghdfe	`outcome_`depvar''	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[pweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll)	absorb(rp_state year)
						est	store	`depvar'_noindFE_OLS
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
					reghdfe	`outcome_`depvar''	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[pweight=wgt_long_fam_adj],	///
						vce(cluster x11101ll)	absorb(rp_state year x11101ll)
						est	store	`depvar'_indFE_OLS
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
					esttab	`depvar'_noFE_OLS	`depvar'_noindFE_OLS		`depvar'_indFE_OLS	using "${SNAP_outRaw}/`depvar'_on_HH X_OLS.csv", ///
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
	
	