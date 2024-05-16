*	Validating IV using state-level (i) change in SPI and (ii) Change in outcomes (macroeconomic outcome)

	*	SPI and unemployment
	
	use "${SNAP_dtInt}/Unemployment Rate_state_annual", clear
	merge 1:1 year rp_state using "${SNAP_dtInt}/SNAP_policy_data_official", /*keepusing(SNAP_index_w)*/ assert(1 3) nogen keep(3)

	keep	if	inrange(year,1997,2014)

	xtset	rp_state	year 

	
	*	Construct change variablee
	gen	d_unemp = unemp_rate - l.unemp_rate
	gen d_SPI = SNAP_index_w - l.SNAP_index_w
	gen	d_SPI_uw	=	SNAP_index_uw	-	l.SNAP_index_uw
 
	lab	var	d_unemp	"Change in State Unemployment Rate (ppt)"
	lab	var	d_SPI	"Change in SPI"
	
		*	Construct if for all SPI components
		ds	exempt_one-outreach
		foreach	var	in	`r(varlist)'	{
			
			cap	drop	d_`var'
			gen			d_`var'	=	`var'	-	l.`var'
			
		}
		
		*	Construct a dummy variable equal to 1 if there was change in ANY of SPI component
		*	For recertification share variable, I categorize it as change if change is greater than 0.1.
	
			*	Number of SPI-components (other than recertification share) without any change
			*	If state did not adopt any change, it has value 9
			*	First-period (1997) has value 0
			cap	drop	change_others
			egen	change_others	=	anycount(d_exempt_one d_exempt_all d_BBCE d_elig_rest d_simp_report d_online_app d_EBT_share d_fingerprint d_outreach), values(0)	// State-year with no change has value 9. First period
			
			*	For short recertification period share variable, I tag it as change if change is greater than 0.1
			loc	var		any_change_in_recert
			cap	drop	`var'
			gen			`var'=.
			replace		`var'=0	if	inrange(d_short_recert,-0.01,0.01)
			replace		`var'=1	if	!mi(d_short_recert)	&	!inrange(d_short_recert,-0.01,0.01)
			
			*	Now, create a dummy variable if there was any change in SPI
			loc	var	change_in_SPI
			cap	drop	`var'
			gen		`var'=.	if	year==1997
			replace	`var'=0	if	change_others==9	&	any_change_in_recert==0	//	No change in SPI component
			replace	`var'=1	if	inrange(change_others,1,8)	|	any_change_in_recert==1	//	Any change in SPI component
			lab	var	`var'	"=1 if State adopted any change in SPI component"
			
			
			*	Do it again for state relaxed any of 4 policies affecting eligibility criteria (vehicle, BBCE and non-citizen)
	
			loc	var		relax_in_elig_crit
			cap	drop	`var'
			gen			`var'=.	if	year==1997
			replace		`var'=1	if	year!=1997	&	(d_exempt_one>0 | d_exempt_all>0 |  d_BBCE>0 | d_elig_rest>0)
			replace		`var'=0	if	year!=1997	&	!(d_exempt_one>0 | d_exempt_all>0 |  d_BBCE>0 | d_elig_rest>0)
			
			*	Average change in SPI
			summ	d_SPI d_SPI_uw	change_in_SPI	relax_in_elig_crit
			
			summ	d_SPI d_SPI_uw	if	change_in_SPI==1 // For years when state adopted any change in SPI
			summ	d_SPI d_SPI_uw	if	change_in_SPI==0 // For years when state adopted no change in SPI
			
			summ	d_SPI d_SPI_uw	if	relax_in_elig_crit==1 // For years when state relaxed any eligibility criteria
			summ	d_SPI d_SPI_uw	if	relax_in_elig_crit==0 // For years when state relaxed any eligibility criteria
			
		*gen	`var'=0
		*replace	`var'=1	if	!inlist(0,d_exempt_one,d_exempt_all,d_BBCE,d_elig_rest,d_simp_report,d_online_app,d_EBT_share,d_fingerprint,d_outreach)
	
	*	(2024-4-19) Correlation between change in state uemp and change in SPI (as suggested in B-exam)
	pwcorr	d_unemp	d_SPI, sig
	
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
		sort	state	year
		twoway line SNAP_index_w year if inrange(state_num,1,25), by(state_num, row(5) title("Dynamics of SPI over year - part I"))  xsize(12) ysize(8)
		graph	export	"${SNAP_outRaw}/change_SPI_by_state_part1.png", as(png) replace
		twoway line SNAP_index_w year if inrange(state_num,26,51), by(state_num, row(5) title("Dynamics of SPI over year - part II"))  xsize(12) ysize(8)
		graph	export	"${SNAP_outRaw}/change_SPI_by_state_part2.png", as(png) replace
		
		graph	twoway	(line SNAP_index_w year if rp_state==22, lpattern(solid)) ///
				(line SNAP_index_w year if rp_state==24, lpattern(dash)) ///
				(line SNAP_index_w year if rp_state==17, lpattern(dot))

				
		twoway	(line SNAP_index_w	year	if	rp_state==4, 	 lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "CA")))	///
				(line SNAP_index_w	year	if	rp_state==31, 	 lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "NY")))	///
				(line SNAP_index_w	year	if	rp_state==50, 	lc(purple) lp(dot) lwidth(medium) graphregion(fcolor(white)) legend(label(3 "AK")))	///
				(line SNAP_index_w	year	if	rp_state==49, lc(red) lp(dash_dot) lwidth(medium) graphregion(fcolor(white)) legend(label(4 "WY"))),	///
				title("SPI over Years") ytitle("SPI") xtitle("Year")	name(SPI_by_state, replace)
		graph	export	"${SNAP_outRaw}/SPI_trend_by_selected_states.png", as(png) replace
		graph	close				
				
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