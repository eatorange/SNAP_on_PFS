
	/*****************************************************************
	PROJECT: 		SNAP of FS
					
	TITLE:			SNAP_clean
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Nov 14, by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	x11101ll        // 1999 Family ID

	DESCRIPTION: 	Clean individual-level data from 1999 to 2017
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Import individual- and family-level PSID variables
					2 - Prepare external data
					3 - Construct PSID panel data and import external data
					4 - Clean data
					X - Save and Exit
					
	INPUTS: 		* SNAP Individual & family raw data
					${SNAP_dtRaw}/Main
					
					* Many external data
										
	OUTPUTS: 		* Cleaned PSID long-format data
					"${SNAP_dtInt}/SNAP_long_const

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
	
	*	Codes to be executed
		*	SECTION 1: Import individual- and family-level PSID variables
		local	ind_agg			0	//	Aggregate individual-level variables across waves
		local	fam_agg			0	//	Aggregate family-level variables across waves
		
		*	SECTION 2: Prepare external data
		local	ext_data		0	//	Prepare external data (CPI, TFP, etc.)
		
		*	SECTION 3: Construct PSID panel data and import external data
		local	cr_panel		0	//	Create panel structure from ID variable
			local	panel_view	0	//	Create an excel file showing the change of certain clan over time (for internal data-check only)
		local	merge_data		0	//	Merge ind- and family- variables and import it into ID variable
			local	raw_reshape	1		//	Merge raw variables and reshape into long data (takes time)
			local	add_clean	1		//	Do additional cleaning and import external data (CPI, TFP)
			local	import_dta	1		//	Import aggregated variables and external data into ID data. 
		
		*	SECTION 4: Clean data and save it
		local	clean_vars		1	//	Clean variables and save it
		
		*	(These parts were moved into "SNAP_const.do")
		local	PFS_const		0	//	Construct PFS
		local	FSD_construct	0	//	Construct FSD
		local	IV_reg			0	//	Run IV-2SLS regression
		local	summ_stats		0	//	Generate summary statistics (will be moved to another file later)

	
	
	/****************************************************************
		SECTION 1: Import individual- and family-level PSID variables
	****************************************************************/	
	
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
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Ind_vars/`var'", replace
			
			*	Grade completed (individual level)
				*	Note: has value zero if a person is 16-year old or younger.
				*	Considers GED, unlike family-level RP variable. For example, if a person completed less than 12 grade (say, 10) but has GED, it would be 10 for family-level variable, but 12 in this variable.
			loc	var	ind_edu
			psid use || `var' [68]ER30010 [70]ER30052 [71]ER30076 [72]ER30100 [73]ER30126 [74]ER30147 [75]ER30169 [76]ER30197 [77]ER30226 [78]ER30255 [79]ER30296 [80]ER30326 [81]ER30356 [82]ER30384 [83]ER30413 [84]ER30443 [85]ER30478 [86]ER30513 [87]ER30549 [88]ER30584 [89]ER30620 [90]ER30657 [91]ER30703 [92]ER30748 [93]ER30820 [94]ER33115 [95]ER33215 [96]ER33315 [97]ER33415 [99]ER33516 [01]ER33616 [03]ER33716 [05]ER33817 [07]ER33917 [09]ER34020 [11]ER34119 [13]ER34230 [15]ER34349 [17]ER34548 [19]ER34752  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Ind_vars/`var'", replace
			
			
			*	Health, good or bad
				*	Note: Not fully available over the entire study period.
			loc	var	ind_health
			psid use || `var' [86]ER30527 [88]ER30598 [89]ER30634 [90]ER30671 [91]ER30719 [92]ER30764 [93]ER30827 [94]ER33117 [95]ER33217 [96]ER33317 [97]ER33417 [99]ER33517 [01]ER33617 [03]ER33717 [05]ER33818 [07]ER33918 [09]ER34021 [11]ER34120 [13]ER34231 [15]ER34381 [17]ER34580 [19]ER34788  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear 
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Ind_vars/`var'", replace
			
			*	Employment status
			loc	var	ind_employed
			psid use || `var' [79]ER30293 [80]ER30323 [81]ER30353 [82]ER30382 [83]ER30411 [84]ER30441 [85]ER30474 [86]ER30509 [87]ER30545 [88]ER30580 [89]ER30616 [90]ER30653 [91]ER30699 [92]ER30744 [93]ER30816 [94]ER33111 [95]ER33211 [96]ER33311 [97]ER33411 [99]ER33512 [01]ER33612 [03]ER33712 [05]ER33813 [07]ER33913 [09]ER34016 [11]ER34116 [13]ER34216 [15]ER34317 [17]ER34516 [19]ER34716  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Ind_vars/`var'", replace
			
			
	}

	*	Aggregate family-level variables
	if	`fam_agg'==1	{
	
		*	Survey information

			*	Household ID (note: it is NOT the same as "family". Multiple families can reside in a same HH)
			*	Note: 1982-1984 are missing.
			local	var	hhid
			psid use || `var' [69]V1015 [70]V1766 [71]V2345 [72]V2979 [73]V3310 [74]V3730 [75]V4231 [76]V5113 [77]V5681 [78]V6220 [79]V6814 [80]V7456 [81]V8110 [85]V12443 [86]V13682 [87]V14732 [88]V16207 [89]V17584 [90]V18936 [91]V20236 [92]V21542 [93]V23356 [94]ER4159R [95]ER6999R [96]ER9250R [97]ER12223R [99]ER16447 [01]ER20393 [03]ER24170 [05]ER28069 [07]ER41059 [09]ER47003 [11]ER52427 [13]ER58245 [15]ER65481 [17]ER71560 [19]ER77621  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
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
			
			
			*	Change in family composition
			local	var	change_famcomp
			psid use || `var' [69]V542 [70]V1109 [71]V1809 [72]V2410 [73]V3010 [74]V3410 [75]V3810 [76]V4310 [77]V5210 [78]V5710 [79]V6310 [80]V6910 [81]V7510 [82]V8210 [83]V8810 [84]V10010 [85]V11112 [86]V12510 [87]V13710 [88]V14810 [89]V16310 [90]V17710 [91]V19010 [92]V20310 [93]V21608 [94]ER2005A [95]ER5004A [96]ER7004A [97]ER10004A [99]ER13008A [01]ER17007 [03]ER21007 [05]ER25007 [07]ER36007 [09]ER42007 [11]ER47307 [13]ER53007 [15]ER60007 [17]ER66007 [19]ER72007  using  "${SNAP_dtRaw}/Unpacked"  , keepnotes design(any) clear	
			
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
			
			*	Race (spouse) - available since 1985
			local	var	sp_race
			psid use || `var' [85]V12293 [86]V13500 [87]V14547 [88]V16021 [89]V17418 [90]V18749 [91]V20049 [92]V21355 [93]V23212 [94]ER3883 [95]ER6753 [96]ER8999 [97]ER11760 [99]ER15836 [01]ER19897 [03]ER23334 [05]ER27297 [07]ER40472 [09]ER46449 [11]ER51810 [13]ER57549 [15]ER64671 [17]ER70744 [19]ER76752 	///
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
		
			*	RP labor income
			loc	var	rp_laborinc
			psid use || `var' [68]V74 [69]V514 [70]V1196 [71]V1897 [72]V2498 [73]V3051 [74]V3463 [75]V3863 [76]V5031 [77]V5627 [78]V6174 [79]V6767 [80]V7413 [81]V8066 [82]V8690 [83]V9376 [84]V11023 [85]V12372 [86]V13624 [87]V14671 [88]V16145 [89]V17534 [90]V18878 [91]V20178 [92]V21484 [93]V23323 [94]ER4140 [95]ER6980 [96]ER9231 [97]ER12080 [99]ER16463 [01]ER20443 [03]ER24116 [05]ER27931 [07]ER40921 [09]ER46829 [11]ER52237 [13]ER58038 [15]ER65216 [17]ER71293	[19]ER77315	///
			using "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear		
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			
			
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
		*	Previously I planned to use previous year's food stamp redemption amount, but I decided to use previous "MONTH" amount for more accurate match with expenditure
			*	Expenditure questions differ based on previous "MONTH" redemption, and food expenditure recall period are often "WEEKLY" or "MONTHLY"
			
			*	Stamp amount saved (1975-1979) or received (1980-2019) last MONTH, or recevied current year (1999-2007)
			*	I combine three series of variables: (1) Amount saved last month (1975-1997) (2) Current year with free recall period (so I can convert it to monthly amount) (1999-2007) (3) Last month (2009-2019)
				**	Note: For earlier periods (1975-1979), where HH had to pay for food stamps, "amount saved" must be combined with "amount paid" to get the total value of food from stamp. (check page 42 of 1977 file description for detail)
					**	It should be in cleaning stage
				**	For "current year" amount (1999-2007), it should be used with recall period to impute monthly variable
					**	91.5% of them gave monthly amount, 2.7% gave weekly amount it 
			*	This variable is important as households' food expenditure are separately collected based on this response.
			loc	var	stamp_useamt_month
			psid use || `var'		[75]V3846 [76]V4359 [77]V5269 [78]V5768 [79]V6374 [80]V6970 [81]V7562 [82]V8254 [83]V8862 [84]V10233 [85]V11373 [86]V12772 [87]V13874 [90]V17805 [91]V19105 [92]V20405 [93]V21703 [94]ER3076 [95]ER6075 [96]ER8172 [97]ER11066	///	/* first series*/
									[99]ER14285 [01]ER18417 [03]ER21682 [05]ER25684 [07]ER36702	///	/*	Second series. Should be combind with recall period variable	*/
									[09]ER42709 [11]ER48025 [13]ER53722 [15]ER60737 [17]ER66784 [19]ER72788, keepnotes design(any) clear		/*	Third series*/
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace						
			
			*	Paid amount for stamp last MONTH (1975-1979)
			*	In early periods (1975-1979) when HH had to buy stamps, this amount should be added to amount saved to get total value of additional foods from food stamps (check pg 42 of 1977 file description for detail)
			loc	var	stamp_payamt_month
			psid use || `var'		[75]V3844 [76]V4357 [77]V5267 [78]V5766 [79]V6372, keepnotes design(any) clear		/*	Third series*/
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
			
			*	Number of people in HH issued food stamp last MONTH
				*	Note: Although PSID year-by-year index categorized it as "previous year", they are actually asking about "last month" (confirmed by the PSID. Check the email thread I first sent on 2022/3/10)
				**	Note: These variables are codded differently (ex. different top-coded value) in different years, so should not be "directly" used in analyses across years unless carefully harmonized.
				**	This variable will only be used to determine whether HH received food stamp (>0) or not (=0), up to 1993 (see pg 42 of 1977 file description)
			loc	var	stamp_ppl_month
			psid use || `var'   	[75]V3843 [76]V4356 [77]V5266 [78]V5765 [79]V6371 [80]V6969 [81]V7561 [82]V8253 [83]V8861 [84]V10232 [85]V11372 [86]V12771 [87]V13873 [90]V17804	///
									[91]V19104 [92]V20404 [93]V21702 [94]ER3075 [95]ER6074 [96]ER8171 [97]ER11065 [99]ER14284 [01]ER18416 [03]ER21681 [05]ER25683 [07]ER36701 [09]ER42708	///
									[11]ER48024 [13]ER53721 [15]ER60736 [17]ER66783 [19]ER72787	///
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
			*	Also, we need to use this variable to calculate the number of months FS redeemed, to correctly impute yearly to monthly food stamp value.
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
		
		*	Reason for not participating in the FSP
			loc	var	why_no_FSP
			psid use || `var'   [77]V5539 [80]V7271 [81]V7965 [87]V14490	///
			using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				
			keep	x11101ll	`var'*
			save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
		
		*	Food expenditure

			*	At-home
			
				*	(1968-1993) Annual home expenditure (stamp excluded)
					*	Note: stamp value is excluded since 1977. For 1975-1976, it depends on whether HH answered "stamp amount included in the expenditure?"
					*	Food expenditure net of stamp amount in 1975-1976 are adjusted in cleaning phase.
				*	Note: This variable includes "cost of food delivered to door". Please find the codebook of variable V21707.
				*	Note: This variable includes food expenditure of FS and non-FS families (they are collected separately since 1994)
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
			
				*	(1994-2019)	At-home expenditure (with free recall period)

					*	Non-FS
					
						*	Amount spent
						loc	var	foodexp_home_nostamp
						psid use || `var'  [94]ER3085 [95]ER6084 [96]ER8181 [97]ER11076 [99]ER14295 [01]ER18431 [03]ER21696 [05]ER25698 [07]ER36716 [09]ER42722 [11]ER48038 [13]ER53735 [15]ER60750 [17]ER66797 [19]ER72801 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
						
						keep	x11101ll	`var'*
						save	"${SNAP_dtInt}/Fam_vars/`var'", replace
						
						*	Recall period (should be used with the amount above)
						loc	var	foodexp_home_nostamp_recall
						psid use || `var'  [94]ER3086 [95]ER6085 [96]ER8182 [97]ER11077 [99]ER14296 [01]ER18432 [03]ER21697 [05]ER25699 [07]ER36717 [09]ER42723 [11]ER48039 [13]ER53736 [15]ER60751 [17]ER66798 [19]ER72802 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
						
						keep	x11101ll	`var'*
						save	"${SNAP_dtInt}/Fam_vars/`var'", replace	
			
			
					*	FS
					
						*	(1994-2019) Whether spent extra money for at home expenditure (dummy) 
							*	This variable is collected only from FS families
							**	If households affirm, then they are asked how much extra money they spent for at-home food
						loc	var	foodexp_home_spent_extra
						psid use || `var'  [94]ER3077 [95]ER6076 [96]ER8173 [97]ER11067 [99]ER14287 [01]ER18420 [03]ER21685 [05]ER25687 [07]ER36705 [09]ER42711 [11]ER48027 [13]ER53724 [15]ER60739 [17]ER66786 [19]ER72790 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
						
						keep	x11101ll	`var'*
						save	"${SNAP_dtInt}/Fam_vars/`var'", replace
						
						*	(1994-2019) At home expenditure, additional to food stamp value (free recall period)
							*	This variable is collected from FS families who spent extra amount of money for at-home exp (those who said "yes" to foodexp_home_spent_extra)
						**	This question is asked only when household affirmed "did you spend any money in addition to stamp value?"
						loc	var	foodexp_home_stamp
						psid use || `var'  [94]ER3078 [95]ER6077 [96]ER8174 [97]ER11068 [99]ER14288 [01]ER18421 [03]ER21686 [05]ER25688 [07]ER36706 [09]ER42712 [11]ER48028 [13]ER53725 [15]ER60740 [17]ER66787 [19]ER72791 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
						
						keep	x11101ll	`var'*
						save	"${SNAP_dtInt}/Fam_vars/`var'", replace
						
						*	Recall period of at home expenditure in addition to stamp (should be matched with "additional expenditure" above)
						*	It should be used with the acutal amount to make consistent expenditure
							**	This question is asked only when household affirmed "did you spend any money in addition to stamp value?"
							**	Note: 1994 recall period is slightly different from the rest of the periods (1995-2019)
						loc	var	foodexp_home_stamp_recall
						psid use || `var'  	[94]ER3079 [95]ER6078 [96]ER8175 [97]ER11069 [99]ER14289 [01]ER18422 [03]ER21687 [05]ER25689 [07]ER36707 [09]ER42713 [11]ER48029 [13]ER53726 [15]ER60741 [17]ER66788 [19]ER72792 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
						
						keep	x11101ll	`var'*
						save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
				*	At-home, whether food stamp amount was included in weekly food expenditure (1975-1976)
				**	If respondent answered "yes", food stamp amount should be deducted from the expenditure to get food expenditure without stamp value
				loc	var	foodexp_home_wth_stamp_incl
				psid use || `var'  	[72]V2482 [74]V3447 [75]V3848 [76]V4361 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	At home, imputed annual cost (1999-2019)
					**	Can be used to check whether my individual calculation is correct.
				loc	var	foodexp_home_imputed
				psid use || `var'  	 	[99]ER16515A2 [01]ER20456A2 [03]ER24138A2 [05]ER28037A2 [07]ER41027A2 [09]ER46971A2 [11]ER52395A2 [13]ER58212A2 [15]ER65411 [17]ER71488 [19]ER77514 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
		*	Away from home (eating out)
		
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
			
			*	Away expenditure (1994-)
			*	Free recall period, thus should be combined with recall period variable
				
				*	FS
				
					*	Amount spent
					loc	var	foodexp_away_stamp
					psid use || `var'  	[94]ER3083 [95]ER6082 [96]ER8179 [97]ER11073 [99]ER14293 [01]ER18428 [03]ER21693 [05]ER25695 [07]ER36713 [09]ER42719 [11]ER48035 [13]ER53732 [15]ER60747 [17]ER66794 [19]ER72798 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
					
					keep	x11101ll	`var'*
					save	"${SNAP_dtInt}/Fam_vars/`var'", replace
					
					*	Recall period of away expenditure, when FS used (should be matched with the expenditure above)
					loc	var	foodexp_away_stamp_recall
					psid use || `var'  [94]ER3084 [95]ER6083 [96]ER8180 [97]ER11074 [99]ER14294 [01]ER18429 [03]ER21694 [05]ER25696 [07]ER36714 [09]ER42720 [11]ER48036 [13]ER53733 [15]ER60748 [17]ER66795 [19]ER72799 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				
					keep	x11101ll	`var'*
					save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	Non-FS
				
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

				*	Imputed annual away expenditure (1999-2019)
				**	Can be used to check whether my individual calculation is correct.
				loc	var	foodexp_away_imputed
				psid use || `var'  	[99]ER16515A3 [01]ER20456A3 [03]ER24138A3 [05]ER28037A3 [07]ER41027A3 [09]ER46971A3 [11]ER52395A3 [13]ER58212A3 [15]ER65412 [17]ER71489 [19]ER77516 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
		*	Food delivered
		**	Note: This expenditure was not separately collected until 1993. At that time, at-home expenditure includes delivered amount
		
			*	FS
								
				*	Whether food is deliverd ot not (1994-2019)
				loc	var	foodexp_deliv_stamp_wth
				psid use || `var'  [94]ER3080 [95]ER6079 [96]ER8176 [97]ER11070 [99]ER14290 [01]ER18424 [03]ER21689 [05]ER25691 [07]ER36709 [09]ER42715 [11]ER48031 [13]ER53728 [15]ER60743 [17]ER66790 [19]ER72794	///
					using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				 
				*	Cost of food delivered (94-19)
				*	This variable should be added to impute total food expenditure.
				loc	var	foodexp_deliv_stamp
				psid use || `var'   	[94]ER3081 [95]ER6080 [96]ER8177 [97]ER11071 [99]ER14291 [01]ER18425 [03]ER21690 [05]ER25692 [07]ER36710 [09]ER42716 [11]ER48032 [13]ER53729 [15]ER60744 [17]ER66791 [19]ER72795	///
					using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
				
				*	Recall period of the cost of food delivered (94-19)
				loc	var	foodexp_deliv_stamp_recall
				psid use || `var' 	[94]ER3082 [95]ER6081 [96]ER8178 [97]ER11072 [99]ER14292 [01]ER18426 [03]ER21691 [05]ER25693 [07]ER36711 [09]ER42717 [11]ER48033 [13]ER53730 [15]ER60745 [17]ER66792 [19]ER72796	///
					using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace
			
			*	Non-FS
			
				*	Whether food is deliverd ot not (1994-2019)
				loc	var	foodexp_deliv_nostamp_wth
				psid use || `var'  [94]ER3087 [95]ER6086 [96]ER8183 [97]ER11078 [99]ER14297 [01]ER18434 [03]ER21699 [05]ER25701 [07]ER36719 [09]ER42725 [11]ER48041 [13]ER53738 [15]ER60753 [17]ER66800 [19]ER72804	///
					using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace	
				
				*	Cost of food delivered (1994-2019)
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
			
			*	Imputed delivered expenditure (1999-2019)
			**	Can be used to check whether my individual calculation is correct.
				loc	var	foodexp_deliv_imputed
				psid use || `var'  	[99]ER16515A4 [01]ER20456A4 [03]ER24138A4 [05]ER28037A4 [07]ER41027A4 [09]ER46971A4 [11]ER52395A4 [13]ER58212A4 [15]ER65413 [17]ER71490 [19]ER77518 using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				
				keep	x11101ll	`var'*
				save	"${SNAP_dtInt}/Fam_vars/`var'", replace	 	
			
			*	Total (imputed,1999-2019)
				loc	var	foodexp_tot_imputed
				psid use || `var' 	[99]ER16515A1 [01]ER20456A1 [03]ER24138A1 [05]ER28037A1 [07]ER41027A1 [09]ER46971A1 [11]ER52395A1 [13]ER58212A1 [15]ER65410 [17]ER71487 [19]ER77513	///
					using  "${SNAP_dtRaw}/Unpacked" , keepnotes design(any) clear	
				
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
			
		
	}


	/****************************************************************
		SECTION 2: Prepare external data
	****************************************************************/		
	
	*	Prepare external data
	if	`ext_data'==1	{
										
				
		*	Unemployment Rate (BLS)
			
			*	Nationwide (for program summary)
			import excel "${clouldfolder}/DataWork/BLS/Unemp_rate_nation_month.xlsx", sheet("BLS Data Series") cellrange(A12)  firstrow clear
			
			rename	(Year Annual) (year unemp_rate)
			keep	year	unemp_rate
			
			label	var	unemp_rate "Unemployment Rate (%)"
			
			save	"${SNAP_dtInt}/Unemployment Rate_nation",	replace
	
		
		
		*	State data with unique PSID code
		*	This data will be merged with other data which has state name
		
		*	Citizen and state ideology (1960-2016, 2017 (government ideology only))
			use	"${clouldfolder}/DataWork/State Ideology/stateideology_v2018.dta", clear
			drop	if	mi(state)
			
			*	Fill in missing state name in later years
			bys	state:	replace	statename	=	statename[_n+1]	if	mi(statename)
			bys	state:	replace	statename	=	statename[_n-1]	if	mi(statename)

			drop	state
			rename	statename	state
			
			*	Merge statecode
			merge	m:1	state using "${SNAP_dtRaw}/Statecode.dta"
			assert	state=="Washington D.C." if _merge==2	//	Washington D.C. is missing
			drop	if	_merge==2
			drop	_merge
			rename	statecode	rp_state
					
			*	Re-scale citizen ideology variable (from 0-100 to 0-1 : for better interpretation)
			cap	drop	citi6016_0to1
			gen	citi6016_0to1	=	citi6016/100
			lab	var	citi6016_0to1	"State citizen ideology (0-1)"
			
			*	Save
			sort	rp_state	year
			compress
			lab	var	citi6016		"State citizen ideology"
			lab	var	inst6017_nom	"State government ideology"	

			save	"${SNAP_dtInt}/citizen_government_ideology",	replace
	
	
	
	
	
			*	Descriptive stats/figures

				
				*	By most & least conservative 
				use	"${SNAP_dtInt}/citizen_government_ideology", clear
				replace	citi6016	=	citi6016/100
				twoway	(line citi6016	year		if state=="Mississippi",	yaxis(1) lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Citizen (MS)")))		///
						(line citi6016	year		if state=="Massachusetts", 	yaxis(1)  lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Citizen (MA)")))		///
						/*(line inst6017_nom	year	if state=="Idaho", 	yaxis(2) lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "Government (ID)")))	///
						(line inst6017_nom	year	if state=="Hawaii", yaxis(2)	lc(red) lp(dashdot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "Government (ID)")))*/,	///
						title("Citizen ideology") ytitle("Citizen score", axis(1)) /*ytitle("Govt score.rate", axis(2))*/ xtitle("year") name(CIM_bystate, replace) 
				graph	export	"${SNAP_outRaw}/ideology_by_state.png", as(png) replace
				graph	close
				
				
				*	By year
				use	"${SNAP_dtInt}/citizen_government_ideology", clear
				replace	citi6016	=	citi6016/100
				collapse	citi6016 inst6017_nom, by(year)
				merge	1:1	year	using	"${SNAP_dtInt}/Unemployment Rate_nation"
				graph	twoway	(line citi6016	year, 	 yaxis(1) lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Citizen ideology")))		///
								/*(line inst6017_nom	year, yaxis(1) 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Government ideology")))*/	///
								(line unemp_rate	year, yaxis(2) lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Uemployment Rate"))),	///
								title("Citizen Ideology and Unemployment Rate by Year") ytitle("score", axis(1)) ytitle("Unemp.rate", axis(2)) xtitle("year") note(0 most conservative - 100 most liberal)	///
								name(CIM_byyear, replace) 
				graph	export	"${SNAP_outRaw}/ideology_by_year.png", as(png) replace
				graph	close	
				
				graph	combine	CIM_bystate	CIM_byyear, graphregion(color(white) fcolor(white)) 
				graph	export	"${SNAP_outRaw}/CIM_combined.png", replace
				
				*	Correlation by specific PSID wave
					
					*	2015
					use "${SNAP_dtRaw}/Unpacked/fam2015er.dta", clear
					gen	year=2015
					rename	ER60003 rp_state
					rename	ER60735	FS_rec_wth
					recode	FS_rec_wth	(5=0)	(8 9=.)
					tempfile psid2015
					save	`psid2015'
					
					use	"${SNAP_dtInt}/citizen_government_ideology", clear
					keep	if	year==2015
					merge	1:m	year	rp_state	using	`psid2015', assert(2 3) keep(3) nogen keepusing(FS_rec_wth)
				
					*	Correlation
					pwcorr FS_rec_wth citi6016 inst6017_nom, sig
					
					*	Bivariate regression
					reg FS_rec_wth citi6016, robust
					reg	FS_rec_wth	inst6017_nom, robust
			

				
				
		
		*	State GDP
			
			*	1976-1996
			import	delimited	"${clouldfolder}/DataWork/BEA/SAGDP/SAGDP2S__ALL_AREAS_1963_1997.csv", clear
			
			*	Keep relevant information only
			keep	if	description=="All industry total"
			drop	if	inlist(geoname,"Far West","Great Lakes","Plains","Southeast","Southwest","Mideast","Rocky Mountain")
			drop	if	inlist(geoname,"United States","United States *","New England")
			drop	geofips	region	tablename	linecode	industryclassification	description	unit
			rename v# GDP#, renumber(1963)
			destring	GDP*, replace
			
			reshape	long	GDP, i(geoname) j(year)
			
			
			rename	geoname	state
			rename	GDP	GDP_old 	//	temporary
			drop	if	inrange(year,1963,1974)
			replace	state="Washington D.C." if state=="District of Columbia"
			
			lab	var	state	"State"
			lab	var	year	"Year"
			*lab	var	GDP		"GDP (Nominal, M)"
					
			tempfile	GDP_pre1997
			save		`GDP_pre1997'
		
			*	1997-2019
			import	delimited	"${clouldfolder}/DataWork/BEA/SAGDP/SAGDP2N__ALL_AREAS_1997_2021.csv", clear
		
			*	Keep relevant information only
			keep	if	description=="All industry total"
			drop	if	inlist(geoname,"Far West","Great Lakes","Plains","Southeast","Southwest","Mideast","Rocky Mountain")
			drop	if	inlist(geoname,"United States","United States *","New England")
			drop	geofips	region	tablename	linecode	industryclassification	description	unit
			rename v# GDP#, renumber(1997)
			destring	GDP*, replace
			
			reshape	long	GDP, i(geoname) j(year)
			
			
			rename	geoname	state
			rename	GDP	GDP_new 	//	temporary
			drop	if	inrange(year,2020,2021)
			replace	state="Washington D.C." if state=="District of Columbia"
			
			
			
			*	Merge old and new GDP
			merge	1:1	state	year	using	`GDP_pre1997', nogen
			
				*	Create a single var that has all GDP
				gen		GDP=GDP_old	if	year<=1996
				replace	GDP=GDP_new	if	year>=1997
				lab	var	GDP	"State GDP (M)"
			
				*	Generate gap var between old and new GDP, for 1997
				gen	GDP_diff	=	(GDP_new - GDP_old) / GDP_new
				
				*	Generate indicator that tags post 1996 data 
				gen		post_1996=0
				replace	post_1996=1	if	year>=1996
			
			*	Merge statecode
			merge	m:1	state using "${SNAP_dtRaw}/Statecode.dta", assert(3) nogen
			rename	statecode	rp_state
			
			*	Save
			sort	rp_state	year
			compress
			save	"${SNAP_dtInt}/GDP_1975_2019",	replace
			

		
		*	Finance information (1977-2019)
			*	Original U.S. Census data do not have state govt data pre-1977 (except 1972)
			*	Primary source: the Urban Institute (https://state-local-finance-data.taxpolicycenter.org/)
			*	Additional source: the Government Finance Database (https://willamette.edu/mba/research-impact/public-datasets/index.html)	//	To fill in missing state & local data of 2001 & 2003
		*	This data has state and local expenditure information
		*	The data strongly recommended to use "state and local" level for inter-state comparison for following reason
			/*
			Important: For inter-state comparisons, we highly recommend using the "State and Local" analysis level.
			The distribution of activity between state and local governments varies greatly from state to state: only the "State and Local" analysis level will fully capture government activity within a state.
			*/
		*	However, "state and local" have data missing in 2001 and 2003, while "state" level has complete info from 1977 to 2019
			*	"state" data is missing in DC
		*	Ideas
			*	(1) Use "state and local" as a base, and use state-only expenditure in 2001 and 2003
			*	(2)	Use "state" as a base, and import "state and local" expenditure for missing DC.
			*	(2022-4-11) For now I use (2) (state as base) for the folowing reasons
				*	1. Weak IV test from both ideas are both strong
				*	2. In "state and local" level data of DC in the UI's raw data, they only included "Washington DC" finance information, not sub-level organizations (ex. housing authority, public transit).
				*	Therefore, using DC expenditure as "state"-level information is more consistent than using 2001/2003 "state" expenditures as "state and local" expenditure for all non-DC states in 2001/2003
		
			*	Total expenditure (thousands), nominal dollars
			*import	delimited	"${dataWorkFolder}/Census/StateData.csv", clear
			import	delimited	"${clouldfolder}/DataWork/Census/StateData.csv",	clear
			
				*	Keep relevant information only
				drop	if	year4==1972
				keep	year4	name	
				
				*	State and local 
				*import	excel	"${dataWorkFolder}/Census/state_local_finance_1977_2019.xlsx", firstrow sheet(s&l_total_K_nominal)	clear
				import	excel	"${clouldfolder}/DataWork/Census/state_local_finance_1977_2019.xlsx", firstrow sheet(s&l_total_K_nominal)	clear
				drop	if	mi(Year)
				drop	if	State=="United States"
				rename	(E013GeneralExpenditure-E090PublicWelfDirectExp)	///
						(genexp_tot dirgenexp_tot edudirexp_tot healthdirexp_tot highwaydirexp_tot housedirexp_tot policedirexp_tot welfaredirexp_tot)
				rename *tot sl_= 
				isid State Year
				tempfile	state_local_total_exp
				save		`state_local_total_exp'
				
				*	State only
				*import	excel	"${dataWorkFolder}/Census/state_local_finance_1977_2019.xlsx", firstrow sheet(state_total_K_nominal)	clear
				import	excel	"${clouldfolder}/DataWork/Census/state_local_finance_1977_2019.xlsx", firstrow sheet(state_total_K_nominal)	clear
				drop	if	mi(Year)
				drop	if	State=="United States"
				rename	(E013GeneralExpenditure-E090PublicWelfDirectExp)	///
						(genexp_tot dirgenexp_tot edudirexp_tot healthdirexp_tot highwaydirexp_tot housedirexp_tot policedirexp_tot welfaredirexp_tot)
				drop	if State=="DC"	//	No data
				destring	*tot, replace
				rename *tot s_= 
				isid State Year
				tempfile	state_total_exp
				save		`state_total_exp'
			
			*	Per capita expenditure, 2019 real dollars, state and local
				
				*	State and local
				*import	excel	"${dataWorkFolder}/Census/state_local_finance_1977_2019.xlsx", firstrow sheet(s&l_pc_real2019)	clear
				import	excel	"${clouldfolder}/DataWork/Census/state_local_finance_1977_2019.xlsx", firstrow sheet(s&l_pc_real2019)	clear
				drop	if	State=="United States"
				drop	if	mi(Year)
				rename	(E013GeneralExpenditure-E090PublicWelfDirectExp)	///
						(genexp_pc_real dirgenexp_pc_real edudirexp_pc_real	healthdirexp_pc_real highwaydirexp_pc_real housedirexp_pc_real policedirexp_pc_real welfaredirexp_pc_real)
				rename *real sl_= 
				isid State Year
				tempfile	state_local_pc_exp
				save		`state_local_pc_exp'
				
				*	State only
				*import	excel	"${dataWorkFolder}/Census/state_local_finance_1977_2019.xlsx", firstrow sheet(state_pc_real2019)	clear
				import	excel	"${clouldfolder}/DataWork/Census/state_local_finance_1977_2019.xlsx", firstrow sheet(state_pc_real2019)	clear				
				drop	if	State=="United States"
				drop	if	mi(Year)
				rename	(E013GeneralExpenditure-E090PublicWelfDirectExp)	///
						(genexp_pc_real dirgenexp_pc_real edudirexp_pc_real	healthdirexp_pc_real highwaydirexp_pc_real housedirexp_pc_real policedirexp_pc_real welfaredirexp_pc_real)
				rename *real s_= 
				isid State Year
				tempfile	state_pc_exp
				save		`state_pc_exp'
				
						
			*	Merge dataset
			use	`state_local_total_exp', clear
			merge	1:1	State Year using `state_local_pc_exp', assert(1 3)
				assert	inlist(Year,2001,2003)	&	State=="DC" if _merge==1	//	2 unmatched record from 2001/2003 DC expenditure (doesn't exist in UI data. I manually added them from Govt Finance Data)
				drop	_merge
			merge	1:1	State Year using `state_total_exp' //, assert(2 3) nogen
				assert	State=="DC"	if	_merge==1
				assert	inlist(Year,2001,2003) if _merge==2
				drop	_merge
			merge	1:1	State Year using `state_pc_exp', assert(1 3)
				assert	State=="DC"	if	_merge==1
				drop	_merge
			
					
			*	Clean data
			rename (State Year) (state year)
			replace	state="Washington D.C." if state=="DC"
			merge	m:1	state using "${SNAP_dtRaw}/Statecode.dta" , assert(3) nogen
			
			*	Save
			rename	statecode	rp_state
			compress
			save	"${SNAP_dtInt}/state_local_finance",	replace
			
			*	Merge GDP and state/local finance
			use	"${SNAP_dtInt}/GDP_1975_2019",	clear
			merge	1:1	rp_state year	using	"${SNAP_dtInt}/state_local_finance", assert(1 3)
				assert	inlist(year,1975,1976)	if	_merge==1	//	Unmatched record from 1975/1976 GDP (no expenditure data available during these years)
				drop	if	_merge==1	//	Drop 1975/1976
				drop	_merge
				
			
				*	Import missing data from another source
				*	Note that "per capita" expenditure will still be missing in many cases (ex. DC), so we will use "total" expenditure as our analysis
				foreach	expvar	in	genexp dirgenexp edudirexp healthdirexp highwaydirexp housedirexp policedirexp welfaredirexp	{
					
					*	Import missing	2001/2003 "state & local" expenditures from "state" expenditure (except DC where I manually added total expenditure from another source, and per capita expenditure is also missing)
					replace	sl_`expvar'_tot		=	s_`expvar'_tot		if	inlist(year,2001,2003)	&	state!="Washington D.C."
					replace	sl_`expvar'_pc_real	=	s_`expvar'_pc_real	if	inlist(year,2001,2003)	&	state!="Washington D.C."
	
					*	Import missing	"state" DC total expenditures from "state & local" total expenditures
					replace	s_`expvar'_tot		=	sl_`expvar'_tot		if	state=="Washington D.C."	
					
				}
				
				*	Generate 2001/2003 and DC indicator, to test whether imported data in state & local level make singificant changes in IV strength in the first stage.
				**	But I don't think "DC" indicator is necessary, since "state" variation is missing just by definition, thus using "state and local"-level dc expenditure for "state" expenditure isn't likely to cause an issue.
				**	Also, as of 2022-4-11, I do not use state&local level data (use state-level only) so these indicators won't be used in the analyses anyway.
				gen		year_01_03=0
				replace	year_01_03=1	if	inlist(year,2001,2003)
				
				gen		DC=0
				replace	DC=1	if	rp_state==8	//	DC
		
				*	Share of total direct expenditure on 4 different categories - education, public welfare, health and housing
				*	We generate different shares using different numerator/denominators for robustness check.
				local	eduvar		edudirexp_tot
				local	welfvar		welfaredirexp_tot
				local	healthvar	healthdirexp_tot
				local	housevar	housedirexp_tot
				
					*	Share of expenditure on spendings ("State and local")
					local	denominator	sl_dirgenexp_tot
					
					gen	share_edu_exp_sl		=	sl_`eduvar'	/	`denominator'
					gen	share_welfare_exp_sl	=	sl_`welfvar'	/	`denominator'
					gen	share_health_exp_sl		=	sl_`healthvar'	/	`denominator'
					gen	share_housing_exp_sl	=	sl_`housevar'	/	`denominator'
					egen	SSI_exp_sl	=	rowtotal(share_edu_exp_sl	share_welfare_exp_sl	share_health_exp_sl	share_housing_exp_sl)
					
					*	Share of expenditure on spendings ("State")
					local	denominator	s_dirgenexp_tot
					
					gen	share_edu_exp_s			=	s_`eduvar'	/	`denominator'
					gen	share_welfare_exp_s		=	s_`welfvar'	/	`denominator'
					gen	share_health_exp_s		=	s_`healthvar'	/	`denominator'
					gen	share_housing_exp_s		=	s_`housevar'	/	`denominator'
					egen	SSI_exp_s	=	rowtotal(share_edu_exp_s	share_welfare_exp_s	share_health_exp_s	share_housing_exp_s)
					
					*	Share of GDP on spendings	("State and local")
					*	Note that GDP is in millions while expenditure is in thousands, thus need to multiply denominator by 1,000 to make unit consistent
					local	denominator	GDP
					
					gen	share_edu_GDP_sl		=	sl_`eduvar'		/	(`denominator'*1000)
					gen	share_welfare_GDP_sl	=	sl_`welfvar'	/	(`denominator'*1000)
					gen	share_health_GDP_sl		=	sl_`healthvar'	/	(`denominator'*1000)
					gen	share_housing_GDP_sl	=	sl_`housevar'	/	(`denominator'*1000)
					egen	SSI_GDP_sl	=	rowtotal(share_edu_GDP_sl	share_welfare_GDP_sl	share_health_GDP_sl	share_housing_GDP_sl)
					
					*	Share of GDP on spendings ("State")
					local	denominator	GDP
					
					gen	share_edu_GDP_s		=	s_`eduvar'		/	(`denominator'*1000)
					gen	share_welfare_GDP_s	=	s_`welfvar'		/	(`denominator'*1000)
					gen	share_health_GDP_s	=	s_`healthvar'	/	(`denominator'*1000)
					gen	share_housing_GDP_s	=	s_`housevar'	/	(`denominator'*1000)
					egen	SSI_GDP_s	=	rowtotal(share_edu_GDP_s	share_welfare_GDP_s	share_health_GDP_s	share_housing_GDP_s)
					
					
				*	Label variables
				*	(2022-4-11) I only label state-level as I don't use state & local level. Will add label if needed later
				*	(2022-5-3) I now use state and local data only.
				
					label	var	share_edu_exp_sl		"State \& local exp on education (as \% of total exp)"
					label	var	share_welfare_exp_sl	"State \& local exp on public welfare (as \% of total exp)"
					label	var	share_health_exp_sl		"State \& local exp on health (as \% of total exp)"
					label	var	share_housing_exp_sl	"State \& local exp on housing (as \% of total exp)"
					label	var	SSI_exp_sl				"Social Spending Index (state \& local as \% of total exp)"
					
					label	var	share_edu_GDP_sl		"State \& local exp on education (as \% of GDP)"
					label	var	share_welfare_GDP_sl	"State \& local exp on public welfare (as \% of GDP)"
					label	var	share_health_GDP_sl		"State \& local exp on health (as \% of GDP)"
					label	var	share_housing_GDP_sl	"State \& local exp on housing (as \% of GDP)"
					label	var	SSI_GDP_sl				"Social Spending Index (state \& local as \% of GDP)"
					
					label	var	share_edu_exp_s			"State exp on education (as \% of total exp)"
					label	var	share_welfare_exp_s		"State exp on public welfare (as \% of total exp)"
					label	var	share_health_exp_s		"State exp on health (as \% of total exp)"
					label	var	share_housing_exp_s		"State exp on housing (as \% of total exp)"
					label	var	SSI_exp_s				"Social Spending Index (state as \% of total exp)"
					
					label	var	share_edu_GDP_s			"State exp on education (as \% of GDP)"
					label	var	share_welfare_GDP_s		"State exp on public welfare (as \% of GDP)"
					label	var	share_health_GDP_s		"State exp on health (as \% of GDP)"
					label	var	share_housing_GDP_s		"State exp on housing (as \% of GDP)"
					label	var	SSI_GDP_s				"Social Spending Index (state as \% of GDP)"
					
			*	Robustness check between SSI from old GDP (pre-1997) and from new GDP (post-1997)
					
					*	Share using old GDP
					local	denominator	GDP_old
					
					gen	share_edu_oldGDP_sl		=	sl_`eduvar'		/	(`denominator'*1000)
					gen	share_welfare_oldGDP_sl	=	sl_`welfvar'		/	(`denominator'*1000)
					gen	share_health_oldGDP_sl	=	sl_`healthvar'	/	(`denominator'*1000)
					gen	share_housing_oldGDP_sl	=	sl_`housevar'	/	(`denominator'*1000)
					egen	SSI_oldGDP_sl	=	rowtotal(share_edu_oldGDP_sl	share_welfare_oldGDP_sl	share_health_oldGDP_sl	share_housing_oldGDP_sl)
					
					*	Share using new GDP
					local	denominator	GDP_new
					
					gen	share_edu_newGDP_sl		=	sl_`eduvar'		/	(`denominator'*1000)
					gen	share_welfare_newGDP_sl	=	sl_`welfvar'		/	(`denominator'*1000)
					gen	share_health_newGDP_sl	=	sl_`healthvar'	/	(`denominator'*1000)
					gen	share_housing_newGDP_sl	=	sl_`housevar'	/	(`denominator'*1000)
					egen	SSI_newGDP_sl	=	rowtotal(share_edu_newGDP_sl	share_welfare_newGDP_sl	share_health_newGDP_sl	share_housing_newGDP_sl)
					
					
					*	Difference in SSI b/w old and new GDP (only available in 1997 which has both old and new GDP)
					*	We cannot reject the null hypothesis that mean difference is zero, implying that we can combine old and new GDP into one variable for our analyses.
					ttest	SSI_oldGDP_sl==SSI_newGDP_sl	if	year==1997
					
					drop	*oldGDP*	*newGDP*
					
					
					
					
					*	Save
					compress
					save	"${SNAP_dtInt}/SSI",	replace
			
			*	Summary statistics
			use	"${SNAP_dtInt}/SSI",	clear
			preserve
			collapse	(mean)	share_edu_GDP_sl share_welfare_GDP_sl share_health_GDP_sl share_housing_GDP_sl SSI_GDP_sl, by(year)
			
			graph	twoway	(line SSI_GDP_sl year, /*lpattern(dash)*/ xaxis(1 2) yaxis(1))	///
							/*(line TFP_monthly_cost	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)) */ 	///
							/*(line FS_rec_amt	year, lpattern(dash_dot) xaxis(1 2) yaxis(2))*/,  ///
							xline(1980 1993 1999 2007, axis(1) lpattern(dot)) xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
							xtitle(Year)	xtitle("", axis(2))  title(Share of State & Local Social Spending by Year)	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_FSamt_byyear, replace)
			
			
			graph	export	"${SNAP_outRaw}/SSI_byyear.png", replace
			graph	close
			
			restore
			collapse	(mean)	share_edu_GDP_sl share_welfare_GDP_sl share_health_GDP_sl share_housing_GDP_sl SSI_GDP_sl, by(state)
			sort	SSI_GDP_sl
		
		*	State governors data
		*	This data is based on "United States Governors 1775-2020" https://doi.org/10.3886/E102000V3
		*	This data are not complete (ex. missing years in some state), so I added them manually.
		*import	excel	"${dataWorkFolder}/Politics/united_states_governors_1775_2020.xlsx", firstrow sheet(governors_1775_2021)	clear
		import	excel	"${clouldfolder}/DataWork/Politics/united_states_governors_1775_2020.xlsx", firstrow sheet(governors_1775_2021)	clear
			
			*	Clean data
			
				*	Keep relevant observations 
				keep	if	inrange(year,1977,2021)	//	Year 1977-
				keep	if	!mi(statecode)	//	Keep 48 continental states + AK, HA
				
				*	Clean variables
				split time_in_office
				destring time_in_office1, gen(start_year)
				destring time_in_office3, gen(end_year)
				drop	time_in_office?
				
				loc	var	governor_party
				cap	drop	`var'
				gen		`var'	=	1	if	party	==	"Democrat"
				replace	`var'	=	2	if	party	==	"Republican"
				replace	`var'	=	0	if	!inlist(party,"Democrat","Republican")
				
					/* (2022-7-22) I no longer attempt to do it, since some independent governors pursue mixed policies. For example, Bill Walker in Alaska supported gun control (rep) and Medicaid expansion (dem) at the same time.
					*	(Incomplete) For independent governors, I determine party association manually based on different circumstances
					replace	`var'=	2	if	governor=="Walter J. Hickel" &	inrange(year,1991,1994)	//	Walter was Republican before- and after- these periods, so I assume he is Republican
					replace	`var'=	2	if	governor=="Bill Walker" &	inrange(year,2015,2018)		//	He is pretty mixed...
					*/
					
				label	define	`var'	0	"Others"	1	"Democrat"	2	"Republican"
				label	value	`var'	`var'
				
				*	Handle observations with multiple governors within a year
				duplicates tag	state	year, gen(multiple_governor)
				
					*	There are a few caess where 3 or more changes happened within a year. We modify it manually for these cases					
						drop	if	year==1994	&	state=="Alaska"			&	party!="Independent"	//	Alaska, 1994: Walter J. Hickel, independent as of Jan 1994 (later changed party)
						drop	if	year==1979	&	state=="Maryland"		&	governor!="Harry Roe Hughes"	//	Maryland, 1979: Harry Roe Hughes as of the latest January governor
						drop	if	year==2017	&	state=="New Hampshire"	&	governor!="Chris Sununu"
						drop	if	year==2002	&	state=="New Jersey"		&	governor!="James E. McGreevey"
						drop	if	year==1991	&	state=="Vermont"		&	governor!="Richard A. Snelling" // from Jan to Aug (death)
						drop	if	year==2017	&	state=="West Virginia"	&	!(governor=="Jim Justice"	&	change_month==1) // Jim changed the party to Rep in Aug, but Dem as of Jan.
						
					*drop	if	multiple_governor>=2
					
				*	Determine former and latter governor.
				**	Note: current code does not work to those who changed the party during the year. Need to think about how to handle it.
				bys	state	year:	egen	start_year_dup	=	min(start_year)
				gen		former	=	1	if	multiple_governor==1	&	start_year == start_year_dup
				replace	former	=	0	if	multiple_governor==1	&	start_year != start_year_dup
		
							
				*	For consistency with the NCSL state legislative partisan composition data, which are based as of Jan or Feb of each year, we determine governor party as of Jan.
				
					*	If governor changed in January, regard new governor as that year's governor so drop former governor. Otherwise, regard former governer as that year's governor so drop the latter
					drop	if	multiple_governor==1	&	change_month==1	&	former==1
					drop	if	multiple_governor==1	&	inrange(change_month,2,12)	&	former==0
					
					*	For those who changed the party within the year (so "former" variable can't be used), manually drop based on the month of party switch
					drop	if	year==1991	&	state=="Louisiana"		&	party=="Republican"	//	Changed to Republic party in March, so drop it (Democrat as of Jan)
					drop	if	year==2013	&	state=="Rhode Island"	&	party=="Democrat"	//	Changed to Democrat party in May, so drop it (Independent as of Jan)
					
					*	Other cases
					drop	if	year==1978	&	state=="Maryland"	&	governor=="Marvin Mandel"	// wasn't in the office so there was an acting governor (Blair Lee). I treat Blair as the governor (doesn't really matter as they are both Democrat)
					
				
				/*	Outdated codes as of March 12, 2022
				*	If former and latter governor have the same party, it is OK to drop either former or latter (so just drop former)
				duplicates tag	state	year	governor_party if multiple_governor==1, gen(same_party)
				drop	if multiple_governor==1	&	same_party==1	&	former==1
				
				*	If new governor came in April or earlier months, regard new governor as that year's governor (since new governor is in position for 8+ months) so drop the old governor
				drop	if	multiple_governor==1	&	same_party==0	&	inrange(change_month,1,4)	&	former==1
				
				*	If new governor came in September or later months, regard old governor as that year's governor (since old governor is in position for 8+ months) so drop the new governor
				drop	if	multiple_governor==1	&	same_party==0	&	inrange(change_month,9,12)	&	former==0
				
				*	If position changed between May to August, assign "Others" to governor's party and drop former (doesn't matter to drop former or latter)
				replace	governor_party=0	if	multiple_governor==1	&	same_party==0	&	inrange(change_month,5,8)
				drop	if	multiple_governor==1	&	same_party==0	&	inrange(change_month,5,8)	&	former==1
				
					duplicates	tag	state	year, gen(newdup)
					*	As of now (2022/2/23) There is only one case that has duplicate. I can come back here and fix it later. SO drop it for now
					drop if newdup==1
				*/				
				
				isid	state	year
				
				*	Save
				rename	statecode	rp_state
				save	"${SNAP_dtInt}/Governors",	replace
				
			*	State legislative bipartisan composition (other than Nebraska and D.C)
			*	Main source: National Conference of State Legislatures (1978-2008 (even years)), (2009-2021), Balletpedia "Who Runs the States, Partisanship Report" (1993-2007 (odd years))
			*import	excel	"${dataWorkFolder}/Politics/united_states_governors_1775_2020.xlsx", firstrow sheet(state_partisan_comp)	clear
			import	excel	"${clouldfolder}/DataWork/Politics/united_states_governors_1775_2020.xlsx", firstrow sheet(state_partisan_comp)	clear
			
			
				*	For missing early years, copy the data of the last year available (ex. Use 1974 data for 1975)
				forval	year=1977(2)1991	{
					
					local	prevyear=`year'-1
					gen	LegisComp`year'=LegisComp`prevyear'
							
				}
				
				*	Re-shape data
				rename	State state
				drop	if	mi(state)
				reshape	long	LegisComp, i(state) j(year)
				drop	if	inrange(year,1974,1976)
				
				*	Generate legislator control (holding both house and senate) variable with 4 categores; Democrat, Republican, Divided, N/A
				loc	var	legis_control
				cap	drop	`var'
				gen		`var'	=	0	if	inlist(LegisComp,"N/A","NA")	//	NA (ex. Nebraska)
				replace	`var'	=	1	if	inlist(LegisComp,"D","Dem","Dem*","*Dem")	//	Democrat
				replace	`var'	=	2	if	inlist(LegisComp,"R","Rep","Rep*")	//	Republican
				replace	`var'	=	3	if	inlist(LegisComp,"Divided","Divided*","S","Split","Split*")	//	Divided
				
				label	define	`var'	0	"N/A"	1	"Democrat"	2	"Republican"	3	"Divided", replace
				label	value	`var'	`var'
				label var	`var'	"State Legislature Control"
				
				save	"${SNAP_dtInt}/State_control",	replace
				
			*	City council data (D.C.)
			*import	excel	"${dataWorkFolder}/Politics/united_states_governors_1775_2020.xlsx", firstrow sheet(DC)	clear
			import	excel	"${clouldfolder}/DataWork/Politics/united_states_governors_1775_2020.xlsx", firstrow sheet(DC)	clear		
			
				*	Clean variable
				rename	(Year State) (year state)
				drop	if	year<1977
				
				*	Veriable that shows whether Democrat has the majority control
				ds	*_party
				local	partyvars	`r(varlist)'
				foreach	var	of	local	partyvars	{
				    
					cap	drop	`var'_num
					gen		`var'_num	=	0	if	inlist(`var',"N/A","NA")	//	NA (ex. Nebraska)
					replace	`var'_num	=	1	if	inlist(`var',"D","Dem","Dem*","*Dem")	//	Democrat
					replace	`var'_num	=	2	if	inlist(`var',"R","Rep","Rep*")	//	Republican
					replace	`var'_num	=	3	if	inlist(`var',"I","STD")	//	Divided
					
				}
				
				cap	drop	count_dem
				egen	count_dem	=	anycount(atlarge*_num Ward_*_num),	values(1)	//	Number of seats (excluding mayor) occupied by Democrats
				gen		council_control=1	if	count_dem>=7	//	If at least 7 of 12 seats belong to Democrats, we consider it as democrat major control
				assert	council_control==1	// Historically, democrats always had major control in D.C. city council
				
				*	Save
				save	"${SNAP_dtInt}/council_control_DC",	replace
				
			*	Attorney General and Secretary of State (Nebraska)
			*	Since Nebraska is unicameral without official party associations, we use triplex (one party holds governor, attorney general and secretary of state at the same time) as majority control
			*import	excel	"${dataWorkFolder}/Politics/united_states_governors_1775_2020.xlsx", firstrow sheet(Nebraska)	clear
			import	excel	"${clouldfolder}/DataWork/Politics/united_states_governors_1775_2020.xlsx", firstrow sheet(Nebraska)	clear
		
				*	Clean variable
				rename	(Year State) (year state)
				drop	if	year<1977
				
				*	Variable that shows which party has control over (1) attorney general and (2) secretary of state
				cap	drop	atgen_sos_party
				gen		atgen_sos_party=1	if	att_gen_party=="D"	&	soc_party=="D"	// Democrat
				replace	atgen_sos_party=2	if	att_gen_party=="R"	&	soc_party=="R"	// Democrat
				assert	atgen_sos_party==2	//	 Historically, both positions were affiliated with Republicans
				
				*	Save
				save	"${SNAP_dtInt}/atgen_soc_Nebraska",	replace
			
			*	Merge governor and state polictics data (City council (DC), At.gen and Secretary of State (Nebraska), Bipartisan composition (all other states))
			
				use "${SNAP_dtInt}/Governors", clear
				merge	m:1	state	year	using	"${SNAP_dtInt}/State_control" , nogen assert(1 3) keepusing(legis_control)	//	Bipartisan composition (all other states)
				merge	m:1	state	year	using	"${SNAP_dtInt}/council_control_DC", nogen assert(1 3) keepusing(council_control)	//	City council control (D.C.)
				merge	m:1	state	year	using	"${SNAP_dtInt}/atgen_soc_Nebraska", nogen assert(1 3) keepusing(atgen_sos_party)	//	Att.gen and SoS (Nebraska)
				
				*	Keep relevant years of data only
				keep	if	inrange(year,1977,2019)
								
				*	Majority of state politics
				loc	var_dem	major_control_dem
				loc	var_rep	major_control_rep
				loc	var_mix	major_control_mix
				cap	drop	`var_dem'
				cap	drop	`var_rep'
				cap	drop	`var_mix'
				gen	`var_dem'=0
				gen	`var_rep'=0
				gen	`var_mix'=0
				
					*	For D.C., we determine majority if one party holds both (1) governor and (2) majority of city council
					replace	`var_dem'=1	if	rp_state==8	&	governor_party==1	&	council_control==1	//	Both republic
					replace	`var_rep'=1	if	rp_state==8	&	governor_party==2	&	council_control==2	//	Both democrat
					replace	`var_mix'=1	if	rp_state==8	&	governor_party!=council_control==2	//	Neither
					assert	`var_dem'==1	if	rp_state==8	//	In our data, Democrats always had major control in D.C.
					assert	`var_rep'==0	if	rp_state==8	
					assert	`var_mix'==0	if	rp_state==8	
					
					*	For Nebraska, we determine majority if one party holds all three positions; governor, attorney general and secretary of state
					*	This state is called "Triplex"
					replace	`var_dem'=1	if	rp_state==26	&	governor_party==1	&	atgen_sos_party==1	//	Both democrat
					replace	`var_rep'=1	if	rp_state==26	&	governor_party==2	&	atgen_sos_party==2	//	Both republic
					replace	`var_mix'=1	if	rp_state==26	&	`var_dem'!=1 & `var_rep'!=1	//	Neither
					
					*	For all other sattes, we determine majority if one party has both governship and majority in both chambers
					*	This status is called "trifecta"
					replace	`var_dem'=1	if	!inlist(rp_state,8,26)	&	governor_party==1	&	legis_control==1	//	Both democrat
					replace	`var_rep'=1	if	!inlist(rp_state,8,26)	&	governor_party==2	&	legis_control==2	//	Both republic
					local	mixed	((governor_party!=legis_control	&	legis_control!=3)	|	///	*/	Governor party != legis control party and legis control is not N/A 
									(governor_party==0)	|	///	/* governor party is independent*/
									(legis_control==3))			/* legis control is divided*/
					replace	`var_mix'=1	if	!inlist(rp_state,8,26)	&	(!mi(governor_party)	&	!mi(legis_control))	&	`mixed'	//	Mixed (neither party has trifecta status)
					
					/*		(2022-7-22)	I do not use it, as it is not easy to 
					*	(Incomplete code) Decompose mixed status into (1) Demo governor + Rep chamber (2) Rep governor + Demo chamber
					loc	var	mixed_repgovt
					cap	drop	`var'
					gen		`var'=0	if	inlist(1,`var_dem',`var_rep')	|	legis_control==3
					replace	`var'=1	if	`var_mix'==1	&	governor_party==1	&	legis_control==2	//	Demo governor + Rep chamber
					replace	`var'=2	if	`var_mix'==1	&	governor_party==2	&	legis_control==1	//	Rep governor + Rep chamber
					*/
				
				*	Double-check that all observations belong to one and only one of the three categories
				cap	drop	tot
				egen tot = rowtotal( major_control_dem major_control_rep major_control_mix)
				assert tot==1
				drop tot
				
				
				
				/*
				*	Trifecta is the status when one political party holds governorship, state control (both houses)
				loc	var	trifecta
				cap	drop	`var'
				gen	`var'	=	.
				replace	`var'	=	1	if	governor_party==1	&	legis_control==1	//	Democrat trifecta
				replace	`var'	=	2	if	governor_party==2	&	legis_control==2	//	Republic trifecta
				
				local	mixed	((governor_party!=legis_control	&	legis_control!=3)	|	///	/*	Governor party != legis control party and legis control is not N/A (*/
								(governor_party==0)	|	///	/* governor party is independent*/
								(legis_control==3))		/* legis control is divided*/
				replace	`var'	=	3	if	(!mi(governor_party)	&	!mi(legis_control))	&	`mixed'	//	Mixed (neither party has trifecta status)
				replace	`var'	=	0	if	legis_control==0	//	Nebraska and D.C.
				replace	`var'	=	.	if	mi(governor_party)	|	mi(legis_control)	//	Missing data (legis_control)
				
				
				
				label	define	`var'	0	"N/A"	1	"Democrat control"	2	"Rep control"	3	"Neither"
				label	value	`var'	`var'
				label	var	`var'	"State Trifecta"
				*/
					
				*	Save
				save	"${SNAP_dtInt}/State_politics",	replace
				use 	"${SNAP_dtInt}/State_politics",	clear
				
				
		*	SNAP policy dataset (raw) (199601-201612)
		*	(2023-06-12) We found an issue with this data, so we no longer use this data. Instead, we will use the official aggregated data below.
		/*
		{
		*import excel	"${dataWorkFolder}/USDA/SNAP_Policy_Database.xlsx", firstrow 	clear
		import excel	"${clouldfolder}/DataWork/USDA/DataSets/Raw/SNAP_Policy_Database.xlsx", firstrow 	clear
				
			label	define	policy_status	0	"No"	1	"Statewide"	2	"Select parts of the state"
		
			*	Clean data
			loc	var	rp_state
			cap	drop	`var'
			gen	`var'	=	state_fips
			recode	`var'	(2=50)	(4=2)	(5=3)	(6=4)	(8=5)	(9=6)	(10=7)	(11=8)	(12=9)	(13=10)	(15=51)	(16=11)	(17=12)	(18=13)	///
								(19=14)	(20=15)	(21=16)	(22=17)	(23=18)	(24=19)	(25=20)	(26=21)	(27=22)	(28=23)	(29=24)	(30=25)	(31=26)	(32=27)	///
								(33=28)	(34=29)	(35=30)	(36=31)	(37=32)	(38=33)	(39=34)	(40=35)	(41=36)	(42=37)	(44=38)	(45=39)	(46=40)	(47=41)	///
								(48=42)	(49=43)	(50=44)	(51=45)	(53=46)	(54=47)	(55=48)	(56=49)
			label	value	`var'	statecode
			label	var	`var'	"State"
			order	`var'
			drop	state_fips	statename	state_pc

			
			*	Year and month
			*	Since we want to match it with previous month of survey (when survey asked FS redemption), make a new variable to be matched with previous month
			clonevar	prev_yrmonth	=	yearmonth
			order	prev_yrmonth, after(yearmonth)
			lab	var	yearmonth "Year and Month of Policy"
			/*
			cap	drop	year	month
			gen year 	=	floor(yearmonth/100)
			gen	month	=	mod(yearmonth,100)
			order	year	month, after(yearmonth)
			drop	yearmonth
			label	var	year	"Year"
			label	var	month	"Month"
			*/
			
			lab	define	yes1no0	1	"Yes"	0	"No"
			
			*	Policy variables
			label	var	bbce	"Broad-based categorical eligibility (BBCE)"
			label value	bbce	yes1no0
			
			loc	var	bbce_inclmt
			label	var	`var'	"Gross income limit as a percentage of the Federal pov guideline under BBCE"
			replace	`var'=.n	if	`var'==-9
					
			loc	var	bbce_asset
			lab	var	`var'	"Asset test eliminated (under BBCE)"
			replace	`var'=.n	if	`var'==-9
			label	value	`var'	yes1no0
			
			loc	var	bbce_a_amt
			label	var	`var'	"Dollar amount of the asset limit used under BBCE (K)"
			replace	`var'=.n	if	`var'==-9
			
			loc	var	bbce_a_veh
			label	var	`var'	"Exludes at least one (but not all) vehicles from asset test under BBCE"
			replace	`var'=.n	if	`var'==-9
			label	value	`var'	yes1no0
			
			loc	var	bbce_hh
			label	var	`var'	"Limits BBCE to certain type of HHs"
			replace	`var'=.n	if	`var'==-9
			label	value	`var'	policy_status
			
			loc	var	bbce_sen
			label	var	`var'	"Gross income limit for senior/disabled to quality for BBCE"
			replace	`var'=.n	if	`var'==-9
			label	value	`var'	yes1no0
			note	`var':	HHs with senior or disabled members whose income is above the state-specified cut-off (typcially 200 percent of Pov line) do not quality for the BBCE and would face the federal asset limit
			
			loc	var	call
			lab	var	`var'	"Call center availability"
			lab	define	`var'	0	"No call center"	///
								1	"Available statewide"	///
								2	"Only in select part of the state"
			lab	values	`var'	`var'					
			
			loc	var	cap
			lab	var	`var'	"Operates Combined Application Project for SSI receipients"
			lab	value	`var'	yes1no0
			note	`var':	It allows SSI recipients to use a streamlined SNAP application process.
			
			loc	var	certearn0103
			lab	var	`var'	"Proportion of SNAP units with earnings with 1-3 month recertification period"
			
			loc	var	certearn0406
			lab	var	`var'	"Proportion of SNAP units with earnings with 4-6 month recertification period"
			
			loc	var	certearn0712
			lab	var	`var'	"Proportion of SNAP units with earnings with 7-12 month recertification period"
			
			loc	var	certearn1399
			lab	var	`var'	"Proportion of SNAP units with earnings with 13+ month recertification period"
			
			loc	var	certearnavg
			lab	var	`var'	"Average certification periods for SNAP units with earnings (in months)"
			
			loc	var	certearnmed
			lab	var	`var'	"Median certification periods for SNAP units with earnings (in months)"
			
			loc	var	certeld0103
			lab	var	`var'	"Proportion of elderly SNAP units with 1-3 month recertification period"
			
			loc	var	certeld0406
			lab	var	`var'	"Proportion of elderly SNAP units with 4-6 month recertification period"
			
			loc	var	certeld0712
			lab	var	`var'	"Proportion of elderly SNAP units with 7-12 month recertification period"
			
			loc	var	certeld1399
			lab	var	`var'	"Proportion of elderly SNAP units with 13+ month recertification period"
			
			loc	var	certeldavg
			lab	var	`var'	"Average certification periods for elderly SNAP units (in months)"
			
			loc	var	certeldmed
			lab	var	`var'	"Median certification periods for elderly SNAP units (in months)"
			
			loc	var	certnonearn0103
			lab	var	`var'	"Proportion of nonearning, nonelderly SNAP units with 1-3 month recertification period"
			
			loc	var	certnonearn0406
			lab	var	`var'	"Proportion of nonearning, nonelderly SNAP units with 4-6 month recertification period"
			
			loc	var	certnonearn0712
			lab	var	`var'	"Proportion of nonearning, nonelderly SNAP units with 7-12 month recertification period"
			
			loc	var	certnonearn1399
			lab	var	`var'	"Proportion of nonearning, nonelderly SNAP units with 13+ month recertification period"
			
			loc	var	certnonearnavg
			lab	var	`var'	"Average certification periods for nonearning, nonelderly SNAP units (in months)"
			
			loc	var	certnonearnmed
			lab	var	`var'	"Median certification periods for nonearning, nonelderly SNAP units (in months)"
			
			loc	var	ebtissuance
			lab	var	`var'	"Proportion of the dollar value of all SNAP benefits that are accounted for by EBIT"
			
			loc	var	faceini
			lab	var	`var'	"Waiver to use a telephone interview in lieu of a face-to-fac interview for initial certification"
			label	value	`var'	yes1no0
			
			loc	var	facerec
			lab	var	`var'	"Waiver to use a telephone interview in lieu of a face-to-fac interview for recertification"
			label	value	`var'	yes1no0
			
			loc	var	fingerprint
			lab	var	`var'	"Fingerprint requirement"
			label	value	`var'	policy_status
			
			loc	var	noncitadultfull
			lab	var	`var'	"SNAP or state-funded food assistance eligibility of ALL legal noncitizen adults (18-64)"
			label	value	`var'	yes1no0
			
			loc	var	noncitadultpart
			lab	var	`var'	"SNAP or state-funded food assistance eligibility of SOME legal noncitizen adults (18-64)"
			label	value	`var'	yes1no0
			
			loc	var	noncitchildfull
			lab	var	`var'	"SNAP or state-funded food assistance eligibility of ALL legal noncitizen children (<18)"
			label	value	`var'	yes1no0
			
			loc	var	noncitchildpart
			lab	var	`var'	"SNAP or state-funded food assistance eligibility of SOME legal noncitizen children (<18)"
			label	value	`var'	yes1no0
			
			loc	var	nonciteldfull
			lab	var	`var'	"SNAP or state-funded food assistance eligibility of ALL legal noncitizen elderly (>64)"
			label	value	`var'	yes1no0
			
			loc	var	nonciteldpart
			lab	var	`var'	"SNAP or state-funded food assistance eligibility of SOME legal noncitizen elderly (>64)"
			label	value	`var'	yes1no0
			
			loc	var	oapp
			lab	var	`var'	"Online Application"
			label	value	`var'	policy_status
			
			loc	var	outreach
			lab	var	`var'	"Total grant outreach spending (nominal, K)"
			
			loc	var	reportsimple
			lab	var	`var'	"Simplified reporting"
			label	value	`var'	yes1no0
			
			loc	var	transben
			lab	var	`var'	"Transitional SNAP benefits to families leaving the TANF or state-funded cash assistance programs"
			label	value	`var'	yes1no0
			
			loc	var	vehexclall
			lab	var	`var'	"ALL vehicles excluded from the asset test"
			label	value	`var'	yes1no0
			
			loc	var	vehexclamt
			lab	var	`var'	"Excemption of the amount higher than thee SNAP standard auto exemption"
			label	value	`var'	yes1no0
			
			loc	var	vehexclall
			lab	var	`var'	"ALL vehicles excluded from the asset test"
			label	value	`var'	yes1no0
			note `var':	When a State removes the asset test due to its adoption of broad-based categorical eligibility, vehexclamt is assigned a value of 0.
			
			loc	var	vehexclone
			lab	var	`var'	"SOME vehicles excluded from the asset test"
			label	value	`var'	yes1no0
			note `var':	When a State removes the asset test due to its adoption of broad-based categorical eligibility, vehexclamt is assigned a value of 0.
			
			*	Construct SNAP index (Stacy, Brian, Laura Tiehen, and David Marquardt. 2018. “Using a Policy Index To Capture Trends and Differences in State Administration of USDA’s Supplemental Nutrition Assistance Program.” ERR-244. Economic Research Report. United States Department of Agriculture, Economic Research Service. http://www.ers.usda.gov/publications/pub-details/?pubid=87095.)

			loc	var_uw	SNAP_index_unweighted
			loc	var_w	SNAP_index_weighted
			cap	drop	`var_uw'	`var_w'
			
			gen	`var_uw'=0
			gen	`var_w'=0
			
			lab	var	`var_uw'	"SNAP Index, unweighted"
			lab	var	`var_w'	"SNAP Index, weighted"
				
				replace	`var_uw'	=	`var_uw'	+	1	if	vehexclone==1	//	Excludes at least one (but not all) vehicle but not all
				replace	`var_w'		=	`var_w'	+	1.624	if	vehexclone==1	//	Excludes at least one (but not all) vehicle but not all
				
				replace	`var_uw'	=	`var_uw'	+	1	if	vehexclall==1	//	Excludes ALL vehicle
				replace	`var_w'		=	`var_w'	+	1.552	if	vehexclall==1	//	Excludes ALL vehicle
				
				replace	`var_uw'	=	`var_uw'	+	1	if	bbce==1	//	BBCE
				replace	`var_w'		=	`var_w'	+	1.828	if	bbce==1	//	BBCE
				
				replace	`var_uw'	=	`var_uw'	+	1	if	reportsimple==1	//	Simplified reporting
				replace	`var_w'		=	`var_w'	+	1.132	if	reportsimple==1	//	Simplified reporting
				
				replace	`var_uw'	=	`var_uw'	+	1	if	oapp==1	//	Statewide online application
				replace	`var_w'		=	`var_w'	+	0.456	if	oapp==1	//	Statewide online application
				
				replace	`var_uw'	=	`var_uw'	+	ebtissuance	//	Proportion of value issued by EBT
				replace	`var_w'		=	`var_w'	+	(ebtissuance*0.276)	//	Proportion of value issued by EBT
				
				replace	`var_uw'	=	`var_uw'	+	1	if	!mi(outreach)	&	outreach>0	//	(paper doesn't mention how they use this variable to index, so I assume that add 1 to index if state spends non-zero amount)
				replace	`var_w'		=	`var_w'	+	0.148	if	!mi(outreach)	&	outreach>0	//	(paper doesn't mention how they use this variable to index, so I assume that add 1 to index if state spends non-zero amount)
				
				replace	`var_uw'	=	`var_uw'	-	1	if	noncitadultfull==0	//	Legal non-citizen eligibility
				replace	`var_w'		=	`var_w'	-	4.8	if	noncitadultfull==0	//	Legal non-citizen eligibility
				
				replace	`var_uw'	=	`var_uw'	-	(certearn0103)		//	Short recertification period (1-3 months)
				replace	`var_w'		=	`var_w'		-	(certearn0103*3.180)	//	Short recertification period (1-3 months)
				
				replace	`var_uw'	=	`var_uw'	-	1	if	fingerprint==1	//	Statewide fingerprint requirement
				replace	`var_w'	=	`var_w'	-	1.864	if	fingerprint==1	//	Statewide fingerprint requirement
				
				*	Scale unweighted index (as in the paper)
				replace	`var_uw'	=	`var_uw'	+	4
				
			*	Save
			save	"${SNAP_dtInt}/SNAP_policy_data",	replace
		}
		*/
		

		*	SNAP policy index data file (1997-2014)
		*	(2023-05-22) This file includes the indices matching to the working paper, but different from manually computed index.
		*	(2023-06-12) We found an issue with the manually imported data, so we use the official data
		{
			import excel	"${clouldfolder}/DataWork/USDA/DataSets/Raw/snappolicyindexdata.xls", firstrow cellrange(A2:X971) clear
				
				*	Clean data
			loc	var	rp_state
			cap	drop	`var'
			gen	`var'	=	StateFIPSCode
			recode	`var'	(2=50)	(4=2)	(5=3)	(6=4)	(8=5)	(9=6)	(10=7)	(11=8)	(12=9)	(13=10)	(15=51)	(16=11)	(17=12)	(18=13)	///
								(19=14)	(20=15)	(21=16)	(22=17)	(23=18)	(24=19)	(25=20)	(26=21)	(27=22)	(28=23)	(29=24)	(30=25)	(31=26)	(32=27)	///
								(33=28)	(34=29)	(35=30)	(36=31)	(37=32)	(38=33)	(39=34)	(40=35)	(41=36)	(42=37)	(44=38)	(45=39)	(46=40)	(47=41)	///
								(48=42)	(49=43)	(50=44)	(51=45)	(53=46)	(54=47)	(55=48)	(56=49)
			label	value	`var'	statecode
			label	var	`var'	"State"
			order	`var'
			drop	Statename StatePostalCode StateFIPSCode
			
			rename	Year	year
			rename	(UnweightedSNAPpolicyindex WeightedSNAPpolicyindex)	(SNAP_index_uw	SNAP_index_w)
			rename	(UnweightedEligibilityindex UnweightedTransactionCostinde UnweightedStigmaindex UnweightedOutreachindex)	(Elig_index_uw Transact_index_uw Stigma_index_uw Outreach_index_uw)
			rename	(WeightedEligibilityindex WeightedTransactionCostindex WeightedStigmaindex WeightedOutreachindex)			(Elig_index_w Transact_index_w Stigma_index_w Outreach_index_w)
			
			rename	(Exemptonevehiclebutnotall-FederallyfundedradioorTVad)	(exempt_one	exempt_all	BBCE	elig_rest	short_recert	simp_report	online_app	EBT_share	fingerprint	outreach)
			
			*	Save
			save	"${SNAP_dtInt}/SNAP_policy_data_official",	replace
		}
		
		
		*	Census data (household information, poverty rate, etc.)
		{
			
			*	U.S. population estimates (in person)
			
				*	1979-1999
				import delimited "${clouldfolder}\DataWork\Census\Annul Estimates of the Resident Population\popclockest.txt", delimiter(space) clear 
				keep	in	7/27
				keep	v4	v10
				rename	(v4	v10)	(year	US_est_pop)
				replace	US_est_pop	=	subinstr(US_est_pop,",","",.)
				destring	*, replace
				format	%12.0fc	US_est_pop
				
				lab	var	year	"Year"
				lab	var	US_est_pop	"US Population Estimates"
				
				tempfile	US_est_pop_1979_1999
				save		`US_est_pop_1979_1999'
				
				*	2000-2009
				import	excel	"${clouldfolder}\DataWork\Census\Annul Estimates of the Resident Population\us-est00int-01.xls", sheet("US-EST00INT-01") clear
				keep	C-L
				
				keep	in	5
				destring	*, replace
				rename	(C-L)	(US_est_pop#), addnumber 
				rename	(US_est_pop#)	(US_est_pop#), renumber(2000)
				
				gen		B=1	//	temporary variable for reshape
				reshape	long	US_est_pop, i(B) j(year)
				drop	B
				
				tempfile	US_est_pop_2000_2009
				save		`US_est_pop_2000_2009'
				
				*	2010-2019
				import excel "${clouldfolder}\DataWork\Census\Annul Estimates of the Resident Population\nst-est2019-01.xlsx", sheet("NST01") clear
				keep	D-M
				rename	(D-M)	(US_est_pop#), addnumber 
				rename	(US_est_pop#)	(US_est_pop#), renumber(2010)
				keep	in	5
				destring	*, replace
				
				gen		B=1	//	temporary variable for reshape
				reshape	long	US_est_pop, i(B) j(year)
				drop	B
				
				tempfile	US_est_pop_2010_2019
				save		`US_est_pop_2010_2019'
				
				*	Append data
				use		`US_est_pop_1979_1999',	clear
				append	using	`US_est_pop_2000_2009'
				append	using	`US_est_pop_2010_2019'
				sort	year
				
				save	"${SNAP_dtInt}/US_population_estimates.dta", replace
			
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
								HH_age_45_54	HH_age_55_64	HH_age_65_74	HH_age_above_75	HH_age_median_Census)
								
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
			lab	var	HH_age_median_Census	"Median householder age"
		
		*	Generate additional variables
			
			*	Median age as intenger
			gen	HH_age_median_Census_int	=	int(HH_age_median_Census)
			
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
			rename	(A	D)	(year	pov_rate_national)
			
			drop	if	year=="2013 (4)"
			drop	if	year=="2017"
			
			replace	year=substr(year,1,4)
			lab	var	year	"Year"
			lab	var	pov_rate_national	"Poverty rate (national)"
			destring	year, replace
			
			*	Save
			save	"${SNAP_dtInt}/pov_rate_1979_2019.dta", replace
		
		*	Merge Census HH data
		use	"${SNAP_dtInt}/US_population_estimates.dta", clear
		merge	1:1	year	using	"${SNAP_dtInt}/HH_type_census.dta", nogen	assert(3)
		merge	1:1	year	using	"${SNAP_dtInt}/HH_race_census.dta", nogen assert(3)
		merge	1:1	year	using	"${SNAP_dtInt}/HH_age_census.dta", nogen assert(3)
		merge	1:1	year	using	"${SNAP_dtInt}/HH_size_census.dta", nogen assert(3)
		merge	1:1	year	using	"${SNAP_dtInt}/ind_education_CPS.dta", nogen assert(3)
		merge	1:1	year	using	"${SNAP_dtInt}/pov_rate_1979_2019.dta", nogen assert(3)
		save	"${SNAP_dtInt}/HH_census_1979_2019.dta", replace
		}	
		
		
		*	Cost of Living Index (1990-2021)
		{
		import	excel	"${clouldfolder}/DataWork/C2ER/COLI Historical Data - 1990 Q1 - 2022 Annual.xlsx", firstrow sheet(HistoricalIndexData)	clear

			*	Notes on data
			*	Up to 2006, the data has full quarterly value (Q1 to Q4)
			*	Since 2007, the data has Q1-Q3 and annual data (no Q4) , except 2020 which is out of our study period.
			
			
			*	Keep relevant variables only
			keep	YEAR QUARTER STATE_CODE STATE_NAME COMPOSITE_INDEX GROCERY_ITEMS
			
			*	Replace unknown value as missing
			*	There's on observation (1991 Q1 NY Ithaca) where composite index was recorded as "parta". Will replace it as missing.
			replace	GROCERY_ITEMS=""	if	GROCERY_ITEMS=="parta"
			
			*	Destring cost index
			destring	GROCERY_ITEMS, replace
			
			*	Replace quarter with numeric value
			loc	var	svy_quarter
			cap	drop	`var'
			gen		`var'=1	if	QUARTER=="Q1"	//	Variable name to be equal to the one in main data
			replace	`var'=2	if	QUARTER=="Q2"	//	Variable name to be equal to the one in main data
			replace	`var'=3	if	QUARTER=="Q3"	//	Variable name to be equal to the one in main data
			replace	`var'=4	if	QUARTER=="Q4"	//	Variable name to be equal to the one in main data
			replace	`var'=99	if	QUARTER=="Annual"	//	Variable name to be equal to the one in main data
			
			*	Due to different data availability, we keep only "ANNUAL" value since 2007
			drop	if	svy_quarter!=99	&	inrange(YEAR,2007,2020)
			
			*	Adjust 2013 data whose annual average is 96 instead of 100
			replace GROCERY_ITEMS = GROCERY_ITEMS * 100/94.6908 if YEAR==2013
			
			*	Compute state-year-level average value
			collapse	COMPOSITE_INDEX GROCERY_ITEMS, by(YEAR STATE_NAME)
			
			*	Rename variables
			rename	(YEAR STATE_NAME	COMPOSITE_INDEX	GROCERY_ITEMS)	(year	state	COLI_composite	COLI_grocery)
			lab	var	COLI_composite	"COLI - Composite"
			lab	var	COLI_grocery	"COLI - Grocery"
			
			*	merge with statecode, to be merged into the main data
			drop	if	inlist(state,"British Columbia","Puerto Rico","Saskatoon","Virgin Islands")
			replace	state="Washington D.C."	if	state=="District of Columbia"
			merge	m:1	state	using	"${SNAP_dtRaw}/Statecode.dta",	nogen	assert(3)
			
			rename	statecode	rp_state	// rename to be merged with the main data
			
			*	Save
			compress
			save	"${SNAP_dtInt}/COLI.dta", replace
		}
		
		*	CPI data (to convert current to real dollars)
			*	(2023-1-15) Baseline month as Jan 2019 (CPI=100)
		import excel	"${clouldfolder}/DataWork/BLS/CPI_seasonally_adj_201901.xls", cellrange(A12) 	clear

		rename	B CPI
		gen		month=month(A)
		gen 	year=year(A)
		drop	A
		label	var	CPI	"Consumer Price Index (CPI)"

		gen	yearmonth	=	year*100+month
		gen	prev_yrmonth	=	yearmonth	//	This variable will be used to match main data

		save	"${SNAP_dtInt}/CPI_1947_2021",	replace
		
		
		*	SNAP summary (participants, costs, benefits, etc.)
		import excel "${clouldfolder}/DataWork/USDA/DataSets/Raw/SNAPsummary-11.xls", sheet("Sheet1") cellrange(A5)  firstrow clear

		rename	(FiscalYear AverageParticipation C TotalBenefits E TotalCosts)	(year	part_num	avg_benefit_pc	total_benefits	other_costs	total_costs)

		drop in 1
		replace	year="1982" if year=="1982 3]"
		drop if _n>=53
		destring *, replace
		
		replace	part_num	=	part_num/1000 // Convert K to M
		replace	total_costs	=	total_costs/1000 // Convert M to B
		
		lab	var	part_num	 	"Average participation (M)"
		lab	var	avg_benefit_pc 	"Average benefit per capita ($)"
		lab	var	total_benefits	"Total benefits ($ M)"
		lab	var	other_costs		"Other costs ($ M)"
		lab	var	total_costs		"Total costs ($ B)"
		
		save	"${SNAP_dtInt}/SNAP_summary",	replace
		
		*	SNAP state-level participation rates
		import	excel	"${clouldfolder}/Datawork/USDA/DataSets/Raw/SNAP-state-participation-rates.xlsx", firstrow sheet(2015_2019) clear
		
			rename	A	state
			*rename	
			*drop	if	inlist(state,"Virgin Islands","Guam")
			replace	state="Washington D.C." if state=="District of Columbia"
			*gen	year=2019
			
			
			/*
			recast	double	partrate_all partrate_wkpoor	partrate_elderly
			foreach	var	in	partrate_all partrate_wkpoor	partrate_elderly	{
				
				replace	`var'	=	`var'/100
				
			}
			*/
			reshape	long	all	WP, i(state) j(year)
			
			*	Merge with state-level polictis data
			merge	1:1	state	year	using	"${SNAP_dtInt}/State_politics", nogen assert(2 3)
			
			summ	all	if	major_control_dem==1
			summ	all	if	major_control_rep==1
			summ	all	if	major_control_mix==1
			
			summ	all	if	major_control_dem==1	&	year==2019
			summ	all	if	major_control_rep==1	&	year==2019
			summ	all	if	major_control_mix==1	&	year==2019
			
		save	"${SNAP_dtInt}/State_participation_rates",	replace	

			*	Statewide
			
				*	Annual
				import excel "${clouldfolder}/DataWork/BLS/Unemp_rate_state_annual.xlsx", sheet("BLS Data Series")  firstrow clear	cellrange(B4)
				rename	State state
				drop	if	mi(state)
				replace	state="Washington D.C." if state=="District of Columbia"
								
				reshape	long	Annual, i(state) j(year)
				rename	Annual	unemp_rate_annual
				lab	var	unemp_rate_annual "State Unemployment Rate (annual)"
			
				merge	m:1	state using "${SNAP_dtRaw}/Statecode.dta", assert(3) nogen	//	Merge statecode
				rename	statecode rp_state
				
				save	"${SNAP_dtInt}/Unemployment Rate_state_annual",	replace
				
				*	Monthly
				import excel "${clouldfolder}/DataWork/BLS/Unemp_rate_state_month.xlsx", sheet("BLS Data Series")  firstrow clear	cellrange(B4)
				rename State state
				replace	state="Washington D.C." if state=="District of Columbia"
				
				reshape	long	Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec, i(state) j(year)
				
				rename	(Jan-Dec) unemp_rate#, addnumber
				reshape	long	unemp_rate, i(state year) j(month)
				
				lab	var	unemp_rate	"State Unemployment Rate (monthly)"
			
				merge	m:1	state using "${SNAP_dtRaw}/Statecode.dta", assert(3) nogen	//	Merge statecode
				rename	statecode rp_state

				
				*	Create year-month variable to be merged with main data
				gen	yearmonth	=	year*100+month
				gen	prev_yrmonth	=	yearmonth	//	This variable will be used to match main data
				
				save	"${SNAP_dtInt}/Unemployment Rate_state_month",	replace		
		
		*	Poverty Guildeline (which determines SNAP income eligibility)
			import excel "${clouldfolder}/DataWork/ASPE/historical-poverty-guidelines.xlsx", sheet("48_Contiguous States--Nonfarm") cellrange(A4:N61) firstrow clear

			rename	Year year
			drop	if	!inrange(year,1977,2019)

			rename	(Person-J)	pov_threshold#, addnumber

			forval	famnum=9/16	{
				
				gen	pov_threshold`famnum'	=	pov_threshold8	+	(`famnum'-8)*Additional
					
			}

			order	pov_threshold*, after(year)
			keep	year	pov_threshold*

			reshape	long	pov_threshold, i(year) j(famnum)

			lab	var	pov_threshold	"Poverty Threshold (annual family income)"
			
			save	"${SNAP_dtInt}/Poverty_guideline", replace
		
		
		*	SNAP payment error rate (1980-2019)

			forval	year=1983/2019		{
		
				import excel "${clouldfolder}/DataWork/USDA/Error Rates/Error_Rates.xlsx", sheet("FY`year'") firstrow clear
				
				rename	(StateTerritory OverPayments UnderPayments PaymentErrorRates)	(state	error_over	error_under	error_total)
				gen	year	=	`year'
				
				tempfile	error_rate_`year'
				save		`error_rate_`year''
				
			}
	

			foreach	year	in	1980	1981	1982	{
				
				import excel "${clouldfolder}/DataWork/USDA/Error Rates/Error_Rates.xlsx", sheet("FY`year'") firstrow clear

				drop	*_H1	*_H2
				rename	(State Overpayments Underpayments PaymentErrorRates)	(state	error_over	error_under	error_total)
				gen	year	=	`year'

				tempfile	error_rate_`year'
				save		`error_rate_`year''
				
			}


			use	`error_rate_1980',	clear
			forval	year=1981/2019	{
				
				di "year is `year'"
				append	using	`error_rate_`year''
				
			}

			replace	state	=	strproper(state)
			replace	state	=	stritrim(state)
			replace	state	=	strtrim(state) 
			
			replace	state	=	"Washington D.C." 	if regexm(state,"Dist")
			replace	state	=	"Indiana"			if regexm(state,"Indiana")	
			replace	state	=	"National Average"	if	inlist(state,"U.S. Average","Total")
			
			lab	var	error_over 	"Overpayment Rate"
			lab	var	error_under "Underpayment Rate"
			lab	var	error_total	"Payment Error Rate"
			
			
			*	Make national error data
			preserve
				keep	if	state=="National Average"
				rename	(error_over	error_under	error_total)	(error_over_ntl	error_under_ntl	error_total_ntl)
				lab	var	error_over_ntl	"Overpayment rate (national)"
				lab	var	error_under_ntl	"Underpayment rate (national)"
				lab	var	error_total_ntl	"Payment Error rate (national)"
				drop	state
				save	"${SNAP_dtInt}/Payment_Error_Rates_ntl", replace
			restore
			
			*	Make state error data
			drop	if	inlist(state,"National Average","Virgin Islands","Guam")
			drop	if	mi(state)
				
				*	Merge statecode
				merge	m:1	state using "${SNAP_dtRaw}/Statecode.dta", assert(3) nogen
				rename	statecode	rp_state
		
			*	Save (state-error rate)
			save	"${SNAP_dtInt}/Payment_Error_Rates", replace

		
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
			use	"${SNAP_dtInt}/TFP cost/TFP_1978", clear
			
			foreach year	of	global	sample_years	{
				
				if	`year'==1978 continue
				append	using	"${SNAP_dtInt}/TFP cost/TFP_`year'"
			
			}
			
			isid year gender age_ind svy_month
			drop	if	year<1977
			save	"${SNAP_dtInt}/TFP cost/TFP_costs_all", replace
			
		use		"${SNAP_dtInt}/TFP cost/TFP_costs_all", clear
		*	Income Poverty from Poverty Guideline (which determines income eligibility)
		*	(Source: HHS Poverty Guideline, https://aspe.hhs.gov/topics/poverty-economic-mobility/poverty-guidelines/prior-hhs-poverty-guidelines-federal-register-references)
		*	Note: I only import poverty line of 48 continental states. I do not import Alaska/Hawaii as they will be excluded from my paper.
		
		import	excel	"${clouldfolder}/DataWork/ASPE/historical-poverty-guidelines.xlsx", sheet("48_Contiguous States--Nonfarm") cellrange(A4) firstrow clear
		drop	Date* L Federal* HTML*

		rename	(Person-J)	incomePL(#), addnumber

		forval	i=9/16	{
			
			local	j=`i'-8
			gen	incomePL`i'	=	incomePL8	+	(Additional	*	`j')
			
		}

		drop	Additional

		rename	Year year
		keep	if	inrange(year,1978,2019)

		reshape	long	incomePL, i(year) j(famnum)
		lab	var	famnum		"Family size"
		lab	var	incomePL	"Income Poverty Line"

		save	"${SNAP_dtInt}/incomePL", replace				
	}
	
	/****************************************************************
		SECTION 3: Construct PSID panel data and import external data
	****************************************************************/	
	
	*	Create panel structure
	if	`cr_panel'==1	{
		
		*	Create a panel structre
		*	This study covers 50-year period with different family composition changes, thus we need to carefully consider that.
		*	Basically we will track the two different types of families
			*	(1) Families that initially existed in 1977 (first year of the study)
			*	(2) Families that split-off from the original families (1st category)
		*	Also, we define family over time as the same family as long as the same individual remain either RP or spouse.
		
		*	First, we create a individual-level aggregated data using "psid use command" with necessary variables to further investigate family change.
			
	
			
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
		
		*	Temporary code observing the number of individuals with different family composition status
		
		local	status_chage_over_time=0	//	disable by default, but need it for in-text numbers
		if		`status_chage_over_time'==1	{
			preserve
				drop *_1968	*_1969	*_1970	*_1971	*_1972	*_1973	*_1974	*_1975	*_1976

				egen	count_seq_7719			=	anycount(xsqnr_1977-xsqnr_2019), values(1,2,3,4,5,6,7,8,9,10,11,12,13,14,15,16,17,18,19,20) //	# of waves an individual in HH (seq b/w 1 to 20)
				egen	count_RP_7719			=	anycount(xsqnr_1977-xsqnr_2019), values(1)	//	# of waves an indivdiual being RP
				egen	count_nochange_7719		=	anycount(change_famcomp1978-change_famcomp2019), values(0)	//	# of waves without any family comp change
				egen	count_sameRP_7719		=	anycount(change_famcomp1978-change_famcomp2019), values(0,1,2) // # of waves with the same RP
				
				drop	if	count_seq_7719==0	//	Drop individuals that never appeared during the study period
				
				count	if	xsqnr_1977==1	//	# of ppl that are RP in 1977
				tab	count_RP_7719	if	xsqnr_1977==1, matcell(temp)	//	# of waves an individual is RP over the study wave. only 11% of them are RP over the entire study period.
				scalar	share_rp_7719	=	temp[32,1] / r(N)
				di	"Share of individuals being RP over 1977-2019 is" share_rp_7719
				tab count_seq_7719	//	2,726 ppl appeared in all 32 waves (1977 to 2019)
				count if count_seq_7719==count_sameRP_7719
			restore
		}
		
				
		*	Drop years outside study sample	
			drop	*1973	*1988	*1989	//	Years without food expenditures (1973, 1988, 1989)
			drop	*1968	*1969	*1970	*1971	//	Years which I cannot separate FS amount from food expenditure
			drop	*1972	*1974	//	Years without previous FS status
			drop	*1975	*1976	//	Years without exogenous IV data and discontinuous food exp
		
				
		*	Set globals
		*	Here we include 1977 variables, as we want to consider the conditions of 1977 as well.
		qui	ds	x11102_1977-x11102_2019
		global	hhid_all_1977	`r(varlist)'
		
		qui	ds	xsqnr_1977-xsqnr_2019
		global	seqnum_all_1977	`r(varlist)'
		
		
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
			
			foreach	year	of	global	sample_years_1977	{
						
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
			foreach	year	of	global	sample_years_1977	{
				
				cap	drop	x11102_`year'_str	relrp_recode`year'_str
				tostring	x11102_`year',	gen(x11102_`year'_str)
				decode 		relrp_recode`year', gen(relrp_recode`year'_str)
				
			}
			
			*	Generate residential status variable
			loc	var	resid_status
			lab	define	resid_status	0	"Inapp"	1	"Resides"	2	"Institution"	3	"Moved Out"	4	"Died", replace
			foreach	year	of	global	sample_years_1977	{
			
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
			foreach	year	of	global	sample_years_1977	{
			
				cap	drop	status_combined`year'
				gen		status_combined`year'	=	x11102_`year'_str + "_" + relrp_recode`year'_str	+	"_"	+	resid_status`year'_str
				label	var	status_combined`year'	"Combined status in `year'"
			}
			
			*	Tag only the individuals that appear at least once during the study period (1977-2019)
			*	I do this by counting the number of sequence variables with non-zero values (zero value in sequence number means inappropriate (not surveyed)
			*	This code is updated as of 2022-3-21. Previously I used the number of missing household IDs, as below.
			loc	var	zero_seq_7719
			cap	drop	`var'
			cap	drop	count_seq_7719
			egen	count_seq_7719	=	anycount(xsqnr_1977-xsqnr_2019), values(0)	//	 Counts the number of sequence variables with zero values
			gen		`var'=0
			replace	`var'=1	if	count_seq_7719==30
			*drop	if	`var'==1	//	Drop individuals who have zero values across all sequence variables
			drop	count_seq_7719
			
			
			*	Individuals who were RP in 1977
			*	These individuals form families that existed in 1977, which I define as "baseline family"
			*	RP should satisfy two conditions; (1) sequence number is 1 (2) relation to head is him/herself
			loc	var	rp1977
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	xsqnr_1977==1	&	relrp1977==1
			lab	var	`var'	"=1 if RP in 1977"
			tab	`var'
			
			*	Individuals who were spouse/partner in 1977
			loc	var	sp1977
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	inrange(xsqnr_1977,1,20)	&	relrp_recode1977==2
			lab	var	`var'	"=1 if SP in 1977"
			
			*	Combine the two indicators above to find individuals who were RP or spouse in 1977
			*	They are the people who represent their family units.
			*	For families that have both RP and SP (ex. married), we treat both individuals representing their own families, but adjust their weight such that the summ of (family) weights they represent being equal to the (family) weight they actually belong to.
			loc	var	rpsp1977
			cap	drop	`var'
			gen	`var'=0
			replace	`var'=1	if	inlist(1,rp1977,sp1977)
			label	var	`var'	"=1 if RP/SP in 1977"
			
			tab	rp1977	sp1977	//	6,007 individuals who were RP in 1977
			distinct	x11102_1977	if	rpsp1977==1	//	6,007 families, which verifies the result above.
		
			*	Individuals that were child/grandchild in 1977
			*	Note that this variable does NOT capture children who were born after 1977 (they are coded as inapp)
			loc	var	ch1977
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	inrange(xsqnr_1977,1,20)	&	inlist(relrp_recode1977,3,6)
			lab	var	`var'	"=1 if child/grandchild in 1977"
			
			*	Inappropriate in 1977
			loc	var	inapp1977
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	xsqnr_1977==0 // Seq number is 0 (inapp) if and only if relation to RP is inapp. So we can use only one condition
			lab	var	`var'	"=1 if inapp in 1977"
			
			*	Combine two indicators above to create "child or inapp in 1977"
			*	We will use this indicator to determine split-off families.
			loc	var	chinapp1977
			cap	drop	`var'
			gen	`var'=0
			replace	`var'=1	if	inlist(1,ch1977,inapp1977)
			label	var	`var'	"=1 if Ch/inapp in 1977"
			
			
			*	Individuals that were either RP or spouse only during the entire study period when residing
			*	These information can be combined with "RP/SP in 1977" variable to detect "same baseline family over time"
			*	IMPORANT: Unlike checking whether an individual is RP or not, this information does NOT need to satisfy sequence number condition, but relation to RP only.
			*	It is because our sample is inevitably unbalanced since it spans over 40 years, thus it is OK for individuals to have sequence number OTHER THAN 1.
			*	Here's an example. Suppose an individual who was RP in 1978 no longer resides in 1979. This individual has "relation to RP" as "him/herself" as his last status was RP, but sequence number is not equal to 1. (81 if died, 0 if moved out/refused, etc.)
			*	As long as this individual is neither RP nor spouse, this person remained as RP or spouse of RP (so it is still the same household)
			*	If a spouse takes over RP position, this family should still treated as the same family.
			*	If someone else (ex. child) takes over RP position, this family is no longer treated as the same family.
			loc	var		rpsp7719
			cap	drop	`var'
			cap	drop	count_relrp7719
			egen	count_relrp7719	=	anycount(relrp_recode1977-relrp_recode2019), values(0 1 2)
			gen		`var'=0
			replace	`var'=1	if	count_relrp7719==30	//	Those who satisfy relation condition; RP or SP (residing) or inapp (not residing) across all waves
			lab	var	`var'	"=1 if RP/SP over study period"
			drop	count_relrp7719	
			
			*	RP/SP at least in one wave
			*	This indicator is based on Chris' suggestion where he suggested to include ALL individuals who were RP/SP at least once.
			*	It allows to capture many individuals we drop from earlier criteria, including "those who later become a parent" and "those who first split-off as sibling and later become RP/SP
			loc	var		rpsponce7719
			cap	drop	`var'
			cap	drop	count_relrp7719
			egen	count_relrp7719	=	anycount(relrp_recode1977-relrp_recode2019), values(1 2)
			gen		`var'=0
			replace	`var'=1	if	count_relrp7719>=1	//	At least having child/grandchild status in one wave
			lab	var	`var'	"=1 if RP/SP at least in one year"
			drop	count_relrp7719	
						
			*	Now we can determine baseline individuals who represent same baseline family over time.
			*	Baseline individuals; (1) RP/SP in 1977, and (2) RP or SP at least once.
			loc	var	baseline_indiv
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	rpsp1977==1	&	rpsponce7719==1
			label	var	`var'	"=1 if baseline individual"
			
			tab	baseline_indiv	//	8,756 individuals
			distinct	x11102_1977	if	baseline_indiv==1	
			
			*	We currently have 9,558 baseline individuals living in 6,007 families in 1977 which remained same over time under our definition
			*	(Final size will be smaller once we exclude non-Sample individuals)
			*	We treat each individuals as each family. Say, we have 9,175 families. To fill in this gap, we adjust the weight.
			
			*	Now we move to the second type of family; split-off family formed by children after 1977
				*	Both children who were living in 1977 as well as born after 1977
			*	Like baseline family, individuals who represent split-off family should satisfy the followings
				*	(1)	Children/grandchild or inapp in 1977 (to exclude baseline individuals; avoid duplicate counting)
				*	(2) Children/grandchild at least in one wave
				*	(3) RP/SP at least in one wave (to exclude those who never had a family they represent)
					*---	(4) Status no other than Ch/RP/SP while residing (to exclude those who do not represent SAME family over time)	--- // Removed this condition as of 2022/3/30
					
			*	Children at least in one wave
			loc	var		chonce7719
			cap	drop	`var'
			cap	drop	count_relrp7519
			egen	count_relrp7719	=	anycount(relrp_recode1977-relrp_recode2019), values(3 6)
			gen		`var'=0
			replace	`var'=1	if	count_relrp7719>=1	//	At least having child/grandchild status in one wave
			lab	var	`var'	"=1 if child at least in one year"
			drop	count_relrp7719	
	
			*	With the indicators constructed above, now we can determine individuals that represent split-off families.
			*	As of 2022/4/2, we have 11,126 split-off individuals
			loc	var	splitoff_indiv
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	chinapp1977==1	&	chonce7719==1	&	rpsponce7719==1	
			label	var	`var'	"=1 if split-off individual"
			
			tab	splitoff_indiv	//	10,281 individuals
			tab baseline_indiv splitoff_indiv
			
			*	Baseline or split-off individuals
			loc	var	bs_splitoff_indiv
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	inlist(1,baseline_indiv,splitoff_indiv)
			label	var	`var'	"=1 if baseline or split-off individual"
				
			/*
			*	Those who have ever been RP
			*	IMPORTANT: we no longer use "rp_any" as our sample condition, as there are individuals who represent family as spouse without being RP.
			*	We just create it as a reference
			cap	drop	rp_any
			egen	rp_any=anymatch(${seqnum_all_1975}), values(1)	//	Indicator if indiv was head/RP at least once.
			*drop	if	rp_any!=1
			label	var	rp_any "=1 if RP in any period"
			*drop	rp_any
			*/
	
		*	Now we keep only relevant observations.
			
		*	Drop Latino sample and 2017 immigrant refresher
			drop	if	sample_source==5	//	Latino sample
			drop	if	sample_source==4	//	2017 refresher
			
		*	Drop those who never appeared during the study period
			drop	if	zero_seq_7719==1
		
			*	Generate a household id which uniquely identifies a combination of household wave IDs.
			**	Note: This is a tepmorary variable where it would have duplicate household ids after applying family panel structure (this is why I named this variabe as "1st")
			cap drop hhid_agg_1st	
			egen hhid_agg_1st = group(x11102_1977-x11102_2019), missing	

		
		*	Tag in-sample	(18,277 HH as of 2023-1-14)
			loc	var	in_sample
			cap	drop	`var'
			gen		`var'=0
			replace	`var'=1	if	Sample==1	&	inlist(1,baseline_indiv,splitoff_indiv)
			label	var	`var'	"=1 if in study sample"
			
		*	Keep relevant study dample only (baseline & splitoff invidiuals, PSID-follable individuals)
			keep	if	in_sample==1
						
		*	Overview of sample
		if	`panel_view'==1	{		
		
			duplicates tag hhid_agg_1st /*if in_sample==1*/, gen(dup)
			tab	dup	//	92.0% of individuals have unique series of family ID over time. Rest of them include: RP and spouse, RP and child, etc.
			drop	dup	
			
			*	This code is to see what individuals have changed the status 
			*	Browsing relevant variables
			sort	x11102_1977	xsqnr_1977
			
			loc	startyear	1977
			loc	endyear		2019
			
			loc	browsevars
			
			foreach	year	of	global	sample_years_1975	{
				
				loc	browsevars	`browsevars'		status_combined`year'	age_ind`year'	noresp_why`year'
				
			}
			
			global	browsevars	`browsevars'	
			
			order	x11101ll	gender	hhid_agg_1st	rpsp1975 chinapp1975 rpsp7519 chonce7519 rpsponce7519  baseline_indiv splitoff_indiv bs_splitoff_indiv Sample in_sample	${browsevars}
			br		x11101ll	gender	hhid_agg_1st	rpsp1975 chinapp1975 rpsp7519 chonce7519 rpsponce7519  baseline_indiv splitoff_indiv bs_splitoff_indiv Sample in_sample	${browsevars} if x11102_1976==488
			
			sort x11101ll
			
			loc	year	1976
			sort	x11102_`year'	xsqnr_`year'
			
			export excel	x11101ll	gender	hhid_agg_1st	rpsp1975 chinapp1975 rpsp7519 chonce7519 rpsponce7519  baseline_indiv splitoff_indiv bs_splitoff_indiv Sample in_sample	${browsevars}	using "${SNAP_dtInt}\family_status_v4.xlsx"	if	x11102_1976==488,  firstrow(variables)	replace
		
		}
		
	
		*	Third, we adjust individual and family weight by the number of valid individuals in each wave
		*	If there are multiple Sample individuals who has ever been an RP within a family at certain wave, their family variables will be counted multiple times (duplicate)
		*	Thus we need to divide the weight by the number of Sample individuals who were living in a family unit 
		*	(2023-1-16) The choice between using adjusted individual- and adjusted family- weight for the analyses is an issue. I use FAMILY weight for the following reason
			*	(1) family weight is the average of the weights for all family unit members, including sample and non-sample. So dividing either wave by the number of individuals within the family would be the same.
				*	(https://www.youtube.com/watch?v=OMbXTnl18JI)
				*	Say, there are 3 individuals in the family - 2 Sample members with individual weight 3 and 6, and 1 non-Sample members. Then family weight would be 3 (3+6+0/3)
					*	If we divide the family weight by the number of Sample individuals in the sample, it would be 1.5 (3/1.5) for each individuals.
					*	If we divide the individual weight by the number of Sample individuals, it would be 1.5 (3/2), 0 (0/2), and 3 (6/2) for each individual (each individual weight divided by 2)
			*	(2) Since food expenditure is family-level indicator, we want the total adjusted-individual weight within family in our regression being equal to the family weight, so it can properly represent the original family weight.
				*	In our study sample, only Sample members are included.
					*	If we use adjusted-family weight, the total weight would be 3 (1.5 + 1.5), which is equal to the original family weight (3)
					*	If we use adjusted-individual unit, the total weight would be 4.5 (1.5 + 3), which is greater than the original family weight (3)
			*	Therefore, we use adjusted "FAMILY" weight in our regression
					
		
			cap	drop	living_Sample*
			cap	drop	tot_living_Sample*
			cap	drop	tot_living_Sample*
			cap	drop	wgt_long_ind_adj&
			cap	drop	wgt_long_fam_adj*
			
		
			foreach	year	of	global	sample_years_1977	{
				
				cap	drop	living_Sample`year'				
					
				*	Use sequence number
				gen		living_Sample`year'=1	if	inrange(xsqnr_`year',1,20)

				*	Count the number of Sample members living in FU in each wave
				bys	x11102_`year':	egen	tot_living_Sample`year'=count(living_Sample`year')
				
				*	Divide individual and family weight in each wave by the number of Sample members living in FU in each wave
				gen	wgt_long_ind_adj`year'	=	wgt_long_ind`year'	/	tot_living_Sample`year'
				gen	wgt_long_fam_adj`year'	=	wgt_long_fam`year'	/	tot_living_Sample`year'
				
			}
				
		*	(2022-4-2) Let's disable this code for now. We can make comprehensive criteria for observations to be dropped
		/*
		*	Drop FUs which were observed only once, as it does not provide sufficient information.
		egen	fu_nonmiss=rownonmiss(${hhid_all})
		label variable	fu_nonmiss	"Number of non-missing survey period as head/PR"
		drop	if	fu_nonmiss==1	//	Drop if there's only 1 observation per household.
		*/
		
		*	Generate the final household id which uniquely identifies a combination of household wave IDs.
		*egen hhid_agg = group(x11102_1968-x11102_2019), missing	//	This variable is no longer needed. Can bring it back if needed.
		drop	hhid_agg_1st
		drop	x11102_*_str	relrp_recode*_str	resid_status*_str relrp????
				
		*	Save
			
			*	Wide-format
			order	pn sampstr sampcls gender sampstat Sample	zero_seq_7719 rp1977 sp1977 rpsp1977 ch1977 inapp1977 chinapp1977 rpsp7719 rpsponce7719 baseline_indiv chonce7719 splitoff_indiv bs_splitoff_indiv in_sample ,	after(x11101ll)
			save	"${SNAP_dtInt}/Ind_vars/ID_sample_wide.dta", replace
		
			*	Re-shape it into long format and save it
			use	"${SNAP_dtInt}/Ind_vars/ID_sample_wide.dta", clear
			reshape long	x11102_	xsqnr_	wgt_long_ind	wgt_long_fam	wgt_long_fam_adj	wgt_long_ind_adj	living_Sample tot_living_Sample	///
							age_ind relrp_recode resid_status status_combined origfu_id noresp_why 	change_famcomp splitoff	/*${varlist_ind}	${varlist_fam}*/, i(x11101ll) j(year)
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
			label	var	change_famcomp		"Change in family composition"
			label	var	splitoff		"Splitoff status"
			
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
			**	(2022-3-13) This code is added, as somehow existing code did not run properly ("age_ind" variable, which is required to merge with TFP cost data, didn't exist). We can see later what the problem is.
			cd "${SNAP_dtInt}/Ind_vars"
			
			global	varlist_ind	age_ind	/*wgt_long_ind	relrp*/	origfu_id	noresp_why	ind_edu	ind_health	ind_employed
			
			foreach	var	of	global	varlist_ind	{
				
				merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(2 3)	keep(3)	//	Longitudinal weight
					
			}
			
			dir "${SNAP_dtInt}/Fam_vars/"
								
			*	Merge family variables
			*	(2022-3-13) Instead of manually entering variables, I use "dir" command to load all variables in "Fam" folder.
			cd "${SNAP_dtInt}/Fam_vars"
			local fam_files : dir "${SNAP_dtInt}/Fam_vars" files "*.dta", respectcase	//	"respectcase" preserves upper case when upper case is included
			
			
			global	varlist_fam		//	Make a list of family variables (to be used in "reshape" command later. Initiate the global with blank entry)
			foreach	filename	of	local	fam_files	{

				di	"current filename is `filename'"
				loc	varname	=	subinstr("`filename'",".dta","",.)
				
				di "current varname is `varname'"			
				merge 1:1 x11101ll using "`varname'", keepusing(`varname'*) nogen assert(2 3)	keep(3)	
				global	varlist_fam	${varlist_fam}	`varname'
				
			}
						
			/*	Outdated as of 2022-3-13
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
								foodexp_home_annual	foodexp_home_grown	foodexp_home_nostamp	foodexp_home_nostamp_recall	foodexp_home_spent_extra	///
								foodexp_home_stamp	foodexp_home_stamp_recall	foodexp_home_wth_stamp_incl	foodexp_home_imputed	///	/* At-home food exp */	///
								foodexp_away_cat	foodexp_away_annual	foodexp_away_stamp	foodexp_away_stamp_recall	foodexp_away_nostamp	foodexp_away_nostamp_recall	foodexp_away_imputed	///	/*	Away food expenditure	*/
								foodexp_atwork	foodexp_atwork_saved	///	/*	At work food expenditure	*/
								foodexp_deliv_nostamp_wth	foodexp_deliv_nostamp	foodexp_deliv_nostamp_recall	foodexp_deliv_stamp_wth	foodexp_deliv_stamp	foodexp_deliv_stamp_recall	///	/*	devliered food expenditure	*/
								foodexp_tot_imputed	/*	total (imputed) food expenditure	*/
		
			foreach	var	of	global	varlist_fam	{
				
				di	"current var is `var'"
				merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(2 3)	keep(3)	
				
			}
			*/
						
			*	Save (wide-format)	
			*order	hhid_agg,	before(x11101ll)
			*order	pn-fu_nonmiss,	after(x11101ll)
			save	"${SNAP_dtInt}/SNAP_RawMerged_wide",	replace
			
			*	Re-shape it into long format	
			use	"${SNAP_dtInt}/SNAP_RawMerged_wide",	clear
			reshape long x11102_	xsqnr_	wgt_long_ind	/*wgt_long_fam*/	wgt_long_ind_adj	wgt_long_fam_adj	living_Sample tot_living_Sample	///
										${varlist_ind}	${varlist_fam}, i(x11101ll) j(year)
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
			*label 	var	relrp		"Relation to RP"	//	This variable will be imported from ID sample data.
			label	var	origfu_id	"Original FU ID splitted from"
			label	var	noresp_why	"Reason for non-response"
			label	var	splitoff	"(raw) Split-off status"
			label	var	rp_gender	"Gender of RP"

			save	"${SNAP_dtInt}/SNAP_RawMerged_long",	replace
	
			*	Appending extra variables 
			**	Disabled by default. Run this code only when you have extra variable to append from the raw PSID data.
			/*
			{
				local	var	why_no_FSP
				cd "${SNAP_dtInt}/Fam_vars"
				
					*	Wide
					use	"${SNAP_dtInt}/SNAP_RawMerged_wide",	clear
					merge 1:1 x11101ll using "`var'", keepusing(`var'*) nogen assert(3)
					save	"${SNAP_dtInt}/SNAP_RawMerged_wide",	replace
					
					*	Long
					use	"`var'", clear
					reshape	long `var', i(x11101ll) j(year)
					tempfile	`var'_ln
					save	``var'_ln'
					
					use	"${SNAP_dtInt}/SNAP_RawMerged_long", clear
					merge	1:1		x11101ll	year	using	``var'_ln',	keepusing(`var'*)	nogen	assert(1 3)
					save	"${SNAP_dtInt}/SNAP_RawMerged_long",	replace
			}
			*/
			
		
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
				gen	`var'_pc	=	(`var'/famnum)
				gen	`var'_pc_th	=	((`var'/famnum)/1000)
				
				label	var	`var'		"Total monthly TFP cost"
				label	var	`var'_pc	"Total monthly TFP cost per capita"
				label	var	`var'_pc_th	"Total monthly TFP cost per capita (K)"
		
			*	Save
			save	"${SNAP_dtInt}/SNAP_ExtMerged_long",	replace
		
		}	//	add_clean
		
		if	`import_dta'==1	{
		    				
			use	"${SNAP_dtInt}/Ind_vars/ID_sample_long.dta",	clear
				*	Added 2022-3-13
				*	Some variables will be used to construct panel data later (ex. relation to HH, indiv age).
				*	As of 2022-3-13, they remain in ID data without being used, so drop them here and let it be merged from "SNAP_ExtMerged_long.dta" This code can be modified later
				*drop	age_ind???? relrp???? origfu_id???? noresp_why????
				//drop	age_ind origfu_id noresp_why
			merge	1:1	x11101ll	year	using "${SNAP_dtInt}/SNAP_ExtMerged_long", nogen assert(2 3) keep(3) 	
								
			*	SSI data
			merge	m:1	rp_state year	using	"${SNAP_dtInt}/SSI", nogen keep(1 3) // keepusing(genexp-SSI)
			
			*	State Politics data
			merge m:1 rp_state year using "${SNAP_dtInt}/State_politics", nogen keep(1 3) keepusing(major_control_dem major_control_rep major_control_mix)
			
			*	Import SNAP policy data
			*merge m:1 rp_state prev_yrmonth using "${SNAP_dtInt}/SNAP_policy_data", nogen keep(1 3)
			merge m:1 rp_state year using "${SNAP_dtInt}/SNAP_policy_data_official", nogen keep(1 3) // keepusing(SNAP_index_off_uw	SNAP_index_off_w)
			
			*	Import census data
			merge	m:1	year	using	"${SNAP_dtInt}/HH_census_1979_2019.dta", nogen keep(1 3) ///
				keepusing(pct_rp_female_Census  pct_rp_nonWhite_Census HH_age_median_Census_int pct_HH_age_below_30_Census HH_size_avg_Census pct_col_Census pov_rate_national	US_est_pop)
			
			*	Imnport state-wide annual unemployment data
			merge m:1 rp_state year using "${SNAP_dtInt}/Unemployment Rate_state_annual", nogen keep(1 3) keepusing(unemp_rate_annual)	
			
			*	Import state-wide monthly unemployment data
			merge m:1 rp_state prev_yrmonth using "${SNAP_dtInt}/Unemployment Rate_state_month", nogen keep(1 3) keepusing(unemp_rate)
			
			*	Import COLI data
			merge m:1	rp_state	year	using	"${SNAP_dtInt}/COLI", nogen keep(1 3)
			
			*	Import Poverty guideline data
			merge	m:1	year	famnum	using	"${SNAP_dtInt}/Poverty_guideline",	nogen	keep(1 3)
			
			*	Import Payment Error Rate
				merge	m:1	year	rp_state	using	 "${SNAP_dtInt}/Payment_Error_Rates", nogen	keep(1 3)	//	State
				merge	m:1	year	using	 "${SNAP_dtInt}/Payment_Error_Rates_ntl", nogen	keep(1 3)	//	State
			
			*	Import CPI data
			merge	m:1	prev_yrmonth	using	"${SNAP_dtInt}/CPI_1947_2021", 	keep(1 3) keepusing(CPI)
			
				*	Validate merge
				local	zero_seqnum	seqnum==0
				local	invalid_mth	svy_month==0
				
				assert	`zero_seqnum'	|	`invalid_mth'	if	_merge==1
				drop	_merge
				
			
			*	Import income poverty line
			merge	m:1	year famnum	using	"${SNAP_dtInt}/incomePL", nogen keep(1 3)
			
			*	Import SNAP summary data
			merge	m:1	year using	"${SNAP_dtInt}/SNAP_summary", nogen keep(1 3)
			
			*	Import	state and government ideology data
			merge	m:1	year	rp_state	using	"${SNAP_dtInt}/citizen_government_ideology", /*gen(merge2)*/ nogen keep(1 3) keepusing(citi6016 inst6017_nom)
			
			
			compress
			save	"${SNAP_dtInt}/SNAP_Merged_long",	replace
			use "${SNAP_dtInt}/SNAP_Merged_long", clear
		}
		
	}	//	merge_data
	
	
	/****************************************************************
		SECTION 4: Clean data and save it
	****************************************************************/	
	
	*	Clean variables
	if	`clean_vars'==1	{
		
		use	"${SNAP_dtInt}/SNAP_Merged_long",	clear
					
			*	Survey year dummies
			tab	year, gen(year_enum)
			
			*	RP changed since the last survey
				*	No change: No change at all (0), change other than RP/SP (1), SP changed (2)
				*	I include Other (8) as "change in RP", as they include some major changes including recontact adn recombined families where RP is changed very often.
				*	I also include "Neither RP nor SP are Sample, and neither of them was RP or SP last year" as "change in RP", since it seems those who were NOT RP (or SP) became RP or SP this year (thus change in RP). A very rough assumption.
			loc	var	change_RP
			cap	drop	`var'
			gen		`var'	=.
			replace	`var'	=	0	if	inlist(change_famcomp,0,1,2)			//	No change at all (0), change other than RP/SP (1), SP changed (2), neither RP nor SP are Sample
			replace	`var'	=	1	if	inlist(change_famcomp,3,4,5,6,7,8,9)	//	I tag "other" as "change in RP", as they include some major changes including recontact adn recombined families where RP is changed very often.
			label	value	`var'	yes1no0
			lab	var	`var'	"=1 if RP changed"
			
			*	Split-off since the last survey
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
			loc	var	rp_age_sq
			cap	drop	`var'
			gen	`var'	=	(rp_age*rp_age)/1000
			lab	var	rp_age_sq	"Age(RP)$^2$/1000"
			
			
				*	RP age group (to compare with the Census data)
			
				*	Below 30.
				loc	var	rp_age_below30
				cap	drop	var
				gen		`var'=.
				replace	`var'=0	if	!mi(rp_age)	&	!inrange(rp_age,1,29)
				replace	`var'=1	if	!mi(rp_age)	&	inrange(rp_age,1,29)
				lab	var	`var'	"RP age below 30"
				
				*	Over 65
				loc	var	rp_age_over65
				cap	drop	var
				gen		`var'=.
				replace	`var'=0	if	!mi(rp_age)	&	!inrange(rp_age,66,120)
				replace	`var'=1	if	!mi(rp_age)	&	inrange(rp_age,66,120)
				lab	var	`var'	"RP age over 65"
				
				
		*	Individual age squared
		loc	var		age_ind_sq
		cap	drop	`var'
		gen	`var'	=	(age_ind)^2
		lab	var	`var'	"Age squared (Ind)"
		
			
		
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
			
			
			*	RP
			loc	var	rp_White
			cap	drop	`var'
			gen		`var'=0	if	inrange(rp_race,2,9)	//	Black, Asian, Native American, etc.
			replace	`var'=1	if	rp_race==1 // White
			label	value	`var'	yes1no0
			label	var		`var'	"White (RP)"
			
			local	var	rp_nonWhte
			cap	drop	`var'
			gen		`var'=rp_White
			recode	`var'	(1=0) (0=1) 
			label	value	`var'	yes1no0
			label	var		`var'	"non-White (RP)"
			
			*	Spouse
			loc	var	sp_White
			cap	drop	`var'
			gen		`var'=0	if	inrange(sp_race,2,9)	//	Black, Asian, Native American, etc.
			replace	`var'=1	if	sp_race==1 // White
			label	value	`var'	yes1no0
			label	var		`var'	"White (SP)"
			
			local	var	sp_nonWhite
			cap	drop	`var'
			gen		`var'=sp_White
			recode	`var'	(1=0) (0=1) 
			label	value	`var'	yes1no0
			label	var		`var'	"non-White (SP)"
			
			*	Individual
			*	NOTE: Individual-level race is NOT avaiable in PSID. So we can only indirectly construct it, using RP or SP
			loc	var	ind_race
			cap	drop	`var'
			gen	`var'=.
			replace	`var'=rp_race	if	seqnum==1	&	relrp_recode==1
			replace	`var'=sp_race	if	seqnum==2	&	relrp_recode==2
			lab	var	`var'	"Race (ind) - only if RP or SP"
			
				loc	var	ind_White
				cap	drop	`var'
				gen		`var'=0	if	inrange(ind_race,2,9)	//	Black, Asian, Native American, etc.
				replace	`var'=1	if	ind_race==1 // White
				label	value	`var'	yes1no0
				label	var		`var'	"White (ind) - only if RP or SP"
				
				local	var	ind_nonWhite
				cap	drop	`var'
				gen		`var'=ind_White
				recode	`var'	(1=0) (0=1) 
				label	value	`var'	yes1no0
				label	var		`var'	"non-White (ind) - only if RP or SP"
					
				
		
		*	State of Residence
		lab	val	rp_state statecode
		lab	var	rp_state "State of Residence"
		
			*	Create a dummy of (group of states)
			tab rp_state, gen(rp_state_enum)
		
			*	Drop Alaska and Hawaii
			*	NOTE: dropping only observations without dropping the entire indiv's obs causes unbalanced panel for some indivdiuals (ex. x11101ll==13031, who were grown in CA and formed her own FU in AL)
			*	However, dropping all observations of individual who have ever lived in AL/CA will drop well-balanced indiv (ex. x11101==18041, who lived there only once)
			*	For now (2021-11-27), I will leave them as they are, BUT KEEP IN MIND HAT TFP cost here does NOT consider AL/HA costs in this file (unlike PFS where we did)
			
			/*
			*	If I want to drop all observations of individual who ever lived there once...
			cap drop	live_in_AL_HA
			cap	drop	ever_in_AL_HA
			gen		live_in_AL_HA=1	if	inlist(rp_state,50,51)
			replace	live_in_AL_HA=0	if	!mi(rp_state) & !inlist(rp_state,50,51)	//	includes NA/DK, inapp
			bys	x11101ll:	egen	ever_in_AL_HA	=	max(live_in_AL_HA)
			
			tab	ever_in_AL_HA
			drop	if	ever_in_AL_HA==1
			drop	live_in_AL_HA	ever_in_AL_HA
			
			*	If I want to drop only the period lived in AL/HA...
			drop	if	inlist(rp_state,50,51)
			*/
			
			*	Generate indicator that FU is in one of 48 states
			local	var	rp_state_48states
			cap	drop	`var'
			gen	`var'	=.
			replace	`var'=0	if	inlist(rp_state,0,50,51,99) // Inapp, AL, HA, DK/NA/DK
			replace	`var'=1	if	!mi(rp_state)	&	!inlist(rp_state,0,50,51,59)
			label	value	`var'	yes1no0
			label var	`var'	"FU in 48 states"
			
			*	Greater region (Northeast, Mid-Atlantic, South, Midwest, West)
			cap	drop	rp_region
			gen		rp_region=.
			replace	rp_region=0	if	inlist(rp_state,0,50,51,59)	// Others: Inapp, AL, HA, DK/NA/DK
			replace	rp_region=1	if	inlist(rp_state,18,28,44,31,20,6,38) //	Northeast: ME, NH, VT, NY, MA, CT, RI
			replace	rp_region=2	if	inlist(rp_state,37,29,8,7,19,45) //	Mid-Atlantic: PA, NJ, DC, DE, MD, VA
			replace	rp_region=3	if	inlist(rp_state,32,39,10,16,41,47,9,1,3,23,17,42) //	South: NC, SC, GA, TN, WV, FL, AL, AR, MS, LS, TX
			replace	rp_region=4	if	inlist(rp_state,34,13,21,12,22,48,14,24) //	MidWest:	OH, IN, MI, IL, MN, WI, IA, MO
			replace	rp_region=5	if	inlist(rp_state,15,26,33,40,35,2,5,11,25,27,30,43,49,36,46,4) //	West: KS, NE, ND, SD, OK, AZ, CO, ID, MT, NV, NM, UT, WY, OR, WA, CA
			
			lab	define	rp_region	0	"Others (Inapp, AL, HA, DK/NA)"	1	"Northeast"	2	"Mid-Atlantic"	3	"South"	4	"Midwest"	5	"West", replace	
			lab	value	rp_region	rp_region
			
				*	Dummies for each region
				tab	rp_region,	gen(rp_region)
				rename	(rp_region?)	(rp_region_Oth	rp_region_NE	rp_region_MidAt	rp_region_South	rp_region_MidWest	rp_region_West)
				clonevar	rp_region_NE_noNY	=	rp_region_NE
				replace		rp_region_NE_noNY	=	0	if	rp_state==31	//	Exclude NY
				
				lab	var	rp_region_Oth	"Other regions (AL, HA, DK/NA, Inapp)"
				lab	var	rp_region_NE	"Northeast"
				lab	var	rp_region_NE_noNY	"Northeast (excluding NY)"
				lab	var	rp_region_MidAt	"Mid-Atlantic"
				lab	var	rp_region_South	"South"
				lab	var	rp_region_MidWest	"Mid-West"
				lab	var	rp_region_West	"West"
				
				
		
		*	Employment Status
			
			
			*	Individual-level education (1979-2019)
			loc	var	ind_employed_dummy
			cap	drop	`var'
			gen		`var'=.
			
			replace	`var'=0	if	inrange(ind_employed,1,2)	//	"Working now" and "Temporarily laid off"
			replace	`var'=1	if	inrange(ind_employed,3,9)	//	Looking for work, retired, permanently disabled, housekeeping, student, other.
			
			*	Treating inappropriate values
				*	On one hand, we should treat them as zero, or many observations with missing values will NOT be included in regression. And some inapp cases make sense to be treated as zero (i.e. 16-year old or younger)
				*	On the other hand, treating some categories as zero could be missleaning (i.e. not yet born) 
				*	Need to think about it.
			replace	`var'=0	if	ind_employed==0	
			
			label	value	`var'	yes1no0
			label	var		`var'	"=1 if Person Employed"
			
			
			*	RP's employment (family-level)
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
			
			*	Individual-level
			loc	var	ind_edu_cat
			cap	drop	`var'
			
			gen		`var'=0		if	inrange(ind_edu,0,0)	//	Inapp
			replace	`var'=1		if	inrange(ind_edu,1,11)	//	Less than HS (I treat )
			replace	`var'=2		if	inrange(ind_edu,12,12)	//	HS
			replace	`var'=3		if	inrange(ind_edu,13,15)	//	Some college
			replace	`var'=4		if	inrange(ind_edu,16,17)	//	College
			replace	`var'=.n	if	inrange(ind_edu,98,99)	//	Dk/NA
			
			replace	`var'=0	if	seqnum==0	//	there are only 2 out of 200K zero seqnum obs that have non-zero value. Possibly data entry error.
			
			label	define	`var'	0	"Inapp"	1	"Less than HS"	2	"High School/GED"	3	"Some college"	4	"College"	/*99	"NA/DK"*/,	replace
			label	value	`var'	`var'
			label 	variable	`var'	"Education category (ind)"
			
				*	Dummies for each category
				cap	drop	ind_edu?
				cap	drop	ind_edu_inapp	ind_NoHS	ind_HS	ind_somecol	ind_col
				tab `var', gen(ind_edu)
				rename	(ind_edu1	ind_edu2	ind_edu3	ind_edu4	ind_edu5)	(ind_edu_inapp	ind_NoHS	ind_HS	ind_somecol	ind_col)
				
				lab	value	ind_edu_inapp	ind_NoHS	ind_HS	ind_somecol	ind_col	yes1no0
				
				label	var	ind_edu_inapp	"Inapp education (ind)"
				label	var	ind_NoHS		"Less than High School (ind)"
				label	var	ind_HS			"High School (ind)"
				label	var	ind_somecol		"Some college (ind)"
				label	var	ind_col			"College Degree (ind)"
				*label	var	rp_NADK	"Education (NA/DK)"
			
			
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
				replace	`var'=.n	if	inrange(year,1968,1990)	&	inrange(rp_gradecomp,9,9)
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
			gen		`var'=0	if	inlist(HFSM_cat,1,2)
			replace	`var'=1	if	inlist(HFSM_cat,3,4)
			
			label	value	`var'	yes1no0
			
			label	var	`var'	"HFSM FI"
			
			*	FSSS-rescaled
			cap	drop	FSSS_rescale
			gen	FSSS_rescale = (9.3-HFSM_scale)/9.3
			label	var	FSSS_rescale "FSSS (re-scaled)"
			
		
		*	Family income
		lab	var	fam_income	"Total family income"
			
			*	Per capita income
			loc	var	fam_income_pc
			cap	drop	`var'
			gen		double	`var'	=	fam_income/famnum
			label	var	`var'	"Family income per capita"	
			
			*	Log of per capita income
			loc	var	ln_fam_income_pc
			cap	drop	`var'
			gen		double	`var'	=	log(fam_income_pc)
			label	var	`var'	"Family income per capita (log)"	
		
		
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
			
			*	200%, entire study period.
			loc	var	income_ever_below_200
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	max(income_below_200)
			lab	var	`var'	"Income below 200% PL at least once"
			tab	`var'	if	year==2013	&	in_sample==1	//	counting only one obs per person. 99% of individuals fall into this category
				
			*	200%, 1997-2017
			loc	var	income_ever_below_200_9713
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	max(income_below_200)	if	inrange(year,1997,2013)
			lab	var	`var'	"Income below 200% PL at least once (1997-2017)"
			tab	`var'	if	year==2013	&	in_sample==1	//	counting only one obs per person. 65% individuals (7,819) fall into this category
			
			*	130%, entire study period
			loc	var	income_ever_below_130
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	max(income_below_130)
			lab	var	`var'	"Income below 130% PL at least once"
			tab	`var'	if	year==2013	&	in_sample==1	//	counting only one obs per person. 98.5% of the invidiuals (17,930) fall into this category
			
			*	130%, 1997-2017
			loc	var	income_ever_below_130_9713
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	max(income_below_130)	if	inrange(year,1997,2013)
			lab	var	`var'	"Income below 130% PL at least once (1997-2013)"
			tab	`var'	if	year==2013	&	in_sample==1	//	counting only one obs per person. 48% of the individuals (5,845) fall into this category
		
		*	Individuals whose family income was "consistently" below 130%/200%
		
			*	200%, entire study period
			loc	var	income_always_below_200
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	min(income_below_200)	//	If individual's income is always below cutoff, then the minimum value would be 1. Otherwise, it would be 0.
			lab	var	`var'	"Income always below 200% PL"
			tab	`var'	if	year==2013	&	in_sample==1	//	counting only one obs per person. 9.5% of individuals (1700) fall into this category.
			
			*	200%, 1997-2017
			loc	var	income_always_below_200_9713
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	min(income_below_200)	if	inrange(year,1997,2013)	//	If individual's income is always below cutoff, then the minimum value would be 1. Otherwise, it would be 0.
			lab	var	`var'	"Income always below 200% PL (1997-2017)"
			tab	`var'	if	year==2013	&	in_sample==1	//	counting only one obs per person. 12% of individuals (1,468) fall into this category.
			
			*	130%, entire study period
			loc	var	income_always_below_130
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	min(income_below_130)	//	If individual's income is always below cutoff, then the minimum value would be 1. Otherwise, it would be 0.
			lab	var	`var'	"Income always below 130% PL"
			tab	`var'	if	year==1979	&	in_sample==1	//	counting only one obs per person. Only 4% (721) individuals fall into this category.
		
			*	130%, 1997-2017
			loc	var	income_always_below_130_9713
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	min(income_below_130)	if	inrange(year,1997,2013)	//	If individual's income is always below cutoff, then the minimum value would be 1. Otherwise, it would be 0.
			lab	var	`var'	"Income always below 130% PL (1997-2017)"
			tab	`var'	if	year==2013	&	in_sample==1	//	counting only one obs per person. 4.7% of individuals (574) fall into this category.
		
			
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
		
		
		
		
		*	Food stamp amount received
		
			*	FS Recall period (1999-2007) - will be later used to adjust values
			loc	var	FS_rec_amt_recall
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=stamp_cntyr_recall	if	inrange(year,1999,2007)
			
			lab	define	`var'	0	"Inapp"		2	"Wild code"	3	"Week"	4	"Two-Week"	5	"Month"	6	"Year"	7	"Other"	8	"DK"	9	"NA/refused", replace
			label	value	`var'	`var'
			label	var	`var'	"FS/SNAP amount received (recall) (1999-2007)"
		
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
			
			label	var	`var'	"FS/SNAP amount received last month"
			
			
			*	Replace food stamp amount received with missing if didn't receive stamp (FS_rec_wth==0), for summary stats
			*	There are only two obs with non-zero amount, so should be safe to clean.
			*	This code can be integrated into "cleaning" part later
			*replace	FS_rec_amt_capita_real=.n	if	FS_rec_wth==0
			replace	FS_rec_amt=.n	if	FS_rec_wth==0
						
	
			*	FS amt received per capita
			loc	var	FS_rec_amt_capita
			cap	drop	`var'
			gen	`var'	=	FS_rec_amt	/	famnum
			lab	var	`var'	"FS/SNAP amount receive last month per capita"
			
			*	Quick summary stat
			tab FS_rec_wth FS_rec_crtyr_wth if inrange(year,1999,2007)
			tab FS_rec_wth if inrange(year,1999,2007) & FS_rec_crtyr_wth==1	//	FU that used FS this year, but not last month			
		
		*	Food stamp amount paid (1975-1979)
		*	On one hand, technically, this amount should be added to "amount saved" to get total food value from food stamp
		*	On the other hand, when I check trend over time between pre-1980 and post-1980, stamp amount received is smooth when I do NOT include it, but has a huge discontinuity when added
			*	Also problematic especially in 1979 where most families gave zero value which didn't happen in earlier years, assuming stamps were no longer required to paid since 1980 survey.
		*	For now, I will NOT include this value into the food stamp amount received for two reasons
			*	(1) Causes huge jump (discontinuity) in food stamp amount trend
			*	(2) I am interested in "extra" amount from FS to food expenditure, implying bonus value only (not the total amount received)
			*	There is 1 obs in raw data where HH answered "$999 or more". I recoded them as zero.
			local	var	FS_rec_amt_paid
			cap	drop	`var'
			gen		double	`var'=.	
			replace	`var'=	stamp_payamt_month	if	inrange(year,1975,1979)
			replace	`var'=	0	if	`var'==999	//	Replace a few missing obs with zero value
			label	var	`var'	"Amount paid for food stamp last month (1975-1979)"
		
			*	(2022-04-28) I will disable this variable since we don't need it, but we can include it later
			/*
			*	Food stamp amount paid + received (bonus) = which yields total food stamp value received.
			loc	var	FS_rec_amt_tot
			cap	drop	`var'
			egen	`var' = rowtotal(FS_rec_amt FS_rec_amt_paid) if inrange(year,1975,1979)
			loc	var	`var'	"Amount paid + bonus value (1975-199)"
			*/
			

			*	Time-series 
		
		
		*	Reason for not participating FS (1977, 1980, 1981, 1987)
		*	Note that this is just for the first mention.
		loc	var	reason_no_FSP
		cap	drop	`var'
		gen		`var'=.n	if	why_no_FSP==0
		replace	`var'=1		if	((why_no_FSP==3	&	year==1977)	|	(why_no_FSP==2	&	inlist(year,1980,1981,1987)))	//	Admin hassle
		replace	`var'=2		if	((why_no_FSP==6	&	year==1977)	|	(why_no_FSP==3	&	inlist(year,1980,1981,1987)))	//	Lack of information (Didn't know)
		replace	`var'=3		if	((why_no_FSP==5	&	year==1977)	|	(why_no_FSP==4	&	inlist(year,1980,1981,1987)))	//	Physical access problem
		replace	`var'=4		if	((why_no_FSP==7	&	year==1977)	|	(why_no_FSP==5	&	inlist(year,1980,1981,1987)))	//	Didn't need it (I can live without it, other people will need more, etc.)
		replace	`var'=5		if	((why_no_FSP==8	&	year==1977)	|	(why_no_FSP==6	&	inlist(year,1980,1981,1987)))	//	Personal attributes (too embarrased, don't like it)
		replace	`var'=6		if	((why_no_FSP==9	&	year==1977)	|	(why_no_FSP==7	&	inlist(year,1980,1981,1987)))	//	Never bothered.
		replace	`var'=7		if	((inlist(why_no_FSP,1,2,4)	&	year==1977)	|	(inlist(why_no_FSP,1,8,9)	&	inlist(year,1980,1981,1987)))	//	Never bothered.
		
		lab	define	`var'	1	"Admin hassle"	2	"Lack of information"	3	"Physical access problem"	4	"Didn't need it"	5	"Personal attributes"	6	"Never bothered"	7	"Others"
		lab	value	`var'	`var'
		lab	var	`var'	"Reason for non-participation"
		
		
	
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
			replace	`var'=.	if	live_in_FU==0	//	Replace it as missing if not living in FU (ex. institution, moved out, etc.)
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
			replace	`var'=.	if	live_in_FU==0	//	Replace it as missing if not living in FU (ex. institution, moved out, etc.)
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
		local	years	1975	${sample_years}
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
					   
			svyset	sampcls [pweight=wgt_long_ind], strata(sampstr)	singleunit(scaled)
				
				*	Generate time variable which increases by 1 over wave ("year" ") // can be used to construct panel data (we can't directly use "year" because PSID was collected bieenially since 1997, thus data will treat it as gap period)
				cap	drop	time
				gen		time	=	year-1977
				replace	time	=	year-1977
			xtset x11101ll year,	delta(1)
		
			*	Create lagged vars
			*	(2022-5-4) we will use 2nd-lag as default lagged food expenditure due to data restriction
				*	Note that under AR(1) process, y_t = a*y_t-1 = a^2 * y_t-2
			foreach	var	of	global	money_vars	{
				
				cap	drop	l1_`var'
				cap	drop	l2_`var'
				*gen	double	l1_`var'	=	l.`var'		if	year<=1997	//	When PSID was collected annually
				*replace		l1_`var'	=	l2.`var'	if	year>=1999	//	When PSID was collected bieenially
				gen	double	l1_`var'	=	l1.`var'		
				gen	double	l2_`var'	=	l2.`var'
				
			}
			
			*	Create lagged dummes for SNAP status
			sort	x11101ll	year
			foreach	lag	in	2	4	6	8	{
				
				cap	drop	l`lag'_FS_rec_wth
				gen		l`lag'_FS_rec_wth	=	l`lag'.FS_rec_wth
				lab	var	l`lag'_FS_rec_wth	"SNAP received `lag' years ago"
				
				*cap	drop	f`lag'_FS_rec_wth
				*gen		f`lag'_FS_rec_wth	=	f`lag'.FS_rec_wth
				*lab	var	f`lag'_FS_rec_wth	"SNAP received `lag' years later"
				
				
			}
			
			*	Create "observational-level" dummies of culumative SNAP redemptions over 5-year (t-4, t-2, t)
			*	NOTE: This is an observational-level variable, NOT individual-level variable
				*	Suppose an individual's SNAP status over 9 years (t-4, t-2, t, t+2, t+4) is (0,0,1,0,1)
				*	Then this variable's value will be (1,1,2) in (t-4, t-2 and t)
			*	I construct "individual-level" SNAP status over years after the "first" SNAP participation later.
				
				*	5-year
				loc	var	SNAP_cum_status_5
				cap	drop	`var'	//	SNAP_for_cum
				egen	`var'	=	group(FS_rec_wth	l2_FS_rec_wth	l4_FS_rec_wth)
				lab	var	`var'	"Cumulative SNAP status last 5-year"
				*egen	SNAP_for_cum	=	group(FS_rec_wth	f2_FS_rec_wth	f4_FS_rec_wth)
				*lab	var	SNAP_for_cum	"Cumulative SNAP status next 5-year"
				
				
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
					
				cap	drop	SNAP_???
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
				
			*	Total # of SNAP redemptions over 5-year
			*	NOTE: This is an observational-level.
			loc	var		SNAP_cum_fre_5
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0		if	inlist(1,SNAP_000)
			replace	`var'=1		if	inlist(1,SNAP_100,SNAP_010,SNAP_001)
			replace	`var'=2		if	inlist(1,SNAP_110,SNAP_011,SNAP_101)
			replace	`var'=3		if	inlist(1,SNAP_111)
			
			lab	var	`var'		"\# SNAP participation last 5 years"
			
			*	Total # of CONTINUOUS SNAP redemptions over 5-year
			*	This variable captures extensive/intensive margin, by treating non-categories as missing
				*	For instance, to capture extensive margin, "redemption in t-2 only" should NOT be cateogorzied as zero, but as missing.
				*	Similarly, to capture intensive margin, "redemption in t-4 and t" should NOT be cateogorzied as zero, but as missing.
			*	NOTE: This is an observational-level.
			loc	var	SNAP_cum_fre_cont_5
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0	if	SNAP_000==1
			replace	`var'=1	if	SNAP_100==1
			replace	`var'=2	if	SNAP_110==1
			replace	`var'=3	if	SNAP_111==1
			lab	var	`var'	"\# continuous SNAP participation: 5 years"
		
			
			
			*	7-year period
			loc	var	SNAP_cum_status_7
			cap	drop	`var'	
			egen	`var'	=	group(FS_rec_wth	l2_FS_rec_wth	l4_FS_rec_wth	l6_FS_rec_wth)
			
			
			*	Double-check how each value is assigned.
			loc	var	SNAP_cum_status_7
			local	count=1
			forval	l0val=0/1	{
				
				forval	l2val=0/1	{
					
					forval	l4val=0/1	{
						
						forval	l6val=0/1	{
										
							assert	`var'==`count'	if	l6_FS_rec_wth==`l6val'	&	l4_FS_rec_wth==`l4val'	&	l2_FS_rec_wth==`l2val'	&	FS_rec_wth==`l0val'
							
							cap	drop	SNAP_`l6val'`l4val'`l2val'`l0val'
							gen			SNAP_`l6val'`l4val'`l2val'`l0val'=0	if	!mi(SNAP_cum_status_7)
							replace		SNAP_`l6val'`l4val'`l2val'`l0val'=1	if	!mi(SNAP_cum_status_7)	&	l6_FS_rec_wth==`l6val'	&	l4_FS_rec_wth==`l4val'	&	l2_FS_rec_wth==`l2val'	&	FS_rec_wth==`l0val'
							loc	count=`count'+1
							
						}
						
					}
					
				}
			}
	
			
			lab	define	`var'	1	"Never"		2	"t-6 only"			3	"t-4 only"			4	"t-6 and t-4 only"	///
								5	"t-2 only"	6	"t-6 and t-2 only"	7	"t-4 and t-2 only"	8	"t-6 t-4 and t-2"	///
								9	"t"		10	"t-6  t"		11	"t-4 t"			12	"t-6 t-4 t"	///
								13	"t-2 t"	14	"t-6  t-2 t"	15	"t-4  t-2 t"	16	"t-6 t-4  t-2 t"	, replace
			lab	val	`var'	`var'
			lab	var	`var'	"SNAP status last 7 years"
			*egen	SNAP_for_cum	=	group(FS_rec_wth	f2_FS_rec_wth	f4_FS_rec_wth)
			*lab	var	SNAP_for_cum	"Cumulative SNAP status next 5-year"	
		
			*	Total # of SNAP redemptions over 7-year
			*	NOTE: This is an observational-level.
			loc	var		SNAP_cum_fre_7
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0		if	inlist(SNAP_cum_status_7,1) //inlist(1,SNAP_0000)
			replace	`var'=1		if	inlist(SNAP_cum_status_7,2,3,5,9)	// inlist(1,SNAP_1000,SNAP_0100,SNAP_0010,SNAP_0001)
			replace	`var'=2		if	inlist(SNAP_cum_status_7,4,6,7,10,11,13)	// inlist(1,SNAP_1100,SNAP_1010,SNAP_1001,SNAP_0110,SNAP_0101,SNAP_0011)
			replace	`var'=3		if	inlist(SNAP_cum_status_7,8,12,14,15)	//	inlist(1,SNAP_1110,SNAP_1101,SNAP_1011,SNAP_0111)
			replace	`var'=4		if	inlist(SNAP_cum_status_7,16)	//	inlist(1,SNAP_1111)
			
			lab	var	`var'		"\# SNAP participation last 7 years"
			
			*	Total # of CONTINUOUS SNAP redemptions over 7-year
			*	This variable captures extensive/intensive margin, by treating non-categories as missing
				*	For instance, to capture extensive margin, "redemption in t-2 only" should NOT be cateogorzied as zero, but as missing.
				*	Similarly, to capture intensive margin, "redemption in t-4 and t" should NOT be cateogorzied as zero, but as missing.
			*	NOTE: This is an observational-level.
			loc	var	SNAP_cum_fre_cont_7
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0	if	SNAP_cum_status_7==1 	//	SNAP_1000==1
			replace	`var'=1	if	SNAP_cum_status_7==2 	//	SNAP_1000==1
			replace	`var'=2	if	SNAP_cum_status_7==4	//	SNAP_1100==1
			replace	`var'=3	if	SNAP_cum_status_7==8	//	SNAP_1110==1
			replace	`var'=4	if	SNAP_cum_status_7==16	//	SNAP_1111==1
			lab	var	`var'	"\# continuous SNAP participation: 7 years"
			
			
			
			
			*	9-year period
			loc	var	SNAP_cum_status_9
			cap	drop	`var'	
			egen	`var'	=	group(FS_rec_wth	l2_FS_rec_wth	l4_FS_rec_wth	l6_FS_rec_wth	l8_FS_rec_wth)
			
			
			*	Double-check how each value is assigned.
			loc	var	SNAP_cum_status_9
			local	count=1
			forval	l0val=0/1	{
				
				forval	l2val=0/1	{
					
					forval	l4val=0/1	{
						
						forval	l6val=0/1	{
										
							forval	l8val=0/1	{
							
							assert	`var'==`count'	if	l8_FS_rec_wth==`l8val'	&	l6_FS_rec_wth==`l6val'	&	l4_FS_rec_wth==`l4val'	&	l2_FS_rec_wth==`l2val'	&	FS_rec_wth==`l0val'
							
							cap	drop	SNAP_`l8val'`l6val'`l4val'`l2val'`l0val'
							gen			SNAP_`l8val'`l6val'`l4val'`l2val'`l0val'=0	if	!mi(SNAP_cum_status_9)
							replace		SNAP_`l8val'`l6val'`l4val'`l2val'`l0val'=1	if	!mi(SNAP_cum_status_9)	&	l8_FS_rec_wth==`l8val'	&	l6_FS_rec_wth==`l6val'	&	l4_FS_rec_wth==`l4val'	&	l2_FS_rec_wth==`l2val'	&	FS_rec_wth==`l0val'
							loc	count=`count'+1
							
							}
							
						}
						
					}
					
				}
			}
	
			
			lab	define	`var'	1	"Never"		2	"t-8 only"		3	"t-6 only"		4	"t-8 t-6"	///
								5	"t-4"		6	"t-8  t-4 "		7	"t-6 t-4"		8	"t-8 t-6 t-4"	///
								9	"t-2"		10	"t-8  t-2"		11	"t-6 t-2"		12	"t-8 t-6 t-2"	///
								13	"t-4 t-2"	14	"t-8  t-4 t-2"	15	"t-6  t-4 t-2"	16	"t-8 t-6  t-4 t-2"	///
								17	"t"		18	"t-8 t"		19	"t-6 t"		20	"t-8 t-6 t"	///
								21	"t-4 t"		22	"t-8  t-4 t"		23	"t-6 t-4 t"			24	"t-8 t-6 t-4 t"	///
								25	"t-2 t"		26	"t-8  t-2 t"		27	"t-6 t-2 t"			28	"t-8 t-6 t-2 t"	///
								29	"t-4 t-2 t"	30	"t-8  t-4 t-2 t"	31	"t-6  t-4 t-2 t"	32	"t-8 t-6  t-4 t-2 t", replace
								
			lab	val	`var'	`var'
			lab	var	`var'	"SNAP status last 9 years"
	
			*	Total # of SNAP redemptions over 9-year
			*	NOTE: This is an observational-level.
			loc	var		SNAP_cum_fre_9
			cap	drop	`var'
			egen	`var'	=	rowtotal(FS_rec_wth	l2_FS_rec_wth	l4_FS_rec_wth	l6_FS_rec_wth	l8_FS_rec_wth)	
			replace	`var'	=.	if	mi(SNAP_cum_status_9)	//	Tag as missing if SNAP status is missing in any time period over 9-year.
			
			lab	var	`var'		"\# SNAP participation last 9 years"
			
			*	Total # of CONTINUOUS SNAP redemptions over 7-year
			*	This variable captures extensive/intensive margin, by treating non-categories as missing
				*	For instance, to capture extensive margin, "redemption in t-2 only" should NOT be cateogorzied as zero, but as missing.
				*	Similarly, to capture intensive margin, "redemption in t-4 and t" should NOT be cateogorzied as zero, but as missing.
			*	NOTE: This is an observational-level.
			loc	var	SNAP_cum_fre_cont_9
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0	if	SNAP_cum_status_9==1
			replace	`var'=1	if	SNAP_cum_status_9==2
			replace	`var'=2	if	SNAP_cum_status_9==4
			replace	`var'=3	if	SNAP_cum_status_9==8
			replace	`var'=4	if	SNAP_cum_status_9==16
			replace	`var'=5	if	SNAP_cum_status_9==32
			lab	var	`var'	"\# continuous SNAP participation: 9 years"	
			
			
			*	Generate SNAP status from (i) 1990 to 1996 (ii) 1977 to 1996
			*	Inspecting aggregated outcome over longer-time horizon is based on the hypothesis that SNAP effects last over longer periods.
			*	This hypothesis requires me to restrict the analysis sample to those who had no prior SNAP experience over the same period.
			*	I will tag individuals (i) who had no SNAP exposure from 1990 to 1996 (ii) who had no SNAP exposure from 1977 to 1996
			*	We might need to restrict FSD sample whose value is 0 in either of the two.
			loc	var	SNAP_1990_1996
			cap	drop	`var'
			cap	drop	`var'_tmp
			bys	x11101ll:	egen	`var'_tmp	=	total(FS_rec_wth)	if	inrange(year,1990,1996)
			bys	x11101ll:	egen	`var'		=	max(`var'_tmp)
			drop	`var'_tmp
			lab	var	`var'	"\# of SNAP participation (1990-1996)"
			
			loc	var	SNAP_1977_1996
			cap	drop	`var'
			cap	drop	`var'_tmp
			bys	x11101ll:	egen	`var'_tmp	=	total(FS_rec_wth)	if	inrange(year,1977,1996)
			bys	x11101ll:	egen	`var'		=	max(`var'_tmp)
			drop	`var'_tmp
			lab	var	`var'	"\# of SNAP participation (1977-1996)"
		
		*	Drop 1975 and 1990
		*	I only need those years for 1967 and 1991, which I just imported above (so no longer needed)
		*	(2021-11-28) Let's not do this for now, as we still need lagged information for purposes (ex. PT assumption testing, etc.)
		*drop	if	inlist(year,1975,1990)
					
		*	Drop variables no longer needed
		*	(This part will be added later)
		
		
		*	(2023-08-24) Construct Cumulative SNAP usage variables, (used for event study plot, intensive/extensive marginal effect, etc.)
				
			*	For event study, we need to create a standardized time
			*	Since there are multiple treatments occuring multiple periods, it is difficult to standardize treatment period.
				*	For example, if a household is treated in 1997 and 1999, then relative treatment period cannot be standarized (which on should be t=0?)
			*	There are two ways to deal with
				*	(1) Limit the sample to whose who "never treated" and "treated only once" where treatment time can be standarzied.
				*	(2) Standardize based on the "first treatment"
			*	I will do the second method, using "tsspell" command
			
			*	Total # of SNAP participation over time (it will be used for analyses by group)
			loc	var	SNAP_cumul_all
			cap	drop	`var'
			bys	x11101ll:	egen	`var'	=	total(FS_rec_wth)
			lab	var	`var'	"\# of SNAP participation over the entire period"
			
						
			* Construct the spells of SNAP redemption using "tsspell" command
			*	NOTE: "replace" option does not work when the variable doesn't exist, so we manually drop them
			*	(2023-09-10) Start with year==1997, a causal inference period.
			cap	drop	SNAP_seq
			cap	drop	SNAP_spell
			cap	drop	SNAP_end	
			tsspell, cond(year>=1997 & FS_rec_wth==1) seq(SNAP_seq) spell(SNAP_spell) end(SNAP_end) 
			
			*	Construct standardized year T when T=-4 as "first SNAP participation" (i.e. T=0 means "first SNAP in 4 years ago")
			*	The reason for not standardizing T when T=0 as "the year first received SNAP" is because, we constructed FSD variables based on PFS status in t-4, t-2 and t
				*	Since I want to plot event study design and effects on SNAP participation based on SNAP redemption status over the same period (t-4, t-2 and t), we need to standardize based on SNAP redemption at t-4
				*	If we standardize based on first SNAP participation at t=0, there's no SNAP status in t=-2 and t=-4 (since first got SNAP in t=0).
			*	Note: the code below excludes those who are "never treated", since they do not have any year of SNAP participation
			
			loc	var		year_SNAP_std
			cap	drop	`var'
			gen	`var'=.
			/*
			forval	t=0(2)4	{
			    
				replace	`var'=`t'			if	l`t'.SNAP_seq==1	&	l`t'.SNAP_spell==1
				replace	`var'=`t' * (-1)	if	f`t'.SNAP_seq==1	&	f`t'.SNAP_spell==1
				
			}
			*/
			
			replace	`var'=-4	if	l0.SNAP_seq==1	&	l0.SNAP_spell==1	//	T=-4: year first received SNAP since 1997
			replace	`var'=-2	if	l2.SNAP_seq==1	&	l2.SNAP_spell==1	//	T=-2: 2 years after first received SNAP since 1997
			replace	`var'=0		if	l4.SNAP_seq==1	&	l4.SNAP_spell==1	//	T=0:  4 years after first received SNAP since 1997
			
			replace	`var'=-6	if	f2.SNAP_seq==1	&	f2.SNAP_spell==1	//	T=-6: 2 years prior to first received SNAP since 1997
			replace	`var'=-8	if	f4.SNAP_seq==1	&	f4.SNAP_spell==1	//	T=-8: 4 years prior to first received SNAP since 1997, standardize at T=-8
			
			
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
					*	(1) Those who redeemed SNAP only once over the 5-year period
					*	(2) Those who redeemed SNAP twice over the 5-year period
					*	(3) Those who redeemed SNAP all 3 periods over the 5-year period (t-4, t-2, t)
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
			collapse (mean) FS_rec_wth foodexp_tot_exclFS foodexp_tot_inclFS foodexp_tot_exclFS_pc foodexp_tot_inclFS_pc foodexp_W_TFP_pc overTFP_exclFS overTFP_inclFS [aw=wgt_long_ind], by(year)
			tempfile	foodvar_check
			save		`foodvar_check'
		restore
		preserve
			collapse (mean) FS_rec_amt if FS_rec_wth==1 [aw=wgt_long_fam_adj], by(year)
			merge	1:1	year	using	`foodvar_check', nogen assert(3)
			
			lab	var	foodexp_tot_exclFS		"Food exp (w/o FS)"
			lab	var	foodexp_tot_exclFS_pc	"Food exp per capita (w/o FS)"
			lab	var	foodexp_tot_inclFS_pc	"Food exp per capita (with FS)"
			lab	var	FS_rec_amt	"FS benefit ($)"
			
			graph	twoway	(line foodexp_tot_exclFS year, /*lpattern(dash)*/ xaxis(1 2) yaxis(1))	///
							/*(line TFP_monthly_cost	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)) */ 	///
							(line FS_rec_amt	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)),  ///
							xline(1980 1993 1999 2007, axis(1) lpattern(dot)) xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
							xtitle(Year)	xtitle("", axis(2)) /* title(Monthly Food Expenditure and FS Benefit)*/	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_FSamt_byyear, replace)
			
				
			graph	export	"${SNAP_outRaw}/foodexp_FSamt_byyear.png", replace
			graph	close	
		restore
			/*
			graph	twoway	(line foodexp_tot_exclFS_pc year, lpattern(dash) xaxis(1 2) yaxis(1))	///
						(line foodexp_tot_inclFS_pc	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)),  ///
						xline(1974 1996 2009 2020, axis(1)) xlabel(1974 "Nationwide FSP" 1996 "Welfare Reform" 2009 "ARRA" 2020 "COVID", axis(2))	///
						xtitle(Fiscal Year)	xtitle("", axis(2))  /*title(Program Summary)*/	bgcolor(white)	graphregion(color(white)) note(Source: USDA & BLS)	name(SNAP_summary, replace)
		
			
			*/
	
	*	Change in food expenditure

			*	W/O SNAP benefit
			loc	var	foodexp_exclFS_diff
			cap	drop	`var'
			gen	`var'	=	foodexp_tot_exclFS_pc_real	-	l2.foodexp_tot_exclFS_pc_real
			lab	var	`var'	"Diff in food exp (w/o SNAP)"
			
			*	with SNAP benefit
			loc	var	foodexp_inclFS_diff
			cap	drop	`var'
			gen	`var'	=	foodexp_tot_inclFS_pc_real	-	l2.foodexp_tot_inclFS_pc_real
			lab	var	`var'	"Diff in food exp (with SNAP)"
				
	*	Food expenditure normalized at (COLI-adjusted) TFP cost

			*	With SNAP benefit
			loc	var	foodexp_inclFS_TFP_normal
			cap	drop	`var'
			
			gen	`var'	=	(foodexp_tot_inclFS_pc_real	-	foodexp_W_TFP_pc_COLI_real)	/	foodexp_W_TFP_pc_real
			lab	var	`var'	"Food exp normalized at TFP - with SNAP"
			
			*	Without SNAP benefit
			loc	var	foodexp_exclFS_TFP_normal
			cap	drop	`var'
			
			gen	`var'	=	(foodexp_tot_exclFS_pc_real	-	foodexp_W_TFP_pc_COLI_real)	/	foodexp_W_TFP_pc_real
			lab	var	`var'	"Food exp normalized at TFP  - without SNAP"
				
		
		
		*	Save cleaned
		
			*	Make dta
			notes	drop _dta
			notes:	SNAP_cleaned_long / created by `name_do' - `c(username)' - `c(current_date)' ///
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
			save	"${SNAP_dtInt}/SNAP_cleaned_long.dta", replace
		
		* Exit	
		exit
	
		
		
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
