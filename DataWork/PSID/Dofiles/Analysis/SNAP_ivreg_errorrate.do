	
			*	Payment Error Rate
				
				*	Setup
				loc	depvar		PFS_glm
				loc	endovar		FSdummy	//	FSamt_capita
				loc	IV			error_total	
				loc	IVname		error_Z
	
			
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
				loc	IV			error_total		//			//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		error_Z
							
					
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
					loc	IV			error_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_Dhat
						
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
					loc	IV			error_total	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_ZDhat
						
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
						esttab	error_Z_nofe_1st 	error_Dhat_nofe_1st	error_ZDhat_nofe_1st	using "${SNAP_outRaw}/PFS_error_IV_nofe_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	nofe_ols	error_Z_nofe_2nd 	error_Dhat_nofe_2nd	error_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_error_IV_nofe_2nd.csv", ///
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
					loc	IV			error_total	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_Z
	
						
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
					loc	IV			error_total	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_Dhat
						
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
					loc	IV			error_total	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_ZDhat
						
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
						esttab	error_Z_yfe_1st 	error_Dhat_yfe_1st	error_ZDhat_yfe_1st	using "${SNAP_outRaw}/PFS_errorIV_yfe_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yfe_ols	error_Z_yfe_2nd 	error_Dhat_yfe_2nd	error_ZDhat_yfe_2nd	using "${SNAP_outRaw}/PFS_error_IV_yfe_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
						
				
				
				*	With Mundlak controls (which include year-FE) (Wooldridge 2019)
				
						*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita
					loc	IV			error_total	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_Z
	
						
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
					loc	IV			error_total	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_Dhat
						
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
					loc	IV			error_total	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_ZDhat
						
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
						esttab	error_Z_mund_1st 	error_Dhat_mund_1st	error_ZDhat_mund_1st	using "${SNAP_outRaw}/PFS_error_IV_mund_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)		
													
						*	SNAP index
						esttab	mund_ols	error_Z_mund_2nd 	error_Dhat_mund_2nd	error_ZDhat_mund_2nd	using "${SNAP_outRaw}/PFS_error_IV_mund_2nd.csv", ///
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
					loc	IV			error_total	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_Z
	
						
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
					loc	IV			error_total	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_Dhat
					
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
					loc	IV			error_total	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		error_ZDhat
						
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
						esttab	error_Z_yife_1st 	error_Dhat_yife_1st	error_ZDhat_yife_1st	using "${SNAP_outRaw}/PFS_error_IV_yife_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)
						
													
						*	SNAP index
						esttab	yife_ols	error_Z_yife_2nd 	error_Dhat_yife_2nd	error_ZDhat_yife_2nd	using "${SNAP_outRaw}/PFS_error_IV_yife_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
						
						/*
						esttab	nofe_ols	index_uw_Z_nofe_2nd 	index_uw_Dhat_nofe_2nd	index_uw_ZDhat_nofe_2nd	using "${SNAP_outRaw}/PFS_index_IV_nofe_2nd.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(rp_state_enum*)	///
						title(PFS on FS dummy)		replace	
						*/		
			
				
					*	Output in the order I want
					
					*	1st stage (Z, Dhat, Z and Dhat)
					esttab	error_Z_nofe_1st	error_Dhat_nofe_1st	error_ZDhat_nofe_1st	error_Z_yfe_1st	error_Dhat_yfe_1st	error_ZDhat_yfe_1st	///
							error_Z_mund_1st	error_Dhat_mund_1st	error_ZDhat_mund_1st	error_Z_yife_1st	error_Dhat_yife_1st	error_ZDhat_yife_1st			///
						using "${SNAP_outRaw}/PFS_error_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
				
					*	2nd stage (Z, Dhat, Z and Dhat)
					esttab	error_Z_nofe_2nd	error_Dhat_nofe_2nd	error_ZDhat_nofe_2nd	error_Z_yfe_2nd	error_Dhat_yfe_2nd	error_ZDhat_yfe_2nd	///
							error_Z_mund_2nd	error_Dhat_mund_2nd	error_ZDhat_mund_2nd	error_Z_yife_2nd	error_Dhat_yife_2nd	error_ZDhat_yife_2nd			///
						using "${SNAP_outRaw}/PFS_error_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
				
				
				