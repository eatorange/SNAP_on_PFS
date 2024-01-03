
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
										
	OUTPUTS: 		* PFS-constructed data (with PFS )						
					${SNAP_dtInt}/SNAP_long_PFS.dta
					

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
	local	PFS_const	1	//	Construct PFS from cleaned data
	
	/****************************************************************
		SECTION 1: Construct PFS
	****************************************************************/	
		
	*	Construct PFS
	*	Please check "SNAP_PFS_const_test.do" file for the rational behind PFS model selection
	if	`PFS_const'==1	{
	 
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
		*	(2023-08-29) Don't. We will use the entire sample for constructin the PFS. It also account for only less than 1%
		*	keep	if	income_ever_below_200==1
		
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
		global	foodvars		FS_rec_wth	//	(2023-08-29: Include it for 2 reasons (i) SNAP is an important determinant of food expenditure (ii) Including it will still not violate exclusion restriction, I think?)
		*global	macrovars		unemp_rate	CPI	
		global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		global	timevars		year_enum4-year_enum11	year_enum14-year_enum30	//	xclude year_enum3 (1979) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
		global	indvars			/*ind_female*/ age_ind	age_ind_sq ind_NoHS ind_somecol ind_col /* ind_employed_dummy*/	//	NOT included in constructing PFS
			
		
					
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
		*	(note: ln doesnt work under ppmlhdfe as the command does not accept zero values, and IHS-based IV estimates become less sensible, so we stick to the original food expenditure variable.)
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
			*	I use Poisson quasi-MLE estimation, instead of ppml with Gamma in the original PFS paper
			*	I include individual-FE
			*	Please refer to "SNAP_PFS_const_test.do" file for more detail.
			
			*	All sample
			ppmlhdfe	${depvar}	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	[pweight=wgt_long_ind], ///
				absorb(x11101ll ib31.rp_state ib1979.year) vce(cluster x11101ll) d	
			
			ereturn list
			est	sto	ppml_step1
				
			*	Predict fitted value and residual
			gen		ppml_step1_sample=1	if	e(sample)==1 // e(sample) includes both subpopulation and non-subpopulation, so we need to include subpop condition here to properly restrict regression sample.
			predict double mean1_foodexp_ppml	if	ppml_step1_sample==1
			predict double e1_foodexp_ppml			if	ppml_step1_sample==1,r
			gen e1_foodexp_sq_ppml = (e1_foodexp_ppml)^2	if	ppml_step1_sample==1
			
		
		br x11101ll year ${depvar} mean1_foodexp_ppml e1_foodexp_ppml e1_foodexp_sq_ppml
		
		*	Step 2
		*	(2023-1-18) Possion with FE now converges, and it does better job compared to Gaussian regression. So we use it.
		local	depvar	e1_foodexp_sq_ppml
		
			*	Poisson quasi-MLE
			ppmlhdfe	`depvar'	${statevars} ${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	[pweight=wgt_long_ind], ///
				absorb(x11101ll ib31.rp_state ib1979.year) vce(cluster x11101ll) d	
			est store ppml_step2
			gen	ppml_step2_sample=1	if	e(sample)==1 
			predict	double	var1_foodexp_ppml	if	ppml_step2_sample==1	// (2023-06-21) Poisson quasi-MLE does not seem to generate negative predicted value, which is good (no need to square them)
			gen	sd_foodexp_ppml	=	sqrt(abs(var1_foodexp_ppml))	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
			gen	error_var1_ppml	=	abs(var1_foodexp_ppml - e1_foodexp_sq_ppml)	//	prediction error. 
			*br	e1_foodexp_sq_ppml	var1_foodexp_ppml	error_var1_ppml
			
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
			
			*	Generate PFS by constructing CDF
			*	I create two versions - without COLI and with COLI.
			
				*	Without COLI adjustment (used for PFS descriptive paper)
				global	TFP_threshold	foodexp_W_TFP_pc_real	/*IHS_TFP*/
				cap	drop	PFS_ppml_noCOLI
				gen			PFS_ppml_noCOLI = gammaptail(alpha1_foodexp_pc_ppml, ${TFP_threshold}/beta1_foodexp_pc_ppml)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_ppml_noCOLI "PFS (w/o COLI)"
			
				*	With COLI adjustment (main caufal inference)
				global	TFP_threshold	foodexp_W_TFP_pc_COLI_real	/*IHS_TFP*/
				cap	drop	PFS_ppml
				gen 		PFS_ppml	 = gammaptail(alpha1_foodexp_pc_ppml, ${TFP_threshold}/beta1_foodexp_pc_ppml)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_ppml "PFS"
			
			
			
			*	Generate lagged PFS
			foreach	var	in	PFS_ppml	PFS_ppml_noCOLI		{
				
				loc	varlabel:	var	label	`var'
				
				cap	drop	l2_`var'
				gen	l2_`var'	=	l2.`var'
				lab	var	l2_`var'	"(L2) `varlabel'"
				
				cap	drop	l4_`var'
				gen	l4_`var'	=	l4.`var'
				lab	var	l4_`var'	"(L4) `varlabel'"
				
			}
		
		
		
		*	(2023-09-24) Repeat for foodexp w/o SNAP (as a supplementary analyses)
		global	depvar		foodexp_tot_exclFS_pc_real	/*IHS_foodexp*/
		
			*	Summary state of dep.var
			summ	${depvar}, d
			*unique x11101ll if in_sample==1	&	!mi(foodexp_tot_inclFS_pc)
		
		*	Step 1
		*	Compared to Lee et al. (2021), I changed as followings
			*	I exclude a binary indicator whether HH received SNAP or not (FS_rec_wth), as including it will violate exclusion restriction of IV
			*	I do NOT use survey structure (but still use weight)
			*	I use Poisson quasi-MLE estimation, instead of ppml with Gamma in the original PFS paper
			*	I include individual-FE
			*	Please refer to "SNAP_PFS_const_test.do" file for more detail.
			
			*	All sample
			ppmlhdfe	${depvar}	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}	${foodvars}	[pweight=wgt_long_ind], ///
				absorb(x11101ll ib31.rp_state ib1979.year) vce(cluster x11101ll) d	
			
			ereturn list
			est	sto	ppml_step1_exclFS
				
			*	Predict fitted value and residual
			gen		ppml_step1_sample_exclFS=1	if	e(sample)==1 // e(sample) includes both subpopulation and non-subpopulation, so we need to include subpop condition here to properly restrict regression sample.
			predict double mean1_foodexp_ppml_exclFS	if	ppml_step1_sample_exclFS==1
			predict double e1_foodexp_ppml_exclFS			if	ppml_step1_sample_exclFS==1,r
			gen e1_foodexp_sq_ppml_exclFS = (e1_foodexp_ppml_exclFS)^2	if	ppml_step1_sample_exclFS==1
			
		
		br x11101ll year ${depvar} mean1_foodexp_ppml_exclFS e1_foodexp_ppml_exclFS e1_foodexp_sq_ppml_exclFS
		
		*	Step 2
		*	(2023-1-18) Possion with FE now converges, and it does better job compared to Gaussian regression. So we use it.
		local	depvar	e1_foodexp_sq_ppml_exclFS
		
			*	Poisson quasi-MLE
			ppmlhdfe	`depvar'	${statevars} ${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	[pweight=wgt_long_ind], ///
				absorb(x11101ll ib31.rp_state ib1979.year) vce(cluster x11101ll) d	
			est store ppml_step2_exclFS
			gen	ppml_step2_sample_exclFS=1	if	e(sample)==1 
			predict	double	var1_foodexp_ppml_exclFS	if	ppml_step2_sample_exclFS==1	// (2023-06-21) Poisson quasi-MLE does not seem to generate negative predicted value, which is good (no need to square them)
			gen	sd_foodexp_ppml_exclFS	=	sqrt(abs(var1_foodexp_ppml_exclFS))	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
			gen	error_var1_ppml_exclFS	=	abs(var1_foodexp_ppml_exclFS - e1_foodexp_sq_ppml_exclFS)	//	prediction error. 
			*br	e1_foodexp_sq_ppml	var1_foodexp_ppml	error_var1_ppml
			
		*	Output
		**	For AER manuscript, we omit asterisk(*) to display significance as AER requires not to use.
		**	If we want to diplay star, renable "star" option inside "cells" and "star(* 0.10 ** 0.05 *** 0.01)"
		
			esttab	ppml_step1_exclFS	ppml_step2_exclFS	using "${SNAP_outRaw}/ppml_pooled_exclFS.csv", ///
					cells(b(star fmt(%8.2f)) se(fmt(2) par)) stats(N_sub /*r2*/) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					title(Conditional Mean and Variance of Food Expenditure per capita) 	replace
					
			esttab	ppml_step1_exclFS	ppml_step2_exclFS	using "${SNAP_outRaw}/ppml_pooled_exclFS.tex", ///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub, fmt(%8.0fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean and Variance of Food Expenditure per capita)		replace		
			
		
		*	Step 3
			
			*	Gamma
			*	(2021-11-28) I temporarily don't use expected residual (var1_foodexp_ppml) as it goes crazy. I will temporarily use expected residual from step 1 (e1_foodexp_sq_ppml)
			*	(2021-11-30) It kinda works after additional cleaning (ex. dropping Latino sample), but its distribution is kinda different from what we saw in PFS paper.
			gen alpha1_foodexp_pc_ppml_exclFS	= (mean1_foodexp_ppml_exclFS)^2 / var1_foodexp_ppml_exclFS	//	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_ppml_exclFS	= var1_foodexp_ppml_exclFS / mean1_foodexp_ppml_exclFS		//	scale parameter of Gamma (beta)
			
			*	Generate PFS by constructing CDF
			*	I create two versions - without COLI and with COLI.
			
				*	Without COLI adjustment (used for PFS descriptive paper)
				global	TFP_threshold	foodexp_W_TFP_pc_real	/*IHS_TFP*/
				cap	drop	PFS_ppml_noCOLI_exclFS
				gen			PFS_ppml_noCOLI_exclFS = gammaptail(alpha1_foodexp_pc_ppml_exclFS, ${TFP_threshold}/beta1_foodexp_pc_ppml_exclFS)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_ppml_noCOLI_exclFS "PFS (w/o COLI) - excluding SNAP benefit"
			
				*	With COLI adjustment (main caufal inference)
				global	TFP_threshold	foodexp_W_TFP_pc_COLI_real	/*IHS_TFP*/
				cap	drop	PFS_ppml_exclFS
				gen 		PFS_ppml_exclFS	 = gammaptail(alpha1_foodexp_pc_ppml_exclFS, ${TFP_threshold}/beta1_foodexp_pc_ppml_exclFS)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
				label	var	PFS_ppml_exclFS "PFS - excluding SNAP benefit"
			
			
			
			*	Generate lagged PFS
			foreach	var	in	PFS_ppml_exclFS	PFS_ppml_noCOLI_exclFS		{
				
				loc	varlabel:	var	label	`var'
				
				cap	drop	l2_`var'
				gen	l2_`var'	=	l2.`var'
				lab	var	l2_`var'	"(L2) `varlabel'"
				
				cap	drop	l4_`var'
				gen	l4_`var'	=	l4.`var'
				lab	var	l4_`var'	"(L4) `varlabel'"
				
			}
		
		
		
		
		
		*	Save
		save	"${SNAP_dtInt}/SNAP_long_PFS", replace

		
		*	Regress PFS on characteristics
		*	(2023-1-18) This one needs to be re-visited, considering what regression method we will use (svy prefix, weight, fixed effects, etc.)
		*	(2023-8-20) Re-visited. Make sure to do this regression on the final sapmle (non-missing PFS, income ever below 200, balaned b/w 9713, etc). I set the default counter as zero to run manually, until it is moved to other dofile.
		*use    "${SNAP_dtInt}/SNAP_long_PFS",	clear	
		local	run_PFS_reg=0
		if	`run_PFS_reg'==1	{
			
			
		
			*	No SNAP status, state and year FE, all sapmle
			local	depvar	PFS_ppml_noCOLI
			svy, subpop(if !mi(`depvar')):	///
				reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${regionvars}	${timevars}
			est	store	PFS_noSNAP_all	
			estadd	local	state_year_FE	"Y"
			svy, subpop(if !mi(`depvar')):	mean	PFS_ppml		//	Need to think about how to add this usign "estadd"....
			
			*	reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars} [aweight=wgt_long_fam_adj]	//	Coefficients are sampe, but different Sterror.
			
			*	SNAP status, state and year FE, all sapmle
			svy, subpop(if !mi(PFS_ppml_noCOLI)):	///
				reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${regionvars}	${timevars}	FS_rec_wth	
			est	store	PFS_SNAP_all	
			estadd	local	state_year_FE	"Y"
			svy, subpop(if !mi(`depvar')):	mean	PFS_ppml	//	Need to think about how to add this usign "estadd"....
			
			/*
			*	No SNAP status, state and year FE, 97-13 balanced sample
			svy, subpop(if !mi(PFS_ppml)	&	balanced_9713==1):	///
				reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${regionvars}	${timevars}	
			est	store	PFS_noSNAP_9713	
			estadd	local	state_year_FE	"Y"
			svy, subpop(if !mi(`depvar') &	balanced_9713==1):	mean	PFS_ppml
			
			*	SNAP status, state and year FE, 97-13 balanced sample
			svy, subpop(if !mi(PFS_ppml)	&	balanced_9713==1):	///
				reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${regionvars}	${timevars}	FS_rec_wth	
			est	store	PFS_SNAP_9713
			estadd	local	state_year_FE	"Y"
			svy, subpop(if !mi(`depvar') &	balanced_9713==1):	mean	PFS_ppml
			*/
			
		*	Food Security Indicators and Their Correlates
			esttab	PFS_noSNAP_all	PFS_SNAP_all	/*PFS_noSNAP_9713	PFS_SNAP_9713*/	using "${SNAP_outRaw}/Tab_3_PFS_association.csv", ///
					cells(b(star fmt(3)) se(fmt(2) par)) stats(N_sub r2 state_year_FE meanPFS, label("N" "R2" "State and Year FE" "Mean PFS")) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state*	year_enum*)	///
					title(PFS and household covariates) replace
					
					
			esttab	PFS_noSNAP_all	PFS_SNAP_all	/*PFS_noSNAP_9713	PFS_SNAP_9713*/	using "${SNAP_outRaw}/Tab_3_PFS_association.tex", ///
					cells(b(star fmt(3)) & se(fmt(2) par)) stats(N_sub r2 state_year_FE	, label("N" "R2" "State and Year FE")) ///
					incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state*	year_enum*)			///
					/*cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	*/	///
					title(PFS and household covariates) replace
		
		}	//	run_PFS_reg
		
		
		
	}
