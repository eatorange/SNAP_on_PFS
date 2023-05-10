
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
	local	PFS_const	1	//	Construct PFS from cleaned data
	local	FSD_const	1	//	Construct FSD from PFS
	
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
		
		*	Drop states outside 48 continental states (HA/AK/inapp/etc.), as we do not have their TFP cost information.
		drop	if	inlist(rp_state,0,50,51,99)
		
		*	Set globals
		global	statevars		l2_foodexp_tot_exclFS_pc_1_real l2_foodexp_tot_exclFS_pc_2_real	//	l2_foodexp_tot_exclFS_pc_1_real l2_foodexp_tot_exclFS_pc_2_real  * Need to use real value later
		global	demovars		rp_age rp_age_sq	rp_nonWhte	rp_married	rp_female	
		global	econvars		ln_fam_income_pc_real	//	ln_fam_income_pc_real   * Need to use real value later
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child
		global	empvars			rp_employed
		global	eduvars			rp_NoHS rp_somecol rp_col
		// global	foodvars		FS_rec_wth	//	Should I use prected FS redemption from 1st-stage IV?, or even drop it for exclusion restriction?
		global	macrovars		unemp_rate	CPI
		global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1978) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
				
			
		label	var	FS_rec_wth	"FS last month"
		label	var	foodexp_tot_inclFS_pc	"Food exp (with FS benefit)"
		label	var	l2_foodexp_tot_inclFS_pc_1	"Food Exp in t-2"
		label	var	l2_foodexp_tot_inclFS_pc_2	"(Food Exp in t-2)$^2$"
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
			*	I use Poisson distribution assumption instead of Gamma
			*	I include individual-FE
			*	Please refer to "SNAP_PFS_const_test.do" file for more detail.
		ppmlhdfe	${depvar}	${statevars} ${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars} 	 [pweight=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) d	
		/*
		glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}*/	${indvars}	/*${regionvars}	${timevars}*/	[aw=wgt_long_fam_adj], family(gamma)	link(log)
		svy, subpop(if ${PFS_sample}): glm 	`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	/*${foodvars}*/	${macrovars}	/*${regionvars}	${timevars}*/, family(gamma)	link(log)
		*/		
		ereturn list
		est	sto	glm_step1
			
		*	Predict fitted value and residual
		gen	glm_step1_sample=1	if	e(sample)==1 // e(sample) includes both subpopulation and non-subpopulation, so we need to include subpop condition here to properly restrict regression sample.
		predict double mean1_foodexp_glm	if	glm_step1_sample==1
		predict double e1_foodexp_glm		if	glm_step1_sample==1,r
		gen e1_foodexp_sq_glm = (e1_foodexp_glm)^2	if	glm_step1_sample==1
		
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
		br x11101ll year ${depvar} mean1_foodexp_glm e1_foodexp_glm e1_foodexp_sq_glm
		
		*	Step 2
		*	(2023-1-18) Possion with FE now converges, and it does better job compared to Gaussian regression. So we use it.
		local	depvar	e1_foodexp_sq_glm
		
			*	GLM with Poisson
			ppmlhdfe	`depvar'	${statevars} ${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	[pweight=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) d	
			est store glm_step2
			gen	glm_step2_sample=1	if	e(sample)==1 
			predict	double	var1_foodexp_glm	if	glm_step2_sample==1	
			gen	sd_foodexp_glm	=	sqrt(abs(var1_foodexp_glm))	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
			gen	error_var1_glm	=	abs(var1_foodexp_glm - e1_foodexp_sq_glm)	//	prediction error. 
			*br	e1_foodexp_sq_glm	var1_foodexp_glm	error_var1_glm
			
			
			/*
			*	Gaussian 
			cap	drop	gau_step2_sample
			local	depvar	e1_foodexp_sq_glm
			reghdfe		`depvar'	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	[aw=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year)
			gen	gau_step2_sample=1	if	e(sample)==1
			predict	double	var1_foodexp_gau	if	glm_step2_sample==1	
			*  Replace predicted value with its absolute value. It is because negative predicted value creates huge missing values in constructing PFS. Replacing with absoluste value is fine, since we are estimating conditional variance which should be non-negative.
			replace	var1_foodexp_gau	=	abs(var1_foodexp_gau)
			
			gen	error_var1_gau	=	abs(var1_foodexp_gau-e1_foodexp_sq_glm)
			
			summ	e1_foodexp_sq_glm	var1_foodexp_glm	var1_foodexp_gau	error_var1_glm	error_var1_gau
			*/
		
	
		/* (2023-1-18) Outdated
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
			br x11101ll year ${depvar} mean1_foodexp_glm e1_foodexp_glm e1_foodexp_sq_glm var1_foodexp_glm
		*/
		
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
			
			*	Gamma
			*	(2021-11-28) I temporarily don't use expected residual (var1_foodexp_glm) as it goes crazy. I will temporarily use expected residual from step 1 (e1_foodexp_sq_glm)
			*	(2021-11-30) It kinda works after additional cleaning (ex. dropping Latino sample), but its distribution is kinda different from what we saw in PFS paper.
			gen alpha1_foodexp_pc_glm	= (mean1_foodexp_glm)^2 / var1_foodexp_glm	//	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_glm	= var1_foodexp_glm / mean1_foodexp_glm		//	scale parameter of Gamma (beta)
			
						
			*	The  code below is a temporary code to see what is going wrong in the original code. I replaced expected value of residual squared with residual squared
			*gen alpha1_foodexp_pc_glm	= (mean1_foodexp_glm)^2 / e1_foodexp_sq_glm	//	shape parameter of Gamma (alpha)
			*gen beta1_foodexp_pc_glm	= e1_foodexp_sq_glm / mean1_foodexp_glm		//	scale parameter of Gamma (beta)
			
			*	Generate PFS by constructing CDF
			global	TFP_threshold	foodexp_W_TFP_pc_real	/*IHS_TFP*/
			gen PFS_glm = gammaptail(alpha1_foodexp_pc_glm, ${TFP_threshold}/beta1_foodexp_pc_glm)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
			label	var	PFS_glm "PFS"
			
					
			*	Normal (to show the robustness of the distributional assumption)
			/*
			gen thresh_foodexp_normal=(foodexp_W_TFP_pc_real-mean1_foodexp_glm)/sd_foodexp_glm	// Let 2 as threshold
			gen prob_below_TFP=normal(thresh_foodexp_normal)
			gen PFS_normal		=	1 - prob_below_TFP
			
			graph twoway (kdensity PFS_glm) (kdensity PFS_normal)
			*/
		
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
		*	(2023-1-18) This one needs to be re-visited, considering what regression method we will use (svy prefix, weight, fixed effects, etc.)
		use    "${SNAP_dtInt}/SNAP_long_PFS",	clear	
		
			*	PFS, without region FE
			local	depvar	PFS_glm
			svy, subpop(if !mi(PFS_glm)):	///
				reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}
			
			reg	`depvar'	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars} [aweight=wgt_long_fam_adj]
			
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
		
		

	}
	
	/****************************************************************
		SECTION 2: Construct FSD
	****************************************************************/	
	
	*	Construct dynamics variables
	if	`FSD_const'==1	{
		
		use	"${SNAP_dtInt}/SNAP_long_PFS", clear
		
		*tsspell, f(L.year == .)
		*br year _spell _seq _end
		
		*gen f_year_mi=1	if	mi(f.year)
		
		*	Generate spell-related variables
		cap drop	_seq	_spell	_end
		tsspell, cond(year>=2 & PFS_FI_glm==1)
		
		br	x11101ll	year	PFS_glm	PFS_FI_glm	_seq	_spell	_end
		
		*	Before genering FSDs, generate the number of non-missing PFS values over the 5-year
		*	It will vary from 0 to the full length of reference period (currently 3)
		loc	var	num_nonmissing_PFS
		cap	drop	`var'
		gen	`var'=0
		foreach time in 0 2 4	{
			
			replace	`var'	=	`var'+1	if	!mi(f`time'.PFS_glm)

		}
		lab	var	`var'	"# of non-missing PFS over 5 years"
		
		
		*	Spell length variable - the consecutive years of FI experience
		*	Start with 5-year period (SL_5)
		*	To utilize biennial data since 1997, I use observations in every two years
			*	Many years lose observations due to data availability
		loc	var	SL_5
		cap	drop	`var'
		gen		`var'=.
		replace	`var'=0	if	!mi(PFS_FI_glm)
		replace	`var'=1	if	PFS_FI_glm==1
		
		*	SL_5=2	if	HH experience FI in two consecutive rounds
		replace	`var'=2	if	PFS_FI_glm==1	&	f2.PFS_FI_glm==1	//	&	inrange(year,1997,1999)
		
		*	SL_5=3	if HH experience FI in three consecutive rounds
		replace	`var'=3	if	PFS_FI_glm==1	&	f2.PFS_FI_glm==1	&	f4.PFS_FI_glm==1	
		
		lab	var	`var'	"# of consecutive FI incidences over the next 5 years (0-3)"
		
		/*
		*	SPL=4	if HH experience FI in four consecutive years
		replace	`var'=4	if	PFS_FI_glm==1	&	f1.PFS_FI_glm==1	&	f2.PFS_FI_glm==1	&	f3.PFS_FI_glm==1	&	(inrange(year,1977,1984)	|	inrange(year,1990,1994))	//	For years with 4 consecutive years of observations available
		*replace	`var'=4	if	PFS_FI_glm==1	&	f3.PFS_FI_glm==1	&	year==1987	//	If HH experienced FI in 1987 and 1990
		
		*	SPL=5	if	HH experience FI in 5 consecutive years
		*	Note: It cannot be constructed in 1987, as all of the 4 consecutive years (1988-1991) are missing.
		*	Issue: 1994/1996 cannot have value 5 as it does not observe 1998/2000 status when the PSID was not conducted.  Thus, I impose the assumption mentioned here
			*	For 1994, SPL=5 if HH experience FI in 94, 95, 96, 97 and 99 (assuming it is also FI in 1998)
			*	For 1996, SPL=5 if HH experience FI in 96, 97, 99, and 01 (assuming it is also FI in 98 and 00)
		replace	`var'=5	if	PFS_FI_glm==1	&	f1.PFS_FI_glm==1	&	f2.PFS_FI_glm==1	&	f3.PFS_FI_glm==1	&	f4.PFS_FI_glm==1	&	(inrange(year,1977,1983)	|	inrange(year,1992,1993))	//	For years with 5 consecutive years of observations available
		replace	`var'=5	if	PFS_FI_glm==1	&	f1.PFS_FI_glm==1	&	f2.PFS_FI_glm==1	&	f4.PFS_FI_glm==1	&	year==1995	//	For years with 5 consecutive years of observations available	
		replace	`var'=5	if	PFS_FI_glm==1	&	f2.PFS_FI_glm==1	&	f4.PFS_FI_glm==1	&	inrange(year,1997,2015)
		*/
		
	
		
			*	Construct SL_5 backwards, since regression current redemption on future outcome may not make sense (Chris said something like that...)
			loc	var	SL_5_backward
			cap	drop	`var'
			gen		`var'=.
			replace	`var'=0	if	!mi(PFS_FI_glm)
			replace	`var'=1	if	PFS_FI_glm==1
			
			*	SL_5=2	if	HH experience FI in "past" two consecutive rounds
			replace	`var'=2	if	PFS_FI_glm==1	&	l2.PFS_FI_glm==1	//	&	inrange(year,1997,1999)
		
			*	SL_5=3	if HH experience FI in "past" three consecutive rounds
			replace	`var'=3	if	PFS_FI_glm==1	&	l2.PFS_FI_glm==1	&	l4.PFS_FI_glm==1	
		
			lab	var	`var'	"# of consecutive FI incidences over the past 5 years (0-3)"
		
			br	x11101ll	year	PFS_glm	PFS_FI_glm	_seq	_spell	_end SL_5	SL_5_backward
		
		*	Permanent approach (TFI and CFI)
		
			*	To construct CFI (Chronic Food Insecurity), we need average PFS over time at household-level.
			*	Since households have different number of non-missing PFS, we cannot simply use "mean" function.
			*	We add-up all non-missing PFS over time at household-level, and divide it by cut-off PFS of those non-missing years.
			
			*	Aggregate PFS and PFS_FI over time (numerator)
			cap	drop	PFS_glm_total
			cap	drop	PFS_FI_glm_total
			
			gen	PFS_glm_total		=	0
			gen	PFS_FI_glm_total	=	0
			
			*	Add non-missing PFS of later periods, and add 0.5 to denominator 
			foreach time in 0 2 4	{
				
				replace	PFS_glm_total		=	PFS_glm_total		+	f`time'.PFS_glm		if	!mi(f`time'.PFS_glm)
				replace	PFS_FI_glm_total	=	PFS_FI_glm_total	+	f`time'.PFS_FI_glm	if	!mi(f`time'.PFS_FI_glm)
				
			}
			
			replace	PFS_glm_total=.		if	num_nonmissing_PFS==0
			replace	PFS_FI_glm_total=.	if	num_nonmissing_PFS==0
			
			lab	var	PFS_glm_total		"Aggregated PFS over 5 years"
			lab	var	PFS_FI_glm_total	"Aggregated FI incidence over 5 years"
			
			*	Generate denominator by aggregating cut-off probability over time
			*	Since I currently use 0.5 as a baseline threshold probability, it should be (0.5 * the number of non-missing PFS)
			cap	drop	PFS_threshold_glm_total
			gen			PFS_threshold_glm_total	=	0.5	*	num_nonmissing_PFS
			lab	var		PFS_threshold_glm_total	"Sum of PFS over time"
			
			*	Generate (normalized) mean-PFS by dividing the numerator into the denominator (Check Calvo & Dercon (2007), page 19)
			cap	drop	PFS_glm_mean_normal
			gen			PFS_glm_mean_normal	=	PFS_glm_total	/	PFS_threshold_glm_total
			lab	var		PFS_glm_mean_normal	"Normalized mean PFS"
			
			
			*	Construct SFIG
			cap	drop	FIG_indiv
			cap	drop	SFIG_indiv
			cap	drop	PFS_glm_normal
			gen	double	FIG_indiv=.
			gen	double	SFIG_indiv	=.
			gen	double PFS_glm_normal	=.				
					
				br	x11101ll	year	num_nonmissing_PFS	PFS_glm	PFS_FI_glm PFS_glm_total PFS_threshold_glm_total	FIG_indiv	SFIG_indiv	PFS_glm_normal	PFS_glm_mean_normal
				
				*	Normalized PFS (PFS/threshold PFS)	(PFSit/PFS_underbar_t)
				replace	PFS_glm_normal	=	PFS_glm	/	0.5
				
				*	Inner term of the food security gap (FIG) and the squared food insecurity gap (SFIG)
				replace	FIG_indiv	=	(1-PFS_glm_normal)^1	if	!mi(PFS_glm_normal)	&	PFS_glm_normal<1	//	PFS_glm<0.5
				replace	FIG_indiv	=	0						if	!mi(PFS_glm_normal)	&	PFS_glm_normal>=1	//	PFS_glm>=0.5
				replace	SFIG_indiv	=	(1-PFS_glm_normal)^2	if	!mi(PFS_glm_normal)	&	PFS_glm_normal<1	//	PFS_glm<0.5
				replace	SFIG_indiv	=	0						if	!mi(PFS_glm_normal)	&	PFS_glm_normal>=1	//	PFS_glm>=0.5
			
				
			*	Total, Transient and Chronic FI
			
				*	Total FI	(Average HCR/SFIG over time)
				cap	drop	TFI_HCR
				cap	drop	TFI_FIG
				cap	drop	TFI_SFIG
				
				gen	TFI_HCR		=	PFS_FI_glm_total	/	num_nonmissing_PFS		
				gen	TFI_FIG		=	0
				gen	TFI_SFIG	=	0
				
				foreach time in 0 2 4	{
					
					replace	TFI_FIG		=	TFI_FIG		+	f`time'.FIG_indiv	if	!mi(f`time'.PFS_glm)
					replace	TFI_SFIG	=	TFI_SFIG	+	f`time'.SFIG_indiv	if	!mi(f`time'.PFS_glm)
					
				}
				
				*	Divide by the number of non-missing PFS (thus non-missing FIG/SFIG) to get average value
				replace	TFI_FIG		=	TFI_FIG		/	num_nonmissing_PFS
				replace	TFI_SFIG	=	TFI_SFIG	/	num_nonmissing_PFS
				
				*	Replace with missing if all PFS are missing.
				replace	TFI_HCR=.	if	num_nonmissing_PFS==0
				replace	TFI_FIG=.	if	num_nonmissing_PFS==0
				replace	TFI_SFIG=.	if	num_nonmissing_PFS==0
					
				*bys	fam_ID_1999:	egen	Total_FI_HCR	=	mean(PFS_FI_glm)	if	inrange(year,2,10)	//	HCR
				*bys	fam_ID_1999:	egen	Total_FI_SFIG	=	mean(SFIG_indiv)	if	inrange(year,2,10)	//	SFIG
				
				label	var	TFI_HCR		"TFI (HCR)"
				label	var	TFI_FIG		"TFI (FIG)"
				label	var	TFI_SFIG	"TFI (SFIG)"

				*	Chronic FI (SFIG(with mean PFS))					
				gen		CFI_HCR=.
				gen		CFI_FIG=.
				gen		CFI_SFIG=.
				replace	CFI_HCR		=	(1-PFS_glm_mean_normal)^0	if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal<1	//	Avg PFS < Avg cut-off PFS
				replace	CFI_FIG		=	(1-PFS_glm_mean_normal)^1	if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal<1	//	Avg PFS < Avg cut-off PFS
				replace	CFI_SFIG	=	(1-PFS_glm_mean_normal)^2	if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal<1	//	Avg PFS < Avg cut-off PFS
				replace	CFI_HCR		=	0							if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
				replace	CFI_FIG		=	0							if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
				replace	CFI_SFIG	=	0							if	!mi(PFS_glm_mean_normal)	&	PFS_glm_mean_normal>=1	//	Avg PFS >= Avg cut-off PFS (thus zero CFI)
				
				lab	var		CFI_HCR		"CFI (HCR)"
				lab	var		CFI_FIG		"CFI (FIG)"
				lab	var		CFI_SFIG	"CFI (SFIG)"
		
		*	Save
		compress
		save    "${SNAP_dtInt}/SNAP_const",	replace
		
	}
	