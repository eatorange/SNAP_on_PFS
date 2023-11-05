


ivregress 2sls 	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)	
predict resid, r					
gen l2_resid = l2.resid
gen l4_resid = l4.resid
gen l6_resid = l6.resid

reg	resid 	l2_resid
reg	resid	l2_resid l4_resid 
reg	resid	l2_resid l4_resid l6_resid

scatter l2_resid resid if e(sample)

pwcorr l2_resid resid, sig