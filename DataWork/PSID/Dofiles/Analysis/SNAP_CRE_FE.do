*	Check equivalnce between CRE (Mundlak) and FE
*	Note that xtlogit drops observations which as within-zero variation in dependent variable.

*	(2024-1-30) I FOUND CRE AND FE ARE MOSTLY EQUIVALENT WHEN I INCLUDE TIME-AVERAGE OF ENDOGENOUS VARIABLE, WHICH I HAVE PREVIUOSLY EXCLUDED SO FAR!

	*	Tag observations with zero within-variance in SNAP status
	global	RHS	${FSD_on_FS_X}	${timevars}	//	Excluding Mundlak
	
	cap drop xtlogit_sample
	cap	drop	SNAPhat_xtlogit
	xtlogit	${endovar}	${IV}	${RHS}	 if reg_sample==1, fe
	gen xtlogit_sample=1 if e(sample)
	predict SNAPhat_xtlogit
	
	*	Time-average of controls and time dummies
	global	Mundlak_vars	//	clear global
	global	FSD_on_FS_X_dm	//	clear global
	
	ds	PFS_ppml	FSdummy	SNAP_index_w	${FSD_on_FS_X} ${timevars}
	foreach	var	in	`r(varlist)'	{
		cap	drop	`var'_bar
		bys	x11101ll:	egen	`var'_bar	=	mean(`var') if reg_sample==1
		global	Mundlak_vars	${Mundlak_vars}	`var'_bar
		
		cap	drop	`var'_dm
		gen	`var'_dm	=	`var'	-	`var'_bar
		
	}
	di	"${Mundlak_vars}"
	cap	drop	SNAP_index_w_bar
	bys	x11101ll:	egen	SNAP_index_w_bar	=	mean(SNAP_index_w) if reg_sample==1	//	Time-average of ${endovar}_hat_bar
				
	global	FSD_on_FS_X_dm	rp_female_dm rp_age_dm rp_age_sq_dm rp_nonWhte_dm rp_married_dm rp_disabled_dm rp_col_dm
	global	timevars_dm		year_enum20_dm year_enum21_dm year_enum22_dm year_enum23_dm year_enum24_dm year_enum25_dm year_enum26_dm year_enum27_dm	
	global	RHS_dm			${FSD_on_FS_X_dm}	${timevars_dm}
	
	*	First-difference estimator
	global	d_FSD_on_FS_X
	ds	PFS_ppml	FSdummy	SNAP_index_w	${FSD_on_FS_X}
	foreach	var	in	`r(varlist)'	{
		
		di	"var is `var'"
		cap	drop	d_`var'
		gen	d_`var'	=	`var'	-	l2.`var'
	
	}
	ds	d_rp_female-d_rp_col
	global	d_FSD_on_FS_X	`r(varlist)'
	
	
	*	2024-1-30
	*	I find that CRE is almost equivalent to FE when I include time-average of first independent variable (i.e. SNAP index for the fist stage, etc.)
		
		
		*	(1)	3-stage model
		
			*	1st-stage: Non-linear regression of SNAP status on IV
			*	Note that I added "SNAP_inde_w_bar", time-average of SNAP indices
			cap	drop	${endovar}_hat
			logit	${endovar}	${IV}	${RHS}	SNAP_index_w_bar	${Mundlak_vars}	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
			predict	${endovar}_hat
			lab	var	${endovar}_hat	"Predicted SNAP"		
			margins, dydx(SNAP_index_w) post
			estadd	local	Controls	"Y"
			estadd	local	YearFE		"Y"
			estadd	local	Mundlak		"Y"
			scalar	Fstat_CD_${Zname}	=	 e(cdf)
			scalar	Fstat_KP_${Zname}	=	e(widstat)
			summ	${endovar}	${sum_weight}	if	e(sample)==1
			estadd	scalar	mean_SNAP	=	 r(mean)
			est	store	logit_SPI_mund

	
			*	2nd stage: Linear regression of SNAP on predicted SNAP
			**	I do this manually, since automatic IV regression does not allow me to include two different time-averarge variables (time average of ${endovar}_hat in the 2nd stage, and of FSdummy_hat in the 3rd stage)
				*	Also this gives me a concern of forbidden regression.
			cap	drop	${endovar}_hat_bar
			bys	x11101ll:	egen	${endovar}_hat_bar	=	mean(${endovar}_hat) if reg_sample==1	//	Time-average of ${endovar}_hat_bar
				
			cap	drop	FSdummy_hat2
			reghdfe	${endovar}	${endovar}_hat	${endovar}_hat_bar	${RHS}	${Mundlak_vars} ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
			predict	FSdummy_hat2
			
				*	Compare with FE. Can see it is almost identical
				reghdfe	${endovar}	${endovar}_hat	${RHS}	 ${reg_weight}	if reg_sample==1, absorb(x11101ll)	vce(cluster x11101ll) 
			
			*	3rd stage
			cap	drop	FSdummy_hat2_bar
			bys	x11101ll:	egen	FSdummy_hat2_bar	=	mean(FSdummy_hat2) if reg_sample==1	//	Constructe time-average of the fitted value.
			
			reghdfe	${depvar}	FSdummy_hat2	FSdummy_hat2_bar	${RHS}	${Mundlak_vars}	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
			
				*	Compare with FE. Coefficients slightly differ, but mostly equivalent.
				reghdfe	${depvar}	FSdummy_hat2	${RHS}	 ${reg_weight}	if reg_sample==1, absorb(x11101ll)	vce(cluster x11101ll) 
					
					
	
		*	(2)	Conventional 2-stage model (SNAP index as IV directly)
			
			*	1st stage
			
				*	Mundlak, no individual FE
				cap	drop	FSdummy_hat3
				reghdfe	${endovar}	${IV}	SNAP_index_w_bar	${RHS}	${Mundlak_vars}	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 	//	1st stage
				predict	FSdummy_hat3
				
				*	FE. Coeffcient and SE almost identical
				reghdfe	${endovar}	${IV}	${RHS}	 ${reg_weight}	if reg_sample==1, absorb(x11101ll)	vce(cluster x11101ll) 
				predict temp2
				
		
			*	Manual 2nd stage
				
				*	Mundlak, No individual FE (predicte first stage from no-FE model above)
				cap	drop	FSdummy_hat3_bar
				bys	x11101ll:	egen	FSdummy_hat3_bar	=	mean(FSdummy_hat3) if reg_sample==1	//	Constructe time-average of the fitted value.
				
				reghdfe	${depvar}	FSdummy_hat3	FSdummy_hat3_bar	${RHS}		${Mundlak_vars}	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 	//	2nd stage
				
				*	Individual FE. COEFFICIENT VARIES A LOT.... BUT WHY?
				*	But coefficient is almost identical to automatic IV with 2-stage FE
				reghdfe	${depvar}	FSdummy_hat3	${RHS}	 ${reg_weight}	if reg_sample==1, absorb(x11101ll)	vce(cluster x11101ll) 
			
			*	Anutomatic 2nd stage
			
				*	CAN"T do automatic 2nd stage with Mundlak, since I need average of the predicted SNAP status, which can't be done in the first stage.)
				
				*	Individual FE
				*	But coefficient is almost identical to automatic IV with 2-stage FE
				ivreghdfe	PFS_ppml	${RHS} 	(${endovar} = SNAP_index_w)	${reg_weight} if reg_sample==1, absorb(x11101ll)	cluster (x11101ll)	
	
				
	
		*	First-difference regression
				global	d_timevars	year_enum21-year_enum27
		
			*	OLS
		
				*	Bivariate
				reg	d_PFS_ppml	d_FSdummy
				
				*	With controls
				reg	d_PFS_ppml	d_FSdummy	${d_FSD_on_FS_X}	if reg_sample==1, 	cluster (x11101ll)	
				
				*	Time FE
				reg	d_PFS_ppml	d_FSdummy	${d_FSD_on_FS_X}	${d_timevars}	if reg_sample==1, 	cluster (x11101ll)		
				
				*	Weight
				reg	d_PFS_ppml	d_FSdummy	${d_FSD_on_FS_X}	${d_timevars}	${reg_weight} 	if reg_sample==1, 	cluster (x11101ll)		
				
				
			*	IV
				
				*	Manual first stage
				reg	d_FSdummy	d_SNAP_index_w	${d_FSD_on_FS_X}	${d_timevars}	if reg_sample==1, 	cluster(x11101ll)		
				
				
				*	IV regression
				ivreg	d_PFS_ppml	${d_FSD_on_FS_X}	${d_timevars}	(d_FSdummy = d_SNAP_index_w)	if reg_sample==1, 	cluster (x11101ll)		
				
		
		*	Within-transformation
		
				*	Show that it is almost identical to fixed effects (theoretically the same)				
				reghdfe	PFS_ppml	FSdummy		${RHS}		${reg_weight} 	if reg_sample==1, absorb(x11101ll)
				reg		PFS_ppml_dm	FSdummy_dm	${RHS_dm}	${reg_weight}	if reg_sample==1

				
				*	Manual 1st-stage (mostly the same)
				reghdfe	FSdummy		SNAP_index_w	${RHS}		${reg_weight}	if reg_sample==1, absorb(x11101ll) cluster(x11101ll)
				reg		FSdummy_dm	SNAP_index_w_dm	${RHS_dm}	${reg_weight}	if reg_sample==1, cluster(x11101ll)
			
				
				*	IV
				ivreghdfe	PFS_ppml	${RHS} 		(FSdummy = SNAP_index_w)	${reg_weight} if reg_sample==1, 	absorb(x11101ll)	cluster (x11101ll)	first	
				ivreg2		PFS_ppml_dm	${RHS_dm} 	(FSdummy_dm = SNAP_index_w_dm)	${reg_weight} if reg_sample==1, 	first cluster (x11101ll)	
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	
	/// Before 2024/1/30
	
	
	
	*	Compare CRE and FE
	
		*	OLS naive regression (PFS on SNAP)
		
			*	very simple model (bivariate, no weight)
			*	coefficients on rp_female are the same, but constant and standard errors are different
			reghdfe		PFS_ppml	rp_female	if	reg_sample==1, cluster(x11101ll)	//	OLS
			xtreg	PFS_ppml	rp_female	if	reg_sample==1, fe cluster(x11101ll)	//	FE with clustering
			reg		PFS_ppml	rp_female	rp_female_bar	if	reg_sample==1, cluster(x11101ll)	//	CRE, manual. beta and se same as FE.
			xthybrid	PFS_ppml	rp_female	if	reg_sample==1, cre se clusterid(x11101ll)	//	CRE, user-written code. beta same as FE but se differs.
			
			*	More controls
			reghdfe		${depvar}	${endovar}	${RHS}	if	reg_sample==1, cluster(x11101ll)	//	OLS
			reghdfe		${depvar}	${endovar}	${RHS}	if reg_sample==1, cluster(x11101ll)  absorb(x11101ll)	//	FE
			reghdfe		${depvar}	${endovar}	${RHS}	FSdummy_bar	${Mundlak_vars}		if reg_sample==1, cluster(x11101ll)	// CRE, manual
			xthybrid	${depvar}	${endovar}	${RHS}		if reg_sample==1, cluster(x11101ll)	cre //  absorb(x11101ll)	//	CRE
			
			if reg_sample==1 & xtlogit_sample==1
			
			*	Including those with zero within variation in outcome
			*	Similar in sign and significance, but magnitude is somewhat different
			reghdfe		${depvar}	${endovar}	${RHS}	${Mundlak_vars}		 ${reg_weight} if reg_sample==1, cluster(x11101ll)	//  absorb(x11101ll)	//	CRE
			reghdfe		${depvar}	${endovar}	${RHS}	 ${reg_weight} if reg_sample==1, cluster(x11101ll)  absorb(x11101ll)	//	FE
		
			*	Excluding those with zero within variation in outcome
			*	Much similar, but not exactly the same.
			reghdfe		${depvar}	${endovar}	${RHS}	${Mundlak_vars}		 ${reg_weight} if reg_sample==1 & xtlogit_sample==1, cluster(x11101ll)	//  absorb(x11101ll)	//	CRE
			reghdfe		${depvar}	${endovar}	${RHS}	 ${reg_weight} if reg_sample==1 & xtlogit_sample==1, cluster(x11101ll)  absorb(x11101ll)	//	FE
			
		*	First-stage (SNAP on SPI)
			
			*	Linear directly using SNAP
			*	Sign and significance are OK, but magnitude is different by 50%
			reghdfe		${endovar}	${IV}	${RHS}	SNAP_index_w_bar ${Mundlak_vars}		 ${reg_weight} if reg_sample==1, cluster(x11101ll)	//  CRE, including zero whtin-variation
			reghdfe		${endovar}	${IV}	${RHS}	${reg_weight} if reg_sample==1, cluster(x11101ll) absorb(x11101ll)	//  FE, including zero within-variation
			
			*	Sign and significance are OK, but magnitude is getting closer.
			reghdfe		${endovar}	${IV}	${RHS}	${Mundlak_vars}		 ${reg_weight} if reg_sample==1 & xtlogit_sample==1, cluster(x11101ll)	//  CRE, excluding zero whtin-variation
			reghdfe		${endovar}	${IV}	${RHS}	${reg_weight} if reg_sample==1 & xtlogit_sample==1, cluster(x11101ll) absorb(x11101ll)	//  FE, excluding zero within-variation
			
			*	Non-linear MLE (drop survey weights for now, as xtlogit doesnt accept pweight)
			*	Note that I can use neither clsutering 
			cap	drop	SNAPhat_mund
			logit	${endovar}	${IV}	${RHS}	${Mundlak_vars}		 if reg_sample==1 & xtlogit_sample==1, cluster(x11101ll)	//  CRE, excluding zero whtin-variation
			predict	SNAPhat_mund	if	e(sample)
				*	xtlogit	${endovar}	${IV}	${RHS}	${Mundlak_vars}		 if reg_sample==1 & xtlogit_sample==1, fe vce(cluster x11101ll)	//	Cannot be run since "xtlogit, fe" does not take clustering
			cap	drop	SNAPhat_FE
			clogit	${endovar}	${IV}	${RHS}		 if reg_sample==1 & xtlogit_sample==1, group(x11101ll) cluster( x11101ll)	// https://www.statalist.org/forums/forum/general-stata-discussion/general/1453675-xtlogit-fe-vce-cluster
			predict	SNAPhat_FE	if	e(sample)
			
			graph	twoway	(kdensity	SNAPhat_mund)	(kdensity	SNAPhat_FE)
			
			*	2SLS
				
				*	Original
				ivreghdfe	${depvar}	${RHS}	${Mundlak_vars}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, cluster(x11101ll) 	first savefirst savefprefix(${Zname})
			
				*	Refind
				ivreghdfe	${depvar}	${RHS}	${Mundlak_vars}	(${endovar} = SNAPhat_mund)	${reg_weight} if reg_sample==1 & xtlogit_sample==1, cluster(x11101ll) 	first savefirst savefprefix(${Zname})
				ivreghdfe	${depvar}	${RHS}					(${endovar} = SNAPhat_FE)	${reg_weight} if reg_sample==1 & xtlogit_sample==1, absorb(x11101ll)	cluster(x11101ll) 	first savefirst savefprefix(${Zname})
			
			
			ds	${depvar}	${endovar}	${IV}	${FSD_on_FS_X}	
			foreach	var	in	`r(varlist)'	{
				
				di	"var is `var'"
				cap	drop	d_`var'
				gen	d_`var'	=	`var'	-	l2.`var'
				
			}
			
			
			global	d_FSD_on_FS_X	d_rp_female d_rp_age d_rp_age_sq d_rp_nonWhte d_rp_married d_rp_disabled d_rp_col
			global	d_IV			d_SNAP_index_w
			global	d_depvar		d_PFS_ppml
			global	d_endovar		d_FSdummy
			*global	d_timevars
			
			*	OLS
			reg	${d_depvar}		${d_endovar}	${d_FSD_on_FS_X}	${timevars}
			
			reg	${d_endovar}	${d_IV}	${d_FSD_on_FS_X}	${timevars} ${reg_weight}	if reg_sample==1, cluster(x11101ll)
			
			
			
			
			ivreghdfe	${d_depvar}	${d_FSD_FS_on_X}	(${d_endovar} = ${d_IV})	${reg_weight} if reg_sample==1, cluster(x11101ll) 	first savefirst savefprefix(${Zname})
			
			
			summ
			
			
/*
				*	Side: Does clustering affect regression coefficients?
				*	Since default estimator is RE, yes (RE vs FE)
				xtlogit	${endovar}	${IV}	${RHS}	 if reg_sample==1 & xtlogit_sample==1	//	RE, no clutering
				xtlogit	${endovar}	${IV}	${RHS}	 if reg_sample==1 & xtlogit_sample==1, fe 	//	FE, no clustering
				xtlogit	${endovar}	${IV}	${RHS}	 if reg_sample==1 & xtlogit_sample==1, vce(cluster x11101ll)	//	RE, clustering.
		
*/


	//	CRE
	//	FE


	*	IV 
			ivreghdfe	${depvar}	${RHS}	(${endovar} = SNAPhat_xtlogit)	${reg_weight} if reg_sample==1 & xtlogit_sample==1, absorb(x11101ll)	cluster(x11101ll) 	first savefirst savefprefix(${Zname})
			ivreghdfe	${depvar}	${RHS}	(${endovar} = SNAP_index_w)	${reg_weight} if reg_sample==1 & xtlogit_sample==1, absorb(x11101ll)	cluster(x11101ll) 	first savefirst savefprefix(${Zname})
			
			
			cap drop SNAPhat_mund
			logit	${endovar}	${IV}	${RHS}	${Mundlak_vars}	 ${reg_weight}	if reg_sample==1 & xtlogit_sample==1, vce(cluster x11101ll) 
			predict	SNAPhat_mund
			
			
			ivreghdfe	${depvar}	${RHS}	${Mundlak_vars}	(${endovar} = SNAPhat_mund)	${reg_weight} if reg_sample==1 & xtlogit_sample==1, cluster(x11101ll) 	first savefirst savefprefix(${Zname})
			
	
	

cap	drop	PFS_FS_ppml
gen	PFS_FS_ppml=PFS_FI_ppml
recode	PFS_FS_ppml	(0=1)	(1=0)


cap	drop	FIG
gen	FIG	=.
replace	FIG=.	if	!mi(PFS_ppml)	&	!inrange(PFS_ppml,0,0.45)
replace	FIG=(0.45 - PFS_ppml)	if	!mi(PFS_ppml)	&	inrange(PFS_ppml,0,0.45)


est clear
global	depvar		FIG	//	PFS_FI_ppml	//	PFS_FS_ppml	//			PFS_ppml	//		

		*	Mundlak controls, all sample
		reghdfe		${depvar}	 FSdummy ${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}		${reg_weight} if	reg_sample_9713==1	${lowincome},	///
			vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
		
		
		
		ivreghdfe	${depvar}	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713} 	(FSdummy = SNAP_index_w)	${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})	partial(*_bar9713)

		
		*	Manual first-stage
		cap	drop	SNAPhat_index
		reg	FSdummy	SNAP_index_w	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}	if	reg_sample_9713==1	${lowincome}, cluster (x11101ll)	
		predict	SNAPhat_index
		
		cap	drop	FSdummy_hat		
		logit	FSdummy	SNAP_index_w	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}	${reg_weight}	if	reg_sample_9713==1	${lowincome}, vce(cluster x11101ll) 
		predict	FSdummy_hat
		lab	var	FSdummy_hat	"Predicted SNAP"
		
		margins, dydx(SNAP_index_w)
		
		summ	SNAPhat_index	FSdummy_hat
		
	
			graph	twoway			(kdensity SNAPhat_index, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) bwidth(0.05) )	///
									(kdensity FSdummy_hat, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) bwidth(0.05) ),	///
									/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(PFS) ytitle(Density)		///
									name(SNAPhat, replace) graphregion(color(white)) bgcolor(white)	title(Predicted SNAP Participation)	///
									legend(lab (1 "OLS") lab(2 "MLE (Logit)") rows(1))	
		graph	export	"${SNAP_outRaw}/SNAPhat.png", replace
		
		ivreghdfe	${depvar}	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713} 	(FSdummy = FSdummy_hat)	${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})	partial(*_bar9713)
							
							
							
							
							
							
							
							
							
							
							
							
							
		*	FE
		*	Mundlak controls, all sample
		reghdfe		${depvar}	 FSdummy ${FSD_on_FS_X}	${timevars}		${reg_weight} if	reg_sample_9713==1	${lowincome},	///
			vce(cluster x11101ll)  absorb(x11101ll)
		
		
		
		ivreghdfe	${depvar}	${FSD_on_FS_X}	${timevars}	(FSdummy = SNAP_index_w)	${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							absorb(x11101ll)	cluster (x11101ll)		first savefirst savefprefix(${Zname})

		
		*	Manual first-stage
		cap	drop	SNAPhat_index
		reghdfe	FSdummy	SNAP_index_w	${FSD_on_FS_X}	${timevars}		if	reg_sample_9713==1	${lowincome}, cluster(x11101ll)	 absorb(x11101ll)
		predict	SNAPhat_index
		
		
		
		cap	drop	FSdummy_hat		
		xtlogit	FSdummy	SNAP_index_w	${FSD_on_FS_X}	${timevars}	  if	reg_sample_9713==1, vce(cluster x11101ll) 
		predict	FSdummy_hat, pr
		lab	var	FSdummy_hat	"Predicted SNAP"
		
		margins, dydx(SNAP_index_w)
		
		graph	twoway	(kdensity	SNAPhat_index)	(kdensity	FSdummy_hat)
		
		summ	SNAPhat_index	FSdummy_hat
		
		ivreghdfe	${depvar}	${FSD_on_FS_X}	${timevars}		(FSdummy = FSdummy_hat)	${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							absorb(x11101ll)	cluster (x11101ll)		first savefirst savefprefix(${Zname})