

/*was indiv present in both waves?*/

gen in1719=0
replace in1719=1 if inrange(sn17,1,20) & inrange(sn19,1,20) /*N=20,512*/

fre in1719

/*was the individual the reference person in both waves?*/

gen rp1719=0
replace rp1719=1 if in1719==1 & sn17==1 & sn19==1 /*N=7,990*/

fre rp1719

/*create family-level indicator - individual lived in FU in 2019 with same RP in both waves*/

bys famid19: egen smrp1719=max(rp1719) 

fre smrp1719 if in1719==1 /*19,193 indivs in FU with same RP in both waves (about 94% of people) */

fre smrp1719 if sn19==1  /*7,990 FUs had same RP in both waves (87% of FU) */

		
		*	Test code based on PSID 2021 Summer workshop
	
		*	Indiv present in both waves
		loc	start_year	75
		loc	end_year	76
		loc	var	in`start_year'`end_year'
		cap	drop	`var'
		gen `var'=0
		replace `var'=1 if inrange(xsqnr_1975,1,20) & inrange(xsqnr_1976,1,20) /*N=20,512*/
	 
		fre `var'

		*	Indiv is a reference person in both waves
		loc	var	rp`start_year'`end_year'
		cap	drop	`var'
		gen	`var'=0
		replace	`var'=1	if	in`start_year'`end_year'==1	&	xsqnr_1975==1	&	xsqnr_1976==1
		
		fre `var'	if	in`start_year'`end_year'==1







	
			
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
			
		*	Drop Latino sample
			drop	if	sample_source==5	//	Latino sample
			drop	if	sample_source==4	//	2017 refresher
		
		*	Set globals
		*	Here we include 1975 variables, as we want to consider the conditions of 1975 as well.
		qui	ds	x11102_1975-x11102_2019
		global	hhid_all_1975	`r(varlist)'
		
		qui	ds	xsqnr_1975-xsqnr_2019
		global	seqnum_all_1975	`r(varlist)'

		tempfile	temp
		save	`temp'
		
		*	Create a panel structre
		*	This study covers 50-year period with different family composition changes, thus we need to carefully consider that.
		*	Basically we will track the two different types of families
			*	(1) Families that initially existed in 1975 (first year of the study)
			*	(2) Families that split-off from the original families (1st category)
		*	Also, we define family over time as the same family as long as the same individual remain either RP or spouse.
		
		*	First, we create a individual-level aggregated data using "psid use command" with necessary variables to further investigate family change.
			
		*	Generate a household id which uniquely identifies a combination of household wave IDs.
		**	Note: This is a tepmorary variable where it would have duplicate household ids after applying family panel structure (this is why I named this variabe as "1st")
		cap drop hhid_agg_1st	
		egen hhid_agg_1st = group(x11102_1975-x11102_2019), missing
		
		*	Keep only the individuals that appear at least once during the study period (1976-2019)
		*	I do this by counting the number of sequence variables with non-zero values (zero value in sequence number means inappropriate (not surveyed)
		*	This code is updated as of 2022-3-21. Previously I used the number of missing household IDs, as below.
		cap	drop	zero_seq_7519
		egen	zero_seq_7519	=	anycount(xsqnr_1975-xsqnr_2019), values(0)	//	 Counts the number of sequence variables with zero values
		drop	if	zero_seq_7519==32	//	Drop individuals who have zero values across all sequence variables
		drop	zero_seq_7519
		
		
			/*	outdated
			*	Tag the number of periods appearing in the survey by counting the number of non-missing household IDs during the period
			**	Note: There are households which are missing across all the study periods, possibly because they appeared only outside the period (ex. 1968-1974)
			**	We might also consider households that appear only once, as we need at least two consecutive periods
			
			egen	fu_nonmiss=rownonmiss(${hhid_all_1975})
			label variable	fu_nonmiss	"Number of non-missing survey period as head/PR"
			*drop	if	fu_nonmiss==1	//	Drop if there's only 1 observation per household.
			drop	if	fu_nonmiss==0	//	These are individuals that don't appear at all during the study period. I assume they appear only outside the study period.
			
			*/
		
			
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
		foreach	year	of	global	sample_years_1975	{
		
			cap	drop	status_combined`year'
			gen		status_combined`year'	=	x11102_`year'_str + "_" + relrp_recode`year'_str	+	"_"	+	resid_status`year'_str
			label	var	status_combined`year'	"Combined status in `year'"
		}
		
		
		
		tempfile temp2
		save `temp2'
		
		
		*	Create individual-level indicators
		
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
			
			
			*	Now we can determine baseline individuals who represent same baseline family over time.
			*	Baseline individuals; (1) RP/SP in 1975, and (2) RP/SP over the period while residing (including attrition)
			loc	var	baseline_indiv
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	rpsp1975==1	&	rpsp7519==1
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
				*	(4) Status no other than Ch/RP/SP while residing (to exclude those who do not represent SAME family over time)
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
			
			*	RP/SP at least in one wave
			loc	var		rpsponce7519
			cap	drop	`var'
			cap	drop	count_relrp7519
			egen	count_relrp7519	=	anycount(relrp_recode1975-relrp_recode2019), values(1 2)
			gen		`var'=0
			replace	`var'=1	if	count_relrp7519>=1	//	At least having child/grandchild status in one wave
			lab	var	`var'	"=1 if RP/SP at least in one year"
			drop	count_relrp7519	
			
			*	Status no other than Ch/RP/SP
			loc	var		rpspch7519
			cap	drop	`var'
			cap	drop	count_relrp7519
			egen	count_relrp7519	=	anycount(relrp_recode1975-relrp_recode2019), values(0 1 2 3 6)
			gen		`var'=0
			replace	`var'=1	if	count_relrp7519==32	//	Those who satisfy relation condition; RP or SP (residing) or inapp (not residing) across all 32 waves
			lab	var	`var'	"=1 if Ch/RP/SP over study period"
			drop	count_relrp7519	
			
			*	With the indicators constructed above, now we can determine individuals that represent split-off families.
			loc	var	splitoff_indiv
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	chinapp1975==1	&	chonce7519==1	&	rpsponce7519==1	&	rpspch7519==1
			label	var	`var'	"=1 if split-off individual"
			
			tab	splitoff_indiv	//	10,281 individuals
			tab baseline_indiv splitoff_indiv
			
			loc	var	bs_splitoff_indiv
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	inlist(1,baseline_indiv,splitoff_indiv)
			label	var	`var'	"=1 if baseline or split-off individual"
			
			*	Additionally, tag (1) those who have never been RP and (2) non-Sample member.
		
			*	Those who have ever been RP
			*	IMPORTANT: we no longer use "rp_any" as our sample condition, as there are individuals who represent family as spouse without being RP.
			*	We just create it as a reference
			cap	drop	rp_any
			egen	rp_any=anymatch(${seqnum_all_1975}), values(1)	//	Indicator if indiv was head/RP at least once.
			*drop	if	rp_any!=1
			label	var	rp_any "=1 if RP in any period"
			*drop	rp_any
			
			*	Second, Sample status defind by the PSID
			cap	drop	Sample
			gen		Sample=0	if	inlist(sampstat,0,5,6)		//	Non-sample, followable non-sample parent and nonsample elderydrop
			replace	Sample=1	if	inlist(sampstat,1,2,3,4)	//	Original, born-in, moved and join inclusion sample
			*drop	if	Sample==0
			label	var	Sample "=1 if PSID Sample member"
			
			loc	var	in_sample
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	Sample==1	&	inlist(1,baseline_indiv,splitoff_indiv)
			label	var	`var'	"=1 if in study sample"

		/*	*	This code is outdated, as I wrote above we don't need sequence number condition
		
		*	We can easily see this by running this outdated code and see two-way tabulate of both conditions; there's no individuals whose satisfy (2) but not (1).		
		*	Individuals who have always been RP when residing.
		*	These individuals should satisfy the following conditions
				*	(1)	Their sequence number should be 1 when residing. In other words, their seq.number should only be 0, 1, or somewhere between 51 to 89 (institution, moved out or dead)
				*	(2) Their relation to RP should always be 0 (when moved out or dead) or 1 (when RP)
			*	They belong to the benchmark definition of "same household over time" as "same RP"
			
				*	(1) Sequence number condition
				cap	drop	count_rp_die7519	seqnum_cond7519
				egen	count_rp_die7519	=	anycount(xsqnr_1975-xsqnr_2019), values(0 1 51 52 53 54 55 56 57 58 59 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89) //	 Counts the number of sequence variables belong to this case
				gen		seqnum_cond7519=0
				replace	seqnum_cond7519=1	if	count_rp_die7519==32	//	Those who satisfying (1)
				
				
				*	(2) Relation to RP conditions
				cap	drop	count_relrp7519	relrp_cond7519
				egen	count_relrp7519	=	anycount(relrp_recode1975-relrp_recode2019), values(0 1)
				gen		relrp_cond7519=0
				replace	relrp_cond7519=1	if	count_relrp7519==32	//	Those who satisfying (2)
				
				tab	seqnum_cond7519	relrp_cond7519
				
			*	Generate an indicator which satisfies both conditions
			gen		rp7619=0
			replace	rp7619=1	if	seqnum_cond7619==1	&	relrp_cond7619==1
			lab	var	rp7619	"Individuals who have always been RP"
			drop	count_rp_die7619		seqnum_cond7619	count_relrp7619	relrp_cond7619
			
		
		
		
			*	Individuals who were once a child/grandchild, and then became "RP" (once they became RP, their role don't change until they attrit)
			*	Children have non-fixed sequence number, so this time I will only use "relation to RP" condition only (NOT CERTAIN if this is the right condition)
			**	IMPORTANT: Currently this code include individuals who were RP and then later became children (ex. returning to parents' house). I do not want to include this so need to think about how to exclude it.
			**	IMPORTANT: Currently this code does NOT include those who were once children and then becamse "spouse of RP" without changing roles. I do not include it for now, as they will be dropped when I drop indivdiuals who have never been RP
			**	Need to think about how we will handle this.
			cap	drop	childrp7619
			cap	drop	count_childrp7619
			cap	drop	count_childrpsp7619
			egen	count_childrp7619	=	anycount(relrp_recode1976-relrp_recode2019), values(0 1 3 6)	//	 Only "inapp", "RP", "child" and "grandchild"
			egen	count_childrpsp7619	=	anycount(relrp_recode1976-relrp_recode2019), values(0 1 2 3 6)	//	 Only "inapp", "RP", "child" and "grandchild"
			gen		childrp7619=0
			replace	childrp7619=1	if	count_childrp7619==31	//	Individual that have always been RP or RP's child (or grandchild+)
			gen		childrpsp7619=0
			replace	childrpsp7619=1	if	count_childrpsp7619==31	//	Individual that have always been RP or RP's child (or grandchild+)
			label	var	childrp7619	"Individuals who have always been RP or RP's heirs'"
			label	var	childrpsp7619	"Individuals who have always been RP, RP's wife or RP's heirs'"
			drop	count_childrp7619
			drop	count_childrpsp7619
			
		*	Now, keep individuals only who belong to either of the two categories (always RP, always RP or child of RP) above.
		*	Note that in current version (2022/3/22), category 2 includes category 1.
		*keep	if	inlist(1,rp7619,childrp7619)
	*/
		
			
		/* Outdated
		Tag in-study sample
		capture	drop	in_sample_rponly
		capture drop	in_sample_rpsp
		capture	drop	in_sample_rpspch
		
		gen		in_sample_rponly=0
		replace	in_sample_rponly=1	if	rp_any==1	&	///	Has to be RP at any point... but is it necesasry? Because it won't capture females who were child and later become spouse only!
										Sample==1	&	
		gen		in_sample_rpsp=0
		replace	in_sample_rpsp=1	if	childrp7619==1	&	rp_any==1	&	Sample==1
		gen		in_sample_rpspch=0
		replace	in_sample_rpspch=1	if	childrpsp7619==1	&	rp_any==1	&	Sample==1
			
			*	Now see how many individuals of unique set of HHIDs over the period.
			*	(2022-3-22) I temporarily disable this code. I will re-activate this after I finalize sample-determining code.
			
			capture	drop	dup_hhid_agg_1st
			duplicates tag hhid_agg_1st, gen(dup_hhid_agg_1st)
			
				*	As of 2022/3/22, there are 32 dups.
				*	I manually checked those obs, and they are mostly a parent and a child.
				*	I manually drop those whom I can safely drop.
				drop	if	x11101ll==178033	//	Child of 178004. Has been living together. Became RP once, but immediately attrited.
				drop	if	x11101ll==368032	//	Child of 368003. Has been living together. Just became RP in 2019
				drop	if	x11101ll==753003	//	Child of 753001. Has been living together. Once became RP in 1979 but immediately attrited
				drop	if	x11101ll==825003	//	Child of 825001. Has been living together. Became RP in 1986 but immediately attrited
				drop	if	x11101ll==2151004	//	Child of 2151001. Has been living together. Became RP in 1992 but immediately attrited
				drop	if	x11101ll==2508003	//	Child of 2508001. Has been living together. Became RP in 2007 but immediately attrited
				drop	if	x11101ll==2850004	//	Child of 2850002. Has been living together. Became RP in 1999 but immediately attrited
				drop	if	x11101ll==3074002	//	Child of 3074001. Has been living together. Just became RP in 2019
				drop	if	x11101ll==5017171	//	Child of 5017032. Has been living together. Just became RP in 2019
				drop	if	x11101ll==5299055	//	Child of 5299010. Has been living together. Just became RP in 2019
				drop	if	x11101ll==5617002	//	Child of 5617001. Has been living together. Became RP in 1979 but immediately attrited
				drop	if	x11101ll==5993035	//	Grandchild of 5993001. Has been living together. Became RP in 1996 but immediately attrited
				drop	if	x11101ll==6120175	//	Child of 6120004. Has been living together. Became RP in 1994 but immediately attrited
				drop	if	x11101ll==6221003	//	Child of 6221001. Has been living together. Became RP in 1986 but immediately attrited
				drop	if	x11101ll==6430031	//	Child of 6430001. Has been living together. Became RP in 1995 but immediately attrited
				drop	if	x11101ll==6527002	//	Child of 6527001. Has been living together. Became RP in 1980 but immediately attrited
			
			
			*	Finally, check if each obs have unique ID
			isid	hhid_agg_1st
		*/	
		
		tempfile temp3
		save	`temp3'
		
		*	Generate a new household id which uniquely identifies a combination of household wave IDs with selected individuals only
		*cap drop hhid_agg_2nd	
		*egen hhid_agg_1st = group(x11102_1975-x11102_2019), missing
		
		
		*	Browsing relevant variables
		sort	x11102_1975	xsqnr_1975
		
		loc	startyear	1975
		loc	endyear		2019
		
		loc	browsevars
		
		foreach	year	of	global	sample_years_1975	{
			
			loc	browsevars	`browsevars'		status_combined`year'	age_ind`year'	noresp_why`year'
			
		}
		
		global	browsevars	`browsevars'	
		
		order	x11101ll	gender	hhid_agg_1st	rp_any	Sample		${browsevars}
		br		x11101ll	gender	hhid_agg_1st	rp_any	Sample		${browsevars} if x11102_1976==488
		
		sort x11101ll
		
		loc	year	1976
		sort	x11102_`year'	xsqnr_`year'
		
		export excel	x11101ll	gender	hhid_agg_1st	rpsp1975 chinapp1975 rpsp7519 chonce7519 rpsponce7519 rpspch7519 baseline_indiv splitoff_indiv bs_splitoff_indiv rp_any Sample in_sample	${browsevars}	using "C:\Users\Seungmin Lee\Desktop\family_status_v3.xlsx"	if	x11102_1976==488,  firstrow(variables)	replace
		*preserve
		*	keep	if	x11102_1976==488
		*	keep  
		*	
		*restore
		