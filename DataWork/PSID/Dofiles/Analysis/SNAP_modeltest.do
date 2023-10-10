*	*	Setup
		*	Setup
				global	depvar		PFS_FI_ppml	//	PFS_ppml	//					
				global	endovar		FSdummy	//	FSamt_capita
				global	IV			SNAP_index_w	//	citi6016	//	inst6017_nom	//	citi6016	//		//	errorrate_total		//			share_welfare_GDP_sl // SSI_GDP_sl //  SSI_GDP_sl SSI_GDP_slx
				global	IVname		index_w	//	CIM	//	
				
				*	Sample and weight choice
				loc	income_below130	1	//	Keep only individuals who were ever below 130% income line 
				loc	weighted		1	//	Generate survey-weighted estimates
				loc	control_ind		0	//	Include individual-level controls
				
				*loc	same_RP_9713	0	//	Keep only individuals were same RP over the period
				
				if	`income_below130'==1	{
					
					global	lowincome	&	income_ever_below_130_9713==1	//	Add condition for low-income population.
					*keep if income_ever_below_130_9713==1
				}
				else	{
					
					global	lowincome	//	null macro
					
				}
				
				di	"${lowincome}"
				
				
				*	Weight setting
				if	`weighted'==1	{
					
					global	reg_weight		[pw=wgt_long_ind]
					global	sum_weight		[aw=wgt_long_ind]
				}
				else	{
					
					global	reg_weight		//	null macro
					global	sum_weight		//	null macro
					
				}
				
				*	Individual-level control setting
				if	`control_ind'==1	{
					
					global	FSD_on_FS_X	${FSD_on_FS_X_ind}
					
				}
				else	{
					
					global	FSD_on_FS_X	${FSD_on_FS_X_noind}
					
				}
				
/*
				*	Same RP
				if	`same_RP_9713'==1	{
					keep	if	sameRP_9713==1
				}
				
*/
				
	*	Bivariate regression
	