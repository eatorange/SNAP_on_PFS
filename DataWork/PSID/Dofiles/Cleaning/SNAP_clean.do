
	/*****************************************************************
	PROJECT: 		SNAP of FS
					
	TITLE:			SNAP_clean
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Nov 14, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	x11101ll        // 1999 Family ID

	DESCRIPTION: 	Clean individual-level data from 1999 to 2017
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Retrieve variables on interest and construct a panel data
					2 - Clean variable labels and values
					X - Save and Exit
					
	INPUTS: 		* SNAP Individual & family raw data
					${SNAP_dtRaw}/Main
										
	OUTPUTS: 		* PSID panel data (individual)								
					* PSID 1999 Constructed (individual)
					${SNAP_dtInt}/SNAP_cleaned.dta
					

	NOTE:			*
	******************************************************************/

	/****************************************************************
		SECTION 0: Preamble			 									
	****************************************************************/		 
		
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
	loc	name_do	SNAP_clean
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${SNAP_doCln}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	/****************************************************************
		SECTION 1: Retrieve variables on interest and construct a panel data
	****************************************************************/	
	
	local	retrieve_vars	1
	local	clean_vars		1
	


clear

global psidtemp	"E:/OneDrive - Cornell University/SNAP/DataWork/DataSets/Raw/PSID"

global	waves_all	1968 1969 1970 1971 1972 1973 1974 1975 19


local	ind_agg	0
local	ind_fam	1
local	merge_ind_fam	0


if	`ind_agg'==1	{
	
	use	"E:/OneDrive - Cornell University/SNAP/DataWork/DataSets/Raw/PSID/Unpacked/ind2019er.dta", clear
		
	*	Generate a single ID variable
	generate	x11101ll=(ER30001*1000)+ER30002
		
	*	Rename necessary variables
	* Note: 1968 person number (ER30002) is the last three digits of the individual id created by psid use command
	rename	(ER30002	ER32006)	(pn	sampstat)
	save	"E:/OneDrive - Cornell University/SNAP/DataWork/DataSets/Intermediate/psid_ind.dta",	replace
	
}



*	Unpacks zipped raw PSID file into .dta file, with cleaning. Need to be done only once
*psid install using "${psidtemp}/Zipped", to("${psidtemp}/Unpacked")

*	Save core files in


	*	Merging practice (use 3 waves data to practice how I can make a panel dataset using individual data)
/*
psid use || age   	 	[68]V117 [69]V1008 [70]V1239 using  "C:/Users/Seungmin Lee/Desktop/psidtemp/installed" , keepnotes design(any) clear	
tempfile	age
save	`age'


