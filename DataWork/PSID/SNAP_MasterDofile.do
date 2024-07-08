   * ******************************************************************** *
   * ******************************************************************** *
   *                                                                      *
   *               SNAP on FS		                                        *
   *               MASTER DO_FILE                                         *
   *                                                                      *
   * ******************************************************************** *
   * ******************************************************************** *

       /*
       ** PURPOSE:      Write intro to survey round here

       ** OUTLINE:      PART 0: Standardize settings and install packages
                        PART 1: Prepare folder path globals
                        PART 2: Run the master dofiles for each high-level task

       ** IDS VAR:      list_ID_var_here         //Uniquely identifies households (update for your project)

       ** NOTES:

       ** WRITTEN BY:   Seungmin Lee

       ** Last date modified:  14 Nov 2021
       */

*iefolder*0*StandardSettings****************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 0:  INSTALL PACKAGES AND STANDARDIZE SETTINGS
   *
   *           - Install packages needed to run all dofiles called
   *            by this master dofile.
   *           - Use ieboilstart to harmonize settings across users
   *
   * ******************************************************************** *

*iefolder*0*End_StandardSettings************************************************
*iefolder will not work properly if the line above is edited

   *Install all packages that this project requires:
   *(Note that this never updates outdated versions of already installed commands, to update commands use adoupdate)
   * I no longer use this code, as sharing the same ado files across the users (it is done in globals_setup.do file) would ensure better replicability. 

   *Standardize settings accross users
   *ssc install ietoolkit, replace
   ieboilstart, version(14.1) maxvar(32767) matsize(11000)        //Set the version number to the oldest version used by anyone in the project team
   `r(version)'                        //This line is needed to actually set the version from the command above

*iefolder*1*FolderGlobals*******************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 1:  PREPARING FOLDER PATH GLOBALS
   *
   *           - Set the global box to point to the project folder
   *            on each collaborator's computer.
   *           - Set other locals that point to other folders of interest.
   *
   * ******************************************************************** *

   * Users
   * -----------

   * Root folder globals
   * ---------------------
   
   * Add local folder name of each collaborator.
   * `c(username)' is the system macro of STATA which has username
   * To find collaborator's user name, type -di "`c(username)'"- in STATA

   if "`c(username)'"== "Seungmin Lee" {	//	Min, office PC
       global	projectfolder	"E:/GitHub/SNAP_on_FS"		//	Github location
	   global	clouldfolder	"E:/Dropbox/Cornell Backups/Box Backup/SNAP"	// Clouldfolder location (where rawdata is stored)
   }

   if "`c(username)'"== "ftac2" {	//	Min, personal laptop
       global	projectfolder	"E:/GitHub/SNAP_on_FS"
	   global	clouldfolder	"E:/Dropbox/Cornell Backups/Box Backup/SNAP"
   }
   
   if "`c(username)'"== "xxx" {	//	
       global	projectfolder	"..."
	   global	clouldfolder	"..."
   }
   
   if "`c(username)'"== "xxx" {	//	
       global	projectfolder	"..."
	   global	clouldfolder	"..."
   }

* These lines are used to test that the name is not already used (do not edit manually)

   * Project folder globals
   * ---------------------

   global dataWorkFolder         "$projectfolder/DataWork"

*iefolder*1*FolderGlobals*master************************************************
*iefolder will not work properly if the line above is edited

   global mastData               "$dataWorkFolder/MasterData" 

*iefolder*1*FolderGlobals*encrypted*********************************************
*iefolder will not work properly if the line above is edited

  // global encryptFolder          "$dataWorkFolder/EncryptedData" 

*iefolder*1*FolderGlobals*PSID**************************************************
*iefolder will not work properly if the line above is edited


   *Encrypted round sub-folder globals
   global SNAP                   "$dataWorkFolder/PSID" 

   *DataSets sub-folder globals
   global SNAP_dt                "$SNAP/DataSets"
   global SNAP_dtRaw			 "$clouldfolder/DataWork/PSID/DataSets/Raw"
   global SNAP_dtInt             "$SNAP_dt/Intermediate" 
   global SNAP_dtFin             "$SNAP_dt/Final" 

   *Dofile sub-folder globals
   global SNAP_do                "$SNAP/Dofiles" 
   global SNAP_doCln             "$SNAP_do/Cleaning" 
   global SNAP_doCon             "$SNAP_do/Construct" 
   global SNAP_doAnl             "$SNAP_do/Analysis" 

   *Output sub-folder globals
   global SNAP_out               "$SNAP/Output" 
   global SNAP_outRaw            "$SNAP_out/Raw" 
   global SNAP_outFin            "$SNAP_out/Final" 

   *Questionnaire sub-folder globals
   global SNAP_prld              "$SNAP_quest/PreloadData" 
   global SNAP_doc               "$SNAP_quest/Questionnaire Documentation" 

*iefolder*1*End_FolderGlobals***************************************************
*iefolder will not work properly if the line above is edited


*iefolder*2*StandardGlobals*****************************************************
*iefolder will not work properly if the line above is edited

   * Set all non-folder path globals that are constant accross
   * the project. Examples are conversion rates used in unit
   * standardization, different sets of control variables,
   * adofile paths etc.

   do "$dataWorkFolder/global_setup.do" 


*iefolder*2*End_StandardGlobals*************************************************
*iefolder will not work properly if the line above is edited


*iefolder*3*RunDofiles**********************************************************
*iefolder will not work properly if the line above is edited

   * ******************************************************************** *
   *
   *       PART 3: - RUN DOFILES CALLED BY THIS MASTER DOFILE
   *
   *           - A task master dofile has been created for each high-
   *            level task (cleaning, construct, analysis). By 
   *            running all of them all data work associated with the 
   *            PSID should be replicated, including output of 
   *            tables, graphs, etc.
   *           - Feel free to add to this list if you have other high-
   *            level tasks relevant to your project.
   *
   * ******************************************************************** *

   **Set the locals corresponding to the tasks you want
   * run to 1. To not run a task, set the local to 0.
   local importDo       0
   local cleaningDo     0
   local constructDo    0
   local analysisDo     0

   if (`importDo' == 1) { // Change the local above to run or not to run this file
       do "$SNAP_do/SNAP_import_MasterDofile.do" 
   }

   if (`cleaningDo' == 1) { // Change the local above to run or not to run this file
       do "$SNAP_do/SNAP_cleaning_MasterDofile.do" 
   }

   if (`constructDo' == 1) { // Change the local above to run or not to run this file
       do "$SNAP_do/SNAP_construct_MasterDofile.do" 
   }

   if (`analysisDo' == 1) { // Change the local above to run or not to run this file
       do "$SNAP_do/SNAP_analysis_MasterDofile.do" 
   }

*iefolder*3*End_RunDofiles******************************************************
*iefolder will not work properly if the line above is edited

