
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
	
	local	ind_agg		1	//	Aggregate individual-level variables across waves
	local	fam_agg		1	//	Aggregate family-level variables across waves
	local	cr_panel	1	//	Create panel structure from ID variable
	
	*	Aggregate individual-level variables
	if	`ind_agg'==1	{

			
			*	Core information - person number, interview number and sequence number
			*	This can be created from "psid use" using any variables). Here I will use "age" variable
			psid use || age_ind   	 	[68]V117 [69]V1008 [70]V1239 [71]V1942 [72]V2542 [73]V3095 [74]V3508 [75]V3921 [76]V4436 [77]V5350 [78]V5850 [79]V6462 [80]V7067 [81]V7658 [82]V8352 [83]V8961 [84]V10419 [85]V11606 [86]V13011 [87]V14114 [88]V15130 [89]V16631 [90]V18049 [91]V19349 [92]V20651 [93]V22406 [94]ER2007 [95]ER5006 [96]ER7006 [97]ER10009 [99]ER13010 [01]ER17013 [03]ER21017 [05]ER25017 [07]ER36017 [09]ER42017 [11]ER47317 [13]ER53017 [15]ER60017 [17]ER66017 [19]ER72017 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
			
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
		
			*	Split-off indicator
			local	var	splitoff
			psid use || `var' [69]V909 [70]V1106 [71]V1806 [72]V2407 [73]V3007 [74]V3407 [75]V3807 [76]V4307 [77]V5207 [78]V5707 [79]V6307 [80]V6907 [81]V7507 [82]V8207 [83]V8807 [84]V10007 [85]V11107 [86]V12507 [87]V13707 [88]V14807 [89]V16307 [90]V17707 [91]V19007 [92]V20307 [93]V21606 [94]ER2005F [95]ER5005F [96]ER7005F [97]ER10005F [99]ER13005E [01]ER17006 [03]ER21005 [05]ER25005 [07]ER36005 [09]ER42005 [11]ER47305 [13]ER53005 [15]ER60005 [17]ER66005 [19]ER72005  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
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
			local	var	rp_employed
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
			
		*	Disability
		
			*	Disability (RP)
			**	Note: I combind three differenet series of variables: (1) "disability" (1968) (2) "Disability now" (1969-1971) (3) "Any physical or nervous condition" (1972-2019). Need to harmonize them
			local	var	rp_disable
			psid use || `var'	[68]V216	///
									[69]V745 [70]V1411 [71]V2123	///
									[72]V2718 [73]V3244 [74]V3666 [75]V4145 [76]V4625 [77]V5560 [78]V6102 [79]V6710 [80]V7343 [81]V7974 [82]V8616 [83]V9290 [84]V10879 [85]V11993 [86]V13427 [87]V14515 [88]V15994 [89]V17391 [90]V18722 [91]V20022 [92]V21322 [93]V23181 [94]ER3854 [95]ER6724 [96]ER8970 [97]ER11724 [99]ER15449 [01]ER19614 [03]ER23014 [05]ER26995 [07]ER38206 [09]ER44179 [11]ER49498 [13]ER55248 [15]ER62370 [17]ER68424 [19]ER74432	///
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
			
			*	Value of food stamp "received" (previous yr, varying period) (1994-2019)
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
			
			
		
	}
	
	*	Create panel structure
	if	`cr_panel'==1		{
		
		*	Merge ID with unique vars 
		use	"${SNAP_dtInt}/Ind_vars/ID", clear
		merge	1:1	x11101ll	using	"${SNAP_dtInt}/Ind_vars/unique_vars.dta",	nogen	assert(3)
		
		*	Generate a 1968 sequence number variable from person number variable
		**	Note: 1968 sequence number is used to determine whether an individual was head/RP in 1968 or not. Don't use it for other purposes, unless it is not consistent with other sequence variables.
		**	It Should be dropped after use to avoid confusion.		
		gen		xsqnr_1968	=	pn
		replace	xsqnr_1968	=	0	if	!inrange(xsqnr_1968,1,20)	
		order	xsqnr_1968,	before(xsqnr_1969)
		
		*	Drop years without food expenditures (1973, 1988, 1989)
		drop	*_1973	*_1988	*_1989
		
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

		
		*save	"${SNAP_dtInt}/SNAP_raw_merged.dta", replace
		*use	"${SNAP_dtInt}/SNAP_raw_merged.dta", clear
		
		*	Create a panel structre
		*	This study covers 50-year period with different family composition changes, thus we need to carefully consider that.
		*	First, we create a individual-level aggregated data using "psid use command" with necessary variables to further investigate family change.
	
				
		*	Generate a household id which uniquely identifies a combination of household wave IDs.
		**	Note: This is a tepmorary variable where it would have duplicate household ids after applying family panel structure (this is why I named this variabe as "1st")
		cap drop hhid_agg_1st	
		egen hhid_agg_1st = group(x11102_1968-x11102_2019), missing
		
		
		*	First, we drop individuals who have never been head/RP in any given wave, as their family level variables would be observed from their head/RP.
		cap	drop	rp_any
		egen	rp_any=anymatch(${seqnum_all}), values(1)	//	Indicator if indiv was head/RP at least once.
		drop	if	rp_any!=1
		drop	rp_any
		
		*	Second, we replace household id with missing(or zero) of the individuals when they were not head/RP
		*	For example, in case of pn=2002 above, her values will be replaced with zero when she were not head/RP (ex. 1968, 1969, 1978, 1979, 1980) so her own household doesn't exist during that period
		***	But this can be problematic, especially during 1978-1980 in the example above. Need to think about how I deal with it.

		foreach	year	of	global	sample_years	{
			
			replace	x11102_`year'=.	if	xsqnr_`year'!=1
			
		}
		
		*	Drop FUs which were observed only once, as it does not provide sufficient information.
		egen	fu_nonmiss=rownonmiss(${hhid_all})
		label variable	fu_nonmiss	"Number of non-missing survey period as head/PR"
		drop	if	fu_nonmiss==1	//	Drop if there's only 1 observation per household.
		
		*	Generate the final household id which uniquely identifies a combination of household wave IDs.
		egen hhid_agg = group(x11102_1968-x11102_2019), missing
		drop	hhid_agg_1st
		
		save	"${SNAP_dtInt}/Ind_vars/ID_sample.dta", replace
		
	}

	*	Merge variables
	if	`merge_data'==1	{
		
		use	"${SNAP_dtInt}/Ind_vars/ID_sample.dta",	clear
		
		*	Merge individual variables
		cd "${SNAP_dtInt}/Ind_vars"
		
		global	varlist_ind	age_ind	wgt_long_ind	relrp	origfu_id	noresp_why
		
		foreach	var	of	global	varlist_ind	{
			
			merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(2 3)	keep(3)	//	Longitudinal weight
			
		}
		
		
		*	Merge family variables
		cd "${SNAP_dtInt}/Fam_vars"
	
		global	varlist_fam	splitoff	///		/*survey info*/
							rp_gender	rp_age	rp_marital	rp_race	///		/*	Demographics	*/
							rp_state	rp_employed	rp_gradecomp	rp_disable	///	/*	Other RP information	*/
							famnum	childnum	///	/*	Family composition	*/
							fam_income	///	/*	Income	*/
							HFSM_raw	HFSM_scale	HFSM_cat	///	/*	HFSM_cat*/
							stamp_useamt	stamp_recamt_annual		stamp_recamt	stamp_recamt_period	stamp_used	stamp_monthsused	///	/*	FS/SNAP usage*/
							foodexp_home_annual	foodexp_home_grown	foodexp_home_nostamp	foodexp_home_nostamp_recall	foodexp_home_spent_extra	foodexp_home_stamp	foodexp_home_stamp_recall	foodexp_home_imputed	///	/* At-home food exp */	///
							foodexp_away_cat	foodexp_away_annual	foodexp_away_nostamp	foodexp_away_nostamp_recall	foodexp_away_imputed	foodexp_atwork	foodexp_atwork_saved	///	/*	Away/at work food expenditure	*/
							foodexp_deliv_nostamp	foodexp_deliv_nostamp_recall	foodexp_deliv_stamp	foodexp_deliv_stamp_recall	/*	devliered food expenditure	*/
	
		foreach	var	of	global	varlist_fam	{
			
			merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(2 3)	keep(3)	//	Longitudinal weight
			
		}
		
		*	Save (wide-format)
		
		order	hhid_agg,	before(x11101ll)
		order	pn-fu_nonmiss,	after(x11101ll)
		save	"${SNAP_dtInt}/SNAP_Merged_wide",	replace
		
		*	Re-shape it into long format	
		reshape long x11102_	xsqnr_	${varlist_ind}	${varlist_fam}, i(hhid_agg) j(year)
		
	}
	
	
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
