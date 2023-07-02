*	This do-file tests which regression model which we should use in constructing the PFS
*	Tests answers the following
	*	(1) Should we apply survey structure with "svy:" prefix? Also, which survey weight should we use?
		*	(2023-01-18) The answer to the first Q is NO, as it has nothing to do with regression coefficient
		*	(2023-06-20) The answer to the second Q is "doesn't matter", as it does not change regression coefficient
	*	(2) Should we include individual-FE using panel command (xt-, reghdfe, etc.)
		*	Yes, it seems
	*	(3) Should we use Gaussian or quasi-MLE Poisson for the step-1 and step-2?
		*	quasi-MLE Poisson
	*	(4) Which distributional assumption we should use - Gaussian, Poisson or Gamma?
		*	We use Gamma distribution
	*	(5) Should we apply mixed model which Steve suggested?
		*	(2023-01-18) I do not answer this question for now, since I don't know how to construct level1 and level2 weight in our analyses
		*	For now I only test with different wights, and conclude that different weights give neither non-significant nor non-trivial changes in regression coeffiicients.
	
	
local	survey_prefix=0
local	fixed_effects=0
local	estimation_test=0
local	distribution_test=0
		
*	Prepare data
use    "${SNAP_dtInt}/SNAP_cleaned_long",	clear
assert	in_sample==1
assert	inrange(year,1977,2019)
		
		
		*	Validate that all observations in the data are in_sample and years b/w 1977 and 2019
		assert	in_sample==1
		assert	inrange(year,1977,2019)
		
		*	Drop states outside 48 continental states (HA/AK/inapp/etc.), as we do not have their TFP cost information.
		drop	if	inlist(rp_state,0,50,51,99)
		
		*	Set globals
		
		*	Set globals
		global	statevars		l2_foodexp_tot_inclFS_pc_1_real l2_foodexp_tot_inclFS_pc_2_real
		global	demovars		rp_age rp_age_sq	rp_nonWhte	rp_married	rp_female	
		global	eduvars			rp_NoHS rp_somecol rp_col
		global	healthvars		rp_disabled
		global	empvars			rp_employed
		global	familyvars		famnum	ratio_child
		global	econvars		ln_fam_income_pc_real	
		// global	foodvars		FS_rec_wth	//	Should I use prected FS redemption from 1st-stage IV?, or even drop it for exclusion restriction?
		global	macrovars		unemp_rate	CPI
		global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1979) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
		
			
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
		
		*	Declare variables (food expenditure per capita, real value)
		global	depvar		foodexp_tot_inclFS_pc_real
		
			*	Summary state of dep.var
			summ	${depvar}, d
			*unique x11101ll if in_sample==1	&	!mi(foodexp_tot_inclFS_pc)
				
		
		
	*	(1) Should we apply survey structure with "svy:" previx?
	if	`survey_prefix'==1	{	
		
		*	No controls, lagged states only
			reg		${depvar}	${statevars}	[aw=wgt_long_fam_adj]	// no survey structure, aweight
			reg		${depvar}	${statevars}	[pw=wgt_long_fam_adj]	// no survey structure, pweight
			svy:	reg	${depvar}	${statevars}	//	survey structure
						
		*	Controls
			reg		${depvar}	${statevars}	${demovars}	${eduvars}	${healthvars}	${empvars}	${familyvars}	${econvars}	[aw=wgt_long_fam_adj]	// no survey structure, aweight
			reg		${depvar}	${statevars}	${demovars}	${eduvars}	${healthvars}	${empvars}	${familyvars}	${econvars}	[pw=wgt_long_fam_adj]	// no survey structure, pweight
			svy:	reg	${depvar}	${statevars}	${demovars}	${eduvars}	${healthvars}	${empvars}	${familyvars}	${econvars}	//	survey structure
		
		*	These identicial  in regression coefficients impliy that it is OK NOT using survey structure in constructing the PFS
		*	Also using different weights doesn't affect regression coefficients.
	}
	
	*	(2) Should we include individual-FE using panel structure? (xtreg, etc.)
		*	Answer: I think I should, which is different from what I did in the original PFS paper.
	
		if	`fixed_effects'==1	{
		
		*	No controls, lagged states only
		*	It seems including individual-FE makes a huge change in regression coefficient
			reg		${depvar}	${statevars}	[aw=wgt_long_fam_adj]	// no individual FE
			reghdfe	${depvar}	${statevars}, absorb(x11101ll) 	//	Individual FE

			*	Note: "reghdfe, absorbe(ID)" gives the same coefficient estimates generated from "xtreg, fe"
				*	reghdfe	${depvar}	${statevars}, absorb(x11101ll)	//	Individual FE
				*	xtreg	${depvar}	${statevars}, fe // individual-FE
			*	One advantage of "reghdfe" is that it allows survey weight varying individuals, while "xtreg, fe" does not
			
			*	For other Stata commands, please find the codes below
			local	test_different_commands=0
			if	`test_different_commands'==1	{
			    						
			*	Testing different Stata commands
				
				*	Gaussian distribution, clustered at individual-level
				
					*	Neither survey weights nor fixed effects
					*	The following commands generate the same results
					reg		${depvar}	${statevars}, cluster(x11101ll)
					glm		${depvar}	${statevars}, family(gaussian) vce(cluster x11101ll)
							
					*	Survey weight but state- and year-fixed effects only
					*	The following commands generate the same coefficients and nearly-identical standard error
					reg		${depvar}	${statevars}	${regionvars}	${timevars}, cluster(x11101ll)
					glm		${depvar}	${statevars}	${regionvars}	${timevars}	, family(gaussian) vce(cluster x11101ll)
					reghdfe		${depvar}	${statevars}, absorb(rp_state year) vce(cluster x11101ll)
				
					*	Survey weight and state- and year- fixed effects (no individual-FE)
					*	The following 2 lines give the same coefficients and nearly-identical standard error (constant is different)
					reghdfe		${depvar}	${statevars}	[aw=wgt_long_fam_adj], absorb(ib31.rp_state ib1979.year) 
					glm 	${depvar}	${statevars}	${regionvars}	${timevars}		[aw=wgt_long_fam_adj], family(gaussian)
				
					*	W/o survey weights, individual FE only
					*	The following two lines generate the same results
					areg		${depvar}	${statevars}, absorb(x11101ll)	//	areg cannot absorb multiple FE
					reghdfe		${depvar}	${statevars}, absorb(x11101ll)
					
				*	Poisson distribution
					
					*	No FE
					*	The following two lines generate the exact same results (regression coefficients and SE)
					glm			${depvar}	${statevars}	[pw=wgt_long_fam_adj], family(poisson) vce(cluster x11101ll)
					ppmlhdfe	${depvar}	${statevars}	[pw=wgt_long_fam_adj], vce(cluster x11101ll)
					
					*	State- and Year- FE
					*	The following two generate the same regression coefficients and SE (except constants)
					glm			${depvar}	${statevars}	${regionvars}	${timevars}	[pw=wgt_long_fam_adj], family(poisson) vce(cluster x11101ll)
					ppmlhdfe	${depvar}	${statevars}	[pw=wgt_long_fam_adj], absorb(ib31.rp_state ib1979.year)	vce(cluster x11101ll)
					
					*	Individual FE, but no weight
					*	The following three lines generat same regression coefficients. The first two have same SE, but the third one have larger SE
					*	However, the first two do NOT allow non-constant survey weights within unit, so we use the third one.
					xtpoisson	${depvar}	${empvars}, fe
					xtpqml		${depvar}	${empvars}, i(x11101ll)
					ppmlhdfe	${depvar}	${empvars}, absorb(x11101ll) 
							
					*	Individual, time and region FE with survey weight
					*	(2023-06-21) I cannot find any other command works. Maybe I can add later
					ppmlhdfe	${depvar}	${empvars}, absorb(x11101ll	ib31.rp_state ib1979.year)  vce(cluster x11101ll)
					
			}
			
		*	Controls
		cap	drop	dephat_nofe
		cap	drop	dephat_fe
		cap	drop	sample_nofe
		cap	drop	sample_fe
		
			*	Testing prediction accuracy
			reg			${depvar}	${statevars}	${demovars}	${eduvars}	${healthvars}	${empvars}	${familyvars}	${econvars}	[aw=wgt_long_fam_adj]	// no FE
			gen sample_nofe=1 if 	e(sample)==1
			predict	double	dephat_nofe	if	 sample_nofe==1
			gen	error_nofe = abs(dephat_nofe-${depvar})	if	sample_nofe==1
			
			reghdfe		${depvar}	${statevars}	${demovars}	${eduvars}	${healthvars}	${empvars}	${familyvars}	${econvars}	[aw=wgt_long_fam_adj], absorb(x11101ll)	//	Individual FE	// no survey structure	
			gen sample_fe=1 if 	e(sample)==1
			predict	double	dephat_fe	if	 sample_fe==1
			gen	error_fe = abs(dephat_fe-${depvar})	if	sample_fe==1
			
			summ	error_nofe	error_fe	if	sample_nofe==1 & sample_fe==1
			drop	error_nofe	error_fe
		
		*	Although non-individual-FE model has higher prediction accuracy, I find individual-FE model for two reasons
			*	(1) Theoretically, it is more sensible to include individual-FE
			*	(2) FE-included model has higher adjusted R2
			*	(3) Differece in prediction accuracy (size in error) are not non-trivial, but not that huge either.
			
			*	Note: reghdfe can be used to include multiple FE at the same time, such as regional- and time-FE)
			/*
				*	state FE only
				reg			${depvar}	${statevars} ${regionvars}	// ${timevars}
				reghdfe		${depvar}	${statevars}, absorb(ib31.rp_state)
				
				*	individual- and state-FE
				xtreg		${depvar}	${statevars} ${regionvars}, fe
				reghdfe		${depvar}	${statevars}, absorb(x11101ll ib31.rp_state)
				
				*	individual, state and year-FE
				xtreg		${depvar}	${statevars} ${regionvars} ${timevars}, fe				
				xtreg		${depvar}	${statevars} ${regionvars} ib1979.year, fe	
				reghdfe		${depvar}	${statevars}, absorb(x11101ll ib31.rp_state ib1979.year)
			*/
		}
		
		
	*	(3)	Estimation check (for step 1 and step 2)
			*	I previously use the GLM with Gamma distribution, but Wooldridge wrote that the Poisson quasi-MLE is consistent for ANY kind of non-negative response variables
				*	Source: https://www.statalist.org/forums/forum/general-stata-discussion/general/1578206-log-gamma-model-for-panel-data-glm-with-individual-fixed-effects
				*	Wooldridge, Jeffrey M. 1999. “Distribution-Free Estimation of Some Nonlinear Panel Data Models.” Journal of Econometrics 90 (1): 77–97. https://doi.org/10.1016/S0304-4076(98)00033-5.
			*	Since Stata built-in commands for GLM (xtpoission, xtgee, etc.) requires weight to be constatnt within individual, which is NOT our case, I use "ppmlhdfe" which allows non-constant weight.
				*	Source: Correia, Sergio, Paulo Guimarães, and Tom Zylkin. 2020. “Fast Poisson Estimation with High-Dimensional Fixed Effects.” The Stata Journal 20 (1): 95–115. https://doi.org/10.1177/1536867X20909691.
			*	(2023-6-21) I could NOT find running GLM with gamma with individual-FE. So we skip testing Gamma
			
		if	`estimation_test'==1	{
		
		
		*	No controls, w/o FE
		cap	drop	dephat_gau
		cap	drop	dephat_glm_pos
		cap	drop	dephat_glm_gam
		cap	drop	sample_gau
		cap	drop	sample_glm_pos
		cap	drop	sample_glm_gam
		cap	drop	error_gau
		cap	drop	error_glm_pos
		cap	drop	error_glm_gam
		
			*	Gaussian
			reg		${depvar}	${statevars}	[aw=wgt_long_fam_adj], vce(cluster x11101ll)
			gen sample_gau=1 if 	e(sample)==1
			predict	double	dephat_gau	if	 sample_gau==1
			gen	error_gau	=	abs(dephat_gau-${depvar})	if	sample_gau==1
			
			*	Poisson quasi-MLE
			ppmlhdfe	${depvar}	${statevars} [pweight=wgt_long_fam_adj], vce(cluster x11101ll)	d
			gen sample_glm_pos=1 if 	e(sample)==1
			predict	double	dephat_glm_pos	if	 sample_glm_pos==1
			gen	error_glm_pos	=	abs(dephat_glm_pos-${depvar})	if	sample_glm_pos==1
			
			*	GLM with Gamma
			glm	${depvar}	${statevars} [pweight=wgt_long_fam_adj], family(gamma) link(log) vce(cluster x11101ll)
			gen sample_glm_gam=1 if 	e(sample)==1
			predict	double	dephat_glm_gam	if	 sample_glm_gam==1
			gen	error_glm_gam	=	abs(dephat_glm_gam-${depvar})	if	sample_glm_gam==1
			
			*	Check the summary stats of the predicted values and RMSE
				
				*	Errors are the smallest with Gaussian (117), followed by Gamma (119) and Poisson (119). Differences are trivial
				summ	${depvar}	dephat_gau	dephat_glm_pos	dephat_glm_gam	error_gau	error_glm_pos	error_glm_gam	///
				[aweight=wgt_long_fam_adj]	if	sample_gau==1	&	sample_glm_pos==1	&	sample_glm_gam==1
				
				*	Median differences are the smallest with Gaussian (84), followed by Gamma (85) and Poisson (88)
				summ	${depvar}	error_gau	error_glm_pos	error_glm_gam	///
				[aweight=wgt_long_fam_adj]	if	sample_gau==1	&	sample_glm_pos==1	&	sample_glm_gam==1, d
			
		*	No controls, with all FE (individual-, region- and year-)
		*	Since we could not find including individual-FE with GLM-Gamma, we only compare Gaussian and Poisson quasi-MLE
		cap	drop	dephat_gau
		cap	drop	dephat_glm
		cap	drop	sample_gau
		cap	drop	sample_glm
		cap	drop	error_gau
		cap	drop	error_glm
		
	
			*	Gaussian
			reghdfe		${depvar}	${statevars}	[aw=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year)
			gen sample_gau=1 if 	e(sample)==1
			predict	double	dephat_gau	if	 sample_gau==1
			gen	error_gau	=	abs(dephat_gau-${depvar})	if	sample_gau==1
			
			*	Poisson quasi-MLE 
			*	Note that I use "pweight" instead of "aweight", since "aweight" is NOT allowed for this command. However, they both generate the same regression coefficient which is our interest
				*	They generate different SE, but we don't use SE in our case
				*	Source: Dupraz, Yannick. 2013. “Using Weights in Stata.” https://www.parisschoolofeconomics.eu/docs/dupraz-yannick/using-weights-in-stata(1).pdf.
			ppmlhdfe	${depvar}	${statevars} [pweight=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) d
			gen sample_glm=1 if 	e(sample)==1
			predict	double	dephat_glm	if	 sample_glm==1, mu
			gen	error_glm	=	abs(dephat_glm-${depvar})	if	sample_glm==1
			
			*	Check the summary stats of the predicted values and RMSE
			*	Poisson quasi-MLE non-trivially better (102 vs 131), while Gaussian is less susceptable to outliers (1089 vs 1235)
			summ	${depvar}	dephat_gau	dephat_glm	error_gau	error_glm	[aw=wgt_long_fam_adj]	if	sample_gau==1	&	sample_glm==1
			

		*	Controls (Note: takes some time for GLM), with all FE (individual-, region- and year-)
		cap	drop	dephat_gau
		cap	drop	dephat_glm
		cap	drop	sample_gau
		cap	drop	sample_glm
		cap	drop	error_gau
		cap	drop	error_glm
		
			*	Gaussian
			reghdfe		${depvar}	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[aw=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) vce(cluster x11101ll)
			gen sample_gau=1 if 	e(sample)==1
			predict	double	dephat_gau	if	 sample_gau==1
			gen	error_gau	=	abs(dephat_gau-${depvar})	if	sample_gau==1
			
			*	GLM with Poisson
			*	Note that I use "pweight" instead of "aweight", since "aweight" is NOT allowed for this command. However, they both generate the same regression coefficient which is our interest
				*	They generate different SE, but we don't use SE in our case
				*	Source: Dupraz, Yannick. 2013. “Using Weights in Stata.” https://www.parisschoolofeconomics.eu/docs/dupraz-yannick/using-weights-in-stata(1).pdf.
			ppmlhdfe	${depvar}	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[pweight=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year)  vce(cluster x11101ll) d
			gen sample_glm=1 if 	e(sample)==1
			predict	double	dephat_glm	if	 sample_glm==1, mu
			gen	error_glm	=	abs(dephat_glm-${depvar})	if	sample_glm==1
	
			*	Check the summary stats of the predicted values and RMSE
			*	GLM is non-trivially better (91 vs 120), and no negative values in predicted variable. Also the outlier in GLM still exists but less severe
			summ	${depvar}	dephat_gau	dephat_glm	error_gau	error_glm	[aw=wgt_long_fam_adj]	if	sample_gau==1	&	sample_glm==1
			
			*	Based on the tests above, I conclude that using GLM with Poisson is better (and should use GLM to avoide negative predicted value).
		}
	
	
	*	(4) Distribution check (for step 3)
		*	We previously assumed the food expenditure follows Gamma distribution.
		*	We will check the difference among three resilience measures; Gaussian, Poisson and Gamma
		*	Step-1 and Step-2 will be estimated using quasi-MLE poisson, as we validated above.
		if	`distribution_check'==1	{
		    
		cap	drop	dephat_gau
		cap	drop	dephat_pos
		cap	drop	sample_gau
		cap	drop	sample_pos
		cap	drop	sample_gau_step2
		cap	drop	sample_pos_step2
		cap	drop	error_gau
		cap	drop	error_pos
		
		
		*	We first estimate step-1 and step-2 using two different methods; Gaussian and Poisson quasi-MLE (which we validated the latter is better, but we still generate Gaussian for testing purpose)
		
		*	Step 1 and Step 2 with Guassian
		
			*	Step 1
			reghdfe		${depvar}	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[aw=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) vce(cluster x11101ll) resid
			gen sample_gau=1 if 	e(sample)==1
			predict	double	dephat_gau	if	 sample_gau==1
			predict double e1_foodexp_gau		if	sample_gau==1,r
			gen e1_foodexp_sq_gau = (e1_foodexp_gau)^2	if	sample_gau==1
			
			*	Step 2
			local	depvar	e1_foodexp_sq_gau
			reghdfe		`depvar'	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[aw=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) vce(cluster x11101ll) resid
			gen	sample_gau_step2=1	if	e(sample)==1 
			predict	double	var1_foodexp_gau	if	sample_gau_step2==1	
			gen	sd_foodexp_gau	=	sqrt(abs(var1_foodexp_gau))	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
			gen	error_var1_gau	=	abs(var1_foodexp_gau - e1_foodexp_sq_gau)	//	prediction error. 
			
		*	Step 1 and Step 2 with Poisson quasi-MLE

			ppmlhdfe	${depvar}	${statevars} ${demovars}	${eduvars} 	${empvars}	${healthvars}	${familyvars}	${econvars}		[pweight=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) d	
			gen		sample_pos=1	if	e(sample)==1 // e(sample) includes both subpopulation and non-subpopulation, so we need to include subpop condition here to properly restrict regression sample.
			predict double mean1_foodexp_pos	if	sample_pos==1
			predict double e1_foodexp_pos		if	sample_pos==1,r
			gen e1_foodexp_sq_pos = (e1_foodexp_pos)^2	if	sample_pos==1
			
			
			local	depvar	e1_foodexp_sq_pos
			ppmlhdfe	`depvar'	${statevars} ${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	[pweight=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) d	
			gen	sample_pos_step2=1	if	e(sample)==1 
			predict	double	var1_foodexp_pos	if	sample_pos_step2==1	
			
			gen	sd_foodexp_pos	=	sqrt(abs(var1_foodexp_pos))	if	sample_pos_step2==1	//	Take square root of absolute value, since predicted value can be negative which does not have square root.
			gen	error_var1_pos	=	abs(var1_foodexp_pos - e1_foodexp_sq_pos)	if	sample_pos_step2==1	//	prediction error. 
			
			*	Error in step 2: Poisson is better (11,859 vs 15,449)
			summ	e1_foodexp_sq_gau	e1_foodexp_sq_pos	error_var1_gau	error_var1_pos	if	sample_gau_step2==1	&	sample_pos_step2==1	
			
		*	Construct PFS under distributional assumptions
		
			*	Normally distributed, generated from Gaussian step1/2
			gen thresh_foodexp_gau_gau=(foodexp_W_TFP_pc_real-dephat_gau)/sd_foodexp_gau	// Let 2 as threshold
			gen prob_below_foodexp_gau_gau=normal(thresh_foodexp_gau_gau)
			gen PFS_gau_gau		=	1-prob_below_foodexp_gau_gau
			
			*	Gamma distributed, generated from Gaussian step 1/2
				*	Since predicted values from Guassian distribution have negative predicted variance, we need to use their absolute values or PFS won't be generated
			gen alpha1_foodexp_pc_gau	= abs((dephat_gau)^2 / var1_foodexp_gau) //	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_gau	= abs(var1_foodexp_gau / dephat_gau)		//	scale parameter of Gamma (beta)
			
			gen PFS_gam_gau = gammaptail(alpha1_foodexp_pc_gau, foodexp_W_TFP_pc_real/beta1_foodexp_pc_gau)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
			
			*	Poisson distribution, generated from Gaussian step 1 & 2
			gen PFS_pos_gau = poissontail(dephat_gau,foodexp_W_TFP_pc_real)	
			
			*	Plots
				*	Poisson distribution has very strange distribution, while the other two have similar distributions
			graph twoway 	(kdensity PFS_gau_gau if !mi(PFS_gau_gau) & !mi(PFS_gam_gau) & !mi(PFS_pos_gau))	///
							(kdensity PFS_gam_gau if !mi(PFS_gau_gau) & !mi(PFS_gam_gau) & !mi(PFS_pos_gau))	///
							(kdensity PFS_pos_gau if !mi(PFS_gau_gau) & !mi(PFS_gam_gau) & !mi(PFS_pos_gau))	
							
			*	Normally distributed, generated from Poisson quasi MLE step 1-2
			gen thresh_foodexp_gau_pos=(foodexp_W_TFP_pc_real-mean1_foodexp_pos)/sd_foodexp_pos	// Let 2 as threshold
			gen prob_below_foodexp_gau_pos=normal(thresh_foodexp_gau_pos)
			gen PFS_gau_pos		=	1-prob_below_foodexp_gau_pos
			
			*	Gamma distributed, generated from Poisson quasi-MLE step 1/2
			gen alpha1_foodexp_pc_pos	= abs((mean1_foodexp_pos)^2 / var1_foodexp_pos) //	shape parameter of Gamma (alpha)
			gen beta1_foodexp_pc_pos	= abs(var1_foodexp_pos / mean1_foodexp_pos)		//	scale parameter of Gamma (beta)
			
			gen PFS_gam_pos = gammaptail(alpha1_foodexp_pc_pos, foodexp_W_TFP_pc_real/beta1_foodexp_pc_pos)	//	gammaptail(a,(x-g)/b)=(1-gammap(a,(x-g)/b)) where g is location parameter (g=0 in this case)
			
			*	Poisson distribution, generated from Gaussian step 1 & 2
			gen PFS_pos_pos = poissontail(mean1_foodexp_pos,foodexp_W_TFP_pc_real)	
			
			*	Summary stats
			summ	PFS_gau_pos	PFS_gam_pos	PFS_pos_pos
			
			*	Plots
				*	Same as what we observe fraom the Gaussian distribution above.
			graph twoway 	(kdensity PFS_gau_pos if !mi(PFS_gau_pos) & !mi(PFS_gam_pos) & !mi(PFS_pos_pos))	///
							(kdensity PFS_gam_pos if !mi(PFS_gau_pos) & !mi(PFS_gam_pos) & !mi(PFS_pos_pos))	///
							(kdensity PFS_pos_pos if !mi(PFS_gau_pos) & !mi(PFS_gam_pos) & !mi(PFS_pos_pos))	
			
		
		}
	
	*	(5) Should we apply mixed model which Steve suggested?
	*	(2023-1-18) I disable this code for now, as I don't have a solution
	*	I will complete the code once needed.
	
	/*
	
	
		*	Construct lv1 and lv2 weights based on "adjusted longitudinal family weight"
		*	Should go into "SNAP_clean.do" file. Will move later
		cap	drop	lv1wgt
		cap	drop	lv2wgt
		*gen	lv1wgt	=	wgt_
		
		
	
			*	mixed model
				cap	drop	unique_secu
				egen	unique_secu	=	group(sampstr	sampcls)
				
				*	Lv 1 weight should be constant within individuals. We use 
				
				mixed ${depvar} ${statevars} ///
   i.sampstr [pweight = level1wgt_r] ///
   || newid_num: yrssince06 yrs06sq, ///
   variance cov(unstruct) ///
   pweight(level2wgt) pwscale(size) ///
   vce(cluster unique_secu)
*/
				