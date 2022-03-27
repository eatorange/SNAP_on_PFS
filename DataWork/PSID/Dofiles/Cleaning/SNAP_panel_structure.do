

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
		qui	ds	x11102_1976-x11102_2019
		global	hhid_all	`r(varlist)'
		
		qui	ds	xsqnr_1976-xsqnr_2019
		global	seqnum_all	`r(varlist)'

		tempfile	temp
		save	`temp'
		
		*	Create a panel structre
		*	This study covers 50-year period with different family composition changes, thus we need to carefully consider that.
		*	Basically we will track the two different types of families
			*	(1) Families that initially existed in 1976 (first year of the study)
			*	(2) Families that split-off from the original families (1st category)
		*	Also, we define family over time as the same family as long as their reference person (RP) stays the same. This is a benchmark definition
		*	A more advanced, refined definition is if a same person is an RP or spouse over time.
		
		*	First, we create a individual-level aggregated data using "psid use command" with necessary variables to further investigate family change.
			
		*	Generate a household id which uniquely identifies a combination of household wave IDs.
		**	Note: This is a tepmorary variable where it would have duplicate household ids after applying family panel structure (this is why I named this variabe as "1st")
		cap drop hhid_agg_1st	
		egen hhid_agg_1st = group(x11102_1975-x11102_2019), missing
		
		*	Keep only the individuals that appear at least once during the study period (1976-2019)
		*	I do this by counting the number of sequence variables with non-zero values (zero value in sequence number means inappropriate (not surveyed)
		*	This code is updated as of 2022-3-21. Previously I used the number of missing household IDs, as below.
		cap	drop	zero_seq_7619
		egen	zero_seq_7619	=	anycount(xsqnr_1976-xsqnr_2019), values(0)	//	 Counts the number of sequence variables with zero values
		drop	if	zero_seq_7619==31	//	Drop individuals who have zero values across all sequence variables
		drop	zero_seq_7619
		
		
			/*	outdated
			*	Tag the number of periods appearing in the survey by counting the number of non-missing household IDs during the period
			**	Note: There are households which are missing across all the study periods, possibly because they appeared only outside the period (ex. 1968-1974)
			**	We might also consider households that appear only once, as we need at least two consecutive periods
			
			egen	fu_nonmiss=rownonmiss(${hhid_all})
			label variable	fu_nonmiss	"Number of non-missing survey period as head/PR"
			*drop	if	fu_nonmiss==1	//	Drop if there's only 1 observation per household.
			drop	if	fu_nonmiss==0	//	These are individuals that don't appear at all during the study period. I assume they appear only outside the study period.
			
			*/
		
			
		*	Relation to HH
		*	As a panel data construction process, I make the code consistent across years
		loc	var	relrp_recode
		
		foreach	year	of	global	sample_years	{
			
			
			cap	drop	`var'`year'
			gen		`var'`year'=0	if	relrp`year'==0	//	Inapp
			
			*	1976-1982
			*	Mostly the same, but need to change a little bit
			if	inrange(`year',1976,1982) {
				
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
		foreach	year	of	global	sample_years	{
			
			cap	drop	x11102_`year'_str	relrp_recode`year'_str
			tostring	x11102_`year',	gen(x11102_`year'_str)
			decode 		relrp_recode`year', gen(relrp_recode`year'_str)
			
		}
		
		
		*	Generate residential status variable
		loc	var	resid_status
		lab	define	resid_status	0	"Inapp"	1	"Resides"	2	"Institution"	3	"Moved Out"	4	"Died", replace
		foreach	year	of	global	sample_years	{
		
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
		foreach	year	of	global	sample_years	{
		
			cap	drop	status_combined`year'
			gen		status_combined`year'	=	x11102_`year'_str + "_" + relrp_recode`year'_str	+	"_"	+	resid_status`year'_str
			label	var	status_combined`year'	"Combined status in `year'"
		}
		
		
		
		tempfile temp2
		save `temp2'
		
		
		*	We start with the first category; families that existed as of 1976. (based on discussion with Chris on 2022-3-22)
		*	I name these families as "base families"  
		*	We can find these families by tagging the individuals who were RP as of 1976
		*	We will track these families as long as their RPs remain as (1) RP or (2) spouse of RP over time.
		cap	drop	rp1976
		gen		rp1976=0
		replace	rp1976=1	if	xsqnr_1976==1	&	relrp1976==1
		loc	var	rp1976	"An individual who was an RP in 1976"
				
		
		/* outdated*/
		/*
		*	Identify individuals who have always been a reference person
		cap	drop	maxseq7619 maxrelrp7619
		egen	maxseq7619=	rowmax(xsqnr_1976-xsqnr_2019)
		egen	maxrelrp7619=rowmax(relrp_recode1976-relrp_recode2019)
		*/
				
		*	Individuals who have always been RP (seq.num==1) when residing.
		*	This indicator is used for stricter definition, where family over time is same as long as RP is the same (doesn't account for spouse)
		*	These individuals should satisfy the following conditions
				*	(1)	Their sequence number should be 1 when residing. In other words, their seq.number should only be 0, 1, or somewhere between 51 to 89 (institution, moved out or dead)
				*	(2) Their relation to RP should always be 0 (when moved out or dead) or 1 (when RP)
			*	They belong to the benchmark definition of "same household over time" as "same RP"
			cap	drop	rp7619
			
				*	(1) Sequence number condition
				cap	drop	count_rp_die7619	seqnum_cond7619
				egen	count_rp_die7619	=	anycount(xsqnr_1976-xsqnr_2019), values(0 1 51 52 53 54 55 56 57 58 59 71 72 73 74 75 76 77 78 79 80 81 82 83 84 85 86 87 88 89) //	 Counts the number of sequence variables belong to this case
				gen		seqnum_cond7619=0
				replace	seqnum_cond7619=1	if	count_rp_die7619==31	//	Those who satisfying (1)
				
				*	(2) Relation to RP conditions
				cap	drop	count_relrp7619	relrp_cond7619
				egen	count_relrp7619	=	anycount(relrp_recode1976-relrp_recode2019), values(0 1)
				gen		relrp_cond7619=0
				replace	relrp_cond7619=1	if	count_relrp7619==31
				
			*	Generate an indicator which satisfies both conditions
			gen		rp7619=0
			replace	rp7619=1	if	seqnum_cond7619==1	&	relrp_cond7619==1
			lab	var	rp7619	"Individuals who have always been RP"
			drop	count_rp_die7619		seqnum_cond7619	count_relrp7619	relrp_cond7619
			
		
		*	Individuals who have always ben RP or spouse or RP
		*	While RP always have seq.no==1, spouse may have different sequnce numbers. Thus I can only use relation to RP condition
		
		
		
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
	
		
		*	Additionally, tag (1) those who have never been RP and (2) non-Sample member.
		
			*	First, we drop individuals who have never been head/RP in any given wave, as their family level variables would be observed from their head/RP.
			cap	drop	rp_any
			egen	rp_any=anymatch(${seqnum_all}), values(1)	//	Indicator if indiv was head/RP at least once.
			*drop	if	rp_any!=1
			label	var	rp_any "=1 if RP in any period"
			*drop	rp_any
			
			*	Second, drop non-Sample member
			cap	drop	Sample
			gen		Sample=0	if	inlist(sampstat,0,5,6)	//	Non-sample, followable non-sample parent and nonsample elderydrop
			replace	Sample=1	if	inlist(sampstat,1,2,3,4)	//	Original, born-in, moved and join inclusion sample
			*drop	if	Sample==0
			label	var	Sample "=1 if PSID Sample member"
			
		*	Tag in-study sample
		capture	drop	in_sample_rponly
		capture	drop	in_sample_childrp
		
		gen		in_sample_rponly=0
		replace	in_sample_rponly=1	if	rp7619==1	&	rp_any==1	&	Sample==1
		gen		in_sample_childrp=0
		replace	in_sample_childrp=1	if	childrp7619==1	&	rp_any==1	&	Sample==1
		gen		in_sample_childrpsp=0
		replace	in_sample_childrpsp=1	if	childrpsp7619==1	&	rp_any==1	&	Sample==1
			
			*	Now see how many individuals of unique set of HHIDs over the period.
			*	(2022-3-22) I temporarily disable this code. I will re-activate this after I finalize sample-determining code.
			/*
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
		sort	x11102_1976	xsqnr_1975
		
		loc	startyear	1976
		loc	endyear		2019
		
		loc	browsevars
		
		foreach	year	of	global	sample_years	{
			
			*loc	browsevars	`browsevars'	x11102_`year'	xsqnr_`year'	age_ind`year'	relrp_recode`year'	
			loc	browsevars	`browsevars'		status_combined`year'	age_ind`year'	noresp_why`year'
			
		}
		
		global	browsevars	`browsevars'	
		
		order	x11101ll	gender	hhid_agg_1st	rp_any	Sample		${browsevars}
		br		x11101ll	gender	hhid_agg_1st	rp_any	Sample		${browsevars} if x11102_1976==488
		
		sort x11101ll
		
		loc	year	1976
		sort	x11102_`year'	xsqnr_`year'
		
		export excel	x11101ll	gender	hhid_agg_1st	rp_any	Sample	rp7619	childrp7619	in_sample_rponly	in_sample_childrp	${browsevars}	using "C:\Users\Seungmin Lee\Desktop\family_status_v3.xlsx"	if	x11102_1976==488,  firstrow(variables)	replace
		*preserve
		*	keep	if	x11102_1976==488
		*	keep  
		*	
		*restore
		