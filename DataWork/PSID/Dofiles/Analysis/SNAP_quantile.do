*	Control, time FE, individual FE
*	(2024-2-13) Main model updated (2-way FE)


*	Within transformation
ds	${depvar}	${RHS}	


		global	RHS	 ${FSD_on_FS_X}	${timevars}	//	${Mundlak_vars}
		global	depvar		PFS_ppml	//		FIG_indiv		
		
		*	Running main model		
		ivreghdfe	${depvar}		${RHS}			(${endovar} = SNAP_index_w)			${reg_weight} if reg_sample==1, cluster(x11101ll) absorb(x11101ll)		first savefirst savefprefix(${Zname})	//	built-in FE
		ivreghdfe	${depvar}_dm	${RHS_dm}		(${endovar}_dm = SNAP_index_w_dm)	${reg_weight} if reg_sample==1, cluster(x11101ll) 	first savefirst savefprefix(${Zname})	//	Within-transformation. Slightly differnt
		
		*	Manual 1st stage
		cap	drop	SNAPhat
		reghdfe		${endovar}		SNAP_index_w	${RHS}		${reg_weight} if reg_sample==1,	cluster(x11101ll) absorb(x11101ll)	//	built-in FE
		predict		SNAPhat
		cap	drop	SNAPhat_dm
		reg			${endovar}_dm	SNAP_index_w_dm	${RHS_dm}	${reg_weight} if reg_sample==1,	cluster(x11101ll)	//	within. Almost identical.
		predict		SNAPhat_dm
		
	
		*	Manual 2nd stage
		reghdfe	${depvar}		SNAPhat			${RHS}		${reg_weight} if reg_sample==1,	cluster(x11101ll)	absorb(x11101ll)	//	built-in FE
		reg		${depvar}_dm	SNAPhat_dm	${RHS_dm}	${reg_weight} if reg_sample==1,	cluster(x11101ll)		//	Within, slightly different.
		
		*reg		FIG_indiv	SNAPhat	${RHS}	${reg_weight} if reg_sample==1,	cluster(x11101ll)	absorb(x11101ll)	//	FIG
		
		*	Quantile regressions		
		*	"qrprocess": community-contribute program. Supports pweight and clustered standard error.
			
			*	Set quantile
			cap	drop	PFS_pct
			xtile PFS_pct = PFS_ppml	${reg_weight} if reg_sample==1, nq(10)
			replace	PFS_pct = PFS_pct * 10
			forval	i=1/10	{
				
				local	j=`i'*5
				local	k=(`i'-1)*5
				di "i is `i', j is `j', k is `k'"
				 lab	define	PFS_pct	`j'	"`k'th to `j'th", add modify
				
			}
			lab	list PFS_pct
			lab	val	PFS_pct	PFS_pct
			lab	var	PFS_pct	"PFS percentile"
			
			*	Summary stats of the lowest quantiles
			summ	PFS_ppml	PFS_FI_ppml	FS_rec_wth	${sum_weight} if reg_sample==1 & PFS_pct==10
			summ	PFS_ppml	PFS_FI_ppml	FS_rec_wth	${sum_weight} if reg_sample==1 & PFS_pct==20
			summ	PFS_ppml	PFS_FI_ppml	FS_rec_wth	${sum_weight} if reg_sample==1 & PFS_pct==30
			summ	PFS_ppml	PFS_FI_ppml	FS_rec_wth	${sum_weight} if reg_sample==1 & PFS_pct==40
			
		
			*	(Ben's comment) To check which group of people drives SNAP participation (thus my estimator), check the SNAP compliance rate by different groups.
			*	I will compare three variables; (i) Realized SNAP participation (FSdummy) (ii) Non-linearly predicted SNAP status (FSdummy_hat) (iii) First-stage (SNAPhat)
				
				logit	${endovar}	${IV}	${RHS}	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
				margins, dydx(${IV}) over(PFS_pct)
				marginsplot, nolabel ytitle(Efects on Prob(SNAP participation)) title(Avg Marginal Effects of SPI on SNAP over PFS percentile)	///
				note(Low-income population. From logit regression of SNAP status on SPI)	name(SPI_on_SNAP_over_PFSqtile, replace)
				graph display SPI_on_SNAP_over_PFSqtile, ysize(4) xsize(9.0)
				graph	export	"${SNAP_outRaw}/SPI_on_SNAP_over_PFSqtile.png", as(png) replace
				
				
				*	Manually compute the first-stage to generate (iii)
				cap	drop	SNAPhat
				reg	${endovar}	SNAP_index_w		${RHS}	${reg_weight} if reg_sample==1, cluster(x11101ll)	absorb(x11101ll)
				predict	SNAPhat
				lab	var	SNAPhat	"Predicted SNAP status"
				
				/* (2024-2-13) Disabled.
				*	"FSdummy_hat" and "SNAPhat" are almost identical. let's check the magnitude of the difference
				cap	drop	diff_FShat_SNAPhat
				gen	diff_FShat_SNAPhat	=	abs(FSdummy_hat-SNAPhat)
				summ	diff_FShat_SNAPhat,d	//	Mean diference 0.008 (0.8ppt), median 0.006 (0.6ppt), std.dev is 0.007, max is 0.04 (4pct)
				*/
				
				
				*	Compute average SNAP statuses for each quantile
				preserve
					keep	if	reg_sample==1
					collapse (mean) PFS_ppml FSdummy /* FSdummy_hat */	SNAPhat ${reg_weight}, by(PFS_pct) // reg_weight and sum_weight give the same mean
					
					*	As we checked above, FSdummy_hat and SNAPhat are nearly identical. SO I will just compare FSdummy and SNAPhat
					lab	var	PFS_ppml		"PFS"
					lab	var	FSdummy			"Realized SNAP (binary)"
					//lab	var	FSdummy_hat		"Non-linearly predicted SNAP (fraction) - IV"
					lab	var	SNAPhat			"Predicted SNAP (linear)"
					
					graph	twoway	(line PFS_ppml PFS_pct) (connected	FSdummy	PFS_pct) /*(line	SNAPhat	PFS_pct)*/, ///
					title(SNAP participation status by PFS quantile,) xline(20) xtitle(PFS percentile) ytitle (Percentage) ///
					note(99\% of Food insecure individuals (PFS<0.45) are below 20th percentile) name(SNAP_over_PFSqtile, replace)
					graph display SNAP_over_PFSqtile, ysize(4) xsize(9.0)
					graph	export	"${SNAP_outRaw}/SNAP_over_PFSqtile_lowinc.png", as(png) replace
				restore
				
			 
			
			*	Quantile regression
			*ivreghdfe	${depvar}		${RHS}			(${endovar} = SNAP_index_w)			${reg_weight} if reg_sample==1, cluster(x11101ll) absorb(x11101ll)		first savefirst savefprefix(${Zname})	//	built-in FE
			*reg		${depvar}_dm		SNAPhat_dm	${RHS_dm}	${reg_weight} if reg_sample==1,	 vce(cluster x11101ll)
				
				*	1st stage (seems not a proper analysis)
				*qrprocess 	SNAPhat_dm		SNAP_index_w_dm	${RHS_dm}	${reg_weight} if reg_sample==1,	 vce(, cluster(x11101ll)) 	q(0.10(0.1)0.9)	//	 10 percentile to 95 percentile (caution: takes time)
				*est store qreg_SNAP
				
				*	2nd stage
				qrprocess 	${depvar}_dm	${RHS_dm}	${reg_weight} if reg_sample==1,	 vce(, cluster(x11101ll)) 	q(0.10(0.1)0.9)	//	 10 percentile to 95 percentile (caution: takes time)
				
			
			*qrprocess 	${depvar}		SNAPhat	${RHS}	${reg_weight} if reg_sample==1,	 vce(, cluster(x11101ll)) q(0.1(0.1)0.9)	// 10 percentile to 95 percentile (caution: takes time)
			*qrprocess 	${depvar}		SNAPhat	${RHS}	${reg_weight} if reg_sample==1,	 vce(, cluster(x11101ll)) q(0.1(0.1)0.2)	// 10 percentile to 20 percentile (caution: takes time)
			

			esttab	  using "${SNAP_outRaw}/PFS_qreg_lowinc.csv", ///
			cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N, fmt(0 2) label("N" )) ///
			incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(q*:SNAPhat_dm)	///
			title(PFS on FS dummy)		replace	
			
			*	Coefficient plot
				*	Coef lable
				global	coeflabel	//	Nul
				forval	i=1/9		{
					loc	j=`i'*10
					
					global	coeflabel	${coeflabel}	q`i':SNAPhat_dm = q`j'
					
				}
				di "${coeflabel}"
			
			//coefplot	qreg_PFS, keep(q1:SNAPhat q2:SNAPhat) vertical    noeqlabels /* nolabels */ 	coeflabels(${coeflabel}) title(SNAP effects by PFS percentile - 5 to 90 percentile)
			
			
			*	2nd stage
			coefplot	qreg_PFS, keep(q*:SNAPhat_dm) vertical    noeqlabels /* nolabels */ 	coeflabels(${coeflabel}) title(SNAP Effects by PFS percentile - 10 to 90 percentile)	///
				bgcolor(white)	graphregion(color(white)) 	name(PFS_qtile, replace)	
			graph display PFS_qtile, ysize(4) xsize(9.0)
			graph	export	"${SNAP_outRaw}/PFS_qtile_lnc.png", as(png) replace
				
		
		
		*	Residual plot
		*	Compare residuals (PFS on X, except SNAP) b/w SNAP and non-SNAP households.
		cap	drop	PFS_on_X_noSNAP_r
		reg		${depvar}	${RHS}	${reg_weight} if reg_sample==1,	cluster(x11101ll)
		predict	PFS_on_X_noSNAP_r, resid
		graph	twoway	(kdensity	PFS_on_X_noSNAP_r	${sum_weight} 	if	FSdummy==0 & reg_sample==1, lpattern(dash))	///
						(kdensity	PFS_on_X_noSNAP_r	${sum_weight}	if	FSdummy==1 & reg_sample==1, lpattern(solid)), ///
			title(Residual by SNAP status) legend(label(1 "Non-SNAP individuals") label(2 "SNAP individuals")) note(Residual from regressing PFS on covariates excluding SNAP status)
		graph	export	"${SNAP_outRaw}/PFS_residual_by_SNAP.png", as(png) replace
		
	
		*	FIG and SFIG
		lab	var	FIG_indiv	"FIG"
		lab	var	SFIG_indiv	"SFIG"
		
		summ	FIG_indiv ${sum_weight}	if	reg_sample==1, d
		summ	FIG_indiv ${sum_weight}	if	reg_sample==1 & FSdummy==0, d
		summ	FIG_indiv ${sum_weight}	if	reg_sample==1 & FSdummy==1, d
		
		summ	SFIG_indiv ${sum_weight}	if	reg_sample==1, d
		summ	SFIG_indiv ${sum_weight}	if	reg_sample==1 & FSdummy==0, d
		summ	SFIG_indiv ${sum_weight}	if	reg_sample==1 & FSdummy==1, d
		
		graph	twoway	(kdensity	FIG_indiv ${sum_weight}	if	reg_sample==1)
		
		
		
		
		*	Bivariate
		global	RHS
		
			*	OLS
			
			foreach	depvar	in	FIG	SFIG	{
				reg	`depvar'_indiv	${endovar}	${RHS}	${reg_weight} if reg_sample==1, cluster(x11101ll)
				estadd	local	Controls	"N"
				estadd	local	YearFE		"N"
				estadd	local	Mundlak		"N"
				estadd	scalar	r2c	=	e(r2)
				summ	`depvar'_indiv	${sum_weight}	if	e(sample)==1			
				estadd	scalar	mean_outcome	=	 r(mean)					
				est	store	`depvar'_biv_OLS
				}
		
			*	IV
				
				cap	drop	${endovar}_hat
				logit	${endovar}	${IV}	${RHS}	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
				predict	${endovar}_hat
				lab	var	${endovar}_hat	"Predicted SNAP"		
				
				
				foreach	depvar	in	FIG	SFIG	{
					ivreghdfe	`depvar'_indiv	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)		first 
					estadd	local	Controls	"N"
					estadd	local	YearFE		"N"
					estadd	local	Mundlak		"N"
					*scalar	Fstat_CD_${Zname}	=	 e(cdf)
					*scalar	Fstat_KP_${Zname}	=	e(widstat)
					summ	`depvar'_indiv	${sum_weight}	if	e(sample)==1
					estadd	scalar	mean_outcome	=	 r(mean)
					est	store	`depvar'_biv_IV
				
				}
			
			
		*	Controls, time FE and Mundlak
		global	RHS	${FSD_on_FS_X}	${timevars}		${Mundlak_vars}
		
			*	OLS
			
			foreach	depvar	in	FIG	SFIG	{
				reg	`depvar'_indiv	${endovar}	${RHS}	${reg_weight} if reg_sample==1, cluster(x11101ll)
				estadd	local	Controls	"Y"
				estadd	local	YearFE		"Y"
				estadd	local	Mundlak		"Y"
				estadd	scalar	r2c	=	e(r2)
				summ	`depvar'_indiv	${sum_weight}	if	e(sample)==1			
				estadd	scalar	mean_outcome	=	 r(mean)					
				est	store	`depvar'_mund_OLS
				}
			
		
			*	IV
				
				global	RHS	${FSD_on_FS_X}	 ${timevars}	${Mundlak_vars}
				
				cap	drop	${endovar}_hat
				logit	${endovar}	${IV}	${RHS}	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
				predict	${endovar}_hat
				lab	var	${endovar}_hat	"Predicted SNAP"		
				
				
				foreach	depvar	in	FIG	SFIG	{
					ivreghdfe	`depvar'_indiv	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)		first 
					estadd	local	Controls	"Y"
					estadd	local	YearFE		"Y"
					estadd	local	Mundlak		"Y"
					*scalar	Fstat_CD_${Zname}	=	 e(cdf)
					*scalar	Fstat_KP_${Zname}	=	e(widstat)
					summ	`depvar'_indiv	${sum_weight}	if	e(sample)==1
					estadd	scalar	mean_outcome	=	 r(mean)
					est	store	`depvar'_mund_IV
				
				}
				
			
			
				esttab	FIG_biv_OLS FIG_biv_IV FIG_mund_OLS FIG_mund_IV	///
						SFIG_biv_OLS SFIG_biv_IV SFIG_mund_OLS SFIG_mund_IV	using "${SNAP_outRaw}/FIG_20231112.csv", ///
						mgroups("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV", pattern(1 1 1 1 1 1 1 1))	///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_outcome Controls, fmt(0 2) label("N" "R$^2$" "Mean outcome" "Control/Year FE/Mundlak")) ///
						incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(${endovar})	///
						title(SNAP on Food Insecurity - Level and Severity)	note(Controls include RP’s characteristics (gender, age, age squared race, marital status, disability and college degree). Mundlak includes time-average of controls and year fixed effects. Estimates are adjusted with longitudinal individual survey weight provided in the PSID. Standard errors are clustered at individual-level.)	replace	

				esttab	FIG_biv_OLS FIG_biv_IV FIG_mund_OLS FIG_mund_IV	///
						SFIG_biv_OLS SFIG_biv_IV SFIG_mund_OLS SFIG_mund_IV	using "${SNAP_outRaw}/FIG_20231112.tex", ///
						mgroups("OLS" "IV" "OLS" "IV" "OLS" "IV" "OLS" "IV", pattern(1 1 1 1 1 1 1 1))	///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_outcome Controls, fmt(0 2) label("N" "R$^2$" "Mean outcome" "Control/Year FE/Mundlak")) ///
						incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(${endovar})	///
						title(SNAP on Food Insecurity - Level and Severity)	note(Controls include RP’s characteristics (gender, age, age squared race, marital status, disability and college degree). Mundlak includes time-average of controls and year fixed effects. Estimates are adjusted with longitudinal individual survey weight provided in the PSID. Standard errors are clustered at individual-level.)	replace		
			
			

			*	Those who were ever food insecure
			*	Generate ever_FI indicator
			cap	drop	PFS_FI_ever
			bys	x11101ll:	egen	PFS_FI_ever=max(PFS_FI_ppml)
			lab	var	PFS_FI_ever	"=1 if ever food isnecure (PFS<0.45)"
			tab	PFS_FI_ever	income_ever_below_130_9713

			cap	drop	${endovar}_hat
			logit	${endovar}	${IV}	${RHS}	 ${reg_weight}	if reg_sample==1	& PFS_FI_ever==1, vce(cluster x11101ll) 
			predict	${endovar}_hat
			lab	var	${endovar}_hat	"Predicted SNAP"		
			
			
			ivreghdfe	PFS_ppml	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})
					
			
			summ	FIG_indiv	SFIG_indiv	${sum_weight} if reg_sample==1	&	PFS_ppml<0.45
			
			ivtobit	FIG_indiv	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, ///
					/*absorb(x11101ll)*/	vce(cluster x11101ll)	ll(0)
			ivtobit	SFIG_indiv	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, ///
					/*absorb(x11101ll)*/	vce(cluster x11101ll)	ll(0)		
			
			reg	FIG_indiv	SNAPhat	if reg_sample==1	
						
			ivreghdfe	FIG_indiv	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})
							
					
			ivreghdfe	SFIG_indiv	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1 & PFS_FI_ever==1, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})
					
			
			
			ivreghdfe	foodexp_tot_exclFS_pc	${RHS}	(${endovar}	=SNAP_index_w)	${reg_weight} if reg_sample==1, 	cluster (x11101ll)	
					
					
		

			 fracreg logit FIG_indiv  ${endovar}_hat	${RHS}	${reg_weight} if reg_sample==1, vce(cluster x11101ll)
			 margins, dydx( ${endovar}_hat)
			 
			 fracreg logit SFIG_indiv  ${endovar}_hat	${RHS}	${reg_weight} if reg_sample==1	& PFS_FI_ever==1, vce(cluster x11101ll)
			 margins, dydx( ${endovar}_hat)
			 
			 
			 
			 *	Qunatile regression plot for FIG