psid use || splitoff [69]V909 [70]V1106  using  "C:/Users/Seungmin Lee/Desktop/psidtemp/installed"  , keepnotes design(any) clear	
tempfile	splitoff
save	`splitoff'


use	`age', clear
merge 1:1 x11101ll using `splitoff', keepusing(splitoff*) nogen assert(3)
*/






*	Data preparation
	
	*	This study covers 50-year period with different family composition changes, thus we need to carefully consider that.
	*	First, we create a individual-level aggregated data using "psid use command" with necessary variables to further investigate family change.
	
		*	Age (not strictly necessary, but useful when observing why composition change)
		psid use || age   	 	[68]V117 [69]V1008 [70]V1239 [71]V1942 [72]V2542 [73]V3095 [74]V3508 [75]V3921 [76]V4436 [77]V5350 [78]V5850 [79]V6462 [80]V7067 [81]V7658 [82]V8352 [83]V8961 [84]V10419 [85]V11606 [86]V13011 [87]V14114 [88]V15130 [89]V16631 [90]V18049 [91]V19349 [92]V20651 [93]V22406 [94]ER2007 [95]ER5006 [96]ER7006 [97]ER10009 [99]ER13010 [01]ER17013 [03]ER21017 [05]ER25017 [07]ER36017 [09]ER42017 [11]ER47317 [13]ER53017 [15]ER60017 [17]ER66017 [19]ER72017 using  "C:/Users/Seungmin Lee/Desktop/psidtemp/installed" , keepnotes design(any) clear	
		tempfile	age
		save	`age'

		*	Split-off indicator
		psid use || splitoff [69]V909 [70]V1106 [71]V1806 [72]V2407 [73]V3007 [74]V3407 [75]V3807 [76]V4307 [77]V5207 [78]V5707 [79]V6307 [80]V6907 [81]V7507 [82]V8207 [83]V8807 [84]V10007 [85]V11107 [86]V12507 [87]V13707 [88]V14807 [89]V16307 [90]V17707 [91]V19007 [92]V20307 [93]V21606 [94]ER2005F [95]ER5005F [96]ER7005F [97]ER10005F [99]ER13005E [01]ER17006 [03]ER21005 [05]ER25005 [07]ER36005 [09]ER42005 [11]ER47305 [13]ER53005 [15]ER60005 [17]ER66005 [19]ER72005  using  "C:/Users/Seungmin Lee/Desktop/psidtemp/installed"  , keepnotes design(any) clear	
		tempfile	splitoff
		save	`splitoff'

		*	Relationg to head/RP
		psid use || relrp   [68]ER30003 [69]ER30022 [70]ER30045 [71]ER30069 [72]ER30093 [73]ER30119 [74]ER30140 [75]ER30162 [76]ER30190 [77]ER30219 [78]ER30248 [79]ER30285 [80]ER30315 [81]ER30345 [82]ER30375 [83]ER30401 [84]ER30431 [85]ER30465 [86]ER30500 [87]ER30537 [88]ER30572 [89]ER30608 [90]ER30644 [91]ER30691 [92]ER30735 [93]ER30808 [94]ER33103 [95]ER33203 [96]ER33303 [97]ER33403 [99]ER33503 [01]ER33603 [03]ER33703 [05]ER33803 [07]ER33903 [09]ER34003 [11]ER34103 [13]ER34203 [15]ER34303 [17]ER34503 [19]ER34703 using  "C:/Users/Seungmin Lee/Desktop/psidtemp/installed" , keepnotes design(any) clear	
		tempfile	relrp
		save	`relrp'

		*	reason for non-response
		psid use || noresp_why [68]ER30018 [69]ER30041 [70]ER30065 [71]ER30089 [72]ER30115 [73]ER30136 [74]ER30158 [75]ER30186 [76]ER30215 [77]ER30244 [78]ER30281 [79]ER30311 [80]ER30341 [81]ER30371 [82]ER30397 [83]ER30427 [84]ER30461 [85]ER30496 [86]ER30533 [87]ER30568 [88]ER30604 [89]ER30640 [90]ER30685 [91]ER30729 [92]ER30802 [93]ER30863 [94]ER33127 [95]ER33283 [96]ER33325 [97]ER33437 [99]ER33545 [01]ER33636 [03]ER33739 [05]ER33847 [07]ER33949 [09]ER34044 [11]ER34153 [13]ER34267 [15]ER34412 [17]ER34649 [19]ER34862  using  "C:/Users/Seungmin Lee/Desktop/psidtemp/installed"  , keepnotes design(any) clear	
		tempfile	noresp_why
		save	`noresp_why'
		
		*	Aggregate them
		use	`age', clear
		merge 1:1 x11101ll using `splitoff', keepusing(splitoff*) nogen assert(3)
		merge 1:1 x11101ll using `relrp', keepusing(relrp*) nogen assert(3)
		merge 1:1 x11101ll using `noresp_why', keepusing(noresp_why*) nogen assert(3)
		*merge 1:1 x11101ll using `gender_head', keepusing(gender_head*) nogen assert(3)
		*merge 1:1 x11101ll using `foodexp_home', keepusing(foodexp_home*) nogen assert(3)
		
		*	Drop years without food expenditures (1973, 1988, 1989)
		drop	*_1973	*_1988	*_1989
		
		
		*	Generate a household id which uniquely identifies a combination of household wave IDs.
		**	Note: This is a tepmorary variable where it would have duplicate household ids after applying family panel structure (this is why I named this variabe as "1st")
		cap drop hhid_agg_1st	
		egen hhid_agg_1st = group(x11102_1968-x11102_2019), missing
		
						
		*br x11102_1968-x11102_1976 hhcomp_change hhcomp_change_missing
		*br	x11102_1968-x11102_1974	xsqnr_1969-xsqnr_1974	relrp1968-relrp1974	gender_head1968-gender_head1974
		
		*	Import variables from invidiual data which cannot be created by "psid use" command
		merge	1:1	x11101ll	using	"E:/OneDrive - Cornell University/SNAP/DataWork/DataSets/Intermediate/psid_ind.dta",	///
			 assert(2 3) keep(3) keepusing(pn	sampstat) nogen	
		
		*	Generate a 1968 sequence number variable from person number variable
		**	Note: 1968 sequence number is used to determine whether an individual was head/RP in 1968 or not. Don't use it for other purposes, unless it is not consistent with other sequence variables. Should be dropped after use to avoid confusion.		
		gen		xsqnr_1968	=	pn
		replace	xsqnr_1968	=	0	if	!inrange(xsqnr_1968,1,20)	
		
		
		*	Set globals
		qui	ds	x11102_1968-x11102_2019
		global	hhid_all	`r(varlist)'
		
		qui	ds	pn xsqnr_1969-xsqnr_2019
		global	seqnum_all	`r(varlist)'
		
		global	sample_years	1968	1969	1970	1971	1972	1974	1975	1976	1977	1978	1979	1980	1981	1982	1983	1984	///
								1985	1986	1987	1990	1991	1992	1993	1994	1995	1996	1997	1999	2001	2003	2005	2007	///
								2009	2011	2013	2015	2017	2019
		
		global	sample_years_comma	1968,	1969,	1970,	1971,	1972,	1974,	1975,	1976,	1977,	1978,	1979,	1980,	1981,	1982,	1983,	1984,	///
									1985,	1986,	1987,	1990,	1991,	1992,	1993,	1994,	1995,	1996,	1997,	1999,	2001,	2003,	2005,	2007,	///
									2009,	2011,	2013,	2015,	2017,	2019


		
		save	"E:/OneDrive - Cornell University/SNAP/DataWork/DataSets/Intermediate/SNAP_raw_merged.dta", replace
		
		
		
		
		
		
	*	Follwing families over time
	*	Key issue is "How to define families over time", as a main issue suggested by PSID
	*	There are many ways to define it; FUs without any member change, FUs with same head/RP, FUs with same head/RP and spouse/partner, etc.
	
	*	As of Nov 2021, I have two idea; (1) FUs with same head/RP over time, and (2) FUs with same head/RP or spouse/partner
	*	(1)	is more straighforward, but does not capture certain family composition change. (ex. husband dies and his spouse/partner becomes a new head/RP)
	*	(2) is more gender-neutral definition which also captures certain composition change that (1) does not capture. However, it is somewhat complicated to code.
		*	PSID conference day 2 excercise shows how to do this, but it works well only in short-term panel. Would be difficult to do this over 50 years.
	*	This part will later be moved after all variables are completed.
	
	
	use	"E:/OneDrive - Cornell University/SNAP/DataWork/DataSets/Intermediate/SNAP_raw_merged.dta", clear
	
	
	*	Next thing to do is dropping observations(individuals) that creates unnecessary panels from the code above (egen hhid_agg=group(...))
	*	(example: Example is hh68id==2. 2001 and 2002 were living together in 1968. 2001 died in 1970 and pn==2002 became a new head. In 1978, 2002 married 2170, and 2170 became a new head and his child (2173) joined FU. In 1980 2171 moved out, and in 1981 2170 also moved out and 2002 became head again. In 1984 2002 had two children (adopted I guess?) - 2171 and 2172. In 1985 one of the children (2172) moved out. In 1987, 2002 died and 2172 are no longer followed. In this example, 2002 and 2172 have same hhid (as 2172 has same household id as 2002 in every year, even before she appeared in PSID), and 2001, 2170, 2171 and 2173 all have different hhid.
	
	*	First, we drop individuals who have never been head/RP in any given wave, as their family level variables would be observed from their head/RP.
	cap	drop	rp_any
	egen	rp_any=anymatch(${seqnum_all}), values(1)	//	Indicator if indiv was head/RP at least once.
	drop	if	rp_any!=1
	
	*	Second, we replace household id with missing(or zero) of the individuals when they were not head/RP
	*	For example, in case of pn=2002 above, her values will be replaced with zero when she were not head/RP (ex. 1968, 1969, 1978, 1979, 1980) so her own household doesn't exist during that period
	***	But this can be problematic, especially during 1978-1980 in the example above. Need to think about how I deal with it.

	foreach	year	of	global	sample_years	{
	    
		replace	x11102_`year'=.	if	xsqnr_`year'!=1
		
	}
	
	*	Drop FUs which were observed only once, as it does not provide sufficient information.
	egen	fu_nonmiss=rownonmiss(${hhid_all})
	label variable	fu_nonmiss	"Number of non-missing survey period as head/PR"
	drop	if	fu_nonmiss==1
	
	*	Generate the final household id which uniquely identifies a combination of household wave IDs.
	egen hhid_agg = group(x11102_1968-x11102_2019), missing
	drop	hhid_agg_1st
	

	
	*	Import other variables
	
		*	Demogrpahics
		
			*	Gender of Household Head (fam)
			psid use || gender_head [68]V119 [69]V1010 [70]V1240 [71]V1943 [72]V2543 [73]V3096 [74]V3509 [75]V3922 [76]V4437 [77]V5351 [78]V5851 [79]V6463 [80]V7068 [81]V7659 [82]V8353 [83]V8962 [84]V10420 [85]V11607 [86]V13012 [87]V14115 [88]V15131 [89]V16632 [90]V18050 [91]V19350 [92]V20652 [93]V22407 [94]ER2008 [95]ER5007 [96]ER7007 [97]ER10010 [99]ER13011 [01]ER17014 [03]ER21018 [05]ER25018 [07]ER36018 [09]ER42018 [11]ER47318 [13]ER53018 [15]ER60018 [17]ER66018	[19]ER72018	///
			using "C:/Users/Seungmin Lee/Desktop/psidtemp/installed" , keepnotes design(any) clear		
			tempfile	gender_head
			save	`gender_head'
			
			




br	x11101 x11102_1968 relrp1968	x11102_1969	xsqnr_1969	relrp1969	x11102_1970	xsqnr_1970	x11102_1971	xsqnr_1971	x11102_1972	xsqnr_1972	x11102_1973	xsqnr_1973	x11102_1974	xsqnr_1974	x11102_1975	xsqnr_1975	x11102_1976	xsqnr_1976

*	Demographics

		


*	Food expenditure

	*	At home
	
		*	At home expenditure, until 1993 (annual, stamp excluded)
		psid use || foodexp_home  [68]V37 [69]V500 [70]V1175 [71]V1876 [72]V2476 [74]V3441 [75]V3841 [76]V4354 [77]V5271 [78]V5770 [79]V6376 [80]V6972 [81]V7564 [82]V8256 [83]V8864 [84]V10235 [85]V11375 [86]V12774 [87]V13876 [90]V17807 [91]V19107 [92]V20407 [93]V21707 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_home_pre1994
		save	`foodexp_home_pre1994'
					
		*	Annual amount saved from grown foods (available from 68-72, 79)
		**	Might be used later.... (ex. can be added later)
		psid use || foodexp_home_grown  	[68]V39 [69]V508 [70]V1179 [71]V1880 [72]V2485 [79]V6385	using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_home_grown
		save	`foodexp_home_grown'
		
		*	At home expenditure (since 1994, for those who didn't redeem food stamp, thus no stamp value)
		*	Free recall period, thus should be combined with recall period variable
		psid use || foodexp_home_nostamp  [94]ER3085 [95]ER6084 [96]ER8181 [97]ER11076 [99]ER14295 [01]ER18431 [03]ER21696 [05]ER25698 [07]ER36716 [09]ER42722 [11]ER48038 [13]ER53735 [15]ER60750 [17]ER66797 [19]ER72801 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_home_nostamp
		save	`foodexp_home_nostamp'
		
		*	Recall period of at home expenditure, when no stamp is used (should be matched with the expenditure above)
	psid use || foodexp_home_nostamp_recall  [94]ER3086 [95]ER6085 [96]ER8182 [97]ER11077 [99]ER14296 [01]ER18432 [03]ER21697 [05]ER25699 [07]ER36717 [09]ER42723 [11]ER48039 [13]ER53736 [15]ER60751 [17]ER66798 [19]ER72802 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_home_nostamp_recall
		save	`foodexp_home_nostamp_recall'
		
		*	Whether spent extra money for at home expenditure (dummy)
		**	If households affirm, then they are asked how much extra money they spent for at-home food
		psid use || foodexp_home_spent_extra  [94]ER3077 [95]ER6076 [96]ER8173 [97]ER11067 [99]ER14287 [01]ER18420 [03]ER21685 [05]ER25687 [07]ER36705 [09]ER42711 [11]ER48027 [13]ER53724 [15]ER60739 [17]ER66786 [19]ER72790 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_home_spent_extra
		save	`foodexp_home_spent_extra'
		
		*	At home expenditure, additional to food stamp value (since 1994, for those who redeemd food stamp, Free recall period)
		**	This question is asked only when household affirmed "did you spend any money in addition to stamp value?"
		psid use || foodexp_home_stamp  [94]ER3078 [95]ER6077 [96]ER8174 [97]ER11068 [99]ER14288 [01]ER18421 [03]ER21686 [05]ER25688 [07]ER36706 [09]ER42712 [11]ER48028 [13]ER53725 [15]ER60740 [17]ER66787 [19]ER72791 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_home_stamp
		save	`foodexp_home_stamp'
		
		*	Recall period of at home expenditure in addition to stamp (should be matched with "additional expenditure" above)
		**	This question is asked only when household affirmed "did you spend any money in addition to stamp value?"
		psid use || foodexp_home_stamp_recall  	[94]ER3079 [95]ER6078 [96]ER8175 [97]ER11069 [99]ER14289 [01]ER18422 [03]ER21687 [05]ER25689 [07]ER36707 [09]ER42713 [11]ER48029 [13]ER53726 [15]ER60741 [17]ER66788 [19]ER72792 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_home_stamp_recall
		save	`foodexp_home_stamp_recall'

		*	At home, imputed annual cost (available since 1999)
		**	Can be used to check whether my individual calculation is correct.
		psid use || foodexp_home_imputed  	 	[99]ER16515A2 [01]ER20456A2 [03]ER24138A2 [05]ER28037A2 [07]ER41027A2 [09]ER46971A2 [11]ER52395A2 [13]ER58212A2 [15]ER65411 [17]ER71488 [19]ER77514 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_home_imputed
		save	`foodexp_home_imputed'
		
	*	Away from home
	
		*	Weekly amount (bracket, 1968-1969)
		**	1968 do not have a exact variable, thus need to be imputed using this variable
		psid use || foodexp_away_cat 	 	[68]V163 [69]V632 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_away_cat
		save	`foodexp_away_cat'
		
		*	Annual amount (1969-1993)
		psid use || foodexp_away  [69]V506 [70]V1185 [71]V1886 [72]V2480 [74]V3445 [75]V3853 [76]V4368 [77]V5273 [78]V5772 [79]V6378 [80]V6974 [81]V7566 [82]V8258 [83]V8866 [84]V10237 [85]V11377 [86]V12776 [87]V13878 [90]V17809 [91]V19109 [92]V20409 [93]V21711 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_away_pre1994
		save	`foodexp_away_pre1994'
		
		*	Away expenditure (since 1994, for those who didn't redeem food stamp, thus no stamp value)
		*	Free recall period, thus should be combined with recall period variable
		psid use || foodexp_away_nostamp  [94]ER3090 [95]ER6089 [96]ER8186 [97]ER11081 [99]ER14300 [01]ER18438 [03]ER21703 [05]ER25705 [07]ER36723 [09]ER42729 [11]ER48045 [13]ER53742 [15]ER60757 [17]ER66804 [19]ER72808 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_away_nostamp
		save	`foodexp_away_nostamp'
		
		*	Recall period of at home expenditure, when no stamp is used (should be matched with the expenditure above)
	psid use || foodexp_home_nostamp_recall  [94]ER3091 [95]ER6090 [96]ER8187 [97]ER11082 [99]ER14301 [01]ER18439 [03]ER21704 [05]ER25706 [07]ER36724 [09]ER42730 [11]ER48046 [13]ER53743 [15]ER60758 [17]ER66805 [19]ER72809 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_away_nostamp_recall
		save	`foodexp_away_nostamp_recall'

		*	Away expenditure, imputed annual cost (available since 1999)
		**	Can be used to check whether my individual calculation is correct.
		psid use || foodexp_away_imputed  	 	[99]ER16515A3 [01]ER20456A3 [03]ER24138A3 [05]ER28037A3 [07]ER41027A3 [09]ER46971A3 [11]ER52395A3 [13]ER58212A3 [15]ER65412 [17]ER71489 [19]ER77516 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_away_imputed
		save	`foodexp_away_imputed'
		
		*	Annual cost of meals at work/school for the family (1969-1972)
		**	Might be used later...
		psid use || foodexp_atwork  	[69]V502 [70]V1177 [71]V1878 [72]V2483 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_atwork
		save	`foodexp_atwork'
		
		*	Annual cost of meals at work/school for the family (1969-1972)
		**	Might be used later...
		psid use || foodexp_atwork_saved  	[69]V504 [70]V1181 [71]V1882 [72]V2487 using  "${psidtemp}" , keepnotes design(any) clear	
		tempfile	foodexp_atwork_saved
		save	`foodexp_atwork_saved'
		
		
	*	Delivery
	
	


use	`age', clear
merge 1:1 x11101ll using `splitoff', keepusing(splitoff*) nogen assert(3)
merge 1:1 x11101ll using `noresp_why', keepusing(noresp_why*) nogen assert(3)
merge 1:1 x11101ll using `foodexp_home', keepusing(foodexp_home*) nogen assert(3)

gen	origin_fu1969	=	x11102_1968	if	splitoff1969==1

*example code
* replace foodexp_1968 = (food exp of original HHs) if splitoff1969==1
** should I use "merge" to import food exp of original households? Or is there any other way to do it more nicely?
** Doesn't have to, because in the individual data, it is already reflected!
	**	ex) hfid1968=1, pnnum=3 is splitted off in 1969 and formed his/her own fu. his 1968 food exp is equal to his/her parents already.

keep	if	inlist(0,noresp_why1968,noresp_why1969)	/*	Indiv present in 1968	*/





*	Food expenditure at home (excluding food stamp amount) - 1968 ~ 1993
