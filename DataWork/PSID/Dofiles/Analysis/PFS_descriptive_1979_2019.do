*	This do-file constructs spells and generates descriptive analyses for historical PFS data, from 1979 to 2019 (with some years missing)


	/****************************************************************
		SECTION 1: Data prep		 									
	****************************************************************/		 
	
		
		*	(2024-6-25)	Import GDP growth rate (Source: BEA)
		import excel "${clouldfolder}/DataWork/BEA/change_in_GDP.xlsx", clear
		
			keep	(A-C)
			rename	(A-C)	(year GDP_growth_nominal GDP_growth_real)
			drop	in	1/8
			drop	if	mi(year)
			destring	*, replace 
			lab	var	GDP_growth_nominal	"Annual GDP growth rate (percent) - nominal"
			lab	var	GDP_growth_real		"Annual GDP growth rate (percent) - 2017 dollars"
			
			tempfile	GDP_growth
			save		`GDP_growth'
			
		
			*	(2024-6-26) Import GDP per capita growh rate
			*	Source: World Bank: https://data.worldbank.org/indicator/NY.GDP.PCAP.KD.ZG
			import excel "${clouldfolder}\DataWork\World Bank\GDP_per_capita_growh_rate.xls", sheet("Data") clear
			
				rename	(F-BO)	GDP_pc_growth#, addnumber(1961)
				keep	if	A=="United States"
				reshape	long	GDP_pc_growth, i(A) j(year)
				keep	year	GDP_pc_growth
				destring		GDP_pc_growth, replace
				lab	var			GDP_pc_growth	"Annual GDP per capita growth rate (percent)"
			
			
			*	Merge two different GDP data
			merge	1:1	year	using	`GDP_growth', nogen assert(2 3) keep(3)
			
			*	Save
			save	"${SNAP_dtInt}/GDP_growth_1961_2023", replace
		
		
		*	Public social spending (Source: OECD)
			import excel "${clouldfolder}\DataWork\OECD\public_social_spending.xlsx", sheet("Sheet1") clear
			
				rename	(B-AR)	social_spending#, addnumber(1980)
				keep	if	A=="United States"
				reshape	long	social_spending, i(A) j(year)
				keep	year	social_spending
				drop	if		mi(social_spending)
				destring		social_spending, replace
				lab	var			social_spending	"Social spending (public) as a share of GDP"
			
				*	Save
				save	"${SNAP_dtInt}/social_spending", replace
				
		*	Disposable personal income per capita (2017 dollars)
		*	Source: FRED
			import excel "${clouldfolder}\DataWork\BEA\real_disposable_income_pc.xls", sheet("FRED Graph") clear
			drop	in	1/11
			gen	year = _n + 1958
			keep	if	inrange(year,1959,2023)
			drop	A
			rename	B	dis_per_inc_pc
			destring	dis_per_inc_pc,	replace
			gen			ln_dis_per_inc_pc	=	ln(dis_per_inc_pc)
			lab	var		year	"Year"
			lab	var		dis_per_inc_pc		"Disposable personal income per capita - 2017 dollars"
			lab	var		ln_dis_per_inc_pc	"ln(disposable personal income per capita - 2017 dollars)"
			order	year	dis_per_inc_pc	ln_dis_per_inc_pc
			
			*	Save
			save	"${SNAP_dtInt}/dis_per_inc_pc", replace
			
		*	Gini Index (Source: World Bank)
		import excel "${clouldfolder}\DataWork\World Bank\Gini_index.xls", sheet("Data") clear
		
			rename	(E-BP)	Gini_index#, addnumber(1960)
			keep	if	A=="United States"
			reshape	long	Gini_index, i(A) j(year)
			keep	year	Gini_index
			destring		Gini_index, replace
			drop	if		mi(Gini_index)
			lab	var			Gini_index	"Gini index"
			
			*	Save
			save	"${SNAP_dtInt}/Gini_index", replace
			
			
		*	CPI and TFP cost
		use		"${SNAP_dtInt}/TFP cost/TFP_costs_all", clear
		keep	if	age_ind==25
		collapse	(mean)	TFP_monthly_cost, by(year)
		tempfile	TFP
		save	`TFP'
		
		use		"${SNAP_dtInt}/CPI_1947_2021",	clear
		collapse	(mean)	CPI, by(year)
		merge	1:1	year	using	`TFP'
		
		gen	TFP_monthly_cost_real	=	TFP_monthly_cost	*		(100/CPI)
		keep	if	!mi(TFP_monthly_cost)
		
		graph	twoway	(line	CPI	year, lc(black) lp(solid) lwidth(medium) yaxis(1) graphregion(fcolor(white))) 	///
						(line	TFP_monthly_cost year, lc(reg) lp(dash) lwidth(medium) yaxis(2) graphregion(fcolor(white))) 	///
						(line	TFP_monthly_cost_real year, lc(blue) lp(dot) lwidth(medium) yaxis(2) graphregion(fcolor(white))), 	///
						legend(order(1 "CPI" 2 "TFP cost (nominal)"	3 "TFP cost (real)") size(small) keygap(0.1) symxsize(5)) ///
						title("CPI and TFP monthly cost") ytitle("CPI", axis(1))  ytitle("Amount ($)", axis(2))	xtitle("Year") name(CPI_TFP, replace)	///
						note(TFP cost for 25-year old. Averaged over gender and month)
		graph	export	"${SNAP_outRaw}/CPI_TFP_trend.png", as(png) replace
		
		
		*	Add official "individual" food insecurity prevalence rate from the USDA report.
		*	Source
			*	2020 report (2006-2019), 2006 report (1998-2005), 1999 report (1995-1997)
			import excel "${clouldfolder}/DataWork/USDA/DataSets/Raw/US_FI_prevalence_rate.xlsx", sheet("person") firstrow clear
			rename	(*)	(year	total_K	FS_K	FS_pct	FI_K	FI_pct	LFS_K	LFS_pct	VLFS_K	VLFS_pct)
			foreach	pct_var	in	FS_pct	FI_pct	LFS_pct	VLFS_pct	{
				
				replace	`pct_var'	=	`pct_var'	/	100
				
			}
						
			compress				
			save	"${SNAP_dtInt}/USDA_FI_prevalnce_rate_person.dta", replace
			
			
	
	*	Open 1979-2019 PFS data, which does NOT have spell constructed
	
	use	"${SNAP_dtInt}/SNAP_long_PFS", clear
	lab	var	PFS_ppml_noCOLI		"PFS"
	
	sort	year	x11101ll
	
		*	Import USDA FI prevalnce rate (person)
		merge	m:1	year	using	"${SNAP_dtInt}/USDA_FI_prevalnce_rate_person.dta",  keep(1 3) nogen keepusing(FI_pct LFS_pct	VLFS_pct)
		lab	var	FI_pct		"FI (national)"
		lab	var	LFS_pct		"Low food secure (national)"
		lab	var	VLFS_pct	"Very low food secure (national)"

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

	
	
	*	Categorize food security status based on annual food security prevalence rate (1996-2019)
	*	CAUTION: TAKES SOME TIME
	*	This code is take from the LBH, with a few minor modification 
		
		
			*	Categorize food security status based on the PFS.
			 quietly	{
				foreach	type	in	ppml_noCOLI	/*ls	rf*/	{
						
						cap	drop		PFS_FS_`type'
						cap	drop		PFS_FI_`type'
						
						gen	PFS_FS_`type'	=	0	if	!mi(PFS_`type')	//	Food secure
						gen	PFS_FI_`type'	=	0	if	!mi(PFS_`type')	//	Food insecure (low food secure and very low food secure)
						*gen	PFS_LFS_`type'	=	0	if	!mi(PFS_`type')	//	Low food secure
						*gen	PFS_VLFS_`type'	=	0	if	!mi(PFS_`type')	//	Very low food secure
						*gen	PFS_cat_`type'	=	0	if	!mi(PFS_`type')	//	Categorical variable: FS, LFS or VLFS
												
						*	Generate a variable for the threshold PFS
						cap	drop	PFS_threshold_`type'
						gen	PFS_threshold_`type'=.
						
						foreach	year	in	1995 1996 1997 1999 2001 2003 2005 2007 2009 2011 2013 2015 2017 2019	{
							
							*if	"`type'"=="glm_RPPadj" & inrange(`year',2,5) continue	
							
							di	"current loop is `plan',  in year `year'"
							cap	drop	pctile_`type'_`year'
							xtile pctile_`type'_`year' = PFS_`type' if !mi(PFS_`type')	&	year==`year', nq(1000)
	
							* We use loop to find the threshold value for categorizing households as food (in)secure
							local	counter 	=	1	//	reset counter
							local	ratio_FI	=	0	//	reset FI population ratio
							*local	ratio_VLFS	=	0	//	reset VLFS population ratio
							
							foreach	indicator	in	FI	/*VLFS*/	{
								
								local	counter 	=	1	//	reset counter
								local	ratio_`indicator'	=	0	//	reset population ratio
							
								* To decrease running time, we first loop by 10 
								summ	`indicator'_pct if year==`year'
								local	prop_`indicator'_`year'=r(mean)
								
								while (`counter' < 1000 & `ratio_`indicator''<`prop_`indicator'_`year'') {	//	Loop until population ratio > USDA ratio
									
									qui di	"current indicator is `indicator', counter is `counter'"
									qui	replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,`counter')	//	categorize certain number of households at bottom as FI
									
									*qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'	//	Generate population ratio
									*local ratio_`indicator' = _b[PFS_`indicator'_`type']
									
									summ	PFS_`indicator'_`type'	[aw=wgt_long_ind]	if	year==`year'
									local ratio_`indicator'	=	r(mean)
									
									local counter = `counter' + 10	//	Increase counter by 10
								}

								*	Since we first looped by unit of 10, we now have to find to exact value by looping 1 instead of 10.
								qui di "internediate counter is `counter'"
								local	counter=`counter'-10	//	Adjust the counter, since we added extra 10 at the end of the first loop

								while (`counter' > 1 & `ratio_`indicator''>`prop_`indicator'_`year'') {	//	Loop until population ratio < USDA ratio
									
									qui di "counter is `counter'"
									qui	replace	PFS_`indicator'_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',`counter',1000)
									*qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'
									*local ratio_`indicator' = _b[PFS_`indicator'_`type']
									summ	PFS_`indicator'_`type'	[aw=wgt_long_ind]	if	year==`year'
									local ratio_`indicator'	=	r(mean)
									
									local counter = `counter' - 1
								}
								qui di "Final counter is `counter'"

								*	Now we finalize the threshold value - whether `counter' or `counter'+1
									
									*	Counter
									local	diff_case1	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')

									*	Counter + 1
									qui	replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,`counter'+1)
									*qui	svy, subpop(year_enum`year'): mean 	PFS_`indicator'_`type'
									*local	ratio_`indicator' = _b[PFS_`indicator'_`type']
									summ	PFS_`indicator'_`type'	[aw=wgt_long_ind]	if	year==`year'
									local ratio_`indicator'	=	r(mean)
									
									local	diff_case2	=	abs(`prop_`indicator'_`year''-`ratio_`indicator'')
									qui	di "diff_case2 is `diff_case2'"

									*	Compare two threshold values and choose the one closer to the USDA value
									if	(`diff_case1'<`diff_case2')	{
										global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'
									}
									else	{	
										global	threshold_`indicator'_`plan'_`type'_`year'	=	`counter'+1
									}
								
								*	Categorize households based on the finalized threshold value.
								qui	{
									replace	PFS_`indicator'_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',1,${threshold_`indicator'_`plan'_`type'_`year'})
									replace	PFS_`indicator'_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',${threshold_`indicator'_`plan'_`type'_`year'}+1,1000)		
								}	
								di "thresval of `indicator' in year `year' is ${threshold_`indicator'_`plan'_`type'_`year'}"
							}	//	indicator
							
							*	Food secure households
							replace	PFS_FS_`type'=0	if	year==`year'	&	inrange(pctile_`type'_`year',1,${threshold_FI_`plan'_`type'_`year'})
							replace	PFS_FS_`type'=1	if	year==`year'	&	inrange(pctile_`type'_`year',${threshold_FI_`plan'_`type'_`year'}+1,1000)
							
							*	Low food secure households
							*replace	PFS_LFS_`type'=1	if	year==`year'	&	PFS_FI_`type'==1	&	PFS_VLFS_`type'==0	//	food insecure but NOT very low food secure households			
							
							*	Categorize households into one of the three values: FS, LFS and VLFS						
							*replace	PFS_cat_`type'=1	if	year==`year'	&	PFS_VLFS_`type'==1
							*replace	PFS_cat_`type'=2	if	year==`year'	&	PFS_LFS_`type'==1
							*replace	PFS_cat_`type'=3	if	year==`year'	&	PFS_FS_`type'==1
							*assert	PFS_cat_`type'!=0	if	year==`year'
							
							*	Save threshold PFS as global macros and a variable, the average of the maximum PFS among the food insecure households and the minimum of the food secure households					
							qui	summ	PFS_`type'	if	year==`year'	&	PFS_FS_`type'==1	//	Minimum PFS of FS households
							local	min_FS_PFS	=	r(min)
							qui	summ	PFS_`type'	if	year==`year'	&	PFS_FI_`type'==1	//	Maximum PFS of FI households
							local	max_FI_PFS	=	r(max)
							
							*	Save the threshold PFS
							replace	PFS_threshold_`type'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2		if	year==`year'
							*global	PFS_threshold_`type'_`year'	=	(`min_FS_PFS'	+	`max_FI_PFS')/2
							
							
						}	//	year
						
						label	var	PFS_FI_`type'	"Food Insecurity (PFS) (`type')"
						label	var	PFS_FS_`type'	"Food security (PFS) (`type')"
						*label	var	PFS_LFS_`type'	"Low food security (PFS) (`type')"
						*label	var	PFS_VLFS_`type'	"Very low food security (PFS) (`type')"
						*label	var	PFS_cat_`type'	"PFS category: FS, LFS or VLFS"
						
						

				}	//	type
				
				*lab	define	PFS_category	1	"Very low food security (VLFS)"	2	"Low food security (LFS)"	3	"Food security(FS)"
				*lab	value	PFS_cat_*	PFS_category
				
				lab	var	PFS_threshold_ppml_noCOLI			"Threshold value (PFS)"
				
			 }	//	qui
			
		save	"${SNAP_dtInt}/SNAP_long_PFS_cat", replace	
	
		
		
	
	
	
	
	*	Construct FI indicator based on PFS
	*	In LBH, we used flexible cut-off; set cut-off such that FI(PFS) prevalence rate is equal to the offical FI reported in the annual USDA report.
	*	Since this period do not have such reference, we set 0.5 as a benchmark threshold.
	
	*	(2023-12-13) To give a reasonable threshold, I compare FI prevalence b/w PFS and FSSS using different thresholds.
	use	"${SNAP_dtInt}/SNAP_long_PFS_cat", clear
	
	
			*	FI(PFS) with different cutoffs
				loc	var	PFS_FI_07
				cap	drop	`var'
				gen		`var'=0	if	!inrange(PFS_ppml_noCOLI,0,0.7)
				replace	`var'=1	if	inrange(PFS_ppml_noCOLI,0,0.7)
				
				loc	var	PFS_FI_06
				cap	drop	`var'
				gen		`var'=0	if	!inrange(PFS_ppml_noCOLI,0,0.6)
				replace	`var'=1	if	inrange(PFS_ppml_noCOLI,0,0.6)
				
				loc	var	PFS_FI_05
				cap	drop	`var'
				gen		`var'=0	if	!inrange(PFS_ppml_noCOLI,0,0.5)
				replace	`var'=1	if	inrange(PFS_ppml_noCOLI,0,0.5)
				
				loc	var	PFS_FI_04
				cap	drop	`var'
				gen		`var'=0	if	!inrange(PFS_ppml_noCOLI,0,0.4)
				replace	`var'=1	if	inrange(PFS_ppml_noCOLI,0,0.4)
				
				loc	var	PFS_FI_03
				cap	drop	`var'
				gen		`var'=0	if	!inrange(PFS_ppml_noCOLI,0,0.3)
				replace	`var'=1	if	inrange(PFS_ppml_noCOLI,0,0.3)
				
				
				summ	PFS_FI_07	PFS_FI_06	PFS_FI_05	PFS_FI_04	PFS_FI_03	FSSS_FI	[aw=wgt_long_ind] if year==1999
				summ	PFS_FI_07	PFS_FI_06	PFS_FI_05	PFS_FI_04	PFS_FI_03	FSSS_FI	[aw=wgt_long_ind] if year==2001
				summ	PFS_FI_07	PFS_FI_06	PFS_FI_05	PFS_FI_04	PFS_FI_03	FSSS_FI	[aw=wgt_long_ind] if year==2003
				summ	PFS_FI_07	PFS_FI_06	PFS_FI_05	PFS_FI_04	PFS_FI_03	FSSS_FI	[aw=wgt_long_ind] if year==2015
				summ	PFS_FI_07	PFS_FI_06	PFS_FI_05	PFS_FI_04	PFS_FI_03	FSSS_FI	[aw=wgt_long_ind] if year==2017
				summ	PFS_FI_07	PFS_FI_06	PFS_FI_05	PFS_FI_04	PFS_FI_03	FSSS_FI	[aw=wgt_long_ind] if year==2019
				
			
			*	Time trend of food insecurity (by PFS) over years, over different cutoffs	
			*	We see that the best cut-off point is 0.4 for earlier period (1999-2003) and 0.6 for later period (2015-2019)
			*	So we use the average (0.5) as the single cut-off point.
			preserve		
				
				collapse	(mean) PFS_ppml	PFS_FI_07	PFS_FI_06	PFS_FI_05	PFS_FI_04	PFS_FI_03	FI_pct	FSSS_FI HFSM_FI	[aw=wgt_long_ind], by(year)	//	weighted average by year
			
				
				*	FI prevalence rate by different cut-offs.
				twoway	(line PFS_FI_07	year if inrange(year,1999,2019), lc(green) lp(solid) lwidth(medium)  graphregion(fcolor(white)) legend(label(1 "(PFS < 0.7)")))	///
						(line PFS_FI_06	year if inrange(year,1999,2019), lc(blue) lp(dash) lwidth(medium)graphregion(fcolor(white)) legend(label(2 "(PFS < 0.6)"))) 	///
						(line PFS_FI_05	year if inrange(year,1999,2019), lc(red) lp(dot) lwidth(medium)	 graphregion(fcolor(white)) legend(label(3 "(PFS < 0.5)")))	///
						(line PFS_FI_04	year if inrange(year,1999,2019), lc(green) lp(dash_dot) lwidth(medium)	 graphregion(fcolor(white)) legend(label(4 "(PFS < 0.4)")))	///
						(line PFS_FI_03	year if inrange(year,1999,2019), lc(gray) lp(shortdash) lwidth(medium)	 graphregion(fcolor(white)) legend(label(5 "(PFS < 0.3)")))	///
						(line FI_pct	year if inrange(year,1999,2019), lc(black) lp(longdash) lwidth(medium)	 graphregion(fcolor(white)) legend(label(6 "USDA official")))	///
						(connected FSSS_FI	year if inlist(year,1999,2001,2003), lc(red) lp(shortdash) lwidth(medium)	msymbol(circle)	graphregion(fcolor(white)) legend(label(7 "FSSS")))	///
						(connected FSSS_FI	year if inlist(year,2015,2017,2019), lc(red) lp(shortdash) lwidth(medium)	msymbol(circle) graphregion(fcolor(white)) legend(label(8 "FSSS") row(2) size(small) keygap(0.1) symxsize(5))),	///
						title("Food Insecurity Prevalence Rates") ytitle("Fraction") xtitle("Year") name(FI_prevalence_cutoffs, replace)
				graph	export	"${SNAP_outRaw}/PFS_FI_rate_cutoffs_9919.png", as(png) replace
				graph	close	
			restore
			
		
		
		*	(2024-6-27) Classifying FS/FI using PFS
		
			*	For post-1995, we have annual USDA FI prevalnce rate, which we can use it as a reference.
			*	For pre-1995, we do not have annual USDA FI prevalence to refer.
			*	Thus, methods could differ b/w pre-1995 and post-1995
			
			*	For post-1995, there are two ways to do it based on official prevalence rate.
				*	(1) Categorize the equal share of households as FI based on PFS (like Lee et al. 2023)
					*	For example, if 10% is food insecure by CPS in a given year, categorize bottom 10th percentile of PFS as FI.
				*	(2) For a subsample where PSID collected FSSS, we can re-classify FSSS-based FI using the Rasch score.
					*	For example, if 10% is food insecure by CPS in a given year, classify the 10% highest Rasch scores as food insecure.
					*	This method can be used to further investigate mismatch b/w PSID and CPS, it cannot be used for the years when PSID didn't collect RFSSS.
					*	This method "re-classifies" FSSS_FI.
			*	For pre-1995, there are two ways to to do it.
				*	(1) Use a fixed PFS probability as a cut-off (like, 0.5)
				*	(2) Use a predicted cut-off from the model using post-1995 data
					*	Model estimating the association of PFS cut-off with macroeconomic indicators.
			
			*	1st method of post-1995 is done above.
			
		*	2nd method of post-1995
			
			*	Distribution of Rasch scores (FSSS) measured by PSID
			loc	var	FSSS_FI_cps_base
			cap	drop	`var'
			gen	`var'=.
			lab	var	`var'	"Food insecure (FSSS - matched to official prevalence)"
			
				*	1999: 10.1% are FI
				loc	year=1999
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 10% of households have the score 2 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,1)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,2,18)	&	year==`year'
				
				*	2001:	10.7% are FI
				loc	year=2001
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 12% of households have the score 1 or higher, 8% have 2 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,0)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,1,18)	&	year==`year'
				
				*	2003:	11.2% are FI
				loc	year=2003
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 13% of households have the score 1 or higher, 9% have 2 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,0)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,1,18)	&	year==`year'
				
				*	2015:	12.7% are FI
				loc	year=2015
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 14.6% of households have the score 2 or higher, 11% have 3 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,2)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,3,18)	&	year==`year'
				
				*	2017:	11.8% are FI
				loc	year=2017
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 12.9% of households have the score 2 or higher, 9.6% have 3 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,1)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,2,18)	&	year==`year'
				
				*	2019:	10.5% are FI
				loc	year=2019
				tab	HFSM_raw	[aw=wgt_long_ind] if year==`year'	//	About 11.3% of households have the score 2 or higher, 9% have 3 or higher
				replace	`var'=0	if	inrange(HFSM_raw,0,1)	&	year==`year'
				replace	`var'=1	if	inrange(HFSM_raw,2,18)	&	year==`year'
				
			*	FS indicator - opposite of FI indicator
			cap	drop	FSSS_FS_cps_base
			recode		FSSS_FI_cps_base	(0=1)	(1=0), gen(FSSS_FS_cps_base)
			lab	var		FSSS_FS_cps_base	"Food secure (FSSS - matched to official prevalence)"
	
		
		
		******	(2024-06-27) CLASSIFY FI FOR PRE-1995 PERIODS (method 1: using fixed point 0.5)
		******	IMPORTANT: PREVIOUSLY, I RE-CLASSIFED ALL HOUSEHOLDS, INCLUDING POST-1995! I THINK IT IS AN ERROR, OR AN OLD METHOD OF SNAP PAPER.
		******	MUST RE-DO THE ANALYSIS.
		loc	var	PFS_FI_ppml_noCOLI
		*cap	drop	`var'
		*gen		`var'=.
		replace	`var'=0	if	!mi(PFS_ppml_noCOLI)	&	inrange(year,1979,1994)	&	!inrange(PFS_ppml_noCOLI,0,0.5)
		replace	`var'=1	if	!mi(PFS_ppml_noCOLI)	&	inrange(year,1979,1994)	&	inrange(PFS_ppml_noCOLI,0,0.5)
		*lab	var	`var'	"Food insecure (PFS < 0.5)"
		
		
		*	CLASSIFY FS  FOR PRE-1995 PERIODS
		loc	var		PFS_FS_ppml_noCOLI
		recode		`var'	(1=0)	(0=1)	if	!mi(PFS_ppml_noCOLI)	&	inrange(year,1979,1994)
		
			
	
		/*
		foreach	var	in	ppml_noCOLI	{
			
			*cap	drop	PFS_FS_`var'
			*clonevar	PFS_FS_`var'	=	PFS_FI_`var'
			recode		PFS_FS_`var'	(1=0)	(0=1)
			
		}
		
		*lab	var	PFS_FS_ppml			"HH is food secure (PFS)"
		lab	var	PFS_FS_ppml_noCOLI	"HH is food secure (PFS w/o COLI)"
		*/
		
		
		
		
		
		
				
		*	Generate lagged PFS variable
		sort	x11101ll	year
		foreach	var	in		PFS_FI_ppml_noCOLI	PFS_FS_ppml_noCOLI	{
			
			cap	drop	l2_`var'
			local	label:	variable	label	`var'
			di	"`label'"
			gen	l2_`var'	=	l2.`var'
			lab	var	l2_`var'	"Lagged `label'"
			
		}

	
		*	Keep relevant study sample only
	keep	if	!mi(PFS_ppml_noCOLI)
	
	*	Construct spell length
		**	IMPORANT NOTE: Since the PFS data has (1) gap period b/w 1988-1991 and (2) changed frequency since 1997, it is not clear how to define "spell"
		**	Based on 2023-7-25 discussion, we decide to define spell as "the number of consecutive 'OBSERVATIONS' experiencing food insecurity", regardless of gap period and updated frequency
			**	We can do robustness check with the updated spell (i) splitting pre-gap period and post-gap period, and (ii) Multiplying spell by 2 for post-1997		
		cap drop	_seq	_spell	_end
		tsspell, cond(year>=1979 & PFS_FI_ppml_noCOLI==1)

	*	Create additional indicators
	
		
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
		estpost tabstat	${indvars}	[aw=wgt_long_ind]	if	!mi(num_waves_in_FU_uniq),	statistics(count	mean	sd	min		/*median	p95*/	max) columns(statistics)		// save
		est	store	sumstat_ind
		*estpost tabstat	${indvars}	[aw=wgt_long_ind]	if	!mi(num_waves_in_FU_uniq) & income_below_200==1,	statistics(count	mean	sd	min	median	p95	max) columns(statistics)		// save
		*est	store	sumstat_ind_incbelow200
		
		*	Ind-year vars (observation level)
		estpost tabstat	${summvars_obs}	[aw=wgt_long_ind],	statistics(count	mean	sd	min	median	/*p95*/	max) columns(statistics)		// save
		est	store	sumstat_indyear

		
		esttab	sumstat_ind	sumstat_indyear	using	"${SNAP_outRaw}/Sumstats_desc_7919.csv",  ///
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
		
		
		
		
		
		
		*	Figure 1: Scatter plot of survey waves and SNAP frequency
		
			*	First, collapse data to individual-level (should be unweighted)
			preserve
				collapse	(count)	num_waves_in_sample=PFS_FI_ppml_noCOLI	///	//	# of waves in sample
							(sum)	total_SNAP_used=FS_rec_wth	///	# of SNAP redemption
							(mean)	wgt_long_ind_avg=wgt_long_ind ///	//	weighted family wgt
								if !mi(PFS_FI_ppml_noCOLI), by(x11101ll)
				lab	var	num_waves_in_sample	"# of waves in sample"
				lab	var	total_SNAP_used		"# of SNAP participation in sample"
				lab	var	wgt_long_ind_avg	"Avg longitudinal individual wgt"
				
				tempfile	col1
				save	`col1', replace
				
			*	Second, collapse data into (# of waves x # of SNAP) level. This can be weighted or unweighted (NOT sure which one is correct)
				
				*	weighted
				collapse	(count) wgt_long_ind_avg [pw=wgt_long_ind_avg], by(num_waves_in_sample total_SNAP_used)
				
				*twoway	contour	wgt_long_ind_avg	total_SNAP_used	num_waves_in_sample // contour plot - looks very odd
				
				twoway	(scatter total_SNAP_used num_waves_in_sample [pw=wgt_long_ind_avg], msymbol(circle_hollow)),	///
					title(Joint distribution of survey waves and SNAP participation)	///
					note(Weighted by longitudinal individual survey weight.)
				graph	export	"${SNAP_outRaw}/joint_waves_SNAP_w.png", replace	
				graph	close
				
				/*	disable other version not used.
				twoway	(scatter total_SNAP_used num_waves_in_sample [pw=wgt_long_ind_avg] if total_SNAP_used>=1, msymbol(circle_hollow)),	///
					title(Joint distribution of survey waves and SNAP participation)	///
					note(Weighted by longitudinal individual survey weight. Zero SNAP participation excluded.)
				graph	export	"${SNAP_outRaw}/joint_waves_SNAP_w_nozero.png", replace	
				graph	close
				
				*	Unweighted
				use	`col1', clear
				
				collapse	(count) wgt_long_ind_avg /*[pw=wgt_long_ind_avg]*/, by(num_waves_in_sample total_SNAP_used)
				
				*twoway	contour	wgt_long_ind_avg	total_SNAP_used	num_waves_in_sample // contour plot - still looks very odd
				twoway	(scatter total_SNAP_used num_waves_in_sample [pw=wgt_long_ind_avg], msymbol(circle_hollow)),	///
					title(Joint distribution of survey waves and SNAP participation)	///
					note(Unweighted.)
				graph	export	"${SNAP_outRaw}/joint_waves_SNAP_uw.png", replace	
				graph	close
				
				twoway	(scatter total_SNAP_used num_waves_in_sample [pw=wgt_long_ind_avg] if total_SNAP_used>=1, msymbol(circle_hollow)),	///
					title(Joint distribution of survey waves and SNAP participation)	///
					note(Zero SNAP participation excluded. Unweighted)
				graph	export	"${SNAP_outRaw}/joint_waves_SNAP_uw_nozero.png", replace	
				graph	close
				*/
			restore
			
	
	
		
	
	
	
	
	
	*	Annual trend
	
	use	"${SNAP_dtInt}/SNAP_long_PFS_cat", clear

				
		*	Variablest to be collapsed
		local	collapse_vars	foodexp_tot_exclFS_pc	foodexp_tot_inclFS_pc	foodexp_tot_exclFS_pc_real	foodexp_tot_inclFS_pc_real	foodexp_W_TFP_pc foodexp_W_TFP_pc_real	///	//	Food expenditure and TFP cost per capita (nominal and real)
								rp_age	rp_age_below30 rp_age_over65	rp_female	rp_nonWhte	rp_HS	rp_somecol	rp_col	rp_disabled	famnum	FS_rec_wth	FS_rec_amt_capita	FS_rec_amt_capita_real	part_num	///	//	Gender, race, education, FS participation rate, FS amount
								PFS_ppml_noCOLI	NME	PFS_FI_ppml_noCOLI	NME_below_1	FSSS_FI	FSSS_FI_v2	PFS_threshold_ppml_noCOLI	//	Outcome variables	
		
		*	All population
			collapse (mean) `collapse_vars' (median)	rp_age_med=rp_age	[pw=wgt_long_ind], by(year)
			
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
		
		*	Import other macroeconomic indicators
		
		*	Import other macroeconomic indicators
		merge	m:1	year	using	"${SNAP_dtInt}/GDP_growth_1961_2023", nogen assert(2 3) keep(3)	//	GDP growth
		merge	m:1	year	using	"${SNAP_dtInt}/dis_per_inc_pc", nogen assert(2 3) keep(3)	//	Disposable income
		merge	m:1	year	using	"${SNAP_dtInt}/Gini_index", nogen assert(2 3) keep(3)	//	Gini index
		merge	m:1	year	using	"${SNAP_dtInt}/social_spending", nogen keep(1 3) //	Social spending
		
	
	
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
			
			
		*	Model of PFS cutoff on macroeconomic indicators
		use	"${SNAP_dtInt}/SNAP_1979_2019_census_annual", clear
			
			
			lab	var	PFS_threshold_ppml_noCOLI	"Cut-off PFS"
			local	macrovars	PFS_threshold_ppml_noCOLI Gini_index ln_dis_per_inc_pc GDP_growth_real GDP_pc_growth unemp_rate pov_rate_national pct_col_Census pct_rp_nonWhite_Census	social_spending
			
			*	Recale variables, from 0-1 to 0-100
			foreach	var	in	pov_rate_national pct_col_Census pct_rp_nonWhite_Census	pct_rp_White_Census	{
				
				replace	`var'	=	`var'	*	100
				
			}
			
			*	Summary stats
			estpost tabstat	`macrovars',	statistics(count	mean	sd	min	  max	/*sd	min	 median	p95 max*/	) columns(statistics) 	// save
			est	store	summstats_annual

		
			esttab	summstats_annual	using	"${SNAP_outRaw}/summstats_annual.csv",  ///
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics - Annual (1979-2019)") noobs 	  replace
		

			*dtable	`macrovars'	, continuous(	`macrovars'	, stat(count mean sd min max)) nformat(%7.2f mean sd min max) title(Summary stats) export(summstat.html, replace)
			
			*	Correlation
			asdoc pwcorr	`macrovars'	if	!mi(PFS_threshold_ppml_noCOLI), label star(all) replace
			
			*	Regression
			
				*	Correlation matrix above show that some variables are highly correlated with one another (i.e. Gini index and disposable income)
				*	Thus, I use only one of those variables to avoid multicolinearity and overfitting.
				*	I use the following four variables
					*	ln(disposable personal income per capita)
					*	share of RP that are non-White
					*	GDP per capita growth rate
					*	Poverty rate
					
				*	Bivariate regression of 4 variables above
				cap	drop	PFS_cutoff_income_hat
				cap	drop	PFS_cutoff_income_e
				cap	drop	PFS_cutoff_income_e2
				
				reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	ln(disposable income per capita)
				predict	PFS_cutoff_income_hat
				predict	PFS_cutoff_income_e, resid
				gen		PFS_cutoff_income_e2	=	(PFS_cutoff_income_e)^2
				est	store	PFS_cutoff_income
				
				cap	drop	PFS_cutoff_nonWhite_hat
				cap	drop	PFS_cutoff_nonWhite_e
				cap	drop	PFS_cutoff_nonWhite_e2
				
				reg	PFS_threshold_ppml_noCOLI pct_rp_nonWhite_Census	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	% of non-White RP
				predict	PFS_cutoff_nonWhite_hat
				predict	PFS_cutoff_nonWhite_e, resid
				gen		PFS_cutoff_nonWhite_e2	=	(PFS_cutoff_nonWhite_e)^2
				est	store	PFS_cutoff_nonWhite
				
				reg	PFS_threshold_ppml_noCOLI GDP_pc_growth	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	GDP per capita growth rate
				est	store	PFS_cutoff_GDPgrowth
				
				cap	drop	PFS_cutoff_pov_hat
				cap	drop	PFS_cutoff_pov_e
				cap	drop	PFS_cutoff_pov_e2
				
				reg	PFS_threshold_ppml_noCOLI pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	Poverty rate
				predict	PFS_cutoff_pov_hat
				predict	PFS_cutoff_pov_e, resid
				gen		PFS_cutoff_pov_e2	=	(PFS_cutoff_pov_e)^2
				est	store	PFS_cutoff_povrate
				
				*	Multivariate regressions
				reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	if	!mi(PFS_threshold_ppml_noCOLI), robust	//	income and non-White population
				est	store	PFS_cutoff_inc_nonWhite
				
				*	Full regression (This is the model I use to construct pre-1995 threshold, after discussing with Chris)
				cap	drop	PFS_cutoff_full_hat
				cap	drop	PFS_cutoff_full_e
				cap	drop	PFS_cutoff_full_e2
				
				reg	PFS_threshold_ppml_noCOLI ln_dis_per_inc_pc	pct_rp_nonWhite_Census	GDP_pc_growth		pov_rate_national	if	!mi(PFS_threshold_ppml_noCOLI), robust
				predict	PFS_cutoff_full_hat
				predict	PFS_cutoff_full_e, resid
				gen		PFS_cutoff_full_e2	=	(PFS_cutoff_full_e)^2
				est	store	PFS_cutoff_full
				
				
				
				esttab	PFS_cutoff_income	PFS_cutoff_nonWhite	PFS_cutoff_GDPgrowth		PFS_cutoff_povrate	PFS_cutoff_inc_nonWhite	PFS_cutoff_full	using "${SNAP_outRaw}/PFS_cutoff_on_X.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 r2_a, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(PFS cutoff on economic indicators)		replace	
					
				
				
				*	Comparing the first and the second model (second model is slightly better)
				summ PFS_threshold_ppml_noCOLI PFS_cutoff_income_hat PFS_cutoff_nonWhite_hat	PFS_cutoff_income_e2	PFS_cutoff_nonWhite_e2
				
				
				*	Graph actual PFS cut-off(1995-2019) and predicted PFS cut-off
				graph	twoway	///
					(line PFS_threshold_ppml_noCOLI year, lpattern(dash) xaxis(1 2) yaxis(1) legend(label(1 "Realized")))	///
					(line PFS_cutoff_income_hat		year, lpattern(dot) xaxis(1 2) yaxis(1) legend(label(2 "Predicted (disposable income)")))	///
					(line PFS_cutoff_nonWhite_hat	year, lpattern(shortdash)	lc(gray)  lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Predicted (non-White)")))	///
					(line PFS_cutoff_pov_hat		year, lpattern(longdash)	lc(gray)  lwidth(medium) graphregion(fcolor(white)) legend(label(4 "Predicted (poverty rate)")))	///
					(line PFS_cutoff_full_hat		year, lpattern(dash_dot) xaxis(1 2) yaxis(1)  legend(label(5 "Predicted  (full)") row(2) size(small) keygap(0.1) pos(6) symxsize(5))),	///
								/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/ xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
								xtitle(Year)	ytitle("Probability")	///
								title(PFS cut-off)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(PFS_cutoff, replace)
							
			
				graph	export	"${SNAP_outRaw}/PFS_cutoff.png", replace	
				graph	close	
				
			
			*	
			
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
			graph	box	PFS_ppml_noCOLI		[aw=wgt_long_ind], over(rp_female) over(rp_nonWhte)	over(rp_edu_cat) nooutsides name(outcome_subgroup_rp, replace) title(Food Security by Subgroup) note("")
			graph	export	"${SNAP_outRaw}/PFS_by_rp_subgroup.png", replace	
			graph	close
			
			*	PFS by individual's gender and race and education
				
				*	Cleaning for label
				lab	define	ind_nonWhite	0	"White"	1	"Non-White", replace
				lab	val	ind_nonWhite	ind_nonWhite
				
				*	Temporarily replace "inapp(education)" as missing
				recode	ind_edu_cat	(0=.)	
				
			graph	box	PFS_ppml_noCOLI		[aw=wgt_long_ind], over(ind_female, sort(1)) over(ind_nonWhite, sort(1))	over(ind_edu_cat, sort(1)) nooutsides name(outcome_subgroup_ind, replace) title(Food Security by Subgroup) note("")
			
			graph display outcome_subgroup_ind, ysize(4) xsize(9.0)
			graph	export	"${SNAP_outRaw}/PFS_by_ind_subgroup.png", replace	
			graph	close
			
			*	PFS by individual's gender, race and education
			
			*	Temporarily contruct individual race variable
			
			
			*	PFS and NME
			/*
			{	
				*	By gender and race
				graph	box	PFS_ppml_noCOLI	NME	[aw=wgt_long_ind], over(rp_female) over(rp_nonWhte) nooutsides name(outcome_gen_race, replace) title(Food Security by Gender and Race)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_gen_race.png", replace	
				graph	close
				
				*	By educational attainment
				graph	box	PFS_ppml_noCOLI	NME	[aw=wgt_long_ind], over(rp_edu_cat) nooutsides name(outcome_edu, replace) title(Food Security by Education)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_edu.png", replace
				graph	close
				
				*	By region
				graph	box	PFS_ppml_noCOLI	NME	[aw=wgt_long_ind], over(rp_region) nooutsides name(outcome_region, replace) title(Food Security by Region)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_region.png", replace
				graph	close
				
				*	By disability
				graph	box	PFS_ppml_noCOLI	NME	[aw=wgt_long_ind], over(rp_disabled) nooutsides name(outcome_region, replace) title(Food Security by Disability)
				graph	export	"${SNAP_outRaw}/PFS_NME_by_disab.png", replace
				graph	close
			
			*	Dummies (PFS<0.5 and NME<1)
				
				*	By Gender and Race
				graph bar PFS_FI_ppml NME_below_1	[aw=wgt_long_ind], over(rp_female) over(rp_nonWhte) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Gender and Race)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_gen_race.png", replace	
				graph	close
					
				*	By Educational attainment
				graph bar PFS_FI_ppml NME_below_1	[aw=wgt_long_ind], over(rp_edu_cat) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Education)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_edu.png", replace
				graph	close
					
				*	By Region
				graph bar PFS_FI_ppml NME_below_1	[aw=wgt_long_ind], over(rp_region) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Region)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_region.png", replace
				graph	close
				
				*	By disability
				graph bar PFS_FI_ppml NME_below_1	[aw=wgt_long_ind], over(rp_disabled) blabel(total, format(%12.2f))	///
					legend(lab (1 "PFS < 0.5") lab(2 "NME < 1") rows(1))	title(Food Insecurity Status by Disability)
				graph	export	"${SNAP_outRaw}/PFS_NME_dummies_by_disab.png", replace
				graph	close	
		
			
			*	SNAP redemption
				
				*	By Gender and Race
				graph bar FS_rec_wth	[aw=wgt_long_ind], over(rp_female) over(rp_nonWhte) blabel(total, format(%12.2f))	///
						legend(lab (1 "Participated in FS") rows(1))	title(Food Stamp Participation by Gender and Race)
				graph	export	"${SNAP_outRaw}/FS_by_gen_race.png", replace	
				graph	close
				
				*	By Educational attainment
				graph bar FS_rec_wth	[aw=wgt_long_ind], over(rp_edu_cat) blabel(total, format(%12.2f))	///
						legend(lab (1 "Participated in FS") rows(1))	title(Food Stamp Participation by Education)
				graph	export	"${SNAP_outRaw}/FS_by_edu.png", replace	
				graph	close
				
				*	Region
				graph bar FS_rec_wth	[aw=wgt_long_ind], over(rp_region) blabel(total, format(%12.2f))	///
						legend(lab (1 "Participated in FS") rows(1))	title(Food Stamp Participation by Region)
				graph	export	"${SNAP_outRaw}/FS_by_region.png", replace	
				graph	close
				
				*	Disability
				graph bar FS_rec_wth	[aw=wgt_long_ind], over(rp_disabled) blabel(total, format(%12.2f))	///
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
			}
			*/	

			
			
			
			*	Distribution of PFS over time, by category
			*	"lgraph" ssc ins required	 
				*	Overall 
				
				*	These two lone show that they generate the same mean estimates.
				summ	PFS_ppml_noCOLI	[aw=wgt_long_ind] if year==1997
				svy, subpop(if year==1997): mean PFS_ppml_noCOLI
				
				lgraph PFS_ppml_noCOLI year [aw=wgt_long_ind], errortype(iqr) separate(0.01) title(PFS) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual.png", replace
				graph	close
				
				/*
				{	
				*	By gender
				lab	define	rp_female	0	"Male"	1	"Female", replace
				lab	val	rp_female	rp_female
				lgraph PFS_ppml_noCOLI year rp_female	[aw=wgt_long_ind], errortype(iqr) separate(0.01)  title(PFS by Gender) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual_gender.png", replace
				graph	close
			
				*	By race
				lab	define	rp_nonWhte	0	"White"	1	"non-White", replace
				lab	val	rp_nonWhte	rp_nonWhte
				lgraph PFS_ppml_noCOLI year rp_nonWhte	[aw=wgt_long_ind], errortype(iqr) separate(0.01)  title(PFS by Race) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual_race.png", replace
				graph	close
			
				*	By educational attainment
				lgraph PFS_ppml_noCOLI year rp_edu_cat	[aw=wgt_long_ind], separate(0.01)  title(PFS by Education) note(25th and 75th percentile)
				graph	export	"${SNAP_outRaw}/PFS_annual_education.png", replace
				graph	close
			
			
				*	By marital status
				lab	define	rp_married	0	"Single or spouse-absent"	1	"Spouse present", replace
				lab	val	rp_married	rp_married
				lgraph PFS_ppml_noCOLI year rp_married	[aw=wgt_long_ind], errortype(iqr)	separate(0.01)  title(PFS by marital status) note(25th and 75th percentile)
			
				graph	export	"${SNAP_outRaw}/PFS_annual_marital.png", replace
				graph	close
				
				}
				*/	
			
			
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
				/*
				{	
					
					*	Overall
					lgraph SL_5 year [aw=wgt_long_ind] if PFS_FI_ppml==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
				
					graph	export	"${SNAP_outRaw}/SL5_annual.png", replace
					graph	close
				
					*	By gender
					lab	define	rp_female	0	"Male"	1	"Female", replace
					lab	val	rp_female	rp_female
					lgraph SL_5 year rp_female [aw=wgt_long_ind] if PFS_FI_ppml==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length by gender) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
					graph	export	"${SNAP_outRaw}/SL5_annual_gender.png", replace
					graph	close
			
					
					*	By race
					lab	define	rp_nonWhte	0	"White"	1	"non-White", replace
					lab	val	rp_nonWhte	rp_nonWhte
					lgraph SL_5 year rp_nonWhte [aw=wgt_long_ind] if PFS_FI_ppml==1, separate(0.01)  ///
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
					
					lgraph SL_5 year rp_HS_less [aw=wgt_long_ind] if PFS_FI_ppml==1 & dyn_sample_5yr==1, separate(0.01)  ///
					xline(1983 1992 2007, axis(1) lcolor(black) lpattern(solid))	///
					xline(1987 1988, lwidth(23) lc(gs12)) xlabel(1980 1987 1992 2000 2007 2010)  ///
					title(Spell length by education) ytitle(average length) note(spell length longer than 3 waves are capped at 3)
					graph	export	"${SNAP_outRaw}/SL5_annual_education.png", replace
					graph	close
				}
				
					*/	
			
				
		*	Rank correlation b/w PFS and FSSS
			
			*	Rescale FSSS
			loc	var	FSSS_rescale
			cap	drop	`var'
			gen	double	`var'	=	(9.3-HFSM_scale)/9.3
			replace	`var'=0	if	HFSM_raw==18	
			
			*	Rank correlation
			spearman	PFS_ppml_noCOLI	FSSS_rescale, stats(rho obs p) star(0.05)
			ktau		PFS_ppml_noCOLI	FSSS_rescale, stats(taua taub obs p) star(0.05)
		
		
		
		
		*	(2023-12-24) Food exp and TFP cost per capita (nominal and real)
		preserve
			collapse	(mean) HFSM_FI	PFS_ppml	PFS_FI_ppml_noCOLI	foodexp_W_TFP_pc	foodexp_W_TFP_pc_real	CPI	///
								foodexp_tot_inclFS_pc	foodexp_tot_inclFS_pc_real	[aw=wgt_long_ind], by(year)	//	weighted average by year
			
			graph	twoway	(line	foodexp_tot_inclFS_pc		year	if inrange(year,1979,2019),	lc(black) lp(solid) lwidth(medium)  graphregion(fcolor(white))) ///
							(line	foodexp_tot_inclFS_pc_real	year 	if inrange(year,1979,2019),	lc(blue) lp(shortdash) lwidth(medium)  graphregion(fcolor(white))) ///
							(line	foodexp_W_TFP_pc		year	if inrange(year,1979,2019),	lc(green) lp(dot) lwidth(medium)  graphregion(fcolor(white))) ///
							(line	foodexp_W_TFP_pc_real	year	if inrange(year,1979,2019),	lc(red) lp(dash) lwidth(medium)  graphregion(fcolor(white))),	///
							legend(order(1 "Food exp (nominal)" 2 "Food exp (real)"	3 "TFP (nominal)" 4 "TFP pc (real)") size(small) keygap(0.1) symxsize(5)) ///
							title("Food Expenditure and TFP cost per capita ($)") ytitle("Amount") xtitle("Year") name(FI_pravelence_measures, replace)
							graph	export	"${SNAP_outRaw}/Foodexp_TFP_pc_trend.png", as(png) replace
		restore
			
		
		*	Compute FI trend b/w PFS and FSSS
		preserve
				
			collapse	(mean) HFSM_FI	PFS_ppml	PFS_FI_ppml_noCOLI	foodexp_W_TFP_pc_real	FI_pct	[aw=wgt_long_ind], by(year)	//	weighted average by year
		
			twoway	(line PFS_FI_ppml_noCOLI	year if inrange(year,1979,2019),	lc(blue) lp(solid) lwidth(medium)  graphregion(fcolor(white))) 	 ///
					(connected HFSM_FI	year if inlist(year,1999,2001,2003), lc(red) lp(shortdash) lwidth(medium)	msymbol(circle)	graphregion(fcolor(white)))	 ///
					(connected HFSM_FI	year if inlist(year,2015,2017,2019), lc(red) lp(shortdash) lwidth(medium)	msymbol(circle) graphregion(fcolor(white)))	///
					(line FI_pct		year if inrange(year,1979,2019),	lc(black) lp(dash) lwidth(medium)  graphregion(fcolor(white))), 	 ///
					legend(order(1 "PFS" 2 "FSSS" 4 "USDA official") row(1) size(small) keygap(0.1) symxsize(5)) title("Food Insecurity Prevalence") ytitle("Fraction") xtitle("Year") name(FI_pravelence_measures, replace)	///
					note(USDA official is person-level)

			graph	export	"${SNAP_outRaw}/PFS_FI_rate_PFS_FSSS.png", as(png) replace
			graph	close	
		restore
		
		
		
				
		*	Decompose into 4 categories.
		*replace	HFSM_FI	=	FSSS_FI_cps_base	//	(2024-6-27) toggle on when matching PSID-FSSS to CPS FI prevalence rate
			
		loc	var	PFS_FI_FSSS_FI
		cap	drop	`var'
		gen	`var'=.
		replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(HFSM_FI)
		replace	`var'=1	if	PFS_FI_ppml_noCOLI==1	&	HFSM_FI==1
		lab	var	`var'	"FI(PFS) and FI(FSSS)"
		
		loc	var	PFS_FS_FSSS_FS
		cap	drop	`var'
		gen	`var'=.
		replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(HFSM_FI)
		replace	`var'=1	if	PFS_FI_ppml_noCOLI==0	&	HFSM_FI==0
		lab	var	`var'	"FS(PFS) and FS(FSSS)"
		
		loc	var	PFS_FI_FSSS_FS
		cap	drop	`var'
		gen	`var'=.
		replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(HFSM_FI)
		replace	`var'=1	if	PFS_FI_ppml_noCOLI==1	&	HFSM_FI==0
		lab	var	`var'	"FI(PFS) and FS(FSSS)"
		
		loc	var	PFS_FS_FSSS_FI
		cap	drop	`var'
		gen	`var'=.
		replace	`var'=0	if	!mi(PFS_FI_ppml_noCOLI)	&	!mi(HFSM_FI)
		replace	`var'=1	if	PFS_FI_ppml_noCOLI==0	&	HFSM_FI==1
		lab	var	`var'	"FS(PFS) and FI(FSSS)"
		
		summ	PFS_FI_FSSS_FI	PFS_FS_FSSS_FS	PFS_FI_FSSS_FS	PFS_FS_FSSS_FI
		summ	PFS_FI_FSSS_FI	PFS_FS_FSSS_FS	PFS_FI_FSSS_FS	PFS_FS_FSSS_FI	[aweight=wgt_long_ind]
		
			
		*	Individual-vars
		estpost tabstat	PFS_FS_FSSS_FS	PFS_FI_FSSS_FI	PFS_FI_FSSS_FS	PFS_FS_FSSS_FI	[aw=wgt_long_ind],	statistics(count	mean		/*sd	min	 median	p95 max*/	) columns(statistics)  by(year)		// save
		est	store	PFS_FSSS_FI_by_year

		
		esttab	PFS_FSSS_FI_by_year	using	"${SNAP_outRaw}/PFS_FSSS_FI_by_year.csv",  ///
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
		

			*	Summary stats based on FS status
			loc	summvars	rp_female	rp_age	rp_nonWhte	rp_married	rp_disabled	rp_col		///
							famnum	ln_fam_income_pc_real	foodexp_tot_inclFS_pc_1_real	PFS_ppml_noCOLI HFSM_raw	
			
			*	Full sample
			estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	!mi(PFS_FS_FSSS_FI)	[aw=wgt_long_ind],	///
				statistics(count	mean	sd	min	max) columns(statistics)	// save
			est	store	PFS_FSSS_full
			
			*	FS(PFS)/FS(FSSS) individuals
			estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FS_FSSS_FS==1	[aw=wgt_long_ind],	///
				statistics(count	mean	sd	min	max) columns(statistics)	// save
			est	store	PFS_FS_FSSS_FS
			
			*	FS(PFS)/FI(FSSS) individuals
			estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FS_FSSS_FI==1	[aw=wgt_long_ind],	///
				statistics(count	mean	sd	min	max) columns(statistics)	// save
			est	store	PFS_FS_FSSS_FI
			
			*	FI(PFS)/FS(FSSS) individuals
			estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FI_FSSS_FS==1	[aw=wgt_long_ind],	///
				statistics(count	mean	sd	min	max) columns(statistics)	// save
			est	store	PFS_FI_FSSS_FS
			
			*	FI(PFS)/FI(FSSS) individuals
			estpost tabstat	`summvars' 	if	!mi(PFS_ppml_noCOLI)	&	PFS_FI_FSSS_FI==1	[aw=wgt_long_ind],	///
				statistics(count	mean	sd	min	max) columns(statistics)	// save
			est	store	PFS_FI_FSSS_FI
			
			
			
			esttab	PFS_FSSS_full	PFS_FS_FSSS_FS	PFS_FS_FSSS_FI	PFS_FI_FSSS_FS	PFS_FI_FSSS_FI	using	"${SNAP_outRaw}/summstat_by_status.csv",  ///
				cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics - FS(PFS) and FI(FSSS)") noobs 	  replace
		
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
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	/*${indvars}*/		[aweight=wgt_long_ind],	///
						vce(cluster x11101ll) absorb(rp_state year)	/*noabsorb*/
					est	store	PFS_ysFE_noind
					
					*	Individual vars
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	${indvars}		[aweight=wgt_long_ind],	///
						vce(cluster x11101ll) absorb(rp_state year)	/*noabsorb*/
					est	store	PFS_ysFE_ind
				
				*	State- and Year-FE, Individual FE
					
					*	OLS
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	/*${indvars}*/		[aweight=wgt_long_ind],	///
						vce(cluster x11101ll) absorb(rp_state year	x11101ll)	/*noabsorb*/
					est	store	PFS_ysiFE_noind
					
					*	Individual vars
					reghdfe	PFS_ppml_noCOLI ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	${indvars}		[aweight=wgt_long_ind],	///
						vce(cluster x11101ll) absorb(rp_state year	x11101ll)	/*noabsorb*/
					est	store	PFS_ysiFE_ind
				
					
				*	Report
				
					*	Regression coefficients
						
					*	OLS
					esttab	PFS_ysFE_noind	PFS_ysFE_ind	PFS_ysiFE_noind		PFS_ysiFE_ind	using "${SNAP_outRaw}/PFS_on_HH X.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(PFS on HH Characteristics)		replace	
					
					esttab	PFS_ysFE_noind	PFS_ysFE_ind	PFS_ysiFE_noind		PFS_ysiFE_ind	using "${SNAP_outRaw}/PFS_on_HH X.tex", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(PFS on HH Characteristics)		replace	
			
	/****************************************************************
		SECTION 4: Dynamics analyses
	****************************************************************/		 
					
		
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		svyset	sampcls [pweight=wgt_long_ind] ,strata(sampstr)   singleunit(scaled)	
		
			*	Spell length by subgroup
			cap	mat	drop	summstat_spell_length
			
				*	Note that the following two line generate the different results, wonder why...
				*	For now I will simply use wgt_long_ind without adjusting survey structure, to be consistent with earlier estiamtes.
				*svy, subpop(if _end==1): mean _seq
				*summ	_seq if _end==1
			
			
			summ	_seq if _end==1
			mat	summstat_spell_length	=	r(N), r(mean), r(sd)
			mat	list	summstat_spell_length
			
			*	The following commands are when using svy-structure adjusted estimates.
			/*
			svy, subpop(if _end==1): mean _seq
			estat sd
			mat	summstat_spell_length	=	e(N_sub), r(mean), r(sd)
			mat	list	summstat_spell_length
			*/

			
			
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
					qui	summ	_seq	if	_end==1	&	`catvar'==`val'
					mat	summstat_spell_length	=	summstat_spell_length	\		(r(N), r(mean), r(sd))
					
					
					*	For svy-structure adjusted estimates.
					/*
					qui	svy, subpop(if _end==1	&	`catvar'==`val'): mean _seq
					estat	sd
					mat	summstat_spell_length	=	summstat_spell_length	\		(e(N_sub), r(mean), r(sd))
					*/
					
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
			tab	_seq	[aw=wgt_long_ind]	if	_end==1,	matcell(spell_freq_w)
			mat	list	spell_freq_w
			local	N=r(N)
			mat	spell_pct_tot	=	spell_freq_w	/	r(N)
			
			mat	spell_pct_all		=	nullmat(spell_pct_all),	spell_pct_tot
			mat	list	spell_pct_all
		
		*	By category
		*	We use categories by - gender, race and college degree (dummy for each category)
		*	I do NOT use individual-information for two reasons; (i) individual-level race not available. (ii) individual-education not available for indivdiual 16-years or less
		
		foreach	catvar	in	rp_female rp_White rp_col	{
			
			foreach	val	in	0 1	{
				
				tab	_seq	[aw=wgt_long_ind]	if	_end==1	&	`catvar'==`val',	matcell(spell_freq_`catvar'_`val')
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
				bar(1, fcolor(gs03*0.5)) /*bar(2, fcolor(gs10*0.6))*/ graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length) ytitle(Fraction)
		
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
	*	 (2023-12-19) Changed RP-level to ind-level
		
		*	Declare macros for each categorical condition
		
		local	all_cond	inrange(year,1981,2019)	//	INclude all obs
		
		local	yr_1981_1990_cond	inrange(year,1981,1990)
		local	yr_1991_2000_cond	inrange(year,1991,2000)
		local	yr_2001_2010_cond	inrange(year,2001,2010)
		local	yr_2011_2019_cond	inrange(year,2011,2019)
		
		local	female_cond		ind_female==1	//	rp_female==1
		local	male_cond		ind_female==0	//	rp_female==0
		
		local	nonWhite_cond	ind_nonWhite==1	//	rp_White==0
		local	White_cond		ind_White==1	//	rp_White==1
		
// 		local	NE_cond			rp_region_NE==1 
// 		local	MidAt_cond		rp_region_MidAt==1
// 		local	South_cond		rp_region_South==1
// 		local	MidWest_cond	rp_region_MidWest==1
// 		local	West_cond		rp_region_West==1
		
		local	NoHS_cond		ind_NoHS	//	rp_NoHS==1 
		local	HS_cond			ind_HS	//	rp_HS==1
		local	somecol_cond	ind_somecol	//	rp_somecol==1 
		local	col_cond		ind_col	//	rp_col==1
		   
// 		local	disab_cond		rp_disabled==1
// 		local	nodisab_cond	rp_disabled==0
//		
// 		local	SNAP_cond		FS_rec_wth==1
// 		local	noSNAP_cond		FS_rec_wth==0
		
		lab	var	FS_rec_wth	"Received SNAP"
		
		
		loc	categories	all	yr_1981_1990	yr_1991_2000	yr_2001_2010	yr_2011_2019	///
						female	male	nonWhite	White	/*NE	MidAt	South	MidWest	West*/	///
						NoHS	HS	somecol	col	/*disab	nodisab	SNAP	noSNAP*/
		
		*	Loop over categories
		*	NOTE: the joint tabulate command below generates the same relative frequency to the one using "svy:". I use this one for computation speed.
		cap	mat	drop	trans_2by2_combined
		cap	mat	drop	trans_2by2_entry_byyr
		cap	mat	drop	trans_2by2_persistence_byyr
		cap	mat	drop	trans_2by2_chronic_byyr
		
		mat	define	blankrow	=	J(1,7,.)
		mat	rownames	blankrow	=	""
		
		mat	define	blankrow_4col	=	J(1,4,.)
		mat	rownames	blankrow_4col	=	""
		
		foreach	cat	of	local	categories	{
			
		
			*	Joint
			tab		l2_PFS_FS_ppml_noCOLI	PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]		if	``cat'_cond'	& inrange(year,1981,2019), cell matcell(trans_2by2_joint_`cat')
			scalar	samplesize_`cat'	=	trans_2by2_joint_`cat'[1,1] + trans_2by2_joint_`cat'[1,2] + trans_2by2_joint_`cat'[2,1] + trans_2by2_joint_`cat'[2,2]	//	calculate sample size by adding up all
			mat trans_2by2_joint_`cat' = trans_2by2_joint_`cat'[1,1], trans_2by2_joint_`cat'[1,2], trans_2by2_joint_`cat'[2,1], trans_2by2_joint_`cat'[2,2]	//	Make it as a row matrix
			mat trans_2by2_joint_`cat' = trans_2by2_joint_`cat'/samplesize_`cat'	//	Divide it by sample size to compute relative frequency
			mat	list	trans_2by2_joint_`cat'	
			
			*	Marginal
			tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]			if	l2_PFS_FS_ppml_noCOLI==0	& inrange(year,1981,2019)	&	``cat'_cond', matcell(temp)	//	Previously FI
			scalar	persistence_`cat'	=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Persistence rate (FI, FI)
			tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]			if	l2_PFS_FS_ppml_noCOLI==1	& inrange(year,1981,2019)	&	``cat'_cond', matcell(temp)	//	Previously FS
			scalar	entry_`cat'			=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Entry rate (FS, FI)
			
				
			*	Combined (Joint + marginal)
			mat	trans_2by2_`cat'	=	samplesize_`cat',	trans_2by2_joint_`cat',	persistence_`cat',	entry_`cat'	
			mat	rownames	trans_2by2_`cat'	=	"`cat'"
			
			*	Acuumulate rows
			if	inlist("`cat'","yr_1981_1990","female","nonWhite","NE","NoHS","disab","SNAP")	{
				
				mat		trans_2by2_combined	=	nullmat(trans_2by2_combined) \ 	blankrow	\	trans_2by2_`cat'	//	Add a blank row at the beginning of subcategory.
				
			}
			else	{
				
				mat		trans_2by2_combined	=	nullmat(trans_2by2_combined) \ trans_2by2_`cat'	//	Add a blank row at the end of subcategory.
				
			}
			
							
			di	"This line is executed, and cat is `cat'"
			
			*	For gender/race/education, repeat for each time-period (1981-1990, 1991-2000, 2001-2010, 2011-2020)
			if	inlist("`cat'","female","male","nonWhite","White","NoHS","HS","somecol","col")	{
				
				di	"Dat line is executed, and cat is `cat'"
				forval	startyear=1981(10)2011	{
					
					local	endyear=`startyear'+9
					di		"startyear is `startyear'"
					di		"endyear is `endyear'"
					
					*	Joint
					tab		l2_PFS_FS_ppml_noCOLI	PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]		if	``cat'_cond'	& inrange(year,`startyear',`endyear'), cell matcell(trans_2by2_joint_`cat')
					scalar	samplesize_`cat'_`startyear'	=	trans_2by2_joint_`cat'[1,1] + trans_2by2_joint_`cat'[1,2] + trans_2by2_joint_`cat'[2,1] + trans_2by2_joint_`cat'[2,2]	//	calculate sample size by adding up all
					mat trans_2by2_joint_`cat'_`startyear' = trans_2by2_joint_`cat'[1,1], trans_2by2_joint_`cat'[1,2], trans_2by2_joint_`cat'[2,1], trans_2by2_joint_`cat'[2,2]	//	Make it as a row matrix
					mat trans_2by2_joint_`cat'_`startyear' = trans_2by2_joint_`cat'/samplesize_`cat'_`startyear'	//	Divide it by sample size to compute relative frequency
					mat	list	trans_2by2_joint_`cat'_`startyear'
					scalar	chronic_`cat'_`startyear'	=	trans_2by2_joint_`cat'_`startyear'[1,1]	//	FI in two consecutive waves
					scalar	list	chronic_`cat'_`startyear'
					
					*	Marginal
					tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]			if	l2_PFS_FS_ppml_noCOLI==0	& inrange(year,`startyear',`endyear')	&	``cat'_cond', matcell(temp)	//	Previously FI
					scalar	persistence_`cat'_`startyear'	=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Persistence rate (FI, FI)
					tab		PFS_FS_ppml_noCOLI	[aw=wgt_long_ind]			if	l2_PFS_FS_ppml_noCOLI==1	& inrange(year,`startyear',`endyear')	&	``cat'_cond', matcell(temp)	//	Previously FS
					scalar	entry_`cat'_`startyear'		=  temp[1,1] / (temp[1,1] + temp[2,1])	//	Entry rate (FS, FI)
						
						
				}	//	startyear
				
				*	Add up persistence and entry rate year
				foreach	type	in	chronic persistence	entry	{
					
					cap	mat	drop	`type'_`cat'_byyear
					mat	`type'_`cat'_byyear	=	`type'_`cat'_1981, `type'_`cat'_1991, `type'_`cat'_2001, `type'_`cat'_2011
					mat	rownames	`type'_`cat'_byyear	=	"`cat'"
					
				}	//	type
				
				
				*	Acuumulate rows
				if	inlist("`cat'","female","nonWhite","NoHS")	{
					
					foreach	type	in	chronic persistence	entry	{
					
						mat		trans_2by2_`type'_byyr	=	nullmat(trans_2by2_`type'_byyr) \ 	blankrow_4col	\	`type'_`cat'_byyear	//	Add a blank row at the beginning of subcategory.
						
					}	//	type
					
				}
				else	{
					
					foreach	type	in	chronic persistence	entry	{
					
						mat		trans_2by2_`type'_byyr	=	nullmat(trans_2by2_`type'_byyr) \ 	`type'_`cat'_byyear	//	
						
					}	//	type
				}
			
			
				
			}	//	if inlist
			
			
		
			
			
		}
		
		mat	colnames	trans_2by2_combined			=	"N"	"Insecure in both rounds" "Insecure in 1st round only" "Insecure in 2nd round only" "Secure in both rounds" "Persistence" "Entry"
		mat	list	trans_2by2_combined
		mat	colnames	trans_2by2_persistence_byyr	=	"1981-1990" "1991-2000" "2001-2010" "2011-2020"
		mat	colnames	trans_2by2_entry_byyr	=	"1981-1990" "1991-2000" "2001-2010" "2011-2020"
		mat	colnames	trans_2by2_chronic_byyr	=	"1981-1990" "1991-2000" "2001-2010" "2011-2020"
		
		mat	list	trans_2by2_persistence_byyr
		mat	list	trans_2by2_entry_byyr
		mat	list	trans_2by2_chronic_byyr
		
		*	Export
		putexcel	set "${SNAP_outRaw}/Trans_matrix_7919_ind", sheet(Fig_3) replace /*modify*/
		putexcel	A5	=	matrix(trans_2by2_combined), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A40	=	matrix(trans_2by2_persistence_byyr), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A55	=	matrix(trans_2by2_entry_byyr), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A70	=	matrix(trans_2by2_chronic_byyr), names overwritefmt nformat(number_d2)	//	3a
		
		/*	Equivalent, but takes longer time to run. I just leave it as a reference
		svy, subpop(if rp_female==0):	tab	l2_PFS_FS_ppml_noCOLI	PFS_FS_ppml
		mat	trans_2by2_joint_male = e(b)[1,1], e(b)[1,2], e(b)[1,3], e(b)[1,4]	
		*/
		
		
		*	Conpare dynamics - PFS and FSSS
		sort	x11101ll	year
		cap	drop	HFSM_FS
		cap	drop	l2_HFSM_FI
		cap	drop	l2_HFSM_FS
		gen	HFSM_FS	=	HFSM_FI
		recode	HFSM_FS	(1=0)	(0=1)
		gen	l2_HFSM_FI	=	l2.HFSM_FI
		gen	l2_HFSM_FS	=	l2.HFSM_FS
	

		loc	PFS_FS_ppml_noCOLI_name	PFS
		loc	HFSM_FS_name	FSSS
		
		    
		foreach	var	in	PFS_FS_ppml_noCOLI	HFSM_FS	{
			    
			foreach	year	in	2001	2003	2017	2019	{
				    
				*	Joint
				tab		l2_`var'	`var'	[aw=wgt_long_ind]		if	year==`year', cell matcell(temp)
				scalar	samplesize	=	temp[1,1] + temp[1,2] + temp[2,1] +temp[2,2]	//	calculate sample size by adding up all
				mat trans_2by2_joint_``var'_name'_`year' = temp[1,1], temp[1,2], temp[2,1], temp[2,2]	//	Make it as a row matrix
				mat trans_2by2_joint_``var'_name'_`year' =  trans_2by2_joint_``var'_name'_`year'/samplesize	//	Divide it by sample size to compute relative frequency
				mat	list	trans_2by2_joint_``var'_name'_`year'
				
				scalar	FIFI_``var'_name'_`year'	=	trans_2by2_joint_``var'_name'_`year'[1,1]	//	FI, FI
				scalar	FIFS_``var'_name'_`year'	=	trans_2by2_joint_``var'_name'_`year'[1,2]	//	FI, FS
				scalar	FSFI_``var'_name'_`year'	=	trans_2by2_joint_``var'_name'_`year'[1,3]	//	FI, FS
				scalar	FSFS_``var'_name'_`year'	=	trans_2by2_joint_``var'_name'_`year'[1,4]	//	FS, FS
				
			}	//	year
			
			foreach	type	in	FIFI	FIFS	FSFI	FSFS	{
				
				mat	`type'_``var'_name'	=	`type'_``var'_name'_2001,	`type'_``var'_name'_2003,	`type'_``var'_name'_2017,	`type'_``var'_name'_2019
				mat	`type'_``var'_name'	=	`type'_``var'_name'_2001,	`type'_``var'_name'_2003,	`type'_``var'_name'_2017,	`type'_``var'_name'_2019
				
				mat	rownames	`type'_``var'_name'	=	"``var'_name'"
				
				mat	colnames	`type'_``var'_name'	=	"1999-2001"	"2001-2003"	"2015-2017"	"2017-2019"
			}
				
		}	//	var
			
		foreach	type	in	FIFI	FIFS	FSFI	FSFS	{
			
			mat	list	`type'_PFS
			mat	list	`type'_FSSS
			
			mat	`type'_PFS_FSSS	=	`type'_PFS	\	`type'_FSSS
		}

		
		putexcel	set "${SNAP_outRaw}/Trans_matrix_7919_ind", sheet(PFS_FSSS_dyn) modify
		putexcel	A4	=	"Food insecure in both rounds"
		putexcel	A5	=	matrix(FIFI_PFS_FSSS), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A9	=	"Food secure in both rounds"
		putexcel	A10	=	matrix(FSFS_PFS_FSSS), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A14	=	"Food insecure 1st round only"
		putexcel	A15	=	matrix(FIFS_PFS_FSSS), names overwritefmt nformat(number_d2)	//	3a
		putexcel	A19	=	"Food insecure 2nd round only"
		putexcel	A20	=	matrix(FSFI_PFS_FSSS), names overwritefmt nformat(number_d2)	//	3a
			
		
		
		*	(2023-12-27)	Spell length - PFS and FSSS
		
			*	Spell length using FSSS
			sort	x11101ll	year
			
			*	Construct spell length using FSSS
			cap	drop	FSSS_FI_spell
			cap	drop	FSSS_FI_seq
			cap	drop	FSSS_FI_end
			
			tsspell, cond(FSSS_FI==1) spell(FSSS_FI_spell) seq(FSSS_FI_seq) end(FSSS_FI_end)

			
			*	Construct spell length using PFS - 1999-2003 and 2015-2019 only
				
				*	1999-2003
				cap	drop	PFS_FI_9903_spell
				cap	drop	PFS_FI_9903_seq
				cap	drop	PFS_FI_9903_end
				
				tsspell, cond(PFS_FI_ppml_noCOLI==1 & inlist(year,1999,2001,2003)) spell(PFS_FI_9903_spell) seq(PFS_FI_9903_seq) end(PFS_FI_9903_end)
				
				*	2015-2019
				cap	drop	PFS_FI_1519_spell
				cap	drop	PFS_FI_1519_seq
				cap	drop	PFS_FI_1519_end
				
				tsspell, cond(PFS_FI_ppml_noCOLI==1 & inlist(year,2015,2017,2019)) spell(PFS_FI_1519_spell) seq(PFS_FI_1519_seq) end(PFS_FI_1519_end)
				
				*	1999-2019 (combine the above two)
				
				foreach	var	in	spell	seq	end	{
					
					cap	drop	PFS_FI_9919_`var'
					gen			PFS_FI_9919_`var'=.
					replace		PFS_FI_9919_`var'=PFS_FI_9903_`var'	if	inlist(year,1999,2001,2003)
					replace		PFS_FI_9919_`var'=PFS_FI_1519_`var'	if	inlist(year,2015,2017,2019)
					
				}
				
				
				*	I do NOT use the code below, as it constructs consecutive spell b/w 1999-2003 and 2015-2019 if an individual is NOT observed b/w 2005 to 2013 (ex: x11101ll:6365049)
				*tsspell, cond(PFS_FI_ppml_noCOLI==1 & inlist(year,1999,2001,2003,2015,2017,2019)) spell(PFS_FI_9919_spell) seq(PFS_FI_9919_seq) end(PFS_FI_9919_end)
					
			
			*	Spell length distribution
			
			loc	period1	inlist(year,1999,2001,2003)
			loc	period2	inlist(year,2015,2017,2019)
			loc	period3	inlist(year,1999,2001,2003,2015,2017,2019)
			
				foreach	var	in	FSSS_FI	PFS_FI_9919	{
					
					forval	t=1/3	{
						tab	`var'_seq	[aw=wgt_long_ind]	if	`var'_end==1	&	`period`t'',	matcell(`var'_freq_`t')
						
						mat	list	`var'_freq_`t'
						local	N=r(N)
						mat	`var'_pct_`t'	=	`var'_freq_`t'	/	r(N)
						
						mat	rownames	`var'_pct_`t'	=	"1"	"2"	"3"				
						
					}
					
					mat	`var'_pct_tot	=	`var'_pct_3 \ `var'_pct_1	\	`var'_pct_2
					mat	list	`var'_pct_tot
					
				}
			
				
				mat	spell_9919_tot	=	FSSS_FI_pct_tot, PFS_FI_9919_pct_tot
				mat	colnames	spell_9919_tot	=	"FSSS"	 "PFS"
				mat	list	spell_9919_tot
				
				putexcel	set "${SNAP_outRaw}/Spell_9919_PFS_FSSS", sheet(PFS_FSSS_spell) replace
				putexcel	A3	=	"Spell length, 1999-2003 and 2015-2019"
				putexcel	A5	=	matrix(spell_9919_tot), names overwritefmt nformat(number_d2)	//	3a

		
		
		*use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		*keep	x11101ll	year	wgt_long_ind	sampstr sampcls year	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI
		*	2 X 2 (FS, FI)	-	FS status over two subsequent periods
		
		*svy:	tab	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI  if inrange(year,1981,2019), missing
		*tab year if mi(l2_PFS_FI_ppml_noCOLI) & inrange(year,1981,2019)
		*svy, subpop(if year==1983): tab 	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
		*tab	l2_PFS_FI_ppml PFS_FI_ppml [aw=wgt_long_ind] if year==1999	, missing // give the same ratio
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
		
		
		*	We test whether svy-structure adjusted and non-svy-structure adjusted give the same results.
			*	NOT using svy-structure adjusted 
			tab	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI	[aw=wgt_long_ind] if year==1997, missing matcell(temp_1997)
			mat temp2_1997 = temp_1997 / r(N)
			
			mat list temp_1997
			mat list temp2_1997
			
			mat	trans_change_1997 = temp2_1997[2,2], temp2_1997[1,2], temp2_1997[3,2]
			mat list trans_change_1997
		
			*	Using svy-structure adjusted
			**	They give the same result!
			svy, subpop(if year==1997): tab 	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
			mat list e(b)
			mat	trans_change_1997 = e(b)[1,4], e(b)[1,2], e(b)[1,6]	//	Still FI, newly FI, previous status unknown.
			mat list trans_change_1997
		
		
		
		local	run_fig3=0	//	Estimates sub-group level persistence. Takes a long time to run. (2023-09-24) Conformality error happens. Need to figure out so turn it off until then.
		foreach	year of	global	transyear {			

			di	"year is `year'"
		
			*	Make a matrix of years
			mat	trans_years	=	nullmat(trans_years)	\	`year'
		
			*	Change in Status - entire population
			**	Note: here we do NOT limit our sample to non-missing values, as we need the ratio of those with missing values.
				
				*	We found that svy-adjusted and non-svy-adjusted give the same estimates, from the test above
				*	But we still need to run "svy, subpop" to get the # of subpopulation (cannot be generated under general "summarize" command)
				*	Thus, we use svy-adjusted way.
				svy, subpop(if year==`year'): tab 	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
				local	sample_popsize_total=e(N_subpop)
				mat	trans_change_`year' = e(b)[1,4], e(b)[1,2], e(b)[1,6]
				mat	trans_change_year	=	nullmat(trans_change_year)	\	trans_change_`year'
			
			
			*	Change in status - by group
			if	`run_fig3'==1	{	
			cap	mat	drop	Pop_ratio
			cap	mat	drop	FI_still_`year'	FI_newly_`year'	FI_unknown_`year'	FI_persist_rate_`year'	FI_entry_rate_`year'	FI_unknown_rate_`year'
				
				
				foreach	edu	in	0	 1 	{	//	College, no college
					foreach	race	in	0	 1 	{	//	People of colors, white
						foreach	gender	in	1	 0 	{	//	Female, male
							
							di	"rp_edu=`edu', rp_race=`race', rp_gender=`gender'"
							
							*	Svy-adjusted way
							svy, subpop(if	rp_female==`gender' & rp_White==`race' & rp_col==`edu'	&	year==`year'):	tab l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
												
							local	Pop_ratio	=	e(N_subpop)/`sample_popsize_total'
							local	FI_still_`year'		=	e(b)[1,4]*`Pop_ratio'	//	% of still FI HH in specific group x share of that population in total sample = fraction of HH in that group still FI in among total sample
							local	FI_newly_`year'		=	e(b)[1,2]*`Pop_ratio'	//	% of newly FI HH in specific group x share of that population in total sample = fraction of HH in that group newly FI in among total sample
							local	FI_unknown_`year'	=	e(b)[1,6]*`Pop_ratio'	//	% of previous status unknown 
							local	FI_persist_rate_`year'		=	e(b)[1,4]
							local	FI_entry_rate_`year'		=	e(b)[1,2]
							local	FI_unknown_rate_`year'		=	e(b)[1,6]
							
							*mat	Pop_ratio	=	nullmat(Pop_ratio)	\	`Pop_ratio'	//	(2023-07-21) Disable it, as we don't need to stack population ratio over years.
							mat	FI_still_`year'		=	nullmat(FI_still_`year')	\	`FI_still_`year''
							mat	FI_newly_`year'		=	nullmat(FI_newly_`year')	\	`FI_newly_`year''
							mat	FI_unknown_`year'	=	nullmat(FI_unknown_`year')	\	`FI_newly_`year''
							mat	FI_persist_rate_`year'	=	nullmat(FI_persist_rate_`year')	\	`FI_persist_rate_`year''
							mat	FI_entry_rate_`year'	=	nullmat(FI_entry_rate_`year')	\	`FI_entry_rate_`year''
							mat	FI_unknown_rate_`year'	=	nullmat(FI_unknown_rate_`year')	\	`FI_unknown_rate_`year''
							
						}	//	gender
					}	//	race
				}	//	education
				
				mat	FI_still_year_all			=	nullmat(FI_still_year_all),	FI_still_`year'
				mat	FI_newly_year_all			=	nullmat(FI_newly_year_all),	FI_newly_`year'
				mat	FI_unknown_year_all			=	nullmat(FI_unknown_year_all),	FI_newly_`year'
				mat	FI_persist_rate_year_all	=	nullmat(FI_persist_rate_year_all),	FI_persist_rate_`year'
				mat	FI_entry_rate_year_all		=	nullmat(FI_entry_rate_year_all),	FI_entry_rate_`year'
				mat	FI_unknown_rate_year_all	=	nullmat(FI_unknown_rate_year_all),	FI_unknown_rate_`year'
			
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
				*drop	status_unknown
				label var	still_FI		"Still food insecure"
				label var	newly_FI		"Newly food insecure"
				label var	status_unknown	"Previous status unknown"
				
				egen	FI_prevalence	=	rowtotal(still_FI	newly_FI	status_unknown)
				label	var	FI_prevalence	"Annual FI prevalence (<0.5)"
				
				*	Matrix for Figure 3
				**	(FI_still_year_all, FI_newly_year_all) have years in column and category as row, so they need to be transposed)
				*	Disable for now, as we don't do sub-group analyses for now
				/*
				foreach	fs_category	in	FI_still_year_all	FI_newly_year_all	{
					
					mat		`fs_category'_tr=`fs_category''
					svmat 	`fs_category'_tr
				}
				*/
				
				*	Figure 2	(Change in food security status by year)
					
					*	B&W 
					graph bar still_FI newly_FI	status_unknown, over(year, label(angle(vertical))) stack legend(lab (1 "Still FI") 	lab(2 "Newly FI")	lab(3 "Previously unknown")rows(1))	///
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
				/*
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
				*/
			
			restore
			