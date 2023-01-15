
	/*****************************************************************
	PROJECT: 		SNAP of FS
					
	TITLE:			SNAP_construct
				
	AUTHOR: 		Seungmin Lee (sl3235@cornell.edu)

	LAST EDITED:	Jan 14, 2023 by Seungmin Lee (sl3235@cornell.edu)
	
	IDS VAR:    	x11101ll        // 1999 Family ID

	DESCRIPTION: 	Construct variables to be analyzed from cleaned data
		
	ORGANIZATION:	0 -	Preamble
						0.1 - Environment setup
					1 - Construct PFS
					2 - Construct FSD variables
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
	loc	name_do	SNAP_construct
	*log using	"${bl_do_cleaning}/logs/`name_do'", replace
	
	/* Git setup */
	cd	"${SNAP_doCln}"
	stgit9
	di "Made using `name_do'.do on `c(current_date)' by `c(username)'."
	di "Git branch `r(branch)'; commit `r(sha)'."
	
	*	Determine which part of the code to be run
	local	PFS_const	1	//	Construct PFS from cleaned data
	local	FSD_const	1	//	Construct FSD from PFS
	
	/****************************************************************
		SECTION 1: Construct PFS
	****************************************************************/	
	
	
	
	*	Construct PFS
	if	`PFS_const'==1	{
	 
		use    "${SNAP_dtInt}/SNAP_long_cleaned",	clear
		
		*	Generate a variable (will be moved to clean var section)
		gen	age_ind_sq	=	(age_ind)^2
		label var	age_ind_sq	"Age sq."
		
		*	Set globals
		global	statevars		l2_foodexp_tot_exclFS_pc_1_real l2_foodexp_tot_exclFS_pc_2_real	//	l2_foodexp_tot_exclFS_pc_1_real l2_foodexp_tot_exclFS_pc_2_real  * Need to use real value later
		global	demovars		rp_age rp_age_sq	rp_nonWhte	rp_married	rp_female	
		global	econvars		ln_fam_income_pc	//	ln_fam_income_pc_real   * Need to use real value later
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child
		global	empvars			rp_employed
		global	eduvars			rp_NoHS rp_somecol rp_col
		// global	foodvars		FS_rec_wth	//	Should I use prected FS redemption from 1st-stage IV?, or even drop it for exclusion restriction?
		global	macrovars		unemp_rate	CPI
		global	regionvars		rp_state_enum1-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		global	timevars		year_enum3-year_enum30 //	Exclude year_enum2 as base category
				
			
		label	var	FS_rec_wth	"FS last month"
		label	var	foodexp_tot_inclFS_pc	"Food exp (with FS benefit)"
		label	var	l2_foodexp_tot_inclFS_pc_1	"Food Exp in t-2"
		label	var	l2_foodexp_tot_inclFS_pc_2	"(Food Exp in t-2)$^2$"
		label	var	rp_age		"Age (RP)"
		label	var	rp_age_sq	"Age$^2$ (RP)"
		label	var	change_RP	"RP changed"
		label	var	ln_fam_income_pc	"ln(per capita income)"
		label	var	unemp_rate	"State Unemp Rate"
		label	var	major_control_dem	"Dem state control"
		label	var	major_control_rep	"Rep state control"
		
		

		*	Sample where PFS will be constructed upon
		*	They include (i) in_sample family (2) HH from 1977 to 2019
		global	PFS_sample		in_sample==1	&	inrange(year,1976,2019)
		
		*	Declare variables
		global	depvar		foodexp_tot_inclFS_pc
		
			*	Summary state of dep.var
			summ	${depvar}, d
			*unique x11101ll if in_sample==1	&	!mi(foodexp_tot_inclFS_pc)
		
		*	Step 1
		*	IMPORTANT: Unlike Lee et al. (2021), I exclude a binary indicator whether HH received SNAP or not (FS_rec_wth), as including it will violate exclusion restriction of IV
		
			*	Vanila model (simply Gaussian regression, no weight, no survey structure, etc.)
			reg	${depvar}	${statevars}
		
		*	Panel regression with xtreg, unweighted
		xtreg	${depvar}	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}*/	${indvars}	/*${regionvars}	${timevars}*/, fe
		
		*	Panel regression with xtreg, weighted
		xtreg	${depvar}	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}*/	${indvars}	/*${regionvars}	${timevars}*/	[aw=wgt_long_fam_adj], fe
		
		
		xtreg	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}*/	${indvars}	/*${regionvars}	${timevars}*/	[aw=wgt_long_fam_adj]
		
		glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}*/	${indvars}	/*${regionvars}	${timevars}*/	[aw=wgt_long_fam_adj], family(gamma)	link(log)
		svy, subpop(if ${PFS_sample}): glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}*/	${macrovars}	/*${regionvars}	${timevars}*/, family(gamma)	link(log)
		
			
			*svy: reg 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}*/	${indvars}	${regionvars}	${timevars}	
		ereturn list
		est	sto	glm_step1
			
		*	Predict fitted value and residual
		gen	glm_step1_sample=1	if	e(sample)==1  & ${PFS_sample}	// e(sample) includes both subpopulation and non-subpopulation, so we need to include subpop condition here to properly restrict regression sample.
		predict double mean1_foodexp_glm	if	glm_step1_sample==1
		predict double e1_foodexp_glm	if	glm_step1_sample==1,r
		gen e1_foodexp_sq_glm = (e1_foodexp_glm)^2
		
		/*
		
			*	Issue: mean in residuals are small, but standard deviation is large, meaning greater dispersion in residual.
			*	It implies that 1st-stage is not working well in predicting mean.
			summ	foodexp_tot_inclFS_pc	mean1_foodexp_glm	e1_foodexp_glm	e1_foodexp_sq_glm
			summ	e1_foodexp_glm,d
			
			
			*	As a robustness check, run step 1 "with" FS redemption (just like Lee et al. (2021)) and compare the variation captured.
			svy: glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	/*${indvars}*/	${regionvars}	${timevars}	, family(gamma)	link(log)
			ereturn list
			est	sto	glm_step1_withFS
			
			*	Without income and FS redemption
			svy: glm 	`depvar'	${statevars}	${demovars}	/*${econvars}*/	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}	${indvars}*/	${regionvars}	${timevars}	, family(gamma)	link(log)
			ereturn list
			est	sto	glm_step1_woFS_woinc
								
			*	Output robustness check (comparing step 1 w/o FS and with FS)
			esttab	glm_step1_withFS	glm_step1	glm_step1_woFS_woinc	using "${SNAP_outRaw}/GLM_pooled_FS.csv", ///
					cells(b(star fmt(%8.2f)) se(fmt(2) par)) stats(N_sub /*r2*/) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					title(Conditional Mean of Food Expenditure per capita (with and w/o FS)) 	replace
					
			esttab	glm_step1_withFS	glm_step1	glm_step1_woFS_woinc	using "${SNAP_outRaw}/GLM_pooled_FS.tex", ///
					cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub, fmt(%8.0fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean of Food Expenditure per capita (with and w/o FS))		replace	
		*/
		
		
		*	Step 2
		local	depvar	e1_foodexp_sq_glm
		
		*	For now (2021-11-28) GLM in step 2 does not converge. Will use OLS for now.
		svy: glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${macrovars}	/*${regionvars}	${timevars}*/, family(gamma)	link(log)
		svy: reg 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}*/	${macrovars}	/*${regionvars}	${timevars}*/
			
		est store glm_step2
		gen	glm_step2_sample=1	if	e(sample)==1 & `=e(subpop)'
		*svy:	reg `e(depvar)' `e(selected)'
		predict	double	var1_foodexp_glm	if	glm_step2_sample==1	
		* (2022-05-06) Replace predicted value with its absolute value. It is because negative predicted value creates huge missing values in constructing PFS. Replacing with absoluste value is fine, since we are estimating conditional variance which should be non-negative.
		replace	var1_foodexp_glm	=	abs(var1_foodexp_glm)
		
			*	Shows the list of variables to manually observe issues (ex. too many negative predicted values)
			br x11101ll year foodexp_tot_inclFS_pc mean1_foodexp_glm e1_foodexp_glm e1_foodexp_sq_glm var1_foodexp_glm
		
		
		*	Output
		**	For AER manuscript, we omit asterisk(*) to display significance as AER requires not to use.
		**	If we want to diplay star, renable "star" option inside "cells" and "star(* 0.10 ** 0.05 *** 0.01)"
		
			esttab	glm_step1	glm_step2	using "${SNAP_outRaw}/GLM_pooled.csv", ///
					cells(b(star fmt(%8.2f)) se(fmt(2) par)) stats(N_sub /*r2*/) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	///
					title(Conditional Mean and Variance of Food Expenditure per capita) 	replace
					
			esttab	glm_step1	glm_step2	using "${SNAP_outRaw}/GLM_pooled.tex", ///
					cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub, fmt(%8.0fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Conditional Mean and Variance of Food Expenditure per capita)		replace		
		
		
		*	Step 3
		*	Assume the outcome variable follows the Gamma distribution
		*	(2021-11-28) I temporarily don't use expected residual (var1_foodexp_glm) as it goes crazy. I will temporarily use expected residual from step 1 (e1_foodexp_sq_glm)
		*	(2021-11-30) It kinda works after additional cleaning (ex. dropping Latino sample), but its distribution is kinda different from what we saw in PFS paper.
		gen alpha1_foodexp_pc_glm	= (mean1_foodexp_glm)^2 / var1_foodexp_glm	//	shape parameter of Gamma (alpha)
		gen beta1_foodexp_pc_glm	= var1_foodexp_glm / mean1_foodexp_glm		//	scale parameter of Gamma (beta)
		
		*	The  code below is a temporary code to see what is going wrong in the original code. I replaced expected value of residual squared with residual squared
		*gen alpha1_foodexp_pc_glm	= (mean1_foodexp_glm)^2 / e1_foodexp_sq_glm	//	shape parameter of Gamma (alpha)
		*gen beta1_foodexp_pc_glm	= e1_foodexp_sq_glm / mean1_foodexp_glm		//	scale parameter of Gamma (beta)
		
		*	Generate PFS by constructing CDF
		gen PFS_glm = gammaptail(alpha1_foodexp_pc_glm, foodexp_W_TFP_pc/beta1_foodexp_pc_glm)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
		label	var	PFS_glm "PFS"
		
		*	Construct FI indicator based on PFS
		*	For now we use threshold probability as 0.55, referred from Lee et al. (2021) where threshold varied from 0.55 to 0.6
		loc	var	PFS_FI_glm
		cap	drop	`var'
		gen		`var'=.
		replace	`var'=0	if	!mi(PFS_glm)	&	!inrange(PFS_glm,0,0.5)
		replace	`var'=1	if	!mi(PFS_glm)	&	inrange(PFS_glm,0,0.5)
		lab	var	`var'	"HH is food insecure (PFS)"
		
		save    "${SNAP_dtInt}/SNAP_long_PFS",	replace
		
		
		
		
		*	Regress PFS on characteristics
		use    "${SNAP_dtInt}/SNAP_long_PFS",	clear	
		
			*	PFS, without region FE
			local	depvar	PFS_glm
			
			svy, subpop(if !mi(PFS_glm)):	///
				reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}	${macrovars}*/
			est	store	PFS_base	
			
			svy, subpop(if !mi(PFS_glm)):	///
				reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}		/*${macrovars}	*/
			est	store	PFS_FS	
			
			svy, subpop(if !mi(PFS_glm)):	///
				reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	${foodvars}	${macrovars}					
			est	store	PFS_FS_macro
			
		*	Food Security Indicators and Their Correlates (Table 4 of 2020/11/16 draft)
			esttab	PFS_base	PFS_FS	PFS_FS_macro	using "${SNAP_outRaw}/Tab_3_PFS_association.csv", ///
					cells(b(star fmt(3)) se(fmt(2) par)) stats(N_sub r2) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Effect of Correlates on Food Security Status) replace
					
					
			esttab	PFS_base	PFS_FS	PFS_FS_macro	using "${SNAP_outRaw}/Tab_3_PFS_association.tex", ///
					cells(b(star fmt(3)) & se(fmt(2) par)) stats(N_sub r2) incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/		///
					/*cells(b(nostar fmt(%8.3f)) & se(fmt(2) par)) stats(N_sub r2, fmt(%8.0fc %8.3fc)) incelldelimiter() label legend nobaselevels /*nostar star(* 0.10 ** 0.05 *** 0.01)*/	/*drop(_cons)*/	*/	///
					title(Effect of Correlates on Food Security Status) replace
		
		
		*	
	}