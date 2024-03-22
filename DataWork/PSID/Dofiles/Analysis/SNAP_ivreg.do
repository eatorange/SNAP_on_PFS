
*	This do-file includes final analyses after testing various models
	*	For model testing, please check "SNAP_ivreg_test.do"

	*	IV regression
	if	`IV_reg'==1	{
		
		*	Data with FSD variables
		use	  "${SNAP_dtInt}/SNAP_const", clear
		
			*	Keep study sample or 1997-2013 causal inference
			*	Note: already done in dynamics data.
			*keep	if	inrange(year,1997,2013)
			

			*	Construct individual indicator
			sort	x11101ll	year
				
				*	RP
				cap	drop	RP
				gen	RP=1	if	seqnum==1	&	relrp_recode==1
				lab	var	RP	"Reference person"
				
				*	Spouse
				cap	drop	SP
				gen	SP=1	if	seqnum==2	&	relrp_recode==2
				lab	var	SP	"Spouse of RP"
				
				*	RP or SP
				cap	drop	RPSP
				gen	RPSP=1	if	inlist(1,RP,SP)
				lab	var	RPSP	"RP or RP's spouse"
				
				
				*	Cumulative status over period
				foreach	var	in RP SP RPSP	{
					
					
					cap	drop	num`var'
					bys	x11101ll:	egen	num`var'	=	total(`var') if inrange(year,1997,2013)
					
					cap	drop	same`var'_9713
					cap	drop	no`var'_9713
					
					
					gen	same`var'_9713=1	if	num`var'==9 // same status all the time
					lab	var	same`var'_9713	"same `var' over 1997-2013"
					gen no`var'_9713=1		if	num`var'==0 // never been this status all the time.
					lab	var	no`var'_9713	"no `var' over 1997-2013"
				}
			
	
			
			*	(2023-08-20)	Keep non-missing PFS obs only.
			*	(2023-09-09)	Already done in dynamics data.
			
			*keep	if	!mi(PFS_ppml)
		
	
		*	Additional cleaning
			
			*	Re-scale (to vary from 0 to 1) and standardize SNAP index
			*	Not sure I am gonna use it..
				foreach	type	in	uw	w	{

					*	Re-scaled version
					cap	drop	SNAP_index_`type'_0to1
					summ	SNAP_index_`type'  [aw=wgt_long_ind]
					gen		SNAP_index_`type'_0to1	=	(SNAP_index_`type'-r(min)) / (r(max) - r(min))
					lab	var	SNAP_index_`type'_0to1		"SNAP Policy Index (`type' \& rescaled)"
							
					*	Standardized version				
					cap drop SNAP_index_`type'_std
					summ	SNAP_index_`type'  [aw=wgt_long_fam_adj]
					gen	SNAP_index_`type'_std = (SNAP_index_`type' - r(mean)) / r(sd)
					lab	var	SNAP_index_`type'_std	"SNAP policy index (`type' \& standardized)"
					
				}
				
				/*
				*	Generate dummy for each cumulative SNAP status over 5-year
				*	Will be later imported to "clean.do" file
				cap	drop	SNAP_cum_fre_?
				tab	SNAP_cum_fre, gen(SNAP_cum_fre_)
				rename	(SNAP_cum_fre_1	SNAP_cum_fre_2	SNAP_cum_fre_3	SNAP_cum_fre_4)	(SNAP_cum_fre_0	SNAP_cum_fre_1	SNAP_cum_fre_2	SNAP_cum_fre_3)
				lab	var	SNAP_cum_fre_0	"No SNAP over 5 years"
				lab	var	SNAP_cum_fre_1	"SNAP once over 5 years"
				lab	var	SNAP_cum_fre_2	"SNAP twice over 5 years"
				lab	var	SNAP_cum_fre_3	"SNAP thrice over 5 years"
				*/
		
			*	Temporary create copies of endogenous variable (name too long)
				cap	drop	FSdummy	FSamt	FSamtK
				clonevar	FSdummy			=	FS_rec_wth
				clonevar	FSamt			=	FS_rec_amt_real
				clonevar	FSamtcp			=	FS_rec_amt_capita_real
				
				gen			FSamtK	=	FSamt/1000
				lab	var		FSamtK	"SNAP benefit (USD) (K)"
				lab	var		FSamtcp	"SNAP benefit amount per capita"
				
				cap	drop	FS_amt_real
				cap	drop	FS_amt_realK
				cap	drop	FS_amt_cap_real
				cap	drop	FS_amt_cap_realK
				clonevar	FS_amt_real			=	FS_rec_amt_real
				gen			FS_amt_realK		=	FS_rec_amt_real	/	1000
				clonevar	FS_amt_cap_real		=	FS_rec_amt_capita_real
				gen			FS_amt_cap_realK	=	FS_rec_amt_capita_real / 1000
				lab	var		FS_amt_real			"SNAP benefit"
				lab	var		FS_amt_realK		"SNAP benefit (K)"
				lab	var		FS_amt_cap_realK	"SNAP benefit per capita (K)"
		
			*	Temporarily rescale SSI and share variables (0-1 to 1-100)
			qui	ds	share_edu_exp_sl-SSI_GDP_s
			
			foreach	var	in	`r(varlist)'		{
				
				replace	`var'=	`var'*100		if	!mi(`var')	&	!inrange(`var',1,100) // This condition make sure that we do not double-scale it (ex. later fixed it in the "clean" part but forgot to fix it here.)
				assert	inrange(`var',0,100)	if	!mi(`var')
			}
			
			*	Temporary rescale lagged food exp^2
			replace	l2_foodexp_tot_inclFS_pc_2_real	=	l2_foodexp_tot_inclFS_pc_2_real/1000
			lab	var	l2_foodexp_tot_inclFS_pc_2_real		"Food exp in t-2 (K)"
			
			*	Temporary generate state control categorical variable
			cap	drop	major_control_cat
			gen			major_control_cat=.
			replace		major_control_cat=0	if	major_control_mix==1
			replace		major_control_cat=1	if	major_control_dem==1
			replace		major_control_cat=2	if	major_control_rep==1
			lab	define	major_control_cat	0	"Mixed"	1	"Demo control"	2	"Repub control"
			lab	val		major_control_cat	major_control_cat
			lab	var		major_control_cat	"State control"
			
			*	Temporary generate interaction variable
			gen	int_SSI_exp_sl_01_03	=	SSI_exp_sl	*	year_01_03
			gen	int_SSI_GDP_sl_01_03	=	SSI_GDP_sl	*	year_01_03
			gen	int_share_GDP_sl_01_03	=	share_welfare_GDP_sl	*	year_01_03
			*gen	int_SSI_GDP_sl_post96	=	SSI_GDP_sl	*	post_1996
			*gen	int_SSI_GDP_s_post96	=	SSI_GDP_s	*	post_1996
			
			lab	var	year_01_03				"{2001,2003}"
			lab	var	int_SSI_exp_sl_01_03	"SSI X {2001_2003}"
			lab	var	int_SSI_GDP_sl_01_03	"SSI X {2001_2003}"
			lab	var	int_share_GDP_sl_01_03	"Social expenditure share X {2001_2003}"
		
			
			*	Variable label	
			label	var	foodexp_tot_inclFS_pc_real	"Food exp (with FS benefit)"
			label	var	l2_foodexp_tot_inclFS_pc_1_real	"Food Exp in t-2"
			label	var	l2_foodexp_tot_inclFS_pc_2_real	"(Food Exp in t-2)$^2$"
			label	var	rp_age		"Age"
			label	var	rp_age_sq	"Age$^2$"
			label	var	change_RP	"RP changed"
			label	var	ln_fam_income_pc_real	"ln(per capita income)"
			label	var	unemp_rate	"State Unemp Rate"
			label	var	major_control_dem	"Dem state control"
			label	var	major_control_rep	"Rep state control"
			label	var	SSI_GDP_sl	"SSI"
			label	var	year_01_03	"2001 or 2003"
			label	var	citi6016	"State citizen ideology (1960-2015)"
			
	

		*	Summary stats of PFS 
		*	(2023-09-01) Use individual weight since the unit of analyse is individual
			*	For now, generate summ table separately for indvars and fam-level vars, as indvars do not represent full sample if conditiond by !mi(ppml) (need to figure out why)
				
				lab	var	age_ind		"Age (years)"
				lab	var	ind_female 	"Female (=1)"
				lab	var	ind_col		"College degree (=1)"
				lab	var	rp_female	"Female (=1)"
				lab	var	rp_age		"Age (years)"
				lab	var	rp_White	"White (=1)"
				lab	var	rp_married	"Married (=1)"
				lab	var	rp_employed "Employed (=1)"
				lab	var	rp_disabled "Disabled (=1)"
				lab	var	rp_NoHS		"Less than high school (=1)"
				lab	var	rp_HS		"High school (=1)"
				lab	var	rp_somecol	"College w/o degree (=1)"
				lab	var	rp_col		"College degree (=1)"
				lab	var	famnum		"Household size"
				lab	var	ratio_child	"\% children in household"
				lab	var	FS_rec_wth	"Received SNAP (=1)"
				
				cap	drop	fam_income_month_pc_real_K
				gen	fam_income_month_pc_real_K	=	(fam_income_pc_real / 1000) / 12
				lab	var	fam_income_month_pc_real_K	"Monthly income per capita (thousands)"
				
				lab	var	SNAP_index_uw	"SNAP Policy Index (unweighted)"
				lab	var	SNAP_index_w	"SNAP Policy Index (weighted)"
				lab	var	FS_rec_amt_real	"SNAP benefit amount"
				
				local	HHvars		rp_female	rp_age	rp_White	rp_married	rp_employed rp_disabled	rp_NoHS rp_HS rp_somecol rp_col	
				local	famvars		famnum	ratio_child
				local	moneyvars	fam_income_month_pc_real_K	foodexp_tot_inclFS_pc_real		
				local	SNAPvars	FS_rec_wth	FS_rec_amt_real
				local	IVs			SNAP_index_uw	SNAP_index_w
				local	FSvars		PFS_ppml PFS_FI_ppml	//SL_5	TFI_HCR	CFI_HCR	TFI_FIG	CFI_FIG	TFI_SFIG	CFI_SFIG	 // temporarily drop FSD
				
				local	summvars	/*`indvars'*/	`HHvars'	`famvars'	`moneyvars' `SNAPvars' `IVs'	`FSvars'
				
				*estpost summ	`indvars'	[aw=wgt_long_fam_adj]	if	!mi(PFS_ppml)	//	all sample
				*estpost summ	`indvars'	[aw=wgt_long_fam_adj]	if	!mi(PFS_ppml)	&	balanced_9713==1	&	income_ever_below_200_9713==1	/*  num_waves_in_FU_uniq>=2	 &*/	  // Temporary condition. Need to think proper condition.
				
				
				*	All, unweighted
				estpost tabstat	`summvars'	 if	!mi(PFS_ppml),	statistics(count	mean	sd) columns(statistics)		// save
				est	store	sumstat_all_nowgt
				*	All, weighted
				estpost tabstat	`summvars' 	if	!mi(PFS_ppml)	&	income_ever_below_130_9713==1,	statistics(count	mean	sd) columns(statistics)	// save
				est	store	sumstat_inc130_nowgt
				*	Income belowe 130, unweighted
				estpost tabstat	`summvars'	 if	!mi(PFS_ppml)	[aw=wgt_long_ind],	statistics(count	mean	sd) columns(statistics)		// save
				est	store	sumstat_all_wgt
				*	Income below 130, weighted
				estpost tabstat	`summvars' 	if	!mi(PFS_ppml)	&	income_ever_below_130_9713==1	[aw=wgt_long_ind],	statistics(count	mean	sd) columns(statistics)	// save
				est	store	sumstat_inc130_wgt
				
				
					*	FS amount per capita in real dollars (only those used)
					*estpost tabstat	 FS_rec_amt_capita	if in_sample==1	&	!mi(PFS_ppml)	&	income_below_200==1	& FS_rec_wth==1 [aw=wgt_long_fam_adj],	statistics(mean	sd	min	max) columns(statistics)	// save
				
			
				
				esttab	sumstat_all_nowgt	sumstat_inc130_nowgt	sumstat_all_wgt	sumstat_inc130_nowgt	using	"${SNAP_outRaw}/Tab_1_Sumstats.csv",  ///
					cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
									
				esttab	sumstat_all_nowgt	sumstat_inc130_nowgt	using	"${SNAP_outRaw}/Tab_1_Sumstats.tex",  ///
					cells("count(fmt(%12.0fc)) mean(fmt(%12.2f)) sd(fmt(%12.2f))") label	title("Summary Statistics - unweighted") noobs 	  replace
					
				esttab	sumstat_all_wgt	sumstat_inc130_wgt	using	"${SNAP_outRaw}/Tab_1_Sumstats_wgt.tex",  ///
					cells("count(fmt(%12.0fc)) mean(fmt(%12.2fc)) sd(fmt(%12.2f))") label	title("Summary Statistics - weighted") noobs 	  replace	
				
			
			
		*	Regression of PFS on Hh characteristics.
			*	Note: aweight and pweight gives the same regression coefficient, but sterror differ.
		{	
			*	Set Xs
			local	indvars		ind_female	age_ind	ind_col 
			local	HHvars		rp_female	rp_age	rp_White	rp_married	rp_employed rp_disabled	rp_col	
			local	famvars		famnum	ratio_child	fam_income_month_pc_real_K
			local	SNAPvars	FS_rec_wth	
			
			local	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
			local	timevars		year_enum20-year_enum27	//	Using year_enum19 (1997) as a base year
			
			
			local	depvar	PFS_ppml
			
		
		
			
			
			*	Unweighted
			
				*	full sample, no individual FE
				*reg		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	`regionvars'	`timevars'
				reghdfe		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	``weight'_spec', absorb(year rp_state)
				estadd	local	wgt			"N", replace
				estadd	local	ind_FE		"N", replace
				summ	`depvar'	``weight'_spec'
				estadd	scalar	meanPFS	=	r(mean), replace
				est	store PFS_X_all_nowgt_noiFE
		
				*	full sample, individual FE
				*reg		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	`regionvars'	`timevars'
				reghdfe		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars', absorb(year rp_state x11101ll)
				estadd	local	wgt			"N", replace
				estadd	local	ind_FE		"Y", replace
				summ	`depvar'
				estadd	scalar	meanPFS	=	r(mean), replace
				est	store PFS_X_all_nowgt_iFE
				
				*	inc130%, no individual FE
				reghdfe		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	if	income_ever_below_130_9713==1, absorb(year rp_state)
				estadd	local	wgt			"N", replace
				estadd	local	ind_FE		"N", replace
				summ	`depvar'	if	income_ever_below_130_9713==1
				estadd	scalar	meanPFS	=	r(mean), replace
				est	store PFS_X_inc130_nowgt_noiFE			
				
				*	inc130%, individual FE
				reghdfe		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	if	income_ever_below_130_9713==1, absorb(year rp_state x11101ll)
				estadd	local	wgt			"N", replace
				estadd	local	ind_FE		"Y", replace
				summ	`depvar'	if	income_ever_below_130_9713==1
				estadd	scalar	meanPFS	=	r(mean), replace
				est	store PFS_X_inc130_nowgt_iFE
				
			
			
			*	Weighted
			
				*	full sample, no individual FE
				*reg		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	`regionvars'	`timevars'
				reghdfe		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	[pw=wgt_long_ind], absorb(year rp_state)
				estadd	local	wgt			"N", replace
				estadd	local	ind_FE		"N", replace
				summ	`depvar'	[aw=wgt_long_ind]
				estadd	scalar	meanPFS	=	r(mean), replace
				est	store PFS_X_all_wgt_noiFE
				
				*	full sample, individual FE
				*reg		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	`regionvars'	`timevars'
				reghdfe		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	[pw=wgt_long_ind], absorb(year rp_state x11101ll)
				estadd	local	wgt			"N", replace
				estadd	local	ind_FE		"Y", replace
				summ	`depvar'	[aw=wgt_long_ind]
				estadd	scalar	meanPFS	=	r(mean), replace
				est	store PFS_X_all_wgt_iFE
				
				*	inc130%, no individual FE
				reghdfe		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	[pw=wgt_long_ind]	if	income_ever_below_130_9713==1, absorb(year rp_state)
				estadd	local	wgt			"N", replace
				estadd	local	ind_FE		"N", replace
				summ	`depvar'	[aw=wgt_long_ind]	if	income_ever_below_130_9713==1
				estadd	scalar	meanPFS	=	r(mean), replace
				est	store PFS_X_inc130_wgt_noiFE
							
				*	inc130%, individual FE
				reghdfe		`depvar'	`indvars'	`HHvars'	`famvars'	`SNAPvars'	[pw=wgt_long_ind]	if	income_ever_below_130_9713==1, absorb(year rp_state x11101ll)
				estadd	local	wgt			"N", replace
				estadd	local	ind_FE		"Y", replace
				summ	`depvar'	[aw=wgt_long_ind]	if	income_ever_below_130_9713==1
				estadd	scalar	meanPFS	=	r(mean), replace
				est	store PFS_X_inc130_wgt_iFE
			
			
			*	Weighted
			esttab	PFS_X_all_wgt_noiFE		PFS_X_all_wgt_iFE	PFS_X_inc130_wgt_noiFE		PFS_X_inc130_wgt_iFE	using "${SNAP_outRaw}/Tab_3_PFS_association_w.csv", ///
					cells(b(star fmt(3)) se(fmt(2) par)) stats(N r2 meanPFS ind_FE wgt, label("N" "R$^2$" "Mean PFS" "Individual FE" "Weighted")) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state*	year_enum*)*/	///
					title(PFS and household covariates) replace
	
			esttab	PFS_X_all_wgt_noiFE		PFS_X_all_wgt_iFE	PFS_X_inc130_wgt_noiFE		PFS_X_inc130_wgt_iFE	using "${SNAP_outRaw}/Tab_3_PFS_association_w.tex", ///
					cells(b(star fmt(3)) se(fmt(2) par)) stats(N r2 meanPFS ind_FE wgt, fmt(%8.0fc %8.2fc) label("N" "R$^2$" "Mean PFS" "Individual FE" "Weighted")) ///
					incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state*	year_enum*)*/	replace		
				
			
			
			*	Unweighted
			esttab	PFS_X_all_nowgt_noiFE		PFS_X_all_nowgt_iFE	PFS_X_inc130_nowgt_noiFE		PFS_X_inc130_nowgt_iFE	using "${SNAP_outRaw}/Tab_3_PFS_association_uw.csv", ///
					cells(b(star fmt(3)) se(fmt(2) par)) stats(N r2 meanPFS ind_FE wgt, label("N" "R$^2$" "Mean PFS" "Individual FE" "Weighted")) label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state*	year_enum*)*/	///
					title(PFS and household covariates) replace
	
			esttab	PFS_X_all_nowgt_noiFE		PFS_X_all_nowgt_iFE	PFS_X_inc130_nowgt_noiFE		PFS_X_inc130_nowgt_iFE	using "${SNAP_outRaw}/Tab_3_PFS_association_uw.tex", ///
					cells(b(star fmt(3)) se(fmt(2) par)) stats(N r2 meanPFS ind_FE wgt, fmt(%8.0fc %8.2fc) label("N" "R$^2$" "Mean PFS" "Individual FE" "Weighted")) ///
					incelldelimiter() label legend nobaselevels star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state*	year_enum*)*/	replace		
				
		}
		
		
		
		*	Kernel density
			*	PFS by gender
				graph twoway 		(kdensity PFS_ppml	if	!mi(PFS_ppml) & inrange(year,1997,2013) & rp_female==0, lc(green) lp(solid) lwidth(medium) graphregion(fcolor(white)) bwidth(0.05) )	///
									(kdensity PFS_ppml	if	!mi(PFS_ppml) & inrange(year,1997,2013) & rp_female==1, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) bwidth(0.05) ),	///
									/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(PFS) ytitle(Density)		///
									name(PFS_ind_gender, replace) graphregion(color(white)) bgcolor(white)	title(by Gender)	///
									legend(lab (1 "Male") lab(2 "Female") rows(1))	
									
									
				*	PFS by race
				graph twoway 		(kdensity PFS_ppml	if	!mi(PFS_ppml) & inrange(year,1997,2013) & rp_White==1, bwidth(0.05) )	///
									(kdensity PFS_ppml	if	!mi(PFS_ppml) & inrange(year,1997,2013) & rp_White==0, bwidth(0.05) ),	///
									/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(PFS) ytitle(Density)		///
									name(PFS_rp_race, replace) graphregion(color(white)) bgcolor(white) title(by Race)		///
									legend(lab (1 "White") lab(2 "non-White") rows(1))	
				
				graph	combine	PFS_ind_gender	PFS_rp_race, graphregion(color(white) fcolor(white)) 
				graph	export	"${SNAP_outRaw}/PFS_kdensities.png", replace
				graph	close
		
		
		*	Distribution of food expenditure difference
			
		twoway	(kdensity foodexp_exclFS_diff	[aw=wgt_long_ind]	if	FS_rec_wth==0, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Non-SNAP users"))) 	///
				(kdensity foodexp_exclFS_diff	[aw=wgt_long_ind]	if	FS_rec_wth==1, lc(purple) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "SNAP user"))), 	///
				title("Difference in food expenditure over 2-year") ytitle("Density") xtitle("Food expenditure difference") name(dist_multires_pov_nut, replace)	///
				note(Food expenditure in real dollars. SNAP benefit excluded)
		graph	export	"${SNAP_outRaw}/foodexp_diff_dist.png", as(png) replace
	
		*	Food expenditure normalized at TFP cost.
		twoway	(kdensity foodexp_inclFS_TFP_normal	[aw=wgt_long_ind]	if	FS_rec_wth==1 & inrange(foodexp_inclFS_TFP_normal,-2,2), lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "SNAP users - with benefit"))) 	///
				(kdensity foodexp_exclFS_TFP_normal	[aw=wgt_long_ind]	if	FS_rec_wth==1 & inrange(foodexp_exclFS_TFP_normal,-2,2), lc(purple) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "SNAP users - w/o benefit"))), 	///
				title("Food expenditure normalized at TFP cost") ytitle("Density") xline(0) xtitle("Food expenditure - normalized") name(foodexp_dist_SNAP, replace)
		graph	export	"${SNAP_outRaw}/foodexp_dist_TFP_normal.png", as(png) replace
		
		*	PFS with cutoff
		twoway	(kdensity PFS_ppml			[aw=wgt_long_ind]	if	FS_rec_wth==1, lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "SNAP users - with benefit"))) 	///
				(kdensity PFS_ppml_exclFS	[aw=wgt_long_ind]	if	FS_rec_wth==1, lc(purple) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "SNAP users - w/o benefit"))), 	///
				title("PFS") ytitle("Density") xtitle("PFS") xline(0.45) xlabel(0.25 0.45 "FI Cutoff (0.45)" 0.75 1.0) name(PFS_dist_SNAP, replace)
		graph	export	"${SNAP_outRaw}/PFS_dist.png", as(png) replace
		
		
		*	PFS with different group (full, low-income)
		twoway	(kdensity PFS_ppml	[aw=wgt_long_ind], lc(blue) lp(dash) lwidth(medium) graphregion(fcolor(white)) legend(label(1 "Full sample"))) 	///
				(kdensity PFS_ppml	[aw=wgt_long_ind]	if	income_ever_below_130_9713==1, lc(purple) lp(solid) lwidth(medium) graphregion(fcolor(white)) legend(label(2 "Low-income population"))), 	///
				title("PFS Distribution") ytitle("Density") xtitle("PFS") xline(0.45) xlabel(0.25 0.45 "FI Cutoff (0.45)" 0.75 1.0) name(PFS_dist_SNAP, replace)
		graph	export	"${SNAP_outRaw}/PFS_dist_byinc.png", as(png) replace
				
		
		
		summ	PFS_FI_ppml [aw=wgt_long_ind]
		summ	PFS_FI_ppml [aw=wgt_long_ind] if income_ever_below_130_9713==1
		
		*graph	export	"${results}/multi_resil_pov_nut.png", as(png) replace
		
		*	PFS normalized at 

		
		/*
		local	demovars	rp_NoHS rp_HS rp_somecol rp_col rp_employed rp_disabled famnum ratio_child
		local	moneyvars	
		
		
		summ 	PFS_ppml  	[aw=wgt_long_fam_adj]	if !mi(PFS_ppml) & !mi(PFS_ppml_noCOLI) & inrange(year,1990,2015)
		scalar	mean_PFS	=	r(mean)
		summ	PFS_ppml_noCOLI	[aw=wgt_long_fam_adj]	if !mi(PFS_ppml) & !mi(PFS_ppml_noCOLI) & inrange(year,1990,2015)
		scalar	mean_PFS_noCOLI	=	r(mean)
		di	(mean_PFS-mean_PFS_noCOLI)/mean_PFS
		
		loc	var	diff_PFS_COLI_noCOLI
		cap	drop	`var'
		gen	`var'	=	abs(PFS_ppml-PFS_ppml_noCOLI)
		summ	`var'	[aw=wgt_long_fam_adj]	if	inrange(year,1990,2015),d
		di r(mean)/mean_PFS
		
		graph twoway 	(kdensity PFS_ppml  			if !mi(PFS_ppml) & !mi(PFS_ppml_noCOLI) & inrange(year,1990,2015), graphregion(fcolor(white)) 	legend(label(1 "PFS (non-COLI)")))	///
						(kdensity PFS_ppml_noCOLI 	if !mi(PFS_ppml) & !mi(PFS_ppml_noCOLI) & inrange(year,1990,2015), graphregion(fcolor(white)) 	legend(label(2 "PFS (COLI adjusted)"))),	///
						title(Distribution of PFS - with and w/o COLI)	note(COLI is available since 1990)
		graph	export	"${SNAP_outRaw}/Dist_PFS_COLI.png", as(png) replace
		graph	close
	
		
		*/
			
	
		
		
		*	Use "PFS_noCOLI" as base PFS variable
		*drop	PFS_ppml
		*rename	PFS_ppml_noCOLI	PFS_ppml
		*lab	var	PFS_ppml	"PFS"
		
		*	Keep only observations where citizen ideology IV is available (1977-2015)
		*	(2023-1-15) Maybe I shouldn't do it, because even if IV is available till 2015, we still use PFS in 2017 and 2019 (Iv regression automatically exclude 2017/2019, since there's no IV there.)
		*keep	if	inrange(year,1977,2015) & !mi(citi6016)


		/*
		*	Outcome variables
		summ	PFS_ppml	PFS_FI_ppml
		summ	PFS_ppml PFS_FI_ppml	[aw=wgt_long_ind]
		summ	PFS_ppml PFS_FI_ppml	[aw=wgt_long_ind] if income_ever_below_200_9713==1 &	balanced_9713==1
		
		*	Uniq sample individuals
		unique	x11101ll	if income_ever_below_200_9713==1 &	balanced_9713==1
		
		*	IV: Official SNAP index (unweighted and weighted)	
		summ	SNAP_index_uw SNAP_index_w
		summ	SNAP_index_uw SNAP_index_w	[aw=wgt_long_fam_adj]
		summ	SNAP_index_uw SNAP_index_w	[aw=wgt_long_fam_adj] if income_ever_below_200_9713==1 
		
		
		summ	citi6016	[aw=wgt_long_fam_adj] if income_ever_below_200_9713==1 
		
		*	(Corrlation and bivariate regression of stamp redemption with state/govt ideology)
		pwcorr	FS_rec_wth	citi6016 inst6017_nom 	if	in_sample==1 & inrange(year,1997,2015)  & income_ever_below_200_9713==1,	sig
		reg	FS_rec_wth	citi6016	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)  & income_ever_below_200_9713==1,	///
					robust	cluster(x11101ll) 
		reg	FS_rec_wth	inst6017_nom	[aw=wgt_long_fam_adj]	///
					if	in_sample==1 & inrange(year,1977,2019)  & income_ever_below_200_9713==1,	///
					robust	cluster(x11101ll) 
		
		*/
		
		*	Event study plot
		
			*	Construct interaction terms
			
			
			* Regress PFS on relative time dummies (2-years ago as a baseline)
			*	yit = a0 + a1*1(T=-8) + a2*1(T=-4) + a3*1(T=-2) + a4*1(T=0)
				*	Base category: T=-6
				
				*	Start with OLS, no FE, no controls
				
				*reg	PFS_ppml	year_SNAP_std_l8 year_SNAP_std_l4 year_SNAP_std_l2 year_SNAP_std_l0	[aw=wgt_long_fam_adj]	if	event_study_sample==1	//	all event study sample
								
							
				reg	PFS_ppml	year_SNAP_std_l8 year_SNAP_std_l4 year_SNAP_std_l2 year_SNAP_std_l0	[aw=wgt_long_ind]	if	event_study_sample==1	&	SNAP_cum_fre_1st==1	//	SNAP only once over 5-year period (t-4, t-2 and t)
				est	store	SNAP_once
				
				reg	PFS_ppml	year_SNAP_std_l8 year_SNAP_std_l4 year_SNAP_std_l2 year_SNAP_std_l0	[aw=wgt_long_ind]	if	event_study_sample==1	&	SNAP_cum_fre_1st==2	//	SNAP only twice over 5-year period (t-4, t-2 and t)
				est	store	SNAP_twice
				
				reg	PFS_ppml	year_SNAP_std_l8 year_SNAP_std_l4 year_SNAP_std_l2 year_SNAP_std_l0	[aw=wgt_long_ind]	if	event_study_sample==1	&	SNAP_cum_fre_1st==3	//	SNAP only twice over 5-year period (t-4, t-2 and t)
				est	store	SNAP_thrice
				
				coefplot SNAP_once SNAP_twice	SNAP_thrice, drop(_cons) xline(0) vertical title(PFS after the first SNAP participation)
				graph	export	"${SNAP_outRaw}/Cumul_SNAP_redemp_1st_noctrl.png", replace
				
				*	Control
				reg	PFS_ppml	${FSD_on_FS_X}	${timevars}	year_SNAP_std_l8 year_SNAP_std_l4 year_SNAP_std_l2 year_SNAP_std_l0	[aw=wgt_long_ind]	if	event_study_sample==1	&	SNAP_cum_fre_1st==1	//	all event study sample 
				est	store	SNAP_once_control
				
				reg	PFS_ppml	${FSD_on_FS_X}	${timevars}	year_SNAP_std_l8 year_SNAP_std_l4 year_SNAP_std_l2 year_SNAP_std_l0	[aw=wgt_long_ind]	if	event_study_sample==1	&	SNAP_cum_fre_1st==2	//	all event study sample 
				est	store	SNAP_twice_control
				
				reg	PFS_ppml	${FSD_on_FS_X}	${timevars}	year_SNAP_std_l8 year_SNAP_std_l4 year_SNAP_std_l2 year_SNAP_std_l0	[aw=wgt_long_ind]	if	event_study_sample==1	&	SNAP_cum_fre_1st==3	//	all event study sample 
				est	store	SNAP_thrice_control
			
				coefplot SNAP_once_control SNAP_twice_control	SNAP_thrice_control, keep(year_SNAP_std_l8	year_SNAP_std_l4	year_SNAP_std_l2	year_SNAP_std_l0) xline(0) vertical title(PFS after the first SNAP participation)
				graph	export	"${SNAP_outRaw}/Cumul_SNAP_redemp_1st_ctrl.png", replace
				

	

	
		*	(2023-7-2)
		*	As many things have changed, I am writing this comments to organize my thoughts
		/*	
			1. IV
			We will use the following IVs
				a. SNAP policy index (benchmark IV)
					-	Available period: 1996-2013
					-	unweighted: Easy to interpret (increase in index by 1 implies adopting one more friendly policy), but does not capture relative importance of each policy.
					-	weighted: Not so eaasy to interpret, but captures relative importance of each policy.
				b.	SNAP overpayment rate (if possible)
					-	Available period: 1980-2013, 2017-2019 (2015 is not complete due to quality issue)
				c.	Social spending index
					-	Available period: 1977-2019
			2.	Estimation method
				a.	Classic (OLS in both 1st and 2nd stagethe first)
					-	Can be used for all three IVs above
				b.	Probit/logit in the first stage, and include the predicted variable as an IV in the second stage (benchmark estimation)
					-	Source: https://www.statalist.org/forums/forum/general-stata-discussion/general/1399436-instrumental-variables-with-binary-endogenous-regressor
			3.	Estimations to be done
				a.	policy index only (OLS and MLE)
				b.	SNAP overpayment only (OLS and MLE)
				c.	policy index AND overpayment (OLS and MLE. need to do overidentifying test.)
				d.	social spending index (for full period)
			4.	FE
				a.	No FE
				b.	year FE
				c.	year and individual-FE
				
			
			*	Since there are many specifications/IV/methods/FE to try, let's do one by one
			*	For now (2023-07-02), try SNAP policy index (unweighted and weighted) only. We can gradually test other IVs
				*	SNAP policy index (unweighted, weighted)
					1.	OLS - no FE, state FE and full FE
					2.	IV
						2a.	1st-stage OLS
							-	original IV (Z)
						2b. 1st-stage MLE (i.e. logit)
							-	predicted value (Dhat)
							-	predicted value AND original IV (Z and Dhat)
						(source: https://www.statalist.org/forums/forum/general-stata-discussion/general/1302474-2sls-regression-with-binary-endogenous-variable)
						(address: https://www.statalist.org/forums/forum/general-stata-discussion/general/1399436-instrumental-variables-with-binary-endogenous-regressor)
		
		
			NOTE: Be careful NOT to do "forbidden regression"
			(address: https://twitter.com/jmwooldridge/status/1365119735424307204)
				 a) Using fitted values from a nonlinear first stage as IVs in a linear second stage.
				(b) Finding your high school sweetheart on Facebook.
				(c) Inserting fitted values from a first stage into a nonlinear second stage.
			(source: https://edrub.in/ARE212/section11.html#the_forbidden_regression)
				(a) You use a nonlinear predictor in your first stage, e.g., probit, logit, Poisson, etc. You need linear OLS in the first stage to guarantee that the covariates and fitted values in second stage will be uncorrelated with the error (exogenous).
				(b) Your first stage does not match your second stage, e.g.,
					You use different fixed effects in the two stages
					You use a different functional form of the endogenous covariate in the two stages, e.g., x inn the first stage and x^2 in the second stage.
		
		
		*/	
		
		
		
			*	Set the benchmark specification based on the test above.	
			*	Benchmark specification
			*	But here I inclued "lagged PFS" as Chris suggested, and excluded "statevars" by my own decision. We can further test this specification with different IV/endogenous variable (political status didn't work still)
			*	(2022-11-16) updates
				*	(1) use 'food expenditure' up to the 2nd order as lagged state,
				*	(2) compare b/w with and w/o state FE  (without FE as benchmark)
				*	(3) compare OLS and IV as diagnosis.
			*	(2022-1-22) updates
				*	(1) Use new PFS (which is estimated using new commands, with state, individual- and year-FE)
				*	(2) Use new command (reghdfe, ivreghdfe) - generates same result.
				*	(3) Always include state FE
			*	(2023-7-28) Note: the last benchmark model (SSI as single IV to instrument amount of FS benefit) tested was including "${statevars}" and excluding "lagged PFS"
			*	(2023-8-01) Drop state-FE based on Nico's suggestion.
			*	(2023-10-12) Default control setting: demographic, health, and eduvars only (drop econvars, familyvars, empvars)
			
			*	Set globals
			*global	statevars		l2_foodexp_tot_inclFS_pc_1_real	l2_foodexp_tot_inclFS_pc_2_real 
			global	indvars			/*ind_female*/ age_ind	age_ind_sq /*ind_NoHS ind_somecol*/  ind_col  /* ind_employed_dummy*/
			global	demovars		rp_female	rp_age  rp_age_sq 	rp_nonWhte	rp_married	
			*global	econvars		ln_fam_income_pc_real	
			global	healthvars		rp_disabled
			*global	familyvars		change_RP	//	famnum	ratio_child	
			*global	empvars			rp_employed
			global	eduvars			/*rp_NoHS rp_somecol*/ rp_col
			//global	foodvars		FS_rec_wth
			*global	macrovars		unemp_rate	CPI
			*global	regionvars		rp_state_enum2-rp_state_enum31 rp_state_enum33-rp_state_enum50 	//	Excluding NY (rp_state_enum32) and outside 48 states (1, 52, 53). The latter should be excluded when running regression
			*global	timevars		year_enum4-year_enum11 year_enum14-year_enum30 //	Exclude year_enum3 (1978) as base category. year_enum12 (1990)  and year_enum13 (1991) are excluded due to lack of lagged data.
			global	timevars		year_enum20-year_enum27	//	Using year_enum19 (1997) as a base year, when regressing with SNAP index IV (1996-2013)
		
		
			
			global	FSD_on_FS_X_noind	${demovars}	${healthvars}		${eduvars}		//	${empvars}		${familyvars}	 ${econvars}	 ${regionvars}	${macrovars} 		W/o individual constrols. Default
			global	FSD_on_FS_X_ind		${FSD_on_FS_X_noind}	${indvars}		//	 ${regionvars}	${macrovars} 	With individual controls.		
			global	PFS_est_1st
			global	PFS_est_2nd
			global	PFS_est_1st
			global	PFS_est_2nd	//	This one includes OLS as well.
							
			lab	var	age_ind		"Age (ind)"
			lab	var	age_ind_sq	"Age$^2$ (ind)"
			lab	var	rp_age		"Age (RP) (years)"
			lab	var	rp_age_sq	"Age$^2$ (RP) (years)"
			lab	var	ind_col		"College degree (ind) (=1)"
			lab	var	rp_col		"College degree (RP) (=1)"
			lab	var	FS_rec_wth	"SNAP received"
					
			*	Stationarty test
			local	test_stationary=0
			if	`test_stationary'==1	{
				
				preserve
				
				bys	x11101ll: egen num_col=count(ind_col)	//	Number of non-missing individual college degree obs
				
				*	Keep only strongly balanced units across years (as test requires balanced panel)
				keep if num_nonmiss==9
				keep	if	num_col==9
				xtset	x11101ll	year, delta(2)
				
				*	Test stationarity for each data (w/o trend)
				*	We see that the PFS and HH covariates are stationary, while ind covariates are not.
				foreach var in	PFS_ppml age_ind  /* age_ind_sq */	ind_col	 rp_female	rp_age		rp_age_sq rp_nonWhte rp_married ln_fam_income_pc_real rp_disabled rp_employed famnum ratio_child change_RP rp_col {	
					
					di "var is `var'"
					xtunitroot ht `var'
					
				}	//	var

				*	We test statioarity with trend. (non-stationary w/o trend variables only)
				*	CAUTION: Takes time.
				foreach var in	age_ind  age_ind_sq	ind_col	rp_age_sq	{
					
					di "var is `var'"
					xtunitroot ht `var', trend
					
				}	//	var
				
				
				restore
			}	//	stationarity test
		

			*	IV - Switch between Weighted Policy index, CIM and GIM
				
				*	Setup
				global	depvar		PFS_ppml	// PFS_FI_ppml	//		//					
				global	endovar		FSdummy	//	FSamt_capita
				global	IV			SNAP_index_w	//	citi6016	//	inst6017_nom	//	citi6016	//		//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				global	IVname		SPI_w	//	CIM	//	
				
				*	Sample and weight choice
				loc	income_below130	1	//	Keep only individuals who were ever below 130% income line 
				loc	weighted		1	//	Generate survey-weighted estimates
				loc	control_ind		0	//	Include individual-level controls
				
				*loc	same_RP_9713	0	//	Keep only individuals were same RP over the period
				
				if	`income_below130'==1	{
					
					global	lowincome	&	income_ever_below_130_9713==1	//	Add condition for low-income population.
					*keep if income_ever_below_130_9713==1
				}
				else	{
					
					global	lowincome	//	null macro
					
				}
				
				di	"${lowincome}"
				
				
				*	Weight setting
				if	`weighted'==1	{
					
					global	reg_weight		[pw=wgt_long_ind]
					global	sum_weight		[aw=wgt_long_ind]
				}
				else	{
					
					global	reg_weight		//	null macro
					global	sum_weight		//	null macro
					
				}
				
				*	Individual-level control setting
				if	`control_ind'==1	{
					
					global	FSD_on_FS_X	${FSD_on_FS_X_ind}
					
				}
				else	{
					
					global	FSD_on_FS_X	${FSD_on_FS_X_noind}
					
				}
				
