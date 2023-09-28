	
	
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
	
	global	depvar	PFS_FI_ppml
	global	Z	SNAP_index_w	//	FSdummy_hat	//	

	ivreghdfe	${depvar}	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}  	(FSdummy = ${Z})	${reg_weight} if	reg_sample_9713==1	${lowincome},	cluster(x11101ll) first savefirst savefprefix(${Zname}) //	partial(*_bar9713)
	
	
	
	
	
	*	Manual first stage
	cap	drop	SNAPhathat
	reg	FSdummy	FSdummy_hat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713} 	${reg_weight}	if	reg_sample_9713==1	${lowincome}, vce(cluster x11101ll) 
	predict SNAPhathat
	
	*	Manual 2nd stage
	regress	${depvar}	SNAPhathat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}   ${reg_weight} if	reg_sample_9713==1	${lowincome}, cluster(x11101ll) 
	*reghdfe	${depvar}	SNAPhathat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}   ${reg_weight} if	reg_sample_9713==1	${lowincome}, cluster(x11101ll) noabsorb
	
	
	
	bsqreg ${depvar}	SNAPhathat	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars_9713}  /*  ${reg_weight} */ if	reg_sample_9713==1	${lowincome}