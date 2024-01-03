*	Check equivalnce between CRE (Mundlak) and FE
*	Note that xtlogit drops observations which as within-zero variation in dependent variable.

	*	Tag observations with zero within-variance in SNAP status
	global	RHS	${FSD_on_FS_X}	${timevars}	//	Excluding Mundlak
	
	cap drop xtlogit_sample
	cap	drop	SNAPhat_xtlogit
	xtlogit	${endovar}	${IV}	${RHS}	 if reg_sample==1, fe
	gen xtlogit_sample=1 if e(sample)
	predict SNAPhat_xtlogit
	
	*	Compare CRE and FE
	
		*	OLS naive regression (PFS on SNAP)
		
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
			reghdfe		${endovar}	${IV}	${RHS}	${Mundlak_vars}		 ${reg_weight} if reg_sample==1, cluster(x11101ll)	//  CRE, including zero whtin-variation
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