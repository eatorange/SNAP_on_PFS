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