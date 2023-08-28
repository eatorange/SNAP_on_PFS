
	/*****************************************************************
	PROJECT: 		SNAP of FS
					
	TITLE:			SNAP_construct
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Jan 14, 2023 by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	x11101ll        // 1999 Family ID

	DESCRIPTION: 	Construct PFS and FSD variables
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Construct PFS
					2 - Construct FSD variables
					
	INPUTS: 		* SNAP cleaned data
					${SNAP_dtInt}/SNAP_cleaned_long.dta
										
	OUTPUTS: 		* PSID constructed data (with PFS and FSD variables)						
					${SNAP_dtInt}/SNAP_const.dta
					

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
	loc	name_do	SNAP_construct
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${SNAP_doCln}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	*	Determine which part of the code to be run
	local	PFS_const_9713	0	//	Construct PFS from cleaned data
	local	PFS_const_9713	1	//	Construct FSD from PFS
	
	/****************************************************************
		SECTION 1: Construct PFS
	****************************************************************/	
		
	*	Construct PFS
	*	Please check "SNAP_PFS_const_test.do" file for the rational behind PFS model selection
	if	`PFS_const'==1	{
	 
		use    "${SNAP_dtInt}/SNAP_cleaned_long_9713",	clear
	
		
		*	(2023-06-11) Chris suggested to keep them, so we keep it for now.
		*	(2023-05-21) Now keep only 1997-2015 data which I have SNAP policy index
		*keep	if	inrange(year,1997,2013)
		
		*	Drop states outside 48 continental states (HA/AK/inapp/etc.), as we do not have their TFP cost information.
		drop	if	inlist(rp_state,0,50,51,99)
		
		*	(2023-08-27) Keep only those whos income ever below 130 (about 34% belong to this case)
		keep	if	income_ever_below_130_9513==1
					
	
		*	Set globals
		global	statevars		l2_foodexp_tot_inclFS_pc_1_real l2_foodexp_inclFS_pc_2_real_K
		global	demovars		rp_age rp_age_sq	rp_nonWhite	rp_married	/*rp_female*/ //	 Female is perfectly collinear with household-FE?
		global	eduvars			rp_NoHS rp_somecol rp_col
		global	empvars			rp_employed
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child
		global	econvars		ln_fam_income_pc_real	
		// global	foodvars		FS_rec_wth	//	Should I use prected FS redemption from 1st-stage IV?, or even drop it for exclusion restriction?
		// global	macrovars		unemp_rate	CPI
		global	regionvars		rp_state_enum1-rp_state_enum30 rp_state_enum32-rp_state_enum49 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1979) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
					
					
		*label	var	FS_rec_wth	"SNAP received"
		label	var	foodexp_tot_inclFS_pc			"Food exp (with FS benefit)"
		label	var	l2_foodexp_tot_inclFS_pc_1_real	"Food Exp in t-2"
		label	var	l2_foodexp_inclFS_pc_2_real_K	"(Food Exp in t-2)$^2$ (K)"
		label	var	foodexp_tot_inclFS_pc_real		"Food exp (with FS benefit) (real)"
		label	var	l2_foodexp_tot_exclFS_pc_1_real	"Food Exp in t-2 (real)"
		label	var	l2_foodexp_tot_exclFS_pc_2_real	"(Food Exp in t-2)$^2$ (real)"	
		label	var	rp_age		"Age (RP)"
		label	var	rp_age_sq	"Age$^2$ (RP)/1000"
		*label	var	change_RP	"RP changed"
		label	var	ln_fam_income_pc_real "ln(per capita income)"
	
		
	
		*	Declare variables (food expenditure per capita, real value)
		global	depvar		foodexp_tot_inclFS_pc_real	/*IHS_foodexp*/
		
			*	Summary state of dep.var
			summ	${depvar}, d

		*	Step 1
		*	Compared to Lee et al. (2021), I changed as followings
			*	I exclude a binary indicator whether HH received SNAP or not (FS_rec_wth), as including it will violate exclusion restriction of IV
			*	I do NOT use survey structure (but still use weight)
			*	I use Poisson quasi-MLE estimation, instead of ppml with Gamma in the original PFS paper
			*	I include individual-FE
			*	Please refer to "SNAP_PFS_const_test.do" file for more detail.
			
			*	All sample
			ppmlhdfe	${depvar}	${statevars}	${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[pweight=wgt_long_fam],	///
				absorb(x11101ll	ib31.rp_state ib1997.year) vce(cluster x11101ll) d	
			
			ereturn list
			est	sto	ppml_step1
				
			*	Predict fitted value and residual
			gen	ppml_step1_sample=1	if	e(sample)==1 // e(sample) includes both subpopulation and non-subpopulation, so we need to include subpop condition here to properly restrict regression sample.
			predict double mean1_foodexp_ppml				if	ppml_step1_sample==1
			predict double e1_foodexp_ppml					if	ppml_step1_sample==1,r
			gen e1_foodexp_sq_ppml = (e1_foodexp_ppml)^2	if	ppml_step1_sample==1
		
		
			
		/*
		
			*	Issue: mean in residuals are small, but standard deviation is large, meaning greater dispersion in residual.
			*	It implies that 1st-stage is not working well in predicting mean.
			summ	foodexp_tot_inclFS_pc	mean1_foodexp_ppml	e1_foodexp_ppml	e1_foodexp_sq_ppml
			summ	e1_foodexp_ppml,d
			
			
			*	As a robustness check, run step 1 "with" FS redemption (just like Lee et al. (2021)) and compare the variation captured.
			svy: ppml 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	/*${indvars}*/	${regionvars}	${timevars}	, family(gamma)	link(log)
			ereturn list
			est	sto	ppml_step1_withFS
			
			*	Without income and FS redemption
			svy: ppml 	`depvar'	${statevars}	${demovars}	/*${econvars}*/	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}	${indvars}*/	${regionvars}	${timevars}	, family(gamma)	link(log)
			ereturn list
			est	sto	ppml_step1_woFS_woinc
								
			*	Output robustness check (comparing step 1 w/o FS and with FS)
			esttab	ppml_step1_withFS	ppml_step1	ppml_step1_woFS_woinc	using "${SNAP_outRaw}/ppml_pooled_FS.csv", ///
					cells(b(star fmt(%8.2f)) se(fmt(2) par)) stats(N_sub /*r2*/) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					title(Conditional Mean of Food Expenditure per capita (with and w/o FS)) 	replace
					
			esttab	ppml_step1_withFS	ppml_step1	ppml_step1_woFS_woinc	using "${SNAP_outRaw}/ppml_pooled_FS.tex", ///
					cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub, fmt(%8.0fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean of Food Expenditure per capita (with and w/o FS))		replace	
		*/
		br x11101ll year ${depvar} mean1_foodexp_ppml e1_foodexp_ppml e1_foodexp_sq_ppml
		
		*	Step 2
		*	(2023-1-18) Possion with FE now converges, and it does better job compared to Gaussian regression. So we use it.
		local	depvar	e1_foodexp_sq_ppml
		
			*	Poisson quasi-MLE
			ppmlhdfe	`depvar'	${statevars} ${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	[pweight=wgt_long_fam], ///
				absorb(x11101ll ib31.rp_state ib1997.year) vce(cluster x11101ll) d	
			est store ppml_step2
			gen	ppml_step2_sample=1	if	e(sample)==1 
			predict	double	var1_foodexp_ppml	if	ppml_step2_sample==1	// (2023-06-21) Poisson quasi-MLE does not seem to generate negative predicted value, which is good (no need to square them)
			gen	sd_foodexp_ppml	=	sqrt(abs(var1_foodexp_ppml))	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
			gen	error_var1_ppml	=	abs(var1_foodexp_ppml - e1_foodexp_sq_ppml)	//	prediction error. 
			
	
		
		*	Output
		**	For AER manuscript, we omit asterisk(*) to display significance as AER requires not to use.
		**	If we want to diplay star, renable "star" option inside "cells" and "star(* 0.10 ** 0.05 *** 0.01)"
		
			esttab	ppml_step1	ppml_step2	using "${SNAP_outRaw}/ppml_pooled.csv", ///
					cells(b(star fmt(%8.2f)) se(fmt(2) par)) stats(N_sub /*r2*/) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					title(Conditional Mean and Variance of Food Expenditure per capita) 	replace
					
			esttab	ppml_step1	ppml_step2	using "${SNAP_outRaw}/ppml_pooled.tex", ///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub, fmt(%8.0fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean and Variance of Food Expenditure per capita)		replace		
			
			
		
		*	Step 3
			
			*	Gamma
			*	(2021-11-28) I temporarily don't use expected residual (var1_foodexp_ppml) as it goes crazy. I will temporarily use expected residual from step 1 (e1_foodexp_sq_ppml)
			*	(2021-11-30) It kinda works after additional cleaning (ex. dropping Latino sample), but its distribution is kinda different from what we saw in PFS paper.
			gen alpha1_foodexp_pc_ppml	= (mean1_foodexp_ppml)^2 / var1_foodexp_ppml	//	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_ppml	= var1_foodexp_ppml / mean1_foodexp_ppml		//	scale parameter of Gamma (beta)
			
						
			*	The  code below is a temporary code to see what is going wrong in the original code. I replaced expected value of residual squared with residual squared
			*gen alpha1_foodexp_pc_ppml	= (mean1_foodexp_ppml)^2 / e1_foodexp_sq_ppml	//	shape parameter of Gamma (alpha)
			*gen beta1_foodexp_pc_ppml	= e1_foodexp_sq_ppml / mean1_foodexp_ppml		//	scale parameter of Gamma (beta)
			
			*	Generate PFS by constructing CDF
			*	I create two versions - without COLI and with COLI.
			*	(2023-Only 79 obs have missing COLI, so I will use COLI as main outcome variable
			
/*
				*	Without COLI adjustment (used for PFS descriptive paper)
				global	TFP_threshold	foodexp_W_TFP_pc_real	/*IHS_TFP*/
				cap	drop	PFS_ppml_noCOLI
				gen			PFS_ppml_noCOLI = gammaptail(alpha1_foodexp_pc_ppml, ${TFP_threshold}/beta1_foodexp_pc_ppml)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_ppml_noCOLI "PFS (w/o COLI)"
			
*/
				*	With COLI adjustment (main caufal inference)
				global	TFP_threshold	foodexp_W_TFP_pc_COLI_real	/*IHS_TFP*/
				cap	drop	PFS_ppml
				gen 		PFS_ppml	 = gammaptail(alpha1_foodexp_pc_ppml, ${TFP_threshold}/beta1_foodexp_pc_ppml)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_ppml "PFS"
			
			*	Generate lagged PFS
			foreach	var	in	PFS_ppml	/*PFS_ppml_noCOLI*/		{
				
				loc	varlabel:	var	label	`var'
				
				cap	drop	l2_`var'
				gen	l2_`var'	=	l2.`var'
				lab	var	l2_`var'	"(L2) `varlabel'"
				
				cap	drop	l4_`var'
				gen	l4_`var'	=	l4.`var'
				lab	var	l4_`var'	"(L4) `varlabel'"
				
			}


			
					
			*	Normal (to show the robustness of the distributional assumption)
			/*
			gen thresh_foodexp_normal=(foodexp_W_TFP_pc_real-mean1_foodexp_ppml)/sd_foodexp_ppml	// Let 2 as threshold
			gen prob_below_TFP=normal(thresh_foodexp_normal)
			gen PFS_normal		=	1 - prob_below_TFP
			
			graph twoway (kdensity PFS_ppml) (kdensity PFS_normal)
			*/
		
		*	Construct FI indicator based on PFS
		*	For now we use threshold probability as 0.6, referred from Lee et al. (2021) where threshold varied from 0.55 to 0.6
		
		loc	var	PFS_FI_ppml
		cap	drop	`var'
		gen		`var'=.
		replace	`var'=0	if	!mi(PFS_ppml)	&	!inrange(PFS_ppml,0,0.6)
		replace	`var'=1	if	!mi(PFS_ppml)	&	inrange(PFS_ppml,0,0.6)
		lab	var	`var'	"HH is food insecure (PFS < 0.6)"
		
	
		save    "${SNAP_dtInt}/SNAP_long_PFS_9713",	replace
		
		*	Regress PFS on characteristics
		*	(2023-1-18) This one needs to be re-visited, considering what regression method we will use (svy prefix, weight, fixed effects, etc.)
		*	(2023-8-20) Re-visited. Make sure to do this regression on the final sapmle (non-missing PFS, income ever below 200, balaned b/w 9713, etc). I set the default counter as zero to run manually, until it is moved to other dofile.
		use    "${SNAP_dtInt}/SNAP_long_PFS_9713",	clear	
		local	run_PFS_reg=1
		if	`run_PFS_reg'==1	{
			
			
			*	No SNAP status, no individual FE
			local	depvar	PFS_ppml
			
			svy:	reg	`depvar'	rp_female	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	ib31.rp_state	ib1997.year 
			reghdfe	`depvar'		rp_female	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	[pw=wgt_long_fam], absorb(rp_state year)
			
			
			svy:	reg	`depvar'	rp_female
			reghdfe	PFS_ppml rp_female	[pw=wgt_long_fam], noabsorb
			
			svy:	reg	`depvar'	rp_female	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	ib31.rp_state	ib1997.year 
			
			
			reghdfe	PFS_ppml rp_female	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	[pw=wgt_long_fam], absorb(rp_state year)
				reghdfe	PFS_ppml rp_female	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	[pw=wgt_long_fam], absorb(rp_state year	x11101ll)
			
			
			
			svy, subpop(if !mi(`depvar')):	///
				reg	`depvar'	rp_female	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	ib31.rp_state	ib1997.year 
			est	store	PFS_noSNAP_all	
			estadd	local	state_year_FE	"Y"
			svy, subpop(if !mi(`depvar')):	mean	PFS_ppml		//	Need to think about how to add this usign "estadd"....
			
			*	reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars} [aweight=wgt_long_fam_adj]	//	Coefficients are sampe, but different Sterror.
			
			*	SNAP status, state and year FE, all sapmle
			svy, subpop(if !mi(PFS_ppml)):	///
				reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	ib31.rp_state	ib1997.year	FS_rec_wth	
			est	store	PFS_SNAP_all	
			estadd	local	state_year_FE	"Y"
			svy, subpop(if !mi(`depvar')):	mean	PFS_ppml	//	Need to think about how to add this usign "estadd"....
		
			
		*	Food Security Indicators and Their Correlates
			esttab	PFS_noSNAP_all	PFS_SNAP_all		using "${SNAP_outRaw}/Tab_3_PFS_association.csv", ///
					cells(b(star fmt(3)) se(fmt(2) par)) stats(N_sub r2 state_year_FE meanPFS, label("N" "R2" "State and Year FE" "Mean PFS")) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	drop(*.rp_state	*.year)	///
					title(PFS and household covariates) replace
					
					
			esttab	PFS_noSNAP_all	PFS_SNAP_all		using "${SNAP_outRaw}/Tab_3_PFS_association.tex", ///
					cells(b(star fmt(3)) & se(fmt(2) par)) stats(N_sub r2 state_year_FE	, label("N" "R2" "State and Year FE")) ///
					incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state*	year_enum*)			///
					/*cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	*/	///
					title(PFS and household covariates) replace
		
		}	//	run_PFS_reg
		
	}
	
	/****************************************************************
		SECTION 2: Construct FSD
	****************************************************************/	
	
	*	Construct dynamics variables
	if	`FSD_const'==1	{
		
		use	"${SNAP_dtInt}/SNAP_long_PFS_9713", clear
		
		*	Generate spell-related variables
		cap drop	_seq	_spell	_end
		tsspell, cond(year>=2 & PFS_FI_ppml==1)
		foreach	var	in	_seq	_spell	_end	{
		    
			replace	`var'=.	if	mi(PFS_FI_ppml)
			
		}
		
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	_seq	_spell	_end
		
	
		
		*	Before genering FSDs, generate the number of non-missing PFS values over the 5-year (PFS_t, PFS_t-2, PFS_t-4)
		*	It will vary from 0 to the full length of reference period (currently 3)
		loc	var	num_nonmissing_PFS
		cap	drop	`var'
		gen	`var'=0
		foreach time in 0 2 4	{
			
			replace	`var'	=	`var'+1	if	!mi(l`time'.PFS_ppml)

		}
		lab	var	`var'	"# of non-missing PFS over 5 years"
		
		
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
		gen		`var'=.
		replace	`var'=0	if	!mi(l4.PFS_FI_ppml)	&	l4.PFS_FI_ppml!=1	//	Food secure in t-4
		replace	`var'=1	if	!mi(l4.PFS_FI_ppml)	&	l4.PFS_FI_ppml==1	//	Food secure in t-4
		replace	`var'=2	if	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	//	Food insecure in t-4 AND t-2
		replace	`var'=3	if	l4.PFS_FI_ppml==1	&	l2.PFS_FI_ppml==1	&	PFS_FI_ppml==1	//	Food insecure in (t-4, t-2 AND t)
		
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
	
		
	
		lab	var	`var'	"# of consecutive FI incidences over the past 5 years (0-3)"
	
		br	x11101ll	year	PFS_ppml	PFS_FI_ppml	_seq	_spell	_end SL_5
		
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
		
			*	To construct CFI (Chronic Food Insecurity), we need average PFS over time at household-level.
			*	Since households have different number of non-missing PFS, we cannot simply use "mean" function.
			*	We add-up all non-missing PFS over time at household-level, and divide it by cut-off PFS of those non-missing years.
			
			*	Aggregate PFS and PFS_FI over time (numerator)
			cap	drop	PFS_ppml_total
			cap	drop	PFS_FI_ppml_total
			
			gen	PFS_ppml_total		=	0
			gen	PFS_FI_ppml_total	=	0
			
			*	Add non-missing PFS of later periods
			foreach time in 0 2 4	{
				
				replace	PFS_ppml_total		=	PFS_ppml_total		+	l`time'.PFS_ppml		if	!mi(l`time'.PFS_ppml)
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
		
		*	Save
		compress
		save    "${SNAP_dtInt}/SNAP_const",	replace
		
	}
	