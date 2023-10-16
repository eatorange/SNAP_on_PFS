
	*	Fractional probit (Requires Stata 18+)
	*	Note: This method requires endogenous X to be continuous, which is NOT the case in this study.
	*	We just run it for robustness check.
		global	RHS	
		global	endovar	FSdummy
		global	IV	SNAP_index_w
		
		
		*	(1) bivariate
		cap	drop	${endovar}_hat
		logit	${endovar}		${IV}	${RHS} 	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
		predict	${endovar}_hat
		
		ivfprobit ${depvar} ${RHS} (${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, vce(cluster x11101ll)
		margins, dydx(FSdummy) post
		est	store	ivfprobit_biv
		
		*	(2) Controls
		global	RHS	${FSD_on_FS_X}
		
		cap	drop	${endovar}_hat
		logit	${endovar}		${IV}	${RHS} 	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
		predict	${endovar}_hat
		
		ivfprobit ${depvar} ${RHS} (${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, vce(cluster x11101ll)
		margins, dydx(FSdummy) post
		est	store	ivfprobit_ctrl
		
		*	(3) Controls and Time FE
		global	RHS	${FSD_on_FS_X}	${timevars}
		
		cap	drop	${endovar}_hat
		logit	${endovar}		${IV}	${RHS} 	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
		predict	${endovar}_hat
		
		ivfprobit ${depvar} ${RHS} (${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, vce(cluster x11101ll)
		margins, dydx(FSdummy) post
		est	store	ivfprobit_timeFE
		
		*	(4) Controls, time FE and Mundlak
		global	RHS	${FSD_on_FS_X}	${timevars}	${Mundlak_vars}
		
		
		cap	drop	${endovar}_hat
		logit	${endovar}		${IV}	${RHS} 	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
		predict	${endovar}_hat
		
		ivfprobit ${depvar} ${RHS} (${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, vce(cluster x11101ll)
		margins, dydx(FSdummy) post
		est	store	ivfprobit_mund
		
		
		esttab	ivfprobit_biv ivfprobit_ctrl	ivfprobit_timeFE	ivfprobit_mund	using "C:\Users\sl3235\Desktop\IVfprobit_lowinc.csv", ///
					cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_PFS Controls YearFE Mundlak, fmt(0 2) label("N" "R$^2$" "Mean PFS" "Controls" "Year FE" "Mundlak" )) ///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy)	///
					title(PFS on FS dummy)		replace	
		
		