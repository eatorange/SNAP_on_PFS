

xtset	x111

cap	drop	resid
cap	drop	l*_resid
ivregress 2sls 	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample_9713==1 & income_ever_below_130_9713==1, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)	
					
newey	${depvar}	 ${endovar}_hat	${RHS} 	${sum_weight} ${lowincome}, lag(2)

predict resid, r					
gen l2_resid = l2.resid
gen l4_resid = l4.resid
gen l6_resid = l6.resid

*	Distribution of residuals (somewhat normal...)
kdensity	resid


*	Serial correlations

reg	resid 	l2_resid
reg	resid	l2_resid l4_resid 
reg	resid	l2_resid l4_resid l6_resid

scatter l2_resid resid if e(sample)

pwcorr l6_resid l4_resid l2_resid resid, sig
spearman	l6_resid l4_resid l2_resid resid
ktau	l6_resid l4_resid l2_resid resid


xtset	x11101ll year, delta(2)

*	Autocorrlation test in linear panel data (Wooldridge 2002)
xtserial ${depvar} ${endovar}_hat	${RHS}	${lowincome}, output

	*	Manual way
	gen d_PFS = PFS_ppml - l.PFS_ppml
	gen d_FSdummy = FSdummy_hat - l.FSdummy_hat 

	reg	d_PFS	d_FSdummy, noconst
	predict resid_d, r

	reg	resid_d l.resid_d, noconst
	test l.resid_d==-0.5



*	Testing differents standard errors
	
	*	Benchmark model: Time FE and Mundlak

		*	2SLS (no cluster)
		ivregress 2sls 	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1 //, 	cluster(x11101ll)	
		
		*	Manual 2nd stage (no cluster, to compare with Newey- and DK-standard error)
			**	Issue: I found that manual standard erorrs are very similar to that of correct standard errors.
		cap	drop	temp
		reg	${endovar}	${endovar}_hat	${RHS}	${reg_weight}	 if reg_sample==1 //, 	cluster(x11101ll)	
		predict temp
		reg		${depvar}	temp	${RHS}	${reg_weight}	 if reg_sample==1 //, 	cluster(x11101ll)	
		
		*	Driscoll-Kraay standard errors
		xtscc ${depvar}   temp	${RHS}	${sum_weight}	 if reg_sample==1, lag(1) // 1 lag
		xtscc ${depvar}   temp	${RHS}	${sum_weight}	 if reg_sample==1, lag(2) // 2 lags
		
		*	Manual 2nd stage (with cluster)
		cap	drop	temp
		reg	${endovar}	${endovar}_hat	${RHS}	${reg_weight}	 if reg_sample==1, 	cluster(x11101ll)	
		predict temp
		reg		${depvar}	temp	${RHS}	${reg_weight}	 if reg_sample==1, 	cluster(x11101ll)	
		
		*	Compared to clean 2SLS regression standard error (with cluster) - benchmark model
		ivregress 2sls 	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, 	cluster(x11101ll)	
	
	
		*	GLS (Caution: takes some time)
		*xtgls	${depvar}	temp	${RHS}	${sum_weight}	if reg_sample==1 // homoskedastic, no autocorrelation)
	
	
	
		*	Unclustered
		ivreghdfe	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, absorb(x11101ll)	first savefirst savefprefix(${Zname})
		
		*	Unclustered manual
		cap	drop	temp
		reghdfe	${endovar}	${endovar}_hat	${RHS}	${reg_weight}  if reg_sample==1, absorb(x11101ll) //, 	cluster(x11101ll)	
		predict temp
		reghdfe		${depvar}	temp	${RHS}	${reg_weight}	 if reg_sample==1, absorb(x11101ll) //, 	cluster(x11101ll)	
		
		
		*	Driscoll-Kraay SE
		ivreghdfe	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, absorb(x11101ll)	dkraay(1) 
		ivreghdfe	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, absorb(x11101ll)	dkraay(2) 
		
		*	Clustered standard error
		ivreghdfe	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} if reg_sample==1, absorb(x11101ll) cluster(x11101ll)	first savefirst savefprefix(${Zname})
		