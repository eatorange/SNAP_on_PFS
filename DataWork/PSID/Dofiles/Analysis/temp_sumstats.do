use "${SNAP_dtInt}/TFP cost/TFP_costs_all", clear

rename	svy_month month

merge m:1	year  month	using "${SNAP_dtInt}/CPI_1947_2021", nogen assert(2 3) keep(3)

gen	TFP_monthly_cost_real	=	TFP_monthly_cost	*	(100/CPI)
lab	var	TFP_monthly_cost_real	"Monthly TFP cost ($ real)"

keep	if	age_ind==20	&	month==1
*collapse	(mean) TFP_monthly_cost, by(year gender)



graph	twoway	(line TFP_monthly_cost year if gender==1, lpattern(dash) xaxis(1 2) yaxis(1))	///
				(line TFP_monthly_cost year if gender==2, lpattern(dash_dot) xaxis(1 2) yaxis(1)),  ///
				xline(1983 1999 2006, axis(1) lpattern(dot)) xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
				xtitle(Year)	xtitle("", axis(2)) /* title(Monthly Food Expenditure and FS Benefit)*/	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_FSamt_byyear, replace)
				
*	Monthly TFP cost (constant $), 20-year-old.
graph	twoway	(line TFP_monthly_cost_real year if gender==1, lpattern(dash) xaxis(1 2) yaxis(1))	///
				(line TFP_monthly_cost_real year if gender==2, lpattern(dash_dot) xaxis(1 2) yaxis(1)),  ///
				xline(1983 1999 2006, axis(1) lpattern(dot)) xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
				xtitle(Year)	xtitle("", axis(2)) legend(lab (1 "20-year-old male") lab(2 "20-year-old female")) 	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(TFP_month_real, replace)	
				
graph	export	"${SNAP_outRaw}/TFP_month_real_20yr.png", replace as(png)
graph	close		
		
	
				
graph	twoway	(line TFP_monthly_cost year if gender==1, lpattern(solid) xaxis(1 2) yaxis(1))	///
				(line TFP_monthly_cost year if gender==2, lpattern(dash) xaxis(1 2) yaxis(1))  ///
				(line TFP_monthly_cost_real year if gender==1, lpattern(dot) xaxis(1 2) yaxis(2))	///
				(line TFP_monthly_cost_real year if gender==2, lpattern(dash_dot) xaxis(1 2) yaxis(2)),  ///
				xline(1983 1999 2006, axis(1) lpattern(dot)) xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
				xtitle(Year)	xtitle("", axis(2)) legend(lab (1 "Male") lab(2 "Female") lab(3 "Male real") lab(4 "Female real") ) 	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_FSamt_byyear, replace)		
				
				
*	Generosity of SNAP policy
	*	SNAP index data
	use	"${SNAP_dtInt}/SNAP_policy_data", clear

	gen	year	=	int(yearmonth/100)
	gen	month	=	mod(yearmonth,100)

	collapse	(mean)	SNAP_index_unweighted SNAP_index_weighted, by(year rp_state)
					
	*	Merge with state politics
	merge	1:1	rp_state	year	using		"${SNAP_dtInt}/State_politics", nogen assert(2 3) keep(3)


	summ	SNAP_index_unweighted SNAP_index_weighted	if year==1996	&	rp_state==1

	summ	SNAP_index_unweighted SNAP_index_weighted	if	major_control_dem==1
	summ	SNAP_index_unweighted SNAP_index_weighted	if	major_control_rep==1
	summ	SNAP_index_unweighted SNAP_index_weighted	if	major_control_mix==1



*	State participation rates
use "${SNAP_dtInt}/State_participation_rates"	, clear

	keep	year	rp_state	all	major_control_dem	major_control_rep	major_control_mix
	drop	if	mi(all)
	summ	all	if	major_control_dem==1
	summ	all	if	major_control_rep==1
	summ	all	if	major_control_mix==1
	

*	State politics status
use	"${SNAP_dtInt}/State_politics", clear
keep	if	inrange(year,1978,2019)

	*	Combined index
	gen	major_status	=	(1*major_control_dem) + (2*major_control_rep)
	
	*	Trifecta status by state
	preserve
		collapse (sum) major_control_dem	major_control_rep	major_control_mix, by(rp_state)
		
		sort	major_control_dem
		sort	major_control_rep
	restore
	
	*	Trifecta status by year
	collapse (sum) major_control_dem	major_control_rep	major_control_mix, by(year)
	
	lab	var	major_control_dem	"Democrat Trifecta"
	lab	var	major_control_rep	"Republic Trifecta"
	lab	var	major_control_mix	"Mixed"
	
		graph	twoway	(line major_control_dem year, /*lpattern(dash)*/ xaxis(1) yaxis(1))	///
						(line major_control_rep	year, lpattern(dot) xaxis(1) yaxis(1))  	///
						(line major_control_mix	year, lpattern(dash_dot) xaxis(1) yaxis(1)),  ///
						/*xline(1980 1993 1999 2007, axis(1) lpattern(dot))*/  ytitle(Number of States)	///
						xtitle(Year)	/* title(Monthly Food Expenditure and FS Benefit)*/	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_FSamt_byyear, replace)
		
		graph	export	"${SNAP_outRaw}/state_trifecta.png", replace
		graph	close		
	
	
	
				
				
use    "${SNAP_dtInt}/SNAP_long_PFS",  clear 

keep	year	rp_state	SNAP_index_unweighted SNAP_index_weighted	major_control_dem major_control_rep major_control_mix
duplicates drop
drop	if	mi(SNAP_index_unweighted)
tab	year





keep	year	age_ind	ind_female	TFP_monthly_cost	TFP_monthly_cost_real

keep	if	age_ind==20
collapse	(mean) TFP_monthly_cost	TFP_monthly_cost_real, by(year ind_female)

graph	twoway	(line TFP_monthly_cost year if ind_female==0, lpattern(dash) xaxis(1 2) yaxis(1))	///
				(line TFP_monthly_cost year if ind_female==1, lpattern(dash_dot) xaxis(1 2) yaxis(1)),  ///
				xline(1983 1999 2006, axis(1) lpattern(dot)) xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
				xtitle(Year)	xtitle("", axis(2)) /* title(Monthly Food Expenditure and FS Benefit)*/	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_FSamt_byyear, replace)

			
			
graph	twoway	(line TFP_monthly_cost_real year if ind_female==0, lpattern(dash) xaxis(1 2) yaxis(1))	///
				(line TFP_monthly_cost_real year if ind_female==1, lpattern(dash_dot) xaxis(1 2) yaxis(1)),  ///
				xline(1983 1999 2006, axis(1) lpattern(dot)) xlabel(/*1980 "No payment" 1993 "xxx" 2009 "ARRA" 2020 "COVID"*/, axis(2))	///
				xtitle(Year)	xtitle("", axis(2)) /* title(Monthly Food Expenditure and FS Benefit)*/	bgcolor(white)	graphregion(color(white)) /*note(Source: USDA & BLS)*/	name(foodexp_FSamt_byyear, replace)

			
			