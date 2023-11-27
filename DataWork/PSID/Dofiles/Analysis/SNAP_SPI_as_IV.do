	local	income_below130=0
	
	if	`income_below130'==1	{
		
		global	lowincome	if	income_ever_below_130_9713==1	//	Add condition for low-income population.
		global	samplename	lowinc
	}
	else	{
		
		global	lowincome	//	null macro
		global	samplename	full
		
	}
	
	di	"${lowincome}"
	
		
	*	Mundlak var of regressors, including time dummy	
	*	Use only the observations with complete information (or the same sample FE estimator is constructed)
	cap	drop	reg_sample
	reghdfe	${depvar}	${FSD_on_FS_X}	${timevars}	${reg_weight}	${lowincome}, cluster(x11101ll) absorb(x11101ll)
	gen	reg_sample=1	if	e(sample)
	
			ds	${FSD_on_FS_X} ${timevars}
			foreach	var	in	`r(varlist)'	{
				cap	drop	`var'_bar
				bys	x11101ll:	egen	`var'_bar	=	mean(`var') if reg_sample==1
			}
			qui	ds	*_bar
			global	Mundlak_vars	`r(varlist)'
			
			di	"${Mundlak_vars}"
		
	
	
	
	
	*	Directly using SPI as an IV
	
		local	RHS1
		local	RHS2	${FSD_on_FS_X}	 	${timevars}		${Mundlak_vars}
		
		*	PFS
		foreach	depvar	in	PFS_ppml	PFS_FI_ppml	{
		    
			foreach	RHS	in	RHS1	RHS2	{
			    
				ivreghdfe	`depvar'	``RHS''	(FSdummy = SNAP_index_w)	${reg_weight} if reg_sample==1, 	cluster (x11101ll)		first // savefirst savefprefix(${Zname})
				
				if	"`RHS'"=="RHS1"	{
					estadd	local	Controls	"N"
				}
				else	{
					estadd	local	Controls	"Y"
				}
				estadd	scalar	Fstat_CD	=	 e(cdf), replace
				estadd	scalar	Fstat_KP	=	e(widstat), replace
				summ	`depvar'	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	`depvar'_`RHS'
				
			}
			
		}
		
		
		esttab	PFS_ppml_RHS1	PFS_ppml_RHS2	PFS_FI_ppml_RHS1	PFS_FI_ppml_RHS2 using "${SNAP_outRaw}/PFS_SPI_2023112.csv", ///
			cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_PFS Controls Fstat_CD	Fstat_KP, fmt(0 2) label("N" "R2" "Mean SNAP" "Controls"  "F-stat(CD)" "F-stat(KP)" )) ///
			incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy)	///
			title(PFS on FS dummy)		replace	
		
		esttab	PFS_ppml_RHS1	PFS_ppml_RHS2	PFS_FI_ppml_RHS1	PFS_FI_ppml_RHS2		using "${SNAP_outRaw}/PFS_SPI_2023112.tex", ///
				cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c	mean_PFS Controls Fstat_KP, fmt(0 2) label("N" "R$^2$" "Mean SNAP" "Controls"  "F-stat(KP)" )) ///
				incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy )	///
				title(SNAP on SPI)	note(Controls include RP’s characteristics (gender, age, age squared race, marital status, disability and college degree). Mundlak includes time-average of controls and year fixed effects. Estimates are adjusted with longitudinal individual survey weight provided in the PSID. Standard errors are clustered at individual-level.)	replace	
		
		
		
		
		
		
			
		*	Key
		
	cap	drop temp
	logit	FSdummy	SNAP_index_w	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
	predict	temp
	
	fracreg	probit	PFS_ppml	temp	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
	margins, dydx(temp)
	
	
	
	logit	${endovar}		${IV}	${RHS} 	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
	