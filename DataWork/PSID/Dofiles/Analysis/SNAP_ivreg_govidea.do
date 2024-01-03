		
		di "${FSD_on_FS_X}"

		*	Unweighted Policy index
				
				*	Setup
				loc	depvar		PFS_glm
				loc	endovar		FSdummy	//	FSamt_capita
				loc	IV			inst6017_nom	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		gov
	
				global	timevars	year_enum4-year_enum28
				*	First we run main IV regression including all FE, to use the uniform sample across different FE/specifications
				*	Sample restricted to (i) Income always below 200% through 97
					cap	drop reg_sample	
					ivreghdfe	`depvar'	 ${FSD_on_FS_X}	 ${timevars}	(`endovar' = `IV')	[aw=wgt_long_fam_adj] ///
						if	income_ever_below_200_9713==1 &	!mi(`IV'),	///
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
				loc	IV			citi6016	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				loc	IVname		citi	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
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
					
					*	year FE
					*reg		`depvar'	`endovar'	${FSD_on_FS_X}	${regionvars}	[aw=wgt_long_fam_adj]	if	income_below_200==1,	robust	// cluster(x11101ll) // first savefirst savefprefix(`IVname') ///
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${timevars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
					est	store	yfe_ols
			
						
					*	Mundlak controls
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${timevars}	${Mundlak_vars}	 [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
					est	store	mund_ols
					
					*	year and individual FE
					reghdfe		PFS_glm	 FSdummy ${FSD_on_FS_X}	${timevars} [aw=wgt_long_fam_adj] if	reg_sample==1,	vce(cluster x11101ll) absorb(/*ib1997.year*/ x11101ll)
					est	store	yife_ols
					
				
					*	Output OLS results
						esttab	nofe_ols	yfe_ols	 mund_ols	yife_ols	using "${SNAP_outRaw}/PFS_OLS_only.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS dummy)		replace	

				
				*	With Mundlak controls (which include year-FE) (Wooldridge 2019)
				
						*	IV
					loc	depvar		PFS_glm
					loc	endovar		FSdummy	//	FSamt_capita
					loc	IV			inst6017_nom	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		gov_Z
	
						
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
					loc	IV			inst6017_nom	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		gov_Dhat
						
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
					loc	IV			inst6017_nom	FSdummy_hat	//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
					loc	IVname		gov_ZDhat
						
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
						esttab	gov_Z_mund_1st 	gov_Dhat_mund_1st	gov_ZDhat_mund_1st	using "${SNAP_outRaw}/PFS_gov_IV_mund_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
													
					
					*	2nd stage (OLS with and w/o FE, IV with and w/o FE)		
													
						*	SNAP index
						esttab	mund_ols	gov_Z_mund_2nd 	gov_Dhat_mund_2nd	gov_ZDhat_mund_2nd	using "${SNAP_outRaw}/PFS_gov_IV_mund_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
				
			