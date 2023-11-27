*	Validating IV using state-level (i) change in SPI and (ii) Change in outcomes (macroeconomic outcome)

	*	SPI and unemployment
	
	use "${SNAP_dtInt}/Unemployment Rate_state_annual", clear
	merge 1:1 year rp_state using "${SNAP_dtInt}/SNAP_policy_data_official", keepusing(SNAP_index_w) assert(1 3) nogen keep(3)

	keep	if	inrange(year,1997,2014)

	xtset	rp_state	year 

	gen	d_unemp = unemp_rate - l.unemp_rate
	gen d_SPI = SNAP_index_w - l.SNAP_index_w
 
	lab	var	d_unemp	"Change in State Unemployment Rate (ppt)"
	lab	var	d_SPI	"Change in SPI"
	
	graph	twoway	(scatter d_unemp d_SPI)
	
	graph twoway (lfit d_unemp d_SPI, graphregion(fcolor(white)))	///
				(scatter d_unemp d_SPI, graphregion(fcolor(white))), ytitle(Change in Unemployment Rate (ppt)) legend(off) title(Change in SPI and State Unemployment Rate)	///
				name(change_SPI_unemp, replace)
	graph display change_SPI_unemp, ysize(4) xsize(9.0)
	graph	export	"${SNAP_outRaw}/change_SPI_unemp.png", as(png) replace
	

	*	Within-state intertemporal variation
	
		*	Check (SPI in 2013 - SPI in 1997)
		cap	drop	d_SPI_9713
		gen	d_SPI_9713	=	SNAP_index_w - l16.SNAP_index_w if year==2013
		sort	d_SPI_9713	//	Minnesotta and Nebreska are smallest, Alabama and Missouri are middle, Louisiana and Ohio are the larest.
		
		cap	drop	state_num
		encode	state, gen(state_num)
		twoway line SNAP_index_w year if inrange(state_num,1,25), by(state_num, row(5) title("Dynamics of SPI over year - part I"))  xsize(12) ysize(8)
		graph	export	"${SNAP_outRaw}/change_SPI_by_state_part1.png", as(png) replace
		twoway line SNAP_index_w year if inrange(state_num,26,51), by(state_num, row(5) title("Dynamics of SPI over year - part II"))  xsize(12) ysize(8)
		graph	export	"${SNAP_outRaw}/change_SPI_by_state_part2.png", as(png) replace
		
		graph	twoway	(line SNAP_index_w year if rp_state==22, lpattern(solid)) ///
				(line SNAP_index_w year if rp_state==24, lpattern(dash)) ///
				(line SNAP_index_w year if rp_state==17, lpattern(dot))
	

		*	Employment outcome
		
			*	OLS
			reg	rp_employed FSdummy	${reg_weight} if reg_sample==1, 	cluster(x11101ll)	//	 bivariate
			reg	rp_employed FSdummy	${RHS}	${reg_weight} if reg_sample==1, 	cluster(x11101ll)	// with controls
		
						
			*	IV
			
				*	Bivariate
				cap	drop	${endovar}_hat_biv
				logit	${endovar}	${IV}	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
				predict	${endovar}_hat_biv
		
				ivreghdfe	rp_employed	(${endovar} = ${endovar}_hat_biv)	${reg_weight} if reg_sample==1, ///
								/*absorb(x11101ll)*/	cluster (x11101ll)	
		
				*	With controls/time FE/Mundlak
					
					*	Controls only
					cap	drop	${endovar}_hat_ctrl
					logit	${endovar}	${IV}	${FSD_on_FS_X}	 ${reg_weight}	if reg_sample==1, vce(cluster x11101ll) 
					predict	${endovar}_hat_ctrl
					
					ivreghdfe	rp_employed	${FSD_on_FS_X} 	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	
				
					*	Controls, time FE and Mundlak
					ivreghdfe	rp_employed	${RHS} 	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, ///
						/*absorb(x11101ll)*/	cluster (x11101ll)	
						
			*	Generate a proxy variable for ABAWD status
			cap	drop	ABAWD_proxy
			gen		ABAWD_proxy=0
			replace	ABAWD_proxy=1 if inrange(rp_age,18,49) & famnum==1
			
			tab		ABAWD_proxy	if	reg_sample==1
			summ	rp_employed if reg_sample==1  ${sum_weight}	
			summ	rp_employed if reg_sample==1 & ABAWD_proxy==1 	 ${sum_weight}	
			
			*	Regress only on ABAWD status
			
				*	OLS
				reg	rp_employed FSdummy	${reg_weight} if reg_sample==1 & ABAWD_proxy==1, 	cluster(x11101ll)	//	 bivariate
				reg	rp_employed FSdummy	${RHS}	${reg_weight} if reg_sample==1 & ABAWD_proxy==1, 	cluster(x11101ll)	// with controls
				
				
				*	IV
					
					*	Bivariate
					cap	drop	${endovar}_hat_biv
					logit	${endovar}	${IV}	 ${reg_weight}	if reg_sample==1 & ABAWD_proxy==1, vce(cluster x11101ll) 
					predict	${endovar}_hat_biv
					
					ivreghdfe	rp_employed	(${endovar} = ${endovar}_hat_biv)	${reg_weight} if reg_sample==1 & ABAWD_proxy==1, ///
								/*absorb(x11101ll)*/	cluster (x11101ll)	
					

				
					*	Controls, time FE and Mundlak
					cap	drop	${endovar}_hat_temp
					logit	${endovar}	${IV}	 ${reg_weight}	if reg_sample==1 & ABAWD_proxy==1, vce(cluster x11101ll) 
					predict	${endovar}_hat_temp
					
					ivreghdfe	rp_employed	${RHS} 	(${endovar} = ${endovar}_hat_temp)	${reg_weight} if reg_sample==1 & ABAWD_proxy==1, ///
						/*absorb(x11101ll)*/	cluster (x11101ll)	