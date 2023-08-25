* In this part I run an event study using saved weights from sdid 
local window =6



gen treated_unit_in_cohort = 0  // treated_unit_in_cohort indicates treated units in each cohort
bys event id (dummy_time): replace treated_unit_in_cohort=service_available[_N] 
		
cap	drop	interact
gen interact = treated_unit_in_cohort * etime2

sum etime2 if etime==-1, meanonly
local base_dummy_yr = r(min)


reghdfe sum_spent_amazon	ib(`base_dummy_yr').interact  [aw=_wt_unit], a(event#id  event#date) vce(cluster id)   // I am only using unit weights for dynamic esitmate



matrix T = r(table)
gen coef = 0 if etime2 == `base_dummy_yr'
gen lb = 0 if etime2 == `base_dummy_yr'
gen ub = 0 if etime2 == `base_dummy_yr'

forvalues t = 0(1)14 {
	if `t' < -1 {
		local tname = abs(`t')
		replace coef = T[1,colnumb(T,"`tname'.interact")] if etime2 == `t'
		replace lb = T[5,colnumb(T,"`tname'.interact")] if etime2 == `t'
		replace ub = T[6,colnumb(T,"`tname'.interact")] if etime2 == `t'
	}
	else if `t' >= 0 {
		replace coef =  T[1,colnumb(T,"`t'.interact")] if etime2 == `t'
		replace lb = T[5,colnumb(T,"`t'.interact")] if etime2 == `t'
		replace ub = T[6,colnumb(T,"`t'.interact")] if etime2 == `t'
	}
}

replace lb = 0 if etime2 == `base_dummy_yr'
replace ub = 0 if etime2 == `base_dummy_yr'

preserve

keep etime2 etime coef lb ub
duplicates drop

sort etime

sum ub, meanonly
local top_range = r(max)
sum lb, meanonly
local bottom_range = r(min)

display max(abs(`bottom_range'),`top_range')
local y_scale = max(abs(`bottom_range'),`top_range')
local y_axis_min = round(-`y_scale') 
local y_axis_max = round(`y_scale')

twoway (sc coef etime, connect(line)) ///
	(rcap ub lb etime)	///
	(function y = 0, range(etime)),  ///
	xline(0, lwidth(thin) lcolor(orange_red)) ///
	xtitle("Months to treatment") ytitle("Average spent on Amazon ($)") yscale(range(`y_axis_min' `y_axis_max') titlegap(2))   xlabel(-6(1)8)  graphregion(color(white)) plotregion(margin(b=0)) legend(off)  legend(off)


graph export "$data/graphs/sdid/all_bef_aft2_th2/level/event_study_dep_15_level_bef_aft2_th2.png", replace