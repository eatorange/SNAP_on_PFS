

*	This do-file tests different IV regression models
	*	different IV
	*	different FE
	*	etc.
	
*	After test is done, please update "SNAP_ivreg.do" file which does analyses
	
*	Please check 
	*	IV regression
	if	`IV_reg'==1	{
			
		*	Weak IV test 
		*	(2022-05-01) For now, we use IV to predict T(FS participation) and use it to predict W (food expenditure per capita) (previously I used it to predict PFS in the second stage)
		use	"${SNAP_dtInt}/SNAP_const", clear
		
		
			
		*	(Corrlation and bivariate regression of stamp redemption with state/govt ideology)
		pwcorr	FS_rec_wth	citi6016 inst6017_nom 	if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	sig
		reg	FS_rec_wth	citi6016	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	///
					robust	cluster(x11101ll) 
		reg	FS_rec_wth	inst6017_nom	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	///
					robust	cluster(x11101ll) 
		
		
		*	Set globals
		global	statevars		l2_foodexp_tot_inclFS_pc_1_real	l2_foodexp_tot_inclFS_pc_2_real 
		global	demovars		rp_age rp_age_sq	rp_nonWhte	rp_married	rp_female	
		global	econvars		ln_fam_income_pc_real	
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child	change_RP
		global	empvars			rp_employed
		global	eduvars			rp_NoHS rp_somecol rp_col
		//global	foodvars		FS_rec_wth
		global	macrovars		unemp_rate	CPI
		global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1978) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
		
		
		label	var	FS_rec_wth	"FS last month"
		label	var	foodexp_tot_inclFS_pc_real	"Food exp (with FS benefit)"
		label	var	l2_foodexp_tot_inclFS_pc_1_real	"Food Exp in t-2"
		label	var	l2_foodexp_tot_inclFS_pc_2_real	"(Food Exp in t-2)$^2$"
		label	var	rp_age		"Age (RP)"
		label	var	rp_age_sq	"Age$^2$ (RP)"
		label	var	change_RP	"RP changed"
		label	var	ln_fam_income_pc_real	"ln(per capita income)"
		label	var	unemp_rate	"State Unemp Rate"
		label	var	major_control_dem	"Dem state control"
		label	var	major_control_rep	"Rep state control"
		label	var	SSI_GDP_sl	"SSI"
				
		*	Temporary renaming	
		rename	(SNAP_index_unweighted	SNAP_index_weighted)	(SNAP_index_uw	SNAP_index_w)
		lab	var	SNAP_index_uw 	"Unweighted SNAP index"
		lab	var	SNAP_index_w 	"Weighted SNAP index"
		
		
		
		
		*	Temporary create a copy of endogenous variable (name too long)
		
			*	FS amount per capita (this is included in the clean variable. I added here temporarily but can be erased.)
			loc	var	FS_rec_amt_capita
			cap	drop	`var'
			gen	`var'	=	FS_rec_amt_real	/	famnum
			lab	var	`var'	"FS/SNAP amount receive last month per capita"
		
			*	Other variables
			cap	drop	FSdummy	FSamt	FSamtK
			clonevar	FSdummy	=	FS_rec_wth
			clonevar	FSamt	=	FS_rec_amt_real
			clonevar	FSamt_capita	=	FS_rec_amt_capita
			
			gen			FSamtK	=	FSamt/1000
			lab	var		FSamtK	"Stamp benefit (USD) (K)"
			
			cap	drop	FS_amt_real
			cap	drop	FS_amt_realK
			clonevar	FS_amt_real		=	FS_rec_amt_real
			gen			FS_amt_realK	=	FS_rec_amt_real	/	1000
			
		
	
		*	Temporarily rescale SSI and share variables (0-1 to 1-100)
		qui	ds	share_edu_exp_sl-SSI_GDP_s
		
		foreach	var	in	`r(varlist)'		{
		    
			replace	`var'=	`var'*100		if	!mi(`var')	&	!inrange(`var',1,100) // This condition make sure that we do not double-scale it (ex. later fixed it in the "clean" part but forgot to fix it here.)
			assert	inrange(`var',0,100)	if	!mi(`var')
		}
		
		*	Temporary rescale lagged food exp^2
		replace	l2_foodexp_tot_inclFS_pc_2_real	=	l2_foodexp_tot_inclFS_pc_2_real/1000
		lab	var	l2_foodexp_tot_inclFS_pc_2_real		"Food exp in t-2 (K)"
		
		*	Temporary generate state control categorical variable
		cap	drop	major_control_cat
		gen			major_control_cat=.
		replace		major_control_cat=0	if	major_control_mix==1
		replace		major_control_cat=1	if	major_control_dem==1
		replace		major_control_cat=2	if	major_control_rep==1
		lab	define	major_control_cat	0	"Mixed"	1	"Demo control"	2	"Repub control"
		lab	val		major_control_cat	major_control_cat
		lab	var		major_control_cat	"State control"
		
		*	Temporary generate interaction variable
		gen	int_SSI_exp_sl_01_03	=	SSI_exp_sl	*	year_01_03
		gen	int_SSI_GDP_sl_01_03	=	SSI_GDP_sl	*	year_01_03
		gen	int_share_GDP_sl_01_03	=	share_welfare_GDP_sl	*	year_01_03
		*gen	int_SSI_GDP_sl_post96	=	SSI_GDP_sl	*	post_1996
		*gen	int_SSI_GDP_s_post96	=	SSI_GDP_s	*	post_1996
		
		lab	var	year_01_03				"{2001,2003}"
		lab	var	int_SSI_exp_sl_01_03	"SSI X {2001_2003}"
		lab	var	int_SSI_GDP_sl_01_03	"SSI X {2001_2003}"
		lab	var	int_share_GDP_sl_01_03	"Social expenditure share X {2001_2003}"
		
			
		*		
			
			
		*	Regression test
		*	For now we test 4 models
			*	(1) Political vars and state-level SSI, without FE
			*	(2) Political vars and state-level SSI, with FE
			*	(3) Political vars and state&local level SSI, without FE
			*	(4) Political vars and state&local level SSI, with FE
			
			*	(1) P and S-SSI, without FE
			*	Before we proceed, let's see whether there are big differences between analytical weight without survey structure, and using survey structure
		
			
				/*				
				* Checking difference in results between different regression methods. Disbled by default.
				
				loc	IV		SSI_GDP_sl
				loc	IVname	SSI_GDP_sl
			
				*	1. Manual do 2SLS reg (analytic weight)
					
					*	1st-stage
					reg	`endovar'	`IV'	${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	time	///
						[aw=wgt_long_fam_adj]	if	in_sample==1 & inrange(year,1977,2019), robust	cluster(x11101ll)
					
					*	Predict
					cap	drop	FS_rec_wth_hat
					predict FS_rec_wth_hat if e(sample),xb
					
					*	2nd stage
					reg	`depvar'	FS_rec_wth_hat	${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	time	///
						[aw=wgt_long_fam_adj]	if	in_sample==1 & inrange(year,1977,2019), robust	cluster(x11101ll)
					
					drop	FS_rec_wth_hat
				
						
					*	2. Manual 1st-stage reg (survey structure)
					svy: reg	`endovar'	`IV'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	///
						if	in_sample==1 & inrange(year,1977,2019)
									
					
					*	3. IV-reg (with analytic weight)
					ivregress	2sls 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}	${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019), first vce(cluster x11101ll)
					estat firststage
					
					*	4. IV-reg (with survey structure)
					svy: ivregress	2sls 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	///
						if	in_sample==1 & inrange(year,1977,2019), first
					*estat firststage
					
					
					*	5. IV-reg (with analytic weight, ivreg2 does not allow survey structure)
					ivreg2 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IV')
				*/
							
			*	The results show that
				*	Comparing analytic weight and survey structure (1 vs 2, 3 vs 4
					*	(1) and (3) give same coefficients and st.errors in the first stage, but slightly different results in both results in 2nd-stage
					*	(2) and (4) give they give same coefficients with very similar standard errors in the first stage. Second stage?
				*	Comparing manual 1st-stage and ivregress 1st-stage (1 vs 3, 2 vs 4): Both coefficients and standard errors differ (but why?). Coefficients differ not by significantly but non-trivially either.
				*	Comparing vreg2 aw (5) with ivregress (aw) (3), svy: ivregress (4) and i: (5) have same coefficients with (3) and (4)
					*	With individual-level cluster error, (5) and (3) give the same standard error.
				*	=>	I will use (5) now, arguing that (5) and (4) have same coefficients with different standard error.
			
			
			/*	Comparing results between (1) S&L share with 01/03 interaction and (2) state share only. Disabled by default
			
				*	SSI (share of s&l exp as % of GDP), with 2001/2003 interaction
				loc	IV		SSI_GDP_sl
				loc	IVname	SSI_GDP_sl
				ivreg2 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	int_SSI_exp_sl_01_03	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IV')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
				
				*	SSI (share of s exp as % of GDP)
				loc	IV		SSI_GDP_s
				loc	IVname	SSI_GDP_s
				ivreg2 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IV')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
					
				*	Very similar results both in first and second, so we will stick to S&L GDP.

			*/
			
			/*
			*	Benchmark
			*	All IVs, w/o state FE, w/o time trend
			loc	IV	SSI_GDP_sl	int_SSI_exp_sl_01_03	major_control_dem major_control_rep	
			loc	IVname	all_bench
			ivreg2 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')		[aw=wgt_long_fam_adj]	///
				if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			
										
				*	All IVs, w/o state FE, time trend
				loc	IV	SSI_GDP_sl	int_SSI_exp_sl_01_03	major_control_dem major_control_rep	
				loc	IVname	all_trend
				ivreg2 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	time	(`endovar'	=	`IV')		[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
				
				*	All IVs, with state FE, no time trend
				loc	IV	SSI_GDP_sl	int_SSI_exp_sl_01_03	major_control_dem major_control_rep	
				loc	IVname	all_FE
				ivreg2 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	${regionvars}	/*${timevars}*/	(`endovar'	=	`IV')		[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
				
				*	All IVs, with state FE, with time trend
				loc	IV	SSI_GDP_sl	int_SSI_exp_sl_01_03	major_control_dem major_control_rep	
				loc	IVname	all_FE_trend
				ivreg2 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	${regionvars}	/*${timevars}*/	time	(`endovar'	=	`IV')	///
					[aw=wgt_long_fam_adj]		if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
			
				*	1st-stage
				esttab	all_bench_1st	all_trend_1st	all_FE_1st	all_FE_trend_1st 	using "${SNAP_outRaw}/WeakIV_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(Fstat, fmt(%8.3fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
						title(Weak IV_1st)		replace	
						
				*	2nd-stage
				esttab	all_bench_2nd	all_trend_2nd	all_FE_2nd	all_FE_trend_2nd 	using "${SNAP_outRaw}/WeakIV_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(Fstat, fmt(%8.3fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
						title(Weak IV_2nd)		replace	
			*/
			
			*	Specification test
			*	Specification Test to see which one has 1) valid 1st-stage F-test and (2) reasonable effect size.
			*	(2022-9-13). Disable by default Turn it on when needed			
			
			local	spec_test	0	//	specification test
			if	`spec_test'==1'	{
			
				*	The following specification/sample will be tested
				*	Different endogenous variables
					*	Participation only
					*	Amount only
					*	Participation and amount
				*	Different IVs
					*	Single IV
						*	SSI
						*	State control
						*	Share of social expenditure only
						*	Don't forget to interact SSI/expenditure with state control!
					*	Double IV
						*	SSI and state control
						*	Share of social expenditure and state control
				*	Different fixed effects
					*	State FE only
					*	Year FE only
					*	State and year
				*	Different samples
					*	All Households
					*	Households with monthly income less than 130%/200% of poverty line (SNAP income eligibility)
		
			
			
			
						
			global	depvar	PFS_glm
			global	endo1	FSdummy
			global	endo2	FSamt_capita
			
			 
			
			/*
			global	IV1		SSI_GDP_sl
			global	IV2		SSI_GDP_sl	year_01_03	int_SSI_GDP_sl_01_03	
			global	IV3		share_welfare_GDP_sl
			global	IV4		i.major_control_cat
			*/
			
			global	IV1		share_welfare_GDP_sl	
			global	IV2		SNAP_index_uw
			global	IV3		SNAP_index_w
			global	IV4		error_total
			
			global	st0
			global	st1		${statevars}
			global	st2		l2.PFS_glm
					
			global	sp1		in_sample==1 & inrange(year,1977,2019)
			global	sp2		in_sample==1 & inrange(year,1977,2019)  & income_below_200==1
			*global	sp3		in_sample==1 & inrange(year,1977,2019)	& !inlist(year,2001,2003)
			*global	sp4		in_sample==1 & inrange(year,1977,2019)  & income_below_200==1	&	!inlist(year,2001,2003)
			
			global	FE0
			global	FE1		${macrovars}
			global	FE2		${timevars}
			global	FE3		${regionvars}
			global	FE4		${regionvars}	${macrovars}
			global	FE5		${regionvars}	${timevars}
			
			
								
			global	test_est_1st
			global	test_est_2nd	
//_13010_13245


			forval	endonum	=	1/1	{				
				forval	IVnum	=	1/2	{
					forval	stnum	=0/2	{
						forval	spnum=1/2	{
							forval	FEnum=0/5	{
								
								loc	IVname	x`endonum'`IVnum'`stnum'`spnum'`FEnum'
								
								ivreg2 	${depvar}	${st`stnum'}	///
								${demovars} ${econvars}	${healthvars}	${empvars}	${familyvars}	${eduvars}	${FE`FEnum'}	///
										(${endo`endonum'}	=	${IV`IVnum'})	[aw=wgt_long_fam_adj]	///
								if	${sp`spnum'},	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
								
								
								est	store	`IVname'_2nd
								
								scalar	Fstat_CD_`IVname'	=	 e(cdf)
								scalar	Fstat_KP_`IVname'	=	e(widstat)
								
								est	restore	`IVname'${endo`endonum'}
								estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
								estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace
								est	store	`IVname'_1st
								est	drop	`IVname'${endo`endonum'}
													
								global	test_est_1st	${test_est_1st}	`IVname'_1st
								global	test_est_2nd	${test_est_2nd}	`IVname'_2nd
								
									*	Add dynamic effects.
									*	First, predict FS amount received
									est restore `IVname'_1st
									cap	drop	xhat`IVname'
									predict 	xhat`IVname', xb
									lab	var		xhat`IVname'	"Predicted depvar"
								
									*	Now, regress 2nd stage, including FS across multiple periods
									reg	PFS_glm xhat`IVname'	l2.xhat`IVname'	///
										${st`stnum'}	${demovars} ${econvars}	${healthvars}	///
										${empvars}	${familyvars}	${eduvars}	${FE`FEnum'}	[aw=wgt_long_fam_adj]	///
												if	${sp`spnum'},	robust	cluster(x11101ll) 
										est	store	`IVname'_dyn_2nd
									
										global	test_est_2nd	${test_est_2nd}	`IVname'_dyn_2nd							
						
							}
						}
					}	//	st(state)
				}		//	IV			
			}	//	endo
			

			
			*	1st-stage
			esttab	${test_est_1st}	using "${SNAP_outRaw}/test_1st.csv", ///
					cells(b(star fmt(%8.4f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) ///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	///
					/*drop(rp_state_enum*)*/	title(test specification 1st)		replace	
			
			*	2nd-stage
			esttab	${test_est_2nd}	using "${SNAP_outRaw}/test_2nd.csv", ///
					cells(b(star fmt(%8.4f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() ///
					label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
					title(test specification 2nd)		replace		
			
			} // specification test
			
			 
	
						
			
			
			*	Set up global			
			global	FSD_on_FS_X			${statevars}	${demovars} ${econvars}	${healthvars}	${empvars}	${familyvars}	${eduvars} 	${macrovars}
			global	FSD_on_FS_X_nomacro	${statevars}	${demovars} ${econvars}	${healthvars}	${empvars}	${familyvars}	${eduvars}
	
			global	PFS_est_1st
			global	PFS_est_2nd
			
				
			
			*	(2023-1-20) Checking with individual fixed effects.
			*	I tested different IVs (social spending, SNAP index, overpayment rate (national & state), political ideology (government and citizen)), with and without individual FE
			*	After testing, I found the following specifications give some credible results
				*	(1)	SSI, state- and individual- FE, entire study period(1978-2019): relevant(17.8), 1st-stage negative and insignificant (-0.0017), 2nd-stage OK (0.17)
					*** 1st-stage result is negative, dunno why....
				*	(2) State citizen ideology, state- and indiviudal-FE, 1977-2015: relevant (20.84), 1st-stage negative (-0.0013) -> negative relation b/w being liberal and FS redemption, 2nd stage OK (0.07)
				*	(3) State citizen & and govt ideology, state- and indiv-FE, 1977-2015: relevant (10.8), 1st-stage: govt insignificant, citizen negatively associated (-0.001), 2nd-stage OK(0.09), overidentification test OK (p-val: 0.85), 2nd-stage: 0.07
				*	(4) SNAP policy index (weighted, standardized), state- and individual-FE, 1996-2015: F-stat (19.8) and 2nd-stage (0.29) same as unstandardized, 1st-stage 0.014
				
				*** Problem: When I restrict study sample to the periods when SNAP policy index is available, both SSI and citizen ideology goes crazy (weak IV and/or negative 2nd-stage effect)
		
				
				
				*	SNAP index (weighted)
				*	Data available: 1996, 1997-2015 (every 2 year)
				
					
					*	(O) State FE, no individual FE: relevant (F-stat: 19.8), 1st-stage positively significant (0.007), 2nd-stage bit high (0.29)
						loc	IV	SNAP_index_w
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(ib31.rp_state) robust	first savefirst 
					
					*	(X) State FE, no individual FE, year FE (no macro variables)
					*	Very weak (F-stat less than 1), 2nd stage less sensible
						*ivreghdfe	PFS_glm	${FSD_on_FS_X_nomacro}	(FSdummy = SNAP_index_w)	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SNAP_index_w),	absorb(ib31.rp_state ib1979.year) robust	first savefirst 
					
					*	(O) State FE, individual FE: relevant (13.0), 1st-stage positively sig (0.005), 2nd-stage bit too high (0.31)
						loc	IV	SNAP_index_w
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(x11101ll ib31.rp_state) robust	first savefirst 
					
					*	(X) State FE, individual FE, no year FE (macro vars), SE clustered at family: weak IV (9.8)
						*loc	IV	SNAP_index_w
						*ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(x11101ll ib31.rp_state) robust cluster(surveyid)	first savefirst 
				
				*	SNAP index (weighted, standardized)
				cap drop SNAP_index_w_std
				summ	SNAP_index_w
				gen	SNAP_index_w_std = (SNAP_index_w - r(mean)) / r(sd)
				lab	var	SNAP_index_w_std	"SNAP policy index (weighted \& standardized)"
				
					
					*	(O) State FE, no individual FE: F-stat (19.8) and 2nd-stage (0.29) same as unstandardized, 1st-stage 0.018
						loc	IV	SNAP_index_w_std
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(ib31.rp_state) robust	first savefirst 
						
					*	(O) State and individual FE: F-stat (19.8) and 2nd-stage (0.29) same as unstandardized, 1st-stage 0.014
						
						*	OLS
						loc	IV	SNAP_index_w_std
						reghdfe	PFS_glm	FSdummy	${FSD_on_FS_X}	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(x11101ll	ib31.rp_state) vce(robust)
						
						*	iV
						loc	IV	SNAP_index_w_std
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(x11101ll ib31.rp_state) robust	first savefirst 
				
					
				*	(X) SNAP policy index (unweighted)
				
					*	(X) State FE, no individual FE: weak IV (1.8)
						loc	IV	SNAP_index_uw
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(ib31.rp_state) robust	first savefirst 
						
					*	(X) State and individual FE: Weak IV (1.08)
						loc	IV	SNAP_index_uw
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(x11101ll ib31.rp_state) robust	first savefirst 
						
				
				*	SSI
					
					
					*	(X) No FE at all
						
						*	OLS, period (1977-2019)
						reghdfe	PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SSI_GDP_sl),	noabsorb
						
						*	(X) Period: 1977-2019: relevant (41.4), 1st-stage positive (0.004), but 2nd-stage negative (-0.057)
						loc	IV	SSI_GDP_sl	 year_01_03 int_SSI_GDP_sl_01_03
						ivreghdfe	PFS_glm	 ${FSD_on_FS_X}	 (FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SSI_GDP_sl),	/*absorb(ib31.rp_state)*/ robust	first savefirst 	
						
						*	(X) Period: 1996-2015: negative 2nd stage
						loc	IV	SSI_GDP_sl	 year_01_03 int_SSI_GDP_sl_01_03
						ivreghdfe	PFS_glm	 ${FSD_on_FS_X}	 (FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SSI_GDP_sl) &  !mi(SNAP_index_w),	/*absorb(ib31.rp_state)*/ robust	first savefirst 	
					
					*	state FE, no individual FE
					
						*	OLS, period 1977-2019
						reghdfe	PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SSI_GDP_sl),	absorb(ib31.rp_state)
						
						*	(O) Period: 1977-2019: relevance OK(36), 1st-stage negative (-0.008), 2nd-stage OK (0.06)
						loc	IV	SSI_GDP_sl	year_01_03 int_SSI_GDP_sl_01_03
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	 (FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SSI_GDP_sl),	absorb(ib31.rp_state) robust	first savefirst 		
					
						*	(X) Period: 1996-2015 (to be consistent with SNAP index): IV OK (10.8) 2nd-stage negative (-0.26)
						loc	IV	SSI_GDP_sl	year_01_03	int_SSI_GDP_sl_01_03
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SSI_GDP_sl) &  !mi(SNAP_index_w),	absorb(ib31.rp_state) robust	first savefirst 
						
					
					*	State FE, individual FE
					
						*	OLS
						reghdfe	PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SSI_GDP_sl),	absorb(x11101ll ib31.rp_state)
						
						*	(O) Period: 1977-2019: relevant(17.8), 1st-stage negative and insignificant (-0.0017), 2nd-stage OK (0.17)
						loc	IV	SSI_GDP_sl	year_01_03	int_SSI_GDP_sl_01_03
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	 (FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SSI_GDP_sl),	absorb(x11101ll ib31.rp_state) robust	first savefirst 
					
						*	(X) Period: 1996-2015 (to be consistent with SNAP index): weak IV (5.5), 1st-stage neg and insig, 2nd-stage negative (-0.27).
						loc	IV	SSI_GDP_sl	year_01_03	int_SSI_GDP_sl_01_03
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(SSI_GDP_sl) & !mi(SNAP_index_w),	absorb(x11101ll ib31.rp_state) robust	first savefirst 
			
				
		
				
				*	(X) "Natinoal" SNAP overpayment error rate
						
					*	(X) State FE, no individual FE
						
						* (X) Period: 1980-2019: weak IV(4.5), 2nd-stage too large (2.4)
						loc	IV	error_over_ntl
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(ib31.rp_state) robust	first savefirst 
						
						* (X) Period: 1996-2015: weak IV(5.7)
						loc	IV	error_over_ntl
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & !mi(SNAP_index_w), absorb(ib31.rp_state) robust	first savefirst 
				
		
					*	(X) State FE, individual FE
						*	(X) Period: 1980-2019 (excluding 2015): weak IV (1.15), 2nd-stage too high (6.1)
						loc	IV	error_over_ntl
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(x11101ll	ib31.rp_state) robust	first savefirst 
						
						*	(X) Period: 1996-2015: weak IV (1.3), 2nd-stage OK(0.29)
						loc	IV	error_over_ntl
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & !mi(SNAP_index_w),	absorb(x11101ll	ib31.rp_state) robust	first savefirst 
			
				*	(X) "State"	 SNAP payment error rate
				
					*	State FE, no individual FE
					
						*	(X) Period: 1991-2019: weak IV(3.4), 2nd-stage too high(1.80)
						loc	IV	error_total
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & inrange(year,1991,2019),	absorb(ib31.rp_state) robust	first savefirst 
					
						*	(X) Period: 1996-2015 (to be consistent with SNAP index): very weak IV(0.4)
						loc	IV	error_total
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & !mi(SNAP_index_w),	absorb(ib31.rp_state) robust	first savefirst 
					
					
					*	State FE, individual FE
					
						*	(X) Period: 1991-2019: weak IV(3.0), 2nd-stage too high(1.7)
						loc	IV	error_total
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & inrange(year,1991,2019),	absorb(x11101ll	ib31.rp_state) robust	first savefirst 
					
						*	(X) Period: 1996-2015 (to be consistent with SNAP index): very weak IV(0.02), 2nd stage too high(1.38)
						loc	IV	error_total
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & !mi(SNAP_index_w),	absorb(x11101ll	ib31.rp_state) robust	first savefirst 
				
				
				*	State governmental ideology 
					
					*	state FE, no individual FE
					
						*	(X) Period: 1977-2017: IV weak (8.5), 2nd-stage negative and insignificant
						loc	IV	inst6017_nom
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') ,	absorb(ib31.rp_state) robust	first savefirst 
					
						*	(X) Period: 1996-2015 (to be consistent with SNAP index): strong (21.3), 1st-stage  negative, but second stage negative and insignificant.
						loc	IV	inst6017_nom
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & !mi(SNAP_index_w), absorb(ib31.rp_state)	robust	first savefirst 
					
					
					*	State FE, individual FE
					
						*	(X) Period: 1977-2017: VERY weak (0.17), 2nd-stage too high (0.75)
						loc	IV	inst6017_nom
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(x11101ll	ib31.rp_state) robust	first savefirst 
					
						*	(?) Period: 1996-2015 (to be consistent with SNAP index): F-stat OK (12.3), 1st stage negative (-0.001) -> negative relation b/w being liberal and FS redemption, but 2nd stage too low (0.01)
						loc	IV	inst6017_nom
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & !mi(SNAP_index_w),	absorb(x11101ll	ib31.rp_state) robust	first savefirst 
					
				*	State citizen ideology
				
					*	state FE, no individual FE
					
						*	OLS
						reghdfe	PFS_glm	FSdummy ${FSD_on_FS_X}	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(citi6016) ,	absorb(ib31.rp_state)
						
						*	(X) Period: 1977-2017: strong(29), 2nd-stage negative and significant (-0.2)
						loc	IV	citi6016
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') ,	absorb(ib31.rp_state) robust	first savefirst 
					
						*	(X) Period: 1996-2015 (to be consistent with SNAP index): weak IV(3.7), 2nd-stage OK (0.13)
						loc	IV	citi6016
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & !mi(SNAP_index_w), absorb(ib31.rp_state)	robust	first savefirst 
					
					
					*	State FE, individual FE
					
						*	OLS
						reghdfe	PFS_glm	FSdummy ${FSD_on_FS_X}	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(citi6016) ,	absorb(x11101ll ib31.rp_state)
						
						*	(?) Period: 1977-2015: relevance OK(20.84), 1st-stage negative (-0.0013) -> negative relation b/w being liberal and FS redemption, 2nd stage insignificant (0.07 with SE 0.05)
						loc	IV	citi6016
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV'),	absorb(x11101ll	ib31.rp_state) robust	first savefirst 
					
						*	(X) Period: 1996-2015 (to be consistent with SNAP index): weak IV (4.1), 2nd-stage high (0.40)
						loc	IV	citi6016
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & !mi(SNAP_index_w),	absorb(x11101ll	ib31.rp_state) robust	first savefirst 
					
				
				*	State and citizen ideology
				
					*	state FE, no individual FE
					
						*	(X) Period: 1977-2015: relevance OK(15), but 2nd-stage negative and significant (-0.23)
						loc	IV	inst6017_nom citi6016 
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(inst6017_nom) & !mi(citi6016),	absorb(ib31.rp_state) robust	first savefirst 
					
						*	(X) Period: 1996-2015 (to be consistent with SNAP index): relevant(10.9), but 2nd-stage negative and insignificant
						loc	IV	inst6017_nom citi6016 
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(inst6017_nom) & !mi(citi6016) & !mi(SNAP_index_w),	absorb(ib31.rp_state) robust	first savefirst 
					
					
					*	State FE, individual FE
					
						*	(O) Period: 1977-2015: relevant (10.8), 1st-stage: govt insignificant, citizen negatively associated, 2nd-stage OK(0.09), overidentification test OK (p-val: 0.85), 2nd-stage: 0.07
						loc	IV	inst6017_nom citi6016 
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(inst6017_nom) & !mi(citi6016),	absorb(x11101ll ib31.rp_state) robust	first savefirst 
					
						*	(X) Period: 1996-2015 (to be consistent with SNAP index): weak IV (6.5)
						loc	IV	inst6017_nom citi6016 
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(inst6017_nom) & !mi(citi6016) & !mi(SNAP_index_w),	absorb(x11101ll ib31.rp_state) robust	first savefirst 

				
				
				
			
			*	(2022-11-14) Test with SNAP index (using available data)
			loc	IV						SNAP_index_uw	
			loc	IVname					SNAP_index_uw
			*loc	FS_rec_wth_name			FSdummy
			*loc	FS_rec_amt_real_name	FSamt
			
			
				foreach	endovar	in	FSdummy	/*FSamt*/	{
					
					loc	IV						SNAP_index_uw	
					loc	IVname					SNAP_index_uw
					loc	depvar	PFS_glm
					*loc	endovar			FSdummy		//	FS_amt_realK	FS_rec_wth	//
					ivreg2 	`depvar'	${FSD_on_FS_X}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
						if	income_below_200==1,	///
						robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
					est	store	`IVname'`endovar'_2nd
					scalar	Fstat_CD	=	 e(cdf)
					scalar	Fstat_KP	=	e(widstat)
					
					est	restore	`IVname'`endovar'
					estadd	scalar	Fstat_CD	=	Fstat_CD, replace
					estadd	scalar	Fstat_KP	=	Fstat_KP, replace
					est	store	`IVname'`endovar'_1st
					est	drop	`IVname'`endovar'
										
					global	PFS_est_1st	${PFS_est_1st}	`IVname'`endovar'_1st
					global	PFS_est_2nd	${PFS_est_2nd}	`IVname'`endovar'_2nd
				
				}				
				
				*	1st-stage
				esttab	${PFS_est_1st}	using "${SNAP_outRaw}/PFS_IV_SNAPindex_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace	

				*	2nd-stage
				esttab	${PFS_est_2nd}	using "${SNAP_outRaw}/PFS_IV_SNAPindex_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
						
				
			

			*	SNAP error rate
				loc	depvar	PFS_glm
				loc	endovar		FS_rec_wth	//	FS_rec_amt_real		//	FS_amt_realK	//
				loc	IV		error_total	
				loc	IVname	error_total
				ivreg2 	`depvar'	${FSD_on_FS_X}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	///
					robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_CD_`IVname'	=	 e(cdf)
				scalar	Fstat_KP_`IVname'	=	e(widstat)
				
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
				estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
									
				global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
				global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
			
			
			/*
			*	(2022-10-13) Test with political ideology
				*	Citizen ideology only 
				*	Weak IV result shows 
					*	participation dummy: 11.9 (CD), 1.3(KP), very weak
					*	amount redeemed: 17.9 (CD), 4.4 (KP), still weak
				loc	depvar	PFS_glm
				loc	endovar		FS_rec_wth	//	FS_rec_amt_real		//	FS_amt_realK	//
				loc	IV		citi6016	
				loc	IVname	citizen_ideo
				ivreg2 	`depvar'	${FSD_on_FS_X}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	///
					robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_CD_`IVname'	=	 e(cdf)
				scalar	Fstat_KP_`IVname'	=	e(widstat)
				
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
				estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
									
				global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
				global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
				
				*	Government ideology only 
				*	Weak IV result shows
					*	Participation dummy: 22.7 (CD), 3.4(KP), slightly stronger than the citizen ideology but still weak.
					*	Amount redeemed: 18/8 (CD), 4.0 (KP), still weak.
				loc	depvar	PFS_glm
				loc	endovar	FS_rec_amt_real		//	FS_rec_wth	//		FS_amt_realK	//	
				loc	IV		inst6017_nom	
				loc	IVname	govt_ideo
				ivreg2 	`depvar'	${FSD_on_FS_X}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	///
					robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_CD_`IVname'	=	 e(cdf)
				scalar	Fstat_KP_`IVname'	=	e(widstat)
				
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
				estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
									
				global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
				global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
			
				
				*	Both citizen and state ideology
				*	Weak IV test is 11.9 (CD), 1.8 (KP), still weak
				loc	depvar	PFS_glm
				loc	endovar	FS_rec_wth	//	FS_rec_amt_real		//	FS_amt_realK	//	
				loc	IV		citi6016	inst6017_nom	
				loc	IVname	citiz_govt_ideo
				ivreg2 	`depvar'	${FSD_on_FS_X}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	///
					robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_CD_`IVname'	=	 e(cdf)
				scalar	Fstat_KP_`IVname'	=	e(widstat)
				
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
				estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
									
				global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
				global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
			*/		
			
			/*
			
			*	SSI (share of s&l exp as % of GDP), with 2001/2003 interaction, w/o FE
			loc	IV		SSI_GDP_sl	int_SSI_exp_sl_01_03

			loc	IVname	SSI_nomacro
			ivreg2 	`depvar'	${statevars}	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	${regionvars}	/*${timevars}	${macrovars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
				if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
								
			global	est_1st	${est_1st}	`IVname'_1st
			global	est_2nd	${est_2nd}	`IVname'_2nd
			
				*	SSI (share of s&l exp as % of GDP), with 2001/2003 interaction, macro
				loc	IV		SSI_GDP_sl	int_SSI_exp_sl_01_03
				loc	IVname	SSI_macro
				ivreg2 	`depvar'	${statevars}	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	${macrovars}	${regionvars}	/*${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
									
				global	est_1st	${est_1st}	`IVname'_1st
				global	est_2nd	${est_2nd}	`IVname'_2nd
			
			*	State control ("mixed" is omitted as base category), no macro
			loc	IV	major_control_dem major_control_rep
			loc	IVname	politics_nomacro
			ivreg2 	`depvar'	${statevars}	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}		/*${macrovars}*/	${regionvars}	/*${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
				if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
						
			global	est_1st	${est_1st}	`IVname'_1st
			global	est_2nd	${est_2nd}	`IVname'_2nd
			
				*	State control ("mixed" is omitted as base category), no macro
				loc	IV	major_control_dem major_control_rep
				loc	IVname	politics_macro
				ivreg2 	`depvar'	${statevars}	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	${macrovars}	${regionvars}	/*${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
							
				global	est_1st	${est_1st}	`IVname'_1st
				global	est_2nd	${est_2nd}	`IVname'_2nd
			
			*	All IVs, no macro
			loc	IV	SSI_GDP_sl	int_SSI_exp_sl_01_03	major_control_dem major_control_rep	
			loc	IVname	all_nomacro
			ivreg2 	`depvar'	${statevars}	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}		/*${macrovars}*/	${regionvars}	/*${timevars}*/	(`endovar'	=	`IV')		[aw=wgt_long_fam_adj]	///
				if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			
			global	est_1st	${est_1st}	`IVname'_1st
			global	est_2nd	${est_2nd}	`IVname'_2nd
			
			
				*	All IVs, macro
				loc	IV	SSI_GDP_sl	int_SSI_exp_sl_01_03	major_control_dem major_control_rep	
				loc	IVname	all_macro
				ivreg2 	`depvar'	${statevars}	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	${macrovars}	${regionvars}	/*${timevars}*/	(`endovar'	=	`IV')		[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
				
				global	est_1st	${est_1st}	`IVname'_1st
				global	est_2nd	${est_2nd}	`IVname'_2nd
			
			
			*	SSI (share of s&l exp as % of GDP), with 2001/2003 interaction, with FE
			loc	IV		SSI_GDP_sl
			loc	IVname	SSI_FE
			ivreg2 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	${regionvars}	${timevars}	(`endovar'	=	`IV')	int_SSI_exp_sl_01_03	[aw=wgt_long_fam_adj]	///
				if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			
	
				*	State control ("mixed" is omitted as base category), with FE
			loc	IV	major_control_dem major_control_rep
			loc	IVname	politics_FE
			ivreg2 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	${regionvars}	${timevars}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
				if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			
			
			
			*	SNAP index (unweighted)
			loc	IV	SNAP_index_uw
			ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/		(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	if	!mi(PFS_glm),	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IV')
			est	store	`IV'_2nd
			scalar	Fstat_`IV'	=	e(widstat)
			est	restore	`IV'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IV', replace
			est	store	`IV'_1st
			est	drop	`IV'`endovar'
			
			*	SNAP index (weighted)
			loc	IV	SNAP_index_w
			ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/		(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	if	!mi(PFS_glm),	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IV')
			est	store	`IV'_2nd
			scalar	Fstat_`IV'	=	e(widstat)
			est	restore	`IV'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IV', replace
			est	store	`IV'_1st
			est	drop	`IV'`endovar'
			*/
												
			/*
				*	IVs without CPI, lagged food expenditure (up to 2nd order)
				loc	IVname	all_lagW2
				ivreg2 	`depvar'	l2_foodexp_tot_inclFS_pc_1 l2_foodexp_tot_inclFS_pc_2 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
				
				local	est_1st	`est_1st'	`IVname'_1st
				local	est_2nd	`est_2nd'	`IVname'_2nd
				
				
				*	IVs with CPI, w/o lagged food exp
				loc	IVname	all_CPI
				ivreg2 	`depvar' ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	CPI	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
				
				local	est_1st	`est_1st'	`IVname'_1st
				local	est_2nd	`est_2nd'	`IVname'_2nd
				
				*	IVs with CPI with lagged food exp (up to 2rd)
				loc	IVname	all_lagW3_CPI
				ivreg2 	`depvar'	l2_foodexp_tot_inclFS_pc_1 l2_foodexp_tot_inclFS_pc_2	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	CPI	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
				
				local	est_1st	`est_1st'	`IVname'_1st
				local	est_2nd	`est_2nd'	`IVname'_2nd
				*/

			/*
				*	1st-stage
				esttab	${est_1st}	using "${SNAP_outRaw}/WeakIV_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(Weak IV_1st)		replace	
						
				esttab	${est_1st}	using "${SNAP_outRaw}/WeakIV_1st.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(Weak IV_1st)		replace	
						
				*	2nd-stage
				esttab	${est_2nd}	using "${SNAP_outRaw}/WeakIV_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)///
						title(Weak IV_2nd)		replace		
						
				esttab	${est_2nd}	using "${SNAP_outRaw}/WeakIV_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)///
						title(Weak IV_2nd)		replace	

		*/
		
						
			*	Set the benchmark specification based on the test above.	
			*	Benchmark specification
			*	(2022-7-28) Note: the last benchmark model (SSI as single IV to instrument amount of FS benefit) tested was including "${statevars}" and excluding "lagged PFS"
			*	But here I inclued "lagged PFS" as Chris suggested, and excluded "statevars" by my own decision. We can further test this specification with different IV/endogenous variable (political status didn't work still)
			*	(2022-11-16) updates
				*	(1) use 'food expenditure' up to the 2nd order as lagged state,
				*	(2) compare b/w with and w/o state FE  (without FE as benchmark)
				*	(3) compare OLS and IV as diagnosis.
			
			global	PFS_est_1st
			global	PFS_est_2nd	//	This one includes OLS as well.
			
				
				*	Social spending				
				loc	depvar		PFS_glm
				loc	endovar		FSdummy	//	FSamt_capita
				loc	IV			SSI_GDP_sl	year_01_03	int_SSI_GDP_sl_01_03	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		SSI
				
					*	OLS
						
						*	no FE at all, macro variables only, SE cluster at invidiual-level
						reg		`depvar'	`endovar'	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	if	income_below_200==1,	///
						robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
						est	store	`IVname'_nofe_ols
												
						
						*	With state FE
						reg		`depvar'	`endovar'	${FSD_on_FS_X}	${regionvars}	[aw=wgt_long_fam_adj]	if	income_below_200==1,	///
						robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
						est	store	`IVname'_fe_ols
						
								
					*	IV
													
							ivreg2 	`depvar'	${FSD_on_FS_X}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
								if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
							est	store	`IVname'_IV_nofe_2nd
							scalar	Fstat_CD_`IVname'	=	 e(cdf)
							scalar	Fstat_KP_`IVname'	=	e(widstat)
						
							est	restore	`IVname'`endovar'
							estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
							estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

							est	store	`IVname'_nofe_IV_1st
							est	drop	`IVname'`endovar'
												
							*global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
							*global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
						
						
							*	Add dynamic effects.
							*	First, predict FS amount received
							est restore `IVname'_nofe_IV_1st
							cap	drop	FS_wth_PFS_hat
							predict 	FS_wth_PFS_hat, xb
							lab	var		FS_wth_PFS_hat	"Predicted FS dummy received last month"
					
							*	Now, regress 2nd stage, including FS across multiple periods
							reg	PFS_glm FS_wth_PFS_hat	l2.FS_wth_PFS_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
										if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
							est	store	`IVname'_dyn_X_nofe_2nd
						
							*global	PFS_est_2nd	${PFS_est_2nd}	PFS_dyn_X_2nd
					
					
						*	SSI, with FE							
							ivreg2 	`depvar'	${FSD_on_FS_X}	${regionvars}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
								if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
							est	store	`IVname'_IV_fe_2nd
							scalar	Fstat_CD_`IVname'	=	 e(cdf)
							scalar	Fstat_KP_`IVname'	=	e(widstat)
						
							est	restore	`IVname'`endovar'
							estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
							estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

							est	store	`IVname'_fe_IV_1st
							est	drop	`IVname'`endovar'
												
							*global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
							*global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
						
						
							*	Add dynamic effects.
							*	First, predict FS amount received
							est restore `IVname'_fe_IV_1st
							cap	drop	FS_wth_PFS_hat
							predict 	FS_wth_PFS_hat, xb
							lab	var		FS_wth_PFS_hat	"Predicted FS dummy received last month"
					
							*	Now, regress 2nd stage, including FS across multiple periods
							reg	PFS_glm FS_wth_PFS_hat	l2.FS_wth_PFS_hat	${FSD_on_FS_X}	${regionvars}	[aw=wgt_long_fam_adj]	///
										if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
							est	store	`IVname'_dyn_X_fe_2nd
						
				
				*	SNAP index (1996-2015)		
				loc	depvar	PFS_glm
				loc	endovar	FSdummy	//	FSamt_capita	//	
				loc	IV		SNAP_index_w
				loc	IVname	index
				
					*	OLS
						
						*	Without state FE
						reg		`depvar'	`endovar'	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
							if	in_sample==1 & inrange(year,1996,2015)  & income_below_200==1,	///
						robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
						est	store	`IVname'_nofe_ols
												
						*	With state FE
						reg		`depvar'	`endovar'	${FSD_on_FS_X}	${regionvars}	[aw=wgt_long_fam_adj]	///
							if	in_sample==1 & inrange(year,1996,2015)   & income_below_200==1,	///
						robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
						est	store	`IVname'_fe_ols
						
								
					*	IV
							
						*	SSI, w/o FE						
							ivreg2 	`depvar'	${FSD_on_FS_X}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
								if	in_sample==1 & inrange(year,1996,2015)   & income_below_200==1,	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
							est	store	`IVname'_IV_nofe_2nd
							scalar	Fstat_CD_`IVname'	=	 e(cdf)
							scalar	Fstat_KP_`IVname'	=	e(widstat)
						
							est	restore	`IVname'`endovar'
							estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
							estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

							est	store	`IVname'_nofe_IV_1st
							est	drop	`IVname'`endovar'
												
							*global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
							*global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
						
						
							*	Add dynamic effects.
							*	First, predict FS amount received
							est restore `IVname'_nofe_IV_1st
							cap	drop	FS_wth_PFS_hat
							predict 	FS_wth_PFS_hat, xb
							lab	var		FS_wth_PFS_hat	"Predicted FS dummy received last month"
					
							*	Now, regress 2nd stage, including FS across multiple periods
							reg	PFS_glm FS_wth_PFS_hat	l2.FS_wth_PFS_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
										if	in_sample==1 & inrange(year,1996,2015)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
							est	store	`IVname'_dyn_X_nofe_2nd
						
							*global	PFS_est_2nd	${PFS_est_2nd}	PFS_dyn_X_2nd
					
					
						*	SSI, with FE							
							ivreg2 	`depvar'	${FSD_on_FS_X}	${regionvars}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
								if	in_sample==1 & inrange(year,1996,2015)   & income_below_200==1,	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
							est	store	`IVname'_IV_fe_2nd
							scalar	Fstat_CD_`IVname'	=	 e(cdf)
							scalar	Fstat_KP_`IVname'	=	e(widstat)
						
							est	restore	`IVname'`endovar'
							estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
							estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

							est	store	`IVname'_fe_IV_1st
							est	drop	`IVname'`endovar'
												
							*global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
							*global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
						
						
							*	Add dynamic effects.
							*	First, predict FS amount received
							est restore `IVname'_fe_IV_1st
							cap	drop	FS_wth_PFS_hat
							predict 	FS_wth_PFS_hat, xb
							lab	var		FS_wth_PFS_hat	"Predicted FS dummy received last month"
					
							*	Now, regress 2nd stage, including FS across multiple periods
							reg	PFS_glm FS_wth_PFS_hat	l2.FS_wth_PFS_hat	${FSD_on_FS_X}	${regionvars}	[aw=wgt_long_fam_adj]	///
										if	in_sample==1 & inrange(year,1996,2015)  & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
							est	store	`IVname'_dyn_X_fe_2nd
						
											
					
						*	Tabulate results comparing OLS and IV
						
							
							*	1st stage (SSI with and w/o FE, index with and w/o FE)
							
								esttab	SSI_nofe_IV_1st	SSI_fe_IV_1st	index_nofe_IV_1st	index_fe_IV_1st	using "${SNAP_outRaw}/PFS_SSI_index_IV_1st.csv", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(PFS on FS dummy)		replace	
								
								esttab	SSI_nofe_IV_1st	SSI_fe_IV_1st	index_nofe_IV_1st	index_fe_IV_1st	using "${SNAP_outRaw}/PFS_SSI_index_IV_1st.tex", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(PFS on FS dummy)		replace	
							
							*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
								
								*	SSI
								esttab	SSI_nofe_ols	SSI_fe_ols	SSI_IV_nofe_2nd	SSI_IV_fe_2nd	using "${SNAP_outRaw}/PFS_SSI_ols_IV.csv", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(PFS on FS dummy)		replace	
								
								esttab	SSI_nofe_ols	SSI_fe_ols	SSI_IV_nofe_2nd	SSI_IV_fe_2nd	using "${SNAP_outRaw}/PFS_SSI_ols_IV.tex", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(PFS on FS dummy)		replace	
				
								*	SNAP index
								esttab	index_nofe_ols	index_fe_ols	index_IV_nofe_2nd	index_IV_fe_2nd	using "${SNAP_outRaw}/PFS_index_ols_IV.csv", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(PFS on FS dummy)		replace	
								
								esttab	index_nofe_ols	index_fe_ols	index_IV_nofe_2nd	index_IV_fe_2nd	using "${SNAP_outRaw}/PFS_index_ols_IV.tex", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(PFS on FS dummy)		replace	
								
								
			/*
			*	(2022-11-15) Add SNAP (weighted) policy index to the benchmark specification.
			loc	depvar	PFS_glm
			loc	endovar	FS_rec_wth	//	FS_rec_amt_real		//	FS_amt_realK	//	
			loc	IV		SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
			loc	IVname	index_w
			ivreg2 	`depvar'	${FSD_on_FS_X}	${regionvars}	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
				if	in_sample==1 & inrange(year,1977,2019)  & income_below_200==1,	///
				robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_CD_`IVname'	=	 e(cdf)
			scalar	Fstat_KP_`IVname'	=	e(widstat)
			
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
			estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
								
			global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
			global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
			
			
			
		
				
				*	1st-stage
				esttab	${PFS_est_1st}	using "${SNAP_outRaw}/PFS_on_FSdummy_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace	
						
				esttab	${PFS_est_1st}	using "${SNAP_outRaw}/PFS_on_FSdummy_1st.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace	
						
				*	2nd-stage
				esttab	${PFS_est_2nd}	using "${SNAP_outRaw}/PFS_on_FSdummy_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
						
				esttab	${PFS_est_2nd}	using "${SNAP_outRaw}/PFS_on_FSdummy_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace	
			
			*/
			

			*	Regressing FSD on predicted FS, using the model we find above
				
				*	Choose which endogeneous variable/IV to use
				*	Make sure to turn on/off both variable and associated names.
				global	endovar	FSdummy	//	participation dummy
					global	endovarname	dummy
				*global	endovar	FSamt_capita	//	amount received per capita
					*global	endovarname	amtcap
				
				global	IV	SSI_GDP_sl	year_01_03	int_SSI_GDP_sl_01_03	//	SSI
					global	IVname SSI
				*global	IV	SNAP_index_w
					*global	IVname	index
			
			*	SL_5	
				{
					global	depvar	SL_5
					global	${depvar}_${endovarname}_${IVname}_est_1st	
					global	${depvar}_${endovarname}_${IVname}_est_2nd	
				
					/*
					*	Static, no control/no macro
					loc	depvar	SL_5
					*loc	endovar	FS_rec_amt_real
					*loc	IV		share_welfare_GDP_sl
					loc	model	`depvar'_biv
					ivreg2 	`depvar'	/*${regionvars}*/	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
					est	store	`model'_2nd
					scalar	Fstat_`model'	=	e(widstat)
					est	restore	`model'${endovar}
					estadd	scalar	Fstat	=	Fstat_`model', replace
					est	store	`model'_1st
					est	drop	`model'${endovar}
										
					global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
					
					
					*	Static, no control, macro
					loc	depvar	SL_5
					*loc	endovar	FS_rec_amt_real
					*loc	IV		SSI_GDP_sl
					loc	model	`depvar'_macro
					ivreg2 	`depvar'	/*${regionvars}*/	${macrovars}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
					est	store	`model'_2nd
					scalar	Fstat_`model'	=	e(widstat)
					est	restore	`model'${endovar}
					estadd	scalar	Fstat	=	Fstat_`model', replace
					est	store	`model'_1st
										
					global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
					*/
					
					*	Static, controls, macro, no state FE
					*loc	endovar	FS_rec_amt_real
					*loc	IV		SSI_GDP_sl
					loc	model	${depvar}_${endovarname}_${IVname}_noFE
					ivreg2 	${depvar} ${FSD_on_FS_X}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
					est	store	`model'_2nd
					scalar	Fstat_`model'	=	e(widstat)
					est	restore	`model'${endovar}
					estadd	scalar	Fstat	=	Fstat_`model', replace
					est	store	`model'_1st
					est	drop	`model'${endovar}
										
					global	${depvar}_${endovarname}_${IVname}_est_1st	${depvar}_${endovarname}_${IVname}_est_1st	`model'_1st
					global	${depvar}_${endovarname}_${IVname}_est_2nd	${depvar}_${endovarname}_${IVname}_est_1st	`model'_2nd
					
					*	Static, controls, macro, state FE
					*loc	endovar	FS_rec_amt_real
					*loc	IV		SSI_GDP_sl
					loc	model	${depvar}_${endovarname}_${IVname}_FE
					ivreg2 	${depvar} ${FSD_on_FS_X}	${regionvars}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
					est	store	`model'_2nd
					scalar	Fstat_`model'	=	e(widstat)
					est	restore	`model'${endovar}
					estadd	scalar	Fstat	=	Fstat_`model', replace
					est	store	`model'_1st
					est	drop	`model'${endovar}
										
					global	${depvar}_${endovarname}_${IVname}_est_1st		${depvar}_${endovarname}_${IVname}_est_1st		`model'_1st
					global	${depvar}_${endovarname}_${IVname}_est_2nd		${depvar}_${endovarname}_${IVname}_est_1st		`model'_2nd
						
						*	Dynamic model (including FS amount from multiple periods)
						*	We will do this manually
						*	First, predict FS amount from the first stage.
						
						est restore ${depvar}_${endovarname}_${IVname}_FE_1st
						cap	drop	FS_${endovarname}_${IVname}_${depvar}_hat
						predict 	FS_${endovarname}_${IVname}_${depvar}_hat, xb
						*lab	var	FS_${endovar}_${depvar}_hat	"Predicted FS amount received last month"
						
						*	Now, regress 2nd stage, including FS across multiple periods
						reg	${depvar} FS_${endovarname}_${IVname}_${depvar}_hat	l2.FS_${endovar}_${depvar}_hat	${FSD_on_FS_X}	${regionvars}	[aw=wgt_long_fam_adj]	///
							if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
						est	store	${depvar}_${endovarname}_${IVname}_dyn_FE_2nd
						
						global		${depvar}_${endovarname}_${IVname}_est_2nd			${depvar}_${endovarname}_${IVname}_est_2nd	///
																						${depvar}_${endovarname}_${IVname}_dyn_FE_2nd
				
					
							
					*	1st-stage
					esttab	${depvar}_${endovarname}_${IVname}_est_1st	using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_1st.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(${depvar} on FS_1st with ${endovarname})		replace	
							
					esttab	${depvar}_${endovarname}_${IVname}_est_1st		using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_1st.tex", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(SL_5 on FS_1st)		replace	
							
					*	2nd-stage
					esttab	${depvar}_${endovarname}_${IVname}_est_2nd			using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_2nd.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(SL_5 on FS_2nd)		replace		
							
					esttab	${depvar}_${endovarname}_${IVname}_est_2nd			using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_2nd.tex", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(SL_5 on FS_2nd)		replace	
				}			
			
			*	TFI (HCR)
				{	
					global	TFI_HCR_est_1st	
					global	TFI_HCR_est_2nd	
					
					cap	drop	FS_amt_real
					cap	drop	FS_amt_realK
					clonevar	FS_amt_real		=	FS_rec_amt_real
					gen			FS_amt_realK	=	FS_rec_amt_real	/	1000
					
					
					*	Static, no control/no macro
					loc	depvar	TFI_HCR
					*loc	endovar	FS_amt_realK
					*loc	IV		SSI_GDP_sl
					loc	model	`depvar'_biv
					ivreg2 	`depvar'	/*${regionvars}*/	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
					est	store	`model'_2nd
					scalar	Fstat_`model'	=	e(widstat)
					est	restore	`model'${endovar}
					estadd	scalar	Fstat	=	Fstat_`model', replace
					est	store	`model'_1st
					est	drop	`model'${endovar}
										
					global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
					
					
					*	Static, no control, macro
					loc	depvar	TFI_HCR
					*loc	endovar	FS_amt_realK
					*loc	IV		SSI_GDP_sl
					loc	model	`depvar'_macro
					ivreg2 	`depvar'	/*${regionvars}*/	${macrovars}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
					est	store	`model'_2nd
					scalar	Fstat_`model'	=	e(widstat)
					est	restore	`model'${endovar}
					estadd	scalar	Fstat	=	Fstat_`model', replace
					est	store	`model'_1st
					est	drop	`model'${endovar}
										
					global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
					
					
					*	Static, controls, macro
					loc	depvar	TFI_HCR
					*loc	endovar	FS_amt_realK
					*loc	IV		SSI_GDP_sl
					loc	model	`depvar'_control
					ivreg2 	`depvar' ${FSD_on_FS_X}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
					est	store	`model'_2nd
					scalar	Fstat_`model'	=	e(widstat)
					est	restore	`model'${endovar}
					estadd	scalar	Fstat	=	Fstat_`model', replace
					est	store	`model'_1st
					est	drop	`model'${endovar}
										
					global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
					
						
						*	Dynamic model (including FS amount from multiple periods)
						*	We will do this manually
						*	First, predict FS amount from the first stage.
						loc	depvar	TFI_HCR
						est restore `depvar'_control_1st
						cap	drop	FS_amt_`depvar'_hat
						predict FS_amt_`depvar'_hat, xb
						lab	var	FS_amt_`depvar'_hat	"Predicted FS amount received last month"
						
						*	Now, regress 2nd stage, including FS across multiple periods
						reg	`depvar' FS_amt_`depvar'_hat	l2.FS_amt_`depvar'_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
							if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
						est	store	`depvar'_dyn_control_2nd
					
						global	`depvar'_est_2nd	${`depvar'_est_2nd}	`depvar'_dyn_control_2nd
				
					
							
					*	1st-stage
					esttab	${TFI_HCR_est_1st}	using "${SNAP_outRaw}/TFI_HCR_on_FS_IV_1st.csv", ///
							cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(TFI_HCR on FS_1st)		replace	
							
					esttab	${TFI_HCR_est_1st}	using "${SNAP_outRaw}/TFI_HCR_on_FS_IV_1st.tex", ///
							cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(TFI_HCR on FS_1st)		replace	
							
					*	2nd-stage
					esttab	${TFI_HCR_est_2nd}	using "${SNAP_outRaw}/TFI_HCR_on_FS_IV_2nd.csv", ///
							cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(TFI_HCR on FS_2nd)		replace		
							
					esttab	${TFI_HCR_est_2nd}	using "${SNAP_outRaw}/TFI_HCR_on_FS_IV_2nd.tex", ///
							cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(TFI_HCR on FS_2nd)		replace	
				}	
					
			*	TFI (FIG)
				{
				global	TFI_FIG_est_1st	
				global	TFI_FIG_est_2nd	
				
				cap	drop	FS_amt_real
				cap	drop	FS_amt_realK
				clonevar	FS_amt_real		=	FS_rec_amt_real
				gen			FS_amt_realK	=	FS_rec_amt_real	/	1000
				
								
				*	Static, no control/no macro
				loc	depvar	TFI_FIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_biv
				ivreg2 	`depvar'	/*${regionvars}*/	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, no control, macro
				loc	depvar	TFI_FIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_macro
				ivreg2 	`depvar'	/*${regionvars}*/	${macrovars}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, controls, macro
				loc	depvar	TFI_FIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_X
				ivreg2 	`depvar' ${FSD_on_FS_X}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
					
					*	Dynamic model (including FS amount from multiple periods)
					*	We will do this manually
					*	First, predict FS amount from the first stage.
					loc	depvar	TFI_FIG
					est restore `depvar'_X_1st
					cap	drop	FS_amt_`depvar'_hat
					predict FS_amt_`depvar'_hat, xb
					lab	var	FS_amt_`depvar'_hat	"Predicted FS amount received last month (K)"
					
					*	Now, regress 2nd stage, including FS across multiple periods
					reg	`depvar' FS_amt_`depvar'_hat	l2.FS_amt_`depvar'_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
					est	store	`depvar'_dyn_X_2nd
				
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`depvar'_dyn_X_2nd
			
				
						
				*	1st-stage
				esttab	${TFI_FIG_est_1st}	using "${SNAP_outRaw}/TFI_FIG_on_FS_IV_1st.csv", ///
						cells(b(star fmt(%8.5f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(TFI_FIG on FS_1st)		replace	
						
				esttab	${TFI_FIG_est_1st}	using "${SNAP_outRaw}/TFI_FIG_on_FS_IV_1st.tex", ///
						cells(b(star fmt(%8.5f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(TFI_FIG on FS_1st)		replace	
						
				*	2nd-stage
				esttab	${TFI_FIG_est_2nd}	using "${SNAP_outRaw}/TFI_FIG_on_FS_IV_2nd.csv", ///
						cells(b(star fmt(%8.5f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(TFI_FIG on FS_2nd)		replace		
						
				esttab	${TFI_FIG_est_2nd}	using "${SNAP_outRaw}/TFI_FIG_on_FS_IV_2nd.tex", ///
						cells(b(star fmt(%8.5f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(TFI_FIG on FS_2nd)		replace	
				}
			
			*	TFI (SFIG)
				{
				global	TFI_SFIG_est_1st	
				global	TFI_SFIG_est_2nd	
				
				cap	drop	FS_amt_real
				cap	drop	FS_amt_realK
				clonevar	FS_amt_real		=	FS_rec_amt_real
				gen			FS_amt_realK	=	FS_rec_amt_real	/	1000
							
				*	Static, no control/no macro
				loc	depvar	TFI_SFIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_biv
				ivreg2 	`depvar'	/*${regionvars}*/	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, no control, macro
				loc	depvar	TFI_SFIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_macro
				ivreg2 	`depvar'	/*${regionvars}*/	${macrovars}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, controls, macro
				loc	depvar	TFI_SFIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_X
				ivreg2 	`depvar' ${FSD_on_FS_X}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
					
					*	Dynamic model (including FS amount from multiple periods)
					*	We will do this manually
					*	First, predict FS amount from the first stage.
					loc	depvar	TFI_SFIG
					est restore `depvar'_X_1st
					cap	drop	FS_amt_`depvar'_hat
					predict FS_amt_`depvar'_hat, xb
					lab	var	FS_amt_`depvar'_hat	"Predicted FS amount received last month (K)"
					
					*	Now, regress 2nd stage, including FS across multiple periods
					reg	`depvar' FS_amt_`depvar'_hat	l2.FS_amt_`depvar'_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
					est	store	`depvar'_dyn_X_2nd
				
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`depvar'_dyn_X_2nd
			
				
						
				*	1st-stage
				esttab	${TFI_SFIG_est_1st}	using "${SNAP_outRaw}/TFI_SFIG_on_FS_IV_1st.csv", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(TFI_HCR on FS_1st)		replace	
						
				esttab	${TFI_SFIG_est_1st}	using "${SNAP_outRaw}/TFI_SFIG_on_FS_IV_1st.tex", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(TFI_HCR on FS_1st)		replace	
						
				*	2nd-stage
				esttab	${TFI_SFIG_est_2nd}	using "${SNAP_outRaw}/TFI_SFIG_on_FS_IV_2nd.csv", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(TFI_HCR on FS_2nd)		replace		
						
				esttab	${TFI_SFIG_est_2nd}	using "${SNAP_outRaw}/TFI_SFIG_on_FS_IV_2nd.tex", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(TFI_HCR on FS_2nd)		replace	
	
				}
		
			*	CFI (HCR)
				{
				global	CFI_HCR_est_1st	
				global	CFI_HCR_est_2nd	
				
				cap	drop	FS_amt_real
				cap	drop	FS_amt_realK
				clonevar	FS_amt_real		=	FS_rec_amt_real
				gen			FS_amt_realK	=	FS_rec_amt_real	/	1000
							
				*	Static, no control/no macro
				loc	depvar	CFI_HCR
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_biv
				ivreg2 	`depvar'	/*${regionvars}*/	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, no control, macro
				loc	depvar	CFI_HCR
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_macro
				ivreg2 	`depvar'	/*${regionvars}*/	${macrovars}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, controls, macro
				loc	depvar	CFI_HCR
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_X
				ivreg2 	`depvar' ${FSD_on_FS_X}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
					
					*	Dynamic model (including FS amount from multiple periods)
					*	We will do this manually
					*	First, predict FS amount from the first stage.
					loc	depvar	CFI_HCR
					est restore `depvar'_X_1st
					cap	drop	FS_amt_`depvar'_hat
					predict FS_amt_`depvar'_hat, xb
					lab	var	FS_amt_`depvar'_hat	"Predicted FS amount received last month (K)"
					
					*	Now, regress 2nd stage, including FS across multiple periods
					reg	`depvar' FS_amt_`depvar'_hat	l2.FS_amt_`depvar'_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
					est	store	`depvar'_dyn_X_2nd
				
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`depvar'_dyn_X_2nd
			
				
						
				*	1st-stage
				esttab	${CFI_HCR_est_1st}	using "${SNAP_outRaw}/CFI_HCR_on_FS_IV_1st.csv", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_HCR on FS_1st)		replace	
						
				esttab	${CFI_HCR_est_1st}	using "${SNAP_outRaw}/CFI_HCR_on_FS_IV_1st.tex", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_HCR on FS_1st)		replace	
						
				*	2nd-stage
				esttab	${CFI_HCR_est_2nd}	using "${SNAP_outRaw}/CFI_HCR_on_FS_IV_2nd.csv", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_HCR on FS_2nd)		replace		
						
				esttab	${CFI_HCR_est_2nd}	using "${SNAP_outRaw}/CFI_HCR_on_FS_IV_2nd.tex", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_HCR on FS_2nd)		replace	
	
				}
		
			*	CFI (FIG)
				{
				global	CFI_FIG_est_1st	
				global	CFI_FIG_est_2nd	
				
				cap	drop	FS_amt_real
				cap	drop	FS_amt_realK
				clonevar	FS_amt_real		=	FS_rec_amt_real
				gen			FS_amt_realK	=	FS_rec_amt_real	/	1000
							
				*	Static, no control/no macro
				loc	depvar	CFI_FIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_biv
				ivreg2 	`depvar'	/*${regionvars}*/	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, no control, macro
				loc	depvar	CFI_FIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_macro
				ivreg2 	`depvar'	/*${regionvars}*/	${macrovars}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, controls, macro
				loc	depvar	CFI_FIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_X
				ivreg2 	`depvar' ${FSD_on_FS_X}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
					
					*	Dynamic model (including FS amount from multiple periods)
					*	We will do this manually
					*	First, predict FS amount from the first stage.
					loc	depvar	CFI_FIG
					est restore `depvar'_X_1st
					cap	drop	FS_amt_`depvar'_hat
					predict FS_amt_`depvar'_hat, xb
					lab	var	FS_amt_`depvar'_hat	"Predicted FS amount received last month (K)"
					
					*	Now, regress 2nd stage, including FS across multiple periods
					reg	`depvar' FS_amt_`depvar'_hat	l2.FS_amt_`depvar'_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
					est	store	`depvar'_dyn_X_2nd
				
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`depvar'_dyn_X_2nd
			
				
						
				*	1st-stage
				esttab	${CFI_FIG_est_1st}	using "${SNAP_outRaw}/CFI_FIG_on_FS_IV_1st.csv", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_FIG on FS_1st)		replace	
						
				esttab	${CFI_FIG_est_1st}	using "${SNAP_outRaw}/CFI_FIG_on_FS_IV_1st.tex", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_FIG on FS_1st)		replace	
						
				*	2nd-stage
				esttab	${CFI_FIG_est_2nd}	using "${SNAP_outRaw}/CFI_FIG_on_FS_IV_2nd.csv", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_FIG on FS_2nd)		replace		
						
				esttab	${CFI_FIG_est_2nd}	using "${SNAP_outRaw}/CFI_FIG_on_FS_IV_2nd.tex", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_FIG on FS_2nd)		replace	
	
				}
		
			*	CFI (SFIG)
				{
				global	CFI_SFIG_est_1st	
				global	CFI_SFIG_est_2nd	
				
				cap	drop	FS_amt_real
				cap	drop	FS_amt_realK
				clonevar	FS_amt_real		=	FS_rec_amt_real
				gen			FS_amt_realK	=	FS_rec_amt_real	/	1000
							
				*	Static, no control/no macro
				loc	depvar	CFI_SFIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_biv
				ivreg2 	`depvar'	/*${regionvars}*/	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, no control, macro
				loc	depvar	CFI_SFIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_macro
				ivreg2 	`depvar'	/*${regionvars}*/	${macrovars}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
				
				*	Static, controls, macro
				loc	depvar	CFI_SFIG
				*loc	endovar	FS_amt_realK
				*loc	IV		SSI_GDP_sl
				loc	model	`depvar'_X
				ivreg2 	`depvar' ${FSD_on_FS_X}	(${endovar}	=	${IV})	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) first savefirst savefprefix(`model')
				est	store	`model'_2nd
				scalar	Fstat_`model'	=	e(widstat)
				est	restore	`model'${endovar}
				estadd	scalar	Fstat	=	Fstat_`model', replace
				est	store	`model'_1st
				est	drop	`model'${endovar}
									
				global	`depvar'_est_1st	${`depvar'_est_1st}	`model'_1st
				global	`depvar'_est_2nd	${`depvar'_est_2nd}	`model'_2nd
				
					
					*	Dynamic model (including FS amount from multiple periods)
					*	We will do this manually
					*	First, predict FS amount from the first stage.
					loc	depvar	CFI_SFIG
					est restore `depvar'_X_1st
					cap	drop	FS_amt_`depvar'_hat
					predict FS_amt_`depvar'_hat, xb
					lab	var	FS_amt_`depvar'_hat	"Predicted FS amount received last month (K)"
					
					*	Now, regress 2nd stage, including FS across multiple periods
					reg	`depvar' FS_amt_`depvar'_hat	l2.FS_amt_`depvar'_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
						if	in_sample==1 & inrange(year,1977,2019)	 & income_below_200==1,	robust	cluster(x11101ll) // first savefirst savefprefix(`IVname')
					est	store	`depvar'_dyn_X_2nd
				
					global	`depvar'_est_2nd	${`depvar'_est_2nd}	`depvar'_dyn_X_2nd
			
				
						
				*	1st-stage
				esttab	${CFI_SFIG_est_1st}	using "${SNAP_outRaw}/CFI_SFIG_on_FS_IV_1st.csv", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_SFIG on FS_1st)		replace	
						
				esttab	${CFI_SFIG_est_1st}	using "${SNAP_outRaw}/CFI_SFIG_on_FS_IV_1st.tex", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_SFIG on FS_1st)		replace	
						
				*	2nd-stage
				esttab	${CFI_SFIG_est_2nd}	using "${SNAP_outRaw}/CFI_SFIG_on_FS_IV_2nd.csv", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_SFIG on FS_2nd)		replace		
						
				esttab	${CFI_SFIG_est_2nd}	using "${SNAP_outRaw}/CFI_SFIG_on_FS_IV_2nd.tex", ///
						cells(b(star fmt(%8.3f)) /*&*/ se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(CFI_SFIG on FS_2nd)		replace	
	
				}
		
			
			*	Print TFI/CFI with control model only
			esttab	TFI_HCR_control_2nd	TFI_HCR_dyn_control_2nd	CFI_HCR_X_2nd	CFI_HCR_dyn_X_2nd	///
			using "${SNAP_outRaw}/TFI_CFI_HCR.csv", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
						
			esttab	TFI_HCR_control_2nd	TFI_HCR_dyn_control_2nd	CFI_HCR_X_2nd	CFI_HCR_dyn_X_2nd	///
			using "${SNAP_outRaw}/TFI_CFI_HCR.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
			
			
			esttab	TFI_FIG_X_2nd	TFI_FIG_dyn_X_2nd	CFI_FIG_X_2nd	CFI_FIG_dyn_X_2nd	///
			using "${SNAP_outRaw}/TFI_CFI_FIG.csv", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
						
			esttab	TFI_FIG_X_2nd	TFI_FIG_dyn_X_2nd	CFI_FIG_X_2nd	CFI_FIG_dyn_X_2nd	///
			using "${SNAP_outRaw}/TFI_CFI_FIG.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
			
			summ	PFS_glm TFI_FIG CFI_FIG if in_sample==1	&	income_below_200==1 & PFS_FI_glm==1 [aw=wgt_long_fam_adj],d
		

		
	}
	
	*	Summary stats	
	if	`summ_stats'==1	{
		 
		 use	"${SNAP_dtInt}/SNAP_long_FSD", clear 
		 *use    "${SNAP_dtInt}/SNAP_long_PFS",	clear	
		*use	"${SNAP_dtInt}/SNAP_long_const", clear
		
		
			*	Re-scale HFSM, so it can be compared with the PFS
			
			cap	drop	HFSM_rescale
			gen	HFSM_rescale = (9.3-HFSM_scale)/9.3
			label	var	HFSM_rescale "HFSM (re-scaled)"
			
			*	Density Estimate of Food Security Indicator (Figure A1)
			graph twoway 		(kdensity HFSM_rescale	if	ind_female==0)	///
								(kdensity PFS_glm		if	!mi(HFSM_rescale)	&	!mi(PFS_glm)),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)		///
								name(HFSM_PFS, replace) graphregion(color(white)) bgcolor(white)		///
								legend(lab (1 "HFSM (rescaled)") lab(2 "PFS") rows(1))					
			graph	export	"${SNAP_outRaw}/Fig_A2_Density_HFSM_PFS.png", replace
			
			
			*	PFS by gender
			graph twoway 		(kdensity PFS_glm	if	ind_female==0, bwidth(0.05) )	///
								(kdensity PFS_glm	if	ind_female==1, bwidth(0.05) ),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(PFS) ytitle(Density)		///
								name(PFS_ind_gender, replace) graphregion(color(white)) bgcolor(white)		///
								legend(lab (1 "Male") lab(2 "Female") rows(1))	
								
								
			*	PFS by race
			graph twoway 		(kdensity PFS_glm	if	rp_nonWhte==0, bwidth(0.05) )	///
								(kdensity PFS_glm	if	rp_nonWhte==1, bwidth(0.05) ),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(PFS) ytitle(Density)		///
								name(PFS_rp_race, replace) graphregion(color(white)) bgcolor(white)		///
								legend(lab (1 "White") lab(2 "non-White") rows(1))	
			
			graph	combine	PFS_ind_gender	PFS_rp_race, graphregion(color(white) fcolor(white)) 
			graph	export	"${SNAP_outRaw}/PFS_kdensities.png", replace
			graph	close
			
		
		
		*	Sample information
			
			count if in_sample	&	income_below_200==1		&	!mi(PFS_glm)		//	Sample with non-missing PFS
				count if in_sample	&	income_below_200==1	//	Sample size	(including missing PFS)
			count if in_sample	&	income_below_200==1		&	!mi(PFS_glm)	&	baseline_indiv==1	//	Baseline individual in sapmle
			count if in_sample	&	income_below_200==1		&	!mi(PFS_glm)	&	splitoff_indiv==1	//	Splitoff individual in sapmle
				
			*	Number of individuals
				distinct	x11101ll	if	in_sample	&	!mi(PFS_glm)	&	income_below_200==1		//	# of baseline individuals in sapmle
				distinct	x11101ll	if	in_sample	&	income_below_200==1		//	# of baseline individuals in sapmle (including missing PFS)
				distinct	x11101ll	if	in_sample	&	!mi(PFS_glm)	&	income_below_200==1		&	baseline_indiv==1	//	# of baseline individuals in sapmle
				distinct	x11101ll	if	in_sample	&	!mi(PFS_glm)	&	income_below_200==1		&	splitoff_indiv==1	//	Baseline individual in sapmle
			
			unique	x11101ll	if	!mi(PFS_glm)	//	Total individuals
			unique	year		if	!mi(PFS_glm)		//	Total waves
	
		
		*	Individual-level stats
		*	To do this, we need to crate a variable which is non-missing only one obs per individual
		*	For now, I use `_uniq' suffix to create such variables
		
			
		*	Sample stats
			
			*	Individual-level (unique per individual)
			
				
				*	Gender
				local	var	ind_female
				cap	drop	`var'_uniq
				bys x11101ll	live_in_FU:	gen `var'_uniq=`var' if _n==1	&	live_in_FU==1
				summ `var'_uniq	
				label	var	`var'_uniq "Gender (ind)"
								
				*	Number of waves living in FU
				loc	var	num_waves_in_FU
				cap	drop	`var'
				cap	drop	`var'_temp
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'=total(live_in_FU)	if	live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
				bys x11101ll:	egen	`var'_temp	=	max(`var')
				bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
				drop	`var'
				rename	`var'_temp	`var'
				summ	`var'_uniq,d
				label	var	`var'_uniq "\# of waves surveyed"
				
				/*
				*	Number of waves surveyed
				local	var	num_surveyed
				cap	drop 	`var'
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'	=	count(live_in_FU)
				bys x11101ll:	gen 	`var'_uniq=`var' if _n==1
				summ	`var'_uniq,d
				*/
				
				*	Ever-used FS over stuy period
				loc	var	FS_ever_used
				cap	drop	`var'
				cap	drop	`var'_uniq
				cap	drop	`var'_temp
				bys	x11101ll:	egen	`var'=	max(FS_rec_wth)	if live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
				bys x11101ll:	egen	`var'_temp	=	max(`var')
				bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
				drop	`var'
				rename	`var'_temp	`var'
				summ	`var'_uniq ,d
				label var	`var'		"FS ever used throughouth the period"
				label var	`var'_uniq	"FS ever used throughouth the period"
				
				*	# of waves FS redeemed	(if ever used)
				loc	var	total_FS_used
				cap	drop	`var'
				cap	drop	`var'_temp
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'=	total(FS_rec_wth)	if	live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
				bys x11101ll:	egen	`var'_temp	=	max(`var')
				bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
				summ	`var'_uniq if `var'_uniq>=1,d
				label var	`var'		"Total FS used throughouth the period"
				label var	`var'_uniq	"Total FS used throughouth the period"
				
				*	% of FS redeemed (# FS redeemed/# surveyed)		
				loc	var	share_FS_used
				cap	drop	`var'
				cap	drop	`var'_uniq
				gen	`var'	=	total_FS_used_uniq	/	num_waves_in_FU_uniq
				bys x11101ll:	gen 	`var'_uniq	=	`var' if _n==1
				label var	`var'		"\% of FS used throughouth the period"
				label var	`var'_uniq	"\% of FS used throughouth the period"
				
					*	Generate indicaor by the #
					*local	var	never_treated
					*cap	drop	`var'
					*cap	drop	`var'_uniq
					*gen	`var'=.
					*replace	`var'=0	if	
					
				*	Generate cumulative FS redemption
				local	var	cumul_FS_used
				cap	drop	`var'
				bysort x11101ll (year) : gen `var' = sum(FS_rec_wth)
				bys x11101ll:	gen `var'_uniq	=	`var' if _n==1
				label var	`var'		"# of cumulative FS used"
				label var	`var'_uniq	"# of cumulative FS used"
				
				*	Reason for non-participation (1977,1980,1981,1987)
				svy, subpop(if !mi(PFS_glm)):	tab reason_no_FSP
				
				*	Create temporary variable for summary table (will be integrated into "clean" part)
				cap	drop	fam_income_month_pc_real
				gen	double	fam_income_month_pc_real	=	(fam_income_pc_real/12)
				label	var	fam_income_month_pc_real	"Monthly family income per capita"
				
				label	var	foodexp_tot_inclFS_pc_real	"Monthly food exp per capia"
				label	var	FS_rec_amt_real				"\$ Monthly FS redeemed"
				label 	var	childnum					"\# of child"
				
				lab		var	major_control_mix	"Mixed state control"
				
				*	For now, generate summ table separately for indvars and fam-level vars, as indvars do not represent full sample if conditiond by !mi(glm) (need to figure out why)
				local	indvars	ind_female_uniq num_waves_in_FU_uniq FS_ever_used_uniq total_FS_used_uniq	share_FS_used_uniq
				local	rpvars	rp_female	rp_age	rp_White	rp_married	rp_NoHS rp_HS rp_somecol rp_col		rp_employed rp_disabled
				local	famvars	famnum	ratio_child		split_off	fam_income_month_pc_real	foodexp_tot_inclFS_pc_real		
				local	FSvars	FS_rec_wth	FS_rec_amt_real
				local	IVs		share_welfare_exp_sl	SSI_GDP_sl	major_control_dem major_control_rep major_control_mix
				local	FSDvars	PFS_glm	SL_5	TFI_HCR	CFI_HCR	TFI_FIG	CFI_FIG	TFI_SFIG	CFI_SFIG	
				
				estpost summ	`indvars'		if	!mi(PFS_glm)	/*  num_waves_in_FU_uniq>=2	 &*/	  // Temporary condition. Need to think proper condition.
				estpost summ	`indvars'		if	in_sample==1	&	income_below_200==1	/*  num_waves_in_FU_uniq>=2	 &*/	  // Temporary condition. Need to think proper condition.
				
				local	summvars	/*`indvars'*/	`rpvars'	`famvars'	`FSvars'	`IVs'	`FSDvars'

				estpost tabstat	`summvars'	 if in_sample==1	&	!mi(PFS_glm)	[aw=wgt_long_fam_adj],	statistics(count	mean	sd	min	median	p95	max) columns(statistics)		// save
				est	store	sumstat_all
				estpost tabstat	`summvars' 	if in_sample==1	&	!mi(PFS_glm)	&	income_below_200==1	[aw=wgt_long_fam_adj],	statistics(mean	sd	min	max) columns(statistics)	// save
				est	store	sumstat_lowinc
				

				

				esttab	sumstat_all	sumstat_lowinc	using	"${SNAP_outRaw}/Tab_1_Sumstats.csv",  ///
					cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) p50(fmt(%12.2f)) p95(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
									
				esttab	sumstat_all	sumstat_lowinc	using	"${SNAP_outRaw}/Tab_1_Sumstats.tex",  ///
					cells("mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
					
				esttab	sumstat_lowinc	using	"${SNAP_outRaw}/Tab_1_Sumstats_lowinc.tex",  ///
					cells("mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace	
					
					
				summ	PFS_glm SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if in_sample==1	&	income_below_200==1 & PFS_FI_glm==1 [aw=wgt_long_fam_adj],d
				summ	PFS_glm SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if in_sample==1	&	income_below_200==1	& PFS_FI_glm==1 & FS_rec_wth!=1 [aw=wgt_long_fam_adj],d // didn't receive SNAP

			
				 x11101ll 	if in_sample==1	&	income_below_200==1	[aw=wgt_long_fam_adj]
				/*
				*estpost summ	`indvars'	if	/*   num_waves_in_FU_uniq>=2	&*/	!mi(PFS_glm)  // Temporary condition. Need to think proper condition.
				*summ	FS_rec_amt_real	if	!mi(PFS_glm)	&	FS_rec_wth==1 & inrange(rp_age,0,130) // Temporarily add age condition to take care of outlier. Will be taken care of later.
			
					/*
					*	If I want survey-weighted summary stats...
					svy, subpop(if num_waves_in_FU_uniq>=2):	mean	`indvars'
					estadd matrix mean = e(b)
					estadd matrix sd = r(table)[2,1...]
					*/
				
				esttab using "${SNAP_outRaw}/Tab_1_Sumstats_ind.csv", replace ///
				cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label	///
				nonumbers mtitles("Total" ) ///
				title (Summary Statistics_ind)	csv 
				
				esttab using "${SNAP_outRaw}/Tab_1_Sumstats_ind.tex", replace ///
				cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label	///
				nonumbers mtitles("Total" ) ///
				title (Summary Statistics_ind)	tex 
				
				estpost summ	`rpvars'	`famvars' if !mi(PFS_glm)	& inrange(rp_age,0,130) // Temporarily add age condition to take care of outlier. Will be taken care of later.
				
						
				esttab using "${SNAP_outRaw}/Tab_1_Sumstats_fam.csv", replace ///
				cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label	///
				nonumbers mtitles("Total" ) ///
				title (Summary Statistics_fam)	csv
				
				esttab using "${SNAP_outRaw}/Tab_1_Sumstats_fam.tex", replace ///
				cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label	///
				nonumbers mtitles("Total" ) ///
				title (Summary Statistics_fam)	tex 
				*/
		
		*	Program Summary
		preserve
		
			use	"${SNAP_dtInt}/SNAP_summary",	clear
			
			merge	1:1	year	using		"${SNAP_dtInt}/Unemployment Rate_nation", nogen assert(3)
			
			graph	twoway	(line part_num		year, lpattern(dash) xaxis(1 2) yaxis(1))	///
						(line unemp_rate	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)),  ///
						xline(1974 1996 2009 2020, axis(1)) xlabel(1974 "Nationwide FSP" 1996 "Welfare Reform" 2009 "ARRA" 2020 "COVID", axis(2))	///
						xtitle(Fiscal Year)	xtitle("", axis(2))  /*title(Program Summary)*/	bgcolor(white)	graphregion(color(white)) note(Source: USDA & BLS)	name(SNAP_summary, replace)
			
			/*
			graph	twoway	(line part_num	year, lpattern(dash) xaxis(1 2) yaxis(1))	///
							(line total_costs	year, lpattern(dot) xaxis(1 2) yaxis(2)),  ///
							xline(1974 1996 2009 2020, axis(1)) xlabel(1974 "Nationwide FSP" 1996 "Welfare Reform" 2009 "2008 Farm Bill" 2020 "COVID", axis(2))	///
							xtitle(Fiscal Year)	xtitle("", axis(2))  /*title(Program Summary)*/	bgcolor(white)	graphregion(color(white)) note(Source: USDA)	name(SNAP_summary, replace)
			*/
			
			
			graph	export	"${SNAP_outRaw}/Program_summary.png", replace
			graph	close
		
		restore
		
		
		
		*	Split-off
			summ	total_FS_used_uniq	if	total_FS_used_uniq>=1
		*	Histogram of FS redemption frequency
			histogram	total_FS_used_uniq	if	total_FS_used_uniq>=1, name(FS_fre, replace)
			graph	export "${SNAP_outRaw}/FS_redemption_freq.png", replace
			graph	close
			
		*	Histogram of share of FS redemption
			histogram	share_FS_used	if	total_FS_used_uniq>=1, bin(10) name(FS_share, replace)
			graph	export "${SNAP_outRaw}/FS_redemption_share.png", replace
			graph	close
			
			grc1leg2		FS_fre	FS_share,	title(Frequency and Share) 	graphregion(color(white))  legendfrom(FS_share)
							graph	export	"${SNAP_outRaw}/hist_FS_redemption.png", replace
							graph	close
	
			
		*	Test parallel trend assumption // Not using it for now.
		{	
			*	Never-treated vs Treated-once
			sort	x11101ll	year
			cap	drop	relat_time
			cap	drop	relat_time*
			
				*	Standardize time
				/*
				gen		relat_time=-4	if	total_FS_used==1	&	FS_rec_wth==0	&	f4.FS_rec_wth==1	//	4 year before FS
				replace	relat_time=-3	if	total_FS_used==1	&	FS_rec_wth==0	&	f3.FS_rec_wth==1	//	3 year before FS
				replace	relat_time=-2	if	total_FS_used==1	&	FS_rec_wth==0	&	f2.FS_rec_wth==1	//	2 year before FS
				replace	relat_time=-1	if	total_FS_used==1	&	FS_rec_wth==0	&	f1.FS_rec_wth==1	//	1 year before FS
				replace	relat_time=0	if	total_FS_used==1	&	FS_rec_wth==1							//	Year of FS
				replace	relat_time=1	if	total_FS_used==1	&	FS_rec_wth==0	&	l1.FS_rec_wth==1	//	1 year after FS
				replace	relat_time=2	if	total_FS_used==1	&	FS_rec_wth==0	&	l2.FS_rec_wth==1	//	2 year after FS
				replace	relat_time=3	if	total_FS_used==1	&	FS_rec_wth==0	&	l3.FS_rec_wth==1	//	3 year after FS			
				*/
				gen		relat_time=-4	if	total_FS_used==1	&	f3.cumul_FS_used==0	&	f4.FS_rec_wth==1	//	4 year before first FS redemption
				replace	relat_time=-3	if	total_FS_used==1	&	f2.cumul_FS_used==0	&	f3.FS_rec_wth==1	//	3 year before first FS redemption
				replace	relat_time=-2	if	total_FS_used==1	&	f1.cumul_FS_used==0	&	f2.FS_rec_wth==1	//	2 year before first FS redemption
				replace	relat_time=-1	if	total_FS_used==1	&	cumul_FS_used==0	&	f1.FS_rec_wth==1	//	1 year before first FS redemption
				replace	relat_time=-0	if	total_FS_used==1	&	cumul_FS_used==1	&	FS_rec_wth==1		//	Year of first FS redemption
				replace	relat_time=1	if	total_FS_used==1	&	cumul_FS_used==1	&	l1.FS_rec_wth==1	//	1 year after first FS redemption
				replace	relat_time=2	if	total_FS_used==1	&	cumul_FS_used==1	&	l2.FS_rec_wth==1	//	2 year after first FS redemption
				replace	relat_time=3	if	total_FS_used==1	&	cumul_FS_used==1	&	l3.FS_rec_wth==1	//	3 year after first FS redemption
				
				
				*	Make value of never-treated group as non-missing and zero for each relative time indicator, so this group can be included in the regression
				replace	relat_time=4	if	total_FS_used==0
				
				*	Creat dummy for each indicator (never-treated group will be zero in all indicator)
				cap	drop	relat_time_enum*
				tab	relat_time, gen(relat_time_enum)
				drop	relat_time_enum9	//	We should not use it, as it is a dummy for never-treated group
				
				label	var	relat_time_enum1	"t-4"
				label	var	relat_time_enum2	"t-3"
				label	var	relat_time_enum3	"t-2"
				label	var	relat_time_enum4	"t-1"
				label	var	relat_time_enum5	"t=0"
				label	var	relat_time_enum6	"t+1"
				label	var	relat_time_enum7	"t+2"
				label	var	relat_time_enum8	"t+3"
				
				*	Pre-trend plot
				*reg	PFS_glm 	relat_time_enum1	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7	i.year, fe
				xtreg PFS_glm 	relat_time_enum1	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7	i.year, fe
				est	store	PT_never_once
				
				coefplot	PT_never_once,	graphregion(color(white)) bgcolor(white) vertical keep(relat_time_enum*) xtitle(Event time) ytitle(Coefficient) ///
											title(Never-treated vs Treated-once)	name(PFS_pretrend, replace)
				graph	export	"${SNAP_outRaw}/PFS_never_once.png", replace
				graph	close
			
			*	Never-treated vs ever-treated
			*	In this comparison, all FU in this dataset will be included, and event will be "when FS used the first time"
			**	QUESTION: but many "ever-treated" observations which don't belong to the time window below won't be included in the regression (ex. 4 years after the first FS). Should I write a code to include such obs?
			cap	drop	relat_time relat_time*
			
				*	Standardize event time
				gen		relat_time=-4	if	total_FS_used>=1	&	f3.cumul_FS_used==0	&	f4.FS_rec_wth==1	//	4 year before first FS redemption
				replace	relat_time=-3	if	total_FS_used>=1	&	f2.cumul_FS_used==0	&	f3.FS_rec_wth==1	//	3 year before first FS redemption
				replace	relat_time=-2	if	total_FS_used>=1	&	f1.cumul_FS_used==0	&	f2.FS_rec_wth==1	//	2 year before first FS redemption
				replace	relat_time=-1	if	total_FS_used>=1	&	cumul_FS_used==0	&	f1.FS_rec_wth==1	//	1 year before first FS redemption
				replace	relat_time=-0	if	total_FS_used>=1	&	cumul_FS_used==1	&	FS_rec_wth==1		//	Year of first FS redemption
				replace	relat_time=1	if	total_FS_used>=1	&	cumul_FS_used>=1	&	l1.cumul_FS_used==1	&	l1.FS_rec_wth==1	//	1 year after first FS redemption
				replace	relat_time=2	if	total_FS_used>=1	&	cumul_FS_used>=1	&	l2.cumul_FS_used==1	&	l2.FS_rec_wth==1	//	2 year after first FS redemption
				replace	relat_time=3	if	total_FS_used>=1	&	cumul_FS_used>=1	&	l3.cumul_FS_used==1	&	l3.FS_rec_wth==1	//	3 year after first FS redemption
				
				*	Make value of never-treated group as non-missing and zero for each relative time indicator, so this group can be included in the regression
				*replace	relat_time=4	if	total_FS_used==0	//	Including only never-treated as a control group
				replace	relat_time=4	if	mi(relat_time)			//	Including never-treated group as well as ever-treated group outside the lead-lag window (ex. 5 yrs before FS redemption) as a control group. Basically all other obs.
				
				*	Creat dummy for each indicator (never-treated group will be zero in all indicator)
				cap	drop	relat_time_enum*
				tab	relat_time, gen(relat_time_enum)
				drop	relat_time_enum9	//	We should not use it, as it is a dummy for never-treated group
				
				label	var	relat_time_enum1	"t-4"
				label	var	relat_time_enum2	"t-3"
				label	var	relat_time_enum3	"t-2"
				label	var	relat_time_enum4	"t-1"
				label	var	relat_time_enum5	"t=0"
				label	var	relat_time_enum6	"t+1"
				label	var	relat_time_enum7	"t+2"
				label	var	relat_time_enum8	"t+3"
				
				xtreg PFS_glm 	relat_time_enum1	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7, fe
				est	store	PT_never_ever
				
				coefplot	PT_never_ever,	graphregion(color(white)) bgcolor(white) vertical keep(relat_time_enum*) xtitle(Event time) ytitle(Coefficient) 	///
											title(Never-treated vs Ever-treated) /*subtitle(Excluding ever-treated outside this window)*/	name(PFS_pretrend, replace)
				graph	export	"${SNAP_outRaw}/PFS_never_ever.png", replace
				graph	close
				
			*	Never-treated vs treated multiple tims (twice or more) - exclude treated only once.
			cap	drop	relat_time relat_time*
			
				*	Standardize event time
				gen		relat_time=-4	if	total_FS_used>1	&	f3.cumul_FS_used==0	&	f4.FS_rec_wth==1	//	4 year before first FS redemption
				replace	relat_time=-3	if	total_FS_used>1	&	f2.cumul_FS_used==0	&	f3.FS_rec_wth==1	//	3 year before first FS redemption
				replace	relat_time=-2	if	total_FS_used>1	&	f1.cumul_FS_used==0	&	f2.FS_rec_wth==1	//	2 year before first FS redemption
				replace	relat_time=-1	if	total_FS_used>1	&	cumul_FS_used==0	&	f1.FS_rec_wth==1	//	1 year before first FS redemption
				replace	relat_time=-0	if	total_FS_used>1	&	cumul_FS_used==1	&	FS_rec_wth==1		//	Year of first FS redemption
				replace	relat_time=1	if	total_FS_used>1	&	cumul_FS_used>=1	&	l1.cumul_FS_used==1	&	l1.FS_rec_wth==1	//	1 year after first FS redemption
				replace	relat_time=2	if	total_FS_used>1	&	cumul_FS_used>=1	&	l2.cumul_FS_used==1	&	l2.FS_rec_wth==1	//	2 year after first FS redemption
				replace	relat_time=3	if	total_FS_used>1	&	cumul_FS_used>=1	&	l3.cumul_FS_used==1	&	l3.FS_rec_wth==1	//	3 year after first FS redemption
				
				*	Make value of never-treated group as non-missing and zero for each relative time indicator, so this group can be included in the regression
				replace	relat_time=4	if	total_FS_used==0	//	Including only never-treated as a control group
								
				*	Creat dummy for each indicator (never-treated group will be zero in all indicator)
				cap	drop	relat_time_enum*
				tab	relat_time, gen(relat_time_enum)
				drop	relat_time_enum9	//	We should not use it, as it is a dummy for never-treated group
				
				label	var	relat_time_enum1	"t-4"
				label	var	relat_time_enum2	"t-3"
				label	var	relat_time_enum3	"t-2"
				label	var	relat_time_enum4	"t-1"
				label	var	relat_time_enum5	"t=0"
				label	var	relat_time_enum6	"t+1"
				label	var	relat_time_enum7	"t+2"
				label	var	relat_time_enum8	"t+3"
				
				xtreg PFS_glm 	relat_time_enum1	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7, fe
				est	store	PT_never_ever
				
				coefplot	PT_never_ever,	graphregion(color(white)) bgcolor(white) vertical keep(relat_time_enum*) xtitle(Event time) ytitle(Coefficient) 	///
											title(Never-treated vs Treated multiple times) /*subtitle(Excluding ever-treated outside this window)*/	name(PFS_pretrend, replace)
				graph	export	"${SNAP_outRaw}/PFS_never_ever.png", replace
				graph	close

			*	Treated-twice vs treated 3-times
			cap	drop	relat_time relat_time*
			
				*	Standardize event time
				gen		relat_time=-4	if	total_FS_used==3	&	f3.cumul_FS_used==2	&	f4.cumul_FS_used==3	//	4 year before 3rd FS redemption
				replace	relat_time=-3	if	total_FS_used==3	&	f2.cumul_FS_used==2	&	f3.cumul_FS_used==3	//	3 year before 3rd FS redemption
				replace	relat_time=-2	if	total_FS_used==3	&	f1.cumul_FS_used==2	&	f2.cumul_FS_used==3	//	2 year before 3rd FS redemption
				replace	relat_time=-1	if	total_FS_used==3	&	cumul_FS_used==2	&	f1.FS_rec_wth==1	&	f1.cumul_FS_used==3	//	1 year before 3rd FS redemption
				replace	relat_time=-0	if	total_FS_used==3	&	cumul_FS_used==3	&	FS_rec_wth==1		//	Year of 3rd FS redemption
				replace	relat_time=1	if	total_FS_used==3	&	cumul_FS_used==3	&	l1.FS_rec_wth==1	&	l1.cumul_FS_used==3	//	1 year after 3rd FS redemption
				replace	relat_time=2	if	total_FS_used==3	&	cumul_FS_used==3	&	l2.FS_rec_wth==1	&	l2.cumul_FS_used==3	//	2 year after 3rd FS redemption
				replace	relat_time=3	if	total_FS_used==3	&	cumul_FS_used==3	&	l3.FS_rec_wth==1	&	l3.cumul_FS_used==3	//	3 year after 3rd FS redemption
				
				*	Make value of treated-twice group as non-missing and zero for each relative time indicator, so this group can be included in the regression as a control group
				replace	relat_time=4	if	total_FS_used==2	// &	cumul_FS_used==2
				
				*	Creat dummy for each indicator (never-treated group will be zero in all indicator)
				cap	drop	relat_time_enum*
				tab	relat_time, gen(relat_time_enum)
				drop	relat_time_enum9	//	We should not use it, as it is a dummy forcontrol group
				
				label	var	relat_time_enum1	"t-4"
				label	var	relat_time_enum2	"t-3"
				label	var	relat_time_enum3	"t-2"
				label	var	relat_time_enum4	"t-1"
				label	var	relat_time_enum5	"t=0"
				label	var	relat_time_enum6	"t+1"
				label	var	relat_time_enum7	"t+2"
				label	var	relat_time_enum8	"t+3"
				
				xtreg PFS_glm 	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7	relat_time_enum8	i.year	, fe
				est	store	PT_never_ever
				
				coefplot	PT_never_ever,	graphregion(color(white)) bgcolor(white) vertical keep(relat_time_enum*) xtitle(Event time) ytitle(Coefficient) 	///
											title(Treated twice vs Treated 3-times)	name(PFS_pretrend, replace)
				graph	export	"${SNAP_outRaw}/PFS_twice_3times.png", replace
				graph	close
		}	
			
			/*
			*	Genenerate average PFS per each group
			cap	drop	PFS_glm_avg
			bys	relat_time	total_FS_used:	egen PFS_glm_avg = mean(PFS_glm) if inlist(total_FS_used,0,1)
			*/
			
			
			*	Plot graph
			
				/*
			graph twoway 		(kdensity HFSM_rescale	if	inlist(year,1999,2001,2003,2015,2017,2019)	&	!mi(PFS_glm))	///
								(kdensity PFS_glm		if	inlist(year,1999,2001,2003,2015,2017,2019)	&	!mi(HFSM_rescale)),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)		///
								name(thrifty, replace) graphregion(color(white)) bgcolor(white)		///
								legend(lab (1 "HFSM (rescaled)") lab(2 "PFS") rows(1))					
			graph	export	"${PSID_outRaw}/Fig_A2_Density_HFSM_PFS.png", replace
				*/
				
				
				*	FWL
				/*
				cap drop uhat1
				cap drop uhat2
				reg PFS_glm relat_time_enum1 relat_time_enum7	//	Regress Y on X1 X2 is equal to...
				reg PFS_glm relat_time_enum1	//	Regress Y on X1
				predict uhat1, resid			//	Get resid1
				reg relat_time_enum7 relat_time_enum1	//	Pregress X2 on X1
				predict uhat2, resid	//	Get resid2
				reg uhat1 uhat2	//	regressing resid1 on resid2!
				*/
			
			
			/*
			*	Seems leads are significant, meaning PT is violated...... is specification wrong?
			svy, subpop(if inrange(year,1975,1997)): reg PFS_glm relat_time_enum1-relat_time_enum7 ${regionvars} ${timevars} 
			reg	PFS_glm relat_time_enum1-relat_time_enum7 ${regionvars} ${timevars} if year<=1997
			svy: reg	foodexp_tot_exclFS_pc_real	relat_time_enum1-relat_time_enum7 ${regionvars} ${timevars}
			reg	foodexp_tot_exclFS_pc_real	relat_time_enum1-relat_time_enum7 ${regionvars} ${timevars}
			*/
			
			
			/*
			*	Real dollars of food expenditure over time
			bys year: egen foodexp_tot_exclFS_pc_real_m = mean(foodexp_tot_exclFS_pc_real)
			bys year: egen foodexp_tot_exclFS_pc_real_m = mean(foodexp_tot_exclFS_pc_real)
			
			preserve
			
			collapse foodexp_tot_exclFS_pc_real foodexp_tot_inclFS_pc_real	[iweight=wgt_long_fam_adj], by(year)
			
			graph	twoway	(line	fs_insecure year, lpattern(dash_dot) yaxis(1))	///
							(line	fs_insecure_vlfs year, lpattern(dash) yaxis(1))	///
							(line	fs_snap year, lpattern(dot) yaxis(1))	///
							(connected	fs_snap_novdec year	if	year!=1996, lpattern(dash_dot) yaxis(2)),	///					
							legend(label(1 "FI") label(2 "Very low FS") label(3 "SNAP (year)")	label(4 "SNAP (Nov/Dec)") rows(1)) ///
							ytitle(FI, axis(1))	ytitle(SNAP, axis(2)) title(Food Insecurity(FI) Prevalence and SNAP usage)	///
							note(This figure replicates Figure 3 in USDA 2019 report)
							
			graph	export	"${figures}/FSS_FI_SNAP.png", replace	
			graph	close
			
			restore
			*/
			
			
		
		
		
		*	Whether FS is used last month at once over the study period

		
		
		*	Time trends of food exp over time
		
			
		*	(V) Modify V4366 (FS used last year) in 1976
			*	This question actually asks if FS is use ALL THE TIME in previous year. So both "yes" and "no" should be coded as "yes" (Those who didn't use FS at all are coded as "inapp(0)")
			*	We no longer use last year's information
		*	(V) Until 1971, it is ambiguous whether food stamp amount was included in food expenditure (they are NOT included since 1972)
			*	We might need to assume that food expenditure amount is included, or drop those periods in worst case.
			*	For now we use years since 1976
		*	Split the year? - pre-1993 and post-1993
			*	Exogenous variation availability
			*	Food stamp and expenditure data (previous year vs current year/month)
		*	Import TFP value from the link
		*	(V) Import survey month to see seasonality of food expenditure reported.
		*	(V) Replace expenditure values to zero if that member didn't exist in that wave (i.e. sequence number outside 0-20)
		*	(V) Generate indicator if PSID RP is not equal to person
		*	Include School meal/WIC variables to see the ratio of school meal/WIC received also receive SNAP
		*	(V) Create real dollars of nominal value variables (don't replace them. Just create new ones)
		*	Check food stamp value reported vs recall period (to see the over- or under- reporting based on )
		*	Make a summary stat of (1) observation level (2) individual level
		
		
		*	Modeling
	
	}
	

	*	(2023-07-03) I disable the outdated codes below. I will re-activate them as needed
		/*		
						
							*	Original IV only
						
							ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
							est	store	`IVname'_IV_nofe_2nd
							scalar	Fstat_CD_`IVname'	=	 e(cdf)
							scalar	Fstat_KP_`IVname'	=	e(widstat)
						
							est	restore	`IVname'`endovar'
							estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
							estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

							est	store	`IVname'_nofe_IV_1st
							est	drop	`IVname'`endovar'
							
						
							*	Predicted value only		
							ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & reg_sample==1, robust	first savefirst savefprefix(`IVname')	 
							est	store	`IVname'_IV_nofe_2nd
							scalar	Fstat_CD_`IVname'	=	 e(cdf)
							scalar	Fstat_KP_`IVname'	=	e(widstat)
						
							est	restore	`IVname'`endovar'
							estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
							estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

							est	store	`IVname'_nofe_IV_1st
							est	drop	`IVname'`endovar'
												
							*global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
							*global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
						
						
							/*
							*	Add dynamic effects.
							*	First, predict FS amount received
							est restore `IVname'_nofe_IV_1st
							cap	drop	FS_wth_PFS_hat
							predict 	FS_wth_PFS_hat, xb
							lab	var		FS_wth_PFS_hat	"Predicted FS dummy received last month"
					
							*	Now, regress 2nd stage, including FS across multiple periods
							reghdfe	PFS_glm FS_wth_PFS_hat	l2.FS_wth_PFS_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	if	income_below_200==1	&	!mi(`IV') & reg_sample==1,	vce(robust) noabsorb
							est	store	`IVname'_dyn_X_nofe_2nd
						
							*global	PFS_est_2nd	${PFS_est_2nd}	PFS_dyn_X_2nd
							*/
					
					
						*	with state FE							
							ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & reg_sample==1,	absorb(ib31.rp_state) robust	first savefirst savefprefix(`IVname')
							est	store	`IVname'_IV_stfe_2nd
							scalar	Fstat_CD_`IVname'	=	 e(cdf)
							scalar	Fstat_KP_`IVname'	=	e(widstat)
						
							est	restore	`IVname'`endovar'
							estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
							estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

							est	store	`IVname'_stfe_IV_1st
							est	drop	`IVname'`endovar'
												
							*global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
							*global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
						
							/*
							*	Add dynamic effects.
							*	First, predict FS amount received
							est restore `IVname'_stfe_IV_1st
							cap	drop	FS_wth_PFS_hat
							predict 	FS_wth_PFS_hat, xb
							lab	var		FS_wth_PFS_hat	"Predicted FS dummy received last month"
					
							*	Now, regress 2nd stage, including FS across multiple periods
							reghdfe	PFS_glm FS_wth_PFS_hat	l2.FS_wth_PFS_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	if	income_below_200==1	&	!mi(`IV') & reg_sample==1,	vce(robust) absorb(ib31.rp_state)
							est	store	`IVname'_dyn_X_stfe_2nd
							*/
							
						*	state and individual FE														
							ivreghdfe	PFS_glm	${FSD_on_FS_X}	(`endovar' = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(`IV') & reg_sample==1,	absorb(ib31.rp_state x11101ll) robust	first savefirst savefprefix(`IVname')	 
							est	store	`IVname'_IV_fe_2nd
							scalar	Fstat_CD_`IVname'	=	 e(cdf)
							scalar	Fstat_KP_`IVname'	=	e(widstat)
						
							est	restore	`IVname'`endovar'
							estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
							estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

							est	store	`IVname'_fe_IV_1st
							est	drop	`IVname'`endovar'
												
							*global	PFS_est_1st	${PFS_est_1st}	`IVname'_1st
							*global	PFS_est_2nd	${PFS_est_2nd}	`IVname'_2nd
						
							/*
							*	Add dynamic effects.
							*	First, predict FS amount received
							est restore `IVname'_fe_IV_1st
							cap	drop	FS_wth_PFS_hat
							predict 	FS_wth_PFS_hat, xb
							lab	var		FS_wth_PFS_hat	"Predicted FS dummy received last month"
					
							*	Now, regress 2nd stage, including FS across multiple periods
							reghdfe	PFS_glm FS_wth_PFS_hat	l2.FS_wth_PFS_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	if	income_below_200==1	&	!mi(`IV') & reg_sample==1,	vce(robust) absorb(ib31.rp_state x11101ll)
							est	store	`IVname'_dyn_X_fe_2nd
							*/
												
					
						*	Tabulate results comparing OLS and IV
						
														
								*	Subsample (1996-2015) - for all IV (SSI, state citizen ideology and SNAP weighted index)
								esttab	index_nofe_IV_1st	index_stfe_IV_1st	index_fe_IV_1st	using "${SNAP_outRaw}/PFS_index_sub_IV_1st.csv", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(PFS on FS dummy)		replace	
															
							
							*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
								
															
								*	SNAP index
								esttab	nofesub_ols	index_IV_nofe_2nd	stfesub_ols	index_IV_stfe_2nd	fesub_ols	index_IV_fe_2nd	index_dyn_X_fe_2nd	using "${SNAP_outRaw}/PFS_index_ols_IV.csv", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(PFS on FS dummy)		replace	
								
								esttab	nofesub_ols	index_IV_nofe_2nd	stfesub_ols	index_IV_stfe_2nd	fesub_ols	index_IV_fe_2nd	index_dyn_X_fe_2nd	using "${SNAP_outRaw}/PFS_index_ols_IV.tex", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
								title(PFS on FS dummy)		replace	
												
				*/			
	
	
	*	(2023-08-20:	Unweighted IV regression has moved to here 
	{
	    
			
			*	Unweighted Policy index
				
				*	Setup
				loc	depvar		PFS_glm
				loc	endovar		FSdummy	//	FSamt_capita
				loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		index_uw
	
			
				*	First we run main IV regression including all FE, to use the uniform sample across different FE/specifications
				*	Sample restricted to (i) Income always below 200% through 97
					cap	drop reg_sample	
					ivreghdfe	`depvar'	 ${FSD_on_FS_X}	 ${timevars}	(`endovar' = `IV')	[aw=wgt_long_fam_adj] ///
						if	income_ever_below_200_9713==1 &	balanced_9713==1	&	!mi(`IV'),	///
						absorb(x11101ll	/*ib1996.year*/)  robust	cluster(x11101ll) //first  savefirst savefprefix(`IVname')	 
					gen	reg_sample=1 if e(sample)
					lab	var	reg_sample "Sample in IV regression"		
					
					*	Impute individual-level average covariates over time, using regression sample only (to comply with Wooldridge (2019))
					cap	drop	*_bar
					ds	${FSD_on_FS_X} ${timevars}
					foreach	var	in	`r(varlist)'	{
						bys	x11101ll:	egen	`var'_bar	=	mean(`var')	if	reg_sample==1
					}
					qui	ds	*_bar
					global	Mundlak_vars	`r(varlist)'
					
					
					
				*	Reduced form	(regress PFS on policy index)
				loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				reghdfe		PFS_glm	 `IV' ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb	//	no FE
				est	store	`IVname'_red_nofe
				reghdfe		PFS_glm	 `IV' ${FSD_on_FS_X}	${timevars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb // year FE
				est	store	`IVname'_red_yfe
				reghdfe		PFS_glm	 `IV' ${FSD_on_FS_X}	${timevars}	${Mundlak_vars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
				est	store	`IVname'_red_Mundlak
				reghdfe		PFS_glm	 `IV' ${FSD_on_FS_X}	${timevars} [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(/*ib1997.year*/ x11101ll)
				est	store	`IVname'_red_yife
				
				esttab	`IVname'_red_nofe	`IVname'_red_yfe	 `IVname'_red_Mundlak	`IVname'_red_yife	using "${SNAP_outRaw}/PFS_`IVname'_reduced.csv", ///
				cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
				title(PFS on FS dummy)		replace	
		
				*	OLS
				
					*	no FE
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb
					*reg		`depvar'	`endovar'	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	if	income_below_200==1,	robust	//cluster(x11101ll) // first savefirst savefprefix(`IVname')
					est	store	nofe_ols	
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample)	&	!mi(SNAP_index_w),	vce(robust) noabsorb
						est	store	nofesub_ols
						*/
					
					*	year FE
					*reg		`depvar'	`endovar'	${FSD_on_FS_X}	${regionvars}	[aw=wgt_long_fam_adj]	if	income_below_200==1,	robust	// cluster(x11101ll) // first savefirst savefprefix(`IVname') ///
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${timevars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
					est	store	yfe_ols
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample) & !mi(SNAP_index_w),	vce(robust) absorb(ib31.rp_state)
						est	store	stfesub_ols
						*/
						
					*	Mundlak controls
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${timevars}	${Mundlak_vars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
					est	store	mund_ols
					
					*	year and individual FE
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${timevars} [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(/*ib1997.year*/ x11101ll)
					est	store	yife_ols
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample) & !mi(SNAP_index_w),	vce(robust) absorb(ib31.rp_state x11101ll)
						est	store	fesub_ols
						*/
						
					*	Output OLS results
						esttab	nofe_ols	yfe_ols	 mund_ols	yife_ols	using "${SNAP_outRaw}/PFS_index_OLS_only.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS dummy)		replace	
					
				*	IV		
				loc	depvar		PFS_glm
				loc	endovar		FSdummy	//	FSamt_capita
				loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		index_uw_Z
							
					
					*	w/o FE		
						
						*	OLS in the first stage (classic 2SLS)
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						est	store	`IVname'_nofe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_nofe_1st
						est	drop	`IVname'`endovar'
						
						*	MLE in the first stage
						*	We first construct fitted value of the endogenous variable from the first stage, to be used as an IV
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_uw_Dhat
						
						cap	drop	FSdummy_hat
						logit	FSdummy	`IV'	${FSD_on_FS_X}	[pw=wgt_long_fam_adj] if	reg_sample==1, vce(cluster x11101ll) 
						predict	FSdummy_hat, p
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_nofe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_nofe_1st
						est	drop	`IVname'`endovar'
						
						*	IVregress with BOTH Z and Dhat
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_uw	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_uw_ZDhat
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_nofe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_nofe_1st
						est	drop	`IVname'`endovar'
		
				
				*	Tabulate results comparing OLS and IV
				
												
						*	1st stage
						esttab	index_uw_Z_nofe_1st 	index_uw_Dhat_nofe_1st	index_uw_ZDhat_nofe_1st	using "${SNAP_outRaw}/PFS_index_IV_nofe_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	nofe_ols	index_uw_Z_nofe_2nd 	index_uw_Dhat_nofe_2nd	index_uw_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_uw_Z_nofe_2nd 	index_uw_Dhat_nofe_2nd	index_uw_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/					
				
				
				*	with year FE only	
					
					*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita
					loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		index_uw_Z
	
						
						*	OLS in the first stage (classic 2SLS)
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							cluster (x11101ll)	/*absorb(year)*/		first savefirst savefprefix(`IVname')	 
						est	store	`IVname'_yfe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yfe_1st
						est	drop	`IVname'`endovar'
						
						*	MLE in the first stage
						*	We first construct fitted value of the endogenous variable from the first stage, to be used as an IV
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_uw_Dhat
						
						cap	drop	FSdummy_hat
						logit	FSdummy	`IV'	${FSD_on_FS_X}	${timevars} [pw=wgt_long_fam_adj] if	reg_sample==1, vce(cluster x11101ll) 
						predict	FSdummy_hat
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_yfe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yfe_1st
						est	drop	`IVname'`endovar'
						
						*	IVregress with BOTH Z and Dhat
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_uw	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_uw_ZDhat
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_yfe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yfe_1st
						est	drop	`IVname'`endovar'
					
					
					*	Tabulate results comparing OLS and IV
										
						*	1st stage
						esttab	index_uw_Z_yfe_1st 	index_uw_Dhat_yfe_1st	index_uw_ZDhat_yfe_1st	using "${SNAP_outRaw}/PFS_index_IV_yfe_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yfe_ols	index_uw_Z_yfe_2nd 	index_uw_Dhat_yfe_2nd	index_uw_ZDhat_yfe_2nd	using "${SNAP_outRaw}/PFS_index_IV_yfe_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
						
				
				
				*	With Mundlak controls (which include year-FE) (Wooldridge 2019)
				
						*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita
					loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		index_uw_Z
	
						
						*	OLS in the first stage (classic 2SLS)
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	${Mundlak_vars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							cluster (x11101ll)	/*absorb(year)*/	first savefirst savefprefix(`IVname') partial(*_bar)
						est	store	`IVname'_mund_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_mund_1st
						est	drop	`IVname'`endovar'
						
						*	MLE in the first stage
						*	We first construct fitted value of the endogenous variable from the first stage, to be used as an IV
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_uw_Dhat
						
						cap	drop	FSdummy_hat
						logit	FSdummy	`IV'	${FSD_on_FS_X}	${timevars}	${Mundlak_vars} [pw=wgt_long_fam_adj] if	reg_sample==1, vce(cluster x11101ll) 
						predict	FSdummy_hat
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	${Mundlak_vars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 partial(*_bar)
						
						est	store	`IVname'_mund_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_mund_1st
						est	drop	`IVname'`endovar'
						
						*	IVregress with BOTH Z and Dhat
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_uw	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_uw_ZDhat
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	${Mundlak_vars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 partial(*_bar)
						
						est	store	`IVname'_mund_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_mund_1st
						est	drop	`IVname'`endovar'
					
					
					*	Tabulate results comparing OLS and IV								
						
						*	1st stage
						esttab	index_uw_Z_mund_1st 	index_uw_Dhat_mund_1st	index_uw_ZDhat_mund_1st	using "${SNAP_outRaw}/PFS_index_IV_mund_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)		
													
						*	SNAP index
						esttab	mund_ols	index_uw_Z_mund_2nd 	index_uw_Dhat_mund_2nd	index_uw_ZDhat_mund_2nd	using "${SNAP_outRaw}/PFS_index_IV_mund_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
				
			
				*	with year- and individual- FE
				*	(2023-08-01) NOTE: It does not work with the latest sample (balanced individuals whose income is ever below 200% PL) due to unexpeded errors seems to be related with the perfect collinearity
					*	(source: https://github.com/sergiocorreia/ivreghdfe/issues/24)
				*	I will disable it for now.
					*	When I manually run without displaying the first stage, the second stage effect goes crazy (0.55), so should be OK to ignore it.
					
					*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita
					loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		index_uw_Z
	
						
						*	OLS in the first stage (classic 2SLS)
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars} 		(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							absorb(x11101ll)		cluster (x11101ll)  		first  savefirst savefprefix(`IVname')
							
						est	store	`IVname'_yife_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yife_1st
						est	drop	`IVname'`endovar'
						
						*	MLE in the first stage
						*	We first construct fitted value of the endogenous variable from the first stage, to be used as an IV
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_uw_Dhat
						
						cap	drop	FSdummy_hat
						clogit	FSdummy	`IV'	${FSD_on_FS_X}	${timevars}  if	reg_sample==1, group(x11101ll)
						predict	FSdummy_hat, p
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							absorb(x11101ll)	cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_yife_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yife_1st
						est	drop	`IVname'`endovar'
						
						*	IVregress with BOTH Z and Dhat
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_uw	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_uw_ZDhat
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							absorb(x11101ll)	cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_yife_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yife_1st
						est	drop	`IVname'`endovar'
					
					
					*	Tabulate results comparing OLS and IV
				
												
						*	1st stage
						esttab	index_uw_Z_yife_1st 	index_uw_Dhat_yife_1st	index_uw_ZDhat_yife_1st	using "${SNAP_outRaw}/PFS_index_IV_yife_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yife_ols	index_uw_Z_yife_2nd 	index_uw_Dhat_yife_2nd	index_uw_ZDhat_yife_2nd	using "${SNAP_outRaw}/PFS_index_IV_yife_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_uw_Z_nofe_2nd 	index_uw_Dhat_nofe_2nd	index_uw_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/		
			
				
					*	Output in the order I want
					
					*	1st stage (Z, Dhat, Z and Dhat)
					esttab	index_uw_Z_nofe_1st	index_uw_Dhat_nofe_1st	index_uw_ZDhat_nofe_1st	index_uw_Z_yfe_1st	index_uw_Dhat_yfe_1st	index_uw_ZDhat_yfe_1st	///
							index_uw_Z_mund_1st	index_uw_Dhat_mund_1st	index_uw_ZDhat_mund_1st	index_uw_Z_yife_1st	index_uw_Dhat_yife_1st	index_uw_ZDhat_yife_1st			///
						using "${SNAP_outRaw}/PFS_index_uw_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
				
					*	2nd stage (Z, Dhat, Z and Dhat)
					esttab	index_uw_Z_nofe_2nd	index_uw_Dhat_nofe_2nd	index_uw_ZDhat_nofe_2nd	index_uw_Z_yfe_2nd	index_uw_Dhat_yfe_2nd	index_uw_ZDhat_yfe_2nd	///
							index_uw_Z_mund_2nd	index_uw_Dhat_mund_2nd	index_uw_ZDhat_mund_2nd	index_uw_Z_yife_2nd	index_uw_Dhat_yife_2nd	index_uw_ZDhat_yife_2nd			///
						using "${SNAP_outRaw}/PFS_index_uw_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
				
				
				
				
		
	}
	
	*	(2023-08-20 Other specifications of IV (weighted SNAP index) reg (no FE, individual FE) are moved to here
	
	{
	    
		
			
			*	Reduced form	(regress PFS on policy index)
				loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				reghdfe		PFS_glm	 `IV' ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb	//	no FE
				est	store	`IVname'_red_nofe
				reghdfe		PFS_glm	 `IV' ${FSD_on_FS_X}	${timevars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb // year FE
				est	store	`IVname'_red_yfe
				reghdfe		PFS_glm	 `IV' ${FSD_on_FS_X}	${timevars}	${Mundlak_vars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
				est	store	`IVname'_red_Mundlak
				reghdfe		PFS_glm	 `IV' ${FSD_on_FS_X}	${timevars} [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(/*ib1997.year*/ x11101ll)
				est	store	`IVname'_red_yife
				
				esttab	`IVname'_red_nofe	`IVname'_red_yfe	 `IVname'_red_Mundlak	`IVname'_red_yife	using "${SNAP_outRaw}/PFS_`IVname'_reduced.csv", ///
				cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
				title(PFS on FS dummy)		replace	
		
			
			
			
				*	OLS
				
					*	no FE
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb
					*reg		`depvar'	`endovar'	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	if	income_below_200==1,	robust	//cluster(x11101ll) // first savefirst savefprefix(`IVname')
					est	store	nofe_ols	
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample)	&	!mi(SNAP_index_w),	vce(robust) noabsorb
						est	store	nofesub_ols
						*/
					
					*	year FE
					*reg		`depvar'	`endovar'	${FSD_on_FS_X}	${regionvars}	[aw=wgt_long_fam_adj]	if	income_below_200==1,	robust	// cluster(x11101ll) // first savefirst savefprefix(`IVname') ///
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${timevars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb	//	absorb(ib1997.year)
					est	store	yfe_ols
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample) & !mi(SNAP_index_w),	vce(robust) absorb(ib31.rp_state)
						est	store	stfesub_ols
						*/
						
					*	Individual fixed effects with macro-economic variables
					*reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${macrovars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(x11101ll)
					*est	store	macro_ols
					
					*	Mundlak controls
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${timevars}	${Mundlak_vars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
					est	store	mund_ols
					
					*	year and individual FE
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${timevars} [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(/*ib1997.year*/ x11101ll)
					est	store	yife_ols
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample) & !mi(SNAP_index_w),	vce(robust) absorb(ib31.rp_state x11101ll)
						est	store	fesub_ols
						*/
						
					*	Output OLS results
						esttab	nofe_ols	yfe_ols	 mund_ols	yife_ols	using "${SNAP_outRaw}/PFS_index_OLS_only.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS dummy)		replace	
					
		
			
					
				*	IV		
				loc	depvar		PFS_glm
				loc	endovar		FSdummy	//	FSamt_capita
			
							
					*	w/o FE		
						
						*	OLS in the first stage (classic 2SLS)
						loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_Z
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						est	store	`IVname'_nofe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_nofe_1st
						est	drop	`IVname'`endovar'
						
						*	MLE in the first stage
						*	We first construct fitted value of the endogenous variable from the first stage, to be used as an IV
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_Dhat
						
						cap	drop	FSdummy_hat
						logit	FSdummy	`IV'	${FSD_on_FS_X}	[pw=wgt_long_fam_adj] if	reg_sample==1, vce(cluster x11101ll) 
						predict	FSdummy_hat, p
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_nofe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_nofe_1st
						est	drop	`IVname'`endovar'
						
						*	IVregress with BOTH Z and Dhat
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_w	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_ZDhat
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_nofe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_nofe_1st
						est	drop	`IVname'`endovar'
		
				
				*	Tabulate results comparing OLS and IV
				
												
						*	1st stage
						esttab	index_w_Z_nofe_1st 	index_w_Dhat_nofe_1st	index_w_ZDhat_nofe_1st	using "${SNAP_outRaw}/PFS_index_w_nofe_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yfe_ols	index_w_Z_nofe_2nd 	index_w_Dhat_nofe_2nd	index_w_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_w_nofe_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_w_Z_nofe_2nd 	index_w_Dhat_nofe_2nd	index_w_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/					
				
				
				*	with year FE only	
					
					*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita

						
						*	OLS in the first stage (classic 2SLS)
						loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_Z
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							cluster (x11101ll)	/*absorb(year)*/		first savefirst savefprefix(`IVname')	 
						est	store	`IVname'_yfe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yfe_1st
						est	drop	`IVname'`endovar'
						
						*	MLE in the first stage
						*	We first construct fitted value of the endogenous variable from the first stage, to be used as an IV
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_Dhat
						
						cap	drop	FSdummy_hat
						logit	FSdummy	`IV'	${FSD_on_FS_X}	i.year [pw=wgt_long_fam_adj] if	reg_sample==1, vce(cluster x11101ll) 
						predict	FSdummy_hat
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_yfe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yfe_1st
						est	drop	`IVname'`endovar'
						
						*	IVregress with BOTH Z and Dhat
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_w	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_ZDhat
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_yfe_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yfe_1st
						est	drop	`IVname'`endovar'
					
					
					*	Tabulate results comparing OLS and IV
				
												
						*	1st stage
						esttab	index_w_Z_yfe_1st 	index_w_Dhat_yfe_1st	index_w_ZDhat_yfe_1st	using "${SNAP_outRaw}/PFS_index_w_yfe_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* )	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	nofe_ols	index_w_Z_yfe_2nd 	index_w_Dhat_yfe_2nd	index_w_ZDhat_yfe_2nd	using "${SNAP_outRaw}/PFS_index_w_yfe_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* )	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_w_Z_nofe_2nd 	index_w_Dhat_nofe_2nd	index_w_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/		
			
				/*
				*	Macroeconomic variable AND individual-FE (no year FE)
				*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita
					
	
						
						*	OLS in the first stage (classic 2SLS)
						loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_Z
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${macrovars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							absorb(x11101ll)		cluster (x11101ll)		first savefirst savefprefix(`IVname')	 
						est	store	`IVname'_macro_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_macro_1st
						est	drop	`IVname'`endovar'
						
						*	MLE in the first stage
						*	We first construct fitted value of the endogenous variable from the first stage, to be used as an IV
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_Dhat
						
						cap	drop	FSdummy_hat
						clogit	FSdummy	`IV'	${FSD_on_FS_X}	${macrovars}  if	reg_sample==1, group(x11101ll)
						predict	FSdummy_hat, p
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${macrovars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							absorb(x11101ll)	cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_macro_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_macro_1st
						est	drop	`IVname'`endovar'
						
						*	IVregress with BOTH Z and Dhat
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_w	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_ZDhat
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${macrovars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							absorb(x11101ll)	cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_macro_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_macro_1st
						est	drop	`IVname'`endovar'
					
					
					*	Tabulate results comparing OLS and IV
				
												
						*	1st stage
						esttab	index_w_Z_macro_1st 	index_w_Dhat_macro_1st	index_w_ZDhat_macro_1st	using "${SNAP_outRaw}/PFS_index_w_macro_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	macro_ols	index_w_Z_macro_2nd 	index_w_Dhat_macro_2nd	index_w_ZDhat_macro_2nd	using "${SNAP_outRaw}/PFS_index_w_macro_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
				*/
				
				
							
						
			
				*	with year- and individual- FE
				*	(2023-08-01) Since it did not work with the latest regression sample (ever below 200% PL, balanced 1997-2017) using unweighted index, I disable this part as well.
				
					*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita
					loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		index_w_Z
	
						
						*	OLS in the first stage (classic 2SLS)
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							absorb(x11101ll)		cluster (x11101ll)		first savefirst savefprefix(`IVname')	 
						est	store	`IVname'_yife_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yife_1st
						est	drop	`IVname'`endovar'
						
						*	MLE in the first stage
						*	We first construct fitted value of the endogenous variable from the first stage, to be used as an IV
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_Dhat
						
						cap	drop	FSdummy_hat
						clogit	FSdummy	`IV'	${FSD_on_FS_X}	${timevars}  if	reg_sample==1, group(x11101ll)
						predict	FSdummy_hat, p
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							absorb(x11101ll)	cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_yife_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yife_1st
						est	drop	`IVname'`endovar'
						
						*	IVregress with BOTH Z and Dhat
						loc	depvar		PFS_glm
						loc	endovar		FSdummy	//	FSamt_capita
						loc	IV			SNAP_index_w	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_w_ZDhat
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	${timevars}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							absorb(x11101ll)	cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
						est	store	`IVname'_yife_2nd
						scalar	Fstat_CD_`IVname'	=	 e(cdf)
						scalar	Fstat_KP_`IVname'	=	e(widstat)
					
						est	restore	`IVname'`endovar'
						estadd	scalar	Fstat_CD	=	Fstat_CD_`IVname', replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_`IVname', replace

						est	store	`IVname'_yife_1st
						est	drop	`IVname'`endovar'
					
					
					*	Tabulate results comparing OLS and IV
				
												
						*	1st stage
						esttab	index_w_Z_yife_1st 	index_w_Dhat_yife_1st	index_w_ZDhat_yife_1st	using "${SNAP_outRaw}/PFS_index_w_yife_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* )	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yife_ols	index_w_Z_yife_2nd 	index_w_Dhat_yife_2nd	index_w_ZDhat_yife_2nd	using "${SNAP_outRaw}/PFS_index_w_yife_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* )	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_w_Z_nofe_2nd 	index_w_Dhat_nofe_2nd	index_w_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_w_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/		
				
				
				
		
		
	}
	
	
	
	//