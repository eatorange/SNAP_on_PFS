	
	
	*	Plot SNAP effects of FI dummy, by cutoff values
	forval	cutoff=0.1(0.1)0.9	{
	
		*local	cutoff=0.2
		cap	drop	PFS_FI_ppml
		gen		PFS_FI_ppml=.
		replace	PFS_FI_ppml=0	if	!mi(PFS_ppml)	&	inrange(PFS_ppml,`cutoff',1)
		replace	PFS_FI_ppml=1	if	!mi(PFS_ppml)	&	inrange(PFS_ppml,0,`cutoff')
		
		global	depvar	PFS_FI_ppml
		global	Z	SNAP_index_w
		
	/*
		*	MLE
		cap	drop	FSdummy_hat
		logit	FSdummy	${IV}	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713} 	${reg_weight}	if	reg_sample_9713==1	${lowincome}, vce(cluster x11101ll) 
		predict	FSdummy_hat
		
		
	*/
		
		loc	cutoff_10	=	ceil(`cutoff'*10)
		di	"cutoff_10 is `cutoff_10'"
		
		*	IV
		ivregress 2sls ${depvar}	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}  	(FSdummy = ${Z})	${reg_weight} if	reg_sample_9713==1	${lowincome},	cluster(x11101ll) first  //	partial(*_bar9713)
		est	store	PFS_FI_`cutoff_10'	
	
	}
		
		
		*	Coefplot of SNAP effects on FI by different cutoff values
				coefplot 	(PFS_FI_1, aseq("0.1")) (PFS_FI_2, aseq("0.2"))	(PFS_FI_3, aseq("0.3")) (PFS_FI_4, aseq("0.4")) (PFS_FI_5, aseq("0.5")) ///
							(PFS_FI_6, aseq("0.6")) (PFS_FI_7, aseq("0.7")) (PFS_FI_8, aseq("0.8")) (PFS_FI_9, aseq("0.9")) , 	keep(FSdummy) byopts(compact cols(1)) vertical swapnames 	///
				 legend(off)  title(SNAP effects on FI by different cutoffs) xtitle(cutoff value) ytitle(coefficient)
				graph	export	"${SNAP_outRaw}/SNAP_on_FI_Z_cutoffs.png", as(png) replace
				

	
	*	Recover cutoff to the original value.
	local	cutoff=0.45
	cap	drop	PFS_FI_ppml
	gen		PFS_FI_ppml=.
	replace	PFS_FI_ppml=0	if	!mi(PFS_ppml)	&	inrange(PFS_ppml,`cutoff',1)
	replace	PFS_FI_ppml=1	if	!mi(PFS_ppml)	&	inrange(PFS_ppml,0,`cutoff')
	lab	var	PFS_FI_ppml	"FI (PFS < `cutoff')"
	
	
	*	Control variable specification
	global	indvars			/*ind_female*/ age_ind	age_ind_sq /*ind_NoHS ind_somecol*/ ind_col /* ind_employed_dummy*/
	global	demovars		rp_female	rp_age  rp_age_sq 	rp_nonWhte	rp_married	
	global	econvars		ln_fam_income_pc_real	
	global	healthvars		rp_disabled
	global	familyvars		//	ratio_child	famnum	change_RP	//  
	global	empvars			rp_employed
	global	eduvars			/*rp_NoHS rp_somecol*/ rp_col
	//global	foodvars		FS_rec_wth
	*global	macrovars		unemp_rate	CPI
	*global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
	*global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1978) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
	global	timevars		year_enum20-year_enum27	//	Using year_enum19 (1997) as a base year, when regressing with SNAP index IV (1996-2013)


	global	FSD_on_FS_X		 ${indvars}	//	${eduvars}	//	${empvars}		//	${healthvars}	//	${demovars} 	 ${econvars}	${familyvars}		 ${regionvars}	${macrovars} 	With individual controls.		
	
	
	*	RHS
	global	RHS	 	famnum	// ${FSD_on_FS_X}	// ${timevars} ${Mundlak_vars_9713} //    // 
	
	
	reg	PFS_ppml	FSdummy	if	reg_sample_9713==1	${lowincome},	cluster(x11101ll)
	
	*	MLE
	cap	drop	FSdummy_hat
	logit	FSdummy	SNAP_index_w	${RHS} 	${reg_weight}	if	reg_sample_9713==1	${lowincome}, vce(cluster x11101ll) 
	predict	FSdummy_hat

	foreach	depvar	in	PFS_ppml	PFS_FI_ppml	{
		
		foreach	Z	in	FSdummy_hat	SNAP_index_w	{
			
		
			ivreghdfe	`depvar'	  ${RHS} 	(FSdummy = `Z')	${reg_weight} if	reg_sample_9713==1	${lowincome},	cluster(x11101ll) first savefirst savefprefix(${Zname}) //	partial(*_bar9713)
			est	store	`depvar'_`Z'
		}
		
	}
	
	
	esttab	PFS_ppml_FSdummy_hat	PFS_ppml_SNAP_index_w	PFS_FI_ppml_FSdummy_hat	PFS_FI_ppml_SNAP_index_w
	
	esttab	PFS_ppml_FSdummy_hat	PFS_ppml_SNAP_index_w	PFS_FI_ppml_FSdummy_hat	PFS_FI_ppml_SNAP_index_w	using "${SNAP_outRaw}/FI_diagnosis.csv", ///
							cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N, fmt(0 2) label("N" )) ///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy)	///
							title(SNAP on PFS)		replace				
	

	
	
	
	
	
	
	
	
	
	global	depvar	PFS_ppml // PFS_FI_ppml
	global	Z	FSdummy_hat	//SNAP_index_w		//	

	ivreghdfe	${depvar}	/*  ${FSD_on_FS_X} 	 ${timevars}	${Mundlak_vars_9713}  */ 	(FSdummy = ${Z})	${reg_weight} if	reg_sample_9713==1	${lowincome},	cluster(x11101ll) first savefirst savefprefix(${Zname}) //	partial(*_bar9713)
	
	
	
	
	
	*	Manual first stage
	cap	drop	SNAPhathat
	reg	FSdummy	FSdummy_hat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713} 	${reg_weight}	if	reg_sample_9713==1	${lowincome}, vce(cluster x11101ll) 
	predict SNAPhathat
	
	*	Manual 2nd stage
	regress	${depvar}	SNAPhathat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}   ${reg_weight} if	reg_sample_9713==1	${lowincome}, cluster(x11101ll) 
	*reghdfe	${depvar}	SNAPhathat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}   ${reg_weight} if	reg_sample_9713==1	${lowincome}, cluster(x11101ll) noabsorb
	
	
	
	bsqreg ${depvar}	SNAPhathat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}  /*  ${reg_weight} */ if	reg_sample_9713==1	${lowincome}