75\
			
			twoway	(kdensity PFS_ppml	${sum_weight}, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full sample"))) 	///
					(kdensity PFS_ppml	${sum_weight}	if	income_ever_below_130_9713==1, lc(purple) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Low-income"))), 	///
					title("PFS Distribution") ytitle("Density") xtitle("PFS") xline(0.45) xlabel(0.25 0.45 "FI Cutoff (0.45)" 0.75 1.0) name(PFS_dist_byinc, replace)
					
			twoway	(kdensity FIG_indiv	${sum_weight}, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full sample"))) 	///
					(kdensity FIG_indiv	${sum_weight}	if	income_ever_below_130_9713==1, lc(purple) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Low-income"))), 	///
					title("FIG Distribution") ytitle("Density") xtitle("PFS") xlabel(0.25 0.5 0.75 1.0) name(FIG_dist_byinc, replace)
			
			graph	combine	PFS_dist_byinc	FIG_dist_byinc, name(PFS_FIG_dist_byinc, replace)
			graph display PFS_FIG_dist_byinc, ysize(4) xsize(9.0)	
			graph	export	"${SNAP_outRaw}/PFS_FIG_dist_byinc.png", as(png) replace
		
			
			graph	twoway	(kdensity	FIG_indiv	${sum_weight})	(kdensity	FIG_indiv	${sum_weight}	if	income_ever_below_200_9713==1)
			
			

				*	Quantile regression at lower quantile; they are mostly zero due to the skewed nature of the FIG.
				qrprocess 	FIG_indiv	SNAPhat	${RHS}	${reg_weight} if reg_sample==1,	 vce(, cluster(x11101ll)) q(0.05(0.05)0.15)	// 5 percentile to 15 percentile - null effects (cuz outcome variable is zero)
				qrprocess 	FIG_indiv	SNAPhat	${RHS}	${reg_weight} if reg_sample==1,	 vce(, cluster(x11101ll)) q(0.7(0.05)0.95)	// 70 percentile to 96 percentile - WHY POSITIVE EFFECTS?
			
				*qrprocess 	FIG_indiv		${endovar}_hat	${RHS}	${reg_weight} if reg_sample==1,	 vce(, cluster(x11101ll)) q(0.8)	// 5 percentile to 95 percentile (caution: takes time)
				est store qreg_FIG


			esttab	  using "${SNAP_outRaw}/FIG_qreg.csv", ///
			cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N, fmt(0 2) label("N" )) ///
			incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(q*:SNAPhat)	///
			title(FIG on SNAP)		replace	
			
			*	Coefficient plot
				*	Coef lable
				global	coeflabel	//	Nul
				forval	i=1/6		{
					loc	j= 65 + (`i'*5)
					
					global	coeflabel	${coeflabel}	q`i':SNAPhat = q`j'
					
				}
				di "${coeflabel}"
			
					
			//coefplot	qreg_PFS, keep(q1:SNAPhat q2:SNAPhat) vertical    noeqlabels /* nolabels */ 	coeflabels(${coeflabel}) title(SNAP effects by PFS percentile - 5 to 90 percentile)
			coefplot	qreg_FIG, keep(q*:SNAPhat) vertical    noeqlabels /* nolabels */ 	coeflabels(${coeflabel}) title(SNAP effects by PFS percentile - 5 to 90 percentile)	///
				bgcolor(white)	graphregion(color(white)) 	name(FIG_qtile, replace)	
			graph display FIG_qtile, ysize(4) xsize(9.0)
			graph	export	"${SNAP_outRaw}/FIG_qtile_lowinc.png", as(png) replace
					 
		* genqreg PFS_ppml	${endovar}	 	${RHS}	if reg_sample==1 , quantile(0.5) instruments(${endovar}_hat	${RHS})	
		
		
				/*
		*	Since I cannot find quantile regressions that allows (i) weighted (ii) simultaneous (iii) clustered standared error, I test each specification.
		
			*	OLS
			reg	${depvar}		SNAPhat	${RHS}				 if reg_sample==1	//	Unweighted, unclustered
			reg	${depvar}		SNAPhat	${RHS}	${reg_weight} if reg_sample==1	//	Weighted, unclustered
		
			
			reg	${depvar}		SNAPhat	${RHS}	${reg_weight} if reg_sample==1,	cluster(x11101ll)	//	weighted, clustered
		
			
			*	Quantile regression
			
				*	"qreg": Stata-included command, support weighted but not clustered standard eror and not simultanoues equation. More than that, it does not converge.
				qreg	${depvar}		SNAPhat	${RHS} ${reg_weight} if reg_sample==1, vce(robust)
				
				*	"bsqreg": Stata-included command. Convereges but does not support weight.
				*	CAUTION: TAKES SOME TIME
				*bsqreg	${depvar}		SNAPhat	${RHS} ${reg_weight} if reg_sample==1
		
				*	qreg2: Community-contriute command. Does not support "pweight"
				qreg2	${depvar}		SNAPhat	${RHS}  if reg_sample==1
				
			*/	