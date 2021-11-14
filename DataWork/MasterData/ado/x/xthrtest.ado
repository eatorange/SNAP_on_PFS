* Born and Breitung (2016) HR-test for serial correlation
*! Version 1.1.1 31jan2017
* Contact jesse.wursten@kuleuven.be for bug reports/inquiries.

* Changelog
** 31jan2017: Updated tooShort mechanism (minimum is 3, not 4)
**  6jan2017: Added preserve-restore framework

cap mata mata drop hr_statistic()
cap mata mata drop hr_statistic_unbalanced()
cap program drop xthrtest

program define xthrtest, rclass
	version 12
	preserve

	** Technicalities
	syntax [varlist(default=none)] [if] [in] [, force hideerror]
	
	*** Postestimation?
	tempvar residuals
	if "`varlist'" == "" {
		predict `residuals', ue
		local varlist = "`residuals'"
		local postEstimation = "1"
	}
	
	** Fill out sample for mata (we reshape in Mata assuming a rectangular sample)
	tsfill, full
	
	*** Mark out if/in restrictions
	marksample toUse, novarlist
	
	*** Obtain time and panel variables
	qui xtset
	local panelvar = r(panelvar)
	local timevar = r(timevar)
	
	
	** Print results header
	if "`postEstimation'" == "" di as result _newline "Heteroskedasticity-robust Born and Breitung (2016) HR-test on `varlist'"
	else 						di as result _newline "Heteroskedasticity-robust Born and Breitung (2016) HR-test as postestimation"
	di as text "Panelvar: `panelvar'"
	di as text "Timevar: `timevar'"
	di as text "{hline 30}{c TT}{hline 23}{c TT}{hline 16}{c TT}{hline 14}{c TRC}"
	di as text _col(2) %~28s = "Variable"  _col(30) " {c |}" _skip(2) "HR-stat" _skip(4) "p-value" _skip(2) " {c |}" _skip(6) "N" _skip(4) "maxT" " {c |}" %~14s = "balance?" "{c |}" 
	di as text "{hline 30}{c +}{hline 23}{c +}{hline 16}{c +}{hline 14}{c RT}"

	** Calculate statistic
	tempname stat pvalue obsCount
	tempvar t id toUse2
	local j = 1
	foreach var of local varlist {
		*** Clear locals
		local balance = ""
		local errorMessage = ""
		local tooShort = ""
		local minT = ""
		
		*** Obtain number of time and panel units
		qui egen `t' = group(`timevar') if `toUse' == 1 & ~missing(`var')
		sum `t', meanonly
		local timelength = r(max)
		
		qui egen `id' = group(`panelvar') if `toUse' == 1 & ~missing(`var')
		sum `id', meanonly
		
		local panelunits = r(max)
		
		***** Tag empty panels
		qui bysort `panelvar': egen `obsCount' = count(`var')
				
		*** Check balancedness
		local balance = ""
		
		**** Unbalanced
		qui count if ~missing(`var') & `toUse' == 1
		local totalObsUsed = r(N)
		local requiredObs = `timelength'*`panelunits'
		
		if `totalObsUsed' != `requiredObs' 	local balance = "unbalanced"
		
		**** With gaps
		tempvar gap
		qui bysort `panelvar' (`timevar'): gen `gap' = 1 if missing(`var') & ~missing(L.`var', F.`var') & `toUse' == 1
		qui count if `gap' == 1
		if r(N) != 0 local balance = "gaps (error)"
		
		**** Balanced
		if "`balance'" == "" local balance = "balanced"
		if "`force'" != "" & "`balance'" == "" local balance = "unbalanced"
		
		*** Unless force is specified ...
		if "`force'" == "" {	
			* Test if residuals include the fixed effect
			tempvar mean_resid
			qui bysort `panelvar' (`timevar'): egen `mean_resid' = mean(`var') if `toUse' == 1
			qui sum `mean_resid' if `toUse' == 1
			drop `mean_resid'
			if r(sd) < 0.001 | abs(r(max)) < 0.001 | abs(r(min)) < 0.001 {
				*noisily di as error _col(2) %~28s = abbrev("`var'",28) 
				noisily di as error "`var': " _continue
				noisily di as error _col(4) "Residuals do not appear to include the fixed effect."
				noisily di as error _col(4) "This test is made to function with ue = c_i + e_it."
				noisily di as error _col(4) "If you are sure that your residuals do indeed include" _newline _col(4) "the fixed effect (programming bugs happen),"
				noisily di as error _col(4) "specify 'force' to skip this test."
				continue
			}
			
			* Test if T is sufficiently long
			tempvar nonMissing
			qui bysort `panelvar' (`timevar'): egen `nonMissing' = count(`var') if `obsCount' > 0
			sum `nonMissing', meanonly
			local minT = r(min)
			if `minT' < 4 local tooShort = "tooShort"
			
			drop `nonMissing'
		}
		
		
					
		*** Update toUse variable 
		**** Exclude missings for the balanced case
		qui gen `toUse2' = `toUse'
		qui replace `toUse2' = 0 if missing(`var')
		
		**** Make sure unbalanced case performs properly
		qui replace `toUse' = 0 if `obsCount' == 0
		drop `obsCount'

		*** Run calculations
		if "`tooShort'" == "" {
			if "`balance'" == "balanced" mata: hr_statistic("`var'", "`toUse2'", `timelength', `panelunits')
			else if "`balance'" == "unbalanced" mata: hr_statistic_unbalanced("`var'", "`toUse'", `panelunits')
			scalar `stat' = round(HR, 0.001)
			scalar `pvalue' = round(pvalue, 0.001)
			
			else if "`balance'" == "gaps (error)" {
				scalar `stat' = .
				scalar `pvalue' = .
				scalar HR = .
				scalar pvalue = .
			}
		}
		
		else if "`tooShort'" != "" {
			scalar `stat' = .
			scalar `pvalue' = .
			scalar HR = .
			scalar pvalue = .
			local errorMessage "At least one panel is too short, i.e. minT(`minT') < 4"
		}
		
		if "`postEstimation'" == "1" local var = "Post Estimation"
		if "`errorMessage'" == "" di _col(2) %~28s = abbrev("`var'",28) _col(30)  " {c +}" _skip(3) %4.2f = `stat' _col(46) %4.3f = `pvalue' _col(55) "{c +}" %7.0f = `panelunits' %8.0f = `timelength' " {c +}" %~14s = "`balance'" "{c RT}"
		if "`errorMessage'" != "" & "`hideerror'" == "" di as error _col(2) "`var': `errorMessage'"
		
		** Prep for return
		drop `toUse2' `t' `id'
		mat hrs = (nullmat(hrs), HR)
		mat ps = (nullmat(ps), pvalue)
		
		** Return as scalar (more useful in some cases)
		return scalar hr`j' = HR
		return scalar pvalue`j' = pvalue
		local j = `j' + 1
	}

	** Notes
	di as text "{hline 30}{c BT}{hline 23}{c BT}{hline 16}{c BT}{hline 14}{c BRC}"
	di _col(2) "Notes: Under H0, HR ~ N(0,1)"
	di as txt _col(5) "H0: No first-order serial correlation."
	di as txt _col(5) "Ha: Some first order serial correlation."
	
	** Return
	return matrix HR = hrs
	return matrix p = ps
	
	restore
end

mata:
	void hr_statistic(string scalar varname, string scalar toUse, real scalar T, real scalar N) {
		real matrix UE, V0, V1, diagMatrix, zeroMaker; real scalar HR, pvalue
		
		// ue = fe + e (currently we just use e, as it also seems to work)
		// me = e
		UE = rowshape(st_data(., varname, toUse), N)'
		
		// V0
		V0 = J(T-3, T, 0) :- 1:/range(2, T-2, 1)

		diagMatrix = J(T-3, 1, 0), I(T-3), J(T-3, 2, 0)

		zeroMaker = J(T-3, 1, .), lowertriangle(J(T-3, T-3, 1)), J(T-3, 2, 0)
		_editvalue(zeroMaker, 1, .)
		zeroMaker = zeroMaker :+ 1:/range(2, T-2, 1)
		_editmissing(zeroMaker, 0)

		V0 = V0 + diagMatrix + zeroMaker

		
		// V1
		V1 = J(T-3, T, 0) :- 1:/range(T-2, 2, -1)
		
		diagMatrix = J(T-3, 2, 0), I(T-3), J(T-3, 1, 0)
		
		zeroMaker = J(T-3, 2, 0), uppertriangle(J(T-3, T-3, 1)), J(T-3, 1, .)
		_editvalue(zeroMaker, 1, .)
		zeroMaker = zeroMaker :+ 1:/range(T-2, 2, -1)
		_editmissing(zeroMaker, 0)

		V1 = V1 + diagMatrix + zeroMaker

		// At
		At = V0'V1
		
		// Z
		Z = J(1, N, .)
		for(n=1; n<=N; n++) {
			Z[1, n] = UE[., n]'*At*UE[.,n]
		}
		
		Z2 = (diagonal(UE'*At*UE))'
		
		// Qp-tilde		
		HR = sum(Z)/sqrt(sum(Z:^2) - 1/N*(sum(Z))^2)
		pvalue = 2*(1-normal(abs(HR)))

		// Store results
		st_numscalar("HR", HR)
		st_numscalar("pvalue", pvalue)
	}
end

mata:
	void hr_statistic_unbalanced(string scalar varname, string scalar toUse, real scalar N) {
		real matrix UE, V0, V1, diagMatrix, zeroMaker; real scalar HR, pvalue
		
		UE = rowshape(st_data(., varname, toUse), N)'
		Ti = colnonmissing(UE)

		Z = J(1, N, .)
		for(n=1; n<=N; n++) {
			V0 = J(Ti[n]-3, Ti[n], 0) :- 1:/range(2, Ti[n]-2, 1)
			diagMatrix = J(Ti[n]-3, 1, 0), I(Ti[n]-3), J(Ti[n]-3, 2, 0)
			zeroMaker = J(Ti[n]-3, 1, .), lowertriangle(J(Ti[n]-3, Ti[n]-3, 1)), J(Ti[n]-3, 2, 0)
			_editvalue(zeroMaker, 1, .)
			zeroMaker = zeroMaker :+ 1:/range(2, Ti[n]-2, 1)
			_editmissing(zeroMaker, 0)
			
			V0 = V0 + diagMatrix + zeroMaker
			

			V1 = J(Ti[n]-3, Ti[n], 0) :- 1:/range(Ti[n]-2, 2, -1)
			diagMatrix = J(Ti[n]-3, 2, 0), I(Ti[n]-3), J(Ti[n]-3, 1, 0)
			zeroMaker = J(Ti[n]-3, 2, 0), uppertriangle(J(Ti[n]-3, Ti[n]-3, 1)), J(Ti[n]-3, 1, .)
			_editvalue(zeroMaker, 1, .)
			zeroMaker = zeroMaker :+ 1:/range(Ti[n]-2, 2, -1)
			_editmissing(zeroMaker, 0)

			V1 = V1 + diagMatrix + zeroMaker
			
			Ati = V0'V1
			UEi = select(UE[.,n], UE[.,n]:!=.)
			Z[1, n] = UEi'*Ati*UEi
		}
		
		// Qp-tilde		
		HR = sum(Z)/sqrt(sum(Z:^2) - 1/N*(sum(Z))^2)
		pvalue = 2*(1-normal(abs(HR)))

		// Store results
		st_numscalar("HR", HR)
		st_numscalar("pvalue", pvalue)
	}
end
