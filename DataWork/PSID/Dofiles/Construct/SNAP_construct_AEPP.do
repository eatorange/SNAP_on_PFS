
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
	local	PFS_const_7919	1	//	Construct PFS from cleaned data
	
	
	/****************************************************************
		SECTION 1: Construct PFS
	****************************************************************/	
		
	*	Construct PFS
	*	Please check "SNAP_PFS_const_test.do" file for the rational behind PFS model selection
	if	`PFS_const_7919'==1	{
	 
		use    "${SNAP_dtInt}/SNAP_cleaned_long",	clear
		
		*	Validate that all observations in the data are in_sample and years b/w 1977 and 2019
		assert	in_sample==1
		assert	inrange(year,1977,2019)
		
		*	(2023-06-11) Chris suggested to keep them, so we keep it for now.
		*	(2023-05-21) Now keep only 1997-2015 data which I have SNAP policy index
		*keep	if	inrange(year,1997,2013)
		
		*	Drop states outside 48 continental states (HA/AK/inapp/etc.), as we do not have their TFP cost information.
		drop	if	inlist(rp_state,0,50,51,99)
		
		*	(2023-08-20) Keep only those whos income ever below 200 (more than 99% belong to this case)
		*	(2023-08-20) We do NOT impost income limit on AEPP construction
		*keep	if	income_ever_below_200==1
		
		*	Rescale large variable
		cap	drop	l2_foodexp_tot_inclFS_pc_2_real_K
		gen			l2_foodexp_inclFS_pc_2_real_K	=	l2_foodexp_tot_inclFS_pc_2_real / 1000
		
		*	Set globals
		global	statevars		l2_foodexp_tot_inclFS_pc_1_real l2_foodexp_inclFS_pc_2_real_K
		global	demovars		rp_age rp_age_sq	rp_nonWhte	rp_married	rp_female	
		global	eduvars			rp_NoHS rp_somecol rp_col
		global	empvars			rp_employed
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child
		global	econvars		ln_fam_income_pc_real	
		global	foodvars		FS_rec_wth	//	Should I use prected FS redemption from 1st-stage IV?, or even drop it for exclusion restriction?
		*global	macrovars		unemp_rate	CPI
		global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1979) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
					
					
		*label	var	FS_rec_wth	"SNAP received"
		label	var	foodexp_tot_inclFS_pc			"Food exp (with FS benefit)"
		label	var	l2_foodexp_tot_inclFS_pc_1_real		"Food Exp in t-2"
		label	var	l2_foodexp_inclFS_pc_2_real_K		"(Food Exp in t-2)$^2$ (K)"
		label	var	foodexp_tot_inclFS_pc_real		"Food exp (with FS benefit) (real)"
		label	var	l2_foodexp_tot_exclFS_pc_1_real	"Food Exp in t-2 (real)"
		label	var	l2_foodexp_tot_exclFS_pc_2_real	"(Food Exp in t-2)$^2$ (real)"	
		label	var	rp_age		"Age (RP)"
		label	var	rp_age_sq	"Age$^2$ (RP)/1000"
		label	var	change_RP	"RP changed"
		label	var	ln_fam_income_pc_real "ln(per capita income)"
		label	var	unemp_rate	"State Unemp Rate"
		*label	var	major_control_dem	"Dem state control"
		*label	var	major_control_rep	"Rep state control"
		
		*	Transformation of the outcome and thresholds
		*	(note: ln doesnt work under glmhdfe as the command does not accept zero values, and IHS-based IV estimates become less sensible, so we stick to the original food expenditure variable.)
		cap	drop	ln_foodexp	IHS_foodexp	ln_TFP	IHS_TFP
		gen	ln_foodexp	=	ln(foodexp_tot_inclFS_pc_real)
		gen	IHS_foodexp	=	asinh(foodexp_tot_inclFS_pc_real)
		gen	ln_TFP		=	ln(foodexp_W_TFP_pc_real)
		gen	IHS_TFP		=	asinh(foodexp_W_TFP_pc_real)
		
		*	Sample where PFS will be constructed upon
		*	They include (i) in_sample family (2) HH from 1978 to 2019
		*	(2023-1-18) I don't need this, as all sample are alrady in_sample and b/w 1977 and 2019
		*	global	PFS_sample		in_sample==1	&	inrange(year,1976,2019) 
		
		*	Declare variables (food expenditure per capita, real value)
		global	depvar		foodexp_tot_inclFS_pc_real	/*IHS_foodexp*/
		
			*	Summary state of dep.var
			summ	${depvar}, d
			*unique x11101ll if in_sample==1	&	!mi(foodexp_tot_inclFS_pc)
		
		*	Step 1
		*	Compared to Lee et al. (2021), I changed as followings
			*	I exclude a binary indicator whether HH received SNAP or not (FS_rec_wth), as including it will violate exclusion restriction of IV
			*	I do NOT use survey structure (but still use weight)
			*	I use Poisson quasi-MLE estimation, instead of GLM with Gamma in the original PFS paper
			*	I include individual-FE
			*	Please refer to "SNAP_PFS_const_test.do" file for more detail.
			
			*	All sample
			ppmlhdfe	${depvar}	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	[pweight=wgt_long_fam_adj], ///
				absorb(x11101ll ib31.rp_state ib1979.year) vce(cluster x11101ll) d	
			
			ereturn list
			est	sto	glm_step1
			*margins, dydx(*) post
			*est	sto	glm_step1_dydx
				
			*	Predict fitted value and residual
			gen	glm_step1_sample=1	if	e(sample)==1 // e(sample) includes both subpopulation and non-subpopulation, so we need to include subpop condition here to properly restrict regression sample.
			predict double mean1_foodexp_glm	if	glm_step1_sample==1
			predict double e1_foodexp_glm		if	glm_step1_sample==1,r
			gen e1_foodexp_sq_glm = (e1_foodexp_glm)^2	if	glm_step1_sample==1
			
		
		
		*	Step 2
		*	(2023-1-18) Possion with FE now converges, and it does better job compared to Gaussian regression. So we use it.
		local	depvar	e1_foodexp_sq_glm
		
			*	Poisson quasi-MLE
			ppmlhdfe	`depvar'	${statevars} ${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	[pweight=wgt_long_fam_adj], ///
				absorb(x11101ll ib31.rp_state ib1979.year) vce(cluster x11101ll) d	
			est store glm_step2
			*margins, dydx(*) post
			*est	sto	glm_step2_dydx
			
			gen	glm_step2_sample=1	if	e(sample)==1 
			predict	double	var1_foodexp_glm	if	glm_step2_sample==1	// (2023-06-21) Poisson quasi-MLE does not seem to generate negative predicted value, which is good (no need to square them)
			gen	sd_foodexp_glm	=	sqrt(abs(var1_foodexp_glm))	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
			gen	error_var1_glm	=	abs(var1_foodexp_glm - e1_foodexp_sq_glm)	//	prediction error. 
			*br	e1_foodexp_sq_glm	var1_foodexp_glm	error_var1_glm
			
	
		
		*	Output
		**	For AER manuscript, we omit asterisk(*) to display significance as AER requires not to use.
		**	If we want to diplay star, renable "star" option inside "cells" and "star(* 0.10 ** 0.05 *** 0.01)"
			/*
			esttab	glm_step1	glm_step2	using "${SNAP_outRaw}/GLM_pooled_7919.csv", ///
					cells(b(star fmt(%8.2f)) se(fmt(2) par)) stats(N_sub /*r2*/) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					title(Conditional Mean and Variance of Food Expenditure per capita) 	replace
					
			esttab	glm_step1	glm_step2	using "${SNAP_outRaw}/GLM_pooled_7919.tex", ///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub, fmt(%8.0fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean and Variance of Food Expenditure per capita)		replace		
			
			esttab	glm_step1_dydx	glm_step2_dydx	using "${SNAP_outRaw}/GLM_pooled_dydx_7919.csv", ///
					cells(b(star fmt(%8.2f)) se(fmt(2) par)) stats(N_sub /*r2*/) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					title(Conditional Mean and Variance of Food Expenditure per capita) 	replace
					
			esttab	glm_step1_dydx	glm_step2_dydx	using "${SNAP_outRaw}/GLM_pooled_dydx_7919.tex", ///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub, fmt(%8.0fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean and Variance of Food Expenditure per capita)		replace	
			
			
			esttab	glm_step1	glm_step2	glm_step1_dydx	glm_step2_dydx	using "${SNAP_outRaw}/GLM_pooled_all_dydx_7919.csv", ///
					cells(b(star fmt(%8.2f)) se(fmt(2) par)) stats(N, fmt(%8.0f) /*r2*/) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					title(Conditional Mean and Variance of Food Expenditure per capita) 	replace
					
			esttab	glm_step1	glm_step2	glm_step1_dydx	glm_step2_dydx	using "${SNAP_outRaw}/GLM_pooled_all_dydx_7919.tex", ///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N, fmt(%8.0fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean and Variance of Food Expenditure per capita)		replace	
		*/
		*	Step 3
			
			*	Gamma
			*	(2021-11-28) I temporarily don't use expected residual (var1_foodexp_glm) as it goes crazy. I will temporarily use expected residual from step 1 (e1_foodexp_sq_glm)
			*	(2021-11-30) It kinda works after additional cleaning (ex. dropping Latino sample), but its distribution is kinda different from what we saw in PFS paper.
			gen alpha1_foodexp_pc_glm	= (mean1_foodexp_glm)^2 / var1_foodexp_glm	//	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_glm	= var1_foodexp_glm / mean1_foodexp_glm		//	scale parameter of Gamma (beta)
			
						
			*	The  code below is a temporary code to see what is going wrong in the original code. I replaced expected value of residual squared with residual squared
			*gen alpha1_foodexp_pc_glm	= (mean1_foodexp_glm)^2 / e1_foodexp_sq_glm	//	shape parameter of Gamma (alpha)
			*gen beta1_foodexp_pc_glm	= e1_foodexp_sq_glm / mean1_foodexp_glm		//	scale parameter of Gamma (beta)
			
			*	Generate PFS by constructing CDF

				*	With COLI adjustment (used for causal inference 1997-2013)
				global	TFP_threshold	foodexp_W_TFP_pc_COLI_real	/*IHS_TFP*/
				cap	drop	PFS_glm
				gen 		PFS_glm	 = gammaptail(alpha1_foodexp_pc_glm, ${TFP_threshold}/beta1_foodexp_pc_glm)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_glm "PFS"
				
				
				*	Without COLI adjustment (used for PFS descriptive paper)
				global	TFP_threshold	foodexp_W_TFP_pc_real	/*IHS_TFP*/
				cap	drop	PFS_glm_noCOLI
				gen			PFS_glm_noCOLI = gammaptail(alpha1_foodexp_pc_glm, ${TFP_threshold}/beta1_foodexp_pc_glm)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_glm_noCOLI "PFS (w/o COLI)"
		
				summ	PFS_glm_noCOLI,d
				summ	PFS_glm_noCOLI [aw=wgt_long_fam_adj], d
				
			
			*	Generate lagged PFS
			foreach	var	in	PFS_glm	PFS_glm_noCOLI	{
				
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
			gen thresh_foodexp_normal=(foodexp_W_TFP_pc_real-mean1_foodexp_glm)/sd_foodexp_glm	// Let 2 as threshold
			gen prob_below_TFP=normal(thresh_foodexp_normal)
			gen PFS_normal		=	1 - prob_below_TFP
			
			graph twoway (kdensity PFS_glm) (kdensity PFS_normal)
			*/
		
		*	Construct FI indicator based on PFS
		*	For now we use threshold probability as 0.55, referred from Lee et al. (2021) where threshold varied from 0.55 to 0.6
		
		
		loc	var	PFS_FI_glm_noCOLI
		cap	drop	`var'
		gen		`var'=.
		replace	`var'=0	if	!mi(PFS_glm_noCOLI)	&	!inrange(PFS_glm_noCOLI,0,0.5)
		replace	`var'=1	if	!mi(PFS_glm_noCOLI)	&	inrange(PFS_glm_noCOLI,0,0.5)
		lab	var	`var'	"HH is food insecure (PFS)"
		
		loc	var	PFS_FI_glm_noCOLI
		cap	drop	`var'
		gen		`var'=.
		replace	`var'=0	if	!mi(PFS_glm_noCOLI)	&	!inrange(PFS_glm_noCOLI,0,0.5)
		replace	`var'=1	if	!mi(PFS_glm_noCOLI)	&	inrange(PFS_glm_noCOLI,0,0.5)
		lab	var	`var'	"HH is food insecure (PFS)"
		
		
			

		save    "${SNAP_dtInt}/SNAP_long_PFS_AEPP",	replace
		
	}
	
	
	