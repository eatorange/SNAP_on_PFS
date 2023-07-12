*	This do-file generates descriptive analyses for historical PFS data, from 1979 to 2019 (with some years missing)


 use	"${SNAP_dtInt}/SNAP_const", clear
 
	
	*	Preamble

		*	ssc install lgraph, replace
		
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
			
			*	RP age group (to compare with the Census data)
			
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
				
			*	4-year college degree
			*	Current variable (rp_col) also set value to 1 if RP said "yes" to "do you have a college degree?" and has less than 16 years of education.
			*	This could imply that community college degree (2-year) is also included, which might be the reason for sudden jump in 2009
			*	So I create a separate variable recognizing 4-year college degree only
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
			
			
		*	Save
		save	"${SNAP_dtInt}/SNAP_descdta_1979_2019", replace	//	Inermediate descriptive data for 1979-2019

	
	*	Importing Census data for comparsion
	*	Note: this section should be moved to the original "SNAP_clean.do" file later.
		
		*	Household by type (gender of householder, family/non-family)
			*	Family: 2 or more people related by marriage/birth/adoption/etc live together
			*	Non-family: Single-person HH, or people unrelated live together.
			import	excel	"${clouldfolder}/DataWork/Census/Historical Household Tables/hh1.xls", sheet(Table HH-1) firstrow	cellrange(A15:K61)	clear
			
			rename	(A B C D F G I J K)	///
					(year total_HH	total_family_HH married_HH family_oth_maleHH family_oth_femaleHH total_nonfamily_HH nonfamily_maleHH nonfamily_femaleHH)
			drop	E H
		
			*	Use the revised record
			*drop	if	year=="2021"
			drop	if	year=="2011"
			drop	if	year=="1993"
			drop	if	year=="1988"
			drop	if	year=="1984"
			drop	if	year=="1980"
			*replace	year="2021" if	year=="2021r"
			replace	year="2014"	if	year=="2014s"
			replace	year="2011" if	year=="2011r"
			replace	year="2001"	if	year=="2001e"
			replace	year="1993"	if	year=="1993r"
			replace	year="1988"	if	year=="1988a"
			replace	year="1984"	if	year=="1984b"
			replace	year="1980"	if	year=="1980c"
			destring	year, replace
			
			*	Label variables
			lab	var	year				"Year"
			lab	var	total_HH			"Total # of HH"
			lab	var	total_family_HH		"Total # of family HH"
			lab	var	married_HH			"Total # of married couples"
			lab	var	family_oth_maleHH	"Total # of other family HH - male householder"
			lab	var	family_oth_femaleHH	"Total # of other family HH - female householder"
			lab	var	total_nonfamily_HH	"Total # of nonfamily HH"
			lab	var	nonfamily_maleHH	"Total # of nonfamily HH - male householder"
			lab	var	nonfamily_femaleHH	"Total # of nonfamily HH - female householder"
			
			*	Generate the share of female-headed HH
			*	Note: In Census, "Married couple" does not say whether householder is male or female, so I cannot figure it out from the data
			*	In this practice, I regard all married couple as male householder, to be consistent with the PSID policy that treats male partner as the reference person.
			loc	var	pct_rp_female_Census
			cap	drop	`var'
			gen	`var'	=	(family_oth_femaleHH + nonfamily_femaleHH) / total_HH
			lab	var	`var'	"\% of female-headed householder (RP) - Census"
			
			*	Save
			save	"${SNAP_dtInt}/HH_type_census.dta", replace
		
		
		*	HH by race
		import	excel	"${clouldfolder}/DataWork/Census/Historical Household Tables/hh2.xls", sheet(Table HH-2) firstrow	cellrange(A14:H56)	clear
		
			*	According to the detailed 2022 data, race has the following categories: (1) White alone (2) Black alone (3) Asian alone (4) Any other single-race or combination of races
			*	However, in this historical data, (4) is not available, and I cannot figure out how to impute it from historical data
			*	Thus, I only keep the following variables (1) Total HH (2) White-alone (3) Black-alone.
				*	Non-White is defined as "(1) - (2)"
			keep A B C E
			rename	(A B C E) (year total_HH White_HH Black_HH)
			
			*	Use revised record
			drop	if	year=="2011"
			
			replace	year="2014"	if	year=="2014s"
			replace	year="2011"	if	year=="2011r"
			replace	year="1980"	if	year=="1980r"
			destring	year, replace
			
			*	Variable label
			lab	var	year	"Year"
			lab	var	total_HH	"Total \# of HH"
			lab	var	White_HH	"Total \# of White householder"
			lab	var	Black_HH	"Total \# of Black householder"
			
			*	Generate percentage indicator
			loc	var	pct_rp_White_Census
			cap	drop	`var'
			gen	`var'	=	(White_HH / total_HH)
			lab	var	`var'	"\% of White householder (RP) - Census"
			
			loc	var	pct_rp_nonWhite_Census
			cap	drop	`var'
			gen	`var'	=	(total_HH - White_HH) / total_HH
			lab	var	`var'	"\% of non-White householder (RP) - Census"
			
			*	Save
			save	"${SNAP_dtInt}/HH_race_census.dta", replace
			
		
		*	Householder age
		import	excel	"${clouldfolder}/DataWork/Census/Historical Household Tables/hh3.xls", sheet(Table HH-3) firstrow	cellrange(A14:K57)	clear
		
			rename	(A-K)	(year	total_HH	HH_age_below_25	HH_age_25_29	HH_age_30_34	HH_age_35_44	///
								HH_age_45_54	HH_age_55_64	HH_age_65_74	HH_age_above_75	HH_age_median)
								
			*	Keep revised record only
			drop	if	year=="2011"
			drop	if	year=="1993"
			
			replace	year="2014"	if	year=="2014s"
			replace	year="2011"	if	year=="2011r"
			replace	year="1993"	if	year=="1993r"
			destring	year,	replace
			
			*	Variable label
			lab	var	year	"Year"
			lab	var	total_HH	"Total \# of HH"
			lab	var	HH_age_below_25	"# of HH - householder age below 25"
			lab	var	HH_age_25_29	"# of HH - householder age 25-29"
			lab	var	HH_age_30_34	"# of HH - householder age 30-34"
			lab	var	HH_age_35_44	"# of HH - householder age 35-44"
			lab	var	HH_age_45_54	"# of HH - householder age 45-54"
			lab	var	HH_age_55_64	"# of HH - householder age 55-64"
			lab	var	HH_age_65_74	"# of HH - householder age 65-74"
			lab	var	HH_age_above_75	"# of HH - householder age 65-74"
			lab	var	HH_age_median	"Median householder age"
		
		*	Generate additional variables
			
			*	Householder age 30 or below
			loc	var	HH_age_below_30_Census
			cap	drop	`var'
			egen	`var'	=	rowtotal(HH_age_below_25	HH_age_25_29)
			lab	var	`var'	"# of HH - householder age below 30 - Census"
			
			loc	var	pct_HH_age_below_30_Census
			cap	drop	`var'
			gen	`var'	=	(HH_age_below_30_Census) / total_HH
			lab	var	`var'	"\% of HH - householder age below 30 - Census"
			
			*	Save
			save	"${SNAP_dtInt}/HH_age_census.dta", replace
			
	
		*	HH size
		import	excel	"${clouldfolder}/DataWork/Census/Historical Household Tables/hh4.xls", sheet(Table HH-4) firstrow	cellrange(A13:J56)	clear
		
			rename	(A B)	(year total_HH)
			rename	(C-H)	HH_size_#, addnumber
			rename	I		HH_size_7_above
			rename	J		HH_size_avg_Census
			
			*	Keep modified record only
			drop	if	year=="2011"
			drop	if	year=="1993"
			
			replace	year="2014"	if	year=="2014s"
			replace	year="2011"	if	year=="2011r"
			replace	year="1993"	if	year=="1993r"
			destring	year, replace
			
			*	Variable label
			lab	var	year	"Year"
			lab	var	total_HH	"Total \# of HH"
			forval	i=1/6	{
				lab	var	HH_size_`i'	"HH size: `i'"
			}
			lab	var	HH_size_7_above	"HH size: 7+"
			lab	var	HH_size_avg_Census	"Average HH size: Census"
			
			*	Save
			save	"${SNAP_dtInt}/HH_size_census.dta", replace
			
		*	Educational attainment (individual-level)
		import	excel	"${clouldfolder}/DataWork/Census/CPS Historical Time Series Tables/taba-1.xlsx", sheet(hst_attain01) firstrow	cellrange(A10:H51)	clear
		
			rename	(A-H)	(year	tot_pop	elem_0to4	elem_5to8	HS_1to3	HS_4	col_1to3	col_4)
			lab	var	year		"Year"
			lab	var	tot_pop		"Population - 25+ years old (K)"
			lab	var	elem_0to4	"Elementary school - 0 to 4 years (K)"
			lab	var	elem_5to8	"Elementary school - 5 to 8 years (K)"
			lab	var	HS_1to3		"High school - 1 to 3 years (K)"
			lab	var	HS_4		"High school - 4 years (K)"
			lab	var	col_1to3	"College - 1 to 3 years (K)"
			lab	var	col_4		"College - 4 years (K)"
			
			*	Generate indicators
			loc	var	pct_noHS_Census
			cap	drop	`var'
			gen	`var'	=	(elem_0to4 + elem_5to8 +	HS_1to3) / tot_pop
			lab	var	`var'	"\% of population less than HS"
			
			loc	var	pct_HS_Census
			cap	drop	`var'
			gen	`var'	=	(HS_4) / tot_pop
			lab	var	`var'	"\% of population HS"
			
			loc	var	pct_somecol_Census
			cap	drop	`var'
			gen	`var'	=	(col_1to3) / tot_pop
			lab	var	`var'	"\% of population with 1-3 college years"
			
			loc	var	pct_col_Census
			cap	drop	`var'
			gen	`var'	=	(col_4) / tot_pop
			lab	var	`var'	"\% of population with 4-year college"
			
			*	Save
			save	"${SNAP_dtInt}/ind_education_CPS.dta", replace
		
		
		*	Poverty status
		import	excel	"${clouldfolder}/DataWork/Census/hstpov2.xlsx", sheet(pov02) firstrow	cellrange(A10:D53)	clear
		
			*	Keep modified record only
			keep	A	D	
			rename	(A	D)	(year	pov_rate)
			
			drop	if	year=="2013 (4)"
			drop	if	year=="2017"
			
			replace	year=substr(year,1,4)
			lab	var	year	"Year"
			lab	var	pov_rate	"Poverty rate"
			destring	year, replace
			
			*	Save
			save	"${SNAP_dtInt}/pov_rate_1979_2019.dta", replace
		
		*	Merge Census HH data
		use	"${SNAP_dtInt}/HH_type_census.dta", clear
		merge	1:1	year	using	"${SNAP_dtInt}/HH_race_census.dta", nogen assert(3)
		merge	1:1	year	using	"${SNAP_dtInt}/HH_age_census.dta", nogen assert(3)
		merge	1:1	year	using	"${SNAP_dtInt}/HH_size_census.dta", nogen assert(3)
		merge	1:1	year	using	"${SNAP_dtInt}/ind_education_CPS.dta", nogen assert(3)
		merge	1:1	year	using	"${SNAP_dtInt}/pov_rate_1979_2019.dta", nogen assert(3)
		save	"${SNAP_dtInt}/HH_census_1979_2019.dta", replace
		
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
		
			
			*	Newly became RP
			sort	x11101ll	year
			cap	drop	newly_RP
			gen	newly_RP=.
			replace	newly_RP=0	if	inrange(year,1968,1997)	&	(!mi(l.RP) | !mi(RP))	//	existed at least one in two consecutive periods.
			replace	newly_RP=0	if	inrange(year,1999,2019)	&	(!mi(l2.RP) | !mi(RP))	//	existed at least one in two consecutive periods.
			replace	newly_RP=1	if	inrange(year,1968,1997)	&	l.RP!=1 & RP==1
			replace	newly_RP=1	if	inrange(year,1999,2019)	&	l2.RP!=1 & RP==1
			lab	var	newly_RP	"Newly became RP"
	
	*	Prepare annually-aggregated data for annual trend plot
	
	use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		
		*	We aggregate data for two different populations: (1) All population  (2) Income below 200%
				*	For now I construct all population sample only
						
				*	Variablest to be collapsed
				local	collapse_vars	foodexp_tot_exclFS_pc	foodexp_tot_inclFS_pc	foodexp_tot_exclFS_pc_real	foodexp_tot_inclFS_pc_real	foodexp_W_TFP_pc foodexp_W_TFP_pc_real	///	//	Food expenditure and TFP cost per capita (nominal and real)
										rp_age	rp_age_below30 rp_age_over65	rp_female	rp_nonWhte	rp_HS	rp_somecol	rp_col	rp_col_4yr	rp_disabled	famnum	FS_rec_wth	FS_rec_amt_capita	FS_rec_amt_capita_real	///	//	Gender, race, education, FS participation rate, FS amount
										PFS_glm	NME	PFS_FI_glm	NME_below_1	//	Outcome variables	
				
				*	All population
					collapse (mean) `collapse_vars' [aw=wgt_long_fam_adj], by(year)
					
					lab	var	rp_female	"Female (RP)"
					lab	var	rp_nonWhte	"Non-White (RP)"
					*lab	var	rp_HS_GED	"HS or GED (RP)"
					lab	var	rp_col		"College degree (RP)"
					lab	var	rp_col_4yr	"4-year College degree (RP)"
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
			
			sort	year
			tempfile	annual_agg_all
			save		`annual_agg_all'
		

		*	Annual plots
		use	`annual_agg_all', clear
		
			*	Gender (RP) 
			graph	twoway	(line rp_female 			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Study Sample (PSID)")))	///
							(line pct_rp_female_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census"))),	///
							/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
							xline(1987 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
							xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
							xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Percent", axis(1)) ///
							ytitle("Percentage", axis(1)) title(Percentage of female RP)	bgcolor(white)	graphregion(color(white)) 	name(gender_annual, replace)	///
							note(Source: U.S. Census. All married couple households in the Census are treated as male householder)
			
			graph	export	"${SNAP_outRaw}/gender_annual.png", replace	
			graph	close	
			
			*	Race (RP)
			graph	twoway	(line rp_nonWhte 			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Study Sample (PSID)")))	///
							(line pct_rp_nonWhite_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census"))),	///
							/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
							xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
							xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
							xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Percent", axis(1)) ///
							ytitle("Percentage", axis(1)) title(Percentage of non-White RP)	bgcolor(white)	graphregion(color(white)) 	name(race_annual, replace)	///
							note(Source: U.S. Census. All households without White householder are treated as non-White in Census)
			
			graph	export	"${SNAP_outRaw}/race_annual.png", replace	
			graph	close	
			
			
			*	Age (RP)
			*	Since Census data does NOT release average age, we use the median age instead	
			use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
			collapse (median) rp_age [aw=wgt_long_fam_adj], by(year)
			merge	1:1	year	using	"${SNAP_dtInt}/HH_age_census.dta", keepusing(HH_age_median)
			gen	HH_age_median_int	=	int(HH_age_median)
			sort	year	
			
			graph	twoway	(line rp_age 			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Study Sample (PSID)")))	///
							(line HH_age_median_int	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census"))),	///
							/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
							xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
							xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
							xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Percent", axis(1)) ///
							ytitle("Age", axis(1)) title(Median of RP age)	bgcolor(white)	graphregion(color(white)) 	name(age_annual, replace)	///
							note(Source: U.S. Census. Median age in Census is rounded up to integer.)
			graph	export	"${SNAP_outRaw}/age_annual.png", replace	
			graph	close
			
				*	Share of HH RP age below 30.
				use	`annual_agg_all', clear
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
			graph	twoway	(line rp_col_4yr 			year, lpattern(dash) xaxis(1) yaxis(1) legend(label(1 "Sample; RP")))	///
							(line pct_col_Census	year, lpattern(dash_dot) xaxis(1) yaxis(1) legend(label(2 "Census; population"))),	///
							/*(line rp_disabled	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(3 "Disabled"))), */ ///
							xline(1987 1992 2007, axis(1) lcolor(black) lpattern(dash))	///
							xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
							xtitle(Year)	/*xtitle("", axis(1))*/	ytitle("Percentage (college)", axis(1)) ///
							ytitle("Percentage (age)", axis(1)) title(Educational attainment - college degree )	bgcolor(white)	graphregion(color(white)) 	name(college_annual, replace)	///
							note(Source: U.S. Census. In Census I treat 'completed 4-year of college' as college degree)

			graph	export	"${SNAP_outRaw}/college_annual.png", replace	
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
			
			
			
			*	FS participation rate and unemployment rate
			graph	twoway	(line FS_rec_wth 	year, lpattern(dash) xaxis(1 2) yaxis(1) legend(label(1 "FS participation (%)")))	///
							(line unemp_rate	year, lpattern(dot) xaxis(1 2) yaxis(2)  legend(label(2 "Unemployment Rate (%)")))  ///
							(line pov_rate	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)  legend(label(3 "Poverty Rate"))),  ///
							xline(1987 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
							xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Fraction", axis(1)) 	ytitle("Percentage (%)", axis(2)) ///
							title(FS participation and monthly benefit amount)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(FS_rate_amt_annual, replace)
							
			graph	export	"${SNAP_outRaw}/FS_rate_amt_annual.png", replace	
			graph	close	
			
		
			
			
			*	PFS and NME dummies and dummy
			graph	twoway	(line PFS_FI_glm	year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(1 "PFS < 0.5")))  ///
							(line NME_below_1	year, /*lpattern(dash_dot)*/ xaxis(1 2) yaxis(1)  legend(label(2 "NME < 1"))),  ///
							xline(1987 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
							xline(1989 1990, lwidth(10) lc(gs12)) xlabel(1980(10)2010 2007)  ///
							xtitle(Year)	xtitle("", axis(2))	ytitle("Scale", axis(1)) 		///
							title(PFS and NME Dummies)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFS_NME_annual, replace)
			graph	export	"${SNAP_outRaw}/PFS_NME_dummies_annual.png", replace	
			graph	close	
				
			*graph	export	"${SNAP_outRaw}/foodexp_FSamt_byyear.png", replace
			*graph	close	
			
			
			
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
				loc	var	dyn_sample_5yr
				cap	drop	`var'
				gen		`var'=0	if	inlist(year,1977,1978,1984,1985,1986,1987,1994,1996,2017,2019)
				replace	`var'=1	if	!inlist(year,1977,1978,1984,1985,1986,1987,1994,1996,2017,2019)
				lab	var	`var'	"Years with full 5-year reference period."
				*	Exclude unbalanced sample
				replace	`var'=0	if	(mi(PFS_glm) | mi(f2.PFS_glm) | mi(f4.PFS_glm))
				*	Missing if PFS is missing
				replace	`var'=.	if	mi(PFS_glm)
				
				*	Spell length (# of consecutive years experiencing FI)
					
					*	Overall
					lgraph SL_5 year [aw=wgt_long_fam_adj] if PFS_FI_glm==1 & dyn_sample_5yr==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
				
					graph	export	"${SNAP_outRaw}/SL5_annual.png", replace
					graph	close
				
					*	By gender
					lab	define	rp_female	0	"Male"	1	"Female", replace
					lab	val	rp_female	rp_female
					lgraph SL_5 year rp_female [aw=wgt_long_fam_adj] if PFS_FI_glm==1 & dyn_sample_5yr==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length by gender) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
					graph	export	"${SNAP_outRaw}/SL5_annual_gender.png", replace
					graph	close
			
					
					*	By race
					lab	define	rp_nonWhte	0	"White"	1	"non-White", replace
					lab	val	rp_nonWhte	rp_nonWhte
					lgraph SL_5 year rp_nonWhte [aw=wgt_long_fam_adj] if PFS_FI_glm==1 & dyn_sample_5yr==1, separate(0.01)  ///
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
	
	