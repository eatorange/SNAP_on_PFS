					
		*	Weak IV test 
		*	(2022-05-01) For now, we use IV to predict T(FS participation) and use it to predict W (food expenditure per capita) (previously I used it to predict PFS in the second stage)
		use	"${SNAP_dtInt}/SNAP_long_const", clear
		local	endovar	FS_rec_wth
		local	depvar	/*PFS_glm*/	foodexp_tot_inclFS_pc
		
		*	Set globals
		global	demovars		rp_age rp_age_sq	rp_nonWhte	rp_married	rp_female	
		global	econvars		ln_fam_income_pc	unemp_rate
		global	healthvars		rp_disabled
		global	familyvars		famnum	ratio_child	change_RP
		global	empvars			rp_employed
		global	eduvars			rp_NoHS rp_somecol rp_col
		global	foodvars		FS_rec_wth
		global	regionvars		rp_state_enum1-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
		global	timevars		year_enum5-year_enum13 year_enum15-year_enum32	//	Exclude 1978 (year_enum4, base year) and 1990 (year_enum14, no lagged food exp available)
		
				
		*	Temporary renaming
		rename	(SNAP_index_unweighted	SNAP_index_weighted)	(SNAP_index_uw	SNAP_index_w)
		lab	var	SNAP_index_uw 	"Unweighted SNAP index"
		lab	var	SNAP_index_w 	"Weighted SNAP index"
		
		*	Temporary generate interaction variable
		gen	int_SSI_exp_sl_01_03	=	SSI_exp_sl	*	year_01_03
		gen	int_SSI_GDP_sl_01_03	=	SSI_GDP_sl	*	year_01_03
		*gen	int_SSI_GDP_sl_post96	=	SSI_GDP_sl	*	post_1996
		*gen	int_SSI_GDP_s_post96	=	SSI_GDP_s	*	post_1996

		*	Regression test
		*	For now we test 4 models
			*	(1) Political vars and state-level SSI, without FE
			*	(2) Political vars and state-level SSI, with FE
			*	(3) Political vars and state&local level SSI, without FE
			*	(4) Political vars and state&local level SSI, with FE
			
			*	(1) P and S-SSI, without FE
			*	Before we proceed, let's see whether there are big differences between analytical weight without survey structure, and using survey structure
			
			*	SSI (share of state exp on state exp)
			loc	IV		SSI_GDP_s
			loc	IVname	SSI_GDP_s
				
				*	1. Manual 1st-stage reg (analytic weight)
				reg	`endovar'	`IV'	${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	///
					[aw=wgt_long_fam_adj]	if	in_sample==1 & inrange(year,1977,2019), robust	cluster(x11101ll)
					
				*	2. Manual 1st-stage reg (survey structure)
				svy: reg	`endovar'	`IV'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	///
					if	in_sample==1 & inrange(year,1977,2019)
					
				*	3. IV-reg (with analytic weight)
				ivregress	2sls 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}	${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019), first
				estat firststage
				
				*	4. IV-reg (with survey structure)
				svy: ivregress	2sls 	`depvar'	 ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	///
					if	in_sample==1 & inrange(year,1977,2019), first
				*estat firststage
				
				*	5. IV-reg (with analytic weight, ivreg2 does not allow survey structure)
				ivreg2 	`depvar'	} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IV')
			
							
			*	The results show that
				*	Comparing analytic weight and survey structure (1 vs 2, 3 vs 4: they give same coefficients with very similar standard errors
				*	Comparing manual 1st-stage and ivregress (1 vs 3, 2 vs 4): 
			/*
			*	SSI (share of s&l exp on s&l exp), with 2001/2003 interaction
			loc	IV		SSI_exp_sl
			loc	IVname	SSI_exp_sl
			ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	int_SSI_exp_sl_01_03		(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
				if	!mi(PFS_glm),	robust	cluster(x11101ll) first savefirst savefprefix(`IV')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			*/
						
			*	SSI (share of state exp on state exp)
			loc	IV		SSI_exp_s
			loc	IVname	SSI_exp_s
				
				*	Manual 1st-stage reg (analytic weight)
				reg	`endovar'	`IV'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}	${familyvars}	${eduvars}	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019), robust	cluster(x11101ll)
					
				*	Manual 1st-stage reg (survey structure)
				svy: reg	`endovar'	`IV'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	///
					if	in_sample==1 & inrange(year,1977,2019)
				
				*	IV-reg (with analytic weight)
				ivregress	2sls 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}	${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019), first
				
				*	IV-reg (with survey structure)
				svy: ivregress	2sls 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	///
					if	in_sample==1 & inrange(year,1977,2019), first
				
				*	IV-reg (with analytic weight, ivreg2 does not allow survey structure)
				ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019),	robust	cluster(x11101ll) first savefirst savefprefix(`IV')
									
									
				est	store	`IVname'_2nd
				scalar	Fstat_`IVname'	=	e(widstat)
				est	restore	`IVname'`endovar'
				estadd	scalar	Fstat	=	Fstat_`IVname', replace
				est	store	`IVname'_1st
				est	drop	`IVname'`endovar'
			
			/*
			*	SSI (share of GDP on s&l exp), with 2001/2003 interaction and post-1996 interactions
			loc	IV	SSI_GDP_sl
			loc	IVname	SSI_GDP_sl
			ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	int_SSI_exp_sl_01_03	int_SSI_GDP_sl_post96		(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
				if	!mi(PFS_glm),	robust	cluster(x11101ll) first savefirst savefprefix(`IV')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			*/
			
			*	SSI (share of GDP on s exp)
			loc	IV	SSI_GDP_s
			loc	IVname	SSI_GDP_s
			ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/		(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	///
				if	!mi(PFS_glm),	robust	cluster(x11101ll) first savefirst savefprefix(`IV')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			
			*	State control ("mixed" is omitted as base category)
			loc	IV	major_control_dem major_control_rep
			loc	IVname	politics
			ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	if	!mi(PFS_glm),	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			
			/*
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
			
			*	SSI (exp_s) and state control (1977-2019)
			loc	IV	SSI_exp_s	major_control_dem major_control_rep	
			loc	IVname	SSI_exp_s_pol
			ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	if	!mi(PFS_glm),	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			
			*	SSI (GDP_s) and state control (1977-2019)
			loc	IV	SSI_GDP_s	major_control_dem major_control_rep	
			loc	IVname	SSI_GDP_s_pol
			ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}	${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	if	!mi(PFS_glm),	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			
			
			*	All IVs (including SNAP index)
			loc	IV	SSI_exp_s	SSI_GDP_s	major_control_dem major_control_rep	//SNAP_index_w
			loc	IVname	all
			ivreg2 	`depvar'	${indvars} ${demovars} ${econvars}		${healthvars}	${empvars}		${familyvars}	${eduvars}	/*${regionvars}	${timevars}*/	(`endovar'	=	`IV')	[aw=wgt_long_fam_adj]	if	!mi(PFS_glm),	///
								robust	cluster(x11101ll) first savefirst savefprefix(`IVname')
			est	store	`IVname'_2nd
			scalar	Fstat_`IVname'	=	e(widstat)
			est	restore	`IVname'`endovar'
			estadd	scalar	Fstat	=	Fstat_`IVname', replace
			est	store	`IVname'_1st
			est	drop	`IVname'`endovar'
			
			
			*	1st-stage
			esttab	SSI_exp_s_1st	SSI_GDP_s_1st	SSI_exp_s_pol_1st	SSI_GDP_s_pol_1st	all_1st	using "${SNAP_outRaw}/WeakIV_1st.csv", ///
					cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(Fstat, fmt(%8.3fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Weak IV_1st)		replace	
					
			*	2nd-stage
			esttab	SSI_2nd	state_control_2nd	SNAP_index_w_2nd	SSI_state_control_2nd	all_2nd	using "${SNAP_outRaw}/WeakIV_2nd.csv", ///
					cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(Fstat, fmt(%8.3fc)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(_cons)*/	///
					title(Weak IV_2nd)		replace	
		
		
		
		
		*estout bbce_1st, stats(Fstat)
		
		*estat firststage
		*weakivtest
		/*
		local	depvar	PFS_glm
		svy, subpop(if !mi(PFS_glm)):	ivregress	2sls	`depvar'	${indvars} ${demovars}	(FS_rec_wth	=	bbce)	
		weakivtest
		estat firststage
		*/
	
	