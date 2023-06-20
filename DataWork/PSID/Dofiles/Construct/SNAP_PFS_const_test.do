*	This do-file tests which regression model which we should use in constructing the PFS
*	Tests answers the following
	*	(1) Should we apply survey structure with "svy:" prefix? Also, which survey weight should we use?
		*	(2023-01-18) The answer to the first Q is NO, as it has nothing to do with regression coefficient
		*	(2023-06-20) The answer to the second Q is "doesn't matter", as it does not change regression coefficient
	*	(2) Should we include individual-FE using panel command (xt-, reghdfe, etc.)
		*	Yes, it seems
	*	(3) Should we use Gaussian or GLM with Poisson?
		*	GLM with Poisson
	*	(4) Should we apply mixed model which Steve suggested?
		*	(2023-01-18) I do not answer this question for now, since I don't know how to construct level1 and level2 weight in our analyses
		*	For now I only test with different wights, and conclude that different weights give neither non-significant nor non-trivial changes in regression coeffiicients.
	
	
local	survey_prefix=1
local	fixed_effects=0
local	distribution_test=1	
		
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
		
		
	*	(3)	Distribution check
			*	I previously use the GLM with Gamma distribution, but Wooldridge wrote that the Poisson quasi-MLE is consistent for ANY kind of non-negative response variables
				*	Source: https://www.statalist.org/forums/forum/general-stata-discussion/general/1578206-log-gamma-model-for-panel-data-glm-with-individual-fixed-effects
				*	Wooldridge, Jeffrey M. 1999. “Distribution-Free Estimation of Some Nonlinear Panel Data Models.” Journal of Econometrics 90 (1): 77–97. https://doi.org/10.1016/S0304-4076(98)00033-5.
			*	Since Stata built-in commands for GLM (xtpoission, xtgee, etc.) requires weight to be constatnt within individual, which is NOT our case, I use "ppmlhdfe" which allows non-constant weight.
				*	Source: Correia, Sergio, Paulo Guimarães, and Tom Zylkin. 2020. “Fast Poisson Estimation with High-Dimensional Fixed Effects.” The Stata Journal 20 (1): 95–115. https://doi.org/10.1177/1536867X20909691.
		if	`distribution_test'==1	{
		
		*	No controls, with all FE (individual-, region- and year-)
		cap	drop	dephat_gau
		cap	drop	dephat_glm
		cap	drop	sample_gau
		cap	drop	sample_glm
		cap	drop	error_gau
		cap	drop	error_glm
		
			
			*	Testing different Stata commands
				
				*	Gaussian distribution, clustered at individual-level
				
					*	Regression with neither survey weights nor fixed effects
					*	The following commands generate the same results
					reg		${depvar}	${statevars}, cluster(x11101ll)
					glm		${depvar}	${statevars}, family(gaussian) vce(cluster x11101ll)
							
					*	Regression without survey weight but state- and year-fixed effects only
					*	The following commands generate the same coefficients and nearly-identical standard error
					reg		${depvar}	${statevars}	${regionvars}	${timevars}, cluster(x11101ll)
					glm		${depvar}	${statevars}	${regionvars}	${timevars}	, family(gaussian) vce(cluster x11101ll)
					reghdfe		${depvar}	${statevars}, absorb(rp_state year) vce(cluster x11101ll)
				
					*	Regression with survey weight and state- and year- fixed effects (no individual-FE)
					*	The following 2 lines give the same coefficients and nearly-identical standard error (constant is different)
					reghdfe		${depvar}	${statevars}	[aw=wgt_long_fam_adj], absorb(ib31.rp_state ib1979.year) 
					glm 	${depvar}	${statevars}	${regionvars}	${timevars}		[aw=wgt_long_fam_adj], family(gaussian)
				
			
					
				
				*	Individual FE
				*	Regression with individual-FE only, no survey weight
				reg 	${depvar}	${statevars}, vce(cluster x11101ll)
				glm		${depvar}	${statevars}, family(gaussian)	vce(cluster x11101ll)
				xtgee	${depvar}	${statevars}, family(gaussian) link(identity) corr(exchangeable) robust

			
				
					*	Fixed-effects poisson
				*	The following line generates the same coefficients, but very different standard errors
				ppmlhdfe	${depvar}	${empvars}, absorb(x11101ll)  vce(cluster x11101ll)
				xtpqml		${depvar}	${empvars}, i(x11101ll) cluster(x11101ll)	//	Note: xtpqml does NOT allow survey weight, so cannot be used for this study
				
				* 		xtgee depvar [indepvars] [if] [in] [weight] [, options]
				//			reghdfe		${depvar}	${statevars}	[aw=wgt_long_fam_adj], absorb(rp_state year)			
				//	glm 	${depvar}	${statevars}	${regionvars}	${timevars}		[aw=wgt_long_fam_adj], family(gamma)	link(log)
	
			
			
	
			*	Gaussian
			reghdfe		${depvar}	${statevars}	[aw=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year)
			gen sample_gau=1 if 	e(sample)==1
			predict	double	dephat_gau	if	 sample_gau==1
			gen	error_gau	=	abs(dephat_gau-${depvar})	if	sample_gau==1
			
			*	Poisson fixed effects estimator
			*	Note that I use "pweight" instead of "aweight", since "aweight" is NOT allowed for this command. However, they both generate the same regression coefficient which is our interest
				*	They generate different SE, but we don't use SE in our case
				*	Source: Dupraz, Yannick. 2013. “Using Weights in Stata.” https://www.parisschoolofeconomics.eu/docs/dupraz-yannick/using-weights-in-stata(1).pdf.
			ppmlhdfe	${depvar}	${statevars} [pweight=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) d
			gen sample_glm=1 if 	e(sample)==1
			predict	double	dephat_glm	if	 sample_glm==1, mu
			gen	error_glm	=	abs(dephat_glm-${depvar})	if	sample_glm==1
			
			*	GLM with Gamma
			glm 	${depvar}	${statevars}	${demovars}	${eduvars}	${healthvars}	${empvars}	${familyvars}	${econvars}	regionvars	[aw=wgt_long_fam_adj], family(gamma)	link(log)
	
			*	Check the summary stats of the predicted values and RMSE
			*	GLM is non-trivially better, while Gaussian is less susceptable to outliers
			summ	${depvar}	dephat_gau	dephat_glm	error_gau	error_glm	if	sample_gau==1	&	sample_glm==1
			
			*	GLM with Gamma
			

		*	Controls (Note: takes some time for GLM), with all FE (individual-, region- and year-)
		cap	drop	dephat_gau
		cap	drop	dephat_glm
		cap	drop	sample_gau
		cap	drop	sample_glm
		cap	drop	error_gau
		cap	drop	error_glm
		
			*	Gaussian
			reghdfe		${depvar}	${statevars}	${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	[aw=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year)
			gen sample_gau=1 if 	e(sample)==1
			predict	double	dephat_gau	if	 sample_gau==1
			gen	error_gau	=	abs(dephat_gau-${depvar})	if	sample_gau==1
			
			*	GLM with Poisson
			*	Note that I use "pweight" instead of "aweight", since "aweight" is NOT allowed for this command. However, they both generate the same regression coefficient which is our interest
				*	They generate different SE, but we don't use SE in our case
				*	Source: Dupraz, Yannick. 2013. “Using Weights in Stata.” https://www.parisschoolofeconomics.eu/docs/dupraz-yannick/using-weights-in-stata(1).pdf.
			ppmlhdfe	${depvar}	${statevars} ${demovars}	${econvars}	${empvars}	${healthvars}	${familyvars}	${eduvars}	[pweight=wgt_long_fam_adj], absorb(x11101ll ib31.rp_state ib1979.year) d
			gen sample_glm=1 if 	e(sample)==1
			predict	double	dephat_glm	if	 sample_glm==1, mu
			gen	error_glm	=	abs(dephat_glm-${depvar})	if	sample_glm==1
	
			*	Check the summary stats of the predicted values and RMSE
			*	GLM is slightly better, and no negative values in predicted variable. Also the outlier in GLM still exists but less severe
			summ	${depvar}	dephat_gau	dephat_glm	error_gau	error_glm	if	sample_gau==1	&	sample_glm==1
			
			*	Based on the tests above, I conclude that using GLM with Poisson is better (and should use GLM to avoide negative predicted value).
		}
	
	
	*	(4) Should we apply mixed model which Steve suggested?
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
				