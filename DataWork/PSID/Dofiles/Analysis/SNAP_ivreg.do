
*	This do-file includes final analyses after testing various models
	*	For model testing, please check "SNAP_ivreg_test.do"

	*	IV regression
	if	`IV_reg'==1	{
			
		*	Weak IV test 
		*	(2022-05-01) For now, we use IV to predict T(FS participation) and use it to predict W (food expenditure per capita) (previously I used it to predict PFS in the second stage)
		use	"${SNAP_dtInt}/SNAP_const", clear
		
		
		
		
		*	Keep only observations where citizen ideology IV is available (1977-2015)
		*	(2023-1-15) Maybe I shouldn't do it, because even if IV is available till 2015, we still use PFS in 2017 and 2019 (Iv regression automatically exclude 2017/2019, since there's no IV there.)
		*keep	if	inrange(year,1977,2015) & !mi(citi6016)
		
		
		*	Outcome variables
		summ	PFS_glm	PFS_FI_glm
		summ	PFS_glm PFS_FI_glm	[aw=wgt_long_fam_adj]
		summ	PFS_glm PFS_FI_glm	[aw=wgt_long_fam_adj] if income_below_200==1 
		
		*	IV: Official SNAP index (unweighted and weighted)	
		summ	SNAP_index_uw SNAP_index_w
		summ	SNAP_index_uw SNAP_index_w	[aw=wgt_long_fam_adj]
		summ	SNAP_index_uw SNAP_index_w	[aw=wgt_long_fam_adj] if income_below_200==1 
		
		
		summ	citi6016	[aw=wgt_long_fam_adj] if income_below_200==1 
		
		*	(Corrlation and bivariate regression of stamp redemption with state/govt ideology)
		pwcorr	FS_rec_wth	citi6016 inst6017_nom 	if	in_sample==1 & inrange(year,1997,2015)  & income_below_200==1,	sig
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
		label	var	year_01_03	"2001 or 2003"
		label	var	citi6016	"State citizen ideology (1960-2015)"
		
		
		*	Re-scale (to vary from 0 to 1) and standardize SNAP index
		*	Not sure I am gonna use it..
			foreach	type	in	uw	w	{

				*	Re-scaled version
				cap	drop	SNAP_index_`type'_0to1
				summ	SNAP_index_`type'  [aw=wgt_long_fam_adj]
				gen		SNAP_index_`type'_0to1	=	(SNAP_index_`type'-r(min)) / (r(max) - r(min))
				lab	var	SNAP_index_`type'_0to1		"SNAP Policy Index (`type' \& rescaled)"
						
				*	Standardized version				
				cap drop SNAP_index_`type'_std
				summ	SNAP_index_`type'  [aw=wgt_long_fam_adj]
				gen	SNAP_index_`type'_std = (SNAP_index_`type' - r(mean)) / r(sd)
				lab	var	SNAP_index_`type'_std	"SNAP policy index (`type' \& standardized)"
				
			}

		
			
		*	Re-scale citizen ideology variable (from 0-100 to 0-1 : for better interpretation)
		cap	drop	citi6016_0to1
		gen	citi6016_0to1	=	citi6016/100
		lab	var	citi6016_0to1	"State citizen ideology (0-1)"

		
		*	Temporary create copies of endogenous variable (name too long)
			cap	drop	FSdummy	FSamt	FSamtK
			clonevar	FSdummy			=	FS_rec_wth
			clonevar	FSamt			=	FS_rec_amt_real
			clonevar	FSamtcp			=	FS_rec_amt_capita_real
			
			gen			FSamtK	=	FSamt/1000
			lab	var		FSamtK	"Stamp benefit (USD) (K)"
			lab	var		FSamtcp	"FS/SNAP benefit amount per capita"
			
			cap	drop	FS_amt_real
			cap	drop	FS_amt_realK
			cap	drop	FS_amt_cap_real
			cap	drop	FS_amt_cap_realK
			clonevar	FS_amt_real			=	FS_rec_amt_real
			gen			FS_amt_realK		=	FS_rec_amt_real	/	1000
			clonevar	FS_amt_cap_real		=	FS_rec_amt_capita_real
			gen			FS_amt_cap_realK	=	FS_rec_amt_capita_real / 1000
			lab	var		FS_amt_real			"FS/SNAP benefit"
			lab	var		FS_amt_realK		"FS/SNAP benefit (K)"
			lab	var		FS_amt_cap_realK	"FS/SNAP benefit per capita (K)"
	
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
		
	
	
		*	(2023-7-2)
		*	As many things have changed, I am writing this comments to organize my thoughts
		/*	
			1. IV
			We will use the following IVs
				a. SNAP policy index (benchmark IV)
					-	Available period: 1996-2013
					-	unweighted: Easy to interpret (increase in index by 1 implies adopting one more friendly policy), but does not capture relative importance of each policy.
					-	weighted: Not so eaasy to interpret, but captures relative importance of each policy.
				b.	SNAP overpayment rate (if possible)
					-	Available period: 1980-2013, 2017-2019 (2015 is not complete due to quality issue)
				c.	Social spending index
					-	Available period: 1977-2019
			2.	Estimation method
				a.	Classic (OLS in both 1st and 2nd stagethe first)
					-	Can be used for all three IVs above
				b.	Probit/logit in the first stage, and include the predicted variable as an IV in the second stage (benchmark estimation)
					-	Source: https://www.statalist.org/forums/forum/general-stata-discussion/general/1399436-instrumental-variables-with-binary-endogenous-regressor
			3.	Estimations to be done
				a.	policy index only (OLS and MLE)
				b.	SNAP overpayment only (OLS and MLE)
				c.	policy index AND overpayment (OLS and MLE. need to do overidentifying test.)
				d.	social spending index (for full period)
			4.	FE
				a.	No FE
				b.	year FE
				c.	year and individual-FE
				
			
			*	Since there are many specifications/IV/methods/FE to try, let's do one by one
			*	For now (2023-07-02), try SNAP policy index (unweighted and weighted) only. We can gradually test other IVs
				*	SNAP policy index (unweighted, weighted)
					1.	OLS - no FE, state FE and full FE
					2.	IV
						2a.	1st-stage OLS
							-	original IV (Z)
						2b. 1st-stage MLE (i.e. logit)
							-	predicted value (Dhat)
							-	predicted value AND original IV (Z and Dhat)
						(source: https://www.statalist.org/forums/forum/general-stata-discussion/general/1302474-2sls-regression-with-binary-endogenous-variable)
						(address: https://www.statalist.org/forums/forum/general-stata-discussion/general/1399436-instrumental-variables-with-binary-endogenous-regressor)
		
		
			NOTE: Be careful NOT to do "forbidden regression"
			(address: https://twitter.com/jmwooldridge/status/1365119735424307204)
				 a) Using fitted values from a nonlinear first stage as IVs in a linear second stage.
				(b) Finding your high school sweetheart on Facebook.
				(c) Inserting fitted values from a first stage into a nonlinear second stage.
			(source: https://edrub.in/ARE212/section11.html#the_forbidden_regression)
				(a) You use a nonlinear predictor in your first stage, e.g., probit, logit, Poisson, etc. You need linear OLS in the first stage to guarantee that the covariates and fitted values in second stage will be uncorrelated with the error (exogenous).
				(b) Your first stage does not match your second stage, e.g.,
					You use different fixed effects in the two stages
					You use a different functional form of the endogenous covariate in the two stages, e.g., x inn the first stage and x^2 in the second stage.
		
		
		*/	
		
		
		
			*	Set the benchmark specification based on the test above.	
			*	Benchmark specification
			*	But here I inclued "lagged PFS" as Chris suggested, and excluded "statevars" by my own decision. We can further test this specification with different IV/endogenous variable (political status didn't work still)
			*	(2022-11-16) updates
				*	(1) use 'food expenditure' up to the 2nd order as lagged state,
				*	(2) compare b/w with and w/o state FE  (without FE as benchmark)
				*	(3) compare OLS and IV as diagnosis.
			*	(2022-1-22) updates
				*	(1) Use new PFS (which is estimated using new commands, with state, individual- and year-FE)
				*	(2) Use new command (reghdfe, ivreghdfe) - generates same result.
				*	(3) Always include state FE
			*	(2022-7-28) Note: the last benchmark model (SSI as single IV to instrument amount of FS benefit) tested was including "${statevars}" and excluding "lagged PFS"
			
			global	FSD_on_FS_X		${statevars}	${demovars} ${econvars}	${healthvars}	${empvars}	${familyvars}	${eduvars} ${regionvars}	//	${macrovars} 
			global	PFS_est_1st
			global	PFS_est_2nd
			global	PFS_est_1st
			global	PFS_est_2nd	//	This one includes OLS as well.
			
			
			*	Unweighted Policy index
				
				*	Setup
				loc	depvar		PFS_glm
				loc	endovar		FSdummy	//	FSamt_capita
				loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		index_uw
	
			
				*	First we run main IV regression including all FE, to use the uniform sample across different FE/specifications
					cap	drop reg_sample	
					ivreghdfe	`depvar'	 ${FSD_on_FS_X}	 (`endovar' = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 &	inrange(year,1996,2013)	&	!mi(`IV'),	///
						absorb(x11101ll	ib1997.year) robust	cluster(x11101ll) first  savefirst savefprefix(`IVname')	 
					gen	reg_sample=1 if e(sample)
					lab	var	reg_sample "Sample in IV regression"														
			
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
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(ib1997.year)
					est	store	yfe_ols
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample) & !mi(SNAP_index_w),	vce(robust) absorb(ib31.rp_state)
						est	store	stfesub_ols
						*/
						
					*	year and individual FE
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(ib1997.year x11101ll)
					est	store	yife_ols
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample) & !mi(SNAP_index_w),	vce(robust) absorb(ib31.rp_state x11101ll)
						est	store	fesub_ols
						*/
					
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
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	nofe_ols	index_uw_Z_nofe_2nd 	index_uw_Dhat_nofe_2nd	index_uw_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
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
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							cluster (x11101ll)	absorb(year)		first savefirst savefprefix(`IVname')	 
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
						logit	FSdummy	`IV'	${FSD_on_FS_X}	i.year [pw=wgt_long_fam_adj] if	reg_sample==1, vce(cluster x11101ll) 
						predict	FSdummy_hat
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
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
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
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
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yfe_ols	index_uw_Z_yfe_2nd 	index_uw_Dhat_yfe_2nd	index_uw_ZDhat_yfe_2nd	using "${SNAP_outRaw}/PFS_index_IV_yfe_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_uw_Z_nofe_2nd 	index_uw_Dhat_nofe_2nd	index_uw_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/		
			

			
				*	with year- and individual- FE
					
					*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita
					loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		index_uw_Z
	
						
						*	OLS in the first stage (classic 2SLS)
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
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
						loc	IV			SNAP_index_uw	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						loc	IVname		index_uw_Dhat
						
						cap	drop	FSdummy_hat
						clogit	FSdummy	`IV'	${FSD_on_FS_X}	i.year  if	reg_sample==1, group(x11101ll)
						predict	FSdummy_hat, p
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
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
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
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
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yife_ols	index_uw_Z_yife_2nd 	index_uw_Dhat_yife_2nd	index_uw_ZDhat_yife_2nd	using "${SNAP_outRaw}/PFS_index_IV_yife_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_uw_Z_nofe_2nd 	index_uw_Dhat_nofe_2nd	index_uw_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/		
			
				
				
				
				
						
			*	Weighted Policy index
				
				*	Setup
				loc	depvar		PFS_glm
				loc	endovar		FSdummy	//	FSamt_capita
				loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		index_w
	
			
				*	First we run main IV regression including all FE, to use the uniform sample across different FE/specifications
					cap	drop reg_sample	
					ivreghdfe	`depvar'	 ${FSD_on_FS_X}	 (`endovar' = `IV')	[aw=wgt_long_fam_adj] if	income_below_200==1 &	inrange(year,1996,2013)	&	!mi(`IV'),	///
						absorb(x11101ll	ib1997.year) robust	cluster(x11101ll) first  savefirst savefprefix(`IVname')	 
					gen	reg_sample=1 if e(sample)
					lab	var	reg_sample "Sample in IV regression"														
			
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
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(ib1997.year)
					est	store	stfe_ols
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample) & !mi(SNAP_index_w),	vce(robust) absorb(ib31.rp_state)
						est	store	stfesub_ols
						*/
						
					*	Individual fixed effects with macro-economic variables
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${macrovars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(x11101ll)
					est	store	macro_ols
					
					*	year and individual FE
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(ib1997.year x11101ll)
					est	store	fe_ols
					
						/*
						*	With 1996-2015 only (SNAP index)
						reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	 [aw=wgt_long_fam_adj] if	income_below_200==1 & !mi(reg_sample) & !mi(SNAP_index_w),	vce(robust) absorb(ib31.rp_state x11101ll)
						est	store	fesub_ols
						*/
					
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
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yfe_ols	index_w_Z_nofe_2nd 	index_w_Dhat_nofe_2nd	index_w_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_w_nofe_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
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
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
							cluster (x11101ll)	absorb(year)		first savefirst savefprefix(`IVname')	 
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
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
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
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, cluster (x11101ll)	first savefirst savefprefix(`IVname')	 
						
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
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	nofe_ols	index_w_Z_yfe_2nd 	index_w_Dhat_yfe_2nd	index_w_ZDhat_yfe_2nd	using "${SNAP_outRaw}/PFS_index_w_yfe_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_w_Z_nofe_2nd 	index_w_Dhat_nofe_2nd	index_w_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/		
			
			
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
				
			
			
				*	with year- and individual- FE
					
					*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita
					loc	IV			SNAP_index_w	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		index_w_Z
	
						
						*	OLS in the first stage (classic 2SLS)
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
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
						clogit	FSdummy	`IV'	${FSD_on_FS_X}	i.year  if	reg_sample==1, group(x11101ll)
						predict	FSdummy_hat, p
		
						*	IVregress with the predicted value (Dhat)
						loc	IV		FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
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
						
						ivreghdfe	PFS_glm	${FSD_on_FS_X}	i.year	(FSdummy = `IV')	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
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
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yife_ols	index_w_Z_yife_2nd 	index_w_Dhat_yife_2nd	index_w_ZDhat_yife_2nd	using "${SNAP_outRaw}/PFS_index_w_yife_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_w_Z_nofe_2nd 	index_w_Dhat_nofe_2nd	index_w_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_w_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/		
				
				
				*	Tabulate in the order I want
					
					*	1st stage (Z, Dhat, Z and Dhat)
					esttab	index_w_Z_nofe_1st	index_w_Z_yfe_1st	index_w_Z_yife_1st	index_w_Dhat_nofe_1st	index_w_Dhat_yfe_1st	index_w_Dhat_yife_1st	///
						index_w_ZDhat_nofe_1st	index_w_ZDhat_yfe_1st	index_w_ZDhat_yife_1st	///
						using "${SNAP_outRaw}/PFS_index_w_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
				
					*	2nd stage (Z, Dhat, Z and Dhat)
					esttab	index_w_Z_nofe_2nd	index_w_Z_yfe_2nd	index_w_Z_yife_2nd	index_w_Dhat_nofe_2nd	index_w_Dhat_yfe_2nd	index_w_Dhat_yife_2nd	///
						index_w_ZDhat_nofe_2nd	index_w_ZDhat_yfe_2nd	index_w_ZDhat_yife_2nd	///
						using "${SNAP_outRaw}/PFS_index_w_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum* *year)	///
						title(PFS on FS dummy)		replace	
				
				
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
								

			*	Regressing FSD on predicted FS, using the model we find above
								
				*	Choose which endogeneous variable/IV to use
				*	Make sure to turn on/off both variable and associated names.
				global	endovar	FSdummy	//	participation dummy
					global	endovarname	dummy
				*global	endovar	FSamtcp	//	amount received per capita (in real)
				*	global	endovarname	amtcap
				
				cap	drop	citi0to1
				clonevar	citi0to1	=	citi6016_0to1
				
				global	IV	citi0to1	//	SSI
					global	IVname citi
				*global	IV	SNAP_index_w
					*global	IVname	index
					
				cap	drop	FS_amt_real
				cap	drop	FS_amt_realK
				clonevar	FS_amt_real		=	FS_rec_amt_real
				gen			FS_amt_realK	=	FS_rec_amt_real	/	1000
				lab	var	FS_amt_realK	"FS amount (K)"
					
			foreach	FSDvar	in	/*SL_5 TFI_HCR	CFI_HCR*/	TFI_FIG	CFI_FIG	TFI_SFIG	CFI_SFIG		{
				
				global	depvar	`FSDvar'
				
				*global	${depvar}_${endovarname}_${IVname}_est_1st	
				*global	${depvar}_${endovarname}_${IVname}_est_2nd	
				
										
					*	Static, state and individual FE
					*loc	endovar	FS_rec_amt_real
					*loc	IV		SSI_GDP_sl
					loc	model	${depvar}_${endovarname}_${IVname}
					ivreghdfe	${depvar}	 ${FSD_on_FS_X}	 (${endovar}	=	${IV})	[aw=wgt_long_fam_adj] if	income_below_200==1 &	!mi(${IV}) & reg_sample==1,	///
							absorb(ib31.rp_state x11101ll) robust first savefirst savefprefix(`model')	 
					est	store	`model'_2nd
					scalar	Fstat_`model'	=	e(widstat)
					est	restore	`model'${endovar}
					estadd	scalar	Fstat	=	Fstat_`model', replace
					est	store	`model'_1st
					est	drop	`model'${endovar}
										
					*global	${depvar}_${endovarname}_${IVname}_est_1st	${depvar}_${endovarname}_${IVname}_est_1st	`model'_1st
					*global	${depvar}_${endovarname}_${IVname}_est_2nd	${depvar}_${endovarname}_${IVname}_est_2nd	`model'_2nd
					
					/*
					*	Dynamic model (including FS amount from multiple periods)
					*	We will do this manually
						*	Note: this will make our SE incorrect. Need to adjust later (but how?)
					*	First, predict FS amount from the first stage.
				
					est restore ${depvar}_${endovarname}_${IVname}_1st
					cap	drop	FS_${endovarname}_${IVname}_${depvar}_hat
					predict 	FS_${endovarname}_${IVname}_${depvar}_hat, xb
					*lab	var	FS_${endovar}_${depvar}_hat	"Predicted FS amount received last month"
					
					*	Now, regress 2nd stage, including FS across multiple periods	
					reghdfe	${depvar} FS_${endovarname}_${IVname}_${depvar}_hat	l2.FS_${endovarname}_${IVname}_${depvar}_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
						if	income_below_200==1 & !mi(${IV}),	vce(robust) absorb(ib31.rp_state x11101ll)
			
					est	store	${depvar}_${endovarname}_${IVname}_dyn_2nd
					*global		${depvar}_${endovarname}_${IVname}_est_2nd			${depvar}_${endovarname}_${IVname}_est_2nd	///
																					${depvar}_${endovarname}_${IVname}_dyn_2nd
					
					*/
					*	1st-stage
					esttab	${depvar}_${endovarname}_${IVname}_1st	using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_1st.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(${depvar} on FS_1st with ${endovarname})		replace	
							
					esttab	${depvar}_${endovarname}_${IVname}_1st		using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_1st.tex", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(SL_5 on FS_1st)		replace	
							
					*	2nd-stage
					esttab	${depvar}_${endovarname}_${IVname}_2nd	/*${depvar}_${endovarname}_${IVname}_dyn_2nd*/		using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_2nd.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(SL_5 on FS_2nd)		replace		
							
					esttab	${depvar}_${endovarname}_${IVname}_2nd	/*${depvar}_${endovarname}_${IVname}_dyn_2nd*/		using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_2nd.tex", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(SL_5 on FS_2nd)		replace	
				
			}
					
					
					
				summ	PFS_glm SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG TFI_SFIG CFI_SFIG	if income_below_200==1 & !mi(citi6016) &	!mi(PFS_glm)					[aw=wgt_long_fam_adj]	//	all sample
				summ	PFS_glm SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG TFI_SFIG CFI_SFIG	if income_below_200==1 & !mi(citi6016) &	!mi(PFS_glm)	& PFS_FI_glm==1 	[aw=wgt_long_fam_adj]	//	Food insecure by PFS
				summ	PFS_glm SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG TFI_SFIG CFI_SFIG	if income_below_200==1 & !mi(citi6016) &	!mi(PFS_glm)	& FS_rec_wth==1 	[aw=wgt_long_fam_adj]	//	FS/SNAP beneficiaries
			
				*	Sub-sample (when SNAP index is available)
				summ	PFS_glm SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if income_below_200==1 & !mi(citi6016) &	!mi(SNAP_index_w) & !mi(PFS_glm)					[aw=wgt_long_fam_adj]	//	all sample
				summ	PFS_glm SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if income_below_200==1 & !mi(citi6016) &	!mi(SNAP_index_w) & !mi(PFS_glm)	& FS_rec_wth==1 	[aw=wgt_long_fam_adj]	//	FS/SNAP beneficiaries	
				summ	PFS_glm SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if income_below_200==1 & !mi(citi6016) &	!mi(SNAP_index_w) & !mi(PFS_glm)	& PFS_FI_glm==1 	[aw=wgt_long_fam_adj]	//	Food insecure by PFS
				
		
		*	Print relevant models toegether
		
			*	Incidence
			esttab	SL_5_dummy_citi_2nd	TFI_HCR_dummy_citi_2nd	CFI_HCR_dummy_citi_2nd		///
			using "${SNAP_outRaw}/SL5_TFI0_CFI0.csv", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(SNAP on Incidences)		replace	
						
			esttab	SL_5_dummy_citi_2nd	TFI_HCR_dummy_citi_2nd	CFI_HCR_dummy_citi_2nd		///
			using "${SNAP_outRaw}/SL5_TFI0_CFI0.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(SNAP on Incidences)		replace	
						
			*	Level and Severity
			esttab	TFI_FIG_dummy_citi_2nd	CFI_FIG_dummy_citi_2nd	TFI_SFIG_dummy_citi_2nd		CFI_SFIG_dummy_citi_2nd	///
			using "${SNAP_outRaw}/TFI1_CFI1_TFI2_CFI2.csv", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(SNAP on Level and Severity)		replace
						
			esttab	TFI_FIG_dummy_citi_2nd	CFI_FIG_dummy_citi_2nd	TFI_SFIG_dummy_citi_2nd		CFI_SFIG_dummy_citi_2nd	///
			using "${SNAP_outRaw}/TFI1_CFI1_TFI2_CFI2.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(SNAP on Level and Severity)		replace
						
		/*
			
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
		*/	
		
		

		
	}
	
	*	Summary stats	
	if	`summ_stats'==1	{
		 
		use	"${SNAP_dtInt}/SNAP_const", clear
		
		*	Keep 1977-2015 data (where citizen ideology is available)
		*	(2023-1-15) Maybe I shouldn't do it, because even if IV is available till 2015, we still use PFS in 2017 and 2019
		*keep	if	inrange(year,1977,2015)
			*	Re-scale HFSM, so it can be compared with the PFS
			
			cap	drop	HFSM_rescale
			gen	HFSM_rescale = (9.3-HFSM_scale)/9.3
			label	var	HFSM_rescale "HFSM (re-scaled)"
			
			*	Density Estimate of Food Security Indicator (Figure A1)
				
				*	ALL households
				graph twoway 		(kdensity HFSM_rescale	[aw=wgt_long_fam_adj]	if	!mi(HFSM_rescale)	&	!mi(PFS_glm) & inrange(year,1977,2015))	///
									(kdensity PFS_glm		[aw=wgt_long_fam_adj]	if	!mi(HFSM_rescale)	&	!mi(PFS_glm) & inrange(year,1977,2015)),	///
									/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)	 ylabel(0(3)21)	///
									name(FSSS_PFS, replace) graphregion(color(white)) bgcolor(white) title(All)		///
									legend(lab (1 "FSSS (rescaled)") lab(2 "PFS") rows(1))					
					
				*	Income below 200% & until 2015 (study sample)
				graph twoway 		(kdensity HFSM_rescale	[aw=wgt_long_fam_adj]	if	!mi(HFSM_rescale)	&	!mi(PFS_glm) & income_below_200==1 & inrange(year,1977,2015))	///
									(kdensity PFS_glm		[aw=wgt_long_fam_adj]	if	!mi(HFSM_rescale)	&	!mi(PFS_glm) & income_below_200==1 & inrange(year,1977,2015)),	///
									/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)  ylabel(0(3)21)		///
									name(FSSS_PFS_below200, replace) graphregion(color(white)) bgcolor(white) title(Income below 200%)		///
									legend(lab (1 "FSSS (rescaled)") lab(2 "PFS") rows(1))	
				
			graph	combine	FSSS_PFS	FSSS_PFS_below200, graphregion(color(white) fcolor(white)) 
			graph	export	"${SNAP_outRaw}/Fig_A2_Density_FSSS_PFS.png", replace
			
			
			*	PFS by gender
			graph twoway 		(kdensity PFS_glm	[aw=wgt_long_fam_adj]	if	!mi(PFS_glm) & inrange(year,1977,2015) & income_below_200==1 & ind_female==0, bwidth(0.05) )	///
								(kdensity PFS_glm	[aw=wgt_long_fam_adj]	if	!mi(PFS_glm) & inrange(year,1977,2015) & income_below_200==1 & ind_female==1, bwidth(0.05) ),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(PFS) ytitle(Density)		///
								name(PFS_ind_gender, replace) graphregion(color(white)) bgcolor(white)	title(by Gender)	///
								legend(lab (1 "Male") lab(2 "Female") rows(1))	
								
								
			*	PFS by race
			graph twoway 		(kdensity PFS_glm	[aw=wgt_long_fam_adj]	if	inrange(year,1977,2015) & rp_nonWhte==0, bwidth(0.05) )	///
								(kdensity PFS_glm	[aw=wgt_long_fam_adj]	if	inrange(year,1977,2015) & rp_nonWhte==1, bwidth(0.05) ),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(PFS) ytitle(Density)		///
								name(PFS_rp_race, replace) graphregion(color(white)) bgcolor(white) title(by Race)		///
								legend(lab (1 "White") lab(2 "non-White") rows(1))	
			
			graph	combine	PFS_ind_gender	PFS_rp_race, graphregion(color(white) fcolor(white)) 
			graph	export	"${SNAP_outRaw}/PFS_kdensities.png", replace
			graph	close
			
		
		
		*	Sample information
			
			count if 	income_below_200==1		&	!mi(PFS_glm)		//	# of observations with non-missing PFS
			count if in_sample	&	income_below_200==1		&	!mi(PFS_glm)	&	baseline_indiv==1	//	Baseline individual in sapmle
			count if in_sample	&	income_below_200==1		&	!mi(PFS_glm)	&	splitoff_indiv==1	//	Splitoff individual in sapmle
				
			*	Number of individuals
				distinct	x11101ll	if	!mi(PFS_glm)	&	income_below_200==1		//	# of baseline individuals in sapmle
				distinct	x11101ll	if	income_below_200==1		//	# of baseline individuals in sapmle (including missing PFS)
				distinct	x11101ll	if	!mi(PFS_glm)	&	income_below_200==1		&	baseline_indiv==1	//	# of baseline individuals in sapmle
				distinct	x11101ll	if	!mi(PFS_glm)	&	income_below_200==1		&	splitoff_indiv==1	//	Baseline individual in sapmle
				
			*	Counting only individuals in regression sample
				distinct	x11101ll	if	reg_sample==1 // reg_sample==1
				distinct	x11101ll	if	reg_sample==1	&	baseline_indiv==1	//	# of baseline individuals in sapmle
				distinct	x11101ll	if	reg_sample==1	&	splitoff_indiv==1	//	# of baseline individuals in sapmle
			
			unique	x11101ll	if	!mi(PFS_glm)	//	Total individuals
			unique	year		if	!mi(PFS_glm)		//	Total waves
	
		
		*	Yearly trends in PFS
		*	Earlier years have very high PFS, need to think of why it is happening...
		preserve
			keep	if	reg_sample==1 
			collapse	(mean) PFS_glm HFSM_rescale [aw=wgt_long_fam_adj], by(year)
			graph	twoway	(line PFS_glm year) (line HFSM_rescale year)
		restore
		
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
				local	IVs		citi6016_0to1
				local	FSDvars	PFS_glm	SL_5	TFI_HCR	CFI_HCR	TFI_FIG	CFI_FIG	TFI_SFIG	CFI_SFIG	
				
				estpost summ	`indvars'		if	!mi(PFS_glm)	/*  num_waves_in_FU_uniq>=2	 &*/	  // Temporary condition. Need to think proper condition.
				estpost summ	`indvars'		if	in_sample==1	&	income_below_200==1	/*  num_waves_in_FU_uniq>=2	 &*/	  // Temporary condition. Need to think proper condition.
				
				local	summvars	/*`indvars'*/	`rpvars'	`famvars'	`FSvars'	`IVs'	`FSDvars'
	
				estpost tabstat	`summvars'	 if in_sample==1	&	!mi(PFS_glm)	[aw=wgt_long_fam_adj],	statistics(count	mean	sd	min	median	p95	max) columns(statistics)		// save
				est	store	sumstat_all
				estpost tabstat	`summvars' 	if in_sample==1	&	!mi(PFS_glm)	&	income_below_200==1	[aw=wgt_long_fam_adj],	statistics(mean	sd	min	max) columns(statistics)	// save
				est	store	sumstat_lowinc
				
					*	FS amount per capita in real dollars (only those used)
					estpost tabstat	 FS_rec_amt_capita	if in_sample==1	&	!mi(PFS_glm)	&	income_below_200==1	& FS_rec_wth==1 [aw=wgt_long_fam_adj],	statistics(mean	sd	min	max) columns(statistics)	// save
				

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
	

	
	