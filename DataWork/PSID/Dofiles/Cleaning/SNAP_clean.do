
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
	
	global	numJan=1
	global	numFeb=2
	global	numMar=3
	global	numApr=4
	global	numMay=5
	global	numJun=6
	global	numJul=7
	global	numAug=8
	global	numSep=9
	global	numOct=10
	global	numNov=11
	global	numDec=12
	
	global	sample_years	/*1968	1969	1970	1971	1972	1974	1975*/	1976	1977	1978	1979	1980	1981	1982	1983	1984	///
								1985	1986	1987	1990	1991	1992	1993	1994	1995	1996	1997	1999	2001	2003	2005	2007	///
								2009	2011	2013	2015	2017	2019
		
	global	sample_years_comma	/*1968,	1969,	1970,	1971,	1972,	1974,	1975,*/	1976,	1977,	1978,	1979,	1980,	1981,	1982,	1983,	1984,	///
									1985,	1986,	1987,	1990,	1991,	1992,	1993,	1994,	1995,	1996,	1997,	1999,	2001,	2003,	2005,	2007,	///
									2009,	2011,	2013,	2015,	2017,	2019
									
	global	sample_years_no1968		/*1969	1970	1971	1972	1974	1975*/	1976	1977	1978	1979	1980	1981	1982	1983	1984	///
										1985	1986	1987	1990	1991	1992	1993	1994	1995	1996	1997	1999	2001	2003	2005	2007	///
										2009	2011	2013	2015	2017	2019
		
	global	sample_years_no1968_comma	/*1969,	1970,	1971,	1972,	1974,	1975,*/	1976,	1977,	1978,	1979,	1980,	1981,	1982,	1983,	1984,	///
											1985,	1986,	1987,	1990,	1991,	1992,	1993,	1994,	1995,	1996,	1997,	1999,	2001,	2003,	2005,	2007,	///
											2009,	2011,	2013,	2015,	2017,	2019
	
	label	define	yes1no0	0	"No"	1	"Yes",	replace
	
	local	ind_agg			0	//	Aggregate individual-level variables across waves
	local	fam_agg			0	//	Aggregate family-level variables across waves
	local	ext_data		0	//	Prepare external data (CPI, TFP, etc.)
	local	cr_panel		0	//	Create panel structure from ID variable
	local	merge_data		1	//	Merge ind- and family- variables and import it into ID variable
		local	raw_reshape	0		//	Merge raw variables and reshape into long data (takes time)
		local	add_clean	0		//	Do additional cleaning and import external data (CPI, TFP)
		local	import_dta	0		//	Import aggregated variables into ID data. 
	local	clean_vars		1	//	Clean variables and construct consistent variables
	local	summ_stats		0	//	Generate summary statistics (will be moved to another file later)
	
	*	Aggregate individual-level variables
	if	`ind_agg'==1	{

			
			*	Core information - person number, interview number and sequence number
			*	This can be created from "psid use" using any variables). Here I will use "age" variable
			psid use || age_ind   	 	[68]ER30004 [69]ER30023 [70]ER30046 [71]ER30070 [72]ER30094 [73]ER30120 [74]ER30141 [75]ER30163 [76]ER30191 [77]ER30220 [78]ER30249 [79]ER30286 [80]ER30316 [81]ER30346 [82]ER30376 [83]ER30402 [84]ER30432 [85]ER30466 [86]ER30501 [87]ER30538 [88]ER30573 [89]ER30609 [90]ER30645 [91]ER30692 [92]ER30736 [93]ER30809 [94]ER33104 [95]ER33204 [96]ER33304 [97]ER33404 [99]ER33504 [01]ER33604 [03]ER33704 [05]ER33804 [07]ER33904 [09]ER34004 [11]ER34104 [13]ER34204 [15]ER34305 [17]ER34504 [19]ER34704 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			isid	x11101ll	//	Make sure the ID variable uniquely identifies the dataset
				
			preserve
				keep	x11101ll	x11102_*	xsqnr_*
				save	"${SNAP_dtInt}/Ind_vars/ID", replace
			restore
				keep	x11101ll	age_ind*
				save	"${SNAP_dtInt}/Ind_vars/age_ind", replace
				
			
			*	Variables that are constant across years (ex: 1968 person number, sample status)
			use	"${SNAP_dtRaw}/Unpacked/ind2019er.dta", clear
		
			*	Generate ID variable that matches ID data
				generate	x11101ll=(ER30001*1000)+ER30002
			
				*	Rename necessary variables
				* Note: 1968 person number (ER30002) is the last three digits of the individual id created by psid use command
				rename	(ER30002	ER32006	ER31996	ER31997	ER32000)	(pn	sampstat sampstr	sampcls	gender)
			
			keep	x11101ll	pn	sampstat	sampstr	sampcls	gender
			save	"${SNAP_dtInt}/Ind_vars/unique_vars.dta",	replace
			
					
			*	Longitudinal, individual-level
			loc	var	wgt_long_ind
			psid use || `var' [68]ER30019 [69]ER30042 [70]ER30066 [71]ER30090 [72]ER30116 [73]ER30137 [74]ER30159 [75]ER30187 [76]ER30216 [77]ER30245 [78]ER30282 [79]ER30312 [80]ER30342 [81]ER30372 [82]ER30398 [83]ER30428 [84]ER30462 [85]ER30497 [86]ER30534 [87]ER30569 [88]ER30605 [89]ER30641 [90]ER30686 [91]ER30730 [92]ER30803	[93]ER30864 [94]ER33119 [95]ER33275 [96]ER33318	[97]ER33430	[99]ER33546 [01]ER33637 [03]ER33740 [05]ER33848 [07]ER33950 [09]ER34045 [11]ER34154 [13]ER34268 [15]ER34413 [17]ER34650	[19]ER34863	using "${SNAP_dtRaw}/Unpacked", keepnotes design(any) clear	
		
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Ind_vars/`var'", replace
			
			*	Relation to head/RP
			loc	var	relrp
			psid use || `var' [68]ER30003 [69]ER30022 [70]ER30045 [71]ER30069 [72]ER30093 [73]ER30119 [74]ER30140 [75]ER30162 [76]ER30190 [77]ER30219 [78]ER30248 [79]ER30285 [80]ER30315 [81]ER30345 [82]ER30375 [83]ER30401 [84]ER30431 [85]ER30465 [86]ER30500 [87]ER30537 [88]ER30572 [89]ER30608 [90]ER30644 [91]ER30691 [92]ER30735 [93]ER30808 [94]ER33103 [95]ER33203 [96]ER33303 [97]ER33403 [99]ER33503 [01]ER33603 [03]ER33703 [05]ER33803 [07]ER33903 [09]ER34003 [11]ER34103 [13]ER34203 [15]ER34303 [17]ER34503 [19]ER34703	using "${SNAP_dtRaw}/Unpacked", keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Ind_vars/`var'", replace
			
			*	Original family (where this split-off family was splitted. split-off family only )
			loc	var	origfu_id
			psid use || `var'  	[69]ER30039 [70]ER30063 [71]ER30087 [72]ER30113 [73]ER30134 [74]ER30156 [75]ER30184 [76]ER30213 [77]ER30242 [78]ER30279 [79]ER30309 [80]ER30339 [81]ER30369 [82]ER30395 [83]ER30424 [84]ER30458 [85]ER30493 [86]ER30530 [87]ER30565 [88]ER30601 [89]ER30637 [90]ER30679 [91]ER30722 [92]ER30797 [93]ER30858 [94]ER33124 [95]ER33280 [96]ER33321 [97]ER33433 [99]ER33541 [01]ER33632 [03]ER33735 [05]ER33841 [07]ER33941 [09]ER34035 [11]ER34147 [13]ER34254 [15]ER34404 [17]ER34643 [19]ER34852	using "${SNAP_dtRaw}/Unpacked", keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Ind_vars/`var'", replace
			
			*	Reason for non-response
			loc	var	noresp_why
			psid use || `var' [68]ER30018 [69]ER30041 [70]ER30065 [71]ER30089 [72]ER30115 [73]ER30136 [74]ER30158 [75]ER30186 [76]ER30215 [77]ER30244 [78]ER30281 [79]ER30311 [80]ER30341 [81]ER30371 [82]ER30397 [83]ER30427 [84]ER30461 [85]ER30496 [86]ER30533 [87]ER30568 [88]ER30604 [89]ER30640 [90]ER30685 [91]ER30729 [92]ER30802 [93]ER30863 [94]ER33127 [95]ER33283 [96]ER33325 [97]ER33437 [99]ER33545 [01]ER33636 [03]ER33739 [05]ER33847 [07]ER33949 [09]ER34044 [11]ER34153 [13]ER34267 [15]ER34412 [17]ER34649 [19]ER34862  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Ind_vars/`var'", replace
			
	}

	*	Aggregate family-level variables
	if	`fam_agg'==1	{
	
		*	Survey information
		
			*	Date of the interview (1968-1996)
			local	var	svydate
			psid use || `var' [68]V99 [69]V553 [70]V1236 [71]V1939 [72]V2539 [73]V3092 [74]V3505 [75]V3918 [76]V4433 [77]V5347 [78]V5847 [79]V6459 [80]V7064 [81]V7655 [82]V8349 [83]V8958 [84]V10416 [85]V11600 [86]V13008 [87]V14111 [88]V15127 [89]V16628 [90]V18046 [91]V19346 [92]V20648 [93]V22403 [94]ER2005 [95]ER5004 [96]ER7004  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Month of the interview (1997-2019)
			local	var	svymonth
			psid use || `var'  	[97]ER10005 [99]ER13006 [01]ER17009 [03]ER21012 [05]ER25012 [07]ER36012 [09]ER42012 [11]ER47312 [13]ER53012 [15]ER60012 [17]ER66012 [19]ER72012  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
						
			*	Day of the interview (1997-2019)
			local	var	svyday
			psid use || `var'  	[97]ER10006 [99]ER13007 [01]ER17010 [03]ER21013 [05]ER25013 [07]ER36013 [09]ER42013 [11]ER47313 [13]ER53013 [15]ER60013 [17]ER66013 [19]ER72013  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			
			*	Split-off indicator
			local	var	splitoff
			psid use || `var' [69]V909 [70]V1106 [71]V1806 [72]V2407 [73]V3007 [74]V3407 [75]V3807 [76]V4307 [77]V5207 [78]V5707 [79]V6307 [80]V6907 [81]V7507 [82]V8207 [83]V8807 [84]V10007 [85]V11107 [86]V12507 [87]V13707 [88]V14807 [89]V16307 [90]V17707 [91]V19007 [92]V20307 [93]V21606 [94]ER2005F [95]ER5005F [96]ER7005F [97]ER10005F [99]ER13005E [01]ER17006 [03]ER21005 [05]ER25005 [07]ER36005 [09]ER42005 [11]ER47305 [13]ER53005 [15]ER60005 [17]ER66005 [19]ER72005  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Longitudinal weight, family-level
			*	I combind 3 series of variables; core (1968-1992), revised (1993-1996) and combined core and immigrant (1997-2019)
			local	var	wgt_long_fam
			psid use || `var' 	[68]V439 [69]V1014 [70]V1609 [71]V2321 [72]V2968 [73]V3301 [74]V3721 [75]V4224 [76]V5099 [77]V5665 [78]V6212 [79]V6805 [80]V7451 [81]V8103 [82]V8727 [83]V9433 [84]V11079 [85]V12446 [86]V13687 [87]V14737 [88]V16208 [89]V17612 [90]V18943 [91]V20243 [92]V21547	///
								[93]V23361 [94]ER4160 [95]ER7000 [96]ER9251	///
								[97]ER12084 [99]ER16518 [01]ER20394 [03]ER24179 [05]ER28078 [07]ER41069 [09]ER47012 [11]ER52436 [13]ER58257 [15]ER65492 [17]ER71570 [19]ER77631	///
								using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace	 	
				
		*	Demogrpahics
		
			*	Gender (RP)
			local	var	rp_gender
			psid use || `var' [68]V119 [69]V1010 [70]V1240 [71]V1943 [72]V2543 [73]V3096 [74]V3509 [75]V3922 [76]V4437 [77]V5351 [78]V5851 [79]V6463 [80]V7068 [81]V7659 [82]V8353 [83]V8962 [84]V10420 [85]V11607 [86]V13012 [87]V14115 [88]V15131 [89]V16632 [90]V18050 [91]V19350 [92]V20652 [93]V22407 [94]ER2008 [95]ER5007 [96]ER7007 [97]ER10010 [99]ER13011 [01]ER17014 [03]ER21018 [05]ER25018 [07]ER36018 [09]ER42018 [11]ER47318 [13]ER53018 [15]ER60018 [17]ER66018	[19]ER72018	///
			using "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Age (RP)
			local	var	rp_age
			psid use || `var' [68]V117 [69]V1008 [70]V1239 [71]V1942 [72]V2542 [73]V3095 [74]V3508 [75]V3921 [76]V4436 [77]V5350 [78]V5850 [79]V6462 [80]V7067 [81]V7658 [82]V8352 [83]V8961 [84]V10419 [85]V11606 [86]V13011 [87]V14114 [88]V15130 [89]V16631 [90]V18049 [91]V19349 [92]V20651 [93]V22406 [94]ER2007 [95]ER5006 [96]ER7006 [97]ER10009 [99]ER13010 [01]ER17013 [03]ER21017 [05]ER25017 [07]ER36017 [09]ER42017 [11]ER47317 [13]ER53017 [15]ER60017 [17]ER66017 [19]ER72017	///
			using "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Marital status (RP)
			local	var	rp_marital
			psid use || `var' [68]V239 [69]V607 [70]V1365 [71]V2072 [72]V2670 [73]V3181 [74]V3598 [75]V4053 [76]V4603 [77]V5650 [78]V6197 [79]V6790 [80]V7435 [81]V8087 [82]V8711 [83]V9419 [84]V11065 [85]V12426 [86]V13665 [87]V14712 [88]V16187 [89]V17565 [90]V18916 [91]V20216 [92]V21522 [93]V23336 [94]ER4159A [95]ER6999A [96]ER9250A [97]ER12223A [99]ER16423 [01]ER20369 [03]ER24150 [05]ER28049 [07]ER41039 [09]ER46983 [11]ER52407 [13]ER58225 [15]ER65461 [17]ER71540 [19]ER77601	///
			using "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Race (RP)
			local	var	rp_race
			psid use || `var' [68]V181 [69]V801 [70]V1490 [71]V2202 [72]V2828 [73]V3300 [74]V3720 [75]V4204 [76]V5096 [77]V5662 [78]V6209 [79]V6802 [80]V7447 [81]V8099 [82]V8723 [83]V9408 [84]V11055 [85]V11938 [86]V13565 [87]V14612 [88]V16086 [89]V17483 [90]V18814 [91]V20114 [92]V21420 [93]V23276 [94]ER3944 [95]ER6814 [96]ER9060 [97]ER11848 [99]ER15928 [01]ER19989 [03]ER23426 [05]ER27393 [07]ER40565 [09]ER46543 [11]ER51904 [13]ER57659 [15]ER64810 [17]ER70882 [19]ER76897	///
			using "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			
		*	Location
			
			*	State of residence
			local	var	rp_state
			psid use || `var' [68]V93 [69]V537 [70]V1103 [71]V1803 [72]V2403 [73]V3003 [74]V3403 [75]V3803 [76]V4303 [77]V5203 [78]V5703 [79]V6303 [80]V6903 [81]V7503 [82]V8203 [83]V8803 [84]V10003 [85]V11103 [86]V12503 [87]V13703 [88]V14803 [89]V16303 [90]V17703 [91]V19003 [92]V20303 [93]V21603 [94]ER4156 [95]ER6996 [96]ER9247 [97]ER12221 [99]ER13004 [01]ER17004 [03]ER21003 [05]ER25003 [07]ER36003 [09]ER42003 [11]ER47303 [13]ER53003 [15]ER60003 [17]ER66003 [19]ER72003	///
			using "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace

		*	Employment (RP)
		
			*	Employed now (RP)
			**	Caution: I combined two different series of variables: (1) "Working now" (1968-1996) and (2) "Working now, 1st mention" (1997-2019) (available from 1994). Need to harmonize them.
			local	var	rp_employment_status
			psid use || `var'	[68]V196 [69]V639 [70]V1278 [71]V1983 [72]V2581 [73]V3114 [74]V3528 [75]V3967 [76]V4458 [77]V5373 [78]V5872 [79]V6492 [80]V7095 [81]V7706 [82]V8374 [83]V9005 [84]V10453 [85]V11637 [86]V13046 [87]V14146 [88]V15154 [89]V16655 [90]V18093 [91]V19393 [92]V20693 [93]V22448 [94]ER2068 [95]ER5067 [96]ER7163	///
			[97]ER10081 [99]ER13205 [01]ER17216 [03]ER21123 [05]ER25104 [07]ER36109 [09]ER42140 [11]ER47448 [13]ER53148 [15]ER60163 [17]ER66164 [19]ER72164	///
			using "${SNAP_dtRaw}/Unpacked", keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
		
		*	Education
		
			*	Grades completed (head/rp)
			**	Caution: I aggregated two different series of variables into one; "Grade finished" from 1968 to 1990, and "how many grades finished" from 1990 to 2019. So they are not strictl comparable
			**	Even within the single series, the way of coding has changed. For now (2021/11/14) I roughly aggregated it, but it must be further refined to make it as consistent as possible. Please check codebook carefully in doing so.
			local	var	rp_gradecomp
			psid use || `var' [68]V313 [69]V794 [70]V1485 [71]V2197 [72]V2823 [73]V3241 [74]V3663 [75]V4198 [76]V5074 [77]V5647 [78]V6194 [79]V6787 [80]V7433 [81]V8085 [82]V8709 [83]V9395 [84]V11042 [85]V12400 [86]V13640 [87]V14687 [88]V16161 [89]V17545 [90]V18898	[91]V20198 [92]V21504 [93]V23333 [94]ER4158 [95]ER6998 [96]ER9249 [97]ER12222 [99]ER16516 [01]ER20457 [03]ER24148 [05]ER28047 [07]ER41037 [09]ER46981 [11]ER52405 [13]ER58223 [15]ER65459 [17]ER71538 [19]ER77599	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Finished HS or has GED (RP)
			local	var	rp_HS_GED
			psid use || `var' [85]V11945 [86]V13568 [87]V14615 [88]V16089 [89]V17486 [90]V18817 [91]V20117 [92]V21423 [93]V23279 [94]ER3948 [95]ER6818 [96]ER9064 [97]ER11854 [99]ER15937 [01]ER19998 [03]ER23435 [05]ER27402 [07]ER40574 [09]ER46552 [11]ER51913 [13]ER57669 [15]ER64821 [17]ER70893 [19]ER76908	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Finished HS or has GED (Spouse)
			local	var	sp_HS_GED
			psid use || `var' [85]V12300 [86]V13503 [87]V14550 [88]V16024 [89]V17421 [90]V18752 [91]V20052 [92]V21358 [93]V23215 [94]ER3887 [95]ER6757 [96]ER9003 [97]ER11766 [99]ER15845 [01]ER19906 [03]ER23343 [05]ER27306 [07]ER40481 [09]ER46458 [11]ER51819 [13]ER57559 [15]ER64682 [17]ER70755 [19]ER76763	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Attend college (RP)
			local	var	rp_colattend
			psid use || `var'  	[85]V11956 [86]V13579 [87]V14626 [88]V16100 [89]V17497 [90]V18828 [91]V20128 [92]V21434 [93]V23290 [94]ER3959 [95]ER6829 [96]ER9075 [97]ER11865 [99]ER15948 [01]ER20009 [03]ER23446 [05]ER27413 [07]ER40585 [09]ER46563 [11]ER51924 [13]ER57680 [15]ER64832 [17]ER70904 [19]ER76919	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Attend college (Spouse)
			local	var	sp_colattend
			psid use || `var'   	[85]V12311 [86]V13510 [87]V14557 [88]V16031 [89]V17428 [90]V18759 [91]V20059 [92]V21365 [93]V23222 [94]ER3894 [95]ER6764 [96]ER9010 [97]ER11777 [99]ER15856 [01]ER19917 [03]ER23354 [05]ER27317 [07]ER40492 [09]ER46469 [11]ER51830 [13]ER57570 [15]ER64693 [17]ER70766 [19]ER76774	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Received College degree (RP)
			local	var	rp_coldeg
			psid use || `var'   [75]V4099 [76]V4690 [77]V5614 [78]V6163 [79]V6760 [80]V7393 [81]V8045 [82]V8669 [83]V9355 [84]V11002 [85]V11960 [86]V13583 [87]V14630 [88]V16104 [89]V17501 [90]V18832 [91]V20132 [92]V21438 [93]V23294 [94]ER3963 [95]ER6833 [96]ER9079 [97]ER11869 [99]ER15952 [01]ER20013 [03]ER23450 [05]ER27417 [07]ER40589 [09]ER46567 [11]ER51928 [13]ER57684 [15]ER64836 [17]ER70908 [19]ER76923	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			 	
			
		*	Disability
				
			*	Work disability (amount)
			**	Note: I combine three different differenet series of variables: (1) "Disability" (1968) (2)  Disability "amount"  (1969-1971) (3) (1972-2019)
			**	This variable will be the basis of determining disability. 
			local	var	rp_disable_amt
			psid use || `var'	[68]V216	///
									[69]V744 [70]V1410 [71]V2122	///
									[72]V2718 [73]V3244 [74]V3666 [75]V4145 [76]V4625 [77]V5560 [78]V6102 [79]V6710 [80]V7343 [81]V7974 [82]V8616 [83]V9290 [84]V10879 [85]V11993 [86]V13427 [87]V14515 [88]V15994 [89]V17391 [90]V18722 [91]V20022 [92]V21322 [93]V23181 [94]ER3854 [95]ER6724 [96]ER8970 [97]ER11724 [99]ER15449 [01]ER19614 [03]ER23014 [05]ER26995 [07]ER38206 [09]ER44179 [11]ER49498 [13]ER55248 [15]ER62370 [17]ER68424 [19]ER74432	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Work disability (type) (1969-1971)
			**	During 1969-1971 "amount" and "type" of disability are separately collected. This is "type" varable
			**	RP will be coded as disabled if either amount or type has issue.
			
			local	var	rp_disable_type
			psid use || `var'	[69]V743 [70]V1409 [71]V2121	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
		*	Family composition
		
			*	# of family members
			loc	var	famnum
			psid use || `var' [68]V115 [69]V549 [70]V1238 [71]V1941 [72]V2541 [73]V3094 [74]V3507 [75]V3920 [76]V4435 [77]V5349 [78]V5849 [79]V6461 [80]V7066 [81]V7657 [82]V8351 [83]V8960 [84]V10418 [85]V11605 [86]V13010 [87]V14113 [88]V15129 [89]V16630 [90]V18048 [91]V19348 [92]V20650 [93]V22405 [94]ER2006 [95]ER5005 [96]ER7005 [97]ER10008 [99]ER13009 [01]ER17012 [03]ER21016 [05]ER25016 [07]ER36016 [09]ER42016 [11]ER47316 [13]ER53016 [15]ER60016 [17]ER66016 [19]ER72016	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	# of childrens
			loc	var	childnum
			psid use || `var' [68]V398 [69]V550 [70]V1242 [71]V1945 [72]V2545 [73]V3098 [74]V3511 [75]V3924 [76]V4439 [77]V5353 [78]V5853 [79]V6465 [80]V7070 [81]V7661 [82]V8355 [83]V8964 [84]V10422 [85]V11609 [86]V13014 [87]V14117 [88]V15133 [89]V16634 [90]V18052 [91]V19352 [92]V20654 [93]V22409 [94]ER2010 [95]ER5009 [96]ER7009 [97]ER10012 [99]ER13013 [01]ER17016 [03]ER21020 [05]ER25020 [07]ER36020 [09]ER42020 [11]ER47320 [13]ER53020 [15]ER60021 [17]ER66021 [19]ER72021	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
		
		*	Income
		
			*	Total family income
			loc	var	fam_income
			psid use || `var' [68]V81 [69]V529 [70]V1514 [71]V2226 [72]V2852 [73]V3256 [74]V3676 [75]V4154 [76]V5029 [77]V5626 [78]V6173 [79]V6766 [80]V7412 [81]V8065 [82]V8689 [83]V9375 [84]V11022 [85]V12371 [86]V13623 [87]V14670 [88]V16144 [89]V17533 [90]V18875 [91]V20175 [92]V21481 [93]V23322 [94]ER4153 [95]ER6993 [96]ER9244 [97]ER12079 [99]ER16462 [01]ER20456 [03]ER24099 [05]ER28037 [07]ER41027 [09]ER46935 [11]ER52343 [13]ER58152 [15]ER65349 [17]ER71426 [19]ER77448	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
		
		*	Food Security (HFSM)
		
			*	Raw score (0-18)
			loc	var	HFSM_raw
			psid use || `var' [99]ER14331S [01]ER18470S [03]ER21735S [15]ER60797 [17]ER66845 [19]ER72849	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			
			*	Scale score (0-9.3)
			loc	var	HFSM_scale
			psid use || `var' [99]ER14331T [01]ER18470T [03]ER21735T [15]ER60798 [17]ER66846 [19]ER72850	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Category (FS, MFS, FI, VFI)
			loc	var	HFSM_cat
			psid use || `var' [99]ER14331U [01]ER18470U [03]ER21735U [15]ER60799 [17]ER66847 [19]ER72851	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
		
		
		*	Food stamp usage & amount
		*	Previusoly I planned to use previous year's food stamp redemption amount, but I decided to use previous "MONTH" amount for more accurate match with expenditure
			*	Expenditure questions differ based on previosu "MONTH" redemption, and food expenditure recall period are often "WEEKLY" or "MONTHLY"
			
			*	Used food stamp last MONTH
			*	I combine three series of variables: (1) Amount saved last month (1975-1997) (2) Current year with free recall period (so I can convert it to monthly amount) (1999-2007) (3) Last month (2009-2019)
			*	This variable is important as households' food expenditure are separately collected based on this response.
			loc	var	stamp_useamt_month
			psid use || `var'		[75]V3846 [76]V4359 [77]V5269 [78]V5768 [79]V6374 [80]V6970 [81]V7562 [82]V8254 [83]V8862 [84]V10233 [85]V11373 [86]V12772 [87]V13874 [90]V17805 [91]V19105 [92]V20405 [93]V21703 [94]ER3076 [95]ER6075 [96]ER8172 [97]ER11066	///	/* first series*/
									[99]ER14285 [01]ER18417 [03]ER21682 [05]ER25684 [07]ER36702	///	/*	Second series. Should be combind with recall period variable	*/
									[09]ER42709 [11]ER48025 [13]ER53722 [15]ER60737 [17]ER66784 [19]ER72788, keepnotes design(any) clear		/*	Third series*/
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace						
			
			*	Stamp amount used recall periods
			*	Should be combined with the amount redeemed this year ([99]ER14285...)
			loc	var	stamp_cntyr_recall
			psid use || `var'  [99]ER14286 [01]ER18418 [03]ER21683 [05]ER25685 [07]ER36703	///
			using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Whether food stamp is used last month
			*	HH food expenditure is collected in separate variables (FS or non-FS) based on this variable.
			*	I will keep it just in case, as redemption status can be found from amount used
			loc	var	stamp_usewth_month
			psid use || `var'  [94]ER3074 [95]ER6073 [96]ER8170 [97]ER11064 [09]ER42707 [11]ER48023 [13]ER53720 [15]ER60735 [17]ER66782 [19]ER72786	///
			using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Whether food stamp is used "current year"
			*	HH food expenditure is collected in separate variables (FS or non-FS) based on this variable.
			*	The following years ask redemption "this year" instead of "last month"
			loc	var	stamp_usewth_crtyear
			psid use || `var'   	[99]ER14270 [01]ER18402 [03]ER21668 [05]ER25670 [07]ER36688	///
			using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	FS used (each month) (1999-2007)
			*	These variables can be used to see monthly distribution of FS usage, and can also be used to construct "FS used last month" when such dummy is not available (1999-2007)
			{
				*	FS used (Jan)
				loc	var	stamp_usewth_crtJan
				psid use || `var'   	[99]ER14271 [01]ER18403 [03]ER21669 [05]ER25671 [07]ER36689	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Feb)
				loc	var	stamp_usewth_crtFeb
				psid use || `var'   	[99]ER14272 [01]ER18404 [03]ER21670 [05]ER25672 [07]ER36690	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Mar)
				loc	var	stamp_usewth_crtMar
				psid use || `var'   	[99]ER14273 [01]ER18405 [03]ER21671 [05]ER25673 [07]ER36691	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Apr)
				loc	var	stamp_usewth_crtApr
				psid use || `var'   	[99]ER14274 [01]ER18406 [03]ER21672 [05]ER25674 [07]ER36692	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (May)
				loc	var	stamp_usewth_crtMay
				psid use || `var'   	[99]ER14275 [01]ER18407 [03]ER21673 [05]ER25675 [07]ER36693	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Jun)
				loc	var	stamp_usewth_crtJun
				psid use || `var'   	[99]ER14276 [01]ER18408 [03]ER21674 [05]ER25676 [07]ER36694	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Jul)
				loc	var	stamp_usewth_crtJul
				psid use || `var'   	[99]ER14277 [01]ER18409 [03]ER21675 [05]ER25677 [07]ER36695	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Aug)
				loc	var	stamp_usewth_crtAug
				psid use || `var'   	[99]ER14278 [01]ER18410 [03]ER21676 [05]ER25678 [07]ER36696	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Sep)
				loc	var	stamp_usewth_crtSep
				psid use || `var'   	[99]ER14279 [01]ER18411 [03]ER21677 [05]ER25679 [07]ER36697	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Oct)
				loc	var	stamp_usewth_crtOct
				psid use || `var'   	[99]ER14280 [01]ER18412 [03]ER21678 [05]ER25680 [07]ER36698	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Nov)
				loc	var	stamp_usewth_crtNov
				psid use || `var'   	[99]ER14281 [01]ER18413 [03]ER21679 [05]ER25681 [07]ER36699	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	FS used (Dec)
				loc	var	stamp_usewth_crtDec
				psid use || `var'   	[99]ER14282 [01]ER18414 [03]ER21680 [05]ER25682 [07]ER36700	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			}	

				
			
			*	The variables below are food stamp information of "previous" year
			*	I was planning to use it, but decided to use last month information due to the reason I stated above.
			*	I will keep it for now, but it won't be used.
			
			{
			*	Value of food stamp "used" (previous yr, annual)
			*	This variable is particularly important for early periods (1968-1979), as these periods have no variables of "food stamp value received" so we can use these variables as a proxy of "value received"
			*	It relies on the assumption that families receive food stamp/SNAP use all of them. But it is basically true from the recent evidence (check the number we cited in PFS paper)
			*	1973 is missing, but doesn't matter as we don't use 1973 periods.
			loc	var	stamp_useamt
			psid use || `var'  [68]V45 [69]V510 [70]V1183 [71]V1884 [72]V2478 [74]V3443 [75]V3851 [76]V4364 [77]V5277 [78]V5776 [79]V6382 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Value of food stamp "received" (previous yr, annual) (1970, 1980-1993)
			loc	var	stamp_recamt_annual
			psid use || `var'  [70]V1765 [80]V6976 [81]V7568 [82]V8260 [83]V8868 [84]V10239 [85]V11379 [86]V12778 [87]V13880 [88]V14895 [89]V16395 [90]V17811 [91]V19111 [92]V20411 [93]V21727 ///
			using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Value of food stamp "used" (previous yr, varying period) (1994-2019)
			*	This series come with different time periods, so need to manually to compute annual food stamp value received
			**	Note: It also exists in 1993 I disable 1993 as I will use the one from the other series above(V21727). We can modify it later if I use this one instead.
			loc	var	stamp_recamt
			psid use || `var'   	/*[93]V21713*/ [94]ER3060 [95]ER6059 [96]ER8156 [97]ER11050 [99]ER14256 [01]ER18387 [03]ER21653 [05]ER25655 [07]ER36673 [09]ER42692 [11]ER48008 [13]ER53705 [15]ER60720 [17]ER66767 [19]ER72771	///
			using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Recall period of the value of food stamp "received" (previous yr, varying periods) (1994-2019)
			*	This should be paired with ER3060 above to annualize food stamp value received
			loc	var	stamp_recamt_period
			psid use || `var'  	/*[93]V21714*/ [94]ER3061 [95]ER6060 [96]ER8157 [97]ER11051 [99]ER14257 [01]ER18388 [03]ER21654 [05]ER25656 [07]ER36674 [09]ER42693 [11]ER48009 [13]ER53706 [15]ER60721 [17]ER66768 [19]ER72772	///
			using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Food stamp Usage (previous yr)
			*	This variable directly asks whether FU used food stamp in previous year or not, but this variable is available only certain periods.
			loc	var	stamp_used
			psid use || `var'  	[69]V634 [76]V4366 [77]V5537 [94]ER3059 [95]ER6058 [96]ER8155 [97]ER11049 [99]ER14255 [01]ER18386 [03]ER21652 [05]ER25654 [07]ER36672 [09]ER42691 [11]ER48007 [13]ER53704 [15]ER60719 [17]ER66766 [19]ER72770	///
			using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Months of food stamp used (previous yr)
			*	This variable collects the number of months food stamp is used. We can use this variable to see whether family used food stamp or not. (ex. used if months>=1)
			loc	var	stamp_monthsused
			psid use || `var'  	 	[76]V4367 [77]V5279 [78]V5778 [79]V6384 [80]V6978 [81]V7570 [82]V8262 [83]V8870 [84]V10241 [85]V11381 [86]V12780 [87]V13882 [88]V14897 [89]V16397 [90]V17813 [91]V19113 [92]V20413 [93]V21729	///
			using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			}			
		
		*	Food expenditure

			*	At home expenditure, until 1993 (annual, stamp excluded)
			*	Note: This variable includes "cost of food delivered to door". Please find the codebook of variable V21707.
			loc	var	foodexp_home_annual
			psid use || `var'  [68]V37 [69]V500 [70]V1175 [71]V1876 [72]V2476 [74]V3441 [75]V3841 [76]V4354 [77]V5271 [78]V5770 [79]V6376 [80]V6972 [81]V7564 [82]V8256 [83]V8864 [84]V10235 [85]V11375 [86]V12774 [87]V13876 [90]V17807 [91]V19107 [92]V20407 [93]V21707 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
						
			*	Annual amount saved from grown foods (available from 68-72, 79)
			**	Might be used later.... (ex. can be added later)
			loc	var	foodexp_home_grown
			psid use || `var'  	[68]V39 [69]V508 [70]V1179 [71]V1880 [72]V2485 [79]V6385	using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	At home expenditure (since 1994, for those who didn't redeem food stamp, thus no stamp value)
			*	Free recall period, thus should be combined with recall period variable
			loc	var	foodexp_home_nostamp
			psid use || `var'  [94]ER3085 [95]ER6084 [96]ER8181 [97]ER11076 [99]ER14295 [01]ER18431 [03]ER21696 [05]ER25698 [07]ER36716 [09]ER42722 [11]ER48038 [13]ER53735 [15]ER60750 [17]ER66797 [19]ER72801 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Recall period of at home expenditure, when no stamp is used (should be matched with the expenditure above)
			loc	var	foodexp_home_nostamp_recall
			psid use || `var'  [94]ER3086 [95]ER6085 [96]ER8182 [97]ER11077 [99]ER14296 [01]ER18432 [03]ER21697 [05]ER25699 [07]ER36717 [09]ER42723 [11]ER48039 [13]ER53736 [15]ER60751 [17]ER66798 [19]ER72802 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace	
			
			*	Whether spent extra money for at home expenditure (dummy)
			**	If households affirm, then they are asked how much extra money they spent for at-home food
			loc	var	foodexp_home_spent_extra
			psid use || `var'  [94]ER3077 [95]ER6076 [96]ER8173 [97]ER11067 [99]ER14287 [01]ER18420 [03]ER21685 [05]ER25687 [07]ER36705 [09]ER42711 [11]ER48027 [13]ER53724 [15]ER60739 [17]ER66786 [19]ER72790 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	At home expenditure, additional to food stamp value (since 1994, for those who redeemd food stamp, Free recall period)
			**	This question is asked only when household affirmed "did you spend any money in addition to stamp value?"
			loc	var	foodexp_home_stamp
			psid use || `var'  [94]ER3078 [95]ER6077 [96]ER8174 [97]ER11068 [99]ER14288 [01]ER18421 [03]ER21686 [05]ER25688 [07]ER36706 [09]ER42712 [11]ER48028 [13]ER53725 [15]ER60740 [17]ER66787 [19]ER72791 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Recall period of at home expenditure in addition to stamp (should be matched with "additional expenditure" above)
			**	This question is asked only when household affirmed "did you spend any money in addition to stamp value?"
			loc	var	foodexp_home_stamp_recall
			psid use || `var'  	[94]ER3079 [95]ER6078 [96]ER8175 [97]ER11069 [99]ER14289 [01]ER18422 [03]ER21687 [05]ER25689 [07]ER36707 [09]ER42713 [11]ER48029 [13]ER53726 [15]ER60741 [17]ER66788 [19]ER72792 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace

			*	At home, imputed annual cost (available since 1999)
			**	Can be used to check whether my individual calculation is correct.
			loc	var	foodexp_home_imputed
			psid use || `var'  	 	[99]ER16515A2 [01]ER20456A2 [03]ER24138A2 [05]ER28037A2 [07]ER41027A2 [09]ER46971A2 [11]ER52395A2 [13]ER58212A2 [15]ER65411 [17]ER71488 [19]ER77514 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
		*	Away from home
		
			*	Weekly amount (bracket, 1968-1969)
			**	1968 do not have a exact variable, thus need to be imputed using this variable
			loc	var	foodexp_away_cat
			psid use || `var' 	 	[68]V163 [69]V632 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Annual amount (1969-1993)
			loc	var	foodexp_away_annual
			psid use || `var'  [69]V506 [70]V1185 [71]V1886 [72]V2480 [74]V3445 [75]V3853 [76]V4368 [77]V5273 [78]V5772 [79]V6378 [80]V6974 [81]V7566 [82]V8258 [83]V8866 [84]V10237 [85]V11377 [86]V12776 [87]V13878 [90]V17809 [91]V19109 [92]V20409 [93]V21711 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Away expenditure (since 1994, for those who used FS)
			*	Free recall period, thus should be combined with recall period variable
			loc	var	foodexp_away_stamp
			psid use || `var'  	[94]ER3083 [95]ER6082 [96]ER8179 [97]ER11073 [99]ER14293 [01]ER18428 [03]ER21693 [05]ER25695 [07]ER36713 [09]ER42719 [11]ER48035 [13]ER53732 [15]ER60747 [17]ER66794 [19]ER72798 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Recall period of at home expenditure, when FS used (should be matched with the expenditure above)
			loc	var	foodexp_away_stamp_recall
			psid use || `var'  [94]ER3084 [95]ER6083 [96]ER8180 [97]ER11074 [99]ER14294 [01]ER18429 [03]ER21694 [05]ER25696 [07]ER36714 [09]ER42720 [11]ER48036 [13]ER53733 [15]ER60748 [17]ER66795 [19]ER72799 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Away expenditure (since 1994, for those who didn't redeem food stamp, thus no stamp value)
			*	Free recall period, thus should be combined with recall period variable
			loc	var	foodexp_away_nostamp
			psid use || `var'  [94]ER3090 [95]ER6089 [96]ER8186 [97]ER11081 [99]ER14300 [01]ER18438 [03]ER21703 [05]ER25705 [07]ER36723 [09]ER42729 [11]ER48045 [13]ER53742 [15]ER60757 [17]ER66804 [19]ER72808 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Recall period of at home expenditure, when no stamp is used (should be matched with the expenditure above)
			loc	var	foodexp_away_nostamp_recall
			psid use || `var'  [94]ER3091 [95]ER6090 [96]ER8187 [97]ER11082 [99]ER14301 [01]ER18439 [03]ER21704 [05]ER25706 [07]ER36724 [09]ER42730 [11]ER48046 [13]ER53743 [15]ER60758 [17]ER66805 [19]ER72809 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace

			*	Away expenditure, imputed annual cost (available since 1999)
			**	Can be used to check whether my individual calculation is correct.
			loc	var	foodexp_away_imputed
			psid use || `var'  	 	[99]ER16515A3 [01]ER20456A3 [03]ER24138A3 [05]ER28037A3 [07]ER41027A3 [09]ER46971A3 [11]ER52395A3 [13]ER58212A3 [15]ER65412 [17]ER71489 [19]ER77516 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Annual cost of meals at work/school for the family (1969-1972)
			**	Might be used later...
			loc	var	foodexp_atwork
			psid use || `var'  	[69]V502 [70]V1177 [71]V1878 [72]V2483 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Annual cost of meals at work/school for the family (1969-1972)
			**	Might be used later...
			loc	var	foodexp_atwork_saved
			psid use || `var'  	[69]V504 [70]V1181 [71]V1882 [72]V2487 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
		*	Food delivered
		
			*	Whether food is deliverd ot not (no stamp, 1994-2019)
			loc	var	foodexp_deliv_nostamp_wth
			psid use || `var'  [94]ER3087 [95]ER6086 [96]ER8183 [97]ER11078 [99]ER14297 [01]ER18434 [03]ER21699 [05]ER25701 [07]ER36719 [09]ER42725 [11]ER48041 [13]ER53738 [15]ER60753 [17]ER66800 [19]ER72804	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace	
			
			*	Cost of food delivered (no stamp, 1994-2019)
			*	This variable should be added to impute total food expenditure.
			**	Note: there are also dummy variables asking whether money was spent or not, but it might not be needed as their amount are coded as zero.
			loc	var	foodexp_deliv_nostamp
			psid use || `var'  [94]ER3088 [95]ER6087 [96]ER8184 [97]ER11079 [99]ER14298 [01]ER18435 [03]ER21700 [05]ER25702 [07]ER36720 [09]ER42726 [11]ER48042 [13]ER53739 [15]ER60754 [17]ER66801 [19]ER72805	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Recall period of the cost of food delivered (no stamp, 1994-2019)
			loc	var	foodexp_deliv_nostamp_recall
			psid use || `var' 	[94]ER3089 [95]ER6088 [96]ER8185 [97]ER11080 [99]ER14299 [01]ER18436 [03]ER21701 [05]ER25703 [07]ER36721 [09]ER42727 [11]ER48043 [13]ER53740 [15]ER60755 [17]ER66802 [19]ER72806	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace	
			
			*	Whether food is deliverd ot not (stamp, 1994-2019)
			loc	var	foodexp_deliv_stamp_wth
			psid use || `var'  [94]ER3080 [95]ER6079 [96]ER8176 [97]ER11070 [99]ER14290 [01]ER18424 [03]ER21689 [05]ER25691 [07]ER36709 [09]ER42715 [11]ER48031 [13]ER53728 [15]ER60743 [17]ER66790 [19]ER72794	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			 
			*	Cost of food delivered (stamp, 1994-2019)
			*	This variable should be added to impute total food expenditure.
			**	Note: there are also dummy variables asking whether money was spent or not, but it might not be needed as their amount are coded as zero.
			loc	var	foodexp_deliv_stamp
			psid use || `var'   	[94]ER3081 [95]ER6080 [96]ER8177 [97]ER11071 [99]ER14291 [01]ER18425 [03]ER21690 [05]ER25692 [07]ER36710 [09]ER42716 [11]ER48032 [13]ER53729 [15]ER60744 [17]ER66791 [19]ER72795	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Recall period of the cost of food delivered (stamp, 1994-2019)
			loc	var	foodexp_deliv_stamp_recall
			psid use || `var' 	[94]ER3082 [95]ER6081 [96]ER8178 [97]ER11072 [99]ER14292 [01]ER18426 [03]ER21691 [05]ER25693 [07]ER36711 [09]ER42717 [11]ER48033 [13]ER53730 [15]ER60745 [17]ER66792 [19]ER72796	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
		
		*	Total (imputed,1999-2019)
			loc	var	foodexp_tot_imputed
			psid use || `var' 	[99]ER16515A1 [01]ER20456A1 [03]ER24138A1 [05]ER28037A1 [07]ER41027A1 [09]ER46971A1 [11]ER52395A1 [13]ER58212A1 [15]ER65410 [17]ER71487 [19]ER77513	///
				using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
		
		 	
			
		
	}

	*	Prepare external data
	if	`ext_data'==1	{
		
		*	CPI data (to convert current to real dollars)
		import excel	"${clouldfolder}/DataWork/CPI/CPI_1913_2021.xlsx", firstrow 	clear
		keep	Year-Dec

		rename	(Year	Jan   Feb   Mar   Apr   May   June  July  Aug   Sep   Oct   Nov   Dec)	///
				(year	CPI1	CPI2	CPI3	CPI4	CPI5	CPI6	CPI7	CPI8	CPI9	CPI10	CPI11	CPI12)

		reshape	long	CPI,	i(year)	j(month)
		label	var	CPI	"Consumer Price Index (CPI)"

		gen	yearmonth	=	year*100+month
		gen	prev_yrmonth	=	yearmonth	//	This variable will be used to match main data

		save	"${SNAP_dtInt}/CPI_1913_2021",	replace
		
		
		*	Thrifty Food Plan data
		
			*	Create year data from raw data
			foreach year	of	global	sample_years	{
							
				if	`year'==1975 continue
				di	"year is `year'"
				
				import excel "${clouldfolder}/DataWork/USDA/DataSets/Raw/Food Plans_Cost of Food Reports.xlsx", sheet("thrifty_`year'") firstrow clear
				
				cap	drop	if	state!=1
				cap	drop	state
				reshape long foodcost_, i(gender age) j(month)
				
				isid	gender	age	month

				gen		year=`year'
				rename	age		age_ind
				rename	month	svy_month
				rename	foodcost_	TFP_monthly_cost
				lab	var	TFP_monthly_cost	"Monthly TFP cost"
				order	year	gender	age_ind	svy_month	TFP_monthly_cost
				keep	year	gender	age_ind	svy_month	TFP_monthly_cost
				
				save	"${SNAP_dtInt}/TFP cost/TFP_`year'", replace
				
			}
			
			*	Combine yearly data
			use	"${SNAP_dtInt}/TFP cost/TFP_1976", clear
			
			foreach year	of	global	sample_years	{
				
				if	`year'==1976 continue
				append	using	"${SNAP_dtInt}/TFP cost/TFP_`year'"
			
			}
			
			isid year gender age_ind svy_month
			
			save	"${SNAP_dtInt}/TFP cost/TFP_costs_all", replace
			
	}
	
	*	Create panel structure
	if	`cr_panel'==1	{
		
		*	Merge ID with unique vars as well as other survey variables needed for panel data creation
		use	"${SNAP_dtInt}/Ind_vars/ID", clear
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/unique_vars.dta",	nogen	assert(3)
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/wgt_long_ind.dta",	nogen	assert(3)	//	Individual weight
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Fam_vars/wgt_long_fam.dta",	nogen	assert(3)	//	Family weight
		

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
	}
	
	*	Merge variables
	if	`merge_data'==1	{
		
		if	`raw_reshape'==1	{
			
			*	Start with ID variables
			use	"${SNAP_dtInt}/Ind_vars/ID", clear
			merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/unique_vars.dta",	nogen assert(3) keepusing(gender)	//	
			*merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/wgt_long_ind.dta",	nogen	assert(3)	//	Individual weight
			*merge	1:1	x11101ll	using	"${SNAP_dtInt}/Fam_vars/wgt_long_fam.dta",	nogen	assert(3)	//	Family weight
			
			*	Merge individual variables
			cd "${SNAP_dtInt}/Ind_vars"
			
			global	varlist_ind	age_ind	/*wgt_long_ind*/	relrp	origfu_id	noresp_why
			
			foreach	var	of	global	varlist_ind	{
				
				merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(2 3)	keep(3)	//	Longitudinal weight
					
			}
			
					
			*	Merge family variables
			cd "${SNAP_dtInt}/Fam_vars"
		
			global	varlist_fam	svydate	svymonth	svyday	splitoff	///		/*survey info*/
								rp_gender	rp_age	rp_marital	rp_race	///		/*	Demographics	*/
								rp_gradecomp	rp_HS_GED	sp_HS_GED	rp_colattend	sp_colattend	rp_coldeg	///	/*	Education	*/
								rp_state	rp_employment_status	rp_disable_amt	rp_disable_type		///	/*	Other RP/spouse information	*/
								famnum	childnum	///	/*	Family composition	*/
								fam_income	///	/*	Income	*/
								HFSM_raw	HFSM_scale	HFSM_cat	///	/*	HFSM_cat*/
								stamp_useamt_month	stamp_cntyr_recall	stamp_usewth_month	stamp_usewth_crtyear	stamp_useamt	stamp_recamt_annual		stamp_recamt	stamp_recamt_period	stamp_used	stamp_monthsused	///	/*	FS/SNAP usage*/							
								stamp_usewth_crtJan	stamp_usewth_crtFeb	stamp_usewth_crtMar	stamp_usewth_crtApr	stamp_usewth_crtMay	stamp_usewth_crtJun		///	/*	FS/SNAP usage*/
								stamp_usewth_crtJul	stamp_usewth_crtAug	stamp_usewth_crtSep	stamp_usewth_crtOct	stamp_usewth_crtNov	stamp_usewth_crtDec		///	/*	FS/SNAP usage*/						
								foodexp_home_annual	foodexp_home_grown	foodexp_home_nostamp	foodexp_home_nostamp_recall	foodexp_home_spent_extra	foodexp_home_stamp	foodexp_home_stamp_recall	foodexp_home_imputed	///	/* At-home food exp */	///
								foodexp_away_cat	foodexp_away_annual	foodexp_away_stamp	foodexp_away_stamp_recall	foodexp_away_nostamp	foodexp_away_nostamp_recall	foodexp_away_imputed	///	/*	Away food expenditure	*/
								foodexp_atwork	foodexp_atwork_saved	///	/*	At work food expenditure	*/
								foodexp_deliv_nostamp_wth	foodexp_deliv_nostamp	foodexp_deliv_nostamp_recall	foodexp_deliv_stamp_wth	foodexp_deliv_stamp	foodexp_deliv_stamp_recall	///	/*	devliered food expenditure	*/
								foodexp_tot_imputed	/*	total (imputed) food expenditure	*/
		
			foreach	var	of	global	varlist_fam	{
				
				di	"current var is `var'"
				merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(2 3)	keep(3)	
				
			}
			


			
			*	Save (wide-format)	
			*order	hhid_agg,	before(x11101ll)
			*order	pn-fu_nonmiss,	after(x11101ll)
			save	"${SNAP_dtInt}/SNAP_RawMerged_wide",	replace
			
			*	Re-shape it into long format	
			reshape long x11102_	xsqnr_	wgt_long_ind	wgt_long_fam	wgt_long_fam_adj	living_Sample tot_living_Sample	${varlist_ind}	${varlist_fam}, i(x11101ll) j(year)
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
			label	var	wgt_long_ind	"Longitudinal individual Weight"
			label	var	wgt_long_fam	"Longitudinal family Weight"
			label	var	living_Sample	"=1 if Sample member living in FU"
			label	var	tot_living_Sample	"# of Sample members living in FU"
			label	var	wgt_long_fam_adj	"Longitudianl family weight, adjusted"
			label	var	age_ind			"Age of individual"
			label 	var	relrp		"Relation to RP"
			label	var	origfu_id	"Original FU ID splitted from"
			label	var	noresp_why	"Reason for non-response"
			label	var	splitoff	"(raw) Split-off status"
			label	var	rp_gender	"Gender of RP"

			save	"${SNAP_dtInt}/SNAP_RawMerged_long",	replace
		
		}
			
		if	`add_clean'==1	{
		
		*	Before constructing panel structure, we first construct TFP cost per FU in each unit.
		*	This must be done before constructing, because it requires individual observations which will later be dropped.
		
			use	"${SNAP_dtInt}/SNAP_RawMerged_long",	clear
			
			*	Survey info
			
				*	Month of interview
			
				loc	var	svy_month
				cap	drop	`var'
				gen		`var'=.
				
					local	year=1968
					replace	`var'=3	if	year==`year'	&	inrange(svydate,1,2)	//	March
					replace	`var'=4	if	year==`year'	&	inrange(svydate,3,4)	//	Apr
					replace	`var'=5	if	year==`year'	&	inrange(svydate,5,6)	//	May
					replace	`var'=6	if	year==`year'	&	inrange(svydate,7,9)	//	June (include 0.02% "NA")
					
					local	year=1969
					replace	`var'=2	if	year==`year'	&	inrange(svydate,1,1)	//	Before March 10
					replace	`var'=3	if	year==`year'	&	inrange(svydate,2,3)	//	March
					replace	`var'=4	if	year==`year'	&	inrange(svydate,4,6)	//	Apr
					replace	`var'=5	if	year==`year'	&	inrange(svydate,7,9)	//	May and after (include 1% "NA")
					
					local	year=1970
					replace	`var'=2	if	year==`year'	&	inrange(svydate,1,1)	//	Before March 1
					replace	`var'=3	if	year==`year'	&	inrange(svydate,2,3)	//	March
					replace	`var'=4	if	year==`year'	&	inrange(svydate,4,5)	//	Apr
					replace	`var'=5	if	year==`year'	&	inrange(svydate,6,7)	//	May
					replace	`var'=6	if	year==`year'	&	inrange(svydate,8,9)	//	June and after (include 0.37% "NA")
					
					local	year=1971
					replace	`var'=2	if	year==`year'	&	inrange(svydate,0,0)	//	Before March 1
					replace	`var'=3	if	year==`year'	&	inrange(svydate,1,2)	//	March
					replace	`var'=4	if	year==`year'	&	inrange(svydate,3,4)	//	Apr
					replace	`var'=5	if	year==`year'	&	inrange(svydate,5,6)	//	May
					replace	`var'=6	if	year==`year'	&	inrange(svydate,7,7)	//	June
					replace	`var'=7	if	year==`year'	&	inrange(svydate,8,9)	//	July and after (include 0.21% NA/DK)
					
					local	year=1972
					replace	`var'=2	if	year==`year'	&	inrange(svydate,0,0)	//	Before March 1
					replace	`var'=3	if	year==`year'	&	inrange(svydate,1,2)	//	March
					replace	`var'=4	if	year==`year'	&	inrange(svydate,3,4)	//	Apr
					replace	`var'=5	if	year==`year'	&	inrange(svydate,5,6)	//	May
					replace	`var'=6	if	year==`year'	&	inrange(svydate,7,7)	//	June
					replace	`var'=7	if	year==`year'	&	inrange(svydate,8,9)	//	July and after (include 0.34% NA/DK)
					
					local	startyear=1973
					local	endyear=1979
					replace	`var'=3	if	inrange(year,`startyear',`endyear')	&	inrange(svydate,1,2)	//	March
					replace	`var'=4	if	inrange(year,`startyear',`endyear')	&	inrange(svydate,3,4)	//	Apr
					replace	`var'=5	if	inrange(year,`startyear',`endyear')	&	inrange(svydate,5,6)	//	May
					replace	`var'=6	if	inrange(year,`startyear',`endyear')	&	inrange(svydate,7,7)	//	June
					replace	`var'=7	if	inrange(year,`startyear',`endyear')	&	inrange(svydate,8,9)	//	July and after (include 0.34% NA/DK)
					
					*	1980-1996
					*	Treat missing month as "0"
					local	startyear=1980
					local	endyear=1996
				
					replace	`var'=floor(svydate/100)	if	inrange(year,`startyear',`endyear')	
					replace	`var'=0						if	inrange(year,`startyear',`endyear')	&	svydate==9999	//	NA/mail interview
					replace	`var'=0						if	inrange(year,`startyear',`endyear')	&	svydate==6	//	Wild code (1 obs in 1994)
					
					*	1997-2019
					local	startyear=1997
					local	endyear=2019
					replace	`var'=svymonth	if	inrange(year,`startyear',`endyear')
				
				lab	define	`var'	0	"NA/DK"	1	"Jan"	2	"Feb"	3	"Mar"	4	"Apr"	5	"May"	6	"Jun"	///
												7	"Jul"	8	"Aug"	9	"Sep"	10	"Oct"	11	"Nov"	12	"Dec", replace
				lab	val	`var'	`var'
				
				label	var	`var'	"Survey Month"
				
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
				
					replace	`var'=mod(svydate,100)	if	inrange(year,`startyear',`endyear')	
					replace	`var'=0					if	inrange(year,`startyear',`endyear')	&	svydate==9999	//	NA/mail interview
					replace	`var'=0					if	inrange(year,`startyear',`endyear')	&	svydate==6		//	Wild code (1 obs in 1994)
			
					*	1997-2019
					local	startyear=1997
					local	endyear=2019
					replace	`var'=svyday	if	inrange(year,`startyear',`endyear')
				
				label	var	`var'	"Survey Day"
				
			*	Member status
			*	For now(2021-11-25) I include only (1) RP (2) Living together. We can add more status (ex. relat to HH) later
			
				*	Individual living status ( fromsequence number)
				loc	var	living_status
				cap	drop	`var'
				gen		`var'=.
				
				replace	`var'=0	if	inrange(seqnum,0,0)		//	Inapp; Not existing at the time of interview (ex. alreay died, not yet born, sub-sample before introduction/after attrition, etc.)
				replace	`var'=1	if	inrange(seqnum,1,20)	//	Individua in the family
				replace	`var'=2	if	inrange(seqnum,51,59)	//	In the institution
				replace	`var'=3	if	inrange(seqnum,71,79)	//	Moved out
				replace	`var'=4	if	inrange(seqnum,81,89)	//	Died
				
				label	define	`var'	0	"Inapp"	1	"Living in FU"	2	"In institutions"	3	"Moved out"	4	"Died"
				label	value	`var'	`var'
				
				label	var	`var'	"Living status"
				
				*	Create an indicator whether living in FU now or not (among positive sequence numbers)
				loc	var	live_in_FU
				cap	drop	`var'
				gen		`var'=.	//	0 sequence number
				
				replace	`var'=0	if	inrange(seqnum,21,89)	//	Not living in FU 
				replace	`var'=1	if	inrange(seqnum,1,20)	//	living in FU 
				
				label	value	`var'	yes1no0
				
				label var	`var'	"Currently living in FU"
				
				*	Currently RP
				loc	var	RP
				cap	drop	`var'
				gen			`var'=.	//	0 sequence number
				
				replace	`var'=0	if	inrange(seqnum,2,89)	//	Not living in FU 
				replace	`var'=1	if	inrange(seqnum,1,1)		//	living in FU 
				
				label	value	`var'	yes1no0
				
				label var	`var'	"Reference person(RP)"
		
			*	Calulate family-level TFP cost
			
				*	Import TFP cost data
				merge m:1	year	age_ind gender svy_month using "${SNAP_dtInt}/TFP cost/TFP_costs_all", keep(1 3) keepusing(TFP_monthly_cost)
			
				*	Validate if merge was properly done
				*	Only observations in PSID data with invalid age/survey month/gender are not matched
				local	age_invalid		inlist(age_ind,0,999)
				local	svymon_invalid	svy_month==0
				local	gender_invalid	!inlist(gender,1,2)
				
				assert `age_invalid' | `svymon_invalid'	|	`gender_invalid'	///
					 if inlist(year,${sample_years_comma}) & _merge==1
				drop	_merge	//	drop after validation
				
				*	Sum all individual costs to calculate total monthly cost 
				loc	var	foodexp_W_TFP
				
				bys	year	surveyid:	egen `var'	=	 total(TFP_monthly_cost)	 if !mi(surveyid)	&	live_in_FU // Total household monthly TFP cost 
				
				*	Adjust by the number of families
				replace	`var'	=	`var'*1.2	if	famnum==1	//	1 person family
				replace	`var'	=	`var'*1.1	if	famnum==2	//	2 people family
				replace	`var'	=	`var'*1.05	if	famnum==3	//	3 people family
				replace	`var'	=	`var'*0.95	if	inlist(famnum,5,6)	//	5-6 people family
				replace	`var'	=	`var'*0.90	if	famnum>=7	//	7+ people family
								
				*	Construct per capita TFP cost (thousands) variable
				**	CAUTION: In the original PFS paper I replaced it instead of creating a new one, but here I will create a new one
				**	Make sure to have this in mind when constructing PFS later.
				gen	`var'_pc_th	=	((`var'/famnum)/1000)
				
				label	var	`var'		"Total monthly TFP cost"
				label	var	`var'_pc_th	"Total monthly TFP cost per capita (K)"
		
			*	Save
			save	"${SNAP_dtInt}/SNAP_ExtMerged_long",	replace
		
		}	//	add_clean
		
		if	`import_dta'==1	{
		    				
			use	"${SNAP_dtInt}/Ind_vars/ID_sample_long.dta",	clear
			merge	1:1	x11101ll	year	using "${SNAP_dtInt}/SNAP_ExtMerged_long", nogen assert(2 3) keep(3) 	
								
			*	Import CPI data
			merge	m:1	prev_yrmonth	using	"${SNAP_dtInt}/CPI_1913_2021", keep(1 3) keepusing(CPI)
			
				*	Validate merge
				local	zero_seqnum	seqnum==0
				local	invalid_mth	svy_month==0
				
				assert	`zero_seqnum'	|	`invalid_mth'	if	_merge==1
				drop	_merge
				
			compress
			save	"${SNAP_dtInt}/SNAP_Merged_long",	replace
		}
		
	}	//	merge_data
	
	*	Clean variables
	if	`clean_vars'==1	{
		
		use	"${SNAP_dtInt}/SNAP_Merged_long",	clear
					
			*	Split-off indicator
			*	General rule of treating re-contact family is that, we treat it as "non split-off"
			loc	var	split_off
			cap	drop	`var'
			gen		`var'=.
			
				*	1975-1989, 1991
				replace	`var'=0	if	splitoff==0	&	(inrange(year,1975,1989)	|	year==1991)
				replace	`var'=1	if	splitoff==1	&	(inrange(year,1975,1989)	|	year==1991)
				
				*	1990
				replace	`var'=0	if	inlist(splitoff,0,2,3)	&	year==1990	//	Re-interview, recontact, Latino
				replace	`var'=1	if	inlist(splitoff,0,1)	&	year==1990	//	Split-off
				
				*	1992
				replace	`var'=0	if	inlist(splitoff,0,2,4,5)	&	year==1992	//	Re-interview, recontact, Sample re-contact, Latino recontact
				replace	`var'=1	if	inlist(splitoff,1,3)	&	year==1992	//	Split-off, split-off recontact
				
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
			label	var	`var'	"Split-off FU"
		
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
		replace	`var'=1	if	rp_race==1 // Single, widow, separated, divorced.
		label	value	`var'	yes1no0
		label	var		`var'	"White"
		
		*	State of Residence
		label define	statecode	0	"Inap.: U.S. territory or foreign country"	99	"D.K; N.A"	///
									1	"Alabama"		2	"Arizona"			3	"Arkansas"	///
									4	"California"	5	"Colorado"			6	"Connecticut"	///
									7	"Delaware"		8	"D.C."				9	"Florida"	///
									10	"Georgia"		11	"Idaho"				12	"Illinois"	///
									13	"Indiana"		14	"Iowa"				15	"Kansas"	///
									16	"Kentucky"		17	"Lousiana"			18	"Maine"		///
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
									49	"Wyoming"		50	"Alaska"			51	"Hawaii"
		lab	val	rp_state statecode
		lab	var	rp_state "State of Residence"
		
		*	Drop Alaska and Hawaii
			*	NOTE: dropping only observations without dropping the entire indiv's obs causes unbalanced panel for some indivdiuals (ex. x11101ll==13031, who were grown in CA and formed her own FU in AL)
			*	However, dropping all observations of individual who have ever lived in AL/CA will drop well-balanced indiv (ex. x11101==18041, who lived there only once)
			*	For now (2021-11-27), I will leave them as they are, BUT KEEP IN MIND HAT TFP cost here does NOT consider AL/HA costs in this file (unlike PFS where we did)
			
			/*
			*	If I want to drop all observations of individual who ever lived there once...
			cap drop	live_in_AL_HA
			cap	drop	ever_in_AL_HA
			gen	live_in_AL_HA=1	if	inlist(rp_state,50,51)
			bys	x11101ll:	egen	ever_in_AL_HA	=	max(live_in_AL_HA)
			drop	if	ever_in_AL_HA==1
			drop	live_in_AL_HA	ever_in_AL_HA
			
			*	If I want to drop only the period lived in AL/HA...
			drop	if	inlist(rp_state,50,51)
			*/
		
		*	Employment Status
		*	Two different variables over time, and even single series changes variable over waves. Need to harmonize them.
		loc	var	rp_employed
		cap	drop	`var'
		gen		`var'=.
		
		replace	`var'=0	if	inrange(year,1968,1975)	&	inrange(rp_employment_status,2,6)	//	I treat "Other" as "unemployed". In the raw PSID data less than 0.2% HH answer "other" during these waves
		replace	`var'=1	if	inrange(year,1968,1975)	&	inrange(rp_employment_status,1,1)	//	Include temporarily laid off/maternity leave/etc.
		
		replace	`var'=0	if	inrange(year,1976,1996)	&	inrange(rp_employment_status,3,9)	//	I treat "Other" as "unemployed". In the raw PSID data less than 0.2% HH answer "other" during these waves
		replace	`var'=1	if	inrange(year,1976,1996)	&	inrange(rp_employment_status,1,2)	//	Include temporarily laid off/maternity leave/etc.
		
		replace	`var'=0	if	inrange(year,1997,2019)	&	inrange(rp_employment_status,3,99)	|	rp_employment_status==0	//	Include other, "workfare", "DK/refusal"
		replace	`var'=1	if	inrange(year,1997,2019)	&	inrange(rp_employment_status,1,2)	//	Include temporarily laid off/maternity leave/etc.
		
		
		label	value	`var'	yes1no0
		label	var		`var'	"Employed"
		
		*	Grades completed
		*	We split grade completion into four categories; No HS, HS, some college, College+
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
			replace	`var'=3	if	inrange(year,1968,1990)	&	rp_gradecomp==6	//	College, but no degree
			replace	`var'=3	if	inrange(year,1991,2019)	&	inrange(rp_gradecomp,13,15)	//	13-15 grades
			
			*	College or greater
			replace	`var'=4	if	inrange(year,1968,1990)	&	inrange(rp_gradecomp,7,8)	//	College
			replace	`var'=4	if	inrange(year,1991,2019)	&	inrange(rp_gradecomp,16,17)	//	College, but no degree
			replace	`var'=4	if	inrange(year,1991,2019)	&	rp_coldeg==1	//	Answered "yes" to "has college degree"
			
			*	NA/DK (excluding "cannot read/write in early years")
			replace	`var'=99	if	inrange(year,1968,1990)	&	inrange(rp_gradecomp,9,9)
			replace	`var'=99	if	inrange(year,1991,2019)	&	inrange(rp_gradecomp,99,99)
			
			label	define	`var'	1	"Less than HS"	2	"High School/GED"	3	"Some college"	4	"College"	99	"NA/DK",	replace
			label	value	`var'	`var'
			label 	variable	`var'	"Education category (RP)"
			
			cap	drop	rp_edu?		rp_NoHS	rp_HS	rp_somecol	rp_col
			tab `var', gen(rp_edu)
			rename	(rp_edu1	rp_edu2	rp_edu3	rp_edu4	rp_edu5)	(rp_NoHS	rp_HS	rp_somecol	rp_col	rp_NADK)
			
			lab	value	rp_NoHS	rp_HS	rp_somecol	rp_col	rp_NADK	yes1no0
			
			label	var	rp_NoHS	"Less than High School"
			label	var	rp_HS	"High School"
			label	var	rp_somecol	"College (w/o degree)"
			label	var	rp_col	"College Degree"
			label	var	rp_NADK	"Education (NA/DK)"
			
		*	Disability
		*	I categorize RP as disabled if RP has either "amount" OR "type" of work limitation
		loc	var	rp_disabled
		cap	drop	`var'
		gen		`var'=.
			
			*	NOT disabled, or no problem on work (including NA/DK)
			replace	`var'=0	if	!mi(rp_disable_amt)	|	!mi(rp_disable_type)
			replace	`var'=0	if	inrange(year,1968,1968)	&	inlist(rp_disable_amt,4,5,7,9)	
			replace	`var'=0	if	inrange(year,1969,1971)	&	(inlist(rp_disable_amt,5,9)	&	inlist(rp_disable_type,5,9))	//	both "amount" AND "type" have no restriction
			replace	`var'=0	if	inrange(year,1972,2019)	&	inrange(rp_disable_amt,5,9)	
			
			*	Disabled
			replace	`var'=1	if	inrange(year,1968,1968)	&	inlist(rp_disable_amt,1,2,3)	
			replace	`var'=1	if	inrange(year,1969,1971)	&	(inlist(rp_disable_amt,1,3)	|	inlist(rp_disable_type,1,3))	//	either "amount" OR "type" has an issue
			replace	`var'=1	if	inrange(year,1972,2019)	&	inlist(rp_disable_amt,1,1)	
			
			label	value	`var'	yes1no0
			label	var	`var'	"Disabled"
		
		*	Family composition
		
			label	var	famnum		"FU size"		//	FU size
			label	var	childnum	"# of child"	//	Child size
			
			*	Ratio of child
			loc	var	ratio_child
			cap	drop	`var'
			gen		`var'=	childnum	/	famnum
			label	var	`var'	"\% of children"
		
		
		*	HFSM
			
			lab	var	HFSM_raw	"HFSM (raw score)"
			lab	var	HFSM_scale	"HFSM (scale score)"
			lab	var	HFSM_cat	"HFSM (category)"
			
			*	FI indicator
			loc	var	HFSM_FI
			cap	drop	`var'
			gen		`var'=0	if	inlist(HFSM_cat,0,1)
			replace	`var'=0	if	inlist(HFSM_cat,2,3)
			
			label	value	`var'	yes1no0
			
			label	var	`var'	"HFSM FI"
		
		*	Family income
		
			lab	var	fam_income	"Total family income"
				
		
		*	Food stamp recall period
		loc	var	FS_rec_amt_recall
		cap	drop	`var'
		gen		`var'=.
		replace	`var'=stamp_cntyr_recall	if	inrange(year,1999,2007)
		
		lab	define	`var'	0	"Inapp"		2	"Wild code"	3	"Week"	4	"Two-Week"	5	"Month"	6	"Year"	7	"Other"	8	"DK"	9	"NA/refused", replace
		label	value	`var'	`var'
		label	var	`var'	"FS/SNAP amount received (recall) (1999-2007)"
		
		*	Food stamp amount received
		local	var	FS_rec_amt
		cap	drop	`var'
		gen		double	`var'=.	
		replace	`var'=	stamp_useamt_month	if	inrange(year,1975,2019)	&	!mi(stamp_useamt_month)
		
		
			*	Harmonize variables into monthly amount (1999-2007)
			*	We treat "wild code" and "other" as "zero amount" for now as there are very small number of observations
			replace	`var'=`var'*4.35	if	FS_rec_amt_recall==3			&	inrange(year,1999,2007)	//	If weekly value, multiply by 4.35
			replace	`var'=`var'*2.17	if	FS_rec_amt_recall==4			&	inrange(year,1999,2007)	//	If two-week value, multiply by 2.17
			replace	`var'=`var'/12		if	FS_rec_amt_recall==6			&	inrange(year,1999,2007)	//	If yearly value, divide by 12
			replace	`var'=0				if	inlist(FS_rec_amt_recall,2,7)	&	inrange(year,1999,2007)	//	If wild code, replace it with zero
						
			*	For Other/DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
			foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
			    
				if	inrange(`year',1994,1997)	{	//	1994 to 1997
				
					summ	`var'			if	year==`year'	&	stamp_useamt_month>0	&	!inlist(stamp_useamt_month,997,998,999)	//	I use raw variable's category 
					replace	`var'=r(mean) 	if	year==`year'	&	inlist(stamp_useamt_month,998,999)
				
				}	//	if
				
				else	if	inrange(`year',1999,2007)	{	//	1999 to 2007
				    
					summ	`var'			if	year==`year'	&	stamp_useamt_month>0	&	(!inlist(stamp_useamt_month,999998,999999)	&	!inlist(FS_rec_amt_recall,7,8,9))	//	Check both amount and recall period
					replace	`var'=r(mean)	if	year==`year'	&	(inlist(FS_rec_amt_recall,7,8,9) | inlist(stamp_useamt_month,999998,999999))
					
				}	//	else	if
				
				else	{	//	2009 to 2017 /* Although 999 and 99999 is NOT categorized as dk/na in these years, I included it as dk/na in this code as I believe it is very unrealistic (some FU has this value)
					
					summ	`var'			if	year==`year'	&	stamp_useamt_month>0	&	!inlist(stamp_useamt_month,999,99999,999998,999999)	//	Check both amount and recall period
					replace	`var'=r(mean)	if	year==`year'	&	inlist(stamp_useamt_month,999,99999,999998,999999)
					
				}	//	else
					
			}	//	year
			
		label	var	`var'	"FS/SNAP amount received last month"
		
		
		
		*	Whether FS received last month (1975-1997, 2009-2019)
		*	(1999-2007 will be constructed after constructing "month of FS redeemed")
		loc	var	FS_rec_wth
		cap	drop	`var'
		gen		`var'=.	
		
			*	1975-1993
			*	Here we determine FS status by redeeming non-zero FS amount
			replace	`var'=0	if	inrange(year,1975,1993)		&	FS_rec_amt==0
			replace	`var'=1	if	inrange(year,1975,1993)		&	!mi(FS_rec_amt)	&	FS_rec_amt!=0
			
			*	1994-1997, 2009-2019
			*	Here we have indicator dummy of last month usage so we can directly import it
			*	Any non-missing value other than "yes" (ex. no, wild code, na/dk, inapp) are categorized as "no"
			replace	`var'=0	if	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	&	!mi(stamp_usewth_month)	&	stamp_usewth_month!=1
			replace	`var'=1	if	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	&	!mi(stamp_usewth_month)	&	stamp_usewth_month==1
			
			label	value	`var' yes1no0
			label var	`var'	"FS used last month"
			label var	FS_rec_wth	"FS used last month"

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
			label	var	`var'	"FS used in `month'"
				
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
		label	var	`var'	"FS used this year"
		
		*	Quick summary stat
			tab FS_rec_wth FS_rec_crtyr_wth if inrange(year,1999,2007)
			tab FS_rec_wth if inrange(year,1999,2007) & FS_rec_crtyr_wth==1	//	FU that used FS this year, but not last month
		
		/* I use new code above.
		*	Whether FS/SNAP received last month
		loc	var	FS_rec_wth
		cap	drop	`var'
		gen		`var'=.
					
			*	1975-1993, 1999-2007
			*	The former period doesn't have indicator value, and the latter value has different recall period (current year) so we determine by whether having non-zero FS redemption amount.
				*	If 0, then didn't receive. Otherwise, received
			replace	`var'=0	if	(inrange(year,1975,1993)	|	inrange(year,1999,2007))	&	FS_rec_amt==0
			replace	`var'=1	if	(inrange(year,1975,1993)	|	inrange(year,1999,2007))	&	!mi(FS_rec_amt)	&	FS_rec_amt!=0
			
			*	1994-1997, 2009-2019
			*	Here we have indicator dummy of last month usage so we can directly import it
			*	Any non-missing value other than "yes" (ex. no, wild code, na/dk, inapp) are categorized as "no"
			replace	`var'=0	if	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	&	!mi(stamp_usewth_month)	&	stamp_usewth_month!=1
			replace	`var'=1	if	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	&	!mi(stamp_usewth_month)	&	stamp_usewth_month==1
			
		label	value	`var'	yes1no0
		label	var	`var'	"Received FS/SNAP last month"
		*/

		*	The code below is written for "previous year" stamp information. Since we no longer use it, we will disable it for now. We can re-use the code once found it useful.
		/*
		
		
		*	Food stamp amount "used", recall period
		*	I start with recall period for easier annualization of food stamp amount later
		
		loc	var	FS_rec_amt_recall
		cap	drop	`var'
		gen	`var'=.
		
			*	Set recall period to "inapp (0)" for those with zero amount (didn't receive any)
			replace	`var'=0	if	inrange(year,1968,1979)	&	stamp_useamt==0
			replace	`var'=0	if	inrange(year,1980,1993)	&	stamp_recamt_annual==0
			replace	`var'=0	if	inrange(year,1994,2019)	&	stamp_recamt==0
			
			*	1968 to 1993
			*	During this period recall period is fixed to yearly recall.
			replace	`var'=1	if	inrange(year,1968,1979)	&	!mi(stamp_useamt)	&	stamp_useamt>0
			replace	`var'=1	if	inrange(year,1980,1993)	&	!mi(stamp_useamt)	&	stamp_useamt>0
			
			*	1994 and onward
			*	For 1994, there's no "year" recall period option. I regard "other" as "year" in 1994 because the proportion of those household anwered "other" in 1994 is similar to those who answered "year" in other periods (b/w 1-2%)
			replace	`var'=1	if	inrange(year,1994,1994)	&	stamp_recamt_period==4	//	Year, 1994
			replace	`var'=1	if	inrange(year,1995,2019)	&	stamp_recamt_period==6	//	Year, 1995-2019
			
			replace	`var'=2	if	inrange(year,1994,1995)	&	stamp_recamt_period==1	//	Month, 1994-1995
			replace	`var'=2	if	inrange(year,1996,2019)	&	stamp_recamt_period==5	//	Month, 1996-2019		
			
			replace	`var'=3	if	inrange(year,1994,1995)	&	stamp_recamt_period==2	//	Two-week, 1994-1995
			replace	`var'=3	if	inrange(year,1996,2019)	&	stamp_recamt_period==4	//	Two-week, 1996-2019
			
			replace	`var'=4	if	inrange(year,1994,2019)	&	stamp_recamt_period==3	//	Week, 1994-2019
			
			replace	`var'=5	if	inrange(year,1995,2019)	&	stamp_recamt_period==7	//	Other, 1995-2019
			
			replace	`var'=6	if	inrange(year,1994,2019)	&	stamp_recamt_period==8	//	DK, 1994-2019
			replace	`var'=7	if	inrange(year,1994,2019)	&	stamp_recamt_period==9	//	NA/refusal, 1994-2019
			
			lab	define	`var'	0	"Inapp"		1	"Year"	2	"Month"	3	"Two-week"	4	"Week"	5	"Other"	6	"DK"	7	"NA/refusal", replace
			label	value	`var'	`var'
			label	var	`var'	"FS/SNAP amount received (recall)"
			

		
		*	Food stamp amount received
		loc	var	FS_rec_amt
		cap	drop	`var'
		gen	double	`var'=.	if	inrange(year,1968,1979)	&	!mi(stamp_useamt)
		
			replace	`var'=stamp_useamt			if	inrange(year,1968,1979)	//	From 1968 to 1976, we dont have value "Received", but have value "used(saved)." (we have one in 1970, but use this one instead for consistency) We use this value instead.
			replace	`var'=stamp_recamt_annual	if	inrange(year,1980,1993)	//	Annual
			replace	`var'=stamp_recamt			if	inrange(year,1994,2019)	//	Varying time period. Need to harmonize
			
			*	Harmonize variables into annual amount
			*	We treat "other" as "zero amount" for now as they account for very little obserations (less than 10 per each wave). We can impute some other values later
			***	One important exception is 1994 where there are over a hundred of households answered as "other." I treat them as "yearly" redemption for the following reasons: (1) No "year" period option available (2) Proportion of those household anwered "other" in 1994 is similar to those who answered "year" in other periods (b/w 1-2%)
			replace	`var'=`var'*12.000	if	FS_rec_amt_recall==2	//	If monthly value, multiply by 12
			replace	`var'=`var'*26.072	if	FS_rec_amt_recall==3	//	If two-week value, multiply by 26.072
			replace	`var'=`var'*52.143	if	FS_rec_amt_recall==4	//	If weekly value, multiply by 52
			
			
			*	For Other/DK/NA/refusal (both in amount and recall period), I impute the annualized yearly average from other categories and assign the mean value
			foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
			    
				if	inrange(`year',1994,1997)	{	//	1994 to 1997 which have different outside category values
				
					summ	FS_rec_amt	if	year==`year'	&	stamp_recamt>0	&	!inlist(stamp_recamt,99998,99999)	//	I use raw variable's category
					replace	FS_rec_amt=r(mean) if year==`year'	&	(inlist(FS_rec_amt_recall,6,7) | inlist(stamp_recamt,99998,99999))
				
				}	//	if
				
				else	{	//	1998 to 2019
				    
					summ	FS_rec_amt	if	year==`year'	&	stamp_recamt>0	&	!inlist(stamp_recamt,999998,999999)	//	I use raw variable's category
					replace	FS_rec_amt=r(mean) if year==`year'	&	(inlist(FS_rec_amt_recall,6,7) | inlist(stamp_recamt,999998,999999))
					
				}	//	else
					
				
			}
				
		label	var	`var'	"FS/SNAP amount received"
		
		
		*	Food stamp used or not
		loc	var	FS_used
		cap	drop	`var'
		gen	`var'=.	
		
			*	For years when we directly asked food samp redemption (1976,1977,1994-2019), use that variables.
			**	Note: 1969 also has this value, but I use "amount used" for that year for consistency with nearby years
			*	I treat (DK/NA/refused) as "didn't use." Very small amount of households account for these values
			
			replace	`var'=0	if	inlist(year,1976,1977)	&	!mi(stamp_used)	&	stamp_used!=1
			replace	`var'=1	if	inlist(year,1976,1977)	&	stamp_used==1
			
			replace	`var'=0	if	inrange(year,1994,2019)	&	!mi(stamp_used)	&	stamp_used!=1
			replace	`var'=1	if	inrange(year,1994,2019)	&	stamp_used==1
			
			*	For years when we don't have direct information, use "amount" variable or "number of months"
				
				*	For 1968, we categorize household used food stamp if non-zero amount is redeemed.
				replace	`var'=0	if	year==1968	&	FS_rec_amt==0
				replace	`var'=1	if	year==1968	&	!mi(FS_rec_amt)	&	FS_rec_amt>0
				
				replace	`var'=0	if	year==1968	&	FS_rec_amt==0
				replace	`var'=1	if	year==1968	&	!mi(FS_rec_amt)	&	FS_rec_amt>0
			
				*	For 1968 to 1975, we use "amount used" as proxy
				replace	`var'=0	if	inrange(year,1968,1975)	&	!mi(FS_rec_amt)	&	FS_rec_amt==0
				replace	`var'=1	if	inrange(year,1968,1975)	&	!mi(FS_rec_amt)	&	FS_rec_amt!=0
				
				*	For 1978 to 1993, we use "the number of months" as proxy
				replace	`var'=0	if	inrange(year,1978,1993)	&	!mi(stamp_monthsused)	&	!inrange(stamp_monthsused,1,12)
				replace	`var'=1	if	inrange(year,1978,1993)	&	!mi(stamp_monthsused)	&	inrange(stamp_monthsused,1,12)
			
			lab	value	`var'	yes1no0
			lab	var		`var'	"FS/SNAP used"
		
		
		*	Food expenditure recall periods (1994-2019)
		*	Some years use different category value for recall period. Need to harmonize it.
		recode	foodexp_home_nostamp_recall	foodexp_home_stamp_recall	(1=3)	(2=4)	(3=5)	(4=6)	if	year==1994	//	In 1994, we treat "other" as "year" for the same reason I mentioned earlier.
		recode	foodexp_home_nostamp_recall	foodexp_home_stamp_recall	(2=1)	if	year==2001	//	use different wild code in 2001.
	
		label	define	foodexp_recall	0	"Inapp"	1	"Wide code"	2	"Day"	3	"Week"	4	"Two weeks"	5	"Month"	6	"Year"	7	"Other"	8	"DK"	9	"NA/refused", replace
		label	value	foodexp_home_nostamp_recall	foodexp_home_stamp_recall	foodexp_recall
		label	var	foodexp_home_nostamp_recall	"Food exp recall period (w/o stamp)"
		label	var	foodexp_home_nostamp_recall	"Add. food exp recall period (with stamp)"
		*/
		
		
		*	Food expenditure
		
			*	At-home
			loc	var_inclFS	foodexp_home_inclFS
			loc	var_exclFS	foodexp_home_exclFS
			loc	var_extamt	foodexp_home_extramt
			
			cap	drop	`var_inclFS'
			cap	drop	`var_exclFS'
			cap	drop	`var_extamt'
			gen	double	`var_inclFS'=.	
			gen	double	`var_exclFS'=.	
			gen	double	`var_extamt'=.	
			label	var	`var_inclFS'	"Food exp at home (Monthly) (FS incl)"
			label	var	`var_exclFS'	"Food exp at home (Monthly) (FS excl)"
			label	var	`var_extamt'	"Food exp at home (Monthly), in addition to FS amount"
		
				*	1968-1993
				*	Note: at-home expenditure includes "delivered" during these period.
				*	Convert annual amount to monthly aount
				*	Important: Although "annual food expenditure" is included this period, I divide it my to make monthly food expenidture for two reasons
				*	(1) Food expenditure is separately collected based on "food stamp used last month", thus it allows more accurate matching with food stamp used "last month"
				*	(2) In the questionnaires people were asked "weekly" or "monthly" expenditure, so I assume annual food expenditure reported here is somehow imputed from those values
					
					*loc	var	foodexp_home_mth_pre1994
					*cap	drop	`var'
					*gen	double	`var'=.	
					
					replace	`var_exclFS'=foodexp_home_annual/12	if	inrange(year,1968,1993)
						
					*	Add up FS amount to get food exp including FS amount
					replace	`var_inclFS'=`var_exclFS'	+	FS_rec_amt	if	inrange(year,1968,1993)	&	FS_rec_wth==1	//	Received FS
					replace	`var_inclFS'=`var_exclFS'					if	inrange(year,1968,1993)	&	FS_rec_wth==0	//	Didn't receive FS
					
							
				*	1994-2019
				*	Food exp are collected separately, between FS user and non-user.
					*	For FS user, (1) FS amount (2) Amount in addition to FS are collected
					*	For non-FS user, (1) Food exp is collected.
 				******	CAUTION	****
				*	For 1999-2007, food exps are collected between FS user and non-FS user of "current year"
				*	It implies that even if FS answered "yes" to that question (so (1) and (2) are collected), that doesn't necessarily mean HH used FS last month
				*	Therefore, when we compare "food exp excluding FS amount", we shouuld be very carefully consider it.
				******	CAUTION	****
							
					*	For FS user (the amounte here is food exp "in addition to" FS redeemed)
					
					local	var	`var_extamt'
					local	rawvar			foodexp_home_stamp
					local	rawvar_recall	foodexp_home_stamp_recall
					
					replace	`var'	=	`rawvar'	if	FS_rec_wth==1		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	// Used food stamp last month
					replace	`var'	=	`rawvar'	if	FS_rec_crtyr_wth==1	&	inrange(year,1999,2007)		//	RECALL: food exp is separately collected based on "this year" usage in this peirod (so we can't use 'FS_rec_wth' here)
					
					replace	`var'	=	0			if	FS_rec_wth==0		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	//	If didt' use FS, set it zero
					replace	`var'	=	0			if	FS_rec_crtyr_wth==0	&	inrange(year,1999,2007)		//	RECALL: food exp is separately collected based on "this year" usage in this peirod! (so we can't use 'FS_rec_wth' here)
					
					replace	`var'	=	0			if	inrange(year,1994,2019)		&	inlist(foodexp_home_spent_extra,0,5)	//	If answered "inapp" or "no" to whether extra mount is used, set it as zero
					
					
						*	Make it monthly expenditure
						*	We treat "wild code" and "other" as "zero amount" for now as there are very small number of observations (except 1994 where we treat other as "yearly")					
						replace	`var'	=	`var'*30.4	if	inrange(year,1995,2019)		&	`rawvar_recall'==2	//	If daily value, multiply by 30.4
						replace	`var'	=	`var'*4.35	if	((inrange(year,1994,1994)	&	`rawvar_recall'==1)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==3))	//	If weekly value, multiply by 4.35
						replace	`var'	=	`var'*2.17	if	((inrange(year,1994,1994)	&	`rawvar_recall'==2)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==4))	//	If two-week value, multiply by 2.17
						replace	`var'	=	`var'/12	if	((inrange(year,1994,1994)	&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0			if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,7)))	//	If other or no stamp use, set it zero
					
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	`rawvar'>0	&	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inlist(`rawvar',99998,99999)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	(inlist(`rawvar',99998,99999)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year
					
						*	For FS user, food exp without FS is equal to extra amount above
						replace	`var_exclFS'	=	`var'	if	FS_rec_wth==1		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))
						replace	`var_exclFS'	=	`var'	if	FS_rec_crtyr_wth==1	&	inrange(year,1999,2007)
						
						
					*	For non FS user
					local	var	`var_exclFS'
					local	rawvar			foodexp_home_nostamp
					local	rawvar_recall	foodexp_home_nostamp_recall
					
					replace	`var'	=	`rawvar'	if	FS_rec_wth==0		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	// Didn't food stamp last month
					replace	`var'	=	`rawvar'	if	FS_rec_crtyr_wth==0	&	inrange(year,1999,2007)		//	RECALL: food exp is separately collected based on "this year" usage in this peirod! (so we can't use 'FS_rec_wth' here)
					
					replace	`var'	=	0			if	FS_rec_wth==1		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))	//	If used FS, set it zero
					replace	`var'	=	0			if	FS_rec_crtyr_wth==1	&	inrange(year,1999,2007)	//	RECALL: food exp is separately collected based on "this year" usage in this peirod!	 (so we can't use 'FS_rec_wth' here)					
					
						*	Make it monthly expenditure
						*	We treat "wild code" and "other" as "zero amount" for now as there are very small number of observations (except 1994 where we treat other as "yearly")					
						replace	`var'	=	`var'*30.4	if	inrange(year,1995,2019)		&	`rawvar_recall'==2	//	If daily value, multiply by 30.4
						replace	`var'	=	`var'*4.35	if	((inrange(year,1994,1994)	&	`rawvar_recall'==1)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==3))	//	If weekly value, multiply by 4.35
						replace	`var'	=	`var'*2.17	if	((inrange(year,1994,1994)	&	`rawvar_recall'==2)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==4))	//	If two-week value, multiply by 2.17
						replace	`var'	=	`var'/12	if	((inrange(year,1994,1994)	&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0			if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,1,7)))	//	If other or no stamp use, set it zero
				
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	`rawvar'>0	&	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inlist(`rawvar',99998,99999)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	(inlist(`rawvar',99998,99999)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year	
						
						
					*	Calculate food exp with FS
						
						*	Received FS (FS amount + extra amount spent)
						replace	`var_inclFS'	=	`var_exclFS'	+	FS_rec_amt	if	FS_rec_wth==1		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))
						replace	`var_inclFS'	=	`var_exclFS'	+	FS_rec_amt	if	FS_rec_crtyr_wth==1	&	inrange(year,1999,2007)
						
						*	Didn't receive FS	(Just food exp)
						replace	`var_inclFS'	=	`var_exclFS'	if	FS_rec_wth==0		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))
						replace	`var_inclFS'	=	`var_exclFS'	if	FS_rec_crtyr_wth==0	&	inrange(year,1999,2007)
					
					
					*	Validation of manually imputed data with the imputed data provided in PSID since 1999 
					*	Incomplete, need further work
					/*
					cap drop diff_home
					cap drop foodexp_home_imp_month
					gen foodexp_home_imp_month = foodexp_home_imputed/12

					gen	diff_home=abs(foodexp_home_imp_month-foodexp_home_exclFS)

					br year foodexp_home_stamp_recall foodexp_home_nostamp_recall FS_rec_wth FS_rec_crtyr_wth foodexp_home_inclFS foodexp_home_exclFS foodexp_home_imp_month foodexp_home_imputed diff_home if inrange(year,1999,2019)

					sum diff_home if inrange(year,1999,2019)
					*/
			
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
						replace	`var'	=	`rawvar'/12	if	((inrange(year,1994,1994)	&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0			if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,7)))	//	If other or no stamp use, set it zero
					
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	`rawvar'>0	&	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inlist(`rawvar',99998,99999)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	(inlist(`rawvar',99998,99999)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year
						
					*	For non FS user
					local	var	foodexp_away_NoFS
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
																	
							summ	`var'			if	year==`year'	&	`rawvar'>0	&	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inlist(`rawvar',99998,99999)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	(inlist(`rawvar',99998,99999)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year	
						
						
					*	Create a final variable
						
						*	Received FS (FS amount + extra amount spent)
						replace	`var_eatout'	=	foodexp_away_FS	if	FS_rec_wth==1		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))
						replace	`var_eatout'	=	foodexp_away_FS	if	FS_rec_crtyr_wth==1	&	inrange(year,1999,2007)
						
						*	Didn't receive FS	(Just food exp)
						replace	`var_eatout'	=	foodexp_away_NoFS	if	FS_rec_wth==0		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))
						replace	`var_eatout'	=	foodexp_away_NoFS	if	FS_rec_crtyr_wth==0	&	inrange(year,1999,2007)
						
								
				
				*	Summary stat
				/*
				cap drop diff_away
					cap drop foodexp_away_imp_month
					gen foodexp_away_imp_month = foodexp_away_imputed/12

					gen	diff_away=abs(foodexp_away_imp_month-foodexp_out)

					br year foodexp_away_stamp_recall foodexp_away_nostamp_recall FS_rec_wth FS_rec_crtyr_wth foodexp_out  foodexp_away_imp_month foodexp_away_imputed diff_away if inrange(year,1999,2019)

					sum diff_away if inrange(year,1999,2019)
					
					cap	drop	diff_away
					cap	drop	foodexp_away_imp_month
				*/
				
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
							
					*	For FS user (the amounte here is food exp "in addition to" FS redeemed)
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
						replace	`var'	=	`rawvar'/12	if	((inrange(year,1994,1994)	&	`rawvar_recall'==4)	|	(inrange(year,1995,2019)	&	`rawvar_recall'==6))	//	If yearly value, divide by 12
						replace	`var'	=	0			if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,7)))	//	If other or no stamp use, set it zero
					
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	`rawvar'>0	&	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inlist(`rawvar',99998,99999)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	(inlist(`rawvar',99998,99999)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year
						
					*	For non FS user
					local	var	foodexp_deliv_NoFS
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
						replace	`var'	=	0			if	((inrange(year,1994,1994)	&	inlist(`rawvar_recall',0))	|	(inrange(year,1995,2019)	&	inlist(`rawvar_recall',0,1,7)))	//	If other or no stamp use, set it zero
				
						*	For DK/NA/refusal (both in amount and recall period), I impute the monthly average from other categories and assign the mean value
						foreach	year	in	1994	1995	1996	1997	1999	2001	2003	2005	2007	2009	2011	2013	2015	2017	2019	{
																	
							summ	`var'			if	year==`year'	&	`rawvar'>0	&	!mi(`rawvar')	&	!mi(`rawvar_recall')	&	///			//	I use raw variable's category 
														!inlist(`rawvar',99998,99999)	&	!inlist(`rawvar_recall',8,9)	//	Both recall period AND amount should be valid
							
							replace	`var'=r(mean) 	if	year==`year'	&	(inlist(`rawvar',99998,99999)	|	inlist(`rawvar_recall',8,9))	//	if amount OR recall period has NA/DK
						
					
						}	//	year	
						
						
					*	Create a final variable
						
						*	Received FS (FS amount + extra amount spent)
						replace	`var_deliv'	=	foodexp_deliv_FS	if	FS_rec_wth==1		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))
						replace	`var_deliv'	=	foodexp_deliv_FS	if	FS_rec_crtyr_wth==1	&	inrange(year,1999,2007)
						
						*	Didn't receive FS	(Just food exp)
						replace	`var_deliv'	=	foodexp_deliv_NoFS	if	FS_rec_wth==0		&	(inrange(year,1994,1997)	|	inrange(year,2009,2019))
						replace	`var_deliv'	=	foodexp_deliv_NoFS	if	FS_rec_crtyr_wth==0	&	inrange(year,1999,2007)
			
			*	Now, aggregate food expenditures - at home, eaten out and delivered - to calculate total monthly food expenditures
			loc	var	foodexp_tot_exclFS
			capture	drop	`var'
			egen	`var'=rowtotal(foodexp_home_exclFS foodexp_out foodexp_deliv)
			replace	`var'=.	if	seqnum==0	//	Replace it as missing if Ind didn't exist (should be, as raw exp variables are also missing)
			replace	`var'=.	if	live_in_FU==0	//	Replace it as missing if not living in FU (ex. institution, moved out, etc.)
			lab	var	`var'	"Total monthly food exp (FS excl)"
			
			loc	var	foodexp_tot_inclFS
			capture	drop	`var'
			egen	`var'=rowtotal(foodexp_home_inclFS foodexp_out foodexp_deliv)
			replace	`var'=.	if	seqnum==0	//	Replace it as missing if Ind didn't exist (should be, as raw exp variables are also missing)
			replace	`var'=.	if	live_in_FU==0	//	Replace it as missing if not living in FU (ex. institution, moved out, etc.)
			lab	var	`var'	"Total monthly food exp (FS incl)"	
			
			*	Summary stat
			/*	
				cap drop diff_total
				cap drop foodexp_tot_imp_month
				gen foodexp_tot_imp_month = foodexp_tot_imputed/12

				gen	diff_total=abs(foodexp_tot_imp_month-foodexp_tot_exclFS)

				br year seqnum FS_rec_wth FS_rec_crtyr_wth foodexp_tot_exclFS  foodexp_tot_imp_month foodexp_tot_imputed diff_total if inrange(year,1999,2019)

				sum diff_total if inrange(year,1999,2019),d
				
				cap	drop	diff_total
				cap	drop	foodexp_tot_imp_month
			*/	
			
			
		*	Create constant dollars of monetary variables  (ex. food exp, TFP)
		*	Unit is 1982-1984=100 (1982-1984 chained)
		qui	ds	FS_rec_amt foodexp_home_inclFS foodexp_home_exclFS foodexp_home_extramt foodexp_out foodexp_deliv foodexp_tot_exclFS foodexp_tot_inclFS TFP_monthly_cost foodexp_W_TFP foodexp_W_TFP_pc_th
		global	money_vars_current	`r(varlist)'
		
		foreach	var of global money_vars_current	{
		    
			cap	drop	`var'_real
			gen	double	`var'_real	=	`var'* (CPI/100)
			
		}
		
		ds	*_real
		global	money_vars_real	`r(varlist)'
		global	money_vars	${money_vars_current}	${money_vars_real}
		
		*	Create lagged variables needed
		*	(2021-11-27) I start with monetary variables (current, real)
			
			*	Set it as panel data
			xtset	x11101ll year, yearly
		
			*	Create lagged vars
			foreach	var	of	global	money_vars	{
				
				cap	drop	l1_`var'
				gen	double	l1_`var'	=	l.`var'
				
			}
		
		*	Drop 1975 and 1990
		*	I only need those years for 1967 and 1991, which I just imported above (so no longer needed)
		drop	if	inlist(year,1975,1990)
					
		*	Drop variables no longer needed
		*	(This part will be added later)
		
		*	Save
		sort	x11101ll	year
		save	"${SNAP_dtInt}/SNAP_long_const",	replace	
	
	}
	
	*	Summary stats	
	if	`summ_stats'==1	{
		
		use    "${SNAP_dtInt}/SNAP_long_const",	clear
		
		*	Sample information
			di _N	//	Sample size
			unique	x11101ll	//	Total individuals
			unique	year		//	Total waves
		
		*	Individual-level stats
		*	To do this, we need to crate a variable which is non-missing only one obs per individual
		*	For now, I use `_uniq' suffix to create such variables
			
		*	Generate cohort
		*	Trying to use de 
		*	Generate age group
		*	Age-group can be tested 
		
			
		*	Sample stats
			
			*	Individual-level (unique per individual)
				
				*	Gender
				local	var	ind_female
				cap	drop	`var'_uniq
				bys x11101ll:	gen `var'_uniq=`var' if _n==1
				summ	`var'_uniq
				
				*	Race
				local	var	rp_White
				cap	drop	`var'_uniq
				bys x11101ll:	gen `var'_uniq=`var' if _n==1
				summ	`var'_uniq		
									
				*	Number of waves living in FU
				loc	var	num_waves_in_FU
				cap	drop	`var'
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'=total(live_in_FU)	if	live_in_FU==1
				bys	x11101ll	live_in_FU:	gen		`var'_uniq	=`var'	if	_n==1	&	live_in_FU==1
				summ	`var'_uniq,d
				
				/*
				*	Number of waves surveyed
				local	var	num_surveyed
				cap	drop 	`var'
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'	=	count(live_in_FU)
				bys x11101ll:	gen 	`var'_uniq=`var' if _n==1
				summ	`var'_uniq,d
				*/
				
				*	Ever-used FS over stuy period
				loc	var	FS_ever_used
				cap	drop	`var'
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'=	max(FS_rec_wth)	if	live_in_FU==1
				bys x11101ll	live_in_FU:	gen `var'_uniq	=	`var' if _n==1	&	live_in_FU==1
				summ	`var'_uniq,d
				
				*	# of waves FS redeemed	(if ever used)
				loc	var	total_FS_used
				cap	drop	`var'
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'=	total(FS_rec_wth)	if	live_in_FU==1
				bys x11101ll	live_in_FU:	gen `var'_uniq	=	`var' if _n==1
				summ	`var'_uniq if `var'_uniq>=1,d
				
			
			
		*	Observation-level (FU-level, RP information)
		
			*	Age
			
			*	Race
			
			*	Education
			
			*	Disability
								
			*	Marital status
			
			*	Family size
			
			*	Split-off
			
			*	FS status (HFSM)
			
			*	FS redeemed
			
			*	FS amount (real dollars)
		
		*	Change in TFP costs over time (real-dollars, 4-ppl FU as an example), to show trends in TFP
		
		
		*	Whether FS is used last month at once over the study period

		
		
		*	Time trends of food exp over time
		
			
		*	(V) Modify V4366 (FS used last year) in 1976
			*	This question actually asks if FS is use ALL THE TIME in previous year. So both "yes" and "no" should be coded as "yes" (Those who didn't use FS at all are coded as "inapp(0)")
			*	We no longer use last year's information
		*	(V) Until 1971, it is ambiguous whether food stamp amount was included in food expenditure (they are NOT included since 1972)
			*	We might need to assume that food expenditure amount is included, or drop those periods in worst case.
			*	For now we use years since 1976
		*	Split the year? - pre-1993 and post-1993
			*	Exogenous variation availability
			*	Food stamp and expenditure data (previous year vs current year/month)
		*	Import TFP value from the link
		*	(V) Import survey month to see seasonality of food expenditure reported.
		*	(V) Replace expenditure values to zero if that member didn't exist in that wave (i.e. sequence number outside 0-20)
		*	(V) Generate indicator if PSID RP is not equal to person
		*	Include School meal/WIC variables to see the ratio of school meal/WIC received also receive SNAP
		*	Create real dollars of nominal value variables (don't replace them. Just create new ones)
		*	Check food stamp value reported vs recall period (to see the over- or under- reporting based on )
		*	Make a summary stat of (1) observation level (2) individual level
		
		
		*	Modeling
	
	}
	
	
	
/*
	*	Drop years not in the sample
	
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
	
	
		
	
		*	Aggregate them
		*use	`age', clear
		*merge 1:1 x11101ll using `splitoff', keepusing(splitoff*) nogen assert(3)
		*merge 1:1 x11101ll using `relrp', keepusing(relrp*) nogen assert(3)
		*merge 1:1 x11101ll using `noresp_why', keepusing(noresp_why*) nogen assert(3)
		*merge 1:1 x11101ll using `gender_head', keepusing(gender_head*) nogen assert(3)
		*merge 1:1 x11101ll using `foodexp_home', keepusing(foodexp_home*) nogen assert(3)
		
		
		
		

						
		*br x11102_1968-x11102_1976 hhcomp_change hhcomp_change_missing
		*br	x11102_1968-x11102_1974	xsqnr_1969-xsqnr_1974	relrp1968-relrp1974	gender_head1968-gender_head1974
		
	
		
		
									


		
		
		
		
		
		
		
		
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
	
	
	

	
	*	Import other variables
	
			
			




br	x11101 x11102_1968 relrp1968	x11102_1969	xsqnr_1969	relrp1969	x11102_1970	xsqnr_1970	x11102_1971	xsqnr_1971	x11102_1972	xsqnr_1972	x11102_1973	xsqnr_1973	x11102_1974	xsqnr_1974	x11102_1975	xsqnr_1975	x11102_1976	xsqnr_1976

*	Demographics

		


		
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
