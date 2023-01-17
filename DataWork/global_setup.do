   * ******************************************************************** *
   *
   *       SET UP STANDARDIZATION GLOBALS AND OTHER CONSTANTS
   *
   *           - Set globals used all across the project
   *           - It is bad practice to define these at multiple locations
   *
   * ******************************************************************** *

   * ******************************************************************** *
   * Set all conversion rates used in unit standardization 
   * ******************************************************************** *

   **Define all your conversion rates here instead of typing them each 
   * time you are converting amounts, for example - in unit standardization. 
   * We have already listed common conversion rates below, but you
   * might have to add rates specific to your project, or change the target 
   * unit if you are standardizing to other units than meters, hectares,
   * and kilograms.

   *Standardizing length to meters
       global foot     = 0.3048
       global mile     = 1609.34
       global km       = 1000
       global yard     = 0.9144
       global inch     = 0.0254

   *Standardizing area to hectares
       global sqfoot   = (1 / 107639)
       global sqmile   = (1 / 258.999)
       global sqmtr    = (1 / 10000)
       global sqkmtr   = (1 / 100)
       global acre     = 0.404686

   *Standardizing weight to kilorgrams
       global pound    = 0.453592
       global gram     = 0.001
       global impTon   = 1016.05
       global usTon    = 907.1874996
       global mtrTon   = 1000

   * ******************************************************************** *
   * Set global lists of variables
   * ******************************************************************** *

   **This is a good location to create lists of variables to be used at 
   * multiple locations across the project. Examples of such lists might 
   * be different list of controls to be used across multiple regressions. 
   * By defining these lists here, you can easliy make updates and have 
   * those updates being applied to all regressions without a large risk 
   * of copy and paste errors.

       *Control Variables
       *Example: global household_controls       income female_headed
       *Example: global country_controls         GDP inflation unemployment

   * ******************************************************************** *
   * Set custom adofile path
   * ******************************************************************** *

   **It is possible to control exactly which version of each command that 
   * is used in the project. This prevents that different versions of 
   * installed commands leads to different results.

  
       global ado      "${mastData}/ado"
           adopath ++  "$ado" 
           *adopath ++  "$ado/m" 
           *adopath ++  "$ado/b" 
   

   * ******************************************************************** *
   * Anything else
   * ******************************************************************** *
   
   *	Globals for data prep and analyses
   
	global	numJan=1
	global	numFeb=2
	global	numMar=3
	global	numApr=4
	global	numMay=5
	global	numJun=6
	global	numJul=7
	global	numAug=8
	global	numSep=9
	global	numOct=10
	global	numNov=11
	global	numDec=12
	
	global	sample_years	/*1968	1969	1970	1971	1972	1974	1975	1976	1977*/	1978	1979	1980	1981	1982	1983	1984	///
								1985	1986	1987	1990	1991	1992	1993	1994	1995	1996	1997	1999	2001	2003	2005	2007	///
								2009	2011	2013	2015	2017	2019
		
	global	sample_years_1977	/*1968	1969	1970	1971	1972	1974	1975	1976*/	1977	1978	1979	1980	1981	1982	1983	1984	///
								1985	1986	1987	1990	1991	1992	1993	1994	1995	1996	1997	1999	2001	2003	2005	2007	///
								2009	2011	2013	2015	2017	2019
	
	global	sample_years_comma	/*1968,	1969,	1970,	1971,	1972,	1974,	1975,	1976,	1977,*/	1978,	1979,	1980,	1981,	1982,	1983,	1984,	///
									1985,	1986,	1987,	1990,	1991,	1992,	1993,	1994,	1995,	1996,	1997,	1999,	2001,	2003,	2005,	2007,	///
									2009,	2011,	2013,	2015,	2017,	2019
									
	global	sample_years_1977_comma	/*1968,	1969,	1970,	1971,	1972,	1974,	1975,	1976,*/	1977,	1978,	1979,	1980,	1981,	1982,	1983,	1984,	///
									1985,	1986,	1987,	1990,	1991,	1992,	1993,	1994,	1995,	1996,	1997,	1999,	2001,	2003,	2005,	2007,	///
									2009,	2011,	2013,	2015,	2017,	2019
	
	global	sample_years_no1968		/*1969	1970	1971	1972	1974	1975	1976	1977*/	1978	1979	1980	1981	1982	1983	1984	///
										1985	1986	1987	1990	1991	1992	1993	1994	1995	1996	1997	1999	2001	2003	2005	2007	///
										2009	2011	2013	2015	2017	2019
		
	global	sample_years_no1968_comma	/*1969,	1970,	1971,	1972,	1974,	1975,	1976,	1977,*/	1978,	1979,	1980,	1981,	1982,	1983,	1984,	///
											1985,	1986,	1987,	1990,	1991,	1992,	1993,	1994,	1995,	1996,	1997,	1999,	2001,	2003,	2005,	2007,	///
											2009,	2011,	2013,	2015,	2017,	2019
	
	
	global	seqnum_years	/*xsqnr_1976 xsqnr_1977*/ xsqnr_1978 xsqnr_1979 xsqnr_1980 xsqnr_1981 xsqnr_1982 xsqnr_1983 xsqnr_1984 xsqnr_1985 xsqnr_1986 xsqnr_1987 xsqnr_1990 ///
							xsqnr_1991 xsqnr_1992 xsqnr_1993 xsqnr_1994 xsqnr_1995 xsqnr_1996 xsqnr_1997 xsqnr_1999 xsqnr_2001 xsqnr_2003 xsqnr_2005 xsqnr_2007 xsqnr_2009	///
							xsqnr_2011 xsqnr_2013 xsqnr_2015 xsqnr_2017 xsqnr_2019
							
	global	seqnum_years_1977	/*xsqnr_1975 xsqnr_1976*/ xsqnr_1977 xsqnr_1978 xsqnr_1979 xsqnr_1980 xsqnr_1981 xsqnr_1982 xsqnr_1983 xsqnr_1984 xsqnr_1985 xsqnr_1986 xsqnr_1987 xsqnr_1990 ///
								xsqnr_1991 xsqnr_1992 xsqnr_1993 xsqnr_1994 xsqnr_1995 xsqnr_1996 xsqnr_1997 xsqnr_1999 xsqnr_2001 xsqnr_2003 xsqnr_2005 xsqnr_2007 xsqnr_2009	///
								xsqnr_2011 xsqnr_2013 xsqnr_2015 xsqnr_2017 xsqnr_2019
	
	global	seqnum_years_1977_comma	/*xsqnr_1975, xsqnr_1976,*/ xsqnr_1977, xsqnr_1978, xsqnr_1979, xsqnr_1980, xsqnr_1981, xsqnr_1982, xsqnr_1983, xsqnr_1984, xsqnr_1985, xsqnr_1986, xsqnr_1987, xsqnr_1990, ///
									xsqnr_1991, xsqnr_1992, xsqnr_1993, xsqnr_1994, xsqnr_1995, xsqnr_1996, xsqnr_1997, xsqnr_1999, xsqnr_2001, xsqnr_2003, xsqnr_2005, xsqnr_2007, xsqnr_2009,	///
									xsqnr_2011, xsqnr_2013, xsqnr_2015, xsqnr_2017, xsqnr_2019
	
	label	define	yes1no0	0	"No"	1	"Yes",	replace

	
	*	States
	*	Note: state codes here are slightly different from that in PFS paper, as Rhode Island (rp_state_enum39) exists here while it didnt exist in PFS paper...
		
		*	Reference state
		global	state_bgroup	rp_state_enum32	//	NY
		
		*	Excluded states (Alaska, Hawaii, U.S. territory, DK/NA)
		global	state_group0	rp_state_enum1	rp_state_enum52	///	//	Inapp, DK/NA
								rp_state_enum51	rp_state_enum51	//	AK, HA
		global	state_group_ex	${state_group0}
		
		*	Northeast
		global	state_group1	rp_state_enum19 rp_state_enum29 rp_state_enum45	///	//	ME, NH, VT
								rp_state_enum21 rp_state_enum7	rp_state_enum39	//	MA, CT, RI
		global	state_group_NE	${state_group1}
			
		*	Mid-atlantic
		global	state_group2	rp_state_enum38	//	PA
		global	state_group3	rp_state_enum30	//	NJ
		global	state_group4	rp_state_enum9	rp_state_enum8	rp_state_enum20	//	DC, DE, MD
		global	state_group5	rp_state_enum46	//	VA
		global	state_group_MidAt	${state_group2}	${state_group3}	${state_group4}	${state_group5}
		
		*	South
		global	state_group6	rp_state_enum33	rp_state_enum40	//	NC, SC
		global	state_group7	rp_state_enum11	//	GA
		global	state_group8	rp_state_enum17	rp_state_enum41	rp_state_enum48	//	KT, TN, WV
		global	state_group9	rp_state_enum10	//	FL
		global	state_group10	rp_state_enum2	rp_state_enum4	rp_state_enum24 rp_state_enum18	//	AL, AR, MS, LA
		global	state_group11	rp_state_enum43	//	TX
		global	state_group_South	${state_group6}	${state_group7}	${state_group8}	${state_group9}	${state_group10}	${state_group11}
		
		*	Mid-west
		global	state_group12	rp_state_enum35	//	OH
		global	state_group13	rp_state_enum14	//	IN
		global	state_group14	rp_state_enum22 	//	MI
		global	state_group15	rp_state_enum13	//	IL
		global	state_group16	rp_state_enum23 rp_state_enum49	//	MN, WI
		global	state_group17	rp_state_enum15	rp_state_enum25	//	IA, MO
		global	state_group_MidWest	${state_group12}	${state_group13}	${state_group14}	${state_group15}	${state_group16}	${state_group17}
		
		*	West
		global	state_group18	rp_state_enum16	rp_state_enum27	///	//	KS, NE
								rp_state_enum34	rp_state_enum41	///	//	ND, SD
								rp_state_enum36	//	OK
		global	state_group19	rp_state_enum3	rp_state_enum6	///	//	AZ, CO
								rp_state_enum12	rp_state_enum26	///	//	ID, MT
								rp_state_enum28	rp_state_enum31	///	//	NV, NM
								rp_state_enum44	rp_state_enum50		//	UT, WY
		global	state_group20	rp_state_enum37	rp_state_enum47	//	OR, WA
		global	state_group21	rp_state_enum5	//	CA						
		global	state_group_West	${state_group18}	${state_group19}	${state_group20}	${state_group21}	
	
	*	Variable label
	label define	statecode		0	"Inap.: U.S. territory or foreign country"	99	"D.K; N.A"	///
									1	"Alabama"		2	"Arizona"			3	"Arkansas"	///
									4	"California"	5	"Colorado"			6	"Connecticut"	///
									7	"Delaware"		8	"D.C."				9	"Florida"	///
									10	"Georgia"		11	"Idaho"				12	"Illinois"	///
									13	"Indiana"		14	"Iowa"				15	"Kansas"	///
									16	"Kentucky"		17	"Lousiana"			18	"Maine"		///
									19	"Maryland"		20	"Massachusetts"		21	"Michigan"	///
									22	"Minnesota"		23	"Mississippi"		24	"Missouri"	///
									25	"Montana"		26	"Nebraska"			27	"Nevada"	///
									28	"New Hampshire"	29	"New Jersey"		30	"New Mexico"	///
									31	"New York"		32	"North Carolina"	33	"North Dakota"	///
									34	"Ohio"			35	"Oklahoma"			36	"Oregon"	///
									37	"Pennsylvania"	38	"Rhode Island"		39	"South Carolina"	///
									40	"South Dakota"	41	"Tennessee"			42	"Texas"	///
									43	"Utah"			44	"Vermont"			45	"Virginia"	///
									46	"Washington"	47	"West Virginia"		48	"Wisconsin"	///
									49	"Wyoming"		50	"Alaska"			51	"Hawaii"	99	"DK/NA",	replace

   **Everything that is constant may be included here. One example of
   * something not constant that should be included here is exchange
   * rates. It is best practice to have one global with the exchange rate
   * here, and reference this each time a currency conversion is done. If 
   * the currency exchange rate needs to be updated, then it only has to
   * be done at one place for the whole project.
