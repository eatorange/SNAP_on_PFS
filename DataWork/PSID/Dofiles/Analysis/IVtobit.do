
*	Tobit (cencored from 0 to 1)

	*	(1) Bivariate
		
		global	RHS		//	Null
		cap	drop	${endovar}_hat
		logit	${endovar}		${IV}	 ${RHS} 	${reg_weight}	${lowincome}, vce(cluster x11101ll) 
		predict	${endovar}_hat
		lab	var	${endovar}_hat	"Predicted SNAP"	
			
		ivtobit	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, 	ll(0) ul(1) vce (cluster x11101ll)	
		margins, dydx(FSdummy) post
		est store tobit_biv
		
		
		global	RHS	${FSD_on_FS_X}	//	Null
		cap	drop	${endovar}_hat
		logit	${endovar}		${IV}	${RHS} 	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
		predict	${endovar}_hat
		lab	var	${endovar}_hat	"Predicted SNAP"	
			
		ivtobit	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, 	ll(0) ul(1) vce (cluster x11101ll)	
		margins, dydx(FSdummy) post
		est store tobit_ctrl
		
		
		
		global	RHS	${FSD_on_FS_X}	${timevars}	//	Null
		cap	drop	${endovar}_hat
		logit	${endovar}		${IV}	${RHS} 	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
		predict	${endovar}_hat
		lab	var	${endovar}_hat	"Predicted SNAP"	
			
		ivtobit	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, 	ll(0) ul(1) vce (cluster x11101ll)	
		margins, dydx(FSdummy) post
		est store tobit_timeFE
		
		
		
		global	RHS	${FSD_on_FS_X}	${timevars}	${Mundlak_vars}	//	Null
		cap	drop	${endovar}_hat
		logit	${endovar}		${IV}	${RHS} 	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
		predict	${endovar}_hat
		lab	var	${endovar}_hat	"Predicted SNAP"	
			
		ivtobit	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, 	ll(0) ul(1) vce (cluster x11101ll)	
		margins, dydx(FSdummy) post
		est store tobit_mund
		
		
		
			esttab	tobit_biv tobit_ctrl	tobit_timeFE	tobit_mund		using "${SNAP_outRaw}/PFS_tobit_20231014.csv", ///
				mgroups("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV", pattern(1 1 1 1 1 1 1 1))	///
					cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_PFS Controls YearFE Mundlak, fmt(0 2) label("N" "R$^2$" "Mean PFS" "Controls" "Year FE" "Mundlak" )) ///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy)	///
					title(PFS on FS dummy)		replace	
					