/*
				*	Same RP
				if	`same_RP_9713'==1	{
					keep	if	sameRP_9713==1
				}
				
*/
				
				
					
			*	Construct lagged treatment variables and controls (Will be later imported to "clean.do" file.)
			
				*	Treatment
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
					
				
				*	First we run main IV regression, to use the uniform sample across different FE/specifications
					
					*	All sample (1979-2015)
					global	Z	${IV}
					
					cap	drop reg_sample_all
					ivreghdfe	${depvar}	 ${FSD_on_FS_X}	${timevars}	 (${endovar} = ${Z})	${reg_weight} if	!mi(${Z})	${lowincome},	///
						absorb(/*x11101ll*/	/*ib1997.year*/) robust	cluster(x11101ll) //	first  savefirst savefprefix(${IVname})	 
					gen	reg_sample_all=1 if e(sample)
					lab	var	reg_sample_all "Sample in IV regression (1979-2015)"		
					
					*	1997-2013 sample (for SNAP index)
					global	Z	${IV}
					
					cap	drop reg_sample_9713
					ivreghdfe	${depvar}	 ${FSD_on_FS_X}	/* ${timevars} */	 (${endovar} = ${Z})	${reg_weight} if	inrange(year,1997,2013)	&	!mi(${Z})	${lowincome},	///
						absorb(x11101ll	ib1997.year) robust	cluster(x11101ll) //	first  savefirst savefprefix(${IVname})	 
					gen	reg_sample_9713=1 if e(sample)
					lab	var	reg_sample_9713 "Sample in IV regression (1997-2013)"	
					
					
					*	Mean value of PFS in each sapmle
					*summ	${depvar}	[aw=wgt_long_ind] if	reg_sample_all==1
					summ	${depvar}	[aw=wgt_long_ind] if	reg_sample_9713==1
					
				*	Impute individual-level average covariates over time, using regression sample only (to comply with Wooldridge (2019))
				*	(2023-08-20) Let's think carefully the right way to aggregate time dumies
					
					*	Mundlak var of regressors, including time dummy					
					foreach	samp	in	/*all*/ 9713	{
					
						*	All sample
						cap	drop	*_bar`samp'
						
						
						*	W/o individual controls (default)
						ds	${FSD_on_FS_X} ${timevars}
						foreach	var	in	`r(varlist)'	{
							bys	x11101ll:	egen	`var'_bar`samp'	=	mean(`var')	if	reg_sample_`samp'==1	
						}
						qui	ds	*_bar`samp'
						global	Mundlak_vars_`samp'	`r(varlist)'
						
						
						*	With individaul controls (for contemporaneous effects only)
						ds	${FSD_on_FS_X} ${timevars}
						foreach	var	in	`r(varlist)'	{
							cap	drop	`var'_bar`samp'
							bys	x11101ll:	egen	`var'_bar`samp'	=	mean(`var')	if	reg_sample_`samp'==1	
						}
						qui	ds	*_bar`samp'
						global	Mundlak_vars_`samp'	`r(varlist)'
					
					}
						
					
	
				
				
					
				*	Generate lagged vars of SPI
				foreach	var	in	/*FSdummy_hat*/	SNAP_index_w	{
					
					loc	varlabel:	var	label	`var'
					
					cap	drop	l2_`var'
					gen	l2_`var'	=	l2.`var'
					lab	var	l2_`var'	"(L2) `varlabel'"
					
					cap	drop	l4_`var'
					gen	l4_`var'	=	l4.`var'
					lab	var	l4_`var'	"(L4) `varlabel'"
					
				}	
				
				
				*	OLS
					
					foreach	samp	in	/*all*/	9713	{
						
						*	Mundlak controls, all sample
						reghdfe		${depvar}	 FSdummy ${FSD_on_FS_X}	${timevars}	${Mundlak_vars_`samp'}		${reg_weight} if	reg_sample_`samp'==1	${lowincome},	///
							vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
						estadd	local	HH_controls	"Y"
						estadd	scalar	r2c	=	e(r2)
						summ	PFS_ppml	${sum_weight}	if	reg_sample_`samp'==1
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	mund_ols_`samp'
							
					}
					
				*	Output OLS results
					esttab	/*mund_ols_all*/	mund_ols_9713	using "${SNAP_outRaw}/PFS_${IVname}_OLS.csv", ///
					cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 yearFE, fmt(0 2) label("N" "R2" "Year FE")) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	///
					drop(year_enum*)	title(PFS on SNAP status)		replace	
					
				*	Reduced form
					foreach	samp	in	/*all*/	9713	{
					
						reghdfe		${depvar}	 ${IV} ${FSD_on_FS_X}	${timevars}	${Mundlak_vars}		${reg_weight}	if	reg_sample_`samp'==1	${lowincome},	///
							vce(cluster x11101ll) noabsorb // absorb(ib1997.year)
						est	store	mund_red_${IVname}_`samp'
					
					}
			
					esttab	/*mund_red_${IVname}_all*/	mund_red_${IVname}_9713	using "${SNAP_outRaw}/PFS_${IVname}_reduced.csv", ///
					cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 yearFE, fmt(0 2)	label("N" "R2" "Year FE")) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(year_enum*)	///
					title(PFS on ${IVname})		replace	
		
			
					
				*	2SLS
				
				foreach	samp	in	9713	/*all*/		{
					
					
					*	(1) OLS in the first stage (classic 2SLS)
						global	Z		${IV}	
						global	Zname	${IVname}_Z
						
						ivreghdfe	${depvar}	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_`samp'} 	(FSdummy = ${Z})	${reg_weight} if	reg_sample_`samp'==1	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)		first savefirst savefprefix(${Zname})	partial(*_bar`samp')
						estadd	local	Mundlak	"Y"
						estadd	local	HH_controls	"Y"
						scalar	Fstat_CD_${Zname}	=	 e(cdf)
						scalar	Fstat_KP_${Zname}	=	e(widstat)
						summ	PFS_ppml	${sum_weight}	if	reg_sample_`samp'==1
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	${Zname}_mund_2nd_`samp'
					
						est	restore	${Zname}${endovar}
						estadd	local	Mundlak	"Y"
						estadd	local	HH_controls	"Y"
						estadd	scalar	Fstat_CD	=	Fstat_CD_${Zname}, replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_${Zname}, replace
						summ	FSdummy	${sum_weight}	if	reg_sample_`samp'==1
						estadd	scalar	mean_SNAP	=	 r(mean) 
						est	store	${Zname}_mund_1st_`samp'
						est	drop	${Zname}${endovar}
						
					
					*	(2) Predicted SNAP status
					
						*	We first construct fitted value of the endogenous variable from the first stage using MLE, to be used as an IV
						global	Z		FSdummy_hat	
						global	Zname	${IVname}_Dhat
						
						cap	drop	FSdummy_hat
						logit	FSdummy	${IV}	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_`samp'}	${reg_weight}	if	reg_sample_`samp'==1	${lowincome}, vce(cluster x11101ll) 
						*xtlogit	FSdummy	${IV}	${FSD_on_FS_X}	${timevars}	/*${Mundlak_vars_`samp'}*/  if	reg_sample_`samp'==1, vce(cluster x11101ll) 
						predict	FSdummy_hat
						lab	var	FSdummy_hat	"Predicted SNAP"
						margins, dydx(${IV})
						est	store	logit_SNAP_index
						
						*	2SLS with the predicted value (Dhat) as instrument			
						ivreghdfe	${depvar}	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_`samp'}  	(FSdummy = ${Z})	${reg_weight} if	reg_sample_`samp'==1	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	partial(*_bar`samp')
						estadd	local	Mundlak	"Y"
						estadd	local	HH_controls	"Y"
						scalar	Fstat_CD_${Zname}	=	 e(cdf)
						scalar	Fstat_KP_${Zname}	=	e(widstat)
						summ	PFS_ppml	${sum_weight}	if	reg_sample_`samp'==1
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	${Zname}_mund_2nd_`samp'
					
						est	restore	${Zname}${endovar}
						estadd	local	Mundlak	"Y"
						estadd	local	HH_controls	"Y"
						estadd	scalar	Fstat_CD	=	Fstat_CD_${Zname}, replace
						estadd	scalar	Fstat_KP	=	Fstat_KP_${Zname}, replace
						summ	FSdummy	${sum_weight}	if	reg_sample_`samp'==1
						estadd	scalar	mean_SNAP	=	 r(mean)
						est	store	${Zname}_mund_1st_`samp'
						est	drop	${Zname}${endovar}
						
			
				}
				
				*reg	${depvar}	FSdummy	SNAP_index_w	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713} ${reg_weight} if	reg_sample_9713==1	${lowincome}, cluster (x11101ll)	
				
				/*
				ivreghdfe	${depvar}	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}  	(FSdummy = ${Z})	${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							cluster (x11101ll)	first savefirst savefprefix(${Zname})	partial(*_bar9713)
				*/			
							
				*plausexog	uci		PFS_ppml	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713} 		(FSdummy = FSdummy_hat)	${reg_weight} if reg_sample_9713==1	${lowincome}, cluster (x11101ll) gmin(0) gmax(0) partial(*_bar9713)
				

				*	Save estimates with different names, depending on the inclusion of individual controls
				*	Need to export combined tex file.
				if	`control_ind'==1	{
					
					foreach	stage	in	1st	2nd	{
					
						est	restore	mund_ols_9713
						estadd	local	Ind_control	"Y", replace
						est	store	mund_OLS_ind
						
						est	restore	index_w_Z_mund_`stage'_9713 
						estadd	local	Ind_control	"Y", replace
						est	store	SPI_w_Z_`stage'_ind
						
						est	restore	index_w_Dhat_mund_`stage'_9713 
						estadd	local	Ind_control	"Y", replace
						est	store	SPI_w_Dhat_`stage'_ind
						
					}
					
				}
				else	{
					
					foreach	stage	in	1st	2nd	{
					
						est	restore	mund_ols_9713
						estadd	local	Ind_control	"N", replace
						est	store	mund_OLS_noind
						
						est	restore	index_w_Z_mund_`stage'_9713 
						estadd	local	Ind_control	"N", replace
						est	store	SPI_w_Z_`stage'_noind
						
						est	restore	index_w_Dhat_mund_`stage'_9713 
						estadd	local	Ind_control	"N", replace
						est	store	SPI_w_Dhat_`stage'_noind
						
					}	
					
				}
				
				cap	drop	PFS_FI_ppml_exclFS
				gen			PFS_FI_ppml_exclFS=0	if	!mi(PFS_ppml_exclFS)	&	!inrange(PFS_ppml_exclFS,0,0.45)
				replace		PFS_FI_ppml_exclFS=1	if	!mi(PFS_ppml_exclFS)	&	inrange(PFS_ppml_exclFS,0,0.45)
				
				summ	PFS_ppml	[aw=wgt_long_ind]	if	PFS_FI_ppml==1 & FSdummy==0, d	//	full sample
				summ	PFS_ppml	[aw=wgt_long_ind]	if	PFS_FI_ppml==1  & FSdummy==0 & income_ever_below_130_9713==1, d	//	full sample
				
				summ	PFS_ppml_exclFS	[aw=wgt_long_ind]	if	PFS_FI_ppml_exclFS==1, d	//	full sample
				summ	PFS_ppml_exclFS	[aw=wgt_long_ind]	if	PFS_FI_ppml_exclFS==1 & income_ever_below_130_9713==1, d	//	low-income
				
					*	Tabulate results comparing OLS and IV
												
						
					foreach	Zname	in	index_w	/*CIM	GIM	*/	{
						
						foreach	samp	in	/*all*/	9713	{
						
							*	1st stage
							esttab	`Zname'_Z_mund_1st_`samp' 	`Zname'_Dhat_mund_1st_`samp' 	using "${SNAP_outRaw}/PFS_`Zname'_mund_1st_`samp'.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N mean_SNAP HH_controls Mundlak	Fstat_CD	Fstat_KP, fmt(0 2) label("N" "Mean SNAP" "HH controls" "Mundlak" "F-stat(CD)" "F-stat(KP)" )) ///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
							title(PFS on FS dummy)		replace	
							
							
							esttab	`Zname'_Z_mund_1st_`samp' 	`Zname'_Dhat_mund_1st_`samp' 	using "${SNAP_outRaw}/PFS_`Zname'_mund_1st_`samp'.tex", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N mean_SNAP HH_controls Mundlak	Fstat_CD	Fstat_KP, fmt(0 2) label("N" "Mean SNAP" "HH controls" "Mundlak" "F-stat(CD)" "F-stat(KP)" )) ///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
							title(PFS on FS dummy)		replace								
						
						*	2nd stage 
															
							*	SNAP index
							esttab	mund_ols_`samp' 	`Zname'_Z_mund_2nd_`samp'  	`Zname'_Dhat_mund_2nd_`samp' 	using "${SNAP_outRaw}/PFS_`Zname'_mund_2nd_`samp'.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2c mean_PFS HH_controls Mundlak Fstat_CD	Fstat_KP , fmt(0 2) label("N" "R2" "Mean PFS" "HH controls" "Mundlak" "F-stat(CD)" "F-stat(KP)"))	///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* )	///
							title(PFS on FS dummy)		replace	
							
							esttab	mund_ols_`samp' 	`Zname'_Z_mund_2nd_`samp'  	`Zname'_Dhat_mund_2nd_`samp' 	using "${SNAP_outRaw}/PFS_`Zname'_mund_2nd_`samp'.tex", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2c mean_PFS HH_controls Mundlak Fstat_CD	Fstat_KP, fmt(0 2) label("N" "R2" "Mean PFS" "HH controls" "Mundlak" "F-stat(CD)" "F-stat(KP)")) ///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* )	///
							title(PFS on FS dummy)		replace	
						}
			
					}

					
					
					
				*	Output combined 1st-stage table (with and w/o individual controls)		
					
					*	1st stage
					esttab	SPI_w_Z_1st_noind	SPI_w_Z_1st_ind	SPI_w_Dhat_1st_noind	SPI_w_Dhat_1st_ind 	using "${SNAP_outRaw}/PFS_weakIV.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N mean_SNAP Ind_control	HH_controls Mundlak	Fstat_CD	Fstat_KP, fmt(0 2) label("N" "Mean SNAP" "Individual Controls" "HH controls" "Mundlak" "F-stat(CD)" "F-stat(KP)" )) ///
						incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
						
					esttab	SPI_w_Z_1st_noind	SPI_w_Z_1st_ind	SPI_w_Dhat_1st_noind	SPI_w_Dhat_1st_ind 	using "${SNAP_outRaw}/PFS_weakIV.tex", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N mean_SNAP  Ind_control	Fstat_KP, fmt(0 2) label("N" "Mean SNAP" "Individual controls" "F-stat(KP)" )) ///
						incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(SNAP_index_w	FSdummy_hat)	///
						title(SNAP on SPI)	note(Household-level controls, year FE and correlated random effects (CRE) are included in all specifications. Household-level controls include RP’s characteristics (gender, age, race, marital status, college degree) and household characteristics (household size, \% of children and income, whether RP changed). Individual-level controls include individual's age and college degree status. CRE are partialled out. Estimates are adjusted with longitudinal individual survey weight provided in the PSID. Standard errors are clustered at individual-level.)	replace	
						
					*	2nd stage
					esttab	mund_OLS_noind	mund_OLS_ind	SPI_w_Z_2nd_noind	SPI_w_Z_2nd_ind		SPI_w_Dhat_2nd_noind	SPI_w_Dhat_2nd_ind 	using "${SNAP_outRaw}/PFS_on_FS_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N mean_SNAP Ind_control	HH_controls Mundlak	Fstat_CD	Fstat_KP, fmt(0 2) label("N" "Mean SNAP" "Individual Controls" "HH controls" "Mundlak" "F-stat(CD)" "F-stat(KP)" )) ///
						incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(PFS on FS dummy)		replace	
						
					esttab	mund_OLS_noind	mund_OLS_ind	SPI_w_Z_2nd_noind	SPI_w_Z_2nd_ind		SPI_w_Dhat_2nd_noind	SPI_w_Dhat_2nd_ind  	using "${SNAP_outRaw}/PFS_on_FS_2nd.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_PFS  Ind_control, fmt(0 2) label("N" "R$^2$" "Mean SNAP" "Individual controls" )) ///
						incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(FSdummy /*age_ind       ind_col*/)	///
						title(SNAP on SPI)	note(Household-level controls, year FE and correlated random effects (CRE) are included in all specifications. Household-level controls include RP’s characteristics (gender, age, race, marital status, college degree) and household characteristics (household size, \% of children and income, whether RP changed). Individual-level controls include individual's age and college degree status. CRE are partialled out. Estimates are adjusted with longitudinal individual survey weight provided in the PSID. Standard errors are clustered at individual-level.)	replace	

			
			*	Heterogeneous effects
			
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
						ivreghdfe	PFS_ppml	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}  	(FSdummy SNAP_female	= FSdummy_hat	SNAPhat_female)	${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(female)  // partial(*_bar9713)
						estadd	local	Mundlak		"Y"
						estadd	local	Controls	"Y"
						local	Fstat_KP: di % 9.2f e(widstat)
						estadd	local	Fstat_KP	=	`Fstat_KP'
						summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	hetero_2nd_female
						
	
					*	NoHS	
						ivreghdfe	PFS_ppml	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}  	(FSdummy SNAP_NoHS	= FSdummy_hat	SNAPhat_NoHS)	${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(NoHS)	partial(*_bar9713)
						estadd	local	Mundlak	"Y"
						estadd	local	Controls	"Y"
						local	Fstat_KP: di % 9.2f e(widstat)
						estadd	local	Fstat_KP	=	`Fstat_KP'
						summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	hetero_2nd_NoHS
					
					*	NonWhte	
						ivreghdfe	PFS_ppml	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}  	(FSdummy SNAP_nonWhte	= FSdummy_hat	SNAPhat_nonWhte)	${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(nonWhte)	partial(*_bar9713)
						estadd	local	Mundlak	"Y"
						estadd	local	Controls	"Y"
						local	Fstat_KP: di % 9.2f e(widstat)
						estadd	local	Fstat_KP	=	`Fstat_KP'
						summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	hetero_2nd_nonWhte
						
					*	Disabled	
						ivreghdfe	PFS_ppml	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}  	(FSdummy SNAP_disabled	= FSdummy_hat	SNAPhat_disabled)	${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(disab)	partial(*_bar9713)
						estadd	local	Mundlak	"Y"
						estadd	local	Controls	"Y"
						local	Fstat_KP: di % 9.2f e(widstat)
						estadd	local	Fstat_KP	=	`Fstat_KP'
						summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	hetero_2nd_disab
						
					*	All combined
						ivreghdfe	PFS_ppml	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}  ///
							(FSdummy SNAP_female	SNAP_NoHS	SNAP_nonWhte	SNAP_disabled	= FSdummy_hat	SNAPhat_female	SNAPhat_NoHS	SNAPhat_nonWhte	SNAPhat_disabled)	///
							${reg_weight} if	reg_sample_9713==1	${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(disab)	partial(*_bar9713)
						estadd	local	Mundlak	"Y"
						estadd	local	Controls	"Y"
						local	Fstat_KP: di % 9.2f e(widstat)
						estadd	local	Fstat_KP	=	`Fstat_KP'
						summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
						estadd	scalar	mean_PFS	=	 r(mean)
						est	store	hetero_2nd_all
						
					*	Export
						esttab	hetero_2nd_female 	hetero_2nd_NoHS  	hetero_2nd_nonWhte	hetero_2nd_disab	hetero_2nd_all 	using "${SNAP_outRaw}/PFS_on_SNAP_hetero.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2c mean_PFS YearFE Mundlak 	Fstat_KP, fmt(0 2) label("N" "R2" "Mean PFS" "Year FE" "Mundlak" "F-stat(KP)"))	///
						incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* ) order(FSdummy SNAP_female	SNAP_NoHS	SNAP_nonWhte	SNAP_disabled)	///
						title(PFS on FS dummy hetero)		replace	
						
						esttab	hetero_2nd_female 	hetero_2nd_NoHS  	hetero_2nd_nonWhte	hetero_2nd_disab	hetero_2nd_all 	using "${SNAP_outRaw}/PFS_on_SNAP_hetero.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_PFS	/* Controls */ 	Fstat_KP, fmt(0 2) label("N" "R2" "Mean PFS" /*  "Controls" */ "F-stat(KP)")) ///
						incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	///
						keep(FSdummy SNAP_female	SNAP_NoHS	SNAP_nonWhte	SNAP_disabled) order(FSdummy SNAP_female	SNAP_NoHS	SNAP_nonWhte	SNAP_disabled)	///
						title(PFS on SNAP - heterogeneous effects)	note(Note: Household-level controls, year FE and correlated random effects (CRE) are included in all specifications. Household-level controls include RP’s characteristics (gender, age, race, marital status, college degree) and household characteristics (household size, \% of children and income, whether RP changed). Individual-level controls are not included. CRE are partialled out. Estimates are adjusted with longitudinal individual survey weight provided in the PSID. Standard errors are clustered at individual-level.)	replace	
		
	
	
	
	
	
	
	
	
	
	
	
	
	
	
			
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
					
					ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_`lag'}	${timevars}	${Mundlak_vars_9713}  	(${endoX} = ${Z})	${reg_weight} if	reg_sample_9713==1 ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first savefirst savefprefix(${Zname})	partial(*_bar9713) 
								
					estadd	local	Mundlak	"Y"
					estadd	local	YearFE	"Y"
					estadd	scalar	Fstat_CD	=	 e(cdf)
					estadd	scalar	Fstat_KP	=	e(widstat)
					summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
					estadd	scalar	mean_PFS	=	 r(mean) 
					est	store	${Zname}_`lag'_2nd_lowinc
					
				
				}
				
				global	Zname	SNAPhat
				
				*	SNAP (t-4, t-2) effects on PFS
				*	Use control in t-4 only
				ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_l4}	${timevars}	${Mundlak_vars_9713}  	(l4_FSdummy	l2_FSdummy  = l4_SNAPhat	l2_SNAPhat)	${reg_weight} if	reg_sample_9713==1 ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	partial(*_bar9713) 
							
				estadd	local	Mundlak	"Y"
				estadd	local	YearFE	"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				*scalar	Fstat_KP_${Zname}	=	e(rkf)
				estadd	scalar	Fstat_KP	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_l42_2nd_lowinc
				
				
				*	SNAP (t-2, t) effects on PFS
				*	Use control in t-2 only
				ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_l2}	${timevars}	${Mundlak_vars_9713}  	(l2_FSdummy	l0_FSdummy  = l2_SNAPhat	l0_SNAPhat)	${reg_weight} if	reg_sample_9713==1 ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	partial(*_bar9713) 				
				estadd	local	Mundlak	"Y"
				estadd	local	YearFE	"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				*scalar	Fstat_KP_${Zname}	=	e(rkf)
				estadd	scalar	Fstat_KP	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_l20_2nd_lowinc
				
				
				*	SNAP (t-4, t-2, t-0) effects on PFS
				*	Use control in t-4 only
					*	Controls in t-4 only
				ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_l4}	${timevars}	${Mundlak_vars_9713}  	(l4_FSdummy	l2_FSdummy	l0_FSdummy  = l4_SNAPhat	l2_SNAPhat	l0_SNAPhat)	${reg_weight} if	reg_sample_9713==1 ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	partial(*_bar9713) 
							
				estadd	local	Mundlak	"Y"
				estadd	local	YearFE	"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				*scalar	Fstat_KP_${Zname}	=	e(rkf)
				estadd	scalar	Fstat_KP	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_l420_2nd_lowinc
				
				
				
				*	SNAP (t-6, t-4, t-2, t-0) effects on PFS
				*	Use control in t-6 only
				ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_l6}	${timevars}	${Mundlak_vars_9713}  	(l6_FSdummy	l4_FSdummy	l2_FSdummy	l0_FSdummy  = l6_SNAPhat	l4_SNAPhat	l2_SNAPhat	l0_SNAPhat)	${reg_weight} if	reg_sample_9713==1 ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	partial(*_bar9713) 
							
				estadd	local	Mundlak	"Y"
				estadd	local	YearFE	"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				*scalar	Fstat_KP_${Zname}	=	e(rkf)
				estadd	scalar	Fstat_KP	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_l6420_2nd_lowinc
				
				
/*
				*	SNAP (t-4, t-2, t-0) effects on PFS
					*	Full controls over 5-years
					*	For covariates that is less likely to be time-variant, I include only those at t-4 (i.e. age, gender, education)
					*	For covariates that is more likely to be time-variant, I include them across all perios (i.e. income, )
					*	(2023-09-21) Just use t-4 controls only
				global	FSD_on_FS_X_5yr	age_ind	age_ind_sq ind_col	///
										rp_female	rp_age rp_age_sq	rp_nonWhte	rp_married	rp_col	rp_employed	rp_disabled	famnum	ratio_child	change_RP	ln_fam_income_pc_real	///
										l2.rp_female	l2.rp_age l2.rp_age_sq	l2.rp_nonWhte	l2.rp_married	l2.rp_col	l2.rp_employed	l2.rp_disabled	l2.famnum	l2.ratio_child	l2.change_RP	l2.ln_fam_income_pc_real	///
										l4.rp_female	l4.rp_age l4.rp_age_sq	l4.rp_nonWhte	l4.rp_married	l4.rp_col	l4.rp_employed	l4.rp_disabled	l4.famnum	l4.ratio_child	l4.change_RP	l4.ln_fam_income_pc_real	
										

				di	"${FSD_on_FS_X_5yr}"
					
				ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_l}	/* ${FSD_on_FS_X_5yr} */	${timevars}	${Mundlak_vars_9713}  	(l4_FSdummy	l2_FSdummy	l0_FSdummy  = l4_SNAPhat	l2_SNAPhat	l0_SNAPhat)	${reg_weight} if	reg_sample_9713==1 ${lowincome}, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})	partial(*_bar9713) 
							
				estadd	local	Mundlak	"Y"
				estadd	local	YearFE	"Y"
				scalar	Fstat_CD_${Zname}	=	 e(cdf)
				*scalar	Fstat_KP_${Zname}	=	e(rkf)
				estadd	scalar	Fstat_KP	=	e(widstat)
				summ	PFS_ppml	${sum_weight}	if	reg_sample_9713==1 ${lowincome}
				estadd	scalar	mean_PFS	=	 r(mean)
				est	store	${Zname}_l4l2l0_allX_2nd
				
				
*/
				*	2nd stage only
					esttab		${Zname}_l8_2nd_lowinc ${Zname}_l6_2nd_lowinc  ${Zname}_l4_2nd_lowinc	 ${Zname}_l2_2nd_lowinc	${Zname}_l0_2nd_lowinc	///
								${Zname}_l42_2nd_lowinc	${Zname}_l20_2nd_lowinc	${Zname}_l420_2nd_lowinc	${Zname}_l6420_2nd_lowinc		using "${SNAP_outRaw}/PFS_${Zname}_2nd_lags.csv", ///
					cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2c mean_PFS YearFE Mundlak Fstat_CD	Fstat_KP , fmt(0 2) label("N" "R2" "Mean PFS" "Year FE" "Mundlak" "F-stat(CD)" "F-stat(KP)"))	///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum* )	order(l0_FSdummy	l2_FSdummy	l4_FSdummy l6_FSdummy	l8_FSdummy)	///
					title(PFS on Lagged FS dummy)		replace	
		
		
					esttab	 ${Zname}_l6_2nd  ${Zname}_l4_2nd	 ${Zname}_l2_2nd	${Zname}_l0_2nd 	/*${Zname}_l4l2_2nd	${Zname}_l2l0_2nd	${Zname}_l4l2l0_2nd	${Zname}_l6l4l2l0_2nd	${Zname}_l4l2l0_allX_2nd*/	using "${SNAP_outRaw}/PFS_${Zname}_2nd_lags.tex", ///
					cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2c mean_PFS YearFE  Fstat_KP , fmt(0 2) label("N" "R$^2$" "Mean PFS" "Controls" "F-stat(KP)"))	///
					incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	keep(l0_FSdummy	l2_FSdummy	l4_FSdummy l6_FSdummy )	order(l0_FSdummy	l2_FSdummy	l4_FSdummy l6_FSdummy	l8_FSdummy)	///
					title(PFS on Lagged FS dummy)		replace	
				
				est	restore	${Zname}_l6l4l2l0_2nd
				test	l6_FSdummy + l4_FSdummy + l2_FSdummy + l0_FSdummy=0
				
				est	restore	${Zname}_l4l2l0_2nd
				test	 l4_FSdummy + l2_FSdummy + l0_FSdummy=0
				
				
				
				*	Coefplot of IR coefficients
				*	(NOTE: I should run IR seprately, one for full sample and one for low-inc sample, and save with "_full" and "_lowinc" prefix.)
				coefplot 	${Zname}_l0_2nd_full ${Zname}_l2_2nd_full ${Zname}_l4_2nd_full ${Zname}_l6_2nd_full, bylabel(Full sample) ||	///
			${Zname}_l0_2nd_lowinc	${Zname}_l2_2nd_lowinc ${Zname}_l4_2nd_lowinc	${Zname}_l6_2nd_lowinc, bylabel(Low-income population) ||,	///
			keep(l0_FSdummy l2_FSdummy l4_FSdummy l6_FSdummy) byopts(compact cols(1) legend(off)) vertical // title(Lagged SNAP Effects on PFS)
				graph	export	"${SNAP_outRaw}/IR_full_lowinc.png", as(png) replace
				
				
				
				logit	FSdummy	${IV}	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}	${reg_weight}		if	reg_sample_9713==1	${lowincome}, vce(cluster x11101ll) 
				logit	FSdummy	${IV}	${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}	${logit_weight_uw} 	if	reg_sample_9713==1 /* & income_ever_below_130_9713==1 */,  vce(cluster x11101ll) 
				
				
				
				
			
			
			
				
				
				
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
					
				foreach	depvar	in	SL_5	TFI0	CFI0	TFI1	CFI1	TFI2	CFI2	{	
				
				
								
					ivreghdfe	`depvar'	 ${FSD_on_FS_X_l4} 	${timevars}	${Mundlak_vars_9713}  (l4_FSdummy = l4_SNAPhat )	${reg_weight} if	reg_sample_9713==1  ${lowincome} , ///
								/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})  partial(*_bar9713)
					
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
				
			
		
				
				
				
				
				
				
				
				
					*	Create dummies for each SNAP usage (5-year)
				*	(2023-09-22) Chris told me to use cumulative usage, NOT continuous usage.
				cap	drop	SNAP_cum_5_?
				tab SNAP_cum_fre_5, gen(SNAP_cum_5_)
				rename	(SNAP_cum_5_1	SNAP_cum_5_2	SNAP_cum_5_3	SNAP_cum_5_4)	(SNAP_cum_5_0	SNAP_cum_5_1	SNAP_cum_5_2	SNAP_cum_5_3)
				lab	var	SNAP_cum_5_0	"No SNAP over 5-year"
				lab	var	SNAP_cum_5_1	"SNAP once over 5-year"
				lab	var	SNAP_cum_5_2	"SNAP twice over 5-year"
				lab	var	SNAP_cum_5_3	"SNAP thrice over 5-year"
				
				
				
			
				*	Run logistic regression, looping over weights
				global	logit_weight_uw
				global	logit_weight_w	 [pw=wgt_long_ind]
					
				
				foreach	weight	in	uw w	{
						
						
						*	Contemporaneous
							*	LHS: SNAP_it
							*	RHS: SPI and X_it
						
						cap	drop	SNAPhat_`weight'
						logit	FSdummy	${IV}	 ${FSD_on_FS_X}	${timevars}	${Mundlak_vars_9713}	${logit_weight_`weight'} 	if	reg_sample_9713==1 /* & income_ever_below_130_9713==1 */,  vce(cluster x11101ll) 
						estadd	local	Mundlak	"Y"
						estadd	local	YearFE	"Y"
						est	store	SNAPhat_`weight'
						predict	SNAPhat_`weight'
						lab	var	SNAPhat_`weight'	"Predicted SNAP (`weight')"
						*margins, dydx(${IV}	${FSD_on_FS_X}) post
						*est	store	SNAPhat_dydx_uw
						
						*	SNAP only once (t-4) over 5-year period (binary)
						*	RHS: SPI_t-4, SPI_t-2, SPI_t, controls over 5-year period, time dummies, Mundlak
						cap	drop	SNAP1hat_`weight'
						logit	SNAP_cum_5_1	l4_${IV}	l2_${IV}	${IV}	${FSD_on_FS_X_5yr}	${timevars}	${Mundlak_vars_9713} ${logit_weight_`weight'}	if	reg_sample_9713==1 /* & income_ever_below_130_9713==1 */, vce(cluster x11101ll)
						estadd	local	Mundlak	"Y"
						estadd	local	YearFE	"Y"
						est	store	SNAP1hat_`weight'
						predict	SNAP1hat_`weight'
						lab	var	SNAP1hat_`weight'	"(Predicted) SNAP once over 5-year"
						
						*	SNAP twice (t-4, t-2) over 5-year period (binary)
						*	RHS: SPI_t-4, SPI_t-2, SPI_t, controls over 5-year period, time dummies, Mundlak
						cap	drop	SNAP2hat_`weight'
						logit	SNAP_cum_5_2	l4_${IV}	l2_${IV}	${IV} ${FSD_on_FS_X_5yr}	${timevars}	${Mundlak_vars_9713} 	${logit_weight_`weight'}	if	reg_sample_9713==1 /* & income_ever_below_130_9713==1 */, vce(cluster x11101ll)
						estadd	local	Mundlak	"Y"
						estadd	local	YearFE	"Y"
						est	store	SNAP2hat_`weight'
						predict	SNAP2hat_`weight'
						lab	var	SNAP2hat_`weight'	"(Predicted) SNAP twice over 5-year"
						
						*	SNAP thrice (t-4, t-2, t-2) over 5-year period (binary)
						*	RHS: SPI_t-4, SPI_t-2, SPI_t, controls over 5-year period, time dummies, Mundlak
						cap	drop	SNAP3hat_`weight'
						logit	SNAP_cum_5_3	l4_${IV}	l2_${IV}	${IV}	 ${FSD_on_FS_X_5yr}	${timevars}	${Mundlak_vars_9713} 	${logit_weight_`weight'}	if	reg_sample_9713==1 /* & income_ever_below_130_9713==1 */, vce(cluster x11101ll)
						estadd	local	Mundlak	"Y"
						estadd	local	YearFE	"Y"
						est	store	SNAP3hat_`weight'
						predict	SNAP3hat_`weight'
						lab	var	SNAP3hat_`weight'	"(Predicted) SNAP twice over 5-year"

				}
					
			
					
/*
					*	Comtemporary SNAP redemption
					esttab	SNAPhat_logit  	 	SNAPhat_logit_dydx	///
							using "${SNAP_outRaw}/SNAP_index_MLE_logit.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2_p YearFE Mundlak Fstat_CD	Fstat_KP pval_Jstat, fmt(0 2) label("N" "R2" "Year FE" "Mundlak" "F-stat(CD)" "F-stat(KP)" "p-val(J-stat)"))	///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop( year_enum* *bar9713 ) /*order(l4_${IV}	l2_${IV}	${IV})*/	///
							title(SNAP on SPI)		replace
					
					*	Cumulative SNAP redemption
					esttab	/*SNAPhat_logit*/  	SNAP1hat_logit  SNAP2hat_logit  SNAP3hat_logit  		///
							using "${SNAP_outRaw}/SNAPcum_index_MLE_logit.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2_p YearFE Mundlak Fstat_CD	Fstat_KP pval_Jstat, fmt(0 2) label("N" "R2" "Year FE" "Mundlak" "F-stat(CD)" "F-stat(KP)" "p-val(J-stat)"))	///
							incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop( year_enum* *bar9713 ) /*order(l4_${IV}	l2_${IV}	${IV})*/	///
							title(Cumulative SNAP on SPI)		replace	
				
*/
				
				*	Benchmark: Everything on the RHS is only at t-4
					*	Outcome: FSD over 3 period (t-4, t-2, t)
					*	Endovar: SNAPhat in t-4 only (benchmark does not include SNAP in t-2 or t)
					*	Z: SPI in t-4
					*	Controls: X in t-4
					
					
						*	Generate lagged vars
					foreach	var	in	 SNAPhat_uw 	SNAPhat_w	{
						
						loc	varlabel:	var	label	`var'
						
						cap	drop	l2_`var'
						gen	l2_`var'	=	l2.`var'
						lab	var	l2_`var'	"(L2) `varlabel'"
						
						cap	drop	l4_`var'
						gen	l4_`var'	=	l4.`var'
						lab	var	l4_`var'	"(L4) `varlabel'"
						
					}	
					
					/*
					*	(2023-08-25) About 11% of 97-13 balanced sample have RP changed (rp_change), so the only time-invarying variable is individual age/college. Not sure it is worth it....
					*	Set global for X such that
						*	(i) If time-varying, include across the periods
						*	(ii) If time-invarying, include only in t-4
						
						di	"${FSD_on_FS_X}"
					foreach	var	of	global	FSD_on_FS_X	{
					    
					}
					*/
					
					
					//global	depvar		TFI_HCR_5	//		SL_5	//	CFI2_5	//		TFI2_5	//	CFI_FIG_5	//	TFI_FIG_5	//	CFI_HCR_5	//		
					global	FSD_results
					global	Z	FSdummy
					
					graph	twoway	(kdensity	l4_FSdummy)	(kdensity	l4_SNAPhat_uw)
								
					ivreghdfe	PFS_ppml	 ${FSD_on_FS_X_l4} 	${timevars}	${Mundlak_vars_9713}  (l4_FSdummy = l4_SNAP_index_w /* l4_SNAPhat_uw */)	/*[aw=wgt_long_ind]*/ if	reg_sample_9713==1 & income_ever_below_130_9713==1, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})  partial(*_bar9713)
					
					
					foreach	depvar	in	SL_5	TFI_HCR_5	CFI_HCR_5	TFI_FIG_5	CFI_FIG_5	TFI2_5	CFI2_5	{
									
						*	SNAP on t-4 only
						global	Z		l4_SNAPhat_uw
						global	Zname	l4_SNAPhat_uw
						global	endoX	l4_${endovar}
						
						
						ivreghdfe	`depvar'	 ${FSD_on_FS_X_l4}	${timevars}	${Mundlak_vars_9713}  (${endoX} = ${Z})	/*[aw=wgt_long_ind]*/ if	reg_sample_9713==1 /* & income_ever_below_130_9713==1 */, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})  partial(*_bar9713)
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
						
						*	Cumulative (continuous) SNAP participation dummies
						global	Z		SNAP1hat_uw	SNAP2hat_uw	SNAP3hat_uw
						global	Zname	cumSNAPhat_uw
						global	endoX	SNAP_cum_5_1	SNAP_cum_5_2	SNAP_cum_5_3	
						
						
						ivreghdfe	`depvar'	 ${FSD_on_FS_X_l4}		${timevars}	${Mundlak_vars_9713}  (${endoX} = ${Z})	/*[aw=wgt_long_ind]*/ if	reg_sample_9713==1  /* & income_ever_below_130_9713==1 */, ///
							/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${Zname})  partial(*_bar9713)
						estadd	local	Mundlak	"Y"
						estadd	local	YearFE	"Y"
						scalar	Fstat_CD_${Zname}		=	e(cdf)
						scalar	Fstat_KP_${Zname}		=	e(widstat)
						est	store	`depvar'_${Zname}_2nd
						
						global	FSD_results	${FSD_results}	`depvar'_${Zname}_2nd
						esttab	`depvar'_l4_SNAPhat_uw_2nd	 	`depvar'_cumSNAPhat_uw_2nd	using "${SNAP_outRaw}/`depvar'_index_uw_2nd.csv", ///
								cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2_c YearFE Mundlak Fstat_CD	Fstat_KP pval_Jstat, fmt(0 2) label("N" "R2" "Year FE" "Mundlak" "F-stat(CD)" "F-stat(KP)" "p-val(J-stat)"))	///
								incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	 drop( year_enum* /**bar9713*/ )  order(l4_FSdummy	SNAP_cum_5_1	SNAP_cum_5_2	SNAP_cum_5_3)	///
								title(`depvar' on SNAP)		replace
					
					
					}
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					
					*	IVregress
				
					*	(i) RHS: treatment and controls at l4 only (FSD_t = a0 + a1*FS_t-4 + a2*X_t-4 + ...)
						*	Since Mundlak in individual-level average over time, we don't need lag.
					loc	depvar		`FSD'
					loc	endovar		l4_FSdummy	//	SNAP in t-4
					loc	IV			l4_SNAP_index_w	l4_FSdummy_hat		//	Z and Dhat in t-4
					loc	IVname		l4
				
					
					ivreghdfe	${depvar}	${FSD_on_FS_X_l4}	${timevars}	${Mundlak_vars} (${endovar} = ${IV})	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
						/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${IVname})	  partial(*_bar)
					
					est	store	${depvar}_${IVname}_2nd
					scalar	Fstat_CD_${IVname}	=	e(cdf)
					scalar	Fstat_KP_${IVname}	=	e(widstat)
					estadd	scalar	Fstat_CD	=	Fstat_CD_${IVname}, replace
					estadd	scalar	Fstat_KP	=	Fstat_KP_${IVname}, replace
					est	store	${depvar}_${IVname}_2nd
			
					est	restore	${IVname}${endovar}
					estadd	scalar	Fstat_CD	=	Fstat_CD_${IVname}, replace
					estadd	scalar	Fstat_KP	=	Fstat_KP_${IVname}, replace
					est	store	${depvar}_${IVname}_1st
					est	drop	${IVname}${endovar}
					
		
					*	(ii) RHS: treatment and controls at all periods. (t-4, t-2, t)
					loc	depvar		`FSD'
					loc	endovar		l4_FSdummy	l2_FSdummy	FSdummy	//	SNAP in t-4
					loc	IV			l4_SNAP_index_w	l4_FSdummy_hat	l2_SNAP_index_w	l2_FSdummy_hat	SNAP_index_w	FSdummy_hat	//	Z and Dhat in t-4
					loc	IVname		alllag
					
					ivreghdfe	${depvar}	${FSD_on_FS_X_l4l2}	${FSD_on_FS_X}	${timevars}	${Mundlak_vars} (${endovar} = ${IV})	[aw=wgt_long_fam_adj] if	reg_sample==1, ///
						/*absorb(x11101ll)*/	cluster (x11101ll)	first savefirst savefprefix(${IVname})	  partial(*_bar)
					
									
					est	store	${depvar}_${IVname}_2nd
					scalar	Fstat_CD_${IVname}	=	e(cdf)
					scalar	Fstat_KP_${IVname}	=	e(widstat)
					
					estadd	scalar	Fstat_CD	=	Fstat_CD_${IVname}
					estadd	scalar	Fstat_KP	=	Fstat_KP_${IVname}
					est	store	${depvar}_${IVname}_2nd
					
					*	Retrieve first-stage F-stat for each endovar
					*	Since there are multiple endogenous variable, we need to loop for each first-stage regression
					loc	i=1	//	counter for retrieving weak IV stat
					foreach	var	of	loc	endovar	{
						
						scalar	Fstat_SWF_`var'	=	e(first)[8,`i']
						loc	i	=	`i'+1
					}
				
					*	Save F-stat to each first-stage stored.		
					*	NOTE: DO NOT combine the loop above (retireving F-stat) and the loop below (adding F-stat to stored estimate). It is because once estimate is restored, e(first) table will be gone.
					foreach	var	of	loc	endovar	{
						di	"endovar is `var'"
						est	restore	${IVname}`var'
						estadd	scalar	Fstat_SWF	=	Fstat_SWF_`var'
						est	store	${depvar}_${IVname}`var'_1st
						est	drop	${IVname}`var'
					}
				
				
				*	Export
					
					*	1st stage
					esttab	`FSD'_l4_1st	`FSD'_alllagl4_FSdummy_1st	`FSD'_alllagl2_FSdummy_1st	`FSD'_alllagFSdummy_1st	///
						using "${SNAP_outRaw}/`FSD'_1st.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 Fstat_CD	Fstat_KP	Fstat_SWF, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(`FSD' on FS dummy)		replace	
				
					*	2nd stage (Z, Dhat, Z and Dhat)
					esttab	`FSD'_l4_2nd	`FSD'_alllag_2nd	///
						using "${SNAP_outRaw}/`FSD'_2nd.csv", ///
						cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2 Fstat_CD	Fstat_KP, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	drop(/*rp_state_enum**/ year_enum*)	///
						title(`FSD' on FS dummy)		replace	
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				
				*	Choose which endogeneous variable/IV to use
				*	Make sure to turn on/off both variable and associated names.
				global	endovar	FSdummy	//	participation dummy
					global	endovarname	dummy
				*global	endovar	FSamtcp	//	amount received per capita (in real)
				*	global	endovarname	amtcap
				
				cap	drop	citi0to1
				clonevar	citi0to1	=	citi6016_0to1
				
				global	IV	citi0to1	//	SSI
					global	IVname citi
				*global	IV	SNAP_index_w
					*global	IVname	index
					
				cap	drop	FS_amt_real
				cap	drop	FS_amt_realK
				clonevar	FS_amt_real		=	FS_rec_amt_real
				gen			FS_amt_realK	=	FS_rec_amt_real	/	1000
				lab	var	FS_amt_realK	"FS amount (K)"
					
			foreach	FSDvar	in	/*SL_5 TFI_HCR	CFI_HCR*/	TFI_FIG	CFI_FIG	TFI_SFIG	CFI_SFIG		{
				
				global	depvar	`FSDvar'
				
				*global	${depvar}_${endovarname}_${IVname}_est_1st	
				*global	${depvar}_${endovarname}_${IVname}_est_2nd	
				
										
					*	Static, state and individual FE
					*loc	endovar	FS_rec_amt_real
					*loc	IV		SSI_GDP_sl
					loc	model	${depvar}_${endovarname}_${IVname}
					ivreghdfe	${depvar}	 ${FSD_on_FS_X}	 (${endovar}	=	${IV})	[aw=wgt_long_fam_adj] if	income_below_200==1 &	!mi(${IV}) & reg_sample==1,	///
							absorb(ib31.rp_state x11101ll) robust first savefirst savefprefix(`model')	 
					est	store	`model'_2nd
					scalar	Fstat_`model'	=	e(widstat)
					est	restore	`model'${endovar}
					estadd	scalar	Fstat	=	Fstat_`model', replace
					est	store	`model'_1st
					est	drop	`model'${endovar}
										
					*global	${depvar}_${endovarname}_${IVname}_est_1st	${depvar}_${endovarname}_${IVname}_est_1st	`model'_1st
					*global	${depvar}_${endovarname}_${IVname}_est_2nd	${depvar}_${endovarname}_${IVname}_est_2nd	`model'_2nd
					
					/*
					*	Dynamic model (including FS amount from multiple periods)
					*	We will do this manually
						*	Note: this will make our SE incorrect. Need to adjust later (but how?)
					*	First, predict FS amount from the first stage.
				
					est restore ${depvar}_${endovarname}_${IVname}_1st
					cap	drop	FS_${endovarname}_${IVname}_${depvar}_hat
					predict 	FS_${endovarname}_${IVname}_${depvar}_hat, xb
					*lab	var	FS_${endovar}_${depvar}_hat	"Predicted FS amount received last month"
					
					*	Now, regress 2nd stage, including FS across multiple periods	
					reghdfe	${depvar} FS_${endovarname}_${IVname}_${depvar}_hat	l2.FS_${endovarname}_${IVname}_${depvar}_hat	${FSD_on_FS_X}	[aw=wgt_long_fam_adj]	///
						if	income_below_200==1 & !mi(${IV}),	vce(robust) absorb(ib31.rp_state x11101ll)
			
					est	store	${depvar}_${endovarname}_${IVname}_dyn_2nd
					*global		${depvar}_${endovarname}_${IVname}_est_2nd			${depvar}_${endovarname}_${IVname}_est_2nd	///
																					${depvar}_${endovarname}_${IVname}_dyn_2nd
					
					*/
					*	1st-stage
					esttab	${depvar}_${endovarname}_${IVname}_1st	using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_1st.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(${depvar} on FS_1st with ${endovarname})		replace	
							
					esttab	${depvar}_${endovarname}_${IVname}_1st		using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_1st.tex", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N Fstat, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(SL_5 on FS_1st)		replace	
							
					*	2nd-stage
					esttab	${depvar}_${endovarname}_${IVname}_2nd	/*${depvar}_${endovarname}_${IVname}_dyn_2nd*/		using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_2nd.csv", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(SL_5 on FS_2nd)		replace		
							
					esttab	${depvar}_${endovarname}_${IVname}_2nd	/*${depvar}_${endovarname}_${IVname}_dyn_2nd*/		using "${SNAP_outRaw}/${depvar}_${endovarname}_${IVname}_est_2nd.tex", ///
							cells(b(star fmt(%8.3f)) & se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
							title(SL_5 on FS_2nd)		replace	
				
			}
					
					
					
				summ	PFS_ppml SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG TFI_SFIG CFI_SFIG	if income_below_200==1 & !mi(citi6016) &	!mi(PFS_ppml)					[aw=wgt_long_fam_adj]	//	all sample
				summ	PFS_ppml SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG TFI_SFIG CFI_SFIG	if income_below_200==1 & !mi(citi6016) &	!mi(PFS_ppml)	& PFS_FI_ppml==1 	[aw=wgt_long_fam_adj]	//	Food insecure by PFS
				summ	PFS_ppml SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG TFI_SFIG CFI_SFIG	if income_below_200==1 & !mi(citi6016) &	!mi(PFS_ppml)	& FS_rec_wth==1 	[aw=wgt_long_fam_adj]	//	FS/SNAP beneficiaries
			
				*	Sub-sample (when SNAP index is available)
				summ	PFS_ppml SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if income_below_200==1 & !mi(citi6016) &	!mi(SNAP_index_w) & !mi(PFS_ppml)					[aw=wgt_long_fam_adj]	//	all sample
				summ	PFS_ppml SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if income_below_200==1 & !mi(citi6016) &	!mi(SNAP_index_w) & !mi(PFS_ppml)	& FS_rec_wth==1 	[aw=wgt_long_fam_adj]	//	FS/SNAP beneficiaries	
				summ	PFS_ppml SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if income_below_200==1 & !mi(citi6016) &	!mi(SNAP_index_w) & !mi(PFS_ppml)	& PFS_FI_ppml==1 	[aw=wgt_long_fam_adj]	//	Food insecure by PFS
				
		
		*	Print relevant models toegether
		
			*	Incidence
			esttab	SL_5_dummy_citi_2nd	TFI_HCR_dummy_citi_2nd	CFI_HCR_dummy_citi_2nd		///
			using "${SNAP_outRaw}/SL5_TFI0_CFI0.csv", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(SNAP on Incidences)		replace	
						
			esttab	SL_5_dummy_citi_2nd	TFI_HCR_dummy_citi_2nd	CFI_HCR_dummy_citi_2nd		///
			using "${SNAP_outRaw}/SL5_TFI0_CFI0.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(SNAP on Incidences)		replace	
						
			*	Level and Severity
			esttab	TFI_FIG_dummy_citi_2nd	CFI_FIG_dummy_citi_2nd	TFI_SFIG_dummy_citi_2nd		CFI_SFIG_dummy_citi_2nd	///
			using "${SNAP_outRaw}/TFI1_CFI1_TFI2_CFI2.csv", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(SNAP on Level and Severity)		replace
						
			esttab	TFI_FIG_dummy_citi_2nd	CFI_FIG_dummy_citi_2nd	TFI_SFIG_dummy_citi_2nd		CFI_SFIG_dummy_citi_2nd	///
			using "${SNAP_outRaw}/TFI1_CFI1_TFI2_CFI2.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(SNAP on Level and Severity)		replace
						
		/*
			
			*	Print TFI/CFI with control model only
			esttab	TFI_HCR_control_2nd	TFI_HCR_dyn_control_2nd	CFI_HCR_X_2nd	CFI_HCR_dyn_X_2nd	///
			using "${SNAP_outRaw}/TFI_CFI_HCR.csv", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
						
			esttab	TFI_HCR_control_2nd	TFI_HCR_dyn_control_2nd	CFI_HCR_X_2nd	CFI_HCR_dyn_X_2nd	///
			using "${SNAP_outRaw}/TFI_CFI_HCR.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
			
			
			esttab	TFI_FIG_X_2nd	TFI_FIG_dyn_X_2nd	CFI_FIG_X_2nd	CFI_FIG_dyn_X_2nd	///
			using "${SNAP_outRaw}/TFI_CFI_FIG.csv", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
						
			esttab	TFI_FIG_X_2nd	TFI_FIG_dyn_X_2nd	CFI_FIG_X_2nd	CFI_FIG_dyn_X_2nd	///
			using "${SNAP_outRaw}/TFI_CFI_FIG.tex", ///
						cells(b(star fmt(%8.3f)) se(fmt(2) par)) stats(N r2, fmt(0 2)) incelldelimiter() label legend nobaselevels /*nostar*/ ///
						star(* 0.10 ** 0.05 *** 0.01)	/*drop(rp_state_enum*)*/	///
						title(PFS on FS amt)		replace		
		*/	
		
		

		
	}
	
	*	Summary stats	
	if	`summ_stats'==1	{
		 
		use	"${SNAP_dtInt}/SNAP_const", clear
		
		
		*	Keep revelant sample only
		keep	if	!mi(PFS_ppml)
	
	
	
	
		
		
		*	Keep 1977-2015 data (where citizen ideology is available)
		*	(2023-1-15) Maybe I shouldn't do it, because even if IV is available till 2015, we still use PFS in 2017 and 2019
		*keep	if	inrange(year,1977,2015)
			*	Re-scale HFSM, so it can be compared with the PFS
			
			cap	drop	FSSS_rescale
			gen	FSSS_rescale = (9.3-HFSM_scale)/9.3
			label	var	FSSS_rescale "FSSS (re-scaled)"
			
			*	Density Estimate of Food Security Indicator (Figure A1)
				
				*	ALL households
				graph twoway 		(kdensity FSSS_rescale	[aw=wgt_long_fam_adj]	if	!mi(FSSS_rescale)	&	!mi(PFS_ppml) & inrange(year,1977,2015))	///
									(kdensity PFS_ppml		[aw=wgt_long_fam_adj]	if	!mi(FSSS_rescale)	&	!mi(PFS_ppml) & inrange(year,1977,2015)),	///
									/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)	 ylabel(0(3)21)	///
									name(FSSS_PFS, replace) graphregion(color(white)) bgcolor(white) title(All)		///
									legend(lab (1 "FSSS (rescaled)") lab(2 "PFS") rows(1))					
					
				*	Income below 200% & until 2015 (study sample)
				graph twoway 		(kdensity FSSS_rescale	[aw=wgt_long_fam_adj]	if	!mi(FSSS_rescale)	&	!mi(PFS_ppml) & income_below_200==1 & inrange(year,1977,2015))	///
									(kdensity PFS_ppml		[aw=wgt_long_fam_adj]	if	!mi(FSSS_rescale)	&	!mi(PFS_ppml) & income_below_200==1 & inrange(year,1977,2015)),	///
									/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)  ylabel(0(3)21)		///
									name(FSSS_PFS_below200, replace) graphregion(color(white)) bgcolor(white) title(Income below 200%)		///
									legend(lab (1 "FSSS (rescaled)") lab(2 "PFS") rows(1))	
				
			graph	combine	FSSS_PFS	FSSS_PFS_below200, graphregion(color(white) fcolor(white)) 
			graph	export	"${SNAP_outRaw}/Fig_A2_Density_FSSS_PFS.png", replace
			
			
			*	PFS by gender
			graph twoway 		(kdensity PFS_ppml	[aw=wgt_long_fam_adj]	if	!mi(PFS_ppml) & inrange(year,1977,2015) & income_below_200==1 & ind_female==0, bwidth(0.05) )	///
								(kdensity PFS_ppml	[aw=wgt_long_fam_adj]	if	!mi(PFS_ppml) & inrange(year,1977,2015) & income_below_200==1 & ind_female==1, bwidth(0.05) ),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(PFS) ytitle(Density)		///
								name(PFS_ind_gender, replace) graphregion(color(white)) bgcolor(white)	title(by Gender)	///
								legend(lab (1 "Male") lab(2 "Female") rows(1) pos(6))	
								
								
			*	PFS by race
			graph twoway 		(kdensity PFS_ppml	[aw=wgt_long_fam_adj]	if	inrange(year,1977,2015) & rp_nonWhte==0, bwidth(0.05) )	///
								(kdensity PFS_ppml	[aw=wgt_long_fam_adj]	if	inrange(year,1977,2015) & rp_nonWhte==1, bwidth(0.05) ),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(PFS) ytitle(Density)		///
								name(PFS_rp_race, replace) graphregion(color(white)) bgcolor(white) title(by Race)		///
								legend(lab (1 "White") lab(2 "non-White") rows(1) pos(6))	
			
			graph	combine	PFS_ind_gender	PFS_rp_race, graphregion(color(white) fcolor(white)) 
			graph	export	"${SNAP_outRaw}/PFS_kdensities.png", replace
			graph	close
			
		
		
		*	Sample information
			
			count if 	income_ever_below_200==1		&	!mi(PFS_ppml)		//	# of observations with non-missing PFS
			count if in_sample	&	income_ever_below_200==1		&	!mi(PFS_ppml)	&	baseline_indiv==1	//	Baseline individual in sapmle
			count if in_sample	&	income_ever_below_200==1		&	!mi(PFS_ppml)	&	splitoff_indiv==1	//	Splitoff individual in sapmle
				
			*	Number of individuals
				distinct	x11101ll	if	!mi(PFS_ppml)	&	income_ever_below_200==1		//	# of baseline individuals in sapmle
				distinct	x11101ll	if	income_ever_below_200==1		//	# of baseline individuals in sapmle (including missing PFS)
				distinct	x11101ll	if	!mi(PFS_ppml)	&	income_ever_below_200==1		&	baseline_indiv==1	//	# of baseline individuals in sapmle
				distinct	x11101ll	if	!mi(PFS_ppml)	&	income_ever_below_200==1		&	splitoff_indiv==1	//	Baseline individual in sapmle
				
			*	Counting only individuals in regression sample
				distinct	x11101ll	if	reg_sample==1 // reg_sample==1
				distinct	x11101ll	if	reg_sample==1	&	baseline_indiv==1	//	# of baseline individuals in sapmle
				distinct	x11101ll	if	reg_sample==1	&	splitoff_indiv==1	//	# of baseline individuals in sapmle
			
			unique	x11101ll	if	!mi(PFS_ppml)	//	Total individuals
			unique	year		if	!mi(PFS_ppml)		//	Total waves
	
		
		*	Yearly trends in PFS
		*	Earlier years have very high PFS, need to think of why it is happening...
		preserve
			keep	if	reg_sample==1 
			collapse	(mean) PFS_ppml FSSS_rescale [aw=wgt_long_ind], by(year)
			graph	twoway	(line PFS_ppml year) (line FSSS_rescale year)
		restore
		
		*	Individual-level stats
		*	To do this, we need to crate a variable which is non-missing only one obs per individual
		*	For now, I use `_uniq' suffix to create such variables
		
			
		*	Sample stats

			*	Individual-level (unique per individual)	
				
				*	Gender and education
				foreach	var	in	ind_female	ind_NoHS	ind_HS ind_somecol ind_col	{
					
					cap	drop	`var'_uniq
					bys x11101ll	live_in_FU:	gen `var'_uniq=`var' if _n==1	&	live_in_FU==1	
					summ `var'_uniq	
					
					local vlab: variable	label	`var'
					lab	var	`var'_uniq	"`vlab'"
				}
				
				
								
				*	Number of waves living in FU
				loc	var	num_waves_in_FU
				cap	drop	`var'
				cap	drop	`var'_temp
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'=total(live_in_FU)	if	live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
				bys x11101ll:	egen	`var'_temp	=	max(`var')
				bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
				drop	`var'
				rename	`var'_temp	`var'
				summ	`var'_uniq,d
				label	var	`var'_uniq "\# of waves surveyed"
				
				/*
				*	Number of waves surveyed
				local	var	num_surveyed
				cap	drop 	`var'
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'	=	count(live_in_FU)
				bys x11101ll:	gen 	`var'_uniq=`var' if _n==1
				summ	`var'_uniq,d
				*/
				
				*	Ever-used FS over stuy period
				loc	var	FS_ever_used
				cap	drop	`var'
				cap	drop	`var'_uniq
				cap	drop	`var'_temp
				bys	x11101ll:	egen	`var'=	max(FS_rec_wth)	if live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
				bys x11101ll:	egen	`var'_temp	=	max(`var')
				bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
				drop	`var'
				rename	`var'_temp	`var'
				summ	`var'_uniq ,d
				label var	`var'		"FS ever used throughouth the period"
				label var	`var'_uniq	"FS ever used throughouth the period"
				
				*	# of waves FS redeemed	(if ever used)
				loc	var	total_FS_used
				cap	drop	`var'
				cap	drop	`var'_temp
				cap	drop	`var'_uniq
				bys	x11101ll:	egen	`var'=	total(FS_rec_wth)	if	live_in_FU==1 // Only counts the period when individual was living in FU. NOT including it will result in counting invalid periods (ex. before born)
				bys x11101ll:	egen	`var'_temp	=	max(`var')
				bys x11101ll:	gen 	`var'_uniq	=	`var'_temp if _n==1
				summ	`var'_uniq if `var'_uniq>=1,d
				label var	`var'		"Total FS used throughouth the period"
				label var	`var'_uniq	"Total FS used throughouth the period"
				
				*	% of FS redeemed (# FS redeemed/# surveyed)		
				loc	var	share_FS_used
				cap	drop	`var'
				cap	drop	`var'_uniq
				gen	`var'	=	total_FS_used_uniq	/	num_waves_in_FU_uniq
				bys x11101ll:	gen 	`var'_uniq	=	`var' if _n==1
				label var	`var'		"\% of FS used throughouth the period"
				label var	`var'_uniq	"\% of FS used throughouth the period"
				
					*	Generate indicaor by the #
					*local	var	never_treated
					*cap	drop	`var'
					*cap	drop	`var'_uniq
					*gen	`var'=.
					*replace	`var'=0	if	
					
				*	Generate cumulative FS redemption
				local	var	cumul_FS_used
				cap	drop	`var'
				bysort x11101ll (year) : gen `var' = sum(FS_rec_wth)
				bys x11101ll:	gen `var'_uniq	=	`var' if _n==1
				label var	`var'		"# of cumulative FS used"
				label var	`var'_uniq	"# of cumulative FS used"
				
				*	Reason for non-participation (1977,1980,1981,1987)
				*svy, subpop(if !mi(PFS_ppml)):	tab reason_no_FSP
				
				*	Create temporary variable for summary table (will be integrated into "clean" part)
				cap	drop	fam_income_month_pc_real
				gen	double	fam_income_month_pc_real	=	(fam_income_pc_real/12)
				label	var	fam_income_month_pc_real	"Monthly family income per capita"
				
				*lab		var	major_control_mix	"Mixed state control"
				
				
				
					*	Additional cleaning
				lab	var	SL_5	"SL5"
				lab	var	citi6016	"State citizen ideology"
				lab	var	FS_rec_wth	"SNAP received"
				lab	var	FS_rec_amt_real	"SNAP amount"
				label	var	foodexp_tot_inclFS_pc_real	"Monthly food exp per capia"
				label 	var	childnum					"\# of child"
				lab	var	SNAP_index_w	"SNAP Policy Index (weighted)"
				lab	var	FS_ever_used_uniq	"Ever received SNAP"
				
				*	For now, generate summ table separately for indvars and fam-level vars, as indvars do not represent full sample if conditiond by !mi(ppml) (need to figure out why)
				local	indvars	ind_female_uniq ind_col_uniq num_waves_in_FU_uniq FS_ever_used_uniq //total_FS_used_uniq	share_FS_used_uniq
				local	rpvars	rp_female	rp_age	rp_White	rp_married	rp_NoHS rp_HS rp_somecol rp_col		rp_employed rp_disabled
				local	famvars	famnum	ratio_child		fam_income_month_pc_real	foodexp_tot_inclFS_pc_real		
				local	FSvars	FS_rec_wth	FS_rec_amt_real
				local	IVs		SNAP_index_uw	SNAP_index_w // citi6016	inst6017_nom
				local	FSDvars	PFS_ppml PFS_FI_ppml	//SL_5	TFI_HCR	CFI_HCR	TFI_FIG	CFI_FIG	TFI_SFIG	CFI_SFIG	
				
				//estpost summ	`indvars'	[aw=wgt_long_fam_adj]	if	!mi(PFS_ppml)	//	all sample
				//estpost summ	`indvars'	[aw=wgt_long_fam_adj]	if	!mi(PFS_ppml)	&	balanced_9713==1	&	income_ever_below_200_9713==1	/*  num_waves_in_FU_uniq>=2	 &*/	  // Temporary condition. Need to think proper condition.
				
				local	summvars	/*`indvars'*/	`rpvars'	`famvars'	`FSvars'	`IVs'	`FSDvars'
	
				estpost tabstat	`summvars'	 if	!mi(PFS_ppml)	[aw=wgt_long_ind],	statistics(count	mean	sd	min	max) columns(statistics)		// save
				est	store	sumstat_all
				estpost tabstat	`summvars' 	if	!mi(PFS_ppml)	&	/* balanced_9713==1	& */	income_ever_below_130_9713==1	[aw=wgt_long_ind],	statistics(count	mean	sd	min	max) columns(statistics)	// save
				est	store	sumstat_lowinc
				
					*	FS amount per capita in real dollars (only those used)
					estpost tabstat	 FS_rec_amt_capita	if in_sample==1	&	!mi(PFS_ppml)	&	income_below_200==1	& FS_rec_wth==1 [aw=wgt_long_fam_adj],	statistics(mean	sd	min	max) columns(statistics)	// save
				
			
				
				esttab	sumstat_all	sumstat_lowinc	using	"${SNAP_outRaw}/Tab_1_Sumstats.csv",  ///
					cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
									
				esttab	sumstat_all	sumstat_lowinc	using	"${SNAP_outRaw}/Tab_1_Sumstats.tex",  ///
					cells("count(fmt(%12.0f)) mean(fmt(%12.2f)) sd(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace
					
				esttab	sumstat_lowinc	using	"${SNAP_outRaw}/Tab_1_Sumstats_lowinc.tex",  ///
					cells("mean(fmt(%12.2f)) sd(fmt(%12.2f)) min(fmt(%12.2f)) max(fmt(%12.2f))") label	title("Summary Statistics") noobs 	  replace	
					
				
				summ	PFS_ppml SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if in_sample==1	&	income_below_200==1 & PFS_FI_ppml==1 [aw=wgt_long_fam_adj],d
				summ	PFS_ppml SL_5 TFI_HCR CFI_HCR TFI_FIG CFI_FIG if in_sample==1	&	income_below_200==1	& PFS_FI_ppml==1 & FS_rec_wth!=1 [aw=wgt_long_fam_adj],d // didn't receive SNAP

			
			
				/*
				*estpost summ	`indvars'	if	/*   num_waves_in_FU_uniq>=2	&*/	!mi(PFS_ppml)  // Temporary condition. Need to think proper condition.
				*summ	FS_rec_amt_real	if	!mi(PFS_ppml)	&	FS_rec_wth==1 & inrange(rp_age,0,130) // Temporarily add age condition to take care of outlier. Will be taken care of later.
			
					/*
					*	If I want survey-weighted summary stats...
					svy, subpop(if num_waves_in_FU_uniq>=2):	mean	`indvars'
					estadd matrix mean = e(b)
					estadd matrix sd = r(table)[2,1...]
					*/
				
				esttab using "${SNAP_outRaw}/Tab_1_Sumstats_ind.csv", replace ///
				cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label	///
				nonumbers mtitles("Total" ) ///
				title (Summary Statistics_ind)	csv 
				
				esttab using "${SNAP_outRaw}/Tab_1_Sumstats_ind.tex", replace ///
				cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label	///
				nonumbers mtitles("Total" ) ///
				title (Summary Statistics_ind)	tex 
				
				estpost summ	`rpvars'	`famvars' if !mi(PFS_ppml)	& inrange(rp_age,0,130) // Temporarily add age condition to take care of outlier. Will be taken care of later.
				
						
				esttab using "${SNAP_outRaw}/Tab_1_Sumstats_fam.csv", replace ///
				cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label	///
				nonumbers mtitles("Total" ) ///
				title (Summary Statistics_fam)	csv
				
				esttab using "${SNAP_outRaw}/Tab_1_Sumstats_fam.tex", replace ///
				cells("mean(fmt(2)) sd(fmt(2)) min(fmt(0)) max(fmt(0))") label	///
				nonumbers mtitles("Total" ) ///
				title (Summary Statistics_fam)	tex 
				*/
		
		*	Program Summary
		preserve
		
			use	"${SNAP_dtInt}/SNAP_summary",	clear
			
			merge	1:1	year	using		"${SNAP_dtInt}/Unemployment Rate_nation", nogen assert(3)
			
			graph	twoway	(line part_num		year, lpattern(dash) xaxis(1 2) yaxis(1))	///
						(line unemp_rate	year, lpattern(dash_dot) xaxis(1 2) yaxis(2)),  ///
						xline(1974 1996 2009 2020, axis(1)) xlabel(1974 "Nationwide FSP" 1996 "Welfare Reform" 2009 "ARRA" 2020 "COVID", axis(2))	///
						xtitle(Fiscal Year)	xtitle("", axis(2))  /*title(Program Summary)*/	bgcolor(white)	graphregion(color(white)) note(Source: USDA & BLS)	name(SNAP_summary, replace)
			
			/*
			graph	twoway	(line part_num	year, lpattern(dash) xaxis(1 2) yaxis(1))	///
							(line total_costs	year, lpattern(dot) xaxis(1 2) yaxis(2)),  ///
							xline(1974 1996 2009 2020, axis(1)) xlabel(1974 "Nationwide FSP" 1996 "Welfare Reform" 2009 "2008 Farm Bill" 2020 "COVID", axis(2))	///
							xtitle(Fiscal Year)	xtitle("", axis(2))  /*title(Program Summary)*/	bgcolor(white)	graphregion(color(white)) note(Source: USDA)	name(SNAP_summary, replace)
			*/
			
			
			graph	export	"${SNAP_outRaw}/Program_summary.png", replace
			graph	close
		
		restore
		
		
		
		*	Split-off
			summ	total_FS_used_uniq	if	total_FS_used_uniq>=1
		*	Histogram of FS redemption frequency
			histogram	total_FS_used_uniq	if	total_FS_used_uniq>=1, name(FS_fre, replace)
			graph	export "${SNAP_outRaw}/FS_redemption_freq.png", replace
			graph	close
			
		*	Histogram of share of FS redemption
			histogram	share_FS_used	if	total_FS_used_uniq>=1, bin(10) name(FS_share, replace)
			graph	export "${SNAP_outRaw}/FS_redemption_share.png", replace
			graph	close
			
			grc1leg2		FS_fre	FS_share,	title(Frequency and Share) 	graphregion(color(white))  legendfrom(FS_share)
							graph	export	"${SNAP_outRaw}/hist_FS_redemption.png", replace
							graph	close
	
			
		*	Test parallel trend assumption // Not using it for now.
		{	
			*	Never-treated vs Treated-once
			sort	x11101ll	year
			cap	drop	relat_time
			cap	drop	relat_time*
			
				*	Standardize time
				/*
				gen		relat_time=-4	if	total_FS_used==1	&	FS_rec_wth==0	&	f4.FS_rec_wth==1	//	4 year before FS
				replace	relat_time=-3	if	total_FS_used==1	&	FS_rec_wth==0	&	f3.FS_rec_wth==1	//	3 year before FS
				replace	relat_time=-2	if	total_FS_used==1	&	FS_rec_wth==0	&	f2.FS_rec_wth==1	//	2 year before FS
				replace	relat_time=-1	if	total_FS_used==1	&	FS_rec_wth==0	&	f1.FS_rec_wth==1	//	1 year before FS
				replace	relat_time=0	if	total_FS_used==1	&	FS_rec_wth==1							//	Year of FS
				replace	relat_time=1	if	total_FS_used==1	&	FS_rec_wth==0	&	l1.FS_rec_wth==1	//	1 year after FS
				replace	relat_time=2	if	total_FS_used==1	&	FS_rec_wth==0	&	l2.FS_rec_wth==1	//	2 year after FS
				replace	relat_time=3	if	total_FS_used==1	&	FS_rec_wth==0	&	l3.FS_rec_wth==1	//	3 year after FS			
				*/
				gen		relat_time=-4	if	total_FS_used==1	&	f3.cumul_FS_used==0	&	f4.FS_rec_wth==1	//	4 year before first FS redemption
				replace	relat_time=-3	if	total_FS_used==1	&	f2.cumul_FS_used==0	&	f3.FS_rec_wth==1	//	3 year before first FS redemption
				replace	relat_time=-2	if	total_FS_used==1	&	f1.cumul_FS_used==0	&	f2.FS_rec_wth==1	//	2 year before first FS redemption
				replace	relat_time=-1	if	total_FS_used==1	&	cumul_FS_used==0	&	f1.FS_rec_wth==1	//	1 year before first FS redemption
				replace	relat_time=-0	if	total_FS_used==1	&	cumul_FS_used==1	&	FS_rec_wth==1		//	Year of first FS redemption
				replace	relat_time=1	if	total_FS_used==1	&	cumul_FS_used==1	&	l1.FS_rec_wth==1	//	1 year after first FS redemption
				replace	relat_time=2	if	total_FS_used==1	&	cumul_FS_used==1	&	l2.FS_rec_wth==1	//	2 year after first FS redemption
				replace	relat_time=3	if	total_FS_used==1	&	cumul_FS_used==1	&	l3.FS_rec_wth==1	//	3 year after first FS redemption
				
				
				*	Make value of never-treated group as non-missing and zero for each relative time indicator, so this group can be included in the regression
				replace	relat_time=4	if	total_FS_used==0
				
				*	Creat dummy for each indicator (never-treated group will be zero in all indicator)
				cap	drop	relat_time_enum*
				tab	relat_time, gen(relat_time_enum)
				drop	relat_time_enum9	//	We should not use it, as it is a dummy for never-treated group
				
				label	var	relat_time_enum1	"t-4"
				label	var	relat_time_enum2	"t-3"
				label	var	relat_time_enum3	"t-2"
				label	var	relat_time_enum4	"t-1"
				label	var	relat_time_enum5	"t=0"
				label	var	relat_time_enum6	"t+1"
				label	var	relat_time_enum7	"t+2"
				label	var	relat_time_enum8	"t+3"
				
				*	Pre-trend plot
				*reg	PFS_ppml 	relat_time_enum1	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7	i.year, fe
				xtreg PFS_ppml 	relat_time_enum1	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7	i.year, fe
				est	store	PT_never_once
				
				coefplot	PT_never_once,	graphregion(color(white)) bgcolor(white) vertical keep(relat_time_enum*) xtitle(Event time) ytitle(Coefficient) ///
											title(Never-treated vs Treated-once)	name(PFS_pretrend, replace)
				graph	export	"${SNAP_outRaw}/PFS_never_once.png", replace
				graph	close
			
			*	Never-treated vs ever-treated
			*	In this comparison, all FU in this dataset will be included, and event will be "when FS used the first time"
			**	QUESTION: but many "ever-treated" observations which don't belong to the time window below won't be included in the regression (ex. 4 years after the first FS). Should I write a code to include such obs?
			cap	drop	relat_time relat_time*
			
				*	Standardize event time
				gen		relat_time=-4	if	total_FS_used>=1	&	f3.cumul_FS_used==0	&	f4.FS_rec_wth==1	//	4 year before first FS redemption
				replace	relat_time=-3	if	total_FS_used>=1	&	f2.cumul_FS_used==0	&	f3.FS_rec_wth==1	//	3 year before first FS redemption
				replace	relat_time=-2	if	total_FS_used>=1	&	f1.cumul_FS_used==0	&	f2.FS_rec_wth==1	//	2 year before first FS redemption
				replace	relat_time=-1	if	total_FS_used>=1	&	cumul_FS_used==0	&	f1.FS_rec_wth==1	//	1 year before first FS redemption
				replace	relat_time=-0	if	total_FS_used>=1	&	cumul_FS_used==1	&	FS_rec_wth==1		//	Year of first FS redemption
				replace	relat_time=1	if	total_FS_used>=1	&	cumul_FS_used>=1	&	l1.cumul_FS_used==1	&	l1.FS_rec_wth==1	//	1 year after first FS redemption
				replace	relat_time=2	if	total_FS_used>=1	&	cumul_FS_used>=1	&	l2.cumul_FS_used==1	&	l2.FS_rec_wth==1	//	2 year after first FS redemption
				replace	relat_time=3	if	total_FS_used>=1	&	cumul_FS_used>=1	&	l3.cumul_FS_used==1	&	l3.FS_rec_wth==1	//	3 year after first FS redemption
				
				*	Make value of never-treated group as non-missing and zero for each relative time indicator, so this group can be included in the regression
				*replace	relat_time=4	if	total_FS_used==0	//	Including only never-treated as a control group
				replace	relat_time=4	if	mi(relat_time)			//	Including never-treated group as well as ever-treated group outside the lead-lag window (ex. 5 yrs before FS redemption) as a control group. Basically all other obs.
				
				*	Creat dummy for each indicator (never-treated group will be zero in all indicator)
				cap	drop	relat_time_enum*
				tab	relat_time, gen(relat_time_enum)
				drop	relat_time_enum9	//	We should not use it, as it is a dummy for never-treated group
				
				label	var	relat_time_enum1	"t-4"
				label	var	relat_time_enum2	"t-3"
				label	var	relat_time_enum3	"t-2"
				label	var	relat_time_enum4	"t-1"
				label	var	relat_time_enum5	"t=0"
				label	var	relat_time_enum6	"t+1"
				label	var	relat_time_enum7	"t+2"
				label	var	relat_time_enum8	"t+3"
				
				xtreg PFS_ppml 	relat_time_enum1	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7, fe
				est	store	PT_never_ever
				
				coefplot	PT_never_ever,	graphregion(color(white)) bgcolor(white) vertical keep(relat_time_enum*) xtitle(Event time) ytitle(Coefficient) 	///
											title(Never-treated vs Ever-treated) /*subtitle(Excluding ever-treated outside this window)*/	name(PFS_pretrend, replace)
				graph	export	"${SNAP_outRaw}/PFS_never_ever.png", replace
				graph	close
				
			*	Never-treated vs treated multiple tims (twice or more) - exclude treated only once.
			cap	drop	relat_time relat_time*
			
				*	Standardize event time
				gen		relat_time=-4	if	total_FS_used>1	&	f3.cumul_FS_used==0	&	f4.FS_rec_wth==1	//	4 year before first FS redemption
				replace	relat_time=-3	if	total_FS_used>1	&	f2.cumul_FS_used==0	&	f3.FS_rec_wth==1	//	3 year before first FS redemption
				replace	relat_time=-2	if	total_FS_used>1	&	f1.cumul_FS_used==0	&	f2.FS_rec_wth==1	//	2 year before first FS redemption
				replace	relat_time=-1	if	total_FS_used>1	&	cumul_FS_used==0	&	f1.FS_rec_wth==1	//	1 year before first FS redemption
				replace	relat_time=-0	if	total_FS_used>1	&	cumul_FS_used==1	&	FS_rec_wth==1		//	Year of first FS redemption
				replace	relat_time=1	if	total_FS_used>1	&	cumul_FS_used>=1	&	l1.cumul_FS_used==1	&	l1.FS_rec_wth==1	//	1 year after first FS redemption
				replace	relat_time=2	if	total_FS_used>1	&	cumul_FS_used>=1	&	l2.cumul_FS_used==1	&	l2.FS_rec_wth==1	//	2 year after first FS redemption
				replace	relat_time=3	if	total_FS_used>1	&	cumul_FS_used>=1	&	l3.cumul_FS_used==1	&	l3.FS_rec_wth==1	//	3 year after first FS redemption
				
				*	Make value of never-treated group as non-missing and zero for each relative time indicator, so this group can be included in the regression
				replace	relat_time=4	if	total_FS_used==0	//	Including only never-treated as a control group
								
				*	Creat dummy for each indicator (never-treated group will be zero in all indicator)
				cap	drop	relat_time_enum*
				tab	relat_time, gen(relat_time_enum)
				drop	relat_time_enum9	//	We should not use it, as it is a dummy for never-treated group
				
				label	var	relat_time_enum1	"t-4"
				label	var	relat_time_enum2	"t-3"
				label	var	relat_time_enum3	"t-2"
				label	var	relat_time_enum4	"t-1"
				label	var	relat_time_enum5	"t=0"
				label	var	relat_time_enum6	"t+1"
				label	var	relat_time_enum7	"t+2"
				label	var	relat_time_enum8	"t+3"
				
				xtreg PFS_ppml 	relat_time_enum1	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7, fe
				est	store	PT_never_ever
				
				coefplot	PT_never_ever,	graphregion(color(white)) bgcolor(white) vertical keep(relat_time_enum*) xtitle(Event time) ytitle(Coefficient) 	///
											title(Never-treated vs Treated multiple times) /*subtitle(Excluding ever-treated outside this window)*/	name(PFS_pretrend, replace)
				graph	export	"${SNAP_outRaw}/PFS_never_ever.png", replace
				graph	close

			*	Treated-twice vs treated 3-times
			cap	drop	relat_time relat_time*
			
				*	Standardize event time
				gen		relat_time=-4	if	total_FS_used==3	&	f3.cumul_FS_used==2	&	f4.cumul_FS_used==3	//	4 year before 3rd FS redemption
				replace	relat_time=-3	if	total_FS_used==3	&	f2.cumul_FS_used==2	&	f3.cumul_FS_used==3	//	3 year before 3rd FS redemption
				replace	relat_time=-2	if	total_FS_used==3	&	f1.cumul_FS_used==2	&	f2.cumul_FS_used==3	//	2 year before 3rd FS redemption
				replace	relat_time=-1	if	total_FS_used==3	&	cumul_FS_used==2	&	f1.FS_rec_wth==1	&	f1.cumul_FS_used==3	//	1 year before 3rd FS redemption
				replace	relat_time=-0	if	total_FS_used==3	&	cumul_FS_used==3	&	FS_rec_wth==1		//	Year of 3rd FS redemption
				replace	relat_time=1	if	total_FS_used==3	&	cumul_FS_used==3	&	l1.FS_rec_wth==1	&	l1.cumul_FS_used==3	//	1 year after 3rd FS redemption
				replace	relat_time=2	if	total_FS_used==3	&	cumul_FS_used==3	&	l2.FS_rec_wth==1	&	l2.cumul_FS_used==3	//	2 year after 3rd FS redemption
				replace	relat_time=3	if	total_FS_used==3	&	cumul_FS_used==3	&	l3.FS_rec_wth==1	&	l3.cumul_FS_used==3	//	3 year after 3rd FS redemption
				
				*	Make value of treated-twice group as non-missing and zero for each relative time indicator, so this group can be included in the regression as a control group
				replace	relat_time=4	if	total_FS_used==2	// &	cumul_FS_used==2
				
				*	Creat dummy for each indicator (never-treated group will be zero in all indicator)
				cap	drop	relat_time_enum*
				tab	relat_time, gen(relat_time_enum)
				drop	relat_time_enum9	//	We should not use it, as it is a dummy forcontrol group
				
				label	var	relat_time_enum1	"t-4"
				label	var	relat_time_enum2	"t-3"
				label	var	relat_time_enum3	"t-2"
				label	var	relat_time_enum4	"t-1"
				label	var	relat_time_enum5	"t=0"
				label	var	relat_time_enum6	"t+1"
				label	var	relat_time_enum7	"t+2"
				label	var	relat_time_enum8	"t+3"
				
				xtreg PFS_ppml 	relat_time_enum2	relat_time_enum3	relat_time_enum4	relat_time_enum5	relat_time_enum6	relat_time_enum7	relat_time_enum8	i.year	, fe
				est	store	PT_never_ever
				
				coefplot	PT_never_ever,	graphregion(color(white)) bgcolor(white) vertical keep(relat_time_enum*) xtitle(Event time) ytitle(Coefficient) 	///
											title(Treated twice vs Treated 3-times)	name(PFS_pretrend, replace)
				graph	export	"${SNAP_outRaw}/PFS_twice_3times.png", replace
				graph	close
		}	
			
			/*
			*	Genenerate average PFS per each group
			cap	drop	PFS_ppml_avg
			bys	relat_time	total_FS_used:	egen PFS_ppml_avg = mean(PFS_ppml) if inlist(total_FS_used,0,1)
			*/
			
			
			*	Plot graph
			
				/*
			graph twoway 		(kdensity HFSM_rescale	if	inlist(year,1999,2001,2003,2015,2017,2019)	&	!mi(PFS_ppml))	///
								(kdensity PFS_ppml		if	inlist(year,1999,2001,2003,2015,2017,2019)	&	!mi(HFSM_rescale)),	///
								/*title (Density Estimates of the USDA scale and the PFS)*/	xtitle(Scale) ytitle(Density)		///
								name(thrifty, replace) graphregion(color(white)) bgcolor(white)		///
								legend(lab (1 "HFSM (rescaled)") lab(2 "PFS") rows(1))					
			graph	export	"${PSID_outRaw}/Fig_A2_Density_HFSM_PFS.png", replace
				*/
				
				
				*	FWL
				/*
				cap drop uhat1
				cap drop uhat2
				reg PFS_ppml relat_time_enum1 relat_time_enum7	//	Regress Y on X1 X2 is equal to...
				reg PFS_ppml relat_time_enum1	//	Regress Y on X1
				predict uhat1, resid			//	Get resid1
				reg relat_time_enum7 relat_time_enum1	//	Pregress X2 on X1
				predict uhat2, resid	//	Get resid2
				reg uhat1 uhat2	//	regressing resid1 on resid2!
				*/
			
			
			/*
			*	Seems leads are significant, meaning PT is violated...... is specification wrong?
			svy, subpop(if inrange(year,1975,1997)): reg PFS_ppml relat_time_enum1-relat_time_enum7 ${regionvars} ${timevars} 
			reg	PFS_ppml relat_time_enum1-relat_time_enum7 ${regionvars} ${timevars} if year<=1997
			svy: reg	foodexp_tot_exclFS_pc_real	relat_time_enum1-relat_time_enum7 ${regionvars} ${timevars}
			reg	foodexp_tot_exclFS_pc_real	relat_time_enum1-relat_time_enum7 ${regionvars} ${timevars}
			*/
			
			
			/*
			*	Real dollars of food expenditure over time
			bys year: egen foodexp_tot_exclFS_pc_real_m = mean(foodexp_tot_exclFS_pc_real)
			bys year: egen foodexp_tot_exclFS_pc_real_m = mean(foodexp_tot_exclFS_pc_real)
			
			preserve
			
			collapse foodexp_tot_exclFS_pc_real foodexp_tot_inclFS_pc_real	[iweight=wgt_long_fam_adj], by(year)
			
			graph	twoway	(line	fs_insecure year, lpattern(dash_dot) yaxis(1))	///
							(line	fs_insecure_vlfs year, lpattern(dash) yaxis(1))	///
							(line	fs_snap year, lpattern(dot) yaxis(1))	///
							(connected	fs_snap_novdec year	if	year!=1996, lpattern(dash_dot) yaxis(2)),	///					
							legend(label(1 "FI") label(2 "Very low FS") label(3 "SNAP (year)")	label(4 "SNAP (Nov/Dec)") rows(1)) ///
							ytitle(FI, axis(1))	ytitle(SNAP, axis(2)) title(Food Insecurity(FI) Prevalence and SNAP usage)	///
							note(This figure replicates Figure 3 in USDA 2019 report)
							
			graph	export	"${figures}/FSS_FI_SNAP.png", replace	
			graph	close
			
			restore
			*/
			
			
		
		
		
		*	Whether FS is used last month at once over the study period

		
		
		*	Time trends of food exp over time
		
			
		*	(V) Modify V4366 (FS used last year) in 1976
			*	This question actually asks if FS is use ALL THE TIME in previous year. So both "yes" and "no" should be coded as "yes" (Those who didn't use FS at all are coded as "inapp(0)")
			*	We no longer use last year's information
		*	(V) Until 1971, it is ambiguous whether food stamp amount was included in food expenditure (they are NOT included since 1972)
			*	We might need to assume that food expenditure amount is included, or drop those periods in worst case.
			*	For now we use years since 1976
		*	Split the year? - pre-1993 and post-1993
			*	Exogenous variation availability
			*	Food stamp and expenditure data (previous year vs current year/month)
		*	Import TFP value from the link
		*	(V) Import survey month to see seasonality of food expenditure reported.
		*	(V) Replace expenditure values to zero if that member didn't exist in that wave (i.e. sequence number outside 0-20)
		*	(V) Generate indicator if PSID RP is not equal to person
		*	Include School meal/WIC variables to see the ratio of school meal/WIC received also receive SNAP
		*	(V) Create real dollars of nominal value variables (don't replace them. Just create new ones)
		*	Check food stamp value reported vs recall period (to see the over- or under- reporting based on )
		*	Make a summary stat of (1) observation level (2) individual level
		
		
		*	Modeling
	
	}
	

	
	