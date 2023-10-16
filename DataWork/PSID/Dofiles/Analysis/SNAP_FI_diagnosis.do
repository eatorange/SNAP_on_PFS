	
	
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
	global	indvars			/*ind_female*/ age_ind	age_ind_sq /*ind_NoHS ind_somecol*//*  ind_col */ /* ind_employed_dummy*/
	global	demovars		rp_female	rp_age  rp_age_sq 	rp_nonWhte	rp_married	
	global	econvars		ln_fam_income_pc_real	
	global	healthvars		rp_disabled
	global	familyvars		change_RP	//	ratio_child	famnum		//  
	global	empvars			rp_employed
	global	eduvars			/*rp_NoHS rp_somecol*/ rp_col
	//global	foodvars		FS_rec_wth
	*global	macrovars		unemp_rate	CPI
	*global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
	*global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1978) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
	global	timevars		year_enum20-year_enum27	//	Using year_enum19 (1997) as a base year, when regressing with SNAP index IV (1996-2013)


	global	FSD_on_FS_X		${demovars}  ${healthvars}	/* 	${familyvars}	 */	/* ${empvars} */	${eduvars}	//			//		 ${econvars}		${indvars}	 ${regionvars}	${macrovars} 	With individual controls.		
	
	
	*	RHS
	global	RHS	 ${FSD_on_FS_X}	//	// ${timevars} ${Mundlak_vars_9713} //    // 
	
	
	*reg	PFS_ppml	FSdummy	if	reg_sample_9713==1	${lowincome},	cluster(x11101ll)
	

						
	*	Benchmark specification: weight-adjusted, clustered at individual-level
	**	From the codes below, we find individual FE captures huge variations.
	global	depvar	PFS_ppml
	local	income_below130=0
	
	if	`income_below130'==1	{
		
		global	lowincome	if	income_ever_below_130_9713==1	//	Add condition for low-income population.
		*keep if income_ever_below_130_9713==1
	}
	else	{
		
		global	lowincome	//	null macro
		
	}
	
	di	"${lowincome}"
	

	
		*	Bivariate
			
			*	No time FE
			reg		${depvar}	FSdummy ${reg_weight} ${lowincome}, cluster(x11101ll)	//	OLS
			
			ivreghdfe	${depvar}	(FSdummy = SNAP_index_w)	${reg_weight} ${lowincome}, 	cluster(x11101ll)	 first savefirst savefprefix(${Zname})	//	IV-SPI
			
			cap	drop	FSdummy_hat
			logit	FSdummy	SNAP_index_w	${reg_weight} ${lowincome}, vce(cluster x11101ll) 
			predict	FSdummy_hat
			ivreghdfe	${depvar}	(FSdummy=FSdummy_hat)	${reg_weight} ${lowincome}, cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SNAPhat
			est	store	IV_SNAPhat_biv_2nd
			
			
			*	Bivariate, with time FE
			reg	${depvar}	FSdummy ${timevars}	${reg_weight} ${lowincome}, cluster(x11101ll) // OLS
			ivreghdfe	${depvar}	 ${timevars} (FSdummy = SNAP_index_w)	${reg_weight} ${lowincome}, 	cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SPI
			cap	drop	FSdummy_hat
			logit	FSdummy	SNAP_index_w  ${timevars}	${reg_weight} ${lowincome}, vce(cluster x11101ll) 
			predict	FSdummy_hat
			ivreghdfe	${depvar}  ${timevars}	(FSdummy=FSdummy_hat)	${reg_weight} ${lowincome}, cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SNAPhat
			
			*	Bivariate, individual FE (no time FE)
			reghdfe	${depvar}	FSdummy  ${reg_weight} ${lowincome}, absorb(x11101ll) cluster(x11101ll) // OLS
			ivreghdfe	${depvar}	(FSdummy = SNAP_index_w)	${reg_weight} ${lowincome}, 	absorb(x11101ll) cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SPI
			cap	drop	FSdummy_hat
			xtlogit	FSdummy	SNAP_index_w ${lowincome}, fe
			predict	FSdummy_hat
			ivreghdfe	${depvar}	(FSdummy=FSdummy_hat)	${reg_weight} ${lowincome}, absorb(x11101ll) cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SNAPhat
		
			*	Bivariate, individual FE (with time FE)
			reghdfe	${depvar}	FSdummy  ${timevars} ${reg_weight} ${lowincome}, absorb(x11101ll) cluster(x11101ll)
			ivreghdfe	${depvar}	${timevars}	(FSdummy = SNAP_index_w)	${reg_weight} ${lowincome}, absorb(x11101ll)	cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SPI
			cap	drop	FSdummy_hat
			xtlogit	FSdummy	SNAP_index_w ${timevars}	${lowincome}, fe
			predict	FSdummy_hat
			ivreghdfe	${depvar}	${timevars}	(FSdummy=FSdummy_hat)	${reg_weight} ${lowincome}, absorb(x11101ll)	cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SNAPhat
			
			
		*	Adding controls  (always with time FE)
		*	Demogrphy, education and health (no employment and incomde)
		global	RHS	 ${demovars} ${healthvars}	${eduvars} ${timevars}
		
	
		
			*	Mundlak var of regressors, including time dummy					
		foreach	samp	in	/*all*/ 9713	{
		
			*	All sample
			cap	drop	*_bar`samp'
			
			
			*	W/o individual controls (default)
			ds	${RHS} 
			foreach	var	in	`r(varlist)'	{
				bys	x11101ll:	egen	`var'_bar`samp'	=	mean(`var')	if	reg_sample_`samp'==1	
			}
			qui	ds	*_bar`samp'
			global	Mundlak_vars_`samp'	`r(varlist)'
			
		
		
		}
				
			*	No FE/no Mundlak
			reg	${depvar}	FSdummy ${RHS} ${reg_weight}  ${lowincome}, cluster(x11101ll)

			*	Mundlak
			reg	${depvar}	FSdummy ${RHS} ${Mundlak_vars_9713}	${reg_weight}  ${lowincome}, cluster(x11101ll)
			
			*	FE
			reghdfe	${depvar}	FSdummy  ${RHS}  ${reg_weight}  ${lowincome}, absorb(x11101ll) cluster(x11101ll)
		

		*	Repeat selected models using IV
		*	model specification: Controls, weighte adjusted
			
			*	No FE/Mundlak
			ivreghdfe	${depvar}	${RHS}	(FSdummy = SNAP_index_w)	${reg_weight}  ${lowincome}, 	cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SPI
			
			cap	drop	FSdummy_hat
			logit	FSdummy	SNAP_index_w	${RHS}	${reg_weight}  ${lowincome}, vce(cluster x11101ll) 
			predict	FSdummy_hat
			ivreghdfe	${depvar}	${RHS}	(FSdummy=FSdummy_hat)	${reg_weight}  ${lowincome}, cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SNAPhat
			
			*	Mundlak
			ivreghdfe	${depvar}	${RHS}	${Mundlak_vars_9713}	(FSdummy = SNAP_index_w)	${reg_weight}  ${lowincome}, 	cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SPI
			
			cap	drop	FSdummy_hat_lin
			reg	FSdummy	SNAP_index_w	${RHS}	${Mundlak_vars_9713} ${reg_weight}  ${lowincome}, vce(cluster x11101ll) 
			predict	FSdummy_hat_lin
			
			cap	drop	FSdummy_hat
			logit	FSdummy	SNAP_index_w	${RHS}	${Mundlak_vars_9713} ${reg_weight}  ${lowincome}, vce(cluster x11101ll) 
			predict	FSdummy_hat
			ivreghdfe	${depvar}	${RHS}	${Mundlak_vars_9713}	(FSdummy=FSdummy_hat)	${reg_weight}  ${lowincome}, cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SNAPhat
			
			ivreghdfe	${depvar}	${RHS}	${Mundlak_vars_9713}	(FSdummy=FSdummy_hat)	${reg_weight} if income_ever_below_130_9713==1, cluster(x11101ll)	first savefirst savefprefix(${Zname}) partial(*_bar9713) //	IV-SNAPhat
			
			
			
			*	FE
			ivreghdfe	${depvar}	${RHS}	(FSdummy = SNAP_index_w)	${reg_weight}  ${lowincome}, 	absorb(x11101ll) cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SPI
			
			
			cap	drop	FSdummy_hat
			xtlogit	FSdummy	SNAP_index_w	${RHS}  ${lowincome}, fe	// Does not allow weight, so have to use unweighted.
			predict	FSdummy_hat
			ivreghdfe	${depvar}	${RHS}	(FSdummy = FSdummy_hat)	${reg_weight}  ${lowincome}, 	absorb(x11101ll) cluster(x11101ll)	first savefirst savefprefix(${Zname})	//	IV-SNAPhat
			
	

	
	
	*	MLE
	cap	drop	FSdummy_hat
	logit	FSdummy	SNAP_index_w	${RHS} 	  ${timevars} ${Mundlak_vars_9713} ${reg_weight}	if	reg_sample_9713==1	${lowincome}, vce(cluster x11101ll) 
	predict	FSdummy_hat
	
	cap	drop	FSdummy_hat_Z
	reg		FSdummy SNAP_index_w	${RHS}		 ${timevars} ${Mundlak_vars_9713}  ${reg_weight}	if	reg_sample_9713==1	${lowincome}, vce(cluster x11101ll) 
	predict	FSdummy_hat_Z
	
	summ	FSdummy_hat	FSdummy_hat_Z
	

	foreach	depvar	in	PFS_ppml	PFS_FI_ppml	{
		
		foreach	Z	in	FSdummy_hat	SNAP_index_w	{
			
		
			ivreghdfe	`depvar'	  ${RHS} 	 ${timevars} ${Mundlak_vars_9713} 	(FSdummy = `Z')	${reg_weight} if	reg_sample_9713==1	${lowincome},	cluster(x11101ll) first savefirst savefprefix(${Zname}) partial(*_bar9713)
			est	store	`depvar'_`Z'
		}
		
	}
	
	
	esttab	PFS_ppml_FSdummy_hat	PFS_ppml_SNAP_index_w	PFS_FI_ppml_FSdummy_hat	PFS_FI_ppml_SNAP_index_w //, keep(FSdummy ${RHS})
	
	
