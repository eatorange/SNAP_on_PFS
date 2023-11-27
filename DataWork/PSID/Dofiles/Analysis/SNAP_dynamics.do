cap	drop	l2_SNAP_index_w
gen	l2_SNAP_index_w=l2.SNAP_index_w

*	

*	Controls and time FE, Mundlak
ivreghdfe	PFS_ppml	l2_PFS_ppml	   ${FSD_on_FS_X_l2}	 	${timevars}		${Mundlak_vars}    	///
	(l2_${endovar}	l0_${endovar} = 	l2_SNAP_index_w	SNAP_index_w)	${reg_weight}  if reg_sample==1, ///
	/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	
	
	
	*	Controls and time FE, Mundlak
ivreghdfe	PFS_ppml		   ${RHS}	 (${endovar}	 = 		SNAP_index_w)	${reg_weight}  if reg_sample==1, ///
	/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	
	
	
	
	
*	Controls and time FE, Mundlak
ivreghdfe	PFS_ppml	  ${RHS}	   	///
	(l0_${endovar} = 	l0_SNAPhat)	${reg_weight}  if reg_sample==1, ///
	/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	
	
	
ivreghdfe	PFS_ppml	l2_PFS_ppml	  ${RHS}	   	///
	(l0_${endovar} = 	l0_SNAPhat)	${reg_weight}  if reg_sample==1, ///
	/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	
	
	
	
	
ivreghdfe	PFS_ppml	 ${RHS} 	 	///
	(l0_${endovar} = 	l0_SNAPhat)	${reg_weight}  if reg_sample==1, ///
	/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	
	
	
	
	
	
	
	
	
	
	
	
					
			*	IV 
			
				*	Non-linear
				cap	drop	l0_${endovar}_hat
				
				logit	l0_${endovar}	/* l2_PFS_ppml */	l2_SNAP_index_w l0_SNAP_index_w	${FSD_on_FS_X_l2}		${timevars}		${Mundlak_vars}  ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
				predict	l0_${endovar}_hat
				lab	var	l0_${endovar}_hat	"Predicted SNAP in t"		
				
				cap	drop	l2_${endovar}_hat
				logit	l2_${endovar}	/* l2_PFS_ppml */	l2_SNAP_index_w l0_SNAP_index_w	${FSD_on_FS_X_l2}		${timevars}		${Mundlak_vars}  ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
				predict	l2_${endovar}_hat
				lab	var	l2_${endovar}_hat	"Predicted SNAP in t-2"		
				
				
				ivreghdfe	PFS_ppml	l2_PFS_ppml		${FSD_on_FS_X_l2}		${timevars}	${Mundlak_vars}	(l2_${endovar}  l0_${endovar} 	=	l2_${endovar}_hat	 l0_${endovar}_hat )	${reg_weight} if reg_sample==1, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})
				
/*
				margins, dydx(SNAP_index_w) post
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				scalar	Fstat_KP_${Zname}	=	e(widstat)
				summ	${endovar}	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_SNAP	=	 r(mean)
				est	store	logit_SPI_mund
*/