
	/*****************************************************************
	PROJECT: 		SNAP of FS
					
	TITLE:			FSD_construct
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Jan 14, 2023 by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	x11101ll        // 1999 Family ID

	DESCRIPTION: 	Construct PFS and FSD variables
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Construct PFS
					2 - Construct FSD variables
					
	INPUTS: 		* FSD_constructed data
					${SNAP_dtInt}/SNAP_cleaned_long.dta
										
	OUTPUTS: 		* PSID constructed data (with PFS and FSD variables)						
					${SNAP_dtInt}/SNAP_const.dta
					

	NOTE:			* Used only for 1979-2013 causal inference paper
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
	loc	name_do	FSD_construct
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${SNAP_doCln}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	*	Determine which part of the code to be run
	local	FSD_const	1	//	Construct FSD from PFS
	
	
		
	/****************************************************************
		SECTION 2: Construct FSD
	****************************************************************/	
	

	
	*	(2023-08-30) Not sure I am gonna use it... since most individual-level samples are almost balanced, and annual FI prevalence measured by PFS more accurately matches with individual-level sample
	/*
	{
	*	Keep only same RPs over 1997-2013 (so I can basically make it household-level)
		*	RP in the same household: (i) sequence number is equal to 1 (ii) relation to RP is equal to 10 (iii) No change in head
		cap	drop	sameRP
		gen		sameRP=0
		replace	sameRP=1	if	seqnum==1	&	relrp_recode==1 & inlist(change_famcomp,0,1,2)
		
		lab	var	sameRP	"Same RP"
		
		*	RP or SP in the same household: (i) sequence number is 1 or 2 (ii) relation to RP is 10, 20 or 22 throught the study period (iii) 
		cap	drop	sameRPorSP
		gen		sameRPorSP=0
		replace	sameRPorSP=1	if	inlist(seqnum,1,2)	&	inlist(relrp_recode,1,2) & inlist(change_famcomp,0,1,2,3,4)
		
		lab	var	sameRPorSP	"Same RP or SP in `year'"
		
		*	Tag only individuals that are same RP over 1997-2013
		cap	drop	sameRP_9713
		bys	x11101ll: egen	sameRP_9713 = total(sameRP) if inrange(year,1997,2013)
		
		keep	if	sameRP_9713==9
		
	}
	*/
	
	
	*	Construct dynamics variables
	if	`FSD_const'==1	{
				
	use	"${SNAP_dtInt}/SNAP_long_PFS", clear
	
		*	Keep only 1997-2013 sample
		keep	if	inrange(year,1997,2013)
		
		*	Keep if non-missing PFS
		keep	if	!mi(PFS_ppml)
	
		*	# of non-missing PFS over teh entire period per individual
		cap	drop	num_nonmiss
		sort	x11101ll	year
		bys	x11101ll:	egen num_nonmiss = count(PFS_ppml)
		lab	var	num_nonmiss	"\# of non-missing PFS"
		
		
		
		*	Construct FI indicator based on PFS
		*	In LBH, we used flexible cut-off; set cut-off such that FI(PFS) prevalence rate is equal to the offical FI reported in the annual USDA report.
		*	In this paper, I match fixed cut-off that best matches FI (FSSS) rate in my study sample during 1999, 2001 and 2003
		*	I use fixed cut-off=0.4 which best matches the FI (FSSS) rate in our sample during 1999, 2001 and 2003, based on the exercise below.

			*	FI(PFS) with different cutoffs
				loc	var	PFS_FI_05
				cap	drop	`var'
				gen		`var'=0	if	!inrange(PFS_ppml,0,0.5)
				replace	`var'=1	if	inrange(PFS_ppml,0,0.5)
				
				loc	var	PFS_FI_04
				cap	drop	`var'
				gen		`var'=0	if	!inrange(PFS_ppml,0,0.4)
				replace	`var'=1	if	inrange(PFS_ppml,0,0.4)
				
				loc	var	PFS_FI_045
				cap	drop	`var'
				gen		`var'=0	if	!inrange(PFS_ppml,0,0.45)
				replace	`var'=1	if	inrange(PFS_ppml,0,0.45)
				
			
			*	Time trend of food insecurity (by PFS) over years, over different cutoffs	
			*	As we can see, 0.4 is the cut-off that most similarly matches FI prevalence rate (FSSS)
			preserve		
				
				collapse	(mean) PFS_ppml	PFS_FI_05	PFS_FI_04	PFS_FI_045	HFSM_FI	[aw=wgt_long_ind], by(year)	//	weighted average by year
			
				
				*	FI prevalence rate by different cut-offs.
				twoway	(line PFS_FI_05	year,	lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "(PFS < 0.5)")))	///
						(line PFS_FI_045	year, 	lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "(PFS < 0.45)"))) 	///
						(line PFS_FI_04	year, 	lc(red) lp(shortdash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "(PFS < 0.4)")))	///
						(line HFSM_FI	year, 		lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "FI (FSSS)")row(1) size(small) keygap(0.1) symxsize(5))),	///
						title("Food Insecurity Rates by Cut-offs") ytitle("Fraction") xtitle("Year") name(FI_prevalence_cutoffs, replace)
				graph	export	"${SNAP_outRaw}/PFS_FI_rate_cutoffs.png", as(png) replace
				graph	close	
			restore
			
			drop	PFS_FI_05	PFS_FI_03
			rename	PFS_FI_045	PFS_FI_ppml
			lab	var	PFS_FI_ppml	"Food insecure (PFS < 0.45)"

			
			*	Set global macro for cutoff,
			global	PFS_cutoff=0.45
			
		*tsspell, f(L.year == .)
		*br year _spell _seq _end
		
		*gen f_year_mi=1	if	mi(f.year)
		
		*	Generate spell-related variables
		*	(2023-09-08) Not sure I am gonna use it... If I do, it should be combined with "\# of non-missing values in PFS over the certain years, since we do not want to consider spell with gap period.
		
		cap drop	PFS_FI_seq	PFS_FI_spell	PFS_FI_end
		tsspell, cond(PFS_FI_ppml==1) spell(PFS_FI_spell) seq(PFS_FI_seq) end(PFS_FI_end)
		/*
		foreach	var	in	_seq	_spell	_end	{
		    
			replace	`var'=.	if	mi(PFS_FI_ppml)
			
		}
		*/
		
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	PFS_FI_seq	PFS_FI_spell		PFS_FI_end
		
	
		
		
		*	Before genering FSDs, generate the number of non-missing PFS values over the year  (PFS_t, PFS_t-2, PFS_t-4)
		*	It will vary from 0 to the full length of reference period (currently 3)
			
			*	5-year
			loc	var	num_nonmiss_PFS_5
			cap	drop	`var'
			gen	`var'=0
			foreach time in 0 2 4	{
				
				replace	`var'	=	`var'+1	if	!mi(l`time'.PFS_ppml)

			}
			lab	var	`var'	"# of non-missing PFS in the last 5 years"
			
			*	7-year
			loc	var	num_nonmiss_PFS_7
			cap	drop	`var'
			gen	`var'=0
			foreach time in 0 2 4 6	{
				
				replace	`var'	=	`var'+1	if	!mi(l`time'.PFS_ppml)

			}
			lab	var	`var'	"# of non-missing PFS in the last 7 years"
			
			*	9-year
			loc	var	num_nonmiss_PFS_9
			cap	drop	`var'
			gen	`var'=0
			foreach time in 0 2 4 6	8 {
				
				replace	`var'	=	`var'+1	if	!mi(l`time'.PFS_ppml)

			}
			lab	var	`var'	"# of non-missing PFS in the last 5 years"
		
	
		*	Spell length variable - the consecutive years of FI experience
		*	Start with 5-year period (SL_5)
		*	To utilize biennial data since 1997, I use observations in every two years
			*	Many years lose observations due to data availability
		*	(2023-08-01) I construct "backwardly", aggregating PFS_t, PFS_t-2, PFS_t-2. FSD = f(PFS_t, PFS_t-2, PFS_t-4)
			*	Chris once mentioned that regression current redemption on future outcome may not make sense (Chris said something like that...)
		*	(2023-08-02) I construct SL5 starting only from t-4. For instance, if individual is FS in t-4 but FI in t-2 and t, SL5=0
		*	Need to think about how to deal with those cases
		
		loc	var	SL_5
		cap	drop	`var'
		gen		`var'=.	if	num_nonmiss_PFS_5!=3	//	missing if any PFS is missing in the last 5 years
		replace	`var'=0	if	num_nonmiss_PFS_5==3	&	l4.PFS_FI_ppml==0	//	if food secure in l4, it takes value 0 regardless of status in t-2 and t
		replace	`var'=1	if	num_nonmiss_PFS_5==3	&	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==0	//	food insecure in t-4, but secure in t-2 (doesn't matter t0 status)
		replace	`var'=2	if	num_nonmiss_PFS_5==3	&	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	&	PFS_FI_ppml==0	//	food insecure in t-4 and t-2, but secure in t0
		replace	`var'=3	if	num_nonmiss_PFS_5==3	&	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	&	PFS_FI_ppml==1	//	food insecure in t-4 and t-2, but secure in t0
		lab	var	`var'	"Spell length (5-year)"
		
		loc	var	SL_7
		cap	drop	`var'
		gen		`var'=.	if	num_nonmiss_PFS_7!=4	//	missing if any PFS is missing in the last 7 years
		replace	`var'=0	if	num_nonmiss_PFS_7==4	&	l6.PFS_FI_ppml==0	//	if food secure in t-6, it takes value 0 regardless of status in t-2 and t
		replace	`var'=1	if	num_nonmiss_PFS_7==4	&	l6.PFS_FI_ppml==1	&	l4.PFS_FI_ppml==0	//	food insecure in t-6, but secure in t-4 (doesn't matter later status)
		replace	`var'=2	if	num_nonmiss_PFS_7==4	&	l6.PFS_FI_ppml==1	&	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==0	//	food insecure in t-6 and t-4, but not in t-2 (t0 doesn't matter)
		replace	`var'=3	if	num_nonmiss_PFS_7==4	&	l6.PFS_FI_ppml==1	&	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	&	PFS_FI_ppml==0	//	food insecure in t-6, t-4 and t-2 (but not t0)
		replace	`var'=4	if	num_nonmiss_PFS_7==4	&	l6.PFS_FI_ppml==1	&	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	&	PFS_FI_ppml==1	//	food insecure in t-6, t-4, t-2 and t0
		lab	var	`var'	"Spell length (7-year)"
		
		loc	var	SL_9
		cap	drop	`var'
		gen		`var'=.	if	num_nonmiss_PFS_9!=5	//	missing if any PFS is missing in the last 9 years
		replace	`var'=0	if	num_nonmiss_PFS_9==5	&	l8.PFS_FI_ppml==0	//	if food secure in t-8, it takes value 0 regardless of future
		replace	`var'=1	if	num_nonmiss_PFS_9==5	&	l8.PFS_FI_ppml==1	&	l6.PFS_FI_ppml==0	//	food insecure in t-8, but secure in t-6 (doesn't matter later status)
		replace	`var'=2	if	num_nonmiss_PFS_9==5	&	l8.PFS_FI_ppml==1	&	l6.PFS_FI_ppml==1	&	l4.PFS_FI_ppml==0	//	food insecure in t-8 and t-6, but not in t-4
		replace	`var'=3	if	num_nonmiss_PFS_9==5	&	l8.PFS_FI_ppml==1	&	l6.PFS_FI_ppml==1	&	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==0	//	food insecure in t-8, t-6, t-4 (not t-2)
		replace	`var'=4	if	num_nonmiss_PFS_9==5	&	l8.PFS_FI_ppml==1	&	l6.PFS_FI_ppml==1	&	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	&	PFS_FI_ppml==0	//	food insecure in t-8, t-6, t-4 and t-2 (not t0)
		replace	`var'=5	if	num_nonmiss_PFS_9==5	&	l8.PFS_FI_ppml==1	&	l6.PFS_FI_ppml==1	&	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	&	PFS_FI_ppml==1		//	food insecure in t-8, t-6, t-4 and t-2 (not t0)
		lab	var	`var'	"Spell length (9-year)"
		
		
		
		/*	{	This code consideres FI in later periods. For example, if individual is FS in t-4 but FI in t-2 and t, SL5=2	
			*	SL_5=1 if FI in any of the last 5 years (t, t-2 or t-4)
		gen		`var'=.
		replace	`var'=0	if	!mi(l4.PFS_FI_ppml)	&	l4.PFS_FI_ppml!=1	//	Food secure in t-4
		replace	`var'=0	if	!mi(l2.PFS_FI_ppml)	&	l2.PFS_FI_ppml!=1	//	Food secure in t-2
		replace	`var'=0	if	!mi(PFS_FI_ppml)	&	PFS_FI_ppml!=1			//	Food secure in t
	
		replace	`var'=1	if	!mi(l4.PFS_FI_ppml)	&	l4.PFS_FI_ppml==1	//	Food insecure in t-4
		replace	`var'=1	if	!mi(l2.PFS_FI_ppml)	&	l2.PFS_FI_ppml==1	//	Food insecure in t-2
		replace	`var'=1	if	!mi(PFS_FI_ppml)	&	PFS_FI_ppml==1			//	Food insecure in t
	
		*	SL_5=2	if	HH experience FI in "past" two consecutive rounds (t-4, t-2) or (t-2, t)
		replace	`var'=2	if	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	//	Food insecure in t-4 AND t-2
		replace	`var'=2	if	l2.PFS_FI_ppml==1	&	PFS_FI_ppml==1	//	Food insecure in t-2 AND t
		
		*	SL_5=3	if HH experience FI in "past" three consecutive rounds
		replace	`var'=3	if	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	&	PFS_FI_ppml==1	//	Food insecure in (t-4, t-2 AND t)
		}	*/
	
		
	
		/*
		
		*	SL_5=2	if	HH experience FI in two consecutive rounds
		replace	`var'=2	if	PFS_FI_ppml==1	&	f2.PFS_FI_ppml==1	//	Use "f2" to utilize the data with biennial frequency. For 1997 data, "f2" retrieves 1999 data.
		
		*	SL_5=3	if HH experience FI in three consecutive rounds
		replace	`var'=3	if	PFS_FI_ppml==1	&	f2.PFS_FI_ppml==1	&	f4.PFS_FI_ppml==1	
		
		lab	var	`var'	"# of consecutive FI incidences over the next 5 years (0-3)"
	
		*	SPL=4	if HH experience FI in four consecutive years
		replace	`var'=4	if	PFS_FI_ppml==1	&	f1.PFS_FI_ppml==1	&	f2.PFS_FI_ppml==1	&	f3.PFS_FI_ppml==1	&	(inrange(year,1977,1984)	|	inrange(year,1990,1994))	//	For years with 4 consecutive years of observations available
		*replace	`var'=4	if	PFS_FI_ppml==1	&	f3.PFS_FI_ppml==1	&	year==1987	//	If HH experienced FI in 1987 and 1990
		
		*	SPL=5	if	HH experience FI in 5 consecutive years
		*	Note: It cannot be constructed in 1987, as all of the 4 consecutive years (1988-1991) are missing.
		*	Issue: 1994/1996 cannot have value 5 as it does not observe 1998/2000 status when the PSID was not conducted.  Thus, I impose the assumption mentioned here
			*	For 1994, SPL=5 if HH experience FI in 94, 95, 96, 97 and 99 (assuming it is also FI in 1998)
			*	For 1996, SPL=5 if HH experience FI in 96, 97, 99, and 01 (assuming it is also FI in 98 and 00)
		replace	`var'=5	if	PFS_FI_ppml==1	&	f1.PFS_FI_ppml==1	&	f2.PFS_FI_ppml==1	&	f3.PFS_FI_ppml==1	&	f4.PFS_FI_ppml==1	&	(inrange(year,1977,1983)	|	inrange(year,1992,1993))	//	For years with 5 consecutive years of observations available
		replace	`var'=5	if	PFS_FI_ppml==1	&	f1.PFS_FI_ppml==1	&	f2.PFS_FI_ppml==1	&	f4.PFS_FI_ppml==1	&	year==1995	//	For years with 5 consecutive years of observations available	
		replace	`var'=5	if	PFS_FI_ppml==1	&	f2.PFS_FI_ppml==1	&	f4.PFS_FI_ppml==1	&	inrange(year,1997,2015)
		*/
		
	
		
			
		
		*	Permanent approach (TFI and CFI)
		
			*	To construct CFI (Chronic Food Insecurity), we need average PFS over time at unit-level
			*	Since I use different reference period of non-missing PFS, we cannot simply use "mean" function.
			*	We add-up all non-missing PFS over time at household-level, and divide it by cut-off PFS of those non-missing years.
			
			*	Aggregate PFS and PFS_FI over time (numerator)
			*	(2023-09-08) Use if all values aggregated are non-missing (balanced).
				
				foreach	var	in	PFS_ppml	PFS_FI_ppml	{
					
					cap	drop	`var'_total_5
					cap	drop	`var'_total_7
					cap	drop	`var'_total_9
					
					gen	`var'_total_5	=.	if	num_nonmiss_PFS_5!=3
					gen	`var'_total_7	=.	if	num_nonmiss_PFS_7!=4
					gen	`var'_total_9	=.	if	num_nonmiss_PFS_9!=5
					
					replace	`var'_total_5		=	l4.`var'	+	l2.`var'	+	`var'	if	num_nonmiss_PFS_5==3
					replace	`var'_total_7		=	l6.`var'	+	l4.`var'	+	l2.`var'	+	`var'	if	num_nonmiss_PFS_7==4
					replace	`var'_total_9		=	l8.`var'	+	l6.`var'	+	l4.`var'	+	l2.`var'	+	`var'	if	num_nonmiss_PFS_9==5
					
					lab	var	`var'_total_5	"`var' (5-year aggregate)"
					lab	var	`var'_total_7	"`var' (7-year aggregate)"
					lab	var	`var'_total_9	"`var' (9-year aggregate)"
				}
				
			
			
			
			*	Generate (normalized) mean-PFS by dividing the numerator into the denominator (Check Calvo & Dercon (2007), page 19)
			*	(2023-09-08) Since I used balanced observations only, I can simply divide it by ${PFS_cutoff} * years of aggregation
				cap	drop	PFS_ppml_mean_normal_5
				cap	drop	PFS_ppml_mean_normal_7
				cap	drop	PFS_ppml_mean_normal_9
				
				gen		PFS_ppml_mean_normal_5	=	PFS_ppml_total_5	/	(${PFS_cutoff}*3)
				gen		PFS_ppml_mean_normal_7	=	PFS_ppml_total_7	/	(${PFS_cutoff}*4)
				gen		PFS_ppml_mean_normal_9	=	PFS_ppml_total_9	/	(${PFS_cutoff}*5)
			
				lab	var		PFS_ppml_mean_normal_5	"Normalized mean PFS (5 year)"
				lab	var		PFS_ppml_mean_normal_7	"Normalized mean PFS (7 year)"
				lab	var		PFS_ppml_mean_normal_9	"Normalized mean PFS (9 year)"
			
			
			
			
			
			*	Construct SFIG
			*	The following three variables have no variation across different reference period; only one for obs.
			cap	drop	PFS_ppml_normal
			cap	drop	FIG_indiv
			cap	drop	SFIG_indiv
			
			
			gen	double	PFS_ppml_normal	=.	
			gen	double	FIG_indiv	=.
			gen	double	SFIG_indiv	=.
			
			
			
				*	Normalized PFS (PFS/threshold PFS)	(PFSit/PFS_underbar_t)
				replace	PFS_ppml_normal	=	PFS_ppml	/	${PFS_cutoff}
								
				*	Inner term of the food security gap (FIG) and the squared food insecurity gap (SFIG)
				replace	FIG_indiv	=	(1-PFS_ppml_normal)^1	if	!mi(PFS_ppml_normal)	&	PFS_ppml_normal<1	//	PFS_ppml<${PFS_cutoff}
				replace	FIG_indiv	=	0						if	!mi(PFS_ppml_normal)	&	PFS_ppml_normal>=1	//	PFS_ppml>=${PFS_cutoff}
				replace	SFIG_indiv	=	(1-PFS_ppml_normal)^2	if	!mi(PFS_ppml_normal)	&	PFS_ppml_normal<1	//	PFS_ppml<${PFS_cutoff}
				replace	SFIG_indiv	=	0						if	!mi(PFS_ppml_normal)	&	PFS_ppml_normal>=1	//	PFS_ppml>=${PFS_cutoff}
				
				
			*	Total, Transient and Chronic FI
			
				*	Total FI	(Average HCR/SFIG over time)
				cap	drop	TFI_HCR_5
				cap	drop	TFI_HCR_7
				cap	drop	TFI_HCR_9
				
				cap	drop	TFI_FIG_5
				cap	drop	TFI_FIG_7
				cap	drop	TFI_FIG_9
				
				cap	drop	TFI_SFIG_5
				cap	drop	TFI_SFIG_7
				cap	drop	TFI_SFIG_9
				
				gen	TFI_HCR_5	=	(PFS_FI_ppml_total_5	/ 3	)								if	num_nonmiss_PFS_5==3	//	Average headcount ratio
				gen	TFI_HCR_7	=	(PFS_FI_ppml_total_7	/ 4	)								if	num_nonmiss_PFS_7==4	//	Average headcount ratio
				gen	TFI_HCR_9	=	(PFS_FI_ppml_total_9	/ 5	)								if	num_nonmiss_PFS_9==5	//	Average headcount ratio
				
				gen	TFI_FIG_5	=	(l4.FIG_indiv	+	l2.FIG_indiv	+	FIG_indiv) / 3											if	num_nonmiss_PFS_5==3
				gen	TFI_FIG_7	=	(l6.FIG_indiv	+	l4.FIG_indiv	+	l2.FIG_indiv	+	FIG_indiv) / 4						if	num_nonmiss_PFS_7==4
				gen	TFI_FIG_9	=	(l8.FIG_indiv	+	l6.FIG_indiv	+	l4.FIG_indiv	+	l2.FIG_indiv	+	FIG_indiv) / 5	if	num_nonmiss_PFS_9==5
				
				gen	TFI_SFIG_5	=	(l4.SFIG_indiv	+	l2.SFIG_indiv	+	SFIG_indiv) / 3											if	num_nonmiss_PFS_5==3
				gen	TFI_SFIG_7	=	(l6.SFIG_indiv	+	l4.SFIG_indiv	+	l2.SFIG_indiv	+	SFIG_indiv) / 4						if	num_nonmiss_PFS_7==4
				gen	TFI_SFIG_9	=	(l8.SFIG_indiv	+	l6.SFIG_indiv	+	l4.SFIG_indiv	+	l2.SFIG_indiv	+	SFIG_indiv) / 5	if	num_nonmiss_PFS_9==5
				
				
				label	var	TFI_HCR_5	"TFI (HCR): 5-year"
				label	var	TFI_HCR_7	"TFI (HCR): 7-year"
				label	var	TFI_HCR_9	"TFI (HCR): 9-year"
				
				label	var	TFI_FIG_5	"TFI (FIG): 5-year"
				label	var	TFI_FIG_7	"TFI (FIG): 7-year"
				label	var	TFI_FIG_9	"TFI (FIG): 9-year"
				
				label	var	TFI_SFIG_5	"TFI (SFIG): 5-year"
				label	var	TFI_SFIG_7	"TFI (SFIG): 7-year"
				label	var	TFI_SFIG_9	"TFI (SFIG): 9-year"
				
				
				*	Chronic FI (SFIG(with mean PFS))	
				*	CFI can be easily created by loop
				foreach	year	in	5	7	9	{
				
					cap	drop	CFI_HCR_`year'
					cap	drop	CFI_FIG_`year'
					cap	drop	CFI_SFIG_`year'
					
					gen		CFI_HCR_`year'=.
					gen		CFI_FIG_`year'=.
					gen		CFI_SFIG_`year'=.
					
					replace	CFI_HCR_`year'	=	(1-PFS_ppml_mean_normal_`year')^0	if	!mi(PFS_ppml_mean_normal_`year')	&	PFS_ppml_mean_normal_`year'<1	//	Normalized mean-PFS < 1
					replace	CFI_FIG_`year'	=	(1-PFS_ppml_mean_normal_`year')^1	if	!mi(PFS_ppml_mean_normal_`year')	&	PFS_ppml_mean_normal_`year'<1	//	Normalized mean-PFS < 1
					replace	CFI_SFIG_`year'	=	(1-PFS_ppml_mean_normal_`year')^2	if	!mi(PFS_ppml_mean_normal_`year')	&	PFS_ppml_mean_normal_`year'<1	//	Normalized mean-PFS < 1
					
					
					replace	CFI_HCR_`year'	=	0								if	!mi(PFS_ppml_mean_normal_`year')	&	PFS_ppml_mean_normal_`year'>=1	//	Normalized mean-PFS >= 1 (thus zero CFI)
					replace	CFI_FIG_`year'	=	0								if	!mi(PFS_ppml_mean_normal_`year')	&	PFS_ppml_mean_normal_`year'>=1	//	Normalized mean-PFS >= 1 (thus zero CFI)
					replace	CFI_SFIG_`year'	=	0								if	!mi(PFS_ppml_mean_normal_`year')	&	PFS_ppml_mean_normal_`year'>=1	//	Normalized mean-PFS >= 1 (thus zero CFI)
					
					lab	var		CFI_HCR_`year'	"CFI (HCR): `year'-year"
					lab	var		CFI_FIG_`year'	"CFI (FIG): `year'-year"
					lab	var		CFI_SFIG_`year'	"CFI (SFIG): `year'-year"
				
				}
				
				
				
			** OLD code
			/*
			
			*	Add non-missing PFS of later periods
			foreach time in 0 2 4	{
				
				replace	PFS_ppml_total		=	PFS_ppml_total		+	l`time'.PFS_ppml	if	!mi(l`time'.PFS_ppml)
				replace	PFS_FI_ppml_total	=	PFS_FI_ppml_total	+	l`time'.PFS_FI_ppml	if	!mi(l`time'.PFS_FI_ppml)
				
			}
			
			*	Replace aggregated value as missing, if all PFS values are missing over the 5-year period.
			replace	PFS_ppml_total=.		if	num_nonmissing_PFS==0
			replace	PFS_FI_ppml_total=.	if	num_nonmissing_PFS==0
			
			lab	var	PFS_ppml_total		"Aggregated PFS over 5 years"
			lab	var	PFS_FI_ppml_total	"Aggregated FI incidence over 5 years"
			
			*	Generate denominator by aggregating cut-off probability over time
			*	Since I currently use 0.5 as a baseline threshold probability, it should be (0.5 * the number of non-missing PFS)
			cap	drop	PFS_threshold_ppml_total
			gen			PFS_threshold_ppml_total	=	0.5	*	num_nonmissing_PFS
			lab	var		PFS_threshold_ppml_total	"Sum of PFS over time"
			
			*	Generate (normalized) mean-PFS by dividing the numerator into the denominator (Check Calvo & Dercon (2007), page 19)
			cap	drop	PFS_ppml_mean_normal
			gen			PFS_ppml_mean_normal	=	PFS_ppml_total	/	PFS_threshold_ppml_total
			lab	var		PFS_ppml_mean_normal	"Normalized mean PFS"
			
			
			*	Construct SFIG
			cap	drop	FIG_indiv
			cap	drop	SFIG_indiv
			cap	drop	PFS_ppml_normal
			gen	double	FIG_indiv=.
			gen	double	SFIG_indiv	=.
			gen	double PFS_ppml_normal	=.				
					
				br	x11101ll	year	num_nonmissing_PFS	PFS_ppml	PFS_FI_ppml PFS_ppml_total PFS_threshold_ppml_total	FIG_indiv	SFIG_indiv	PFS_ppml_normal	PFS_ppml_mean_normal
				
				*	Normalized PFS (PFS/threshold PFS)	(PFSit/PFS_underbar_t)
				replace	PFS_ppml_normal	=	PFS_ppml	/	0.5
				
				*	Inner term of the food security gap (FIG) and the squared food insecurity gap (SFIG)
				replace	FIG_indiv	=	(1-PFS_ppml_normal)^1	if	!mi(PFS_ppml_normal)	&	PFS_ppml_normal<1	//	PFS_ppml<0.5
				replace	FIG_indiv	=	0						if	!mi(PFS_ppml_normal)	&	PFS_ppml_normal>=1	//	PFS_ppml>=0.5
				replace	SFIG_indiv	=	(1-PFS_ppml_normal)^2	if	!mi(PFS_ppml_normal)	&	PFS_ppml_normal<1	//	PFS_ppml<0.5
				replace	SFIG_indiv	=	0						if	!mi(PFS_ppml_normal)	&	PFS_ppml_normal>=1	//	PFS_ppml>=0.5
			
				
			*	Total, Transient and Chronic FI
			
				*	Total FI	(Average HCR/SFIG over time)
				cap	drop	TFI_HCR
				cap	drop	TFI_FIG
				cap	drop	TFI_SFIG
				
				gen	TFI_HCR		=	PFS_FI_ppml_total	/	num_nonmissing_PFS		
				gen	TFI_FIG		=	0
				gen	TFI_SFIG	=	0
				
				foreach time in 0 2 4	{
					
					replace	TFI_FIG		=	TFI_FIG		+	f`time'.FIG_indiv	if	!mi(f`time'.PFS_ppml)
					replace	TFI_SFIG	=	TFI_SFIG	+	f`time'.SFIG_indiv	if	!mi(f`time'.PFS_ppml)
					
				}
				
				*	Divide by the number of non-missing PFS (thus non-missing FIG/SFIG) to get average value
				replace	TFI_FIG		=	TFI_FIG		/	num_nonmissing_PFS
				replace	TFI_SFIG	=	TFI_SFIG	/	num_nonmissing_PFS
				
				*	Replace with missing if all PFS are missing.
				replace	TFI_HCR=.	if	num_nonmissing_PFS==0
				replace	TFI_FIG=.	if	num_nonmissing_PFS==0
				replace	TFI_SFIG=.	if	num_nonmissing_PFS==0
					
				*bys	fam_ID_1999:	egen	Total_FI_HCR	=	mean(PFS_FI_ppml)	if	inrange(year,2,10)	//	HCR
				*bys	fam_ID_1999:	egen	Total_FI_SFIG	=	mean(SFIG_indiv)	if	inrange(year,2,10)	//	SFIG
				
				label	var	TFI_HCR		"TFI (HCR)"
				label	var	TFI_FIG		"TFI (FIG)"
				label	var	TFI_SFIG	"TFI (SFIG)"

				*	Chronic FI (SFIG(with mean PFS))					
				gen		CFI_HCR=.
				gen		CFI_FIG=.
				gen		CFI_SFIG=.
				replace	CFI_HCR		=	(1-PFS_ppml_mean_normal)^0	if	!mi(PFS_ppml_mean_normal)	&	PFS_ppml_mean_normal<1	//	Avg PFS < Avg cut-off PFS
				replace	CFI_FIG		=	(1-PFS_ppml_mean_normal)^1	if	!mi(PFS_ppml_mean_normal)	&	PFS_ppml_mean_normal<1	//	Avg PFS < Avg cut-off PFS
				replace	CFI_SFIG	=	(1-PFS_ppml_mean_normal)^2	if	!mi(PFS_ppml_mean_normal)	&	PFS_ppml_mean_normal<1	//	Avg PFS < Avg cut-off PFS
				replace	CFI_HCR		=	0							if	!mi(PFS_ppml_mean_normal)	&	PFS_ppml_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
				replace	CFI_FIG		=	0							if	!mi(PFS_ppml_mean_normal)	&	PFS_ppml_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
				replace	CFI_SFIG	=	0							if	!mi(PFS_ppml_mean_normal)	&	PFS_ppml_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
				
				lab	var		CFI_HCR		"CFI (HCR)"
				lab	var		CFI_FIG		"CFI (FIG)"
				lab	var		CFI_SFIG	"CFI (SFIG)"
				
				*/
				
		*	Eyeballing results
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 SL_5 SL_7 SL_9	//	PFS_ppml_total_5 PFS_ppml_total_7 PFS_ppml_total_9
		
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 PFS_ppml_total_5 PFS_ppml_total_7 PFS_ppml_total_9	PFS_ppml_mean_normal_5 PFS_ppml_mean_normal_7 PFS_ppml_mean_normal_9
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 PFS_FI_ppml_total_5 PFS_FI_ppml_total_7 PFS_FI_ppml_total_9
		
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 PFS_ppml_normal SFIG_indiv FIG_indiv
		
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 PFS_FI_ppml_total_?	TFI_HCR_5 TFI_HCR_7 TFI_HCR_9	
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 FIG_indiv	TFI_FIG_5 TFI_FIG_7 TFI_FIG_9
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 SFIG_indiv	TFI_SFIG_5 TFI_SFIG_7 TFI_SFIG_9
		
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 PFS_ppml_mean_normal_?	CFI_HCR_?
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 PFS_ppml_mean_normal_?	CFI_FIG_?
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	num_nonmiss_PFS_5 num_nonmiss_PFS_7 num_nonmiss_PFS_9 PFS_ppml_mean_normal_?	CFI_SFIG_?
		
		*	Save
		compress
		save    "${SNAP_dtInt}/SNAP_const",	replace
		
	
	}
	
	