/*
	esttab	PFS_ppml_FSdummy_hat	PFS_ppml_SNAP_index_w	PFS_FI_ppml_FSdummy_hat	PFS_FI_ppml_SNAP_index_w	using "${SNAP_outRaw}/FI_diagnosis.csv", ///
							cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N, fmt(0 2) label("N" )) ///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy)	///
							title(SNAP on PFS)		replace				
	
*/

	
	*	(2023-10-14) We do 4 specification
		
		*	1. Bivariate
		
	
	
	
	
	
	
	
	
	
	
	*	Manual first stage
	cap	drop	SNAPhathat
	reg	FSdummy	FSdummy_hat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713} 	${reg_weight}	if	reg_sample_9713==1	${lowincome}, vce(cluster x11101ll) 
	predict SNAPhathat
	
	*	Manual 2nd stage
	regress	${depvar}	SNAPhathat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}   ${reg_weight} if	reg_sample_9713==1	${lowincome}, cluster(x11101ll) 
	*reghdfe	${depvar}	SNAPhathat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}   ${reg_weight} if	reg_sample_9713==1	${lowincome}, cluster(x11101ll) noabsorb
	
	
	
	bsqreg ${depvar}	SNAPhathat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}  /*  ${reg_weight} */ if	reg_sample_9713==1	${lowincome}