	/* 0.1 - Environment setup */
	
	* Clear all stored values in memory from previous projects
	clear			all
	cap	log			close

	* Set version number
	version			16

	* Set basic memory limits
	set maxvar 		32767
	set matsize		11000

	* Set default options
	set more		off
	pause			on
	set varabbrev	off
	
	* Filename and log
	loc	name_do	SNAP_clean_9513
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${SNAP_doCln}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	
	
	local	cr_panel_9513=0
	local	merge_data_9513=0
		local	raw_reshape_9513=1
		local	add_clean_9513=1
		local	import_dta_9513=1
	local	clean_vars_9513=1
		
	
	
	/****************************************************************
		SECTION 3: Construct PSID panel data and import external data
	****************************************************************/	

	*	Create a panel structre
		*	This study covers 50-year period with different family composition changes, thus we need to carefully consider that.
		*	Basically we will track the two different types of families
			*	(1) Families that initially existed in 1977 (first year of the study)
			*	(2) Families that split-off from the original families (1st category)
		*	Also, we define family over time as the same family as long as the same individual remain either RP or spouse.
		
	if	`cr_panel_9513'==1	{		
		
		*	Merge ID with unique vars as well as other survey variables needed for panel data creation
		use	"${SNAP_dtInt}/Ind_vars/ID", clear
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/unique_vars.dta",	nogen	assert(3)
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/wgt_long_ind.dta",	nogen	assert(3)	//	Individual weight
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Fam_vars/wgt_long_fam.dta",	nogen	assert(3)	//	Family weight
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Fam_vars/change_famcomp.dta",	nogen	assert(3)	//	Family composition
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Fam_vars/splitoff.dta",	nogen	assert(3)	//	Splitoff indicator
		
		*	Merge individual variables
		cd "${SNAP_dtInt}/Ind_vars"
		
		global	varlist_ind	age_ind	/*wgt_long_ind*/	relrp	origfu_id	noresp_why
		
		foreach	var	of	global	varlist_ind	{
			
			merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(2 3)	keep(3)	//	Longitudinal weight
				
		}
		
		*	Keep only study period years (1995-2013)
		keep	x11101ll	pn sampstr sampcls gender sampstat	*1995	*1997	*1999	*2001	*2003	*2005	*2007	*2009	*2011	*2013
		
		*	Tag individuals who are RP in the same household throughout 1995-2013, which can be determined by
			*	(i) RP all the time
			*	(ii) No household composition change
		
		*	Construct additional variables
			
			*	Sample source
			cap	drop	sample_source
			gen		sample_source=.
			replace	sample_source=1	if	inrange(x11101ll,1000,2930999)		//	SRC
			replace	sample_source=2	if	inrange(x11101ll,5001000,6872999)	//	SEO
			replace	sample_source=3	if	inrange(x11101ll,3001000,3511999)	//	Immgrant Regresher (1997,1999)
			replace	sample_source=4	if	inrange(x11101ll,4001000,4462999)	|	inrange(x11101ll,4700000,4851999)	//	Immigrant Refresher (2017)
			replace	sample_source=5	if	inrange(x11101ll,7001000,9308999)	//	Latino Sample (1990-1992)
			
			label	define	sample_source		1	"SRC(Survey Research Center)"	///
												2	"SEO(Survey of Economic Opportunity)"	///
												3	"Immigrant Refresher (1997,1999)"	///
												4	"Immigrant Refresher (2017)"	///
												5	"Latino Sample (1990-1992)",	replace
			label	values		sample_source		sample_source
			label	variable	sample_source	"Source of Sample"	
			
					
			*	Sample status defind by the PSID
			cap	drop	Sample
			gen		Sample=0	if	inlist(sampstat,0,5,6)		//	Non-sample, followable non-sample parent and nonsample elderydrop
			replace	Sample=1	if	inlist(sampstat,1,2,3,4)	//	Original, born-in, moved and join inclusion sample
			*drop	if	Sample==0
			label	var	Sample "=1 if PSID Sample member"
			
			*	Relation to HH
			*	As a panel data construction process, I make the code consistent across years
			loc	var	relrp_recode
			
			global	sample_years_9513	1995	1997	1999	2001	2003	2005	2007	2009	2011	2013
			foreach	year	of	global	sample_years_9513	{
						
				cap	drop	`var'`year'
				gen		`var'`year'=0	if	relrp`year'==0	//	Inapp
				
					replace	`var'`year'=1	if	relrp`year'==10	//	Reference Person
					replace	`var'`year'=2	if	inlist(relrp`year',20,22,88,90,92)	//	Spouse, partner, first-year cohabitor, legal spouse
					replace	`var'`year'=3	if	inrange(relrp`year',30,38) | relrp`year'==83	//	Child (including son-in-law, daughter-in-law, stepchild, etc.)
					replace	`var'`year'=4	if	inrange(relrp`year',40,48)	//	Sibling (including in-law, that of cohabitor)
					replace	`var'`year'=5	if	inrange(relrp`year',50,58)	//	Parent (including in-law, that of cohabitor)
					replace	`var'`year'=6	if	inrange(relrp`year',60,65)	//	Grandchild or lower generation
					replace	`var'`year'=7	if	inrange(relrp`year',66,69)	|	inrange(relrp`year',70,75) | inrange(relrp`year',95,97) 	// Other relative (grand-parent, etc.)
					replace	`var'`year'=8	if	relrp`year'==98 	//	Other non-relative
				
							
				label	var	`var'`year'	"Relation to RP (modified) in `year'"
				
			}
		
			label	define	relrp_recode	0	"Inapp"	1	"RP"	2	"Spouse/Partner"	3	"Child"	4	"Sibling"	5	"Parent"	6	"Grandchild or lower"	7	"Other relative"	8	"Other non-relative", replace
			label	value	relrp_recode????	relrp_recode
			
			*	Generate string version of variables for comparison
			foreach	year	of	global	sample_years_9513	{
				
				cap	drop	x11102_`year'_str	relrp_recode`year'_str
				tostring	x11102_`year',	gen(x11102_`year'_str)
				decode 		relrp_recode`year', gen(relrp_recode`year'_str)
				
			}
			
			*	Generate residential status variable
			loc	var	resid_status
			lab	define	resid_status	0	"Inapp"	1	"Resides"	2	"Institution"	3	"Moved Out"	4	"Died", replace
			foreach	year	of	global	sample_years_9513	{
			
				cap	drop	`var'`year'	`var'`year'_str
				gen		`var'`year'=0
				replace	`var'`year'=1	if	inrange(xsqnr_`year',1,20)	//	In HH
				replace	`var'`year'=2	if	inrange(xsqnr_`year',51,59)	//	In institution (ex. college)
				replace	`var'`year'=3	if	inrange(xsqnr_`year',71,79)	//	Moved out and cannot be traced
				replace	`var'`year'=3	if	inrange(xsqnr_`year',80,89)	//	Passed away
				
				lab	var	`var'`year'	"Residential status in `year'"
				
				label	value	`var'`year'	resid_status
				decode	`var'`year', gen(`var'`year'_str)
				
			}
			
			*	Generate dummies for different individuals
			foreach	year	of	global	sample_years_9513	{
			
				*	RP in the same household: (i) sequence number is equal to 1 (ii) relation to RP is equal to 10 (iii) No change in head
				cap	drop	sameRP`year'
				gen		sameRP`year'=0
				replace	sameRP`year'=1	if	xsqnr_`year'==1	&	relrp`year'==10 & inlist(change_famcomp`year',0,1,2)
				
				lab	var	sameRP`year'	"Same RP in `year'"
				
				*	RP or SP in the same household: (i) sequence number is 1 or 2 (ii) relation to RP is 10, 20 or 22 throught the study period (iii) 
				cap	drop	sameRPorSP`year'
				gen		sameRPorSP`year'=0
				replace	sameRPorSP`year'=1	if	inlist(xsqnr_`year',1,2)	&	inlist(relrp`year',10,20,22) & inlist(change_famcomp`year',0,1,2,3,4)
				
				lab	var	sameRPorSP`year'	"Same RP or SP in `year'"
				
			
			}
			
			*	Tag individual who has been same RP across the study period
			loc	var	sameRP_9513
			cap	drop	`var'
			egen		`var'	=	anycount(sameRP????), values(1)
			lab	var	`var'	"# of waves being same RP (1997-2013)"
			
			*	Tag individual who has been same RP across the study period
			loc	var	sameRPorSP_9513
			cap	drop	`var'
			egen		`var'	=	anycount(sameRPorSP????), values(1)
			lab	var	`var'	"# of waves being same RP (1997-2013)"
			
			
	
		*	Keep only the relevant sample
		*	(2023-08-27) Unlike individual-level data cosntruction, I need not worry about not being Sample member (since that person is living with a Sample member), and weight adjustment.
		
		
			*	Drop Latino sample and immigrant refreshers
				drop	if	inlist(sample_source,3,4,5)			
			
			*	Keep only if same RP or SP
				keep	if	sameRPorSP_9513==10
				
				/*
				foreach	year	of	global	sample_years_9513	{
				
					*	Tag duplicate obs for same HH in a year
					cap	drop	dup`year'
					duplicates	tag	x11102_`year', gen(dup`year')
					
					
					tab xsqnr_`year' if dup`year'==1
					
					*	Keep only sequence number=1 (RP only) if duplicate
					drop	if	dup`year'==1	&	 xsqnr_`year'==2
					
				}
				*/
			
			*	(2023-08-27) For now, I use RP being the same over time. Can think of other ways to deal with....
			*	keep only invididuals being RP in the same HH over the period
				keep	if	sameRP_9513==10
		
				
			*	Double-checking there is only one person (RP) per HH each year
			loc	check_unique_HH=0
			if	`check_unique_HH'==1	{
				
			preserve
				keep	x11101ll x11102_????
				duplicates tag x11102_ year, gen(dup)
				assert	dup==0
			restore
				
			}
			
		*	Save
			
			keep	x11101ll x11102_???? xsqnr_???? pn sampstr sampcls gender sampstat wgt_long_fam???? change_famcomp???? splitoff???? age_ind???? relrp???? sample_source Sample resid_status????
			order	pn sampstr sampcls gender sampstat Sample,	after(x11101ll)	
			
			*	Wide-format
			save	"${SNAP_dtInt}/Ind_vars/ID_sample_wide_9513.dta", replace
		
			*	Re-shape it into long format and save it
			use	"${SNAP_dtInt}/Ind_vars/ID_sample_wide_9513.dta", clear
			reshape long	x11102_	xsqnr_	wgt_long_fam	change_famcomp	splitoff	age_ind relrp	resid_status, i(x11101ll) j(year)
	
			*	Rename variables
			rename	x11102_	surveyid
			rename	xsqnr_	seqnum
			
			label	var	year		"Year"
			label	var	surveyid	"Survey ID"
			label	var	seqnum		"Sequence No."
			label	var	wgt_long_fam	"Longitudinal family Weight"
			label	var	change_famcomp		"Change in family composition"
			label	var	splitoff		"Splitoff status"
			label	var	age_ind 	"Age (individual)"
			label	var	relrp		"Relationship to RP"
			label	var	resid_status	"Residentail status"
			
			save	"${SNAP_dtInt}/Ind_vars/ID_sample_long_9513.dta",	replace
	}	
		
			*	Merge variables
	if	`merge_data_9513'==1	{
		
		if	`raw_reshape_9513'==1	{
			
			*	Start with ID variables
			use	"${SNAP_dtInt}/Ind_vars/ID_sample_wide_9513.dta", clear
										
			*	Merge family variables
			*	(2022-3-13) Instead of manually entering variables, I use "dir" command to load all variables in "Fam" folder.
			cd "${SNAP_dtInt}/Fam_vars"
			local fam_files : dir "${SNAP_dtInt}/Fam_vars" files "*.dta", respectcase	//	"respectcase" preserves upper case when upper case is included
			di	`fam_files'
			
			global	varlist_fam		//	Make a list of family variables (to be used in "reshape" command later. Initiate the global with blank entry)
			foreach	filename	of	local	fam_files	{

				di	"current filename is `filename'"
				loc	varname	=	subinstr("`filename'",".dta","",.)
				
				di "current varname is `varname'"			
				merge 1:1 x11101ll using "`varname'", keepusing(`varname'*) nogen assert(2 3)	keep(3)	
				global	varlist_fam	${varlist_fam}	`varname'
				
			}
						
		
			*	Keep only study period + 1995 (for lagged food exp) data
			keep	x11101ll-Sample	*1995	*1997	*1999	*2001	*2003	*2005	*2007	*2009	*2011	*2013
			
			*	Keep only lived in 48 continental states over 1997-2013
			loc	var	any_AK_HA
			cap	drop	`var'
			egen	`var'= anycount(rp_state1995-rp_state2013), values(0,50,51,99)
			drop	if	`var'!=0
			drop	`var'
	
			*	Save (wide-format)
			save	"${SNAP_dtInt}/SNAP_RawMerged_wide_9513",	replace
			
			*	Re-shape it into long format	
			use	"${SNAP_dtInt}/SNAP_RawMerged_wide_9513",	clear
			reshape long x11102_	xsqnr_	 age_ind relrp resid_status	${varlist_fam}, i(x11101ll) j(year)
			order	x11101ll /*pn sampstat Sample*/ year x11102_ xsqnr_ 
			*drop	if	inlist(year,1973,1988,1989)	//	These years seem to be re-created during "reshape." Thus drop it again.
			*drop	if	inrange(year,1968,1974)	//	Drop years which don't have last month food stamp information exist.
			
			*	Rename variables
			rename	x11102_	surveyid
			rename	xsqnr_	seqnum
			
						
			*	Label variables
			*	It would be better to do this after preparing all variables
			
			label	var	year			"Survey Wave"
			label 	var	surveyid		"Survey	ID"
			label	var	seqnum			"Sequence Number"
			*label	var	wgt_long_ind	"Longitudinal individual Weight"
			label	var	wgt_long_fam	"Longitudinal family Weight"
			*label	var	living_Sample	"=1 if Sample member living in FU"
			*label	var	tot_living_Sample	"# of Sample members living in FU"
			*label	var	wgt_long_fam_adj	"Longitudianl family weight, adjusted"
			label	var	age_ind			"Age of individual"
			*label 	var	relrp		"Relation to RP"	//	This variable will be imported from ID sample data.
			*label	var	origfu_id	"Original FU ID splitted from"
			*label	var	noresp_why	"Reason for non-response"
			label	var	splitoff	"(raw) Split-off status"
			label	var	rp_gender	"Gender of RP"

			save	"${SNAP_dtInt}/SNAP_RawMerged_long_9513",	replace
	
		
		}
			
		if	`add_clean_9513'==1	{
		
		*	Before constructing panel structure, we first construct TFP cost per FU in each unit.
		*	This must be done before constructing, because it requires individual observations which will later be dropped.
		
			use	"${SNAP_dtInt}/SNAP_RawMerged_long_9513",	clear
			
			*	Survey info
			
				*	Month of interview
			
				loc	var	svy_month
				cap	drop	`var'
				gen		`var'=.
				
					*	1980-1996
					*	Treat missing month as "0"
					local	startyear=1980
					local	endyear=1996
				
					replace	`var'=floor(svydate/100)	if	inrange(year,`startyear',`endyear')	
					replace	`var'=0						if	inrange(year,`startyear',`endyear')	&	svydate==9999	//	NA/mail interview
					replace	`var'=0						if	inrange(year,`startyear',`endyear')	&	svydate==6	//	Wild code (1 obs in 1994)
					
					*	1997-2013
					local	startyear=1997
					local	endyear=2013
					replace	`var'=svymonth	if	inrange(year,`startyear',`endyear')
					
					lab	define	`var'	0	"NA/DK"	1	"Jan"	2	"Feb"	3	"Mar"	4	"Apr"	5	"May"	6	"Jun"	///
													7	"Jul"	8	"Aug"	9	"Sep"	10	"Oct"	11	"Nov"	12	"Dec", replace
					lab	val	`var'	`var'
					
					label	var	`var'	"Survey Month"
				
				
				*	Generate survey year+month variable (yyyymm)
				loc	var	svy_yrmonth
				cap	drop	`var'
				gen		`var'	=	year*100	+	(svy_month)
				replace	`var'	=.	if	svy_month==0	|	mi(svy_month)
				lab	var	`var'	"Survey year and month (YYYYMM)"
				
				*	Previous year+month
				*	This variable will be used to import CPI, to impute real value (FS amount, food expenditures)
				loc	var	prev_yrmonth
				cap	drop	`var'
				gen		`var'	=	year*100+(svy_month-1)
				replace	`var'	=	(year-1)*100+12	if	svy_month==1	//	For janury
				replace	`var'	=.	if	svy_month==0	|	mi(svy_month)	//	NA/DK or missing survey month(seqnum==0)
				label	var	`var'	"Previous year/month"
			
				*	Survey date	(1980-2019)
				**	Date prior to 1980 is available only in categorical value.
				loc	var	svy_day
				cap	drop	`var'
				gen		`var'=.
			
					*	1980-1996
					*	Treat missing month as "0"
					local	startyear=1980
					local	endyear=1996
				
					replace	`var'=floor(svydate/100)	if	inrange(year,`startyear',`endyear')	
					replace	`var'=0						if	inrange(year,`startyear',`endyear')	&	svydate==9999	//	NA/mail interview
					replace	`var'=0						if	inrange(year,`startyear',`endyear')	&	svydate==6	//	Wild code (1 obs in 1994)
					
					*	1997-2013
					local	startyear=1997
					local	endyear=2013
					replace	`var'=svyday	if	inrange(year,`startyear',`endyear')
				
					label	var	`var'	"Survey Day"
				
		
				
			*	Calulate family-level TFP cost
			
				*	Import TFP cost data
				merge m:1	year	age_ind gender svy_month using "${SNAP_dtInt}/TFP cost/TFP_costs_all" , assert(2 3)  keepusing(TFP_monthly_cost)
			
				*	Validate if merge was properly done
				*	Only observations in PSID data with invalid age/survey month/gender are not matched
				local	age_invalid		inlist(age_ind,0,999)
				local	svymon_invalid	svy_month==0
				local	gender_invalid	!inlist(gender,1,2)
				
				assert `age_invalid' | `svymon_invalid'	|	`gender_invalid'	///
					 if inrange(year,1995,2013) & _merge==1
				drop	if	_merge!=3
				drop	_merge	//	drop after validation
				
				*	Sum all individual costs to calculate total monthly cost 
				loc	var	foodexp_W_TFP
				
				bys	year	surveyid:	egen `var'	=	 total(TFP_monthly_cost)	 if !mi(surveyid)	//	&	live_in_FU // Total household monthly TFP cost 
				
				*	Adjust by the number of families
				replace	`var'	=	`var'*1.2	if	famnum==1	//	1 person family
				replace	`var'	=	`var'*1.1	if	famnum==2	//	2 people family
				replace	`var'	=	`var'*1.05	if	famnum==3	//	3 people family
				replace	`var'	=	`var'*0.95	if	inlist(famnum,5,6)	//	5-6 people family
				replace	`var'	=	`var'*0.90	if	famnum>=7	//	7+ people family
								
				*	Construct per capita TFP cost (thousands) variable
				**	CAUTION: In the original PFS paper I replaced it instead of creating a new one, but here I will create a new one
				**	Make sure to have this in mind when constructing PFS later.
				gen	`var'_pc	=	(`var'/famnum)
				gen	`var'_pc_th	=	((`var'/famnum)/1000)
				
				label	var	`var'		"Total monthly TFP cost"
				label	var	`var'_pc	"Total monthly TFP cost per capita"
				label	var	`var'_pc_th	"Total monthly TFP cost per capita (K)"
		
			*	Save
			save	"${SNAP_dtInt}/SNAP_ExtMerged_long_9513",	replace
		
		}	//	add_clean
		
		if	`import_dta_9513'==1	{
		    				
			use	"${SNAP_dtInt}/SNAP_ExtMerged_long_9513.dta",	clear
	
			*	Import SNAP policy data
			*merge m:1 rp_state prev_yrmonth using "${SNAP_dtInt}/SNAP_policy_data", nogen keep(1 3)
			merge m:1 rp_state year using "${SNAP_dtInt}/SNAP_policy_data_official", nogen  keep(1 3) //keepusing(SNAP_index_off_uw	SNAP_index_off_w)
			
			*	Import census data
			merge	m:1	year	using	"${SNAP_dtInt}/HH_census_1979_2019.dta", nogen assert(2 3) keep(3)  ///
				keepusing(pct_rp_female_Census  pct_rp_nonWhite_Census HH_age_median_Census_int pct_HH_age_below_30_Census HH_size_avg_Census pct_col_Census pov_rate_national	US_est_pop) 
			
			*	Import state-wide monthly unemployment data
			merge m:1 rp_state prev_yrmonth using "${SNAP_dtInt}/Unemployment Rate_state_month", nogen assert(2 3) keep(3) keepusing(unemp_rate)
			
			*	Import COLI data
			*	(2023-08-27) NOT all state-year has COLI available every year (ex. NJ in 1997). We can later drop them from analyses sample
			merge m:1	rp_state	year	using	"${SNAP_dtInt}/COLI", nogen keep(1 3)
			
			*	Import Poverty guideline data
			merge	m:1	year	famnum	using	"${SNAP_dtInt}/Poverty_guideline",	nogen	assert(2 3) keep(3)
			
			*	Import Payment Error Rate
				merge	m:1	year	rp_state	using	 "${SNAP_dtInt}/Payment_Error_Rates", nogen	assert(2 3) keep(3)	//	State
				merge	m:1	year	using	 "${SNAP_dtInt}/Payment_Error_Rates_ntl", nogen	assert(2 3) keep(3)	//	State
			
			*	Import CPI data
			merge	m:1	prev_yrmonth	using	"${SNAP_dtInt}/CPI_1947_2021",	nogen	assert(2 3) keep(3) keepusing(CPI)
			
			
			*	Import income poverty line
			merge	m:1	year famnum	using	"${SNAP_dtInt}/incomePL", nogen assert(2 3) keep(3)
			
			*	Import SNAP summary data
			merge	m:1	year using	"${SNAP_dtInt}/SNAP_summary", nogen assert(2 3) keep(3) 
			
			compress
			save	"${SNAP_dtInt}/SNAP_Merged_long_9513",	replace
			use "${SNAP_dtInt}/SNAP_Merged_long_9513", clear
		}
		
	}	//	merge_data
	
	
	
	/****************************************************************
		SECTION 4: Clean data and save it
	****************************************************************/	
	
	*	Clean variables
	if	`clean_vars_9513'==1	{
		
		use	"${SNAP_dtInt}/SNAP_Merged_long_9513",	clear
					
			*	Define "yes1no0" label
			lab	define	yes1no0	0	"No"	1	"Yes", replace
			
			*	Survey year dummies
			tab	year, gen(year_enum)
			
			*	Split-off since the last survey
			*	General rule of treating re-contact family is that, we treat it as "non split-off"
			loc	var	split_off
			cap	drop	`var'
			gen		`var'=.
			
				*	1993-1996
				replace	`var'=0	if	inlist(splitoff,1,3)	&	inrange(year,1993,1996)	//	Re-interview, re-contact
				replace	`var'=1	if	inlist(splitoff,2,4)	&	inrange(year,1993,1996)	//	Split-off, split-off recontact
				
				*	1997, 1999
				*	Here immigrant refresher has value 4, so we need to categorize them as non-splitoff
				replace	`var'=0	if	inlist(splitoff,1,3)	&	inrange(year,1997,1999)	//	Re-interview, re-contact
				replace	`var'=1	if	inlist(splitoff,2,4)	&	inrange(year,1997,1999)	//	Split-off, split-off recontact
				
				replace	`var'=0	if	inlist(splitoff,4,4)	&	inrange(year,1997,1997)	&	inrange(x11101ll,3001001,3441999)	//	Imm. refresher in 1997
				replace	`var'=0	if	inlist(splitoff,4,4)	&	inrange(year,1999,1999)	&	inrange(x11101ll,3442001,3511999)	//	Imm. refresher in 1999
				
				*	2001-2019
				*	Treat immigrant refreshers in 2017,2019 as non-splitoff
				replace	`var'=0	if	inlist(splitoff,1,3,5)	&	inrange(year,2001,2019)	//	Re-interview, re-contact
				replace	`var'=1	if	inlist(splitoff,2,4)	&	inrange(year,2001,2019)	//	Split-off, split-off recontact
			
			label	value	`var'	yes1no0
			label	var	`var'	"Split-off since the last survey"
		
		*	Age
			
			*	Individual age
			*	Fix age=999 from manually observed result.
			replace	age_ind=99	if	x11101ll==802002	&	year==1997
			replace	age_ind=99	if	x11101ll==1952002	&	year==1992
			replace	age_ind=14	if	x11101ll==6112034	&	year==1993
			
			*	RP age
			replace	rp_age=age_ind	if	rp_age==999	&	seqnum==1	//	If member is RP, just use his/her age
			
			replace	rp_age=41	if	x11101ll==976033	&	year==2001
			replace	rp_age=41	if	x11101ll==1152031	&	year==2001
			replace	rp_age=64	if	x11101ll==1538001	&	year==1997
			replace	rp_age=46	if	x11101ll==1697036	&	year==1999	//	Re-interviwed (institution), thus use previous RP's updated age
			replace	rp_age=46	if	x11101ll==1697040	&	year==1999	//	Re-interviwed (moved out), thus use previous RP's updated age
			
			replace	rp_age=49	if	x11101ll==2601032	&	year==1999	//	Re-interviwed (RP age inconsistent), thus use RP's updated age in next wave
			replace	rp_age=49	if	x11101ll==2601034	&	year==1999	//	Re-interviwed (RP age inconsistent), thus use RP's updated age in next wave
			replace	rp_age=49	if	x11101ll==2601036	&	year==1999	//	Re-interviwed (RP age inconsistent), thus use RP's updated age in next wave

			replace	rp_age=52	if	x11101ll==3274001	&	year==1997	//	Refresher, thus use RP's age in next wave
			
			replace	rp_age=38	if	x11101ll==4434001	&	year==2017	//	Refresher, thus use RP's age in next wave
			
			replace	rp_age=39	if	x11101ll==5031003	&	year==2003	//	Age inconsistent, use later information
			replace	rp_age=39	if	x11101ll==5031031	&	year==2003	//	Age inconsistent, use later information
			replace	rp_age=39	if	x11101ll==5031046	&	year==2003	//	Age inconsistent, use later information
			
			replace	rp_age=56	if	x11101ll==5366009	&	year==2005	//	Use age from the next wave
			
			replace	rp_age=33	if	x11101ll==5366048	&	year==2005	//	Re-contact family, thus usa age from earlier waves
			
			replace	rp_age=62	if	surveyid==2020		&	year==2005	//	Married. Use age from later waves
			
			replace	rp_age=47	if	x11101ll==5959177	&	year==1999	//	Institution. Use age earlier wave
			
			replace	rp_age=54	if	x11101ll==6051039	&	year==2009	//	Split-off. Use age later wave
			
			
			replace	rp_age=47	if	x11101ll==5959004	&	year==1999	//	From individual age data (this RP is dropped sample)
			replace	rp_age=24	if	x11101ll==6589030	&	year==2007	//	From individual age data (this RP is dropped sample)
			replace	rp_age=35	if	x11101ll==6129032	&	year==2013	//	From individual age data (this RP is dropped sample)
			
			replace	rp_age=.n	if	rp_age==999	//	Tag as missing if 999
			
			label	var	rp_age	"Age (RP)"
			
			*	Square age to capture non-linear effect
			*	We also re-scale it to thousands
			
				*	Individual age squared
				loc	var		age_ind_sq
				cap	drop	`var'
				gen	`var'	=	(age_ind)^2
				lab	var	`var'	"Age(ind)$^2$/1000"
				
				
				loc	var	rp_age_sq
				cap	drop	`var'
				gen	`var'	=	(rp_age*rp_age)/1000
				lab	var	`var'	"Age(RP)$^2$/1000"
			
			
			*	RP age group (to compare with the Census data)
			
				*	Below 30.
				loc	var	rp_age_below30
				cap	drop	`var'
				gen		`var'=.
				replace	`var'=0	if	!mi(rp_age)	&	!inrange(rp_age,1,29)
				replace	`var'=1	if	!mi(rp_age)	&	inrange(rp_age,1,29)
				lab	var	`var'	"RP age below 30"
				
				*	Over 65
				loc	var	rp_age_over65
				cap	drop	`var'
				gen		`var'=.
				replace	`var'=0	if	!mi(rp_age)	&	!inrange(rp_age,66,120)
				replace	`var'=1	if	!mi(rp_age)	&	inrange(rp_age,66,120)
				lab	var	`var'	"RP age over 65"
				
				
		
		
		*	Gender
		*	Uses same code over the waves. Very few observations have wild code neither male nor female. Treat them as missing
			
			*	Individual
			loc	var	ind_female
			cap	drop	`var'
			rename	gender	`var'
			recode	`var'	(1=0)	(2=1)
			label	value	`var'	yes1no0
			label	var	`var'	"Female"
			
			*	RP
			loc	var	rp_female
			cap	drop	`var'
			gen		`var'=0	if	rp_gender==1
			replace	`var'=1	if	rp_gender==2
			label	value	`var'	yes1no0
			label	var		`var'	"Female (RP)"
		
			order	`var',	after(rp_gender)
			drop	rp_gender
		
		*	Marital status
		*	I use variable that are consistent across wave. If I need further distinction (ex. b/w legal marriage and merely living together), I need to check other variables
		loc	var	rp_married
		cap	drop	`var'
		gen		`var'=0	if	inlist(rp_marital,2,3,4,5,9)
		replace	`var'=1	if	rp_marital==1 // Single, widow, separated, divorced.
		label	value	`var'	yes1no0
		label	var		`var'	"Married"
		
		*	Race
		*	Codes are different over waves, but White always has value=1 so we can use simple categorization (White vs non-White) without further harmonization
		*	For years with multiple responses, we use the first reponse only (over the entire PSID data less than 5% gave multiple answers.)
		*	For DK/Refusal, we categorize them as non-White
		loc	var	rp_White
		cap	drop	`var'
		gen		`var'=0	if	inrange(rp_race,2,9)	//	Black, Asian, Native American, etc.
		replace	`var'=1	if	rp_race==1 // White
		label	value	`var'	yes1no0
		label	var		`var'	"White (RP)"
		
		local	var	rp_nonWhite
		cap	drop	`var'
		gen		`var'=rp_White
		recode	`var'	(1=0) (0=1) 
		label	value	`var'	yes1no0
		label	var		`var'	"non-White (RP)"
		
		*	State of Residence
		label define	statecode	0	"Inap.: U.S. territory or foreign country"	99	"D.K; N.A"	///
									1	"Alabama"		2	"Arizona"			3	"Arkansas"	///
									4	"California"	5	"Colorado"			6	"Connecticut"	///
									7	"Delaware"		8	"D.C."				9	"Florida"	///
									10	"Georgia"		11	"Idaho"				12	"Illinois"	///
									13	"Indiana"		14	"Iowa"				15	"Kansas"	///
									16	"Kentucky"		17	"Louisiana"			18	"Maine"		///
									19	"Maryland"		20	"Massachusetts"		21	"Michigan"	///
									22	"Minnesota"		23	"Mississippi"		24	"Missouri"	///
									25	"Montana"		26	"Nebraska"			27	"Nevada"	///
									28	"New Hampshire"	29	"New Jersey"		30	"New Mexico"	///
									31	"New York"		32	"North Carolina"	33	"North Dakota"	///
									34	"Ohio"			35	"Oklahoma"			36	"Oregon"	///
									37	"Pennsylvania"	38	"Rhode Island"		39	"South Carolina"	///
									40	"South Dakota"	41	"Tennessee"			42	"Texas"	///
									43	"Utah"			44	"Vermont"			45	"Virginia"	///
									46	"Washington"	47	"West Virginia"		48	"Wisconsin"	///
									49	"Wyoming"		50	"Alaska"			51	"Hawaii"	///
						, replace
		lab	val	rp_state statecode
		lab	var	rp_state "State of Residence"
		
			*	Create a dummy of (group of states)
			tab rp_state, gen(rp_state_enum)
			
			*	Greater region (Northeast, Mid-Atlantic, South, Midwest, West)
			cap	drop	rp_region
			gen		rp_region=.
			replace	rp_region=1	if	inlist(rp_state,18,28,44,31,20,6,38) //	Northeast: ME, NH, VT, NY, MA, CT, RI
			replace	rp_region=2	if	inlist(rp_state,37,29,8,7,19,45) //	Mid-Atlantic: PA, NJ, DC, DE, MD, VA
			replace	rp_region=3	if	inlist(rp_state,32,39,10,16,41,47,9,1,3,23,17,42) //	South: NC, SC, GA, TN, WV, FL, AL, AR, MS, LS, TX
			replace	rp_region=4	if	inlist(rp_state,34,13,21,12,22,48,14,24) //	MidWest:	OH, IN, MI, IL, MN, WI, IA, MO
			replace	rp_region=5	if	inlist(rp_state,15,26,33,40,35,2,5,11,25,27,30,43,49,36,46,4) //	West: KS, NE, ND, SD, OK, AZ, CO, ID, MT, NV, NM, UT, WY, OR, WA, CA
			
			lab	define	rp_region	0	"Others (Inapp, AL, HA, DK/NA)"	1	"Northeast"	2	"Mid-Atlantic"	3	"South"	4	"Midwest"	5	"West", replace	
			lab	value	rp_region	rp_region
			
			*	Dummies for each region
			tab	rp_region,	gen(rp_region)
			rename	(rp_region?)	(rp_region_NE	rp_region_MidAt	rp_region_South	rp_region_MidWest	rp_region_West)
			clonevar	rp_region_NE_noNY	=	rp_region_NE
			replace		rp_region_NE_noNY	=	0	if	rp_state==31	//	Exclude NY
			
			lab	var	rp_region_NE	"Northeast"
			lab	var	rp_region_NE_noNY	"Northeast (excluding NY)"
			lab	var	rp_region_MidAt	"Mid-Atlantic"
			lab	var	rp_region_South	"South"
			lab	var	rp_region_MidWest	"Mid-West"
			lab	var	rp_region_West	"West"
			
				
		
		*	Employment Status
			
			*	RP's employment (family-level)
			*	Two different variables over time, and even single series changes variable over waves. Need to harmonize them.
			loc	var	rp_employed
			cap	drop	`var'
			gen		`var'=.
			
			replace	`var'=0	if	inrange(year,1976,1996)	&	inrange(rp_employment_status,3,9)	//	I treat "Other" as "unemployed". In the raw PSID data less than 0.2% HH answer "other" during these waves
			replace	`var'=1	if	inrange(year,1976,1996)	&	inrange(rp_employment_status,1,2)	//	Include temporarily laid off/maternity leave/etc.
			
			replace	`var'=0	if	inrange(year,1997,2019)	&	inrange(rp_employment_status,3,99)	|	rp_employment_status==0	//	Include other, "workfare", "DK/refusal"
			replace	`var'=1	if	inrange(year,1997,2019)	&	inrange(rp_employment_status,1,2)	//	Include temporarily laid off/maternity leave/etc.
			
			
			label	value	`var'	yes1no0
			label	var		`var'	"Employed"
		
		*	Grades completed
		*	We split grade completion into four categories; No HS, HS, some college, College
						
			*	RP's education (family-level)
			*	For households who didn't respond, I will create a separate category as "NA/DK/Refusal/Inapp"
			loc	var	rp_edu_cat
			cap	drop	`var'
			gen		`var'=.
			
				*	No High school (Less than 12 degree)
				*	Includes "cannot read or write"
				replace	`var'=1	if	inrange(year,1968,1990)	&	inrange(rp_gradecomp,0,3)	// Includes 0 coded as "cannot read or write"
				replace	`var'=1	if	inrange(year,1991,2019)	&	inrange(rp_gradecomp,0,11)	//	Less than 12 grade
				
				*	High School
				replace	`var'=2	if	inrange(year,1968,1990)	&	inrange(rp_gradecomp,4,5)	//	12 grade and higher
				replace	`var'=2	if	inrange(year,1991,2019)	&	inrange(rp_gradecomp,12,12)	//	12 grade and higher
				replace	`var'=2	if	inrange(year,1985,2019)	&	inlist(rp_HS_GED,1,2) 	//	HS or GED
				
				*	Some college (College without degree)
				replace	`var'=3	if	inrange(year,1968,1990)	&	rp_gradecomp==6		//	During these years, rp_gradecomp==6 means "College, but no degree"
				replace	`var'=3	if	inrange(year,1991,2019)	&	inrange(rp_gradecomp,13,17)	&	rp_coldeg!=1	//	13-grade or over, but did not say "yes" to the question "has college degree?"
				
				*	College or greater 
				*	(2023-7-17) Previously it tagged community degree as well.
				replace	`var'=4	if	inrange(year,1968,1990)	&	inrange(rp_gradecomp,7,8)	//	College
				replace	`var'=4	if	inrange(year,1991,2019)	&	rp_coldeg==1	// said "yes" to "has college degree"
				*replace	`var'=4	if	inrange(year,1991,2019)	&	inrange(rp_gradecomp,13,17)		&	rp_coldeg==1	//	Said "yes" to the question "has college degree?" (disabled as of 2023-07-17)
				
				
				
				*	NA/DK
					*	Usually when it is unknown whether RP has high school diploma or how many years of college education completed.
					*	Excluding "cannot read/write in early years"
				replace	`var'=.n	if	inrange(year,1991,2019)	&	inrange(rp_gradecomp,99,99)
				
				label	define	`var'	1	"Less than HS"	2	"High School/GED"	3	"Some college"	4	"College"	/*99	"NA/DK"*/,	replace
				label	value	`var'	`var'
				label 	variable	`var'	"Education category (RP)"
				
				cap	drop	rp_edu?		rp_NoHS	rp_HS	rp_somecol	rp_col
				tab `var', gen(rp_edu)
				rename	(rp_edu1	rp_edu2	rp_edu3	rp_edu4	/*rp_edu5*/)	(rp_NoHS	rp_HS	rp_somecol	rp_col	/*rp_NADK*/)
				
				lab	value	rp_NoHS	rp_HS	rp_somecol	rp_col	/*rp_NADK*/	yes1no0
				
				label	var	rp_NoHS	"Less than High School"
				label	var	rp_HS	"High School"
				label	var	rp_somecol	"College (w/o degree)"
				label	var	rp_col	"College Degree"
				*label	var	rp_NADK	"Education (NA/DK)"
			
		*	Disability
		*	I categorize RP as disabled if RP has either "amount" OR "type" of work limitation
		loc	var	rp_disabled
		cap	drop	`var'
		gen		`var'=.
			
			*	NOT disabled, or no problem on work (including NA/DK)
			replace	`var'=0	if	!mi(rp_disable_amt)	|	!mi(rp_disable_type)
			replace	`var'=0	if	inrange(year,1972,2019)	&	inrange(rp_disable_amt,5,9)	
			
			*	Disabled
			replace	`var'=1	if	inrange(year,1972,2019)	&	inlist(rp_disable_amt,1,1)	
			
			label	value	`var'	yes1no0
			label	var	`var'	"Disabled"
		
		*	Family composition
		
			label	var	famnum		"HH size"		//	FU size
			label	var	childnum	"# of child"	//	Child size
			
			*	Ratio of child
			loc	var	ratio_child
			cap	drop	`var'
			gen		`var'=	childnum	/	famnum
			label	var	`var'	"\% of children"
		
		
		*	HFSM
			
			lab	var	HFSM_raw	"FSSS (raw score)"
			lab	var	HFSM_scale	"FSSS (scale score)"
			lab	var	HFSM_cat	"FSSS (category)"
			
			*	FI indicator
			loc	var	HFSM_FI
			cap	drop	`var'
			gen		`var'=0	if	inlist(HFSM_cat,0,1)
			replace	`var'=0	if	inlist(HFSM_cat,2,3)
			
			label	value	`var'	yes1no0
			
			label	var	`var'	"HFSM FI"
			
			*	FSSS-rescaled
			cap	drop	FSSS_rescale
			gen	FSSS_rescale = (9.3-HFSM_scale)/9.3
			label	var	FSSS_rescale "FSSS (re-scaled)"
			
		
		*	Family income
		lab	var	fam_income	"Total household income"
			
			*	Per capita income
			loc	var	fam_income_pc
			cap	drop	`var'
			gen		double	`var'	=	fam_income/famnum
			label	var	`var'	"household income per capita"	
			
			*	Log of per capita income
			loc	var	ln_fam_income_pc
			cap	drop	`var'
			gen		double	`var'	=	log(fam_income_pc)
			label	var	`var'	"household income per capita (log)"	
		
		
		*	Poverty status indicator, based on poverty guideline
			
			*	100%
			loc	var	income_below_100
			cap	drop	`var'
			gen		`var'=0	if	!mi(fam_income)	&	fam_income>incomePL*1
			replace	`var'=1	if	!mi(fam_income)	&	fam_income<=incomePL*1
			lab	var	`var'	"Income below PL"
			
			*	130%
			loc	var	income_below_130
			cap	drop	`var'
			gen		`var'=0	if	!mi(fam_income)	&	fam_income>incomePL*1.3
			replace	`var'=1	if	!mi(fam_income)	&	fam_income<=incomePL*1.3
			lab	var	`var'	"Income below 130\% PL"
			
			*	185%
			loc	var	income_below_185
			cap	drop	`var'
			gen		`var'=0	if	!mi(fam_income)	&	fam_income>incomePL*1.85
			replace	`var'=1	if	!mi(fam_income)	&	fam_income<=incomePL*1.85
			lab	var	`var'	"Income below 185\% PL"
			
			*	200%
			loc	var	income_below_200
			cap	drop	`var'
			gen		`var'=0	if	!mi(fam_income)	&	fam_income>incomePL*2
			replace	`var'=1	if	!mi(fam_income)	&	fam_income<=incomePL*2
			lab	var	`var'	"Income below 200\% PL"
			
			
		*	Individual whose family income was below 130%/200% "at least" once
		*	It seems almost all individuals (over 98%) have their family income below 200% at least onc
			
			*	200%, 1995-2013
			loc	var	income_ever_below_200_9513
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	max(income_below_200)	if	inrange(year,1995,2013)
			lab	var	`var'	"Income below 200% PL at least once (1995-2013)"
			tab	`var'	if	year==2013	//	counting only one obs per person. 65% individuals (7,819) fall into this category
			
			*	130%, 1997-2013
			loc	var	income_ever_below_130_9513
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	max(income_below_130)	if	inrange(year,1995,2013)
			lab	var	`var'	"Income below 130% PL at least once (1995-2013)"
			tab	`var'	if	year==2013	//	counting only one obs per person. 48% of the individuals (5,845) fall into this category
		
		*	Individuals whose family income was "consistently" below 130%/200%

			*	200%, 1997-2013
			loc	var	income_always_below_200_9513
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	min(income_below_200)	if	inrange(year,1995,2013)	//	If individual's income is always below cutoff, then the minimum value would be 1. Otherwise, it would be 0.
			lab	var	`var'	"Income always below 200% PL (1995-2017)"
			tab	`var'	if	year==2013		//	counting only one obs per person. 12% of individuals (1,468) fall into this category.

			*	130%, 1997-2017
			loc	var	income_always_below_130_9513
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	min(income_below_130)	if	inrange(year,1995,2013)	//	If individual's income is always below cutoff, then the minimum value would be 1. Otherwise, it would be 0.
			lab	var	`var'	"Income always below 130% PL (1995-2017)"
			tab	`var'	if	year==2013		//	counting only one obs per person. 4.7% of individuals (574) fall into this category.
		
			
		*	COLI (Cost of Living Index)	
		*	Adjust TFP costs with COLI - grocery index
		gen	TFP_monthly_cost_COLI		=	TFP_monthly_cost	*	(COLI_grocery/100)
		lab	var	TFP_monthly_cost_COLI		"Monthly TFP cost (COLI adjusted)"
		gen	foodexp_W_TFP_COLI			=	foodexp_W_TFP 		*	(COLI_grocery/100)
		lab	var	foodexp_W_TFP_COLI			"Total Monthly TFP cost (COLI adjusted)"
		gen	foodexp_W_TFP_pc_COLI		=	foodexp_W_TFP_pc	*	(COLI_grocery/100)
		lab	var	foodexp_W_TFP_pc_COLI		"Total Monthly TFP cost per capita (COLI adjusted)"
		gen	foodexp_W_TFP_pc_th_COLI	=	foodexp_W_TFP_pc_th	*	(COLI_grocery/100)
		lab	var	foodexp_W_TFP_pc_th_COLI	"Total Monthly TFP cost per capita (K) (COLI adjusted)"
		
		*	Food stamp
		
			*	Whether FS received last month (1975-1997, 2009-2019)
			*	(1999-2007 will be constructed after constructing "month of FS redeemed")
			loc	var	FS_rec_wth
			cap	drop	`var'
			gen		`var'=.	
			
				*	1975-1993
				*	Here we determine FS status by "the number of people FS issued", based on 1977 file description document (page 42)
				*	Note: in 1985, among 786 HHs where at least one person received FS, 97% of them (762 HHs) redeemed non-zero amount (code: tab V3844 if V3843!=0 from 1975 raw data)
				replace	`var'=0	if	inrange(year,1975,1993)		&	stamp_ppl_month==0	//	No FS
				replace	`var'=1	if	inrange(year,1975,1993)		&	inrange(stamp_ppl_month,1,9)	//	FS
				
				*	1994-1997, 2009-2019
				*	Here we have indicator dummy of last month usage so we can directly import it
				*	Any non-missing value other than "yes" (ex. no, wild code, na/dk, inapp) are categorized as "no"
				replace	`var'=0	if	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	&	!mi(stamp_usewth_month)	&	stamp_usewth_month!=1
				replace	`var'=1	if	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	&	!mi(stamp_usewth_month)	&	stamp_usewth_month==1
				
				label	value	`var' yes1no0
				label var	`var'		"SNAP received"
				
			

			*	Month of FS redemption 
			foreach	month	in	Jan	Feb	Mar Apr May Jun Jul Aug Sep Oct Nov Dec	{
								
				loc	var	FS_rec_wth_`month'
				cap	drop	`var'
				gen		`var'=.	
				
				*	1999-2007
				*	We have direct information, so start from here. This is the only period where we ask FS usage of each month.
				*	Treat NA as "didn't use'"
				replace	`var'=0	if	inlist(stamp_usewth_crt`month',0,9)	&	inrange(year,1999,2007)	&	svy_month>=${num`month'}	//	Last condition is needed, because only FS usage of month "prior to survey this year" is asked
				replace	`var'=1	if	inlist(stamp_usewth_crt`month',1)	&	inrange(year,1999,2007)	&	svy_month>=${num`month'}	//	Last condition is needed, because only FS usage of month "prior to survey this year" is asked
					
				*	1975-1997, 2009-2019 
				*	Important: These years don't have FS status other than the previous month (ex. HH surveyed in March don't give any information of FS redemption outside Feb)
				*	Therefore, we need to make sure that only the information of the month right before the survey month should be updated.
							
				if	"`month'"=="Dec"	{
				
					replace	`var'=0	if	(inrange(year,1975,1997)	|	inrange(year,2009,2019))	&	svy_month==1	&	FS_rec_wth==0	//	Second condition restricts only HH surveyed in Jan is used for Dec redemption
					replace	`var'=1	if	(inrange(year,1975,1997)	|	inrange(year,2009,2019))	&	svy_month==1	&	FS_rec_wth==1	//	Second condition restricts only HH surveyed in Jan is used for Dec redemption
					
				}
				
				else	{
					
					replace	`var'=0	if	(inrange(year,1975,1997)	|	inrange(year,2009,2019))	&	svy_month-1==${num`month'}	&	FS_rec_wth==0	//	Second condition restricts only previous month infomration to be imported
					replace	`var'=1	if	(inrange(year,1975,1997)	|	inrange(year,2009,2019))	&	svy_month-1==${num`month'}	&	FS_rec_wth==1	//	Second condition restricts only previous month infomration to be imported
					
				}
			
				label	value	`var' yes1no0
				label	var	`var'	"SNAP used in `month'"
					
			}
			
			*	Whether FS received last month (1999-2007)
			*	Set it 1 if a month prior to survey month has FS redeemed. Otherwise it is zero.
			loc	var	FS_rec_wth
			
			foreach	month	in	Jan	Feb	Mar Apr May Jun Jul Aug Sep Oct Nov Dec	{
			
				if	"`month'"=="Dec"	{
					
					replace	`var'=0	if	inrange(year,1999,2007)	&	svy_month==1	&	FS_rec_wth_`month'==0	//	For HH surveyd in Jan, last month is Dec
					replace	`var'=1	if	inrange(year,1999,2007)	&	svy_month==1	&	FS_rec_wth_`month'==1	//	For HH surveyd in Jan, last month is Dec	
					
				}
				
				else	{
					
					replace	`var'=0	if	inrange(year,1999,2007)		&	svy_month==${num`month'}+1	&	FS_rec_wth_`month'==0		
					replace	`var'=1	if	inrange(year,1999,2007)		&	svy_month==${num`month'}+1	&	FS_rec_wth_`month'==1		
					
				}
			
			}
			
			*	Whether FS used current year (1999-2007)
			*	This variable determines how food expenditure are collected during the period above.
			*	Treat every answers other than "yes" as "no"
			loc	var	FS_rec_crtyr_wth
			cap	drop	`var'
			gen		`var'=.	
			
			replace	`var'=0	if	inrange(year,1999,2007)		&	inlist(stamp_usewth_crtyear,0,2,5,8,9)		
			replace	`var'=1	if	inrange(year,1999,2007)		&	inlist(stamp_usewth_crtyear,1)
			
			label	value	`var'	yes1no0
			label	var	`var'	"SNAP used this year"
		
		*	Spouse have changed
			loc	var	SP_changed
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	change_famcomp==2
			lab	var	`var'	"Spouse changed"
			
		
		
		*	SNAP amount received
		
			*	FS Recall period (1999-2007) - will be later used to adjust values
			loc	var	FS_rec_amt_recall
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=stamp_cntyr_recall	if	inrange(year,1999,2007)
			
			lab	define	`var'	0	"Inapp"		2	"Wild code"	3	"Week"	4	"Two-Week"	5	"Month"	6	"Year"	7	"Other"	8	"DK"	9	"NA/refused", replace
			label	value	`var'	`var'
			label	var	`var'	"SNAP amount received (recall) (1999-2007)"
		
			*	Amount received last month (except 1999-2007 which will be adjusted shortly)
			local	var	FS_rec_amt
			cap	drop	`var'
			gen		double	`var'=.	
			replace	`var'=	stamp_useamt_month	if	inrange(year,1975,2019)	&	!mi(stamp_useamt_month)

			*	Harmonize 1999-2007 into monthly amount (1999-2007)	using recall period	
			*	We treat "wild code" and "other" as "zero amount" for now as there are very small number of observations
			replace	`var'=`var'*4.35	if	FS_rec_amt_recall==3	&	inrange(year,1999,2007)	//	If weekly value, multiply by 4.35
			replace	`var'=`var'*2.17	if	FS_rec_amt_recall==4	&	inrange(year,1999,2007)	//	If two-week value, multiply by 2.17
			replace	`var'=`var'/12		if	FS_rec_amt_recall==6	&	inrange(year,1999,2007)	//	If yearly value, divide by 12
			*replace	`var'=0				if	inlist(FS_rec_amt_recall,2,7)	&	inrange(year,1999,2007)	//	If "inappropriate", then replace with zero
									
			*	For Other/DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value 
				
				*	Share of obs reported outliers
					tab stamp_useamt_month if inrange(year,1994,1997)	//	1994-1997: Less than 0.3% reported 998/999
					tab	stamp_useamt_month if inrange(year,1999,2007)	//	1999-2007: Less than 0.5% reported 999998/999999
					tab	FS_rec_amt_recall	//	1999-2007: Less than 0.5% reported Other/DK/NA/refused.
					tab	stamp_useamt_month if inrange(year,2009,2019)	//	2009-2019: Less than 0.5% reported 99999/999998/999999
	
			*	(2023-1-15) I replace those values as 
			foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
			    
				if	inrange(`year',1994,1997)	{	//	1994 to 1997
										
					summ	`var'			if	year==`year'	&	FS_rec_wth==1	&	!inlist(stamp_useamt_month,998,999)	//	Exclude outliers in imputing mean
					replace	`var'=r(mean) 	if	year==`year'	&	FS_rec_wth==1	&	inlist(stamp_useamt_month,998,999)
				
				}	//	if
				
				else	if	inrange(`year',1999,2007)	{	//	1999 to 2007
				    
					summ	`var'			if	year==`year'	&	FS_rec_wth==1	&	(!inlist(stamp_useamt_month,999998,999999)	&	!inlist(FS_rec_amt_recall,7,8,9))	//	Check both amount and recall period
					replace	`var'=r(mean)	if	year==`year'	&	FS_rec_wth==1	&	(inlist(FS_rec_amt_recall,7,8,9) | inlist(stamp_useamt_month,999998,999999))
					replace	`var'=0			if	year==`year'	&	FS_rec_wth==0	//	Small number of observations (less than 2%) have non-zero redemption value, likely the value other than the previous month. Since the variable we create is the value used "previous month", recode them as zero.
					
				}	//	else	if
				
				else	{	//	2009 to 2017 /* Although 99999 is NOT categorized as dk/na in these years, I included it as dk/na in this code as I believe it is very unrealistic (some FU has this value)					
					summ	`var'			if	year==`year'	&	FS_rec_wth==1	&	!inlist(stamp_useamt_month,99999,999998,999999)	//	Check both amount and recall period
					replace	`var'=r(mean)	if	year==`year'	&	inlist(stamp_useamt_month,99999,999998,999999)
					
				}	//	else
					
			}	//	year
			
			label	var	`var'	"SNAP amount received"
			
			
			*	Replace food stamp amount received with missing if didn't receive stamp (FS_rec_wth==0), for summary stats
			*	There are only two obs with non-zero amount, so should be safe to clean.
			*	This code can be integrated into "cleaning" part later
			*replace	FS_rec_amt_capita_real=.n	if	FS_rec_wth==0
			replace	FS_rec_amt=.n	if	FS_rec_wth==0
						
	
			*	FS amt received per capita
			loc	var	FS_rec_amt_capita
			cap	drop	`var'
			gen	`var'	=	FS_rec_amt	/	famnum
			lab	var	`var'	"SNAP amount per capita"
			
			*	Quick summary stat
			tab FS_rec_wth FS_rec_crtyr_wth if inrange(year,1999,2007)
			tab FS_rec_wth if inrange(year,1999,2007) & FS_rec_crtyr_wth==1	//	FU that used FS this year, but not last month			
		
	
		*	Food expenditure
		*	Note that Food expenditures are separately collected b/w FS users and non-FS (nFS) users since 1994, so we need make variables which combine them.
			
			*	At-home
			*	For at-home expenditures, we need to create two combined variables; one that including FS benefit amount, and one that does NOT include that benefit amount
			loc	var_inclFS	foodexp_home_inclFS		//	food expenditure including food stamp amount, including both FS and nFS across all study period
			loc	var_exclFS	foodexp_home_exclFS		//	food expenditure excluding food stamp amount, including both FS and nFS across all study period
			
			cap	drop	`var_inclFS'
			cap	drop	`var_exclFS'
			
			gen	double	`var_inclFS'=.	
			gen	double	`var_exclFS'=.	
			
			label	var	`var_inclFS'	"Food exp at home (Monthly) (FS incl)"
			label	var	`var_exclFS'	"Food exp at home (Monthly) (FS excl)"
			
			
			*	Also, we create two variables for each type - for FS and NFS - which combined food stamp amounts over time
			*	These two variables will be used to make combined (FS and nFS) variables
			loc	var_inclFS_FS	foodexp_home_inclFS_FS	//	food expenditure including food stamp amount, for FS families only
			loc	var_exclFS_FS	foodexp_home_exclFS_FS	//	food expenditure excluding food stamp amount, for FS families only
						
			cap	drop	`var_inclFS_FS'
			cap	drop	`var_exclFS_FS'
			
			gen	double	`var_inclFS_FS'=.	
			gen	double	`var_exclFS_FS'=.	

			
			loc	var_inclFS_nFS	foodexp_home_inclFS_nFS	//	food expenditure including food stamp amount, for nFS families only
			loc	var_exclFS_nFS	foodexp_home_exclFS_nFS	//	food expenditure excluding food stamp amount, for nFS families only (they should be the same for non-FS)
			
			cap	drop	`var_inclFS_nFS'
			cap	drop	`var_exclFS_nFS'
			
			gen	double	`var_inclFS_nFS'=.	
			gen	double	`var_exclFS_nFS'=.	
					
			
			
				*	1975-1993
				*	Note: at-home expenditure includes "delivered" during these period, and both FS and nFS are collected in the same variable
				*	Convert annual amount to monthly amount
				*	Important: Although "annual" food expenditure is used during these periods, I divide it my to make monthly food expenidture for two reasons
				*	(1) Food expenditure is separately collected based on "food stamp used last month", thus it allows more accurate matching with food stamp used "last month"
				*	(2) In the questionnaires people were asked "weekly" or "monthly" expenditure, so I assume annual food expenditure reported here is somehow imputed from those values
								
					*	(1975-1976) Separate questions were asked whether food stamp amount is included in reported food expenditure
					*	If included, then the amount should be excluded from annual food expenditure to get annual food expenditure "net of" food stamp value
					*	Note: Less than 1% of cases give negative values (0.36% at the time of writing this comment (2022-4-28)). 
						*	I can't check it since the raw data does not have raw responses, but only imputed data. I can only assume that are inconsistent responses.
						*	I will recode those values as zero.
					replace	foodexp_home_annual	=	foodexp_home_annual	-	(FS_rec_amt*12)	///
						if	inrange(year,1975,1976)	&	foodexp_home_wth_stamp_incl==5	//	If stamp value is included
					replace	foodexp_home_annual	=	0	if	inrange(year,1975,1976)	&	!mi(foodexp_home_annual)	&	foodexp_home_annual<0
					
					*	Make annual expenditure into monthly expenditure
					*	They are same for both FS and nFS since they are collected together
					replace	`var_exclFS_FS'	=	foodexp_home_annual/12	if	inrange(year,1968,1993)	&	FS_rec_wth==1
					replace	`var_exclFS_nFS'=	foodexp_home_annual/12	if	inrange(year,1968,1993)	&	FS_rec_wth==0
										
					*	Add up FS amount received (and amount paid in 1975-1979) to get food exp including FS amount
					*	(2022-4-28) Previously I added "amount paid" during 1975-1979. I decided to not to add it since we are interested in bonus value (families actually benefited)
					replace	`var_inclFS_FS'	=	`var_exclFS_FS'	+	FS_rec_amt	if	inrange(year,1975,1993)	&	FS_rec_wth==1	//	Received FS (1975-1993, add amount benefitted)
					replace	`var_inclFS_nFS'=	`var_exclFS_nFS'				if	inrange(year,1975,1993)	&	FS_rec_wth==0	//	Didn't receive FS (so no stamp value to be added)
					
					/*
					replace	`var_inclFS'=`var_exclFS'	+	FS_rec_amt	+	FS_rec_amt_paid	if	inrange(year,1975,1979)	&	FS_rec_wth==1	//	Received FS (1975-1979, add amount paid and amount received)
					replace	`var_inclFS'=`var_exclFS'	+	FS_rec_amt						if	inrange(year,1980,1993)	&	FS_rec_wth==1	//	Received FS (1980-1993, add amount received)
					*/			
												
				*	1994-2019
				*	Food exp are collected separately, between FS user and non-user.
					*	For FS user, (1) FS amount (2) Amount in addition to FS are collected
					*	For non-FS user, (1) Food exp is collected.
 				******	CAUTION	****
				*	For 1999-2007, food exps are collected between FS user and non-FS user of "current year"
				*	It implies that even if FS answered "yes" to that question (so (1) and (2) are collected), that doesn't necessarily mean HH used FS last month
				*	Therefore, when we compare "food exp excluding FS amount", we should be very carefully consider it.
				******	CAUTION	****
							
					*	For FS user
					*	At-home food exp "excluding" FS differs by the response to "Whether used extra amount in addition to FS benefit"
							*	If they answered "yes", then it is the extra amount they used in addition to FS
							*	If they answered "no", then it is zero.
					
						*	Whether used extra value or not
						loc	var	foodexp_home_extra_wth

						cap	drop	`var'
						gen	double	`var'=.
						replace		`var'=0	if	inlist(foodexp_home_spent_extra,0,5,8,9)
						replace		`var'=1	if	inlist(foodexp_home_spent_extra,1)
						label	value	`var'	yes1no0
						label var	`var'	"=1 if spent in addition to FS"
						
						*	Extra amount is collected with free recall period, so we need to make them monthly value
						*	We treat "wild code" and "other" as "zero amount" for now as there are very small number of observations (except 1994 where we treat other as "yearly")					
						
						loc	var				`var_exclFS_FS'
						loc	rawvar			foodexp_home_stamp	//	Raw vaiable with extra amount
						loc	rawvar_recall	foodexp_home_stamp_recall
						
						*cap	drop	`var'
						replace	`var'=`rawvar'	if	inrange(year,1994,2019)
						
						replace	`var'	=	`rawvar'*30.4	if	inrange(year,1995,2019)		&	`rawvar_recall'==2	//	If daily value, multiply by 30.4
						replace	`var'	=	`rawvar'*4.35	if	((inrange(year,1994,1994)	&	`rawvar_recall'==1)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==3))	//	If weekly value, multiply by 4.35
						replace	`var'	=	`rawvar'*2.17	if	((inrange(year,1994,1994)	&	`rawvar_recall'==2)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==4))	//	If two-week value, multiply by 2.17
						replace	`var'	=	`rawvar'/12	if	((inrange(year,1994,1994)		&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0			if	((inrange(year,1994,1994)		&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,7)))	//	If other or no stamp use, set it zero
						
						
						*	(1997-2007)	Their recall period is based upon "current year", so some families said "no" to "spent extra amt (this year)" have non-zero values on extra amount spent
						*	We will recode those extra values as zero if they didn't redeem FS "last month" even if they spent it "this year"
						*	Also, some raw observations have non-zero values that should not be there (ex. family ID==7231 in 2001 has 999999 amount even if "no amounte extra spent"). We recode them zero.
						replace	`var'	=	0	if	FS_rec_wth==0				&	inrange(year,1994,2019)
						replace	`var'	=	0	if	foodexp_home_extra_wth==0	&	inrange(year,1994,2019)
									
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	/*`rawvar'>0	&*/	!mi(`rawvar')	&	FS_rec_wth==1	&	foodexp_home_extra_wth==1	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inlist(`rawvar',99998,99999)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	FS_rec_wth==1	&	foodexp_home_extra_wth==1	&	(inlist(`rawvar',99998,99999)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year
						
						*	Quick check
						assert	`var'==0	if FS_rec_wth==1	&	foodexp_home_extra_wth==0
						*br	year FS_rec_wth	foodexp_home_extra_wth	`var'	if	FS_rec_wth==1	&	foodexp_home_extra_wth==0	&	`var'!=0
						
						*	Checking extra amount over year
							
							*	1994-2019
							*bys year: summ stamp_useamt_month if inrange(stamp_useamt_month,0,9999)
							
							*	1999-2007
							*bys year: summ stamp_useamt_month if inlist(stamp_cntyr_recall,0,5) & inrange(stamp_useamt_month,0,9999)
						
												
						*	Replace final imputed values						
						replace	`var_exclFS_FS'	=	`var'							if	inrange(year,1994,2019)	&	FS_rec_wth==1	//	Extra amount, if any.
						replace	`var_inclFS_FS'	=	`var_exclFS_FS'	+	FS_rec_amt	if	inrange(year,1994,2019)	&	FS_rec_wth==1	//	Extra amount, if any.
						
						*	Check time series
						bys	year:	summ 	foodexp_home_exclFS_FS	FS_rec_amt foodexp_home_inclFS_FS	if	FS_rec_wth==1
						
				
					*	For non-FS user							
						loc	var				`var_exclFS_nFS'
						loc	rawvar			foodexp_home_nostamp	//	Raw vaiable with extra amount
						loc	rawvar_recall	foodexp_home_nostamp_recall
						
						*cap	drop	`var'
						replace	`var'=`rawvar'	if	inrange(year,1994,2019)
						
						replace	`var'	=	`rawvar'*30.4	if	inrange(year,1995,2019)		&	`rawvar_recall'==2	//	If daily value, multiply by 30.4
						replace	`var'	=	`rawvar'*4.35	if	((inrange(year,1994,1994)	&	`rawvar_recall'==1)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==3))	//	If weekly value, multiply by 4.35
						replace	`var'	=	`rawvar'*2.17	if	((inrange(year,1994,1994)	&	`rawvar_recall'==2)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==4))	//	If two-week value, multiply by 2.17
						replace	`var'	=	`rawvar'/12		if	((inrange(year,1994,1994)	&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0				if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,7)))	//	If other or stamp use, set it zero
											
						replace	`var'	=	0	if	FS_rec_wth==1	&	inrange(year,1999,2007)	//	Recode zero if stamp use last month (1999-2007)
						
						*bys	year:	summ 	foodexp_home_exclFS_nFS	if	FS_rec_wth==0 & !inrange(foodexp_home_nostamp,70000,99999)
														
						*	For DK/NA/refusal (both in amount and recall period), or clear outlier (monthly food exp>100K)  I impute the monthly average from other categories and assign the mean value
						*	Assign values that are (1) original family expenditure is above 70K (outlier) and (2)
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	/*`rawvar'>0	&*/	!mi(`rawvar')	&	FS_rec_wth==0	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inrange(`rawvar',70000,99999)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	FS_rec_wth==0	&	(inrange(`rawvar',70000,99999)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year
						
						
						
						*	Replace final imputed values				
						replace	`var_inclFS_nFS'	=	`var'	if	inrange(year,1994,2019)	&	FS_rec_wth==0	//	InclFS=ExclFS for non-FS
										
						*	Check time series
						bys	year:	summ 	foodexp_home_exclFS_nFS	foodexp_home_inclFS_nFS	if	FS_rec_wth==0
					
					*	Now, combine FS and nFS variables
					replace	`var_exclFS'=	`var_exclFS_nFS'	if	FS_rec_wth==0
					replace	`var_exclFS'=	`var_exclFS_FS'		if	FS_rec_wth==1
					
					replace	`var_inclFS'=	`var_inclFS_nFS'	if	FS_rec_wth==0
					replace	`var_inclFS'=	`var_inclFS_FS'		if	FS_rec_wth==1
					
									
					
					*	Validation of imputed data
						*	Mean at-home food expenditure by year
						*sort year
						*br	year FS_rec_wth FS_rec_amt foodexp_home_exclFS_nFS	foodexp_home_inclFS_nFS	foodexp_home_exclFS_FS	foodexp_home_inclFS_FS	foodexp_home_exclFS	foodexp_home_inclFS
						bys	year:	summ	foodexp_home_exclFS	FS_rec_amt	foodexp_home_inclFS
						bys	year:	summ	FS_rec_amt	if	FS_rec_wth==1
								
					*	manually imputed data with the imputed data provided in PSID since 1999 
						*	(Excluding zero in imputing average): Mean diff $7.0, median diff $1.3, 95% of obs diff less than $4.2
						*	(Including zero in imputing average): Mean diff $6.9, median diff $1.3, 95% of obs diff less than $4.2 <= Current way
						cap drop diff_home_exclFS
						cap drop diff_home_inclFS
						cap drop foodexp_home_imp_month
						gen foodexp_home_imp_month = foodexp_home_imputed/12

						gen	diff_home=abs(foodexp_home_imp_month-foodexp_home_exclFS)

						*br year foodexp_home_stamp_recall foodexp_home_nostamp_recall FS_rec_wth FS_rec_crtyr_wth foodexp_home_inclFS foodexp_home_exclFS foodexp_home_imp_month foodexp_home_imputed diff_home if inrange(year,1999,2019)

						sum diff_home if inrange(year,1999,2019),d
						
			
			*	Eaten out
			loc	var_eatout	foodexp_out
			cap	drop	`var_eatout'
			gen	double	`var_eatout'=.	
			label	var	`var_eatout'	"Food exp eaten out (Monthly)"
			
				*	1968-1993
				*	Convert annual amount to monthly aount
				*	Important: Although "annual food expenditure" is included this period, I divide it my to make monthly food expenidture for two reasons
				*	(1) Food expenditure is separately collected based on "food stamp used last month", thus it allows more accurate matching with food stamp used "last month"
				*	(2) In the questionnaires people were asked "weekly" or "monthly" expenditure, so I assume annual food expenditure reported here is somehow imputed from those values
								
					replace	`var_eatout'=foodexp_away_annual/12	if	inrange(year,1968,1993)
							
				*	1994-2019
				*	Food exp are collected separately, between FS user and non-user.
 				******	CAUTION	****
				*	For 1999-2007, food exps are collected between FS user and non-FS user of "current year"
				*	It implies that even if FS answered "yes" to that question (so (1) and (2) are collected), that doesn't necessarily mean FU used FS last month
				******	CAUTION	****
							
					*	For FS user (the amounte here is food exp "in addition to" FS redeemed)
					local	var	foodexp_away_FS
					local	rawvar			foodexp_away_stamp
					local	rawvar_recall	foodexp_away_stamp_recall
					
					cap	drop	`var'
					gen	double	`var'	=	`rawvar'
					label	var	`var'	"Food exp eaten out (Monthly) - FS user"
					
										
						*	Make it monthly expenditure
						*	We treat "wild code" and "other" as "zero amount" for now as there are very small number of observations (except 1994 where we treat other as "yearly")					
						replace	`var'	=	`rawvar'*30.4	if	inrange(year,1995,2019)		&	`rawvar_recall'==2	//	If daily value, multiply by 30.4
						replace	`var'	=	`rawvar'*4.35	if	((inrange(year,1994,1994)	&	`rawvar_recall'==1)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==3))	//	If weekly value, multiply by 4.35
						replace	`var'	=	`rawvar'*2.17	if	((inrange(year,1994,1994)	&	`rawvar_recall'==2)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==4))	//	If two-week value, multiply by 2.17
						replace	`var'	=	`rawvar'/12		if	((inrange(year,1994,1994)	&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0				if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,7)))	//	If other or no stamp use, set it zero
						
						*	Note that for 1999-2007, families that used FS this year might not use FS last month, and vice versa
						*	The best way to do is to swap the values between _FS and _nFS.
						*	But for now, let's just assign average value depending on last month usage
						
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	FS_rec_wth==1	&	/*`rawvar'>0	&*/	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inrange(`rawvar',99998,100000)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							*	One difference between here and "at-home" is that I disabled "FS_rec_wth==1" condition, in order to assign average value to those who didn't use FS last month but used this year (so "_FS" has non-zero value)
							replace	`var'=r(mean) 	if	year==`year'	&	/*FS_rec_wth==1	&*/	(inrange(`rawvar',99998,100000)		|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year
						
						*	Quick check to see if there's any outlier causing mean value to be discontinuous
						*bys year: summ foodexp_away_FS
						
						
						
					*	For non FS user
					local	var	foodexp_away_nFS
					local	rawvar			foodexp_away_nostamp
					local	rawvar_recall	foodexp_away_nostamp_recall
					
					cap	drop	`var'
					gen	double	`var'	=	`rawvar'
					label	var	`var'	"Food exp eaten out (Monthly) - non-FS user"
								
											
						*	Make it monthly expenditure
						*	We treat "wild code" and "other" as "zero amount" for now as there are very small number of observations (except 1994 where we treat other as "yearly")					
						replace	`var'	=	`var'*30.4	if	inrange(year,1995,2019)		&	`rawvar_recall'==1	//	If daily value, multiply by 30.4
						replace	`var'	=	`var'*4.35	if	((inrange(year,1994,1994)	&	`rawvar_recall'==1)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==3))	//	If weekly value, multiply by 4.35
						replace	`var'	=	`var'*2.17	if	((inrange(year,1994,1994)	&	`rawvar_recall'==2)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==4))	//	If two-week value, multiply by 2.17
						replace	`var'	=	`var'/12	if	((inrange(year,1994,1994)	&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0			if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,1,7)))	//	If other or no stamp use, set it zero
				
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	FS_rec_wth==0	&	/*`rawvar'>0	&*/	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inrange(`rawvar',80001,100000)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							*	One difference between here and "at-home" is that I disabled "FS_rec_wth==0" condition, in order to assign average value to those who did use FS last month but didn't used this year
							*	Theoretically they shouldn't exist, but there is 1 family in 2001.
							replace	`var'=r(mean) 	if	year==`year'	&	/*FS_rec_wth==0	&*/	(inrange(`rawvar',80001,100000)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
							
					
						}	//	year	
						
						*	Quick check
						*	(2022-4-29) A few outliers exist, and expect to be winsorized later
						*bys year: summ foodexp_away_nFS
						
						
					*	Create a final variable
					
						replace	`var_eatout'	=	foodexp_away_nFS	if	inrange(year,1994,2019)	&	FS_rec_wth==0
						replace	`var_eatout'	=	foodexp_away_FS		if	inrange(year,1994,2019)	&	FS_rec_wth==1
						replace	`var_eatout'	=	foodexp_away_FS		if	inrange(year,1997,2007)	&	FS_rec_wth==0	&	stamp_usewth_crtyear==1	//	Those who didn't use FS last month, but eaten out exp was collected in "_FS" variable
						
						*count if	inrange(year,1997,2007)	&	FS_rec_wth==0	&	stamp_usewth_crtyear==1	
						*summ	foodexp_away_FS	foodexp_away_nFS	if	inrange(year,1997,2007)	&	FS_rec_wth==0	&	stamp_usewth_crtyear==1	
								
				
				*	Validate imputation by comparing PSID-imputed value
					*	(Including 0 in imputing average):	Mean diff $4.1, Median diff $0.3, 95% of obs have diff less than $2 <= current way, since many families spend zero amount.
					*	(Excluding 0 in imputing average):  Mean diff $4.3, 95% of obs have diff less than $2.1
					
					cap drop diff_away
					cap drop foodexp_away_imp_month
					gen foodexp_away_imp_month = foodexp_away_imputed/12

					gen	diff_away=abs(foodexp_away_imp_month-foodexp_out)

					br year foodexp_away_stamp_recall foodexp_away_nostamp_recall FS_rec_wth FS_rec_crtyr_wth foodexp_out  foodexp_away_imp_month foodexp_away_imputed diff_away if inrange(year,1999,2019)

					sum diff_away if inrange(year,1999,2019),d // Mean diff around $4, 95% obs with $2 difference. Pretty accurate.
					
					cap	drop	diff_away
					cap	drop	foodexp_away_imp_month
				
				
			*	Delivered
			*	Note: delivered cost is included in at-home cost prior to 1994
			*	Unlike at-home or eaten-out exp, it has dummy indicator
			loc	var_deliv	foodexp_deliv
			cap	drop	`var_deliv'
			gen	double	`var_deliv'=.	
			label	var	`var_deliv'	"Food exp delivered (Monthly)"
			
							
				*	1994-2019
				*	Food exp are collected separately, between FS user and non-user.
 				******	CAUTION	****
				*	For 1999-2007, food exps are collected between FS user and non-FS user of "current year"
				*	It implies that even if FS answered "yes" to that question (so (1) and (2) are collected), that doesn't necessarily mean FU used FS last month
				******	CAUTION	****
							
					*	For FS user 
					
					*	Whether spent money on food delivered
						loc	var	foodexp_deliv_wth_FS
						cap	drop	`var'
						gen		`var'=.
						replace	`var'=0	if	inlist(foodexp_deliv_stamp_wth,0,5,8,9)
						replace	`var'=1	if	inlist(foodexp_deliv_stamp_wth,1)
						label	value	`var'	yes1no0
						label var	`var'	"=1 if spent on food delivery (FS)"
									
						local	var	foodexp_deliv_FS
						local	rawvar			foodexp_deliv_stamp
						local	rawvar_recall	foodexp_deliv_stamp_recall
						
						cap	drop	`var'
						gen	double	`var'	=	`rawvar'
						label	var	`var'	"Food exp delivered (Monthly) - FS user"
									
						*	Make it monthly expenditure
						*	We treat "wild code" and "other" as "zero amount" for now as there are very small number of observations (except 1994 where we treat other as "yearly")					
						replace	`var'	=	`rawvar'*30.4	if	inrange(year,1995,2019)		&	`rawvar_recall'==2	//	If daily value, multiply by 30.4
						replace	`var'	=	`rawvar'*4.35	if	((inrange(year,1994,1994)	&	`rawvar_recall'==1)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==3))	//	If weekly value, multiply by 4.35
						replace	`var'	=	`rawvar'*2.17	if	((inrange(year,1994,1994)	&	`rawvar_recall'==2)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==4))	//	If two-week value, multiply by 2.17
						replace	`var'	=	`rawvar'/12		if	((inrange(year,1994,1994)	&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0				if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,7)))	//	If other or no stamp use, set it zero
					
						*	Confirm that delivered food exp is zero if family said "no"
						assert	`var'==0	if	foodexp_deliv_wth_FS==0	
	
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	/*FS_rec_wth==1	&*/	foodexp_deliv_wth_FS==1	&	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inrange(`rawvar',99998,100000)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	/*FS_rec_wth==1	&*/	foodexp_deliv_wth_FS==1	&	(inrange(`rawvar',99998,100000)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year
						
								
						*	Quick check to see if there's any outlier causing mean value to be discontinuous
						bys year: summ foodexp_deliv_FS
						
						
					*	For non FS user
					
						*	Whether spent money on food delivered
						loc	var	foodexp_deliv_wth_nFS

						cap	drop	`var'
						gen		`var'=.
						replace	`var'=0	if	inlist(foodexp_deliv_nostamp_wth,0,5,8,9)
						replace	`var'=1	if	inlist(foodexp_deliv_nostamp_wth,1)
						label	value	`var'	yes1no0
						label var	`var'	"=1 if spent on food delivery (non-FS)"
						
						local	var	foodexp_deliv_nFS
						local	rawvar			foodexp_deliv_nostamp
						local	rawvar_recall	foodexp_deliv_nostamp_recall
						
						cap	drop	`var'
						gen	double	`var'	=	`rawvar'
						label	var	`var'	"Food exp delivered (Monthly) - non-FS user"
									
											
						*	Make it monthly expenditure
						*	We treat "wild code" and "other" as "zero amount" for now as there are very small number of observations (except 1994 where we treat other as "yearly")					
						replace	`var'	=	`var'*30.4	if	inrange(year,1995,2019)		&	`rawvar_recall'==1	//	If daily value, multiply by 30.4
						replace	`var'	=	`var'*4.35	if	((inrange(year,1994,1994)	&	`rawvar_recall'==1)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==3))	//	If weekly value, multiply by 4.35
						replace	`var'	=	`var'*2.17	if	((inrange(year,1994,1994)	&	`rawvar_recall'==2)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==4))	//	If two-week value, multiply by 2.17
						replace	`var'	=	`var'/12	if	((inrange(year,1994,1994)	&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0			if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,7)))	//	If other or no stamp use, set it zero
						
						*	There are very few obs (6 obs as of 2022-04-30) having non-zero food delivered amount even when didn't way "yes" to the amount. Will recode them as zero.
						replace	`var'=0	if	foodexp_deliv_wth_nFS==0	
												
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						*	(2023-06-22): There is 1 obs (year==2007, ID=1988030) whose "weekly" eaten out expenditure was 80,000. I think it is mistake, but it was somehow not properly winsorized later. Need to fix it.
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	/*FS_rec_wth==0	&*/	foodexp_deliv_wth_nFS==1	&	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inrange(`rawvar',99998,100000)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	/*FS_rec_wth==0	&*/	foodexp_deliv_wth_nFS==1	&	(inrange(`rawvar',99998,100000)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
							
					
						}	//	year	
						
						*	Quick check to see if there's any outlier causing mean value to be discontinuous
						bys year: summ	foodexp_deliv_nFS
						
						
					*	Create a final variable
						
						replace	`var_deliv'	=	foodexp_deliv_nFS	if	inrange(year,1994,2019)	&	FS_rec_wth==0
						replace	`var_deliv'	=	foodexp_deliv_FS	if	inrange(year,1994,2019)	&	FS_rec_wth==1
						replace	`var_deliv'	=	foodexp_deliv_FS	if	inrange(year,1997,2007)	&	FS_rec_wth==0	&	stamp_usewth_crtyear==1	//	Those who didn't use FS last month, but delivered exp was collected in "_FS" variable
						
						/* Outdated
						*	Received FS (FS amount + extra amount spent)
						replace	`var_deliv'	=	foodexp_deliv_FS	if	FS_rec_wth==1		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))
						replace	`var_deliv'	=	foodexp_deliv_FS	if	FS_rec_crtyr_wth==1	&	inrange(year,1999,2007)
						
						*	Didn't receive FS	(Just food exp)
						replace	`var_deliv'	=	foodexp_deliv_NoFS	if	FS_rec_wth==0		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))
						replace	`var_deliv'	=	foodexp_deliv_NoFS	if	FS_rec_crtyr_wth==0	&	inrange(year,1999,2007)
						*/
			
					*	Validate imputation by comparing PSID-imputed value
									
					cap drop diff_deliv
					cap drop foodexp_deliv_imp_month
					gen foodexp_deliv_imp_month = foodexp_deliv_imputed/12

					gen	diff_deliv=abs(foodexp_deliv_imp_month-foodexp_deliv)

					sum diff_deliv if inrange(year,1999,2019),d // Mean diff around $0.14, 90% perfect match, 95% less than 0.25% 

					cap	drop	diff_deliv
					cap	drop	foodexp_deliv_imp_month
			
			*	Now, aggregate food expenditures - at home, eaten out and delivered - to calculate total monthly food expenditures
			loc	var	foodexp_tot_exclFS
			capture	drop	`var'
			egen	`var'=rowtotal(foodexp_home_exclFS foodexp_out foodexp_deliv)
			replace	`var'=.	if	seqnum==0	//	Replace it as missing if Ind didn't exist (should be, as raw exp variables are also missing)
			*replace	`var'=.	if	live_in_FU==0	//	Replace it as missing if not living in FU (ex. institution, moved out, etc.)
			lab	var	`var'	"Total monthly food exp (FS excl)"
			
				*	Validation of aggregated cost
					cap drop diff_foodexp_tot
					cap drop foodexp_tot_imp_month
					gen foodexp_tot_imp_month = foodexp_tot_imputed/12

					gen	diff_foodexp_tot=abs(foodexp_tot_imp_month-foodexp_tot_exclFS)

					summ foodexp_tot_exclFS if inrange(year,1999,2019)	//	Average total food exp is $585.7
					sum diff_foodexp_tot if inrange(year,1999,2019),d // Mean diff $11.2 (2% of mean value above), median $1.83 (0.3% of average value), 95% less than $6 (1% of avg value above)
					
					cap	drop	diff_foodexp_tot
					cap	drop	foodexp_tot_imp_month
			
			loc	var	foodexp_tot_inclFS
			capture	drop	`var'
			egen	`var'=rowtotal(foodexp_home_inclFS foodexp_out foodexp_deliv)
			replace	`var'=.	if	seqnum==0	//	Replace it as missing if Ind didn't exist (should be, as raw exp variables are also missing)
			*replace	`var'=.	if	live_in_FU==0	//	Replace it as missing if not living in FU (ex. institution, moved out, etc.)
			lab	var	`var'	"Total monthly food exp (FS incl)"	
			
						
			*	Divide total exp by family number to get per capita value, and then divide by thousand to make unit as thousand
				
				*	Food exp (w/o FS)
				loc	var	foodexp_tot_exclFS
				cap	drop	`var'_pc
				gen		double	`var'_pc	=	`var'/famnum
				gen		double	`var'_pc_th	=	(`var'/famnum)/1000
				label	var	`var'_pc	"Monthly food exp per capita (FS excl)"
				label	var	`var'_pc_th	"Monthly food exp per capita (FS excl) (K)"
				
				*	Food exp (with FS)
				loc	var	foodexp_tot_inclFS
				cap	drop	`var'_pc
				gen		double	`var'_pc	=	`var'/famnum
				gen		double	`var'_pc_th	=	(`var'/famnum)/1000
				label	var	`var'_pc	"Monthly food exp per capita (FS incl)"
				label	var	`var'_pc_th	"Monthly food exp per capita (FS incl) (K)"
			

			*	Construct a indicator whether total food exp (per capita) exceeds TFP (per capita)
			*	Make sure to consider only non-missing TFP observations, which are missing for those who are not living together (seq.num outside 1-20). Otherwise indicators will tag those who do not live together.
			*	Note: These indicators are exactly the same when using "per capita" value instead
			loc	var	overTFP_inclFS
			cap drop `var'
			gen		`var'=.
			replace	`var'=0	if	!mi(foodexp_W_TFP)	&	!mi(foodexp_tot_inclFS)	&	foodexp_W_TFP>foodexp_tot_inclFS
			replace	`var'=1	if	!mi(foodexp_W_TFP)	&	!mi(foodexp_tot_inclFS)	&	foodexp_W_TFP<=foodexp_tot_inclFS
			label	value	`var'	yes1no0
			label var	`var'	"Food exp(with FS) exceeds TFP cost"

			loc	var	overTFP_exclFS
			cap drop `var'
			gen		`var'=.
			replace	`var'=0	if	!mi(foodexp_W_TFP)	&	!mi(foodexp_tot_exclFS)	&	foodexp_W_TFP>foodexp_tot_exclFS
			replace	`var'=1	if	!mi(foodexp_W_TFP)	&	!mi(foodexp_tot_exclFS)	&	foodexp_W_TFP<=foodexp_tot_exclFS
			label	value	`var'	yes1no0
			label var	`var'	"Food exp(w/o FS) exceeds TFP cost"
			
			br year foodexp_W_TFP	foodexp_tot_exclFS	foodexp_tot_inclFS	if	inrange(foodexp_W_TFP,foodexp_tot_exclFS,foodexp_tot_inclFS)	
			
			
					
		*	Winsorize top 1% values of per capita values for every year (except TFP)
		
		local	pcvars	fam_income_pc ln_fam_income_pc foodexp_tot_exclFS_pc foodexp_tot_exclFS_pc_th foodexp_tot_inclFS_pc foodexp_tot_inclFS_pc_th	// fam_income_pc_real foodexp_tot_exclFS_pc_real foodexp_tot_inclFS_pc_real
		local	years	1995	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015
		foreach	var	of	local	pcvars	{
			
			cap	drop	`var'_wins
			cap	drop	outlier_`var'
			gen	double	`var'_wins=`var'
			
			foreach	year	of	local	years	{
				
				di "var is `var', year is `year'"
				qui	summarize	`var' 				if	year==`year' & seqnum!=0,d
				replace 	`var'_wins=r(p99)	if	year==`year' & seqnum!=0	&	!mi(`var')	& `var'>=r(p99)
				
			}
			
			order	`var'_wins, after(`var')
			drop	`var'
			rename	`var'_wins	`var'
			
		}
		
		*	Generate polynomial degree of per capita expenditure up to 3
		forval	i=1/3	{
			
			cap	drop	foodexp_tot_exclFS_pc_`i'
			gen	double	foodexp_tot_exclFS_pc_`i'=(foodexp_tot_exclFS_pc)^`i'
			cap	drop	foodexp_tot_inclFS_pc_`i'
			gen	double	foodexp_tot_inclFS_pc_`i'=(foodexp_tot_inclFS_pc)^`i'
			*gen	double	foodexp_tot_exclFS_pc_th_`i'=(foodexp_tot_exclFS_pc_th)^`i'
			
			label	var	foodexp_tot_exclFS_pc_`i'	"Total monthly food exp pc (FS excl) - `i'th order"
			label	var	foodexp_tot_inclFS_pc_`i'	"Total monthly food exp pc (FS incl) - `i'th order"
			
		}
			
		
		*	Create constant dollars of monetary variables  (ex. food exp, TFP)
		*	Baseline CPI is 2019 Jan (100) 
		qui	ds	fam_income_pc	FS_rec_amt	FS_rec_amt_capita foodexp_home_inclFS foodexp_home_exclFS  foodexp_out foodexp_deliv foodexp_tot_exclFS foodexp_tot_inclFS ///
				TFP_monthly_cost foodexp_W_TFP foodexp_W_TFP_pc	foodexp_W_TFP_pc_th	TFP_monthly_cost_COLI foodexp_W_TFP_COLI foodexp_W_TFP_pc_COLI foodexp_W_TFP_pc_th_COLI	///
				foodexp_tot_exclFS_pc foodexp_tot_inclFS_pc	foodexp_tot_exclFS_pc_? foodexp_tot_inclFS_pc_?
		global	money_vars_current	`r(varlist)'
		
		foreach	var of global money_vars_current	{
		    
			cap	drop	`var'_real
			gen	double	`var'_real	=	`var'* (100/CPI)
			
		}
		
		*	Generate log and IHS of family income per capita (real)
		*	NOTE: I can later use inverse hyperbolic transformation instead.
		cap	drop	ln_fam_income_pc_real
		gen			ln_fam_income_pc_real	=	ln(fam_income_pc_real)
		cap	drop	IHS_fam_income_pc_real
		gen			IHS_fam_income_pc_real	=	asinh(fam_income_pc_real)
			
		ds	*_real
		global	money_vars_real	`r(varlist)'
		global	money_vars	${money_vars_current}	${money_vars_real}
		
		*	Normalized Money Expenditure (NME) - ratio of food expenditure to TFP cost
		*	(2023-06-22) For some reason, HH-level food expenditure is NOT properly winsorized above. So we use "per capita" expenditure which is technically identical but somehow generates more reasonable values (thus I assue properly winsorized)
		loc	var	NME
		cap	drop	`var'
		gen	`var'	=	foodexp_tot_inclFS_pc	/ foodexp_W_TFP_pc
		lab	var	`var'	"Normalized Money Expenditure"
		
			*	Dummy if NME<1 (i.e. spend less than TFP cost)
			loc	var	NME_below_1
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0	if	!mi(NME)	&	NME>=1
			replace	`var'=1	if	!mi(NME)	&	NME<1
			lab	var	`var'	"=1 if NME<1 (spend less than TFP cost)"
		
		
		di "${money_vars_real}"
		
		*	Create lagged variables needed
		*	(2021-11-27) I start with monetary variables (current, real)
			
			*	Set it as survey panel data
					   
			svyset	sampcls [pweight=wgt_long_fam], strata(sampstr)	singleunit(scaled)
				
				*	Generate time variable which increases by 1 over wave ("year" ") // can be used to construct panel data (we can't directly use "year" because PSID was collected bieenially since 1997, thus data will treat it as gap period)
				cap	drop	time
				gen		time	=	year-1997
				replace	time	=	year-1997
			xtset x11101ll year,	delta(1)
		
			*	Create lagged vars
			*	(2022-5-4) we will use 2nd-lag as default lagged food expenditure due to data restriction
				*	Note that under AR(1) process, y_t = a*y_t-1 = a^2 * y_t-2
			foreach	var	of	global	money_vars	{
				
				cap	drop	l2_`var'
				cap	drop	l4_`var'
				*gen	double	l1_`var'	=	l.`var'		if	year<=1997	//	When PSID was collected annually
				*replace		l1_`var'	=	l2.`var'	if	year>=1999	//	When PSID was collected bieenially
				gen	double	l2_`var'	=	l2.`var'		
				gen	double	l4_`var'	=	l4.`var'
				
			}
			
					
			
				*	Rescale large variable
			cap	drop	l2_foodexp_tot_inclFS_pc_2_real_K
			gen			l2_foodexp_inclFS_pc_2_real_K	=	l2_foodexp_tot_inclFS_pc_2_real / 1000
			
			
			*	Create lagged dummes for SNAP status
			sort	x11101ll	year
			foreach	lag	in	2	4	6	8	10	{
				
				cap	drop	l`lag'_FS_rec_wth
				gen		l`lag'_FS_rec_wth	=	l`lag'.FS_rec_wth
				lab	var	l`lag'_FS_rec_wth	"SNAP received `lag' years ago"
				
			
			}
			
			*	Drop 1995 dta, since its food expenditure exists as lagged food exp in 1997
			drop	if	year==1995
			
			
			*	Create "observational-level" dummies of culumative SNAP redemptions over 5-year (t-4, t-2, t)
			*	NOTE: This is an observational-level variable, NOT individual-level variable
				*	Suppose an individual's SNAP status over 9 years (t-4, t-2, t, t+2, t+4) is (0,0,1,0,1)
				*	Then this variable's value will be (1,1,2) in (t-4, t-2 and t)
			*	I construct "individual-level" SNAP status over the 5-year after the "first" SNAP participation later.
				
				loc	var	SNAP_cum_status5
				cap	drop	`var'	//	SNAP_for_cum
				egen	`var'	=	group(FS_rec_wth	l2_FS_rec_wth	l4_FS_rec_wth)
				lab	var	`var'	"Cumulative SNAP status last 5-year"
				
				assert	`var'==1	if	l4_FS_rec_wth==0	&	l2_FS_rec_wth==0	&	FS_rec_wth==0
				assert	`var'==2	if	l4_FS_rec_wth==1	&	l2_FS_rec_wth==0	&	FS_rec_wth==0
				assert	`var'==3	if	l4_FS_rec_wth==0	&	l2_FS_rec_wth==1	&	FS_rec_wth==0
				assert	`var'==4	if	l4_FS_rec_wth==1	&	l2_FS_rec_wth==1	&	FS_rec_wth==0
				assert	`var'==5	if	l4_FS_rec_wth==0	&	l2_FS_rec_wth==0	&	FS_rec_wth==1
				assert	`var'==6	if	l4_FS_rec_wth==1	&	l2_FS_rec_wth==0	&	FS_rec_wth==1
				assert	`var'==7	if	l4_FS_rec_wth==0	&	l2_FS_rec_wth==1	&	FS_rec_wth==1
				assert	`var'==8	if	l4_FS_rec_wth==1	&	l2_FS_rec_wth==1	&	FS_rec_wth==1
								
				lab	define	`var'	1	"Never"		2	"t-4 only"			3	"t-2 only"			4	"t-4 and t-2 only"	///
											5	"t only"	6	"t-4 and t only"	7	"t-2 and t only"	8	"t-4 t-2 and t", replace
				lab	val	`var'	`var'
				lab	var	`var'	"SNAP status last 5 years"
					
				tab	`var',	gen(`var')
				rename	`var'?	(SNAP_000	SNAP_100	SNAP_010	SNAP_110	SNAP_001	SNAP_101	SNAP_011	SNAP_111)
				
				lab	var	SNAP_000	"SNAP status 5 years: Never"
				lab	var	SNAP_100	"SNAP status 5 years: t-4 only"
				lab	var	SNAP_010	"SNAP status 5 years: t-2 only"
				lab	var	SNAP_110	"SNAP status 5 years: t-4 and t-2 only"
				lab	var	SNAP_001	"SNAP status 5 years: t only"
				lab	var	SNAP_101	"SNAP status 5 years: t-4 and t only"
				lab	var	SNAP_011	"SNAP status 5 years: t-2 and t only"
				lab	var	SNAP_111	"SNAP status 5 years: t-4 t-2 and t"
				
				
				
				loc	var	SNAP_cum_status7
				cap	drop	`var'	//	SNAP_for_cum
				egen	`var'	=	group(FS_rec_wth	l2_FS_rec_wth	l4_FS_rec_wth	l6_FS_rec_wth)
				lab	var	`var'	"Cumulative SNAP status last 7-year"
				
				loc	var	SNAP_cum_status9
				cap	drop	`var'	//	SNAP_for_cum
				egen	`var'	=	group(FS_rec_wth	l2_FS_rec_wth	l4_FS_rec_wth	l6_FS_rec_wth	l8_FS_rec_wth)
				lab	var	`var'	"Cumulative SNAP status last 7-year"
				
			
			*	Aggregate cumulative dummies by the number of SNAP redemptions over 5-year
			*	NOTE: This is an observational-level.
			loc	var		SNAP_cum_fre5
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0		if	inlist(1,SNAP_000)
			replace	`var'=1		if	inlist(1,SNAP_100,SNAP_010,SNAP_001)
			replace	`var'=2		if	inlist(1,SNAP_110,SNAP_011,SNAP_101)
			replace	`var'=3		if	inlist(1,SNAP_111)
			
			lab	var	`var'		"\# SNAP participation last 5 years"
			
			loc	var	SNAP_cum_fre7
			cap	drop	`var'
			egen	`var'=	anycount(FS_rec_wth	l2_FS_rec_wth	l4_FS_rec_wth	l6_FS_rec_wth), values(1)
			lab	var	`var'		"\# SNAP participation last 7 years"
			
			loc	var	SNAP_cum_fre9
			cap	drop	`var'
			egen	`var'=	anycount(FS_rec_wth	l2_FS_rec_wth	l4_FS_rec_wth	l6_FS_rec_wth	l8_FS_rec_wth), values(1)
			lab	var	`var'		"\# SNAP participation last 9 years"
			
	
		
		*	(2023-08-24) Construct Cumulative SNAP usage variables, (used for event study plot, intensive/extensive marginal effect, etc.)
				
			*	For event study, we need to create a standardized time
			*	Since there are multiple treatments occuring multiple periods, it is difficult to standardize treatment period.
				*	For example, if a household is treated in 1997 and 1999, then relative treatment period cannot be standarized (which on should be t=0?)
			*	There are two ways to deal with
				*	(1) Limit the sample to whose who "never treated" and "treated only once" where treatment time can be standarzied.
				*	(2) Standardize based on the "first treatment"
			*	I will do the second method, using "tsspell" command
			
			*	Total # of SNAP participation over time (it will be used for analyses by group)
			*	NOTE: Exclude 1995, since 1995 is only for "lagged food expenditure" in constructing PFS
			loc	var	SNAP_cumul_all
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	total(FS_rec_wth)	if	inrange(year,1997,2013)
			lab	var	`var'	"\# of SNAP participation over the entire period"
			
						
			* Construct the spells of SNAP redemption using "tsspell" command
			*	NOTE: "replace" option does not work when the variable doesn't exist, so we manually drop them
			cap	drop	SNAP_seq
			cap	drop	SNAP_spell
			cap	drop	SNAP_end	
			tsspell, cond(year>=1997 & FS_rec_wth==1) seq(SNAP_seq) spell(SNAP_spell) end(SNAP_end) 
			lab	var	SNAP_seq	"SNAP spell length"
			lab	var	SNAP_spell	"SNAP spell indicator"
			lab	var	SNAP_end	"SNAP spell end period"
			
			*	Construct standardized year T when T=-4 as "first SNAP participation" (i.e. T=0 means "first SNAP in 4 years ago")
			*	The reason for not standardizing T when T=0 as "the year first received SNAP" is because, we constructed FSD variables based on PFS status in past years (ex. t-4, t-2 and t for 5-year window)
				*	Since I want to plot event study design and effects on SNAP participation based on SNAP redemption status over the same period (t-4, t-2 and t), we need to standardize based on SNAP redemption at t-4
				*	If we standardize based on first SNAP participation at t=0, there's no SNAP status in t=-2 and t=-4 (since first got SNAP in t=0).
			*	Note: the code below excludes those who are "never treated", since they do not have any year of SNAP participation
			
			loc	var		year_SNAP_std
			cap	drop	`var'
			gen	`var'=.

			
			replace	`var'=-4	if	l0.SNAP_seq==1	&	l0.SNAP_spell==1	//	T=-4: year first received SNAP
			replace	`var'=-2	if	l2.SNAP_seq==1	&	l2.SNAP_spell==1	//	T=-2: 2 years after first received SNAP
			replace	`var'=0		if	l4.SNAP_seq==1	&	l4.SNAP_spell==1	//	T=0:  4 years after first received SNAP
			
			replace	`var'=-6	if	f2.SNAP_seq==1	&	f2.SNAP_spell==1	//	T=-6: 2 years prior to first received SNAP
			replace	`var'=-8	if	f4.SNAP_seq==1	&	f4.SNAP_spell==1	//	T=-8: 4 years prior to first received SNAP, standardize at T=-8
			
			
			lab	var	`var'	"Standardized year (=-4 when first received SNAP)"
			
			
			*	Create dummies of standardized years
			cap	drop	year_SNAP_std?
			cap	drop	year_SNAP_std_??
			tab	year_SNAP_std, gen(year_SNAP_std)	
			rename	year_SNAP_std?	(year_SNAP_std_l8	year_SNAP_std_l6	year_SNAP_std_l4	year_SNAP_std_l2	year_SNAP_std_l0)
			
			lab	var	year_SNAP_std_l8	"t-4"	//	4 years before the first SNAP (T=-8)
			lab	var	year_SNAP_std_l6	"t-2"	//	2 years before the first SNAP (T=-6)
			lab	var	year_SNAP_std_l4	"t"		//	Year of the first SNAP (T=-4)
			lab	var	year_SNAP_std_l2	"t+2"	//	2 years after the first SNAP (T=-2)
			lab	var	year_SNAP_std_l0	"t+4"	//	4 years after the first SNAP (T=0)
			
			
			*	Generate interaction variable (SNAP x relative time duumies)
			*	Not sure I am gonna use it...
			/*
			forval	t=1/7	{
			    
				cap	drop	year_SNAP_int`t'
				gen		year_SNAP_int`t'	=	year_SNAP_std`t' & FS_rec_wth
				replace	year_SNAP_int`t'=.	if	mi(year_SNAP_standard`t')
				lab	var	year_SNAP_int`t'	"SNAP x relative time dummy"
			}
			*/
			
			*	Set sample of balanced households (no-missing value from 4-year ago, 2-year ago, 0-year, 2-year later and 4-year later)
				*	Time period conditioned upon should be equal to the time period used to construct the standardized year.
			*	Remember that FSD variables are constructed based on 4-year ago, 2-year ago and 0-year.
				cap	drop	num_nonmiss_event
				cap	drop	event_study_sample
				gen	num_nonmiss_event	=	1	if	!mi(l4.year_SNAP_std)	&	!mi(l2.year_SNAP_std)	&	!mi(l0.year_SNAP_std)	&	!mi(f2.year_SNAP_std)	&	!mi(f4.year_SNAP_std)	//	Tag balanced individual
				bys	x11101ll:	egen	event_study_sample	=	max(num_nonmiss_event)	if	!mi(year_SNAP_std)
				lab	var	event_study_sample	"Balanced event study sample (-6 -4 -2 0 2)"
				drop	num_nonmiss_event
		
			*	Cateogrization of individuals based on the # of cumulative SNAP redemption over 5 years "after" the first redemption (including the first one)
				*	This variable is needed to categorize "a group of" observations into subgroup.
					*	(1) Those who redeemped SNAP only once over the 5-year period
					*	(2) Those who only redeemd SNAP twice over the 5-year period
					*	(3) Those who got SNAP all 3 periods over the 5-year period (t-4, t-2, t)
				*	It is to see how PFS change differently over time by different intensity of the fist SNAP exposure.
				*	NOTE: I could construct it at individual-level since I limit to 5 years since the "first" SNAP exposure. I cannot create individual-level if I use "any" SNAP exposure
				loc	var	SNAP_cum_fre_1st
				cap	drop	`var'	
				gen	`var'=.
				
					*	(0) Those who never participated in SNAP: should be zero (no SNAP participation over 3 period)
					replace	`var'=0	if	year_SNAP_std==.	&	FS_rec_wth==0		&	f2.FS_rec_wth==0	&	f4.FS_rec_wth==0					
					
					*	(1) Those who participated only once over 5-year period, since the first participation.
					replace	`var'=1	if	year_SNAP_std==-8	&	f6.FS_rec_wth==0	&	f8.FS_rec_wth==0	//	(t-8)
					replace	`var'=1	if	year_SNAP_std==-6	&	f4.FS_rec_wth==0	&	f6.FS_rec_wth==0	//	(t-6)
					replace	`var'=1	if	year_SNAP_std==-4	&	f2.FS_rec_wth==0	&	f4.FS_rec_wth==0	//	(t-4)
					replace	`var'=1	if	year_SNAP_std==-2	&	FS_rec_wth==0		&	f2.FS_rec_wth==0	//	(t-2) 
					replace	`var'=1	if	year_SNAP_std==0	&	l2.FS_rec_wth==0	&	FS_rec_wth==0		//	t
										
					*	(2)	1 more SNAP redemption after the first redemption.
					replace	`var'=2	if	year_SNAP_std==-8	&	((f6.FS_rec_wth==1	&	f8.FS_rec_wth==0)	|	(f6.FS_rec_wth==0	&	f8.FS_rec_wth==1))	//	(t-8)
					replace	`var'=2	if	year_SNAP_std==-6	&	((f4.FS_rec_wth==1	&	f6.FS_rec_wth==0)	|	(f4.FS_rec_wth==0	&	f6.FS_rec_wth==1))	//	(t-6)
					replace	`var'=2	if	year_SNAP_std==-4	&	((f2.FS_rec_wth==1	&	f4.FS_rec_wth==0)	|	(f2.FS_rec_wth==0	&	f4.FS_rec_wth==1))	//	(t-4)
					replace	`var'=2	if	year_SNAP_std==-2	&	((FS_rec_wth==1		&	f2.FS_rec_wth==0)	|	(FS_rec_wth==0		&	f2.FS_rec_wth==1))	//	(t-2)
					replace	`var'=2	if	year_SNAP_std==0	&	((l2.FS_rec_wth==1	&	FS_rec_wth==0)		|	(l2.FS_rec_wth==0	&	FS_rec_wth==1))	//	(t)
					
					*	(3) All 3 redemption over the five-year period
					replace	`var'=3	if	year_SNAP_std==-8	&	f6.FS_rec_wth==1	&	f8.FS_rec_wth==1	//	(t-8)
					replace	`var'=3	if	year_SNAP_std==-6	&	f4.FS_rec_wth==1	&	f6.FS_rec_wth==1	//	(t-6)
					replace	`var'=3	if	year_SNAP_std==-4	&	f2.FS_rec_wth==1	&	f4.FS_rec_wth==1	//	(t-4)
					replace	`var'=3	if	year_SNAP_std==-2	&	FS_rec_wth==1		&	f2.FS_rec_wth==1	//	(t-2)
					replace	`var'=3	if	year_SNAP_std==0	&	l2.FS_rec_wth==1	&	FS_rec_wth==1	//	(t)
					
					lab	var	`var'	"\# of cumulative SNAP redemption since the first redemption over 5-year"
					
					lab	define	`var'	0	"N/A - No SNAP at all"	1	"Once"	2	"Twice"		3	"Three times", replace
					lab	val	`var'	`var'
			
			
			*	Tabluate cumulative SNAP frequency over event study sample
				tab	SNAP_cum_fre_1st	if	event_study_sample==1, m
				
				br	x11101ll	year	FS_rec_wth	year_SNAP_std	year_SNAP_std_??	if	event_study_sample
		

		*	Check discontinuity of final variables by checking weighted average
		*use	"${SNAP_dtInt}/SNAP_long_const", clear
		preserve
			collapse (mean) FS_rec_wth foodexp_tot_exclFS foodexp_tot_inclFS foodexp_tot_exclFS_pc foodexp_tot_inclFS_pc foodexp_W_TFP_pc overTFP_exclFS overTFP_inclFS [pw=wgt_long_fam], by(year)
			tempfile	foodvar_check
			save		`foodvar_check'
		restore
		preserve
			collapse (mean) FS_rec_amt if FS_rec_wth==1 [pw=wgt_long_fam], by(year)
			merge	1:1	year	using	`foodvar_check', nogen assert(3)
			
			lab	var	foodexp_tot_exclFS		"Food exp (w/o FS)"
			lab	var	foodexp_tot_exclFS_pc	"Food exp per capita (w/o FS)"
			lab	var	foodexp_tot_inclFS_pc	"Food exp per capita (with FS)"
			lab	var	FS_rec_amt	"FS benefit ($)"
			
			graph	twoway	(line foodexp_tot_exclFS year, /*lpattern(dash)*/ xaxis(1 2) yaxis(1))	///
							/*(line TFP_monthly_cost	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)) */ 	///
							(line FS_rec_amt	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)),  ///
							xline( 1999 2007, axis(1) lpattern(dot)) xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
							xtitle(Year)	xtitle("", axis(2)) /* title(Monthly Food Expenditure and FS Benefit)*/	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_FSamt_byyear, replace)
			
				
			graph	export	"${SNAP_outRaw}/foodexp_FSamt_byyear_9513.png", replace
			graph	close	
		restore
			/*
			graph	twoway	(line foodexp_tot_exclFS_pc year, lpattern(dash) xaxis(1 2) yaxis(1))	///
						(line foodexp_tot_inclFS_pc	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)),  ///
						xline(1974 1996 2009 2020, axis(1)) xlabel(1974 "Nationwide FSP" 1996 "Welfare Reform" 2009 "ARRA" 2020 "COVID", axis(2))	///
						xtitle(Fiscal Year)	xtitle("", axis(2))  /*title(Program Summary)*/	bgcolor(white)	graphregion(color(white)) note(Source: USDA & BLS)	name(SNAP_summary, replace)
		
			
			*/
		
		
		*	Save cleaned
		
			*	Make dta
			notes	drop _dta
			notes:	SNAP_cleaned_long_9513 / created by `name_do' - `c(username)' - `c(current_date)' ///
					Cleaned PSID data with external data
				
			* Git branch info
			stgit9 
			notes : SNAP_cleaned_long / Git branch `r(branch)'; commit `r(sha)'.

			* Sort, order and save dataset
			/*
			loc	IDvars		HHID_survey HHID_old_Feb22
			loc	Geovars		District Village CDCID Masjid
			loc	HHvars		hhhead_gender hhhead_name father_spouse_name relationship_hhhead
			loc	PRAvars		SNo-PRA_remarks PRA_multiple_results
			loc	eligvars	TUP_eligible_initial TUP_eligible_Feb22 TUP_eligible_Mar10
			loc	surveyvars	survey_done_Mar10 survey_sample
			
			sort	`IDvars'	`Geovars'	`HHvars'	`PRAvars'	`eligvars'	`surveyvars'
			order	`IDvars'	`Geovars'	`HHvars'	`PRAvars'	`eligvars'	`surveyvars'
			*/
			
			/*
			* Save log
			cap file		close _all
			cap log			close
			copy			"${bl_do_cleaning}/logs/`name_do'.smcl" ///
							"${bl_do_cleaning}/logs/archive/`name_do' - `c(current_date)' - `c(username)'.smcl", replace
			*/
			
			sort	x11101ll	year
			qui		compress
			save	"${SNAP_dtInt}/SNAP_cleaned_long_9713.dta", replace
		
		* Exit	
		exit
	
		
		
	}

