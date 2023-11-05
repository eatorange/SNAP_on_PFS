*	This do-file creates regressions for 2023/10/14 draft
*	Once done, it will be imported into SNAP_ivreg.do file

*	Benchmark specification
	*	Weighted
	*	standard error clustered at individual level

	
*	Control variable specification
	global	indvars			/*ind_female*/ age_ind	age_ind_sq /*ind_NoHS ind_somecol*//*  ind_col */ /* ind_employed_dummy*/
	global	demovars		rp_female	rp_age  rp_age_sq 	rp_nonWhte	rp_married	
	global	econvars		ln_fam_income_pc_real	
	global	healthvars		rp_disabled
	global	familyvars		change_RP	//	ratio_child	famnum		//  
	global	empvars			rp_employed
	global	eduvars			/*rp_NoHS rp_somecol*/ rp_col
	global	timevars		year_enum20-year_enum27	//	Using year_enum19 (1997) as a base year, when regressing with SNAP index IV (1996-2013)


	global	FSD_on_FS_X		${demovars}  ${healthvars}	${eduvars}		//		 ${econvars}		${indvars}	 ${regionvars}	${macrovars} 	With individual controls.		

	
	*	Mundlak var of regressors, including time dummy					
			
			ds	${FSD_on_FS_X} ${timevars}
			foreach	var	in	`r(varlist)'	{
				cap	drop	`var'_bar
				bys	x11101ll:	egen	`var'_bar	=	mean(`var')
			}
			qui	ds	*_bar
			global	Mundlak_vars	`r(varlist)'
			
			di	"${Mundlak_vars}"
					
	*	Benchmark specification: weight-adjusted, clustered at individual-level
	global	reg_weight		 [pw=wgt_long_ind]
	global	sum_weight		[aw=wgt_long_ind]
	*global	xtlogit_weight	[iw=wgt_long_ind]
	
	
	*	Preample
	global	depvar		PFS_ppml	// 	PFS_FI_ppml	//		//					
	global	endovar		FSdummy	//	FSamt_capita
	global	IV			SNAP_index_w	//	citi6016	//	inst6017_nom	//	citi6016	//		//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
	global	IVname		SPI_w	//	CIM	//	
	
	
	lab	var	PFS_FI_ppml	"FI (=1)"
	
	global	Z		FSdummy_hat	
	global	Zname	${IVname}_Dhat
	
	*	Specification for sample
	local	income_below130=1
	
	if	`income_below130'==1	{
		
		global	lowincome	if	income_ever_below_130_9713==1	//	Add condition for low-income population.
		global	samplename	lowinc
	}
	else	{
		
		global	lowincome	//	null macro
		global	samplename	full
		
	}
	
	di	"${lowincome}"
	
	
	graph twoway (kdensity	PFS_ppml ${sum_weight} if income_ever_below_130_9713==1) (kdensity	PFS_ppml ${sum_weight}), xline(0.45)
	
	lab	var	FSdummy	"SNAP (=1)"
	
