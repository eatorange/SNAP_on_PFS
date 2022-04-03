
**	Note: This do-file contain panel-data construction code which no longer used as of 2022/4/1
**	I leave this file only as a back-up.

	*	Create panel structure
	if	`cr_panel'==1	{
		
		*	Merge ID with unique vars as well as other survey variables needed for panel data creation
		use	"${SNAP_dtInt}/Ind_vars/ID", clear
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/unique_vars.dta",	nogen	assert(3)
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/wgt_long_ind.dta",	nogen	assert(3)	//	Individual weight
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Fam_vars/wgt_long_fam.dta",	nogen	assert(3)	//	Family weight
		
		*	Merge individual variables
		cd "${SNAP_dtInt}/Ind_vars"
		
		global	varlist_ind	age_ind	/*wgt_long_ind*/	relrp	origfu_id	noresp_why
		
		foreach	var	of	global	varlist_ind	{
			
			merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(2 3)	keep(3)	//	Longitudinal weight
				
		}
			
		
		
		*	Construct additional variable
				
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
		
		*	Generate a 1968 sequence number variable from person number variable
		**	Note: 1968 sequence number is used to determine whether an individual was head/RP in 1968 or not. Don't use it for other purposes, unless it is not consistent with other sequence variables.
		**	It Should be dropped after use to avoid confusion.		
		gen		xsqnr_1968	=	pn
		replace	xsqnr_1968	=	0	if	!inrange(xsqnr_1968,1,20)	
		order	xsqnr_1968,	before(xsqnr_1969)
		
		*	Drop years outside study sample	
			drop	*1973	*1988	*1989	//	Years without food expenditures (1973, 1988, 1989)
			drop	*1968	*1969	*1970	*1971	//	Years which I cannot separate FS amount from food expenditure
			drop	*1972	*1974	//	Years without previous FS status
			
		*	Drop subsamples we won't use in this study
			drop	if	sample_source==5	//	Latino sample
			drop	if	sample_source==4	//	2017 refresher
			
		
		*	Set globals
		qui	ds	x11102_1975-x11102_2019
		global	hhid_all	`r(varlist)'
		
		qui	ds	xsqnr_1975-xsqnr_2019
		global	seqnum_all	`r(varlist)'

		
		*	Create a panel structre
		*	This study covers 50-year period with different family composition changes, thus we need to carefully consider that.
		*	First, we create a individual-level aggregated data using "psid use command" with necessary variables to further investigate family change.
	
				
		*	Generate a household id which uniquely identifies a combination of household wave IDs.
		**	Note: This is a tepmorary variable where it would have duplicate household ids after applying family panel structure (this is why I named this variabe as "1st")
		cap drop hhid_agg_1st	
		egen hhid_agg_1st = group(x11102_1975-x11102_2019), missing
		
		
		*	First, we drop individuals who have never been head/RP in any given wave, as their family level variables would be observed from their head/RP.
		cap	drop	rp_any
		egen	rp_any=anymatch(${seqnum_all}), values(1)	//	Indicator if indiv was head/RP at least once.
		drop	if	rp_any!=1
		drop	rp_any
		
		
		
		*	Second, we drop individuals who were non-Sample members
		*	It is because non-Sample members become household member via marriage or adoption in the middle of the waves, causing break in the panel data.
		*	Even if drop them, we still have family-level variable information from Sample, non-RP member in family
		
			*	First, generate sample indicator
			cap	drop	Sample
			gen		Sample=0	if	inlist(sampstat,0,5,6)	//	Non-sample, followable non-sample parent and nonsample elderydrop
			replace	Sample=1	if	inlist(sampstat,1,2,3,4)	//	Original, born-in, moved and join inclusion sample
			label	var	Sample "=1 if PSID Sample member"
			
			*	Then drop the non-Sample members
			drop	if	Sample==0
			
		*	Third, we adjust family weight by the number of valid individuals in each wave
		*	If there are multiple Sample individuals who has ever been an RP within a family at certain wave, their family variables will be counted multiple times (duplicate)
		*	Thus we need to divide the family weight by the number of Sample individuals who were living in a family unit 
		
			cap	drop	living_Sample*
			cap	drop	tot_living_Sample*
			cap	drop	tot_living_Sample*
			cap	drop	wgt_long_fam_adj*
			
		
			foreach	year	of	global	sample_years	{
				
				cap	drop	living_Sample`year'	num_living_Sample`1968'
				
				if	`year'==1968	{	
					
					*	In 1968, invididuals with pn b/w 1 and 20 are living in the family unit (and automatically born-in Sample)
					gen		living_Sample`year'=1	if	inrange(pn,1,20)	
					
				}
				
				else	{
					
					*	For all other years, use sequence number
					gen		living_Sample`year'=1	if	inrange(xsqnr_`year',1,20)
					
				}

				*	Count the number of Sample members living in FU in each wave
				bys	x11102_`year':	egen	tot_living_Sample`year'=count(living_Sample`year')
				
				*	Divide family weight in each wave by the number of Sample members living in FU in each wave
				gen	wgt_long_fam_adj`year'	=	wgt_long_fam`year'	/	tot_living_Sample`year'
				
			}
		
		/*
		*	(2021-11-19: The following code is dropped after discussing with Chris)
		*	Second, we replace household id with missing(or zero) of the individuals when they were not head/RP
		*	For example, in case of pn=2002 above, her values will be replaced with zero when she were not head/RP (ex. 1968, 1969, 1978, 1979, 1980) so her own household doesn't exist during that period
		***	But this can be problematic, especially during 1978-1980 in the example above. Need to think about how I deal with it.

		foreach	year	of	global	sample_years	{
			
			replace	x11102_`year'=.	if	xsqnr_`year'!=1
			
		}
		*/
		
		*	Drop FUs which were observed only once, as it does not provide sufficient information.
		egen	fu_nonmiss=rownonmiss(${hhid_all})
		label variable	fu_nonmiss	"Number of non-missing survey period as head/PR"
		drop	if	fu_nonmiss==1	//	Drop if there's only 1 observation per household.
		
		*	Generate the final household id which uniquely identifies a combination of household wave IDs.
		*egen hhid_agg = group(x11102_1968-x11102_2019), missing	//	This variable is no longer needed. Can bring it back if needed.
		drop	hhid_agg_1st
		
		*	Save
			
			*	Wide-format
			order	pn sampstr sampcls gender sampstat Sample fu_nonmiss,	after(x11101ll)
			save	"${SNAP_dtInt}/Ind_vars/ID_sample_wide.dta", replace
		
			*	Re-shape it into long format and save it
			reshape long x11102_	xsqnr_	wgt_long_ind	wgt_long_fam	wgt_long_fam_adj	living_Sample tot_living_Sample	/*${varlist_ind}	${varlist_fam}*/, i(x11101ll) j(year)
			order	x11101ll pn sampstat Sample year x11102_ xsqnr_ 
			*drop	if	inlist(year,1973,1988,1989)	//	These years seem to be re-created during "reshape." Thus drop it again.
			*drop	if	inrange(year,1968,1974)	//	Drop years which don't have last month food stamp information exist.
			
			*	Rename variables
			rename	x11102_	surveyid
			rename	xsqnr_	seqnum
			
			label	var	year		"Year"
			label	var	surveyid	"Survey ID"
			label	var	seqnum		"Sequence No."
			
			label	var	wgt_long_ind	"Longitudinal individual Weight"
			label	var	wgt_long_fam	"Longitudinal family Weight"
			label	var	living_Sample	"=1 if Sample member living in FU"
			label	var	tot_living_Sample	"# of Sample members living in FU"
			label	var	wgt_long_fam_adj	"Longitudianl family weight, adjusted"	
			
			save	"${SNAP_dtInt}/Ind_vars/ID_sample_long.dta",	replace
			use "${SNAP_dtInt}/Ind_vars/ID_sample_long.dta", clear
	}
	



	
	
	
	/*
	


		*	Create a panel structre
		*	This study covers 50-year period with different family composition changes, thus we need to carefully consider that.
		*	Basically we will track the two different types of families
			*	(1) Families that initially existed in 1975 (first year of the study)
			*	(2) Families that split-off from the original families (1st category)
		*	Also, we define family over time as the same family as long as the same individual remain either RP or spouse.
		
		*	First, we create a individual-level aggregated data using "psid use command" with necessary variables to further investigate family change.
			
	
			
		*	Merge ID with unique vars as well as other survey variables needed for panel data creation
		use	"${SNAP_dtInt}/Ind_vars/ID", clear
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/unique_vars.dta",	nogen	assert(3)
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/wgt_long_ind.dta",	nogen	assert(3)	//	Individual weight
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Fam_vars/wgt_long_fam.dta",	nogen	assert(3)	//	Family weight
		
		*	Merge individual variables
		cd "${SNAP_dtInt}/Ind_vars"
		
		global	varlist_ind	age_ind	/*wgt_long_ind*/	relrp	origfu_id	noresp_why
		
		foreach	var	of	global	varlist_ind	{
			
			merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(2 3)	keep(3)	//	Longitudinal weight
				
		}
		
				
		*	Drop years outside study sample	
			drop	*1973	*1988	*1989	//	Years without food expenditures (1973, 1988, 1989)
			drop	*1968	*1969	*1970	*1971	//	Years which I cannot separate FS amount from food expenditure
			drop	*1972	*1974	//	Years without previous FS status
		
				
		*	Set globals
		*	Here we include 1975 variables, as we want to consider the conditions of 1975 as well.
		qui	ds	x11102_1975-x11102_2019
		global	hhid_all_1975	`r(varlist)'
		
		qui	ds	xsqnr_1975-xsqnr_2019
		global	seqnum_all_1975	`r(varlist)'
		
		
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
			
			foreach	year	of	global	sample_years_1975	{
				
				
				cap	drop	`var'`year'
				gen		`var'`year'=0	if	relrp`year'==0	//	Inapp
				
				*	1976-1982
				*	Mostly the same, but need to change a little bit
				if	inrange(`year',1975,1982) {
					
					replace	`var'`year'=relrp`year'	//	Copy original "relation to head" variable, as they are mostly the same
					replace	`var'`year'=2	if	relrp`year'==9	//	Recode "husband of head" as spouse
					
				}
				
				*	1983-2019
				*	They have more detailed info, so need to simplify them
				
				else	{
				
					replace	`var'`year'=1	if	relrp`year'==10	//	Reference Person
					replace	`var'`year'=2	if	inlist(relrp`year',20,22,88,90,92)	//	Spouse, partner, first-year cohabitor, legal spouse
					replace	`var'`year'=3	if	inrange(relrp`year',30,38) | relrp`year'==83	//	Child (including son-in-law, daughter-in-law, stepchild, etc.)
					replace	`var'`year'=4	if	inrange(relrp`year',40,48)	//	Sibling (including in-law, that of cohabitor)
					replace	`var'`year'=5	if	inrange(relrp`year',50,58)	//	Parent (including in-law, that of cohabitor)
					replace	`var'`year'=6	if	inrange(relrp`year',60,65)	//	Grandchild or lower generation
					replace	`var'`year'=7	if	inrange(relrp`year',66,69)	|	inrange(relrp`year',70,75) | inrange(relrp`year',95,97) 	// Other relative (grand-parent, etc.)
					replace	`var'`year'=8	if	relrp`year'==98 	//	Other non-relative
				
				}
				
				label	var	`var'`year'	"Relation to RP (modified) in `year'"
				
			}
		
			label	define	relrp_recode	0	"Inapp"	1	"RP"	2	"Spouse/Partner"	3	"Child"	4	"Sibling"	5	"Parent"	6	"Grandchild or lower"	7	"Other relative"	8	"Other non-relative", replace
			label	value	relrp_recode????	relrp_recode
			
			*	Generate string version of variables for comparison
			foreach	year	of	global	sample_years_1975	{
				
				cap	drop	x11102_`year'_str	relrp_recode`year'_str
				tostring	x11102_`year',	gen(x11102_`year'_str)
				decode 		relrp_recode`year', gen(relrp_recode`year'_str)
				
			}
			
			
			*	Generate residential status variable
			loc	var	resid_status
			lab	define	resid_status	0	"Inapp"	1	"Resides"	2	"Institution"	3	"Moved Out"	4	"Died", replace
			foreach	year	of	global	sample_years_1975	{
			
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
			
			*	Combine Variables - ID, relation and status
			*	This variable is not directly used for analysis, but to check individual status more clearly.
			foreach	year	of	global	sample_years_1975	{
			
				cap	drop	status_combined`year'
				gen		status_combined`year'	=	x11102_`year'_str + "_" + relrp_recode`year'_str	+	"_"	+	resid_status`year'_str
				label	var	status_combined`year'	"Combined status in `year'"
			}
			
			*	Keep only the individuals that appear at least once during the study period (1976-2019)
			*	I do this by counting the number of sequence variables with non-zero values (zero value in sequence number means inappropriate (not surveyed)
			*	This code is updated as of 2022-3-21. Previously I used the number of missing household IDs, as below.
			loc	var	zero_seq_7519
			cap	drop	`var'
			cap	drop	count_seq_7519
			egen	count_seq_7519	=	anycount(xsqnr_1975-xsqnr_2019), values(0)	//	 Counts the number of sequence variables with zero values
			gen		`var'=0
			replace	`var'=1	if	count_seq_7519==32
			*drop	if	`var'==1	//	Drop individuals who have zero values across all sequence variables
			drop	count_seq_7519
			
			
			*	Individuals who were RP in 1975
			*	These individuals form families that existed in 1975, which I define as "baseline family"
			*	RP should satisfy two conditions; (1) sequence number is 1 (2) relation to head is him/herself
			loc	var	rp1975
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	xsqnr_1975==1	&	relrp1975==1
			lab	var	`var'	"=1 if RP in 1975"
			tab	`var'
			
			*	Individuals who were spouse/partner in 1975
			loc	var	sp1975
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	inrange(xsqnr_1975,1,20)	&	relrp_recode1975==2
			lab	var	`var'	"=1 if SP in 1975"
			
			*	Combine the two indicators above to find individuals who were RP or spouse in 1975
			*	They are the people who represent their family units.
			*	For families that have both RP and SP (ex. married), we treat both individuals representing their own families, but adjust their weight such that the summ of (family) weights they represent being equal to the (family) weight they actually belong to.
			loc	var	rpsp1975
			cap	drop	`var'
			gen	`var'=0
			replace	`var'=1	if	inlist(1,rp1975,sp1975)
			label	var	`var'	"=1 if RP/SP in 1975"
			
			tab	rp1975	sp1975	//	5,725 individuals who were RP in 1975
			distinct	x11102_1975	if	rpsp1975==1	//	5,725 families, which verifies the result above.
		
			*	Individuals that were child/grandchild in 1975
			*	Note that this variable does NOT capture children who were born after 1975 is NOT captured here (they are coded as inapp)
			loc	var	ch1975
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	inrange(xsqnr_1975,1,20)	&	inlist(relrp_recode1975,3,6)
			lab	var	`var'	"=1 if child/grandchild in 1975"
			
			*	Inappropriate in 1975
			loc	var	inapp1975
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	xsqnr_1975==0 // Seq number is 0 (inapp) if and only if relation to RP is inapp. So we can use only one condition
			lab	var	`var'	"=1 if inapp in 1975"
			
			*	Combine two indicators above to create "child or inapp in 1975"
			*	We will use this indicator to determine split-off families.
			loc	var	chinapp1975
			cap	drop	`var'
			gen	`var'=0
			replace	`var'=1	if	inlist(1,ch1975,inapp1975)
			label	var	`var'	"=1 if Ch/inapp in 1975"
			
			
			*	Individuals that were either RP or spouse only during the entire study period when residing
			*	These information can be combined with "RP/SP in 1975" variable to detect "same baseline family over time"
			*	IMPORANT: Unlike checking whether an individual is RP or not, this information does NOT need to satisfy sequence number condition, but relation to RP only.
			*	It is because our sample is inevitably unbalanced since it spans over 40 years, thus it is OK for individuals to have sequence number OTHER THAN 1.
			*	Here's an example. Suppose an individual who was RP in 1976 no longer resides in 1977. This individual has "relation to RP" as "him/herself" as his last status was RP, but sequence number is not equal to 1. (81 if died, 0 if moved out/refused, etc.)
			*	As long as this individual is neither RP nor spouse, this person remained as RP or spouse of RP (so it is still the same household)
			*	If a spouse takes over RP position, this family should still treated as the same family.
			*	If someone else (ex. child) takes over RP position, this family is no longer treated as the same family.
			loc	var		rpsp7519
			cap	drop	`var'
			cap	drop	count_relrp7519
			egen	count_relrp7519	=	anycount(relrp_recode1975-relrp_recode2019), values(0 1 2)
			gen		`var'=0
			replace	`var'=1	if	count_relrp7519==32	//	Those who satisfy relation condition; RP or SP (residing) or inapp (not residing) across all 32 waves
			lab	var	`var'	"=1 if RP/SP over study period"
			drop	count_relrp7519	
			
			*	RP/SP at least in one wave
			*	This indicator is based on Chris' suggestion where he suggested to include ALL individuals who were RP/SP at least once.
			*	It allows to capture many individuals we drop from earlier criteria, including "those who later become a parent" and "those who first split-off as sibling and later become RP/SP
			loc	var		rpsponce7519
			cap	drop	`var'
			cap	drop	count_relrp7519
			egen	count_relrp7519	=	anycount(relrp_recode1975-relrp_recode2019), values(1 2)
			gen		`var'=0
			replace	`var'=1	if	count_relrp7519>=1	//	At least having child/grandchild status in one wave
			lab	var	`var'	"=1 if RP/SP at least in one year"
			drop	count_relrp7519	
						
			*	Now we can determine baseline individuals who represent same baseline family over time.
			*	Baseline individuals; (1) RP/SP in 1975, and (2) RP or SP at least once.
			loc	var	baseline_indiv
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	rpsp1975==1	&	/*rpsp7519==1*/	rpsponce7519==1
			label	var	`var'	"=1 if baseline individual"
			
			tab	baseline_indiv	//	8,756 individuals
			distinct	x11102_1975	if	baseline_indiv==1	
			
			*	We currently have 8,756 baseline individuals living in 5,564 families in 1975 which remained same over time under our definition
			*	(Final size will be smaller once we exclude non-Sample individuals)
			*	We treat each individuals as each family. Say, we have 8,756 families. To fill in this gap, we adjust the weight.
			
		
			
			*	Now we move to the second type of family; split-off family formed by children after 1975
				*	Both children who were living in 1975 as well as born after 1975
			*	Like baseline family, individuals who represent split-off family should satisfy the followings
				*	(1)	Children/grandchild or inapp in 1975 (to exclude baseline individuals; avoid duplicate counting)
				*	(2) Children/grandchild at least in one wave
				*	(3) RP/SP at least in one wave (to exclude those who never had a family they represent)
					*---	(4) Status no other than Ch/RP/SP while residing (to exclude those who do not represent SAME family over time)	--- // Removed this condition as of 2022/3/30
			**	Note: this code is incomplete as it fails to capture the following indivdiuals
				*	(1) Those who first split-off as non-RP/SP, but kept RP/SP status once they became RP/SP
					*	ex)6785033: First split-off as sibling of RP in 2009, but formed own HH in 2011 and remaind RP/SP status till 2019
					
			
			*	Children at least in one wave
			loc	var		chonce7519
			cap	drop	`var'
			cap	drop	count_relrp7519
			egen	count_relrp7519	=	anycount(relrp_recode1975-relrp_recode2019), values(3 6)
			gen		`var'=0
			replace	`var'=1	if	count_relrp7519>=1	//	At least having child/grandchild status in one wave
			lab	var	`var'	"=1 if child at least in one year"
			drop	count_relrp7519	
			
			/*	We no longer use this condition
			*	Status no other than Ch/RP/SP
			loc	var		rpspch7519
			cap	drop	`var'
			cap	drop	count_relrp7519
			egen	count_relrp7519	=	anycount(relrp_recode1975-relrp_recode2019), values(0 1 2 3 6)
			gen		`var'=0
			replace	`var'=1	if	count_relrp7519==32	//	Those who satisfy relation condition; RP or SP (residing) or inapp (not residing) across all 32 waves
			lab	var	`var'	"=1 if Ch/RP/SP over study period"
			drop	count_relrp7519	
			*/
			
			*	With the indicators constructed above, now we can determine individuals that represent split-off families.
			loc	var	splitoff_indiv
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	chinapp1975==1	&	chonce7519==1	&	rpsponce7519==1	/*&	rpspch7519==1*/
			label	var	`var'	"=1 if split-off individual"
			
			tab	splitoff_indiv	//	10,281 individuals
			tab baseline_indiv splitoff_indiv
			
			loc	var	bs_splitoff_indiv
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	inlist(1,baseline_indiv,splitoff_indiv)
			label	var	`var'	"=1 if baseline or split-off individual"
				
			*	Those who have ever been RP
			*	IMPORTANT: we no longer use "rp_any" as our sample condition, as there are individuals who represent family as spouse without being RP.
			*	We just create it as a reference
			cap	drop	rp_any
			egen	rp_any=anymatch(${seqnum_all_1975}), values(1)	//	Indicator if indiv was head/RP at least once.
			*drop	if	rp_any!=1
			label	var	rp_any "=1 if RP in any period"
			*drop	rp_any

	
		*	Now we keep only relevant observations.
			
		*	Drop Latino sample
			drop	if	sample_source==5	//	Latino sample
			drop	if	sample_source==4	//	2017 refresher
			
		*	Drop those who never appeared during the study period
			drop	if	zero_seq_7519==1
		
			*	Generate a household id which uniquely identifies a combination of household wave IDs.
			**	Note: This is a tepmorary variable where it would have duplicate household ids after applying family panel structure (this is why I named this variabe as "1st")
			cap drop hhid_agg_1st	
			egen hhid_agg_1st = group(x11102_1975-x11102_2019), missing	

		*	Drop non-Sample individuals
		*	Note: Previous analysis were done without dropping them. Make sure to drop it carefully.
			drop	if	Sample==0
			
			
		*	Tab study-sample without dropping.
			
			loc	var	in_sample
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	Sample==1	&	inlist(1,baseline_indiv,splitoff_indiv)
			label	var	`var'	"=1 if in study sample"

		*	Overview of sample
		duplicates tag hhid_agg_1st if in_sample==1, gen(dup)
		tab	dup	//	91.6% of individuals have unit 1st-stage HHID (series of sequence numbers over waves). 8% have non-unique, mostly RP with SP/ch.
		drop	dup
		
		
		
	
		