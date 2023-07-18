import	excel	"${clouldfolder}/DataWork/C2ER/COLI Historical Data - 1990 Q1 - 2022 Annual.xlsx", firstrow sheet(HistoricalIndexData)	clear

	*	Notes on data
	*	Up to 2006, the data has full quarterly value (Q1 to Q4)
	*	Since 2007, the data has Q1-Q3 and annual data (no Q4) , except 2020 which is out of our study period.
	
	
	*	Keep relevant variables only
	keep	YEAR QUARTER STATE_CODE STATE_NAME COMPOSITE_INDEX GROCERY_ITEMS
	
	*	Replace unknown value as missing
	*	There's on observation (1991 Q1 NY Ithaca) where composite index was recorded as "parta". Will replace it as missing.
	replace	GROCERY_ITEMS=""	if	GROCERY_ITEMS=="parta"
	
	*	Destring cost index
	destring	GROCERY_ITEMS, replace
	
	*	Replace quarter with numeric value
	loc	var	svy_quarter
	cap	drop	`var'
	gen		`var'=1	if	QUARTER=="Q1"	//	Variable name to be equal to the one in main data
	replace	`var'=2	if	QUARTER=="Q2"	//	Variable name to be equal to the one in main data
	replace	`var'=3	if	QUARTER=="Q3"	//	Variable name to be equal to the one in main data
	replace	`var'=4	if	QUARTER=="Q4"	//	Variable name to be equal to the one in main data
	replace	`var'=99	if	QUARTER=="Annual"	//	Variable name to be equal to the one in main data
	
	*	Due to different data availability, we keep only "ANNUAL" value since 2007
	drop	if	svy_quarter!=99	&	inrange(YEAR,2007,2020)
	
	*	Adjust 2013 data whose annual average is 96 instead of 100
	replace GROCERY_ITEMS = GROCERY_ITEMS * 100/94.6908 if YEAR==2013
	
	*	Compute state-year-level average value
	collapse	COMPOSITE_INDEX GROCERY_ITEMS, by(YEAR STATE_NAME)
	
	*	Graph time trend for selected states
	graph	twoway (bar GROCERY_ITEMS YEAR if STATE_NAME=="California", title(Grocery Index in California))
	graph export "E:\GitHub\SNAP_on_FS\DataWork\PSID\Output\Raw\COLI_CA.png", as(png) name("Graph") replace
	
	graph	twoway (bar GROCERY_ITEMS YEAR if STATE_NAME=="Texas", title(Grocery Index in Texas))
	graph export "E:\GitHub\SNAP_on_FS\DataWork\PSID\Output\Raw\COLI_TX.png", as(png) name("Graph") replace
	
	graph	twoway (bar GROCERY_ITEMS YEAR if STATE_NAME=="Mississippi", title(Grocery Index in Mississippi))
	graph export "E:\GitHub\SNAP_on_FS\DataWork\PSID\Output\Raw\COLI_MS.png", as(png) name("Graph") replace
	
	graph	twoway (bar GROCERY_ITEMS YEAR if STATE_NAME=="New York", title(Grocery Index in NY))
	graph export "E:\GitHub\SNAP_on_FS\DataWork\PSID\Output\Raw\COLI_NY.png", as(png) name("Graph") replace
	
	*	See state-level average
	preserve
		collapse COMPOSITE_INDEX GROCERY_ITEMS, by(STATE_NAME)	
	restore
	
	*	See annual national trend
		collapse COMPOSITE_INDEX GROCERY_ITEMS, by(YEAR)	
		graph	twoway (bar GROCERY_ITEMS YEAR, title(Grocery Index in NY))

//	use  "${SNAP_dtRaw}/Statecode.dta", clear