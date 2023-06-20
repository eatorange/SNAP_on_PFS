*	This do-file generates descriptive analyses for historical PFS data, from 1979 to 2019 (with some years missing)


 use	"${SNAP_dtInt}/SNAP_const", clear
 
  
 	*	Declare macros
		global	indvars		age_ind	ind_female	
		
		global	demovars	rp_age	rp_White rp_nonWhte	rp_married	rp_female	famnum ratio_child
		global	familyvars	famnum ratio_child
		global	eduvars		rp_NoHS rp_HS rp_somecol rp_col
		global	healthvars	rp_disabed	
		global	regionvars	rp_region_NE rp_region_MidAt rp_region_South rp_region_MidWest rp_region_West
		global	empvars		rp_employed
		global	foodvars	FS_rec_wth
		global	econvars	fam_income_pc_real	FS_rec_amt_capita_real
		
		
	*	Additional cleaning
		lab	var	fam_income_pc_real	"Family income per capita (Jan 2019 dollars)"
		lab	var	FS_rec_amt_capita_real	"stamp amount received (Jan 2019 dollars)"
		
		
	*	Pooled summary stats
	
	
		/*food_stamp_used_1yr*/	food_stamp_used_0yr	child_meal_assist // 2022-12-15: Changed "last year" to "this year", since we add this year's stamp value to food expenditure.
		fam_income_pc_real
		
				local 	outcomevars	PFS_glm
		
		
		local	sumvars	`demovars'	`eduvars'		`empvars'	`healthvars'	`econvars'	`familyvars'		`foodvars'		`changevars'	`outcomevars'	`regionvars'

		summ	`sumvars'
 *	Pooled summary statistics
