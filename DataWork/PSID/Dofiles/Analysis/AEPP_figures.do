	*	Prepare sub-data for figure 
	
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019", clear
		
		keep	x11101ll	year	wgt_long_fam_adj	sampstr sampcls year	///
				PFS_FI_ppml_noCOLI	_seq	_spell	_end	
		
		sort	x11101ll	year
		gen		l2_PFS_FI_ppml_noCOLI=l2.PFS_FI_ppml_noCOLI
		
		lab	var	_seq					"Food Insecurity (PFS < 0.5) sequence"
		lab	var	_spell					"Food Insecurity (PFS < 0.5) spell"
		lab	var	_end					"Food Insecurity (PFS < 0.5) end year"
		lab	var	l2_PFS_FI_ppml_noCOLI	"Lagged Food insecure (PFS < 0.5)"
		
		*	Save
		save	"${SNAP_dtInt}/SNAP_descdta_1979_2019_sub", replace
	
		*	Put your work path here
		global	SNAP_dtInt		""
	
	
	*	Distribution of spell

		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019_sub", clear
		
		keep	x11101ll	year	wgt_long_fam_adj	sampstr sampcls year	///
				_seq	_spell	_end	
		
		
		cap	mat	drop	spell_pct_all
		
		*	All sample
		tab	_seq	[aw=wgt_long_fam_adj]	if	_end==1,	matcell(spell_freq_w)
		mat	list	spell_freq_w
		local	N=r(N)
		mat	spell_pct_tot	=	spell_freq_w	/	r(N)
		
		mat	spell_pct_all		=	nullmat(spell_pct_all),	spell_pct_tot
		
		*preserve
	
		clear
		set	obs	26
		gen	spell_length	=	_n
		
		svmat	spell_pct_all
		rename	spell_pct_all1	spell_pct_all			
		
		*	Figures
			
			*	All population
		graph hbar spell_pct_all, over(spell_length, sort(spell_percent_w) /*descending*/	label(labsize(vsmall)))	legend(lab (1 "Fraction") size(small) rows(1))	///
			bar(1, fcolor(gs03*0.5)) /*bar(2, fcolor(gs10*0.6))*/	graphregion(color(white)) bgcolor(white) title(Distribution of Spell Length) ytitle(Fraction)
	

			
		*restore
		
		
		*	Yearly FI status change
		
		use	"${SNAP_dtInt}/SNAP_descdta_1979_2019_sub", clear
		
		
		cap	mat	drop	trans_years
		cap	mat	drop	trans_2by2_year
		cap	mat	drop	trans_change_year
		cap	mat	drop	FI_still_year_all
		cap	mat	drop	FI_newly_year_all
		cap	mat	drop	FI_persist_rate*
		cap	mat	drop	FI_entry_rate*
		
		
			*	Year
		global	transyear	1981 1982 1983 1984 1985 1986 1987 1994 1995 1996 1997 1999 2001 2003 2005 2007 2009 2011 2013 2015 2017 2019	//	Years I will use to generate figures
		*	Make a matrix of year matrix
		
				
		foreach	year	of	global	transyear	{			

			*	Make a matrix of years
			mat	trans_years	=	nullmat(trans_years)	\	`year'
		
			*	Change in Status - entire population
			**	Note: here we do NOT limit our sample to non-missing values, as we need the ratio of those with missing values.
			svy, subpop(if year==`year'): tab 	l2_PFS_FI_ppml_noCOLI PFS_FI_ppml_noCOLI, missing
			local	sample_popsize_total=e(N_subpop)
			mat	trans_change_`year' = e(b)[1,5], e(b)[1,2], e(b)[1,8]
			mat	trans_change_year	=	nullmat(trans_change_year)	\	trans_change_`year'
			
		}
		
		
		clear
				
		set	obs	22
		
		*	Matrix for Figure 2
		svmat	trans_years
		svmat	trans_change_year
		rename	(trans_years1 trans_change_year1 trans_change_year2 trans_change_year3)	(year	still_FI	newly_FI	status_unknown)
		drop	status_unknown
		label var	still_FI		"Still food insecure"
		label var	newly_FI		"Newly food insecure"
		
	
		graph bar still_FI newly_FI, over(year, label(angle(vertical))) stack legend(lab (1 "Still FI") lab(2 "Newly FI")	rows(1))	///
		graphregion(color(white)) bgcolor(white)  bar(1, fcolor(gs11)) bar(2, fcolor(gs6)) bar(3, fcolor(gs1))	///
		ytitle(Fraction of Population) title(Change in Food Security Status)	ylabel(0(.025)0.125) 	
		
	