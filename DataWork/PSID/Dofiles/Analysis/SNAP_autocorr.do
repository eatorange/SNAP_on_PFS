


ivregress 2sls 	${depvar}	${RHS}	(${endovar} = ${endovar}_hat)	${reg_weight} ${lowincome}, ///
					/*absorb(x11101ll)*/	cluster (x11101ll)	
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

pwcorr l2_resid resid, sig
spearman	l2_resid resid
ktau	l2_resid resid


xtset	x11101ll year, delta(2)

xtserial ${depvar} ${endovar}_hat	${RHS}	${lowincome}, output


xtserial ${depvar} ${endovar}_hat, output

gen d_PFS = PFS_ppml - l.PFS_ppml
gen d_FSdummy = FSdummy_hat - l.FSdummy_hat 

reg	d_PFS	d_FSdummy, noconst
predict resid_d, r

reg	resid_d l.resid_d, noconst
test l.resid_d==-0.5



