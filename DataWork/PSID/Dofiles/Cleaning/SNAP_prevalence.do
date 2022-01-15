*	Individual data
use "E:\OneDrive - Cornell University\SNAP\DataWork\PSID\DataSets\Raw\Unpacked\ind2019er.dta", clear

	*	2019
	drop	if	ER34701==0

	keep	ER34701 ER31996 ER31997
	duplicates drop

	rename	ER34701	ER72002

	tempfile	ind2019_2019only
	save	`ind2019_2019only'

	*	2017
	use "E:\OneDrive - Cornell University\SNAP\DataWork\PSID\DataSets\Raw\Unpacked\ind2019er.dta", clear
	drop	if	ER34501==0
	
	keep	ER34501 ER31996 ER31997
	duplicates drop

	rename	ER34501	ER66002

	tempfile	ind2019_2017only
	save	`ind2019_2017only'

*	Family-level data (2019)
use "E:\OneDrive - Cornell University\SNAP\DataWork\PSID\DataSets\Raw\Unpacked\fam2019er.dta", clear

merge	1:1	ER72002 using `ind2019_2019only', nogen assert(3)

tempfile	fam2019
save	`fam2019'

*	Make survey structure using cross-sectional family weight
svyset	ER31997 [pweight=ER77632], strata(ER31996)


*	WTR used SNAP last "year" (2018)
di	(20.21/127.59)	//	True participation rate (household-level) *Note: numerator is "FY 2018", so is not perfectly accurate
tab ER72770	//	Unweighted
svy: tabulate ER72770	//	Weighted



*	Family-level data (2017)
use "E:\OneDrive - Cornell University\SNAP\DataWork\PSID\DataSets\Raw\Unpacked\fam2017er.dta", clear

merge	1:1	ER66002 using `ind2019_2017only', nogen assert(3)

tempfile	fam2017
save	`fam2017'

*	Make survey structure using cross-sectional family weight
svyset	ER31997 [pweight=ER71571], strata(ER31996)

*	WTR used SNAP last "year"
di	(21.78/125.82)	//	True participation rate (household-level) *Note: numerator is "FY 2018", so is not perfectly accurate
tab ER66766	//	Unweighted
svy: tabulate ER66766	//	Weighted

