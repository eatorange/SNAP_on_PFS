*Test
cap	drop	SPI_female
cap	drop	SPI_nonWhte
gen	SPI_female	=	SNAP_index_w * rp_female
gen SPI_nonWhte	=	SNAP_index_w * rp_nonWhte


ivreghdfe	PFS_ppml	${RHS}		(FSdummy SNAP_female	= SNAP_index_w	SPI_female)	${reg_weight} if reg_sample==1, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first // savefirst savefprefix(female)  // partial(*_bar9713)
							

cap drop hat1
cap drop hat2
reg		FSdummy		SNAP_index_w	SPI_female	${RHS}				${reg_weight} if reg_sample==1,	cluster(x11101ll)			
predict hat1
reg		SNAP_female		SNAP_index_w	SPI_female	${RHS}				${reg_weight} if reg_sample==1,	cluster(x11101ll)			
predict hat2 



ivreghdfe	PFS_ppml	${RHS}		(FSdummy SNAP_female	= hat1	hat2)	${reg_weight} if reg_sample==1, ///
							/*absorb(x11101ll)*/	cluster(x11101ll)	first // savefirst savefprefix(female)  // partial(*_bar9713)
							
*	1st-stage Not coverging in non-linear regression model	while estimating heterogenous effects.						
cap drop hat1
cap drop hat2
logit	FSdummy		SNAP_index_w	SPI_female	/* 	${RHS} */				${reg_weight} if reg_sample==1,	cluster(x11101ll)							
predict hat1
reg		SNAP_nonWhte	SNAP_index_w	SPI_nonWhte		rp_female	rp_age  rp_age_sq         rp_married  rp_disabled      rp_col		/*	${reg_weight}  */ if reg_sample==1,	cluster(x11101ll)				
logit	SNAP_nonWhte	SNAP_index_w	SPI_nonWhte		rp_female	rp_age  rp_age_sq         rp_married  rp_disabled      rp_col 	/*	${reg_weight}  */	 if reg_sample==1 & !inlist(pattern,719,720),	cluster(x11101ll)				
predict hat2							
								

*	Diagonsis - is it due to multicoliliearlity?
*	Source consulted: https://www.stata.com/support/faqs/statistics/completely-determined-in-logistic-regression/
*	It seems there is, but how can I drop endogenous variables from IV???
egen	pattern = group(SNAP_index_w	SPI_nonWhte	)
logit SNAP_nonWhte	SNAP_index_w	SPI_nonWhte	
predict p
summarize p, d
tab pattern if p <9e-24
list SNAP_nonWhte SNAP_index_w	SPI_nonWhte	 if pattern==719

logit	SNAP_nonWhte	SNAP_index_w		if pattern==720


*** Things I might ask on Statlist...
/*
I am estimating causal effects of safety net program participation on individual well-being using an IV (change in program rules).

    Y: Individual well-being (fractional variable varying from 0 to 1, higher the number, better the well-being is)
    T: program participation (binary, =1 if participated and 0 otherwise). Endogenous
    Z: state-level generosity of program eligibility (continuous varying from 0 to 10. The greater the number, the more generous program eligibility is). Exogenous
    Female: Dummy indicator (=1 if a person is female, 0 otherwise).

Since endogenous X is binary and exogenous Z is continuous, I run logit regression of T on Z and a vector of control variables (gender, age, year FE, etc.), and use its predicted probability, That, as an instrument in 2SLS equation (Mostly Harmless Econometrics, Angrist and Pischke 2009).

The problem occurred when I tried to estimate heterogeneous effects of program participation.
For instance, I try to estimate how program affects differently to females using interaction terms. Now I have two endogenous variables (Tand T*Female) so I need two IVs (Z and Z*Female).

Thus I run the following two logit regressions


[CODE]
logit T Z Z*Female Female ${X}
logit T*Female Z Z*Female Female ${X}
[/CODE]
where Female and ${X} are control variables.