*	4 models
	*	(1) No control, no time FE, no mundlak
	*	(2) control, no time FE, no mundlak
	*	(3) control, time FE, no mundlak
	*	(4) control, time FE, mundlak
	
	*	(1) No control, no time FE, no Mundlak
		
		global	RHS	//	Null
	
	
	
		*	OLS
		reg		${depvar}	FSdummy	${RHS} ${reg_weight} ${lowincome}, cluster(x11101ll)	//	OLS
		estadd	local	Controls	"N"
		estadd	local	YearFE		"N"
		estadd	local	Mundlak		"N"
		estadd	scalar	r2c	=	e(r2)
		summ	PFS_ppml	${sum_weight}				
		estadd	scalar	mean_PFS	=	 r(mean)					
		est	store	OLS_biv			
						
		*	IV 
		
			*	Non-linear
			cap	drop	${endovar}_hat
			logit	${endovar}		${IV}	${RHS} 	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
			predict	${endovar}_hat
			lab	var	${endovar}_hat	"Predicted SNAP"
			*scalar	r2c	=	e(r2_p)
			margins, dydx(SNAP_index_w) post
			*estadd	scalar	r2c	=	r2c
			estadd	local	Controls	"N"
			estadd	local	YearFE		"N"
			estadd	local	Mundlak		"N"
			scalar	Fstat_CD_${Zname}	=	 e(cdf)
			scalar	Fstat_KP_${Zname}	=	e(widstat)
			summ	FSdummy	${sum_weight}	if	e(sample)==1
			estadd	scalar	mean_SNAP	=	 r(mean)
			est	store	logit_SPI_biv		
			
		ivreghdfe	${depvar}	${RHS} 	(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, ///
				/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})
			estadd	local	Controls	"N"
			estadd	local	YearFE		"N"
			estadd	local	Mundlak		"N"
			scalar	Fstat_CD_${Zname}	=	 e(cdf)
			scalar	Fstat_KP_${Zname}	=	e(widstat)
			summ	PFS_ppml	${sum_weight}	if	e(sample)==1
			estadd	scalar	mean_PFS	=	 r(mean)
			est	store	${Zname}_biv_2nd
		
			est	restore	${Zname}${endovar}
			estadd	local	Controls	"N"
			estadd	local	YearFE		"N"
			estadd	local	Mundlak		"N"
			estadd	scalar	Fstat_CD	=	Fstat_CD_${Zname}, replace
			estadd	scalar	Fstat_KP	=	Fstat_KP_${Zname}, replace
			summ	FSdummy	${sum_weight}	if	e(sample)==1
			estadd	scalar	mean_SNAP	=	 r(mean) 
			est	store	${Zname}_biv_1st	
			est	drop	${Zname}${endovar}
			
		
		
		
		*	(2) Control, no time FE, no Mundlak
		global	RHS	${FSD_on_FS_X}
		
			*	OLS
			reg		${depvar}	FSdummy	${RHS}	 ${reg_weight} ${lowincome}, cluster(x11101ll)	//	OLS
			estadd	local	Controls	"Y"
			estadd	local	YearFE		"N"
			estadd	local	Mundlak		"N"
			estadd	scalar	r2c	=	e(r2)
			summ	PFS_ppml	${sum_weight}				
			estadd	scalar	mean_PFS	=	 r(mean)					
			est	store	OLS_ctrl			
							
			*	IV 
			
				*	Non-linear
				cap	drop	${endovar}_hat
				logit	${endovar}		${IV}	${RHS}	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
				predict	${endovar}_hat
				lab	var	${endovar}_hat	"Predicted SNAP"
				margins, dydx(SNAP_index_w) post
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"N"
				estadd	local	Mundlak		"N"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				scalar	Fstat_KP_${Zname}	=	e(widstat)
				summ	FSdummy	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_SNAP	=	 r(mean)
				est	store	logit_SPI_ctrl
				
			ivreghdfe	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"N"
				estadd	local	Mundlak		"N"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				scalar	Fstat_KP_${Zname}	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_ctrl_2nd
			
				est	restore	${Zname}${endovar}
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"N"
				estadd	local	Mundlak		"N"
				estadd	scalar	Fstat_CD	=	Fstat_CD_${Zname}, replace
				estadd	scalar	Fstat_KP	=	Fstat_KP_${Zname}, replace
				summ	FSdummy	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_SNAP	=	 r(mean) 
				est	store	${Zname}_ctrl_1st	
				est	drop	${Zname}${endovar}
		
		
		
			
		*	(3) Control, time FE, no Mundlak
		global	RHS	${FSD_on_FS_X}	${timevars}
		
			*	OLS
			reg		${depvar}	FSdummy 	${RHS}		${reg_weight} ${lowincome}, cluster(x11101ll)	//	OLS
			estadd	local	Controls	"Y"
			estadd	local	YearFE		"Y"
			estadd	local	Mundlak		"N"
			estadd	scalar	r2c	=	e(r2)
			summ	PFS_ppml	${sum_weight}				
			estadd	scalar	mean_PFS	=	 r(mean)					
			est	store	OLS_timeFE			
							
			*	IV 
			
				*	Non-linear
				cap	drop	${endovar}_hat
				logit	${endovar}	${IV}	${RHS}		 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
				predict	${endovar}_hat
				lab	var	${endovar}_hat	"Predicted SNAP"		
				margins, dydx(SNAP_index_w) post
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"N"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				scalar	Fstat_KP_${Zname}	=	e(widstat)
				summ	FSdummy	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_SNAP	=	 r(mean)
				est	store	logit_SPI_timeFE
				
			ivreghdfe	${depvar}	${RHS}		(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"N"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				scalar	Fstat_KP_${Zname}	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_timeFE_2nd
			
				est	restore	${Zname}${endovar}
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"N"
				estadd	scalar	Fstat_CD	=	Fstat_CD_${Zname}, replace
				estadd	scalar	Fstat_KP	=	Fstat_KP_${Zname}, replace
				summ	FSdummy	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_SNAP	=	 r(mean) 
				est	store	${Zname}_timeFE_1st	
				est	drop	${Zname}${endovar}
		
		
		
		*	(4) Control, time FE, Mundlak
		global	RHS	${FSD_on_FS_X}	${timevars}	${Mundlak_vars}
		
			*	OLS
			reg		${depvar}	FSdummy	${RHS}		 ${reg_weight} ${lowincome}, cluster(x11101ll)	//	OLS
			estadd	local	Controls	"Y"
			estadd	local	YearFE		"Y"
			estadd	local	Mundlak		"Y"
			estadd	scalar	r2c	=	e(r2)
			summ	PFS_ppml	${sum_weight}				
			estadd	scalar	mean_PFS	=	 r(mean)					
			est	store	OLS_mund		
							
			*	IV 
			
				*	Non-linear
				cap	drop	${endovar}_hat
				logit	${endovar}	${IV}	${RHS}	 ${reg_weight}	${lowincome}, vce(cluster x11101ll) 
				predict	${endovar}_hat
				lab	var	${endovar}_hat	"Predicted SNAP"		
				margins, dydx(SNAP_index_w) post
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				scalar	Fstat_KP_${Zname}	=	e(widstat)
				summ	FSdummy	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_SNAP	=	 r(mean)
				est	store	logit_SPI_mund
				
			ivreghdfe	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				scalar	Fstat_KP_${Zname}	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_mund_2nd
			
				est	restore	${Zname}${endovar}
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"Y"
				estadd	scalar	Fstat_CD	=	Fstat_CD_${Zname}, replace
				estadd	scalar	Fstat_KP	=	Fstat_KP_${Zname}, replace
				summ	FSdummy	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_SNAP	=	 r(mean) 
				est	store	${Zname}_mund_1st	
				est	drop	${Zname}${endovar}
		
		
		
			*	(5) Control, time FE, individual FE
		global	RHS	${FSD_on_FS_X}	${timevars}	
		
			*	OLS
			reghdfe		${depvar}	FSdummy	${RHS}		 ${reg_weight} ${lowincome}, cluster(x11101ll) absorb(x11101ll)	//	OLS
			estadd	local	Controls	"Y"
			estadd	local	YearFE		"Y"
			estadd	local	Mundlak		"Y"
			estadd	scalar	r2c	=	e(r2)
			summ	PFS_ppml	${sum_weight}				
			estadd	scalar	mean_PFS	=	 r(mean)					
			est	store	OLS_indFE		
							
			*	IV 
			
				*	Non-linear
				cap	drop	${endovar}_hat
				xtlogit	${endovar}	${IV}	${RHS}	 ${lowincome}, fe
				predict	${endovar}_hat
				lab	var	${endovar}_hat	"Predicted SNAP"		
				margins, dydx(SNAP_index_w) post
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				scalar	Fstat_KP_${Zname}	=	e(widstat)
				summ	FSdummy	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_SNAP	=	 r(mean)
				est	store	logit_SPI_indFE
				
			*ivreghdfe	${depvar}	${RHS}	(${endovar} = SNAP_index_w)	${reg_weight} ${lowincome}, absorb(x11101ll)	cluster(x11101ll) //		first savefirst savefprefix(${Zname})
			xtivreg2	${depvar}	${RHS}	(${endovar} = SNAP_index_w)	${reg_weight} ${lowincome}, fe cluster(x11101ll) first	//		 savefirst savefprefix(${Zname})
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				scalar	Fstat_KP_${Zname}	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_mund_2nd
			
				est	restore	${Zname}${endovar}
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"Y"
				estadd	scalar	Fstat_CD	=	Fstat_CD_${Zname}, replace
				estadd	scalar	Fstat_KP	=	Fstat_KP_${Zname}, replace
				summ	FSdummy	${sum_weight}	if	e(sample)==1
				estadd	scalar	mean_SNAP	=	 r(mean) 
				est	store	${Zname}_mund_1st	
				est	drop	${Zname}${endovar}
		
		
		
		
		
		*	1st stage
		esttab	logit_SPI_biv	logit_SPI_ctrl	logit_SPI_timeFE	logit_SPI_mund SPI_w_Dhat_biv_1st 	SPI_w_Dhat_ctrl_1st	SPI_w_Dhat_timeFE_1st	SPI_w_Dhat_mund_1st	using "${SNAP_outRaw}/PFS_1st_20231014.csv", ///
					cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_SNAP Controls YearFE Mundlak	Fstat_CD	Fstat_KP, fmt(0 2) label("N" "R2" "Mean SNAP" "Controls" "Year FE" "Mundlak" "F-stat(CD)" "F-stat(KP)" )) ///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(SNAP_index_w FSdummy_hat)	///
					title(PFS on FS dummy)		replace	
					
		esttab	logit_SPI_biv	logit_SPI_ctrl	logit_SPI_timeFE	logit_SPI_mund	SPI_w_Dhat_biv_1st 	SPI_w_Dhat_ctrl_1st	SPI_w_Dhat_timeFE_1st	SPI_w_Dhat_mund_1st	using "${SNAP_outRaw}/PFS_1st_20231014.tex", ///
				cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N mean_SNAP Controls YearFE Mundlak	Fstat_KP, fmt(0 2) label("N" "Mean SNAP" "Controls" "Year FE" "Mundlak"  "F-stat(KP)" )) ///
				incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(SNAP_index_w FSdummy_hat /*age_ind       ind_col*/)	///
				title(SNAP on SPI)	note(Controls include RP’s characteristics (gender, age, age squared race, marital status, disability college degree). Mundlak includes time-average of controls and year fixed effects. Estimates are adjusted with longitudinal individual survey weight provided in the PSID. Standard errors are clustered at individual-level.)	replace	

				
		*	2nd stage
		esttab	OLS_biv SPI_w_Dhat_biv_2nd	OLS_ctrl	SPI_w_Dhat_ctrl_2nd	OLS_timeFE	SPI_w_Dhat_timeFE_2nd	OLS_mund	 SPI_w_Dhat_mund_2nd	using "${SNAP_outRaw}/PFS_2nd_20231014.csv", ///
				mgroups("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV", pattern(1 1 1 1 1 1 1 1))	///
					cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_PFS Controls YearFE Mundlak, fmt(0 2) label("N" "R$^2$" "Mean PFS" "Controls" "Year FE" "Mundlak" )) ///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy)	///
					title(PFS on FS dummy)		replace	
					
		esttab	OLS_biv SPI_w_Dhat_biv_2nd	OLS_ctrl	SPI_w_Dhat_ctrl_2nd	OLS_timeFE	SPI_w_Dhat_timeFE_2nd	OLS_mund	 SPI_w_Dhat_mund_2nd	using "${SNAP_outRaw}/PFS_2nd_20231014.tex", ///
				mgroups("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV", pattern(1 1 1 1 1 1 1 1))	///
					cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_PFS Controls YearFE Mundlak, fmt(0 2) label("N" "R$^2$" "Mean PFS" "Controls" "Year FE" "Mundlak" )) ///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy)	///
					title(PFS on FS dummy)		replace	
		
		
		
		
		
			*	Heterogeneous effects
			global	RHS	${FSD_on_FS_X}	${timevars}	${Mundlak_vars}
			
			
				*	Create interaction terms of sub-catgories and endogenous SNAP participation (and predicted SNAP)
				foreach	var	in	female	NoHS	nonWhte		disabled	{
					
					cap	drop	SNAP_`var'
					gen		SNAP_`var'	=	FS_rec_wth	*	rp_`var'
					
					cap	drop	SNAPhat_`var'
					gen		SNAPhat_`var'	=	FSdummy_hat	*	rp_`var'
					
				}
				
				lab	var	SNAP_female		"SNAP x Female (RP)"
				lab	var	SNAP_NoHS		"SNAP x No High School diploma (RP)"
				lab	var	SNAP_nonWhte	"SNAP x Non-White (RP)"
				lab	var	SNAP_disabled	"SNAP x Disabled (RP)"
				
				
				lab	var	SNAPhat_female		"Predicted SNAP x Female (RP)"
				lab	var	SNAPhat_NoHS		"Predicted SNAP x No High School diploma (RP)"
				lab	var	SNAPhat_nonWhte		"Predicted SNAP x Non-White (RP)"
				lab	var	SNAPhat_disabled	"Predicted SNAP x Disabled (RP)"
				
		
				*	Run regression for each heterogenous category
				
									
					*	Female	
						ivreghdfe	PFS_ppml	${RHS}		(FSdummy SNAP_female	= FSdummy_hat	SNAPhat_female)	${reg_weight} ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(female)  // partial(*_bar9713)
						estadd	local	Controls	"Y"
						estadd	local	YearFE		"Y"
						estadd	local	Mundlak		"Y"
						local	Fstat_KP: di % 9.2f e(widstat)
						estadd	local	Fstat_KP	=	`Fstat_KP'
						summ	PFS_ppml	${sum_weight} ${lowincome}
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	hetero_2nd_female
						
	
					*	NoHS	
						ivreghdfe	PFS_ppml	${RHS}		(FSdummy SNAP_NoHS	= FSdummy_hat	SNAPhat_NoHS)	${reg_weight}	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(NoHS)	// partial(*_bar9713)
						estadd	local	Controls	"Y"
						estadd	local	YearFE		"Y"
						estadd	local	Mundlak		"Y"
						local	Fstat_KP: di % 9.2f e(widstat)
						estadd	local	Fstat_KP	=	`Fstat_KP'
						summ	PFS_ppml	${sum_weight}	${lowincome}
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	hetero_2nd_NoHS
					
					*	NonWhte	
						ivreghdfe	PFS_ppml	${RHS}	 	(FSdummy SNAP_nonWhte	= FSdummy_hat	SNAPhat_nonWhte)	${reg_weight} 	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(nonWhte)	// partial(*_bar9713)
						estadd	local	Controls	"Y"
						estadd	local	YearFE		"Y"
						estadd	local	Mundlak		"Y"
						local	Fstat_KP: di % 9.2f e(widstat)
						estadd	local	Fstat_KP	=	`Fstat_KP'
						summ	PFS_ppml	${sum_weight} ${lowincome}
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	hetero_2nd_nonWhte
						
					*	Disabled	
						ivreghdfe	PFS_ppml	${RHS}	 	(FSdummy SNAP_disabled	= FSdummy_hat	SNAPhat_disabled)	${reg_weight} 	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(disab)	// partial(*_bar9713)
						estadd	local	Controls	"Y"
						estadd	local	YearFE		"Y"
						estadd	local	Mundlak		"Y"
						local	Fstat_KP: di % 9.2f e(widstat)
						estadd	local	Fstat_KP	=	`Fstat_KP'
						summ	PFS_ppml	${sum_weight} ${lowincome}
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	hetero_2nd_disab
						
					*	Export
					esttab	hetero_2nd_female 	hetero_2nd_NoHS  	hetero_2nd_nonWhte	hetero_2nd_disab		using "${SNAP_outRaw}/PFS_on_SNAP_hetero.csv", ///
					cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2c mean_PFS /* Controls YearFE Mundlak*/ Fstat_KP , fmt(0 2) label("N" "R$^2$" "Mean PFS" /* "Controls" "Year FE" "Mundlak" */ "F-stat(KP)"))	///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy SNAP_female	SNAP_NoHS	SNAP_nonWhte	SNAP_disabled) ///
					title(PFS on FS dummy hetero)		replace	
					
					esttab	hetero_2nd_female 	hetero_2nd_NoHS  	hetero_2nd_nonWhte	hetero_2nd_disab		using "${SNAP_outRaw}/PFS_on_SNAP_hetero.tex", ///
					cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_PFS /* Controls YearFE Mundlak  */ Fstat_KP, fmt(0 2) label("N" "R$^2$" "Mean PFS" /* "Controls" "Year FE" "Mundlak" */ "F-stat(KP)"))	///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy SNAP_female	SNAP_NoHS	SNAP_nonWhte	SNAP_disabled) ///
					title(PFS on SNAP - heterogeneous effects)	note(Note: Controls (RP's gender, age, age squared race, marital status, disability college degree), year FE and Mundlak controls are included in all specifications. Estimates are adjusted with longitudinal individual survey weight provided in the PSID. Standard errors are clustered at individual-level.)	replace	
			
			
			
		*	Dynamics
				
			
				cap	drop	l2_FSdummy
				cap	drop	l4_FSdummy
				cap	drop	l6_FSdummy
				cap	drop	l8_FSdummy
				
				gen	l2_FSdummy	=	l2.FSdummy
				gen	l4_FSdummy	=	l4.FSdummy
				gen	l6_FSdummy	=	l6.FSdummy
				gen	l8_FSdummy	=	l8.FSdummy
				lab	var	l2_FSdummy	"SNAP 2 years ago"
				lab	var	l4_FSdummy	"SNAP 4 years ago"
				lab	var	l6_FSdummy	"SNAP 6 years ago"
				lab	var	l8_FSdummy	"SNAP 8 years ago"
				
				*	Controls
				*	Reset macros		
				global	FSD_on_FS_X_l4l2l0	//	Controls in l0, l2 and l4
				global	FSD_on_FS_X_l4l2	//	Controls in l2 and l4
				global	FSD_on_FS_X_l2		//	Controls in l2
				global	FSD_on_FS_X_l4		//	Controls in l4
				global	FSD_on_FS_X_l6		//	Controls in l6
				global	FSD_on_FS_X_l8		//	Controls in l8
				
				foreach	var	of	global	FSD_on_FS_X	{
					
					loc	varlabel:	var	label	`var'
					
					cap	drop	l2_`var'
					cap	drop	l4_`var'
					cap	drop	l6_`var'
					cap	drop	l8_`var'
					
					gen		l2_`var'	=	l2.`var'
					gen		l4_`var'	=	l4.`var'
					gen		l6_`var'	=	l6.`var'
					gen		l8_`var'	=	l8.`var'
					
					lab	var	l2_`var'	"(L2) `varlabel'"
					lab	var	l4_`var'	"(L4) `varlabel'"
					lab	var	l6_`var'	"(L6) `varlabel'"
					lab	var	l8_`var'	"(L8) `varlabel'"
					
					global	FSD_on_FS_X_l4l2l0	${FSD_on_FS_X_l4l2l0}	l4_`var'	l2_`var'	`var'		
					global	FSD_on_FS_X_l4l2	${FSD_on_FS_X_l4l2}		l4_`var'	l2_`var'	
					global	FSD_on_FS_X_l2		${FSD_on_FS_X_l2}		l2_`var'
					global	FSD_on_FS_X_l4		${FSD_on_FS_X_l4}		l4_`var'
					global	FSD_on_FS_X_l6		${FSD_on_FS_X_l6}		l6_`var'
					global	FSD_on_FS_X_l8		${FSD_on_FS_X_l8}		l8_`var'
									
				}
				
				di	"${FSD_on_FS_X_l4l2l0}"
				di	"${FSD_on_FS_X}"
				di	"${FSD_on_FS_X_l4l2}"
				di	"${FSD_on_FS_X_l2}"
				di	"${FSD_on_FS_X_l4}"			
				di	"${FSD_on_FS_X_l6}"	
				di	"${FSD_on_FS_X_l8}"	
			
			
			
			*	Impulse response function (SNAP effects on future PFS)
				
				*	Create lagged non-linearly SNAP prediction 
				
				cap	drop	l0_SNAPhat
				cap	drop	l2_SNAPhat
				cap	drop	l4_SNAPhat
				cap	drop	l6_SNAPhat
				cap	drop	l8_SNAPhat
				cap	drop	f2_PFS_ppml
				cap	drop	f4_PFS_ppml
			
				
				cap	drop	l0_PFS_ppml
				clonevar	l0_PFS_ppml	=	PFS_ppml
				
				cap	drop	l0_FSdummy
				clonevar	l0_FSdummy	=	FSdummy
				
				clonevar	l0_SNAPhat	=	FSdummy_hat
				gen	l2_SNAPhat	=	l2.FSdummy_hat
				gen	l4_SNAPhat	=	l4.FSdummy_hat
				gen	l6_SNAPhat	=	l6.FSdummy_hat
				gen	l8_SNAPhat	=	l8.FSdummy_hat
				
				gen	f2_PFS_ppml	=	f2.PFS_ppml
				gen	f4_PFS_ppml	=	f4.PFS_ppml
				
				global	FSD_on_FS_X_l0	${FSD_on_FS_X}
				
				di	"${FSD_on_FS_X_l0}"
			
			
				
				*	Lagged SNAP effect
				*	Include the earliest
		
				foreach	lag	in	l0	 l2	l4	l6	l8 	{
						
					global	Z		`lag'_SNAPhat	//	FSdummy_hat	// 
					global	Zname	SNAPhat
					global	endoX	`lag'_FSdummy	//	FSdummy	//	
					
					ivreghdfe	PFS_FI_ppml	 ${FSD_on_FS_X_`lag'}	${timevars}	${Mundlak_vars}  	(${endoX} = ${Z})	${reg_weight}  ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(${Zname}) //	partial(*_bar9713) 
								
					estadd	local	Mundlak	"Y"
					estadd	local	YearFE	"Y"
					estadd	scalar	Fstat_CD	=	 e(cdf)
					estadd	scalar	Fstat_KP	=	e(widstat)
					summ	PFS_ppml	${sum_weight}	${lowincome}
					estadd	scalar	mean_PFS	=	 r(mean) 
					est	store	${Zname}_`lag'_2nd
					
					
				}
				
			
				*	SNAP (t-4, t-2) effects on PFS
				*	Use control in t-4 only
				ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_l4}	${timevars}	${Mundlak_vars_9713}  	(l4_FSdummy	l2_FSdummy  = l4_SNAPhat	l2_SNAPhat)	${reg_weight}  ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	
							
				estadd	local	Mundlak	"Y"
				estadd	local	YearFE	"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				*scalar	Fstat_KP_${Zname}	=	e(rkf)
				estadd	scalar	Fstat_KP	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	 ${lowincome}
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_l42_2nd
				
				
				*	SNAP (t-2, t) effects on PFS
				*	Use control in t-2 only
				ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_l2}	${timevars}	${Mundlak_vars_9713}  	(l2_FSdummy	l0_FSdummy  = l2_SNAPhat	l0_SNAPhat)	${reg_weight} ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})				
				estadd	local	Mundlak	"Y"
				estadd	local	YearFE	"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				*scalar	Fstat_KP_${Zname}	=	e(rkf)
				estadd	scalar	Fstat_KP	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	${lowincome}
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_l20_2nd
				
				
				*	SNAP (t-4, t-2, t-0) effects on PFS
				*	Use control in t-4 only
					*	Controls in t-4 only
				ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_l4}	${timevars}	${Mundlak_vars_9713}  	(l4_FSdummy	l2_FSdummy	l0_FSdummy  = l4_SNAPhat	l2_SNAPhat	l0_SNAPhat)	${reg_weight}  ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	
							
				estadd	local	Mundlak	"Y"
				estadd	local	YearFE	"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				*scalar	Fstat_KP_${Zname}	=	e(rkf)
				estadd	scalar	Fstat_KP	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	${lowincome}
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_l420_2nd
				
				
		
				
								
				
				*	2nd stage only
				esttab	${Zname}_l8_2nd ${Zname}_l6_2nd  ${Zname}_l4_2nd	 ${Zname}_l2_2nd	${Zname}_l0_2nd	${Zname}_l42_2nd ${Zname}_l20_2nd ${Zname}_l420_2nd using "${SNAP_outRaw}/PFS_${Zname}_2nd_lags.csv", ///
				cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2c mean_PFS YearFE Mundlak Fstat_CD	Fstat_KP , fmt(0 2) label("N" "R2" "Mean PFS" "Year FE" "Mundlak" "F-stat(CD)" "F-stat(KP)"))	///
				incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* )	order(l0_FSdummy	l2_FSdummy	l4_FSdummy l6_FSdummy	l8_FSdummy)	///
				title(PFS on Lagged FS dummy)		replace	
				
				
				
				
				
				
				
				
				
				
				*	Replicate for one-time users only
				
				*	Set-up for excluding multiple SNAP users.
				cap drop num_SNAP_used
				bys x11101ll: egen num_SNAP_used = total(FS_rec_wth) 
				lab	var	num_SNAP_used	"# of SNAP used during the period"
				
				cap	drop	SNAP_multi_used
				gen		SNAP_multi_used=0 if inrange(num_SNAP_used,0,1)
				replace	SNAP_multi_used=1 if inrange(num_SNAP_used,2,9)
				lab	var	SNAP_multi_used	"=1 if used SNAP multiple times"
				
				
				foreach	lag	in	l0	 l2	l4	l6	l8 	{
						
					global	Z		`lag'_SNAPhat	//	FSdummy_hat	// 
					global	Zname	SNAPhat
					global	endoX	`lag'_FSdummy	//	FSdummy	//	
					
					ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_`lag'}	${timevars}	${Mundlak_vars}  	(${endoX} = ${Z})	${reg_weight}  if  SNAP_multi_used==0, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(${Zname}) //	partial(*_bar9713) 
								
					estadd	local	Mundlak	"Y"
					estadd	local	YearFE	"Y"
					estadd	scalar	Fstat_CD	=	 e(cdf)
					estadd	scalar	Fstat_KP	=	e(widstat)
					summ	PFS_ppml	${sum_weight}	${lowincome}
					estadd	scalar	mean_PFS	=	 r(mean) 
					est	store	${Zname}_`lag'_2nd_dyn
					
					
				}
				
				esttab	${Zname}_l8_2nd_dyn ${Zname}_l6_2nd_dyn  ${Zname}_l4_2nd_dyn	 ${Zname}_l2_2nd_dyn	${Zname}_l0_2nd_dyn	using "${SNAP_outRaw}/PFS_${Zname}_2nd_lags_dyn.csv", ///
				cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2c mean_PFS YearFE Mundlak Fstat_CD	Fstat_KP , fmt(0 2) label("N" "R2" "Mean PFS" "Year FE" "Mundlak" "F-stat(CD)" "F-stat(KP)"))	///
				incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* )	order(l0_FSdummy	l2_FSdummy	l4_FSdummy l6_FSdummy	l8_FSdummy)	///
				title(PFS on Lagged FS dummy)		replace	
			
			
			
			
			
			*	Regressing FSD on predicted FS, using the model we find above
				*	SNAP weighted policy index, Dhat only, Mundlak controls.
				global	depvar		PFS_ppml
				global	endovar		FSdummy	//	FSamt_capita
				global	IV			SNAP_index_w	//	citi6016	//	inst6017_nom	//	citi6016	//		//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				global	IVname		index_w	//	CIM	//	
				
				
					*	Rename variables
										
					foreach	dropvar	in	TFI0	CFI0	TFI1	CFI1	TFI2	CFI2	SNAPhat	{
						cap	drop	`dropvar'
					}
			
					
					clonevar	TFI0	=	TFI_HCR_5
					clonevar	CFI0	=	CFI_HCR_5
					clonevar	TFI1	=	TFI_FIG_5
					clonevar	CFI1	=	CFI_FIG_5
					clonevar	TFI2	=	TFI_SFIG_5
					clonevar	CFI2	=	CFI_SFIG_5
					clonevar	SNAPhat	=	FSdummy_hat
					
/*
					cap	drop	TFI2_5
					cap	drop	CFI2_5
					clonevar	TFI2_5	=	TFI_SFIG_5
					clonevar	CFI2_5	=	CFI_SFIG_5
*/
		
				*	(2023-10-12) I start with the effects of SNAP 4-years ago on FSD
					*	The effects of cumulative redemption will be done later
				global	FSD_results
				global	Z		l4_SNAPhat
				global	Zname	l4_SNAPhat
				global	endoX	l4_FSdummy
					
				cap drop SNAP_5yr_?
				tab SNAP_cum_fre_5, gen(SNAP_5yr_)
				lab	var	SNAP_5yr_1	"No SNAP in 5 years"
				lab	var	SNAP_5yr_2	"SNAP once in 5 years"
				lab	var	SNAP_5yr_3	"SNAP twice in 5 years"
				lab	var	SNAP_5yr_4	"SNAP thrice in 5 years"
					
				foreach	depvar	in	SL_5	TFI0	CFI0	TFI1	CFI1	TFI2	CFI2	{	
				
				
								
					ivreghdfe	`depvar'	 ${FSD_on_FS_X_l4} 	${timevars}	${Mundlak_vars_9713}  (l4_FSdummy  l2_FSdummy l0_FSdummy  = l4_SNAPhat  l2_SNAPhat l0_SNAPhat )	${reg_weight}  ${lowincome} , ///
								/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname}) // partial(*_bar9713)
					
					estadd	local	Mundlak	"Y"
					estadd	local	YearFE	"Y"
					scalar	Fstat_CD_${Zname}		=	e(cdf)
					scalar	Fstat_KP_${Zname}		=	e(widstat)
					est	store	`depvar'_${Zname}_2nd
				
					est	restore	${Zname}${endoX}
					estadd	local	Mundlak	"Y"
					estadd	local	YearFE	"Y"
					estadd	scalar	Fstat_CD	=	Fstat_CD_${Zname}, replace
					estadd	scalar	Fstat_KP	=	Fstat_KP_${Zname}, replace
					
					est	store	`depvar'_${Zname}_1st
					est	drop	${Zname}${endoX}

					global	FSD_results	${FSD_results}	`depvar'_${Zname}_2nd
					
					
					esttab	`depvar'_l4_SNAPhat_2nd	 using "${SNAP_outRaw}/`depvar'_index_w_2nd.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2_c YearFE Mundlak Fstat_CD	Fstat_KP pval_Jstat, fmt(0 2) label("N" "R2" "Year FE" "Mundlak" "F-stat(CD)" "F-stat(KP)" "p-val(J-stat)"))	///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	 drop( year_enum* /**bar9713*/ )  order(l4_FSdummy)	///
							title(`depvar' on SNAP)		replace
					
				}
				
				esttab	${FSD_results}	 using "${SNAP_outRaw}/FSD_index_w_2nd.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2_c YearFE Mundlak Fstat_CD	Fstat_KP pval_Jstat, fmt(0 2) label("N" "R2" "Year FE" "Mundlak" "F-stat(CD)" "F-stat(KP)" "p-val(J-stat)"))	///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	 drop( year_enum* /**bar9713*/ )  order(l4_FSdummy)	///
							title(`depvar' on SNAP)		replace
				
			
		
