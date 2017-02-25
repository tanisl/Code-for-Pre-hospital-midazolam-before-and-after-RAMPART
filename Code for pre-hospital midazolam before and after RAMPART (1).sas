LIBNAME NEMSIS "D:\tanisl\Desktop\NEMSISdata"; /*laptop desktop*/

*applying formats;
DATA nemsis.complete;
	SET nemsis.complete;
	OPTIONS fmtsearch = (nemsis);
	format E03_01new E03_01new. CC CC. E09_15new E09_15new. primary primary. E09_16new E09_16new. secondary secondary. condition1new condition1new. E11_01new E11_01new. E09_04new E09_04new. E06_15new E06_15new. agecat agecat. E06_11new E06_11new. E06_12new E06_12new. race race. E06_13new E06_13new. E02_04num E02_04num. E02_05num E02_05num. E07_34new E07_34new. type_service type_service. service_level service_level. primary_role primary_role. rescue rescue. airway airway. IV IV. Benzocat benzocat. midazolam midazolam.;
RUN;


****************************************
Before running code from start to finish, rename original datasets so that the 2-digit year is after the dataset name.
Eg. events from 2010--> events10, geocodes from 2013 -->geocodes13
************************************************************************************************************************;

*************************************************************
*************************************************************
Merging 2010 datasets
*************************************************************
*************************************************************;

*Sorting datasets to be use;
PROC SORT DATA=nemsis.events10; BY eventID; RUN;
PROC SORT DATA=nemsis.conditioncode10; BY eventID; RUN;
PROC SORT DATA=nemsis.medsgiven10; BY eventID; RUN;
PROC SORT DATA=nemsis.procedures10; BY eventID; RUN;
PROC SORT DATA=nemsis.geocodes10; BY eventID; RUN;

*******************************************************************
Demonstrating that events dataset does not require transposition
******************************************************************;
DATA events10_ct;
	SET nemsis.events10;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=events10_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in events10 dataset (=Total number of events)";
RUN;

*reformating E05_XX variables to 20 characters to match other datasets, so data are not truncated on merger;
proc contents data=nemsis.events10; run;
DATA nemsis.events10;
	SET nemsis.events10;
	FORMAT E05_02 $20. E05_04 $20. E05_05 $20. E05_06 $20. E05_07 $20. E05_09 $20. E05_10 $20. E05_11 $20. E05_13 $20.;
RUN;
proc contents data=nemsis.events10; run;

*******************************************************************
Demonstrating that geocodes dataset does not require transposition
******************************************************************;

DATA geocodes10_ct;
	SET nemsis.geocodes10;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=geocodes10_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in geocodes10 dataset (=Total number of events)";
RUN;

**************************************************************************************
Limiting conditioncode database to those with seziure/convulsion and transposing in preparation for merger
****************************************************************************************;

PROC FREQ DATA=nemsis.conditioncode10;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure (=8017) in nemsis.conditioncode10";
RUN;
*limiting conditioncode dataset to seizure/convulsion;
DATA limited_condition10;
	SET nemsis.conditioncode10;
	KEEP eventID E07_35;
	IF E07_35 = 8017;
RUN;
PROC FREQ DATA=limited_condition10;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure in limited_condition10";
RUN;
*checking number of observations per eventID;
DATA limited_condition10;
	SET limited_condition10;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_condition10;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition10 dataset";
RUN;

*removing duplicates in limited_condition;
		*****don't know why there are multiple 8017s per event ID. tried PROC SORT with NODUPRECS and got same results*****
		******IS IT OK TO REMOVE THE EXTRAS?????? its just an inclusion criteria, and would do "condition1 = 8017 OR condition2=8017..." anyways;
DATA limited_condition10_2;
	SET limited_condition10;
	IF count = 1;
RUN;
*checking number of observations per eventID;
PROC FREQ DATA=limited_condition10_2;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition10_2 dataset";
RUN;

*transposing limited_condition11_2 dataset and dropping original condition code variable
		******v. limited_condition11??? (after removing extra observations that had >1 8017 code/eventID);
PROC TRANSPOSE DATA=limited_condition10_2 OUT=nemsis.limited_flipped_conditioncode10 (DROP=_name_) prefix=condition;
	BY eventID;
	VAR E07_35;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_condition10_ct;
	SET nemsis.limited_flipped_conditioncode10;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_condition10_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_conditioncode10 dataset";
RUN;

**************************************************************************************
Limiting medsgiven database to benzodiazepines and transposing in preparation for merger
****************************************************************************************;

*ensuring that meds descriptions have Propper Casing, and renaming carbonic anhydrase inhibitors so that they do not include "zolam" in the name;
DATA propcase_meds10;
	SET nemsis.medsgiven10;
	E18_03 = PROPCASE (E18_03);
	IF E18_03 = "Acetazolamide" OR E18_03 = "Dorzolamide Hydrochloride" THEN E18_03 = "CA-I";
RUN;
*limiting meds dataset to benzos;
DATA limited_propcase_meds10;
	SET propcase_meds10;
	KEEP eventID E18_03;
	WHERE E18_03 CONTAINS ("zolam") OR E18_03 CONTAINS ("zepam") OR E18_03 CONTAINS ("zepate") OR E18_03 CONTAINS ("diazep") OR E18_03 CONTAINS ("Diazep");
RUN;
PROC FREQ DATA=limited_propcase_meds10;
	TABLE E18_03 /list missing;
	TITLE "Frequency of benzodiazepines in limited_propcase_meds10";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_meds10;
	SET limited_propcase_meds10;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_meds10;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_meds10 dataset";
RUN;

*transposing medsgiven dataset and dropping original medication variable;
PROC TRANSPOSE DATA=limited_propcase_meds10 OUT=nemsis.limited_flipped_medsgiven10 (DROP=_name_) prefix=med;
	BY eventID;
	VAR E18_03;
RUN;

*checking that number of observations per eventID is 1 (for proper 1:1 merger);
DATA limited_flipped_medsgiven10_ct;
	SET nemsis.limited_flipped_medsgiven10;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_medsgiven10_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_medsgiven10 dataset";
RUN;

***************************************************************************************************
Limiting procedures database to Airway and IV procedures and transposing in preparation for merger
***************************************************************************************************;

*ensuring that procedures descriptions have Propper Casing;
DATA propcase_procedures10;
	SET nemsis.procedures10;
	E19_03Desc = PROPCASE (E19_03Desc);
RUN;

*limiting meds dataset to Airway and IV procedures
		*****can change specific Airway procedures per Meurer (e.g. oral, nasal)******;
DATA limited_propcase_procedures10;
	SET propcase_procedures10;
	KEEP eventID E19_03Desc;
	WHERE E19_03Desc CONTAINS ("Airway-Combitube") OR E19_03Desc CONTAINS ("Airway-Direct Laryngoscopy") OR E19_03Desc CONTAINS ("Airway-Eoa/Egta") OR E19_03Desc CONTAINS ("Airway-King Lt") OR E19_03Desc CONTAINS ("Airway-Laryngeal Mask") OR E19_03Desc CONTAINS ("Airway-Nasotracheal") OR E19_03Desc CONTAINS ("Airway-Orotracheal") OR E19_03Desc CONTAINS ("Airway-Rapid Sequence") OR E19_03Desc CONTAINS ("Airway-Surgical")
		OR E19_03Desc CONTAINS ("Venous Access-Extremity") OR E19_03Desc CONTAINS ("Venous Access-Intraosseous");
RUN;
PROC FREQ DATA=limited_propcase_procedures10;
	TABLE E19_03Desc /list missing;
	TITLE "Frequency of Airway and IV in limited_propcase_procedures10";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_procedures10;
	SET limited_propcase_procedures10;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_procedures10;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_procedures10 dataset";
RUN;

*transposing proecedures dataset and dropping original procedures variable;
PROC TRANSPOSE DATA=limited_propcase_procedures10 OUT=nemsis.limited_flipped_procedures10 (DROP=_name_) prefix=proc;
	BY eventID;
	VAR E19_03Desc;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_procedures10_ct;
	SET nemsis.limited_flipped_procedures10;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_procedures10_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_procedures10 dataset";
RUN;

***************************************************************************
Merging datasets, limited to those with documentation of a seizure
***************************************************************************;

*merging files, limited to those with documentation of a seizure;
DATA nemsis.seizures_broad10;
	MERGE nemsis.events10 nemsis.geocodes10 nemsis.limited_flipped_medsgiven10 nemsis.limited_flipped_procedures10 nemsis.limited_flipped_conditioncode10;
	BY eventID;
	IF E03_01 = 455 OR E09_15 = 1710 OR E09_16 = 1845 OR condition1 = 8017;
RUN;

***************************************************************************
Limiting broad_seizure dataset to those who were treated with a benzodiazepine
***************************************************************************;

*limiting seizure dataset to those treated with benzodiazepines;
DATA nemsis.seizures_benzos_broad10;
	SET nemsis.seizures_broad10;
	WHERE 
		med1 CONTAINS ("zolam") OR med1 CONTAINS ("zepam") OR med1 CONTAINS ("Benzo") OR med1 CONTAINS ("diazep") OR
		med2 CONTAINS ("zolam") OR med2 CONTAINS ("zepam") OR med2 CONTAINS ("Benzo") OR med2 CONTAINS ("diazep") OR
		med3 CONTAINS ("zolam") OR med3 CONTAINS ("zepam") OR med3 CONTAINS ("Benzo") OR med3 CONTAINS ("diazep") OR
		med4 CONTAINS ("zolam") OR med4 CONTAINS ("zepam") OR med4 CONTAINS ("Benzo") OR med4 CONTAINS ("diazep") OR
		med5 CONTAINS ("zolam") OR med5 CONTAINS ("zepam") OR med5 CONTAINS ("Benzo") OR med5 CONTAINS ("diazep") OR
		med6 CONTAINS ("zolam") OR med6 CONTAINS ("zepam") OR med6 CONTAINS ("Benzo") OR med6 CONTAINS ("diazep") OR
		med7 CONTAINS ("zolam") OR med7 CONTAINS ("zepam") OR med7 CONTAINS ("Benzo") OR med7 CONTAINS ("diazep") OR
		med8 CONTAINS ("zolam") OR med8 CONTAINS ("zepam") OR med8 CONTAINS ("Benzo") OR med8 CONTAINS ("diazep") OR
		med9 CONTAINS ("zolam") OR med9 CONTAINS ("zepam") OR med9 CONTAINS ("Benzo") OR med9 CONTAINS ("diazep") OR
		med10 CONTAINS ("zolam") OR med10 CONTAINS ("zepam") OR med10 CONTAINS ("Benzo") OR med10 CONTAINS ("diazep") OR
		med11 CONTAINS ("zolam") OR med11 CONTAINS ("zepam") OR med11 CONTAINS ("Benzo") OR med11 CONTAINS ("diazep") OR
		med12 CONTAINS ("zolam") OR med12 CONTAINS ("zepam") OR med12 CONTAINS ("Benzo") OR med12 CONTAINS ("diazep") OR
		med13 CONTAINS ("zolam") OR med13 CONTAINS ("zepam") OR med13 CONTAINS ("Benzo") OR med13 CONTAINS ("diazep") OR
		med14 CONTAINS ("zolam") OR med14 CONTAINS ("zepam") OR med14 CONTAINS ("Benzo") OR med14 CONTAINS ("diazep") OR
		med15 CONTAINS ("zolam") OR med15 CONTAINS ("zepam") OR med15 CONTAINS ("Benzo") OR med15 CONTAINS ("diazep") OR
		med16 CONTAINS ("zolam") OR med16 CONTAINS ("zepam") OR med16 CONTAINS ("Benzo") OR med16 CONTAINS ("diazep") OR
		med17 CONTAINS ("zolam") OR med17 CONTAINS ("zepam") OR med17 CONTAINS ("Benzo") OR med17 CONTAINS ("diazep") OR
		med18 CONTAINS ("zolam") OR med18 CONTAINS ("zepam") OR med18 CONTAINS ("Benzo") OR med18 CONTAINS ("diazep") OR
		med19 CONTAINS ("zolam") OR med19 CONTAINS ("zepam") OR med19 CONTAINS ("Benzo") OR med19 CONTAINS ("diazep");
RUN;


*************************************************************
*************************************************************
Merging 2011 datasets
*************************************************************
*************************************************************;

*Sorting datasets to be use;
PROC SORT DATA=nemsis.events11; BY eventID; RUN;
PROC SORT DATA=nemsis.conditioncode11; BY eventID; RUN;
PROC SORT DATA=nemsis.medsgiven11; BY eventID; RUN;
PROC SORT DATA=nemsis.procedures11; BY eventID; RUN;
PROC SORT DATA=nemsis.geocodes11; BY eventID; RUN;

*******************************************************************
Demonstrating that events dataset does not require transposition
******************************************************************;
DATA events11_ct;
	SET nemsis.events11;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=events11_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in events11 dataset (=Total number of events)";
RUN;

*******************************************************************
Demonstrating that geocodes dataset does not require transposition
******************************************************************;

DATA geocodes11_ct;
	SET nemsis.geocodes11;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=geocodes11_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in geocodes11 dataset (=Total number of events)";
RUN;

**************************************************************************************
Limiting conditioncode database to those with seziure/convulsion and transposing in preparation for merger
****************************************************************************************;

PROC FREQ DATA=nemsis.conditioncode11;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure (=8017) in nemsis.conditioncode11";
RUN;
*limiting conditioncode dataset to seizure/convulsion;
DATA limited_condition11;
	SET nemsis.conditioncode11;
	KEEP eventID E07_35;
	IF E07_35 = 8017;
RUN;
PROC FREQ DATA=limited_condition11;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure in limited_condition11";
RUN;
*checking number of observations per eventID;
DATA limited_condition11;
	SET limited_condition11;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_condition11;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition11 dataset";
RUN;

*removing duplicates in limited_condition;
		*****don't know why there are multiple 8017s per event ID. tried PROC SORT with NODUPRECS and got same results*****
		******IS IT OK TO REMOVE THE EXTRAS?????? its just an inclusion criteria, and would do "condition1 = 8017 OR condition2=8017..." anyways;
DATA limited_condition11_2;
	SET limited_condition11;
	IF count = 1;
RUN;
*checking number of observations per eventID;
PROC FREQ DATA=limited_condition11_2;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition11_2 dataset";
RUN;

*transposing limited_condition11_2 dataset and dropping original condition code variable
		******v. limited_condition11??? (after removing extra observations that had >1 8017 code/eventID);
PROC TRANSPOSE DATA=limited_condition11_2 OUT=nemsis.limited_flipped_conditioncode11 (DROP=_name_) prefix=condition;
	BY eventID;
	VAR E07_35;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_condition11_ct;
	SET nemsis.limited_flipped_conditioncode11;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_condition11_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_conditioncode11 dataset";
RUN;

**************************************************************************************
Limiting medsgiven database to benzodiazepines and transposing in preparation for merger
****************************************************************************************;

*ensuring that meds descriptions have Propper Casing, and renaming carbonic anhydrase inhibitors so that they do not include "zolam" in the name;
DATA propcase_meds11;
	SET nemsis.medsgiven11;
	E18_03recoded = PROPCASE (E18_03recoded);
	IF E18_03recoded = "Acetazolamide" OR E18_03recoded = "Dorzolamide Hydrochloride" THEN E18_03recoded = "CA-I";
RUN;
*limiting meds dataset to benzos;
DATA limited_propcase_meds11;
	SET propcase_meds11;
	KEEP eventID E18_03recoded;
	WHERE E18_03recoded CONTAINS ("zolam") OR E18_03recoded CONTAINS ("zepam") OR E18_03recoded CONTAINS ("zepate") OR E18_03recoded CONTAINS ("diazep") OR E18_03recoded CONTAINS ("Diazep");
RUN;
PROC FREQ DATA=limited_propcase_meds11;
	TABLE E18_03recoded /list missing;
	TITLE "Frequency of benzodiazepines in limited_propcase_meds11";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_meds11;
	SET limited_propcase_meds11;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_meds11;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_meds11 dataset";
RUN;

*transposing medsgiven dataset and dropping original medication variable;
PROC TRANSPOSE DATA=limited_propcase_meds11 OUT=nemsis.limited_flipped_medsgiven11 (DROP=_name_) prefix=med;
	BY eventID;
	VAR E18_03recoded;
RUN;

*checking that number of observations per eventID is 1 (for proper 1:1 merger);
DATA limited_flipped_medsgiven11_ct;
	SET nemsis.limited_flipped_medsgiven11;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_medsgiven11_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_medsgiven11 dataset";
RUN;

***************************************************************************************************
Limiting procedures database to Airway and IV procedures and transposing in preparation for merger
***************************************************************************************************;

*ensuring that procedures descriptions have Propper Casing;
DATA propcase_procedures11;
	SET nemsis.procedures11;
	E19_03Description = PROPCASE (E19_03Description);
RUN;

*limiting meds dataset to Airway and IV procedures
		*****can change specific Airway procedures per Meurer (e.g. oral, nasal)******;
DATA limited_propcase_procedures11;
	SET propcase_procedures11;
	KEEP eventID E19_03Description;
	WHERE E19_03Description CONTAINS ("Airway-Combitube") OR E19_03Description CONTAINS ("Airway-Direct Laryngoscopy") OR E19_03Description CONTAINS ("Airway-Eoa/Egta") OR E19_03Description CONTAINS ("Airway-King Lt") OR E19_03Description CONTAINS ("Airway-Laryngeal Mask") OR E19_03Description CONTAINS ("Airway-Nasotracheal") OR E19_03Description CONTAINS ("Airway-Orotracheal") OR E19_03Description CONTAINS ("Airway-Rapid Sequence") OR E19_03Description CONTAINS ("Airway-Surgical")
		OR E19_03Description CONTAINS ("Venous Access-Extremity") OR E19_03Description CONTAINS ("Venous Access-Intraosseous");
RUN;
PROC FREQ DATA=limited_propcase_procedures11;
	TABLE E19_03Description /list missing;
	TITLE "Frequency of Airway and IV in limited_propcase_procedures11";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_procedures11;
	SET limited_propcase_procedures11;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_procedures11;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_procedures11 dataset";
RUN;

*transposing proecedures dataset and dropping original procedures variable;
PROC TRANSPOSE DATA=limited_propcase_procedures11 OUT=nemsis.limited_flipped_procedures11 (DROP=_name_) prefix=proc;
	BY eventID;
	VAR E19_03Description;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_procedures11_ct;
	SET nemsis.limited_flipped_procedures11;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_procedures11_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_procedures11 dataset";
RUN;

***************************************************************************
Merging datasets, limited to those with documentation of a seizure
***************************************************************************;

*merging files, limited to those with documentation of a seizure
(Even with the Work Directory set to the D drive, there was insufficient space to make a complete nemsis file with 25,835,729 observations and 137 variables).
Based on the data in the eventID count tables made above there are 25,835,729 events (same in all individual files except procedures, with 25,835,595 observation--based on CODE_clear.
	Did not include primary or associated symptom as there is no code for seizure/convulsion;
DATA nemsis.seizures_broad11;
	MERGE nemsis.events11 nemsis.geocodes11 nemsis.limited_flipped_medsgiven11 nemsis.limited_flipped_procedures11 nemsis.limited_flipped_conditioncode11;
	BY eventID;
	IF E03_01 = 455 OR E09_15 = 1710 OR E09_16 = 1845 OR condition1 = 8017;
RUN;

***************************************************************************
Limiting broad_seizure dataset to those who were treated with a benzodiazepine
***************************************************************************;

*limiting seizure dataset to those treated with benzodiazepines;
DATA nemsis.seizures_benzos_broad11;
	SET nemsis.seizures_broad11;
	WHERE 
		med1 CONTAINS ("zolam") OR med1 CONTAINS ("zepam") OR med1 CONTAINS ("Benzo") OR med1 CONTAINS ("diazep") OR
		med2 CONTAINS ("zolam") OR med2 CONTAINS ("zepam") OR med2 CONTAINS ("Benzo") OR med2 CONTAINS ("diazep") OR
		med3 CONTAINS ("zolam") OR med3 CONTAINS ("zepam") OR med3 CONTAINS ("Benzo") OR med3 CONTAINS ("diazep") OR
		med4 CONTAINS ("zolam") OR med4 CONTAINS ("zepam") OR med4 CONTAINS ("Benzo") OR med4 CONTAINS ("diazep") OR
		med5 CONTAINS ("zolam") OR med5 CONTAINS ("zepam") OR med5 CONTAINS ("Benzo") OR med5 CONTAINS ("diazep") OR
		med6 CONTAINS ("zolam") OR med6 CONTAINS ("zepam") OR med6 CONTAINS ("Benzo") OR med6 CONTAINS ("diazep") OR
		med7 CONTAINS ("zolam") OR med7 CONTAINS ("zepam") OR med7 CONTAINS ("Benzo") OR med7 CONTAINS ("diazep") OR
		med8 CONTAINS ("zolam") OR med8 CONTAINS ("zepam") OR med8 CONTAINS ("Benzo") OR med8 CONTAINS ("diazep") OR
		med9 CONTAINS ("zolam") OR med9 CONTAINS ("zepam") OR med9 CONTAINS ("Benzo") OR med9 CONTAINS ("diazep") OR
		med10 CONTAINS ("zolam") OR med10 CONTAINS ("zepam") OR med10 CONTAINS ("Benzo") OR med10 CONTAINS ("diazep") OR
		med11 CONTAINS ("zolam") OR med11 CONTAINS ("zepam") OR med11 CONTAINS ("Benzo") OR med11 CONTAINS ("diazep") OR
		med12 CONTAINS ("zolam") OR med12 CONTAINS ("zepam") OR med12 CONTAINS ("Benzo") OR med12 CONTAINS ("diazep") OR
		med13 CONTAINS ("zolam") OR med13 CONTAINS ("zepam") OR med13 CONTAINS ("Benzo") OR med13 CONTAINS ("diazep") OR
		med14 CONTAINS ("zolam") OR med14 CONTAINS ("zepam") OR med14 CONTAINS ("Benzo") OR med14 CONTAINS ("diazep") OR
		med15 CONTAINS ("zolam") OR med15 CONTAINS ("zepam") OR med15 CONTAINS ("Benzo") OR med15 CONTAINS ("diazep") OR
		med16 CONTAINS ("zolam") OR med16 CONTAINS ("zepam") OR med16 CONTAINS ("Benzo") OR med16 CONTAINS ("diazep") OR
		med17 CONTAINS ("zolam") OR med17 CONTAINS ("zepam") OR med17 CONTAINS ("Benzo") OR med17 CONTAINS ("diazep") OR
		med18 CONTAINS ("zolam") OR med18 CONTAINS ("zepam") OR med18 CONTAINS ("Benzo") OR med18 CONTAINS ("diazep");
RUN;


*************************************************************
*************************************************************
Merging 2012 datasets
*************************************************************
*************************************************************;

*Sorting datasets to be use;
PROC SORT DATA=nemsis.events12; BY eventID; RUN;
PROC SORT DATA=nemsis.conditioncode12; BY eventID; RUN;
PROC SORT DATA=nemsis.medsgiven12; BY eventID; RUN;
PROC SORT DATA=nemsis.procedures12; BY eventID; RUN;
PROC SORT DATA=nemsis.geocodes12; BY eventID; RUN;

*******************************************************************
Demonstrating that events dataset does not require transposition
******************************************************************;
DATA events12_ct;
	SET nemsis.events12;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=events12_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in events12 dataset (=Total number of events)";
RUN;

*******************************************************************
Demonstrating that geocodes dataset does not require transposition
******************************************************************;

DATA geocodes12_ct;
	SET nemsis.geocodes12;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=geocodes12_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in geocodes12 dataset (=Total number of events)";
RUN;

**************************************************************************************
Limiting conditioncode database to those with seziure/convulsion and transposing in preparation for merger
****************************************************************************************;

PROC FREQ DATA=nemsis.conditioncode12;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure (=8017) in nemsis.conditioncode12";
RUN;
*limiting conditioncode dataset to seizure/convulsion;
DATA limited_condition12;
	SET nemsis.conditioncode12;
	KEEP eventID E07_35;
	IF E07_35 = 8017;
RUN;
PROC FREQ DATA=limited_condition12;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure in limited_condition12";
RUN;
*checking number of observations per eventID;
DATA limited_condition12;
	SET limited_condition12;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_condition12;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition12 dataset";
RUN;

*removing duplicates in limited_condition;
		*****don't know why there are multiple 8017s per event ID. tried PROC SORT with NODUPRECS and got same results*****
		******IS IT OK TO REMOVE THE EXTRAS?????? its just an inclusion criteria, and would do "condition1 = 8017 OR condition2=8017..." anyways;
DATA limited_condition12_2;
	SET limited_condition12;
	IF count = 1;
RUN;
*checking number of observations per eventID;
PROC FREQ DATA=limited_condition12_2;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition12_2 dataset";
RUN;

*transposing limited_condition11_2 dataset and dropping original condition code variable
		******v. limited_condition11??? (after removing extra observations that had >1 8017 code/eventID);
PROC TRANSPOSE DATA=limited_condition12_2 OUT=nemsis.limited_flipped_conditioncode12 (DROP=_name_) prefix=condition;
	BY eventID;
	VAR E07_35;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_condition12_ct;
	SET nemsis.limited_flipped_conditioncode12;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_condition12_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_conditioncode12 dataset";
RUN;

**************************************************************************************
Limiting medsgiven database to benzodiazepines and transposing in preparation for merger
****************************************************************************************;

*ensuring that meds descriptions have Propper Casing, and renaming carbonic anhydrase inhibitors so that they do not include "zolam" in the name;
DATA propcase_meds12;
	SET nemsis.medsgiven12;
	E18_03recoded = PROPCASE (E18_03recoded);
	IF E18_03recoded = "Acetazolamide" OR E18_03recoded = "Dorzolamide Hydrochloride" THEN E18_03recoded = "CA-I";
RUN;
*limiting meds dataset to benzos;
DATA limited_propcase_meds12;
	SET propcase_meds12;
	KEEP eventID E18_03recoded;
	WHERE E18_03recoded CONTAINS ("zolam") OR E18_03recoded CONTAINS ("zepam") OR E18_03recoded CONTAINS ("zepate") OR E18_03recoded CONTAINS ("diazep") OR E18_03recoded CONTAINS ("Diazep");
RUN;
PROC FREQ DATA=limited_propcase_meds12;
	TABLE E18_03recoded /list missing;
	TITLE "Frequency of benzodiazepines in limited_propcase_meds12";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_meds12;
	SET limited_propcase_meds12;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_meds12;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_meds12 dataset";
RUN;

*transposing medsgiven dataset and dropping original medication variable;
PROC TRANSPOSE DATA=limited_propcase_meds12 OUT=nemsis.limited_flipped_medsgiven12 (DROP=_name_) prefix=med;
	BY eventID;
	VAR E18_03recoded;
RUN;

*checking that number of observations per eventID is 1 (for proper 1:1 merger);
DATA limited_flipped_medsgiven12_ct;
	SET nemsis.limited_flipped_medsgiven12;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_medsgiven12_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_medsgiven12 dataset";
RUN;

***************************************************************************************************
Limiting procedures database to Airway and IV procedures and transposing in preparation for merger
***************************************************************************************************;

*ensuring that procedures descriptions have Propper Casing;
DATA propcase_procedures12;
	SET nemsis.procedures12;
	E19_03Description = PROPCASE (E19_03Description);
RUN;

*limiting meds dataset to Airway and IV procedures
		*****can change specific Airway procedures per Meurer (e.g. oral, nasal)******;
DATA limited_propcase_procedures12;
	SET propcase_procedures12;
	KEEP eventID E19_03Description;
	WHERE E19_03Description CONTAINS ("Airway-Combitube") OR E19_03Description CONTAINS ("Airway-Direct Laryngoscopy") OR E19_03Description CONTAINS ("Airway-Eoa/Egta") OR E19_03Description CONTAINS ("Airway-King Lt") OR E19_03Description CONTAINS ("Airway-Laryngeal Mask") OR E19_03Description CONTAINS ("Airway-Nasotracheal") OR E19_03Description CONTAINS ("Airway-Orotracheal") OR E19_03Description CONTAINS ("Airway-Rapid Sequence") OR E19_03Description CONTAINS ("Airway-Surgical")
		OR E19_03Description CONTAINS ("Venous Access-Extremity") OR E19_03Description CONTAINS ("Venous Access-Intraosseous");
RUN;
PROC FREQ DATA=limited_propcase_procedures12;
	TABLE E19_03Description /list missing;
	TITLE "Frequency of Airway and IV in limited_propcase_procedures12";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_procedures12;
	SET limited_propcase_procedures12;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_procedures12;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_procedures12 dataset";
RUN;

*transposing proecedures dataset and dropping original procedures variable;
PROC TRANSPOSE DATA=limited_propcase_procedures12 OUT=nemsis.limited_flipped_procedures12 (DROP=_name_) prefix=proc;
	BY eventID;
	VAR E19_03Description;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_procedures12_ct;
	SET nemsis.limited_flipped_procedures12;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_procedures12_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_procedures12 dataset";
RUN;

***************************************************************************
Merging datasets, limited to those with documentation of a seizure
***************************************************************************;

*merging files, limited to those with documentation of a seizure
(Even with the Work Directory set to the D drive, there was insufficient space to make a complete nemsis file with 25,835,729 observations and 137 variables).
Based on the data in the eventID count tables made above there are 25,835,729 events (same in all individual files except procedures, with 25,835,595 observation--based on CODE_clear.
	Did not include primary or associated symptom as there is no code for seizure/convulsion;
DATA nemsis.seizures_broad12;
	MERGE nemsis.events12 nemsis.geocodes12 nemsis.limited_flipped_medsgiven12 nemsis.limited_flipped_procedures12 nemsis.limited_flipped_conditioncode12;
	BY eventID;
	IF E03_01 = 455 OR E09_15 = 1710 OR E09_16 = 1845 OR condition1 = 8017;
RUN;

***************************************************************************
Limiting broad_seizure dataset to those who were treated with a benzodiazepine
***************************************************************************;

*limiting seizure dataset to those treated with benzodiazepines;
DATA nemsis.seizures_benzos_broad12;
	SET nemsis.seizures_broad12;
	WHERE 
		med1 CONTAINS ("zolam") OR med1 CONTAINS ("zepam") OR med1 CONTAINS ("Benzo") OR med1 CONTAINS ("diazep") OR
		med2 CONTAINS ("zolam") OR med2 CONTAINS ("zepam") OR med2 CONTAINS ("Benzo") OR med2 CONTAINS ("diazep") OR
		med3 CONTAINS ("zolam") OR med3 CONTAINS ("zepam") OR med3 CONTAINS ("Benzo") OR med3 CONTAINS ("diazep") OR
		med4 CONTAINS ("zolam") OR med4 CONTAINS ("zepam") OR med4 CONTAINS ("Benzo") OR med4 CONTAINS ("diazep") OR
		med5 CONTAINS ("zolam") OR med5 CONTAINS ("zepam") OR med5 CONTAINS ("Benzo") OR med5 CONTAINS ("diazep") OR
		med6 CONTAINS ("zolam") OR med6 CONTAINS ("zepam") OR med6 CONTAINS ("Benzo") OR med6 CONTAINS ("diazep") OR
		med7 CONTAINS ("zolam") OR med7 CONTAINS ("zepam") OR med7 CONTAINS ("Benzo") OR med7 CONTAINS ("diazep") OR
		med8 CONTAINS ("zolam") OR med8 CONTAINS ("zepam") OR med8 CONTAINS ("Benzo") OR med8 CONTAINS ("diazep") OR
		med9 CONTAINS ("zolam") OR med9 CONTAINS ("zepam") OR med9 CONTAINS ("Benzo") OR med9 CONTAINS ("diazep") OR
		med10 CONTAINS ("zolam") OR med10 CONTAINS ("zepam") OR med10 CONTAINS ("Benzo") OR med10 CONTAINS ("diazep") OR
		med11 CONTAINS ("zolam") OR med11 CONTAINS ("zepam") OR med11 CONTAINS ("Benzo") OR med11 CONTAINS ("diazep") OR
		med12 CONTAINS ("zolam") OR med12 CONTAINS ("zepam") OR med12 CONTAINS ("Benzo") OR med12 CONTAINS ("diazep") OR
		med13 CONTAINS ("zolam") OR med13 CONTAINS ("zepam") OR med13 CONTAINS ("Benzo") OR med13 CONTAINS ("diazep") OR
		med14 CONTAINS ("zolam") OR med14 CONTAINS ("zepam") OR med14 CONTAINS ("Benzo") OR med14 CONTAINS ("diazep") OR
		med15 CONTAINS ("zolam") OR med15 CONTAINS ("zepam") OR med15 CONTAINS ("Benzo") OR med15 CONTAINS ("diazep") OR
		med16 CONTAINS ("zolam") OR med16 CONTAINS ("zepam") OR med16 CONTAINS ("Benzo") OR med16 CONTAINS ("diazep") OR
		med17 CONTAINS ("zolam") OR med17 CONTAINS ("zepam") OR med17 CONTAINS ("Benzo") OR med17 CONTAINS ("diazep") OR
		med18 CONTAINS ("zolam") OR med18 CONTAINS ("zepam") OR med18 CONTAINS ("Benzo") OR med18 CONTAINS ("diazep")OR
		med19 CONTAINS ("zolam") OR med19 CONTAINS ("zepam") OR med19 CONTAINS ("Benzo") OR med19 CONTAINS ("diazep") OR
		med20 CONTAINS ("zolam") OR med20 CONTAINS ("zepam") OR med20 CONTAINS ("Benzo") OR med20 CONTAINS ("diazep");
RUN;

*************************************************************
*************************************************************
Merging 2013 datasets
*************************************************************
*************************************************************;

*Sorting datasets to be use;
PROC SORT DATA=nemsis.events13; BY eventID; RUN;
PROC SORT DATA=nemsis.conditioncode13; BY eventID; RUN;
PROC SORT DATA=nemsis.medsgiven13; BY eventID; RUN;
PROC SORT DATA=nemsis.procedures13; BY eventID; RUN;
PROC SORT DATA=nemsis.geocodes13; BY eventID; RUN;

*******************************************************************
Demonstrating that events dataset does not require transposition
******************************************************************;
DATA events13_ct;
	SET nemsis.events13;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=events13_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in events13 dataset (=Total number of events)";
RUN;

*******************************************************************
Demonstrating that geocodes dataset does not require transposition
******************************************************************;

DATA geocodes13_ct;
	SET nemsis.geocodes13;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=geocodes13_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in geocodes13 dataset (=Total number of events)";
RUN;

**************************************************************************************
Limiting conditioncode database to those with seziure/convulsion and transposing in preparation for merger
****************************************************************************************;

PROC FREQ DATA=nemsis.conditioncode13;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure (=8017) in nemsis.conditioncode13";
RUN;
*limiting conditioncode dataset to seizure/convulsion;
DATA limited_condition13;
	SET nemsis.conditioncode13;
	KEEP eventID E07_35;
	IF E07_35 = 8017;
RUN;
PROC FREQ DATA=limited_condition13;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure in limited_condition13";
RUN;
*checking number of observations per eventID;
DATA limited_condition13;
	SET limited_condition13;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_condition13;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition13 dataset";
RUN;

*removing duplicates in limited_condition;
		*****don't know why there are multiple 8017s per event ID. tried PROC SORT with NODUPRECS and got same results*****
		******IS IT OK TO REMOVE THE EXTRAS?????? its just an inclusion criteria, and would do "condition1 = 8017 OR condition2=8017..." anyways;
DATA limited_condition13_2;
	SET limited_condition13;
	IF count = 1;
RUN;
*checking number of observations per eventID;
PROC FREQ DATA=limited_condition13_2;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition13_2 dataset";
RUN;

*transposing limited_condition13_2 dataset and dropping original condition code variable
		******v. limited_condition13??? (after removing extra observations that had >1 8017 code/eventID);
PROC TRANSPOSE DATA=limited_condition13_2 OUT=nemsis.limited_flipped_conditioncode13 (DROP=_name_) prefix=condition;
	BY eventID;
	VAR E07_35;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_condition13_ct;
	SET nemsis.limited_flipped_conditioncode13;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_condition13_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_conditioncode13 dataset";
RUN;

**************************************************************************************
Limiting medsgiven database to benzodiazepines and transposing in preparation for merger
****************************************************************************************;

*ensuring that meds descriptions have Propper Casing, and renaming carbonic anhydrase inhibitors so that they do not include "zolam" in the name;
DATA propcase_meds13;
	SET nemsis.medsgiven13;
	E18_03recoded = PROPCASE (E18_03recoded);
	IF E18_03recoded = "Acetazolamide" OR E18_03recoded = "Dorzolamide Hydrochloride" THEN E18_03recoded = "CA-I";
RUN;
*limiting meds dataset to benzos;
DATA limited_propcase_meds13;
	SET propcase_meds13;
	KEEP eventID E18_03recoded;
	WHERE E18_03recoded CONTAINS ("zolam") OR E18_03recoded CONTAINS ("zepam") OR E18_03recoded CONTAINS ("zepate") OR E18_03recoded CONTAINS ("diazep") OR E18_03recoded CONTAINS ("Diazep");
RUN;
PROC FREQ DATA=limited_propcase_meds13;
	TABLE E18_03recoded /list missing;
	TITLE "Frequency of benzodiazepines in limited_propcase_meds13";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_meds13;
	SET limited_propcase_meds13;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_meds13;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_meds13 dataset";
RUN;

*transposing medsgiven dataset and dropping original medication variable;
PROC TRANSPOSE DATA=limited_propcase_meds13 OUT=nemsis.limited_flipped_medsgiven13 (DROP=_name_) prefix=med;
	BY eventID;
	VAR E18_03recoded;
RUN;

*checking that number of observations per eventID is 1 (for proper 1:1 merger);
DATA limited_flipped_medsgiven13_ct;
	SET nemsis.limited_flipped_medsgiven13;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_medsgiven13_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_medsgiven13 dataset";
RUN;

***************************************************************************************************
Limiting procedures database to Airway and IV procedures and transposing in preparation for merger
***************************************************************************************************;

*ensuring that procedures descriptions have Propper Casing;
DATA propcase_procedures13;
	SET nemsis.procedures13;
	E19_03Description = PROPCASE (E19_03Description);
RUN;

*limiting meds dataset to Airway and IV procedures
		*****can change specific Airway procedures per Meurer (e.g. oral, nasal)******;
DATA limited_propcase_procedures13;
	SET propcase_procedures13;
	KEEP eventID E19_03Description;
	WHERE E19_03Description CONTAINS ("Airway-Combitube") OR E19_03Description CONTAINS ("Airway-Direct Laryngoscopy") OR E19_03Description CONTAINS ("Airway-Eoa/Egta") OR E19_03Description CONTAINS ("Airway-King Lt") OR E19_03Description CONTAINS ("Airway-Laryngeal Mask") OR E19_03Description CONTAINS ("Airway-Nasotracheal") OR E19_03Description CONTAINS ("Airway-Orotracheal") OR E19_03Description CONTAINS ("Airway-Rapid Sequence") OR E19_03Description CONTAINS ("Airway-Surgical")
		OR E19_03Description CONTAINS ("Venous Access-Extremity") OR E19_03Description CONTAINS ("Venous Access-Intraosseous");
RUN;
PROC FREQ DATA=limited_propcase_procedures13;
	TABLE E19_03Description /list missing;
	TITLE "Frequency of Airway and IV in limited_propcase_procedures13";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_procedures13;
	SET limited_propcase_procedures13;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_procedures13;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_procedures13 dataset";
RUN;

*transposing proecedures dataset and dropping original procedures variable;
PROC TRANSPOSE DATA=limited_propcase_procedures13 OUT=nemsis.limited_flipped_procedures13 (DROP=_name_) prefix=proc;
	BY eventID;
	VAR E19_03Description;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_procedures13_ct;
	SET nemsis.limited_flipped_procedures13;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_procedures13_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_procedures13 dataset";
RUN;

***************************************************************************
Merging datasets, limited to those with documentation of a seizure
***************************************************************************;

*merging files, limited to those with documentation of a seizure
(Even with the Work Directory set to the D drive, there was insufficient space to make a complete nemsis file with 25,835,729 observations and 137 variables).
Based on the data in the eventID count tables made above there are 25,835,729 events (same in all individual files except procedures, with 25,835,595 observation--based on CODE_clear.
	Did not include primary or associated symptom as there is no code for seizure/convulsion;
DATA nemsis.seizures_broad13;
	MERGE nemsis.events13 nemsis.geocodes13 nemsis.limited_flipped_medsgiven13 nemsis.limited_flipped_procedures13 nemsis.limited_flipped_conditioncode13;
	BY eventID;
	IF E03_01 = 455 OR E09_15 = 1710 OR E09_16 = 1845 OR condition1 = 8017;
RUN;

***************************************************************************
Limiting broad_seizure dataset to those who were treated with a benzodiazepine
***************************************************************************;

*limiting seizure dataset to those treated with benzodiazepines;
DATA nemsis.seizures_benzos_broad13;
	SET nemsis.seizures_broad13;
	WHERE 
		med1 CONTAINS ("zolam") OR med1 CONTAINS ("zepam") OR med1 CONTAINS ("Benzo") OR med1 CONTAINS ("diazep") OR
		med2 CONTAINS ("zolam") OR med2 CONTAINS ("zepam") OR med2 CONTAINS ("Benzo") OR med2 CONTAINS ("diazep") OR
		med3 CONTAINS ("zolam") OR med3 CONTAINS ("zepam") OR med3 CONTAINS ("Benzo") OR med3 CONTAINS ("diazep") OR
		med4 CONTAINS ("zolam") OR med4 CONTAINS ("zepam") OR med4 CONTAINS ("Benzo") OR med4 CONTAINS ("diazep") OR
		med5 CONTAINS ("zolam") OR med5 CONTAINS ("zepam") OR med5 CONTAINS ("Benzo") OR med5 CONTAINS ("diazep") OR
		med6 CONTAINS ("zolam") OR med6 CONTAINS ("zepam") OR med6 CONTAINS ("Benzo") OR med6 CONTAINS ("diazep") OR
		med7 CONTAINS ("zolam") OR med7 CONTAINS ("zepam") OR med7 CONTAINS ("Benzo") OR med7 CONTAINS ("diazep") OR
		med8 CONTAINS ("zolam") OR med8 CONTAINS ("zepam") OR med8 CONTAINS ("Benzo") OR med8 CONTAINS ("diazep") OR
		med9 CONTAINS ("zolam") OR med9 CONTAINS ("zepam") OR med9 CONTAINS ("Benzo") OR med9 CONTAINS ("diazep") OR
		med10 CONTAINS ("zolam") OR med10 CONTAINS ("zepam") OR med10 CONTAINS ("Benzo") OR med10 CONTAINS ("diazep") OR
		med11 CONTAINS ("zolam") OR med11 CONTAINS ("zepam") OR med11 CONTAINS ("Benzo") OR med11 CONTAINS ("diazep") OR
		med12 CONTAINS ("zolam") OR med12 CONTAINS ("zepam") OR med12 CONTAINS ("Benzo") OR med12 CONTAINS ("diazep") OR
		med13 CONTAINS ("zolam") OR med13 CONTAINS ("zepam") OR med13 CONTAINS ("Benzo") OR med13 CONTAINS ("diazep") OR
		med14 CONTAINS ("zolam") OR med14 CONTAINS ("zepam") OR med14 CONTAINS ("Benzo") OR med14 CONTAINS ("diazep") OR
		med15 CONTAINS ("zolam") OR med15 CONTAINS ("zepam") OR med15 CONTAINS ("Benzo") OR med15 CONTAINS ("diazep") OR
		med16 CONTAINS ("zolam") OR med16 CONTAINS ("zepam") OR med16 CONTAINS ("Benzo") OR med16 CONTAINS ("diazep") OR
		med17 CONTAINS ("zolam") OR med17 CONTAINS ("zepam") OR med17 CONTAINS ("Benzo") OR med17 CONTAINS ("diazep") OR
		med18 CONTAINS ("zolam") OR med18 CONTAINS ("zepam") OR med18 CONTAINS ("Benzo") OR med18 CONTAINS ("diazep") OR
		med19 CONTAINS ("zolam") OR med19 CONTAINS ("zepam") OR med19 CONTAINS ("Benzo") OR med19 CONTAINS ("diazep") OR
		med20 CONTAINS ("zolam") OR med20 CONTAINS ("zepam") OR med20 CONTAINS ("Benzo") OR med20 CONTAINS ("diazep") OR
		med21 CONTAINS ("zolam") OR med21 CONTAINS ("zepam") OR med21 CONTAINS ("Benzo") OR med21 CONTAINS ("diazep") OR
		med22 CONTAINS ("zolam") OR med22 CONTAINS ("zepam") OR med22 CONTAINS ("Benzo") OR med22 CONTAINS ("diazep");
RUN;

*************************************************************
*************************************************************
Merging 2014 datasets
*************************************************************
*************************************************************;

*Sorting datasets to be use;
PROC SORT DATA=nemsis.events; BY eventID; RUN;
PROC SORT DATA=nemsis.conditioncode; BY eventID; RUN;
PROC SORT DATA=nemsis.medsgiven; BY eventID; RUN;
PROC SORT DATA=nemsis.procedures; BY eventID; RUN;
PROC SORT DATA=nemsis.geocodes; BY eventID; RUN;

*******************************************************************
Demonstrating that events dataset does not require transposition
******************************************************************;
DATA events_ct;
	SET nemsis.events;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=events_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in events dataset (=Total number of events)";
RUN;

*******************************************************************
Demonstrating that geocodes dataset does not require transposition
******************************************************************;

DATA geocodes_ct;
	SET nemsis.geocodes;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=geocodes_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in geocodes dataset (=Total number of events)";
RUN;

**************************************************************************************
Limiting conditioncode database to those with seziure/convulsion and transposing in preparation for merger
****************************************************************************************;

PROC FREQ DATA=nemsis.conditioncode;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure (=8017) in nemsis.conditioncode";
RUN;
*limiting conditioncode dataset to seizure/convulsion;
DATA limited_condition;
	SET nemsis.conditioncode;
	KEEP eventID E07_35;
	IF E07_35 = 8017;
RUN;
PROC FREQ DATA=limited_condition;
	TABLE E07_35 /list missing;
	TITLE "Frequency of seizure in limited_condition";
RUN;
*checking number of observations per eventID;
DATA limited_condition;
	SET limited_condition;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_condition;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition dataset";
RUN;

*removing duplicates in limited_condition;
		*****don't know why there are multiple 8017s per event ID. tried PROC SORT with NODUPRECS and got same results*****
		******IS IT OK TO REMOVE THE EXTRAS?????? its just an inclusion criteria, and would do "condition1 = 8017 OR condition2=8017..." anyways;
DATA limited_condition2;
	SET limited_condition;
	IF count = 1;
RUN;
*checking number of observations per eventID;
PROC FREQ DATA=limited_condition2;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_condition dataset";
RUN;

*transposing limited_condition2 dataset and dropping original condition code variable
		******v. limited_condition??? (after removing extra observations that had >1 8017 code/eventID);
PROC TRANSPOSE DATA=limited_condition2 OUT=nemsis.limited_flipped_conditioncode (DROP=_name_) prefix=condition;
	BY eventID;
	VAR E07_35;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_conditioncode_ct;
	SET nemsis.limited_flipped_conditioncode;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_conditioncode_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_conditioncode dataset";
RUN;

**************************************************************************************
Limiting medsgiven database to benzodiazepines and transposing in preparation for merger
****************************************************************************************;

*ensuring that meds descriptions have Propper Casing, and renaming carbonic anhydrase inhibitors so that they do not include "zolam" in the name;
DATA propcase_meds;
	SET nemsis.medsgiven;
	E18_03recoded = PROPCASE (E18_03recoded);
	IF E18_03recoded = "Acetazolamide" OR E18_03recoded = "Dorzolamide Hydrochloride" THEN E18_03recoded = "CA-I";
RUN;
*limiting meds dataset to benzos;
DATA limited_propcase_meds;
	SET propcase_meds;
	KEEP eventID E18_03recoded;
	WHERE E18_03recoded CONTAINS ("zolam") OR E18_03recoded CONTAINS ("zepam") OR E18_03recoded CONTAINS ("zepate") OR E18_03recoded CONTAINS ("diazep") OR E18_03recoded CONTAINS ("Diazep");
RUN;
PROC FREQ DATA=limited_propcase_meds;
	TABLE E18_03recoded /list missing;
	TITLE "Frequency of benzodiazepines in limited_propcase_meds";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_meds;
	SET limited_propcase_meds;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_meds;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_meds dataset";
RUN;

*transposing medsgiven dataset and dropping original medication variable;
PROC TRANSPOSE DATA=limited_propcase_meds OUT=nemsis.limited_flipped_medsgiven (DROP=_name_) prefix=med;
	BY eventID;
	VAR E18_03recoded;
RUN;

*checking that number of observations per eventID is 1 (for proper 1:1 merger);
DATA limited_flipped_medsgiven_ct;
	SET nemsis.limited_flipped_medsgiven;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=lilmited_flipped_medsgiven_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_medsgiven dataset";
RUN;

***************************************************************************************************
Limiting procedures database to Airway and IV procedures and transposing in preparation for merger
***************************************************************************************************;

*ensuring that procedures descriptions have Propper Casing;
DATA propcase_procedures;
	SET nemsis.procedures;
	E19_03Description = PROPCASE (E19_03Description);
RUN;

*limiting meds dataset to Airway and IV procedures
		*****can change specific Airway procedures per Meurer (e.g. oral, nasal)******;
DATA limited_propcase_procedures;
	SET propcase_procedures;
	KEEP eventID E19_03Description;
	WHERE E19_03Description CONTAINS ("Airway-Combitube") OR E19_03Description CONTAINS ("Airway-Direct Laryngoscopy") OR E19_03Description CONTAINS ("Airway-Eoa/Egta") OR E19_03Description CONTAINS ("Airway-King Lt") OR E19_03Description CONTAINS ("Airway-Laryngeal Mask") OR E19_03Description CONTAINS ("Airway-Nasotracheal") OR E19_03Description CONTAINS ("Airway-Orotracheal") OR E19_03Description CONTAINS ("Airway-Rapid Sequence") OR E19_03Description CONTAINS ("Airway-Surgical")
		OR E19_03Description CONTAINS ("Venous Access-Extremity") OR E19_03Description CONTAINS ("Venous Access-Intraosseous");
RUN;
PROC FREQ DATA=limited_propcase_procedures;
	TABLE E19_03Description /list missing;
	TITLE "Frequency of Airway and IV in limited_propcase_procedures";
RUN;
*checking number of observations per eventID;
DATA limited_propcase_procedures;
	SET limited_propcase_procedures;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_propcase_procedures;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_propcase_procedures dataset";
RUN;

*transposing proecedures dataset and dropping original procedures variable;
PROC TRANSPOSE DATA=limited_propcase_procedures OUT=nemsis.limited_flipped_procedures (DROP=_name_) prefix=proc;
	BY eventID;
	VAR E19_03Description;
RUN;

*checking that number of observations per eventID is 1;
DATA limited_flipped_procedures_ct;
	SET nemsis.limited_flipped_procedures;
	count + 1;
	BY eventID;
	IF first.eventID THEN count=1;
RUN;
PROC FREQ DATA=limited_flipped_procedures_ct;
	TABLE count / list missing;
	TITLE "Frequencies of eventID counts in limited_flipped_procedures dataset";
RUN;

***************************************************************************
Merging datasets, limited to those with documentation of a seizure
***************************************************************************;

*merging files, limited to those with documentation of a seizure
(Even with the Work Directory set to the D drive, there was insufficient space to make a complete nemsis file with 25,835,729 observations and 137 variables).
Based on the data in the eventID count tables made above there are 25,835,729 events (same in all individual files except procedures, with 25,835,595 observation--based on CODE_clear.
	Did not include primary or associated symptom as there is no code for seizure/convulsion;
DATA nemsis.seizures_broad14;
	MERGE nemsis.events nemsis.geocodes nemsis.limited_flipped_medsgiven nemsis.limited_flipped_procedures nemsis.limited_flipped_conditioncode;
	BY eventID;
	IF E03_01 = 455 OR E09_15 = 1710 OR E09_16 = 1845 OR condition1 = 8017;
RUN;

***************************************************************************
Limiting broad_seizure dataset to those who were treated with a benzodiazepine
***************************************************************************;

*limiting seizure dataset to those treated with benzodiazepines;
DATA nemsis.seizures_benzos_broad14;
	SET nemsis.seizures_broad14;
	WHERE 
		med1 CONTAINS ("zolam") OR med1 CONTAINS ("zepam") OR med1 CONTAINS ("Benzo") OR
		med2 CONTAINS ("zolam") OR med2 CONTAINS ("zepam") OR med2 CONTAINS ("Benzo") OR
		med3 CONTAINS ("zolam") OR med3 CONTAINS ("zepam") OR med3 CONTAINS ("Benzo") OR
		med4 CONTAINS ("zolam") OR med4 CONTAINS ("zepam") OR med4 CONTAINS ("Benzo") OR
		med5 CONTAINS ("zolam") OR med5 CONTAINS ("zepam") OR med5 CONTAINS ("Benzo") OR
		med6 CONTAINS ("zolam") OR med6 CONTAINS ("zepam") OR med6 CONTAINS ("Benzo") OR
		med7 CONTAINS ("zolam") OR med7 CONTAINS ("zepam") OR med7 CONTAINS ("Benzo") OR
		med8 CONTAINS ("zolam") OR med8 CONTAINS ("zepam") OR med8 CONTAINS ("Benzo") OR
		med9 CONTAINS ("zolam") OR med9 CONTAINS ("zepam") OR med9 CONTAINS ("Benzo") OR
		med10 CONTAINS ("zolam") OR med10 CONTAINS ("zepam") OR med10 CONTAINS ("Benzo") OR
		med11 CONTAINS ("zolam") OR med11 CONTAINS ("zepam") OR med11 CONTAINS ("Benzo") OR
		med12 CONTAINS ("zolam") OR med12 CONTAINS ("zepam") OR med12 CONTAINS ("Benzo") OR
		med13 CONTAINS ("zolam") OR med13 CONTAINS ("zepam") OR med13 CONTAINS ("Benzo") OR
		med14 CONTAINS ("zolam") OR med14 CONTAINS ("zepam") OR med14 CONTAINS ("Benzo") OR
		med15 CONTAINS ("zolam") OR med15 CONTAINS ("zepam") OR med15 CONTAINS ("Benzo") OR
		med16 CONTAINS ("zolam") OR med16 CONTAINS ("zepam") OR med16 CONTAINS ("Benzo") OR
		med17 CONTAINS ("zolam") OR med17 CONTAINS ("zepam") OR med17 CONTAINS ("Benzo") OR
		med18 CONTAINS ("zolam") OR med18 CONTAINS ("zepam") OR med18 CONTAINS ("Benzo") OR
		med19 CONTAINS ("zolam") OR med19 CONTAINS ("zepam") OR med19 CONTAINS ("Benzo") OR
		med20 CONTAINS ("zolam") OR med20 CONTAINS ("zepam") OR med20 CONTAINS ("Benzo") OR
		med21 CONTAINS ("zolam") OR med21 CONTAINS ("zepam") OR med21 CONTAINS ("Benzo") OR
		med22 CONTAINS ("zolam") OR med22 CONTAINS ("zepam") OR med22 CONTAINS ("Benzo") OR
		med23 CONTAINS ("zolam") OR med23 CONTAINS ("zepam") OR med23 CONTAINS ("Benzo") OR
		med24 CONTAINS ("zolam") OR med24 CONTAINS ("zepam") OR med24 CONTAINS ("Benzo") OR
		med25 CONTAINS ("zolam") OR med25 CONTAINS ("zepam") OR med25 CONTAINS ("Benzo") OR
		med26 CONTAINS ("zolam") OR med26 CONTAINS ("zepam") OR med26 CONTAINS ("Benzo") OR
		med27 CONTAINS ("zolam") OR med27 CONTAINS ("zepam") OR med27 CONTAINS ("Benzo") OR
		med28 CONTAINS ("zolam") OR med28 CONTAINS ("zepam") OR med28 CONTAINS ("Benzo") OR
		med29 CONTAINS ("zolam") OR med29 CONTAINS ("zepam") OR med29 CONTAINS ("Benzo") OR
		med30 CONTAINS ("zolam") OR med30 CONTAINS ("zepam") OR med30 CONTAINS ("Benzo");
RUN;


********************************************************************
********************************************************************
Combining datasets from 2010, 2011, 2012, 2013, 2014
********************************************************************
*******************************************************************;

DATA nemsis.SBB_all;
	SET nemsis.seizures_benzos_broad10 nemsis.seizures_benzos_broad11 nemsis.seizures_benzos_broad12 nemsis.seizures_benzos_broad13 nemsis.seizures_benzos_broad14;
RUN;


********************************************************************
********************************************************************
Combnining SBB with Agency-Level variables
********************************************************************
********************************************************************;

*adding years to agency databases;
DATA Agency10;
	SET nemsis.randomkey2010;
	Agency_Year = 2010;
RUN;
DATA Agency11;
	SET nemsis.randomkey2011;
	Agency_Year = 2011;
RUN;
DATA Agency12;
	SET nemsis.randomkey2012;
	Agency_Year = 2012;
RUN;
DATA Agency13;
	SET nemsis.randomkey2013;
	Agency_Year = 2013;
RUN;
DATA Agency14;
	SET nemsis.randomkey2014;
	Agency_Year = 2014;
RUN;

*combining agency datasets across years;
DATA nemsis.Agency_all;
	SET agency10 agency11 agency12 agency13 agency14;
RUN;

*Merging SBB dataset with Agency dataset;
PROC SORT DATA=nemsis.Agency_all; BY eventID; RUN;
PROC SORT DATA=nemsis.SBB_all; BY eventID; RUN;
DATA nemsis.SBBA_all;
	MERGE nemsis.SBB_all (in=A) nemsis.Agency_all;
	BY eventID;
	IF A;
RUN;
	

********************************************************************
********************************************************************
Working with multi-year dataset
********************************************************************
********************************************************************;


*************************************************************
Prepping for analysis and condensing dataset to relevant variables
*************************************************************;

*Replacing proc1-proc40 with variables Airway and IV. 
	Airway = advanced airway needed
	IV = IV or IO placed 
******check frequency of IV placement (also BY benzo type). Does it make sense to assume it was for med administration? NO. See prep for analysis (70% of midaz had IV palced);

DATA SBBA_all;
	SET nemsis.SBBA_all;
	IF 
		proc1	=	"Venous Access-Extremity"	OR	proc1	=	"Venous Access-Intraosseous Adult"	OR	proc1	=	"Venous Access-Intraosseous Pediatric"	OR
		proc2	=	"Venous Access-Extremity"	OR	proc2	=	"Venous Access-Intraosseous Adult"	OR	proc2	=	"Venous Access-Intraosseous Pediatric"	OR
		proc3	=	"Venous Access-Extremity"	OR	proc3	=	"Venous Access-Intraosseous Adult"	OR	proc3	=	"Venous Access-Intraosseous Pediatric"	OR
		proc4	=	"Venous Access-Extremity"	OR	proc4	=	"Venous Access-Intraosseous Adult"	OR	proc4	=	"Venous Access-Intraosseous Pediatric"	OR
		proc5	=	"Venous Access-Extremity"	OR	proc5	=	"Venous Access-Intraosseous Adult"	OR	proc5	=	"Venous Access-Intraosseous Pediatric"	OR
		proc6	=	"Venous Access-Extremity"	OR	proc6	=	"Venous Access-Intraosseous Adult"	OR	proc6	=	"Venous Access-Intraosseous Pediatric"	OR
		proc7	=	"Venous Access-Extremity"	OR	proc7	=	"Venous Access-Intraosseous Adult"	OR	proc7	=	"Venous Access-Intraosseous Pediatric"	OR
		proc8	=	"Venous Access-Extremity"	OR	proc8	=	"Venous Access-Intraosseous Adult"	OR	proc8	=	"Venous Access-Intraosseous Pediatric"	OR
		proc9	=	"Venous Access-Extremity"	OR	proc9	=	"Venous Access-Intraosseous Adult"	OR	proc9	=	"Venous Access-Intraosseous Pediatric"	OR
		proc10	=	"Venous Access-Extremity"	OR	proc10	=	"Venous Access-Intraosseous Adult"	OR	proc10	=	"Venous Access-Intraosseous Pediatric"	OR
		proc11	=	"Venous Access-Extremity"	OR	proc11	=	"Venous Access-Intraosseous Adult"	OR	proc11	=	"Venous Access-Intraosseous Pediatric"	OR
		proc12	=	"Venous Access-Extremity"	OR	proc12	=	"Venous Access-Intraosseous Adult"	OR	proc12	=	"Venous Access-Intraosseous Pediatric"	OR
		proc13	=	"Venous Access-Extremity"	OR	proc13	=	"Venous Access-Intraosseous Adult"	OR	proc13	=	"Venous Access-Intraosseous Pediatric"	OR
		proc14	=	"Venous Access-Extremity"	OR	proc14	=	"Venous Access-Intraosseous Adult"	OR	proc14	=	"Venous Access-Intraosseous Pediatric"	OR
		proc15	=	"Venous Access-Extremity"	OR	proc15	=	"Venous Access-Intraosseous Adult"	OR	proc15	=	"Venous Access-Intraosseous Pediatric"	OR
		proc16	=	"Venous Access-Extremity"	OR	proc16	=	"Venous Access-Intraosseous Adult"	OR	proc16	=	"Venous Access-Intraosseous Pediatric"	OR
		proc17	=	"Venous Access-Extremity"	OR	proc17	=	"Venous Access-Intraosseous Adult"	OR	proc17	=	"Venous Access-Intraosseous Pediatric"	OR
		proc18	=	"Venous Access-Extremity"	OR	proc18	=	"Venous Access-Intraosseous Adult"	OR	proc18	=	"Venous Access-Intraosseous Pediatric"	OR
		proc19	=	"Venous Access-Extremity"	OR	proc19	=	"Venous Access-Intraosseous Adult"	OR	proc19	=	"Venous Access-Intraosseous Pediatric"	OR
		proc20	=	"Venous Access-Extremity"	OR	proc20	=	"Venous Access-Intraosseous Adult"	OR	proc20	=	"Venous Access-Intraosseous Pediatric"	OR
		proc21	=	"Venous Access-Extremity"	OR	proc21	=	"Venous Access-Intraosseous Adult"	OR	proc21	=	"Venous Access-Intraosseous Pediatric"	OR
		proc22	=	"Venous Access-Extremity"	OR	proc22	=	"Venous Access-Intraosseous Adult"	OR	proc22	=	"Venous Access-Intraosseous Pediatric"	OR
		proc23	=	"Venous Access-Extremity"	OR	proc23	=	"Venous Access-Intraosseous Adult"	OR	proc23	=	"Venous Access-Intraosseous Pediatric"	OR
		proc24	=	"Venous Access-Extremity"	OR	proc24	=	"Venous Access-Intraosseous Adult"	OR	proc24	=	"Venous Access-Intraosseous Pediatric"	OR
		proc25	=	"Venous Access-Extremity"	OR	proc25	=	"Venous Access-Intraosseous Adult"	OR	proc25	=	"Venous Access-Intraosseous Pediatric"	OR
		proc26	=	"Venous Access-Extremity"	OR	proc26	=	"Venous Access-Intraosseous Adult"	OR	proc26	=	"Venous Access-Intraosseous Pediatric"	OR
		proc27	=	"Venous Access-Extremity"	OR	proc27	=	"Venous Access-Intraosseous Adult"	OR	proc27	=	"Venous Access-Intraosseous Pediatric"	OR
		proc28	=	"Venous Access-Extremity"	OR	proc28	=	"Venous Access-Intraosseous Adult"	OR	proc28	=	"Venous Access-Intraosseous Pediatric"	OR
		proc29	=	"Venous Access-Extremity"	OR	proc29	=	"Venous Access-Intraosseous Adult"	OR	proc29	=	"Venous Access-Intraosseous Pediatric"	OR
		proc30	=	"Venous Access-Extremity"	OR	proc30	=	"Venous Access-Intraosseous Adult"	OR	proc30	=	"Venous Access-Intraosseous Pediatric"	OR
		proc31	=	"Venous Access-Extremity"	OR	proc31	=	"Venous Access-Intraosseous Adult"	OR	proc31	=	"Venous Access-Intraosseous Pediatric"	OR
		proc32	=	"Venous Access-Extremity"	OR	proc32	=	"Venous Access-Intraosseous Adult"	OR	proc32	=	"Venous Access-Intraosseous Pediatric"	OR
		proc33	=	"Venous Access-Extremity"	OR	proc33	=	"Venous Access-Intraosseous Adult"	OR	proc33	=	"Venous Access-Intraosseous Pediatric"	OR
		proc34	=	"Venous Access-Extremity"	OR	proc34	=	"Venous Access-Intraosseous Adult"	OR	proc34	=	"Venous Access-Intraosseous Pediatric"	OR
		proc35	=	"Venous Access-Extremity"	OR	proc35	=	"Venous Access-Intraosseous Adult"	OR	proc35	=	"Venous Access-Intraosseous Pediatric"	OR
		proc36	=	"Venous Access-Extremity"	OR	proc36	=	"Venous Access-Intraosseous Adult"	OR	proc36	=	"Venous Access-Intraosseous Pediatric"	OR
		proc37	=	"Venous Access-Extremity"	OR	proc37	=	"Venous Access-Intraosseous Adult"	OR	proc37	=	"Venous Access-Intraosseous Pediatric"	OR
		proc38	=	"Venous Access-Extremity"	OR	proc38	=	"Venous Access-Intraosseous Adult"	OR	proc38	=	"Venous Access-Intraosseous Pediatric"	OR
		proc39	=	"Venous Access-Extremity"	OR	proc39	=	"Venous Access-Intraosseous Adult"	OR	proc39	=	"Venous Access-Intraosseous Pediatric"	OR
		proc40	=	"Venous Access-Extremity"	OR	proc40	=	"Venous Access-Intraosseous Adult"	OR	proc40	=	"Venous Access-Intraosseous Pediatric"
	THEN IV = 1;
	ELSE IV = 0;
	IF	
		proc1	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc1	=	"Airway-Direct Laryngoscopy"	OR	proc1	=	"Airway-Eoa/Egta"	OR	proc1	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc1	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc1	=	"Airway-Nasotracheal Intubation"	OR	proc1	=	"Airway-Orotracheal Intubation"	OR	proc1	=	"Airway-Rapid Sequence Induction"	OR 	proc1	=	"Airway-Surgical Cricothyrotomy"	OR
		proc2	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc2	=	"Airway-Direct Laryngoscopy"	OR	proc2	=	"Airway-Eoa/Egta"	OR	proc2	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc2	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc2	=	"Airway-Nasotracheal Intubation"	OR	proc2	=	"Airway-Orotracheal Intubation"	OR	proc2	=	"Airway-Rapid Sequence Induction"	OR 	proc2	=	"Airway-Surgical Cricothyrotomy"	OR
		proc3	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc3	=	"Airway-Direct Laryngoscopy"	OR	proc3	=	"Airway-Eoa/Egta"	OR	proc3	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc3	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc3	=	"Airway-Nasotracheal Intubation"	OR	proc3	=	"Airway-Orotracheal Intubation"	OR	proc3	=	"Airway-Rapid Sequence Induction"	OR 	proc3	=	"Airway-Surgical Cricothyrotomy"	OR
		proc4	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc4	=	"Airway-Direct Laryngoscopy"	OR	proc4	=	"Airway-Eoa/Egta"	OR	proc4	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc4	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc4	=	"Airway-Nasotracheal Intubation"	OR	proc4	=	"Airway-Orotracheal Intubation"	OR	proc4	=	"Airway-Rapid Sequence Induction"	OR 	proc4	=	"Airway-Surgical Cricothyrotomy"	OR
		proc5	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc5	=	"Airway-Direct Laryngoscopy"	OR	proc5	=	"Airway-Eoa/Egta"	OR	proc5	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc5	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc5	=	"Airway-Nasotracheal Intubation"	OR	proc5	=	"Airway-Orotracheal Intubation"	OR	proc5	=	"Airway-Rapid Sequence Induction"	OR 	proc5	=	"Airway-Surgical Cricothyrotomy"	OR
		proc6	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc6	=	"Airway-Direct Laryngoscopy"	OR	proc6	=	"Airway-Eoa/Egta"	OR	proc6	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc6	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc6	=	"Airway-Nasotracheal Intubation"	OR	proc6	=	"Airway-Orotracheal Intubation"	OR	proc6	=	"Airway-Rapid Sequence Induction"	OR 	proc6	=	"Airway-Surgical Cricothyrotomy"	OR
		proc7	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc7	=	"Airway-Direct Laryngoscopy"	OR	proc7	=	"Airway-Eoa/Egta"	OR	proc7	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc7	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc7	=	"Airway-Nasotracheal Intubation"	OR	proc7	=	"Airway-Orotracheal Intubation"	OR	proc7	=	"Airway-Rapid Sequence Induction"	OR 	proc7	=	"Airway-Surgical Cricothyrotomy"	OR
		proc8	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc8	=	"Airway-Direct Laryngoscopy"	OR	proc8	=	"Airway-Eoa/Egta"	OR	proc8	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc8	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc8	=	"Airway-Nasotracheal Intubation"	OR	proc8	=	"Airway-Orotracheal Intubation"	OR	proc8	=	"Airway-Rapid Sequence Induction"	OR 	proc8	=	"Airway-Surgical Cricothyrotomy"	OR
		proc9	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc9	=	"Airway-Direct Laryngoscopy"	OR	proc9	=	"Airway-Eoa/Egta"	OR	proc9	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc9	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc9	=	"Airway-Nasotracheal Intubation"	OR	proc9	=	"Airway-Orotracheal Intubation"	OR	proc9	=	"Airway-Rapid Sequence Induction"	OR 	proc9	=	"Airway-Surgical Cricothyrotomy"	OR
		proc10	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc10	=	"Airway-Direct Laryngoscopy"	OR	proc10	=	"Airway-Eoa/Egta"	OR	proc10	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc10	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc10	=	"Airway-Nasotracheal Intubation"	OR	proc10	=	"Airway-Orotracheal Intubation"	OR	proc10	=	"Airway-Rapid Sequence Induction"	OR 	proc10	=	"Airway-Surgical Cricothyrotomy"	OR
		proc11	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc11	=	"Airway-Direct Laryngoscopy"	OR	proc11	=	"Airway-Eoa/Egta"	OR	proc11	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc11	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc11	=	"Airway-Nasotracheal Intubation"	OR	proc11	=	"Airway-Orotracheal Intubation"	OR	proc11	=	"Airway-Rapid Sequence Induction"	OR 	proc11	=	"Airway-Surgical Cricothyrotomy"	OR
		proc12	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc12	=	"Airway-Direct Laryngoscopy"	OR	proc12	=	"Airway-Eoa/Egta"	OR	proc12	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc12	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc12	=	"Airway-Nasotracheal Intubation"	OR	proc12	=	"Airway-Orotracheal Intubation"	OR	proc12	=	"Airway-Rapid Sequence Induction"	OR 	proc12	=	"Airway-Surgical Cricothyrotomy"	OR
		proc13	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc13	=	"Airway-Direct Laryngoscopy"	OR	proc13	=	"Airway-Eoa/Egta"	OR	proc13	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc13	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc13	=	"Airway-Nasotracheal Intubation"	OR	proc13	=	"Airway-Orotracheal Intubation"	OR	proc13	=	"Airway-Rapid Sequence Induction"	OR 	proc13	=	"Airway-Surgical Cricothyrotomy"	OR
		proc14	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc14	=	"Airway-Direct Laryngoscopy"	OR	proc14	=	"Airway-Eoa/Egta"	OR	proc14	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc14	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc14	=	"Airway-Nasotracheal Intubation"	OR	proc14	=	"Airway-Orotracheal Intubation"	OR	proc14	=	"Airway-Rapid Sequence Induction"	OR 	proc14	=	"Airway-Surgical Cricothyrotomy"	OR
		proc15	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc15	=	"Airway-Direct Laryngoscopy"	OR	proc15	=	"Airway-Eoa/Egta"	OR	proc15	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc15	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc15	=	"Airway-Nasotracheal Intubation"	OR	proc15	=	"Airway-Orotracheal Intubation"	OR	proc15	=	"Airway-Rapid Sequence Induction"	OR 	proc15	=	"Airway-Surgical Cricothyrotomy"	OR
		proc16	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc16	=	"Airway-Direct Laryngoscopy"	OR	proc16	=	"Airway-Eoa/Egta"	OR	proc16	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc16	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc16	=	"Airway-Nasotracheal Intubation"	OR	proc16	=	"Airway-Orotracheal Intubation"	OR	proc16	=	"Airway-Rapid Sequence Induction"	OR 	proc16	=	"Airway-Surgical Cricothyrotomy"	OR
		proc17	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc17	=	"Airway-Direct Laryngoscopy"	OR	proc17	=	"Airway-Eoa/Egta"	OR	proc17	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc17	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc17	=	"Airway-Nasotracheal Intubation"	OR	proc17	=	"Airway-Orotracheal Intubation"	OR	proc17	=	"Airway-Rapid Sequence Induction"	OR 	proc17	=	"Airway-Surgical Cricothyrotomy"	OR
		proc18	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc18	=	"Airway-Direct Laryngoscopy"	OR	proc18	=	"Airway-Eoa/Egta"	OR	proc18	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc18	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc18	=	"Airway-Nasotracheal Intubation"	OR	proc18	=	"Airway-Orotracheal Intubation"	OR	proc18	=	"Airway-Rapid Sequence Induction"	OR 	proc18	=	"Airway-Surgical Cricothyrotomy"	OR
		proc19	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc19	=	"Airway-Direct Laryngoscopy"	OR	proc19	=	"Airway-Eoa/Egta"	OR	proc19	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc19	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc19	=	"Airway-Nasotracheal Intubation"	OR	proc19	=	"Airway-Orotracheal Intubation"	OR	proc19	=	"Airway-Rapid Sequence Induction"	OR 	proc19	=	"Airway-Surgical Cricothyrotomy"	OR
		proc20	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc20	=	"Airway-Direct Laryngoscopy"	OR	proc20	=	"Airway-Eoa/Egta"	OR	proc20	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc20	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc20	=	"Airway-Nasotracheal Intubation"	OR	proc20	=	"Airway-Orotracheal Intubation"	OR	proc20	=	"Airway-Rapid Sequence Induction"	OR 	proc20	=	"Airway-Surgical Cricothyrotomy"	OR
		proc21	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc21	=	"Airway-Direct Laryngoscopy"	OR	proc21	=	"Airway-Eoa/Egta"	OR	proc21	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc21	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc21	=	"Airway-Nasotracheal Intubation"	OR	proc21	=	"Airway-Orotracheal Intubation"	OR	proc21	=	"Airway-Rapid Sequence Induction"	OR 	proc21	=	"Airway-Surgical Cricothyrotomy"	OR
		proc22	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc22	=	"Airway-Direct Laryngoscopy"	OR	proc22	=	"Airway-Eoa/Egta"	OR	proc22	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc22	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc22	=	"Airway-Nasotracheal Intubation"	OR	proc22	=	"Airway-Orotracheal Intubation"	OR	proc22	=	"Airway-Rapid Sequence Induction"	OR 	proc22	=	"Airway-Surgical Cricothyrotomy"	OR
		proc23	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc23	=	"Airway-Direct Laryngoscopy"	OR	proc23	=	"Airway-Eoa/Egta"	OR	proc23	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc23	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc23	=	"Airway-Nasotracheal Intubation"	OR	proc23	=	"Airway-Orotracheal Intubation"	OR	proc23	=	"Airway-Rapid Sequence Induction"	OR 	proc23	=	"Airway-Surgical Cricothyrotomy"	OR
		proc24	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc24	=	"Airway-Direct Laryngoscopy"	OR	proc24	=	"Airway-Eoa/Egta"	OR	proc24	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc24	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc24	=	"Airway-Nasotracheal Intubation"	OR	proc24	=	"Airway-Orotracheal Intubation"	OR	proc24	=	"Airway-Rapid Sequence Induction"	OR 	proc24	=	"Airway-Surgical Cricothyrotomy"	OR
		proc25	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc25	=	"Airway-Direct Laryngoscopy"	OR	proc25	=	"Airway-Eoa/Egta"	OR	proc25	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc25	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc25	=	"Airway-Nasotracheal Intubation"	OR	proc25	=	"Airway-Orotracheal Intubation"	OR	proc25	=	"Airway-Rapid Sequence Induction"	OR 	proc25	=	"Airway-Surgical Cricothyrotomy"	OR
		proc26	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc26	=	"Airway-Direct Laryngoscopy"	OR	proc26	=	"Airway-Eoa/Egta"	OR	proc26	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc26	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc26	=	"Airway-Nasotracheal Intubation"	OR	proc26	=	"Airway-Orotracheal Intubation"	OR	proc26	=	"Airway-Rapid Sequence Induction"	OR 	proc26	=	"Airway-Surgical Cricothyrotomy"	OR
		proc27	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc27	=	"Airway-Direct Laryngoscopy"	OR	proc27	=	"Airway-Eoa/Egta"	OR	proc27	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc27	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc27	=	"Airway-Nasotracheal Intubation"	OR	proc27	=	"Airway-Orotracheal Intubation"	OR	proc27	=	"Airway-Rapid Sequence Induction"	OR 	proc27	=	"Airway-Surgical Cricothyrotomy"	OR
		proc28	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc28	=	"Airway-Direct Laryngoscopy"	OR	proc28	=	"Airway-Eoa/Egta"	OR	proc28	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc28	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc28	=	"Airway-Nasotracheal Intubation"	OR	proc28	=	"Airway-Orotracheal Intubation"	OR	proc28	=	"Airway-Rapid Sequence Induction"	OR 	proc28	=	"Airway-Surgical Cricothyrotomy"	OR
		proc29	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc29	=	"Airway-Direct Laryngoscopy"	OR	proc29	=	"Airway-Eoa/Egta"	OR	proc29	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc29	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc29	=	"Airway-Nasotracheal Intubation"	OR	proc29	=	"Airway-Orotracheal Intubation"	OR	proc29	=	"Airway-Rapid Sequence Induction"	OR 	proc29	=	"Airway-Surgical Cricothyrotomy"	OR
		proc30	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc30	=	"Airway-Direct Laryngoscopy"	OR	proc30	=	"Airway-Eoa/Egta"	OR	proc30	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc30	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc30	=	"Airway-Nasotracheal Intubation"	OR	proc30	=	"Airway-Orotracheal Intubation"	OR	proc30	=	"Airway-Rapid Sequence Induction"	OR 	proc30	=	"Airway-Surgical Cricothyrotomy"	OR
		proc31	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc31	=	"Airway-Direct Laryngoscopy"	OR	proc31	=	"Airway-Eoa/Egta"	OR	proc31	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc31	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc31	=	"Airway-Nasotracheal Intubation"	OR	proc31	=	"Airway-Orotracheal Intubation"	OR	proc31	=	"Airway-Rapid Sequence Induction"	OR 	proc31	=	"Airway-Surgical Cricothyrotomy"	OR
		proc32	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc32	=	"Airway-Direct Laryngoscopy"	OR	proc32	=	"Airway-Eoa/Egta"	OR	proc32	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc32	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc32	=	"Airway-Nasotracheal Intubation"	OR	proc32	=	"Airway-Orotracheal Intubation"	OR	proc32	=	"Airway-Rapid Sequence Induction"	OR 	proc32	=	"Airway-Surgical Cricothyrotomy"	OR
		proc33	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc33	=	"Airway-Direct Laryngoscopy"	OR	proc33	=	"Airway-Eoa/Egta"	OR	proc33	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc33	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc33	=	"Airway-Nasotracheal Intubation"	OR	proc33	=	"Airway-Orotracheal Intubation"	OR	proc33	=	"Airway-Rapid Sequence Induction"	OR 	proc33	=	"Airway-Surgical Cricothyrotomy"	OR
		proc34	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc34	=	"Airway-Direct Laryngoscopy"	OR	proc34	=	"Airway-Eoa/Egta"	OR	proc34	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc34	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc34	=	"Airway-Nasotracheal Intubation"	OR	proc34	=	"Airway-Orotracheal Intubation"	OR	proc34	=	"Airway-Rapid Sequence Induction"	OR 	proc34	=	"Airway-Surgical Cricothyrotomy"	OR
		proc35	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc35	=	"Airway-Direct Laryngoscopy"	OR	proc35	=	"Airway-Eoa/Egta"	OR	proc35	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc35	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc35	=	"Airway-Nasotracheal Intubation"	OR	proc35	=	"Airway-Orotracheal Intubation"	OR	proc35	=	"Airway-Rapid Sequence Induction"	OR 	proc35	=	"Airway-Surgical Cricothyrotomy"	OR
		proc36	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc36	=	"Airway-Direct Laryngoscopy"	OR	proc36	=	"Airway-Eoa/Egta"	OR	proc36	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc36	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc36	=	"Airway-Nasotracheal Intubation"	OR	proc36	=	"Airway-Orotracheal Intubation"	OR	proc36	=	"Airway-Rapid Sequence Induction"	OR 	proc36	=	"Airway-Surgical Cricothyrotomy"	OR
		proc37	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc37	=	"Airway-Direct Laryngoscopy"	OR	proc37	=	"Airway-Eoa/Egta"	OR	proc37	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc37	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc37	=	"Airway-Nasotracheal Intubation"	OR	proc37	=	"Airway-Orotracheal Intubation"	OR	proc37	=	"Airway-Rapid Sequence Induction"	OR 	proc37	=	"Airway-Surgical Cricothyrotomy"	OR
		proc38	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc38	=	"Airway-Direct Laryngoscopy"	OR	proc38	=	"Airway-Eoa/Egta"	OR	proc38	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc38	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc38	=	"Airway-Nasotracheal Intubation"	OR	proc38	=	"Airway-Orotracheal Intubation"	OR	proc38	=	"Airway-Rapid Sequence Induction"	OR 	proc38	=	"Airway-Surgical Cricothyrotomy"	OR
		proc39	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc39	=	"Airway-Direct Laryngoscopy"	OR	proc39	=	"Airway-Eoa/Egta"	OR	proc39	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc39	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc39	=	"Airway-Nasotracheal Intubation"	OR	proc39	=	"Airway-Orotracheal Intubation"	OR	proc39	=	"Airway-Rapid Sequence Induction"	OR 	proc39	=	"Airway-Surgical Cricothyrotomy"	OR
		proc40	=	"Airway-Combitube Blind Insertion Airway Device"	OR	proc40	=	"Airway-Direct Laryngoscopy"	OR	proc40	=	"Airway-Eoa/Egta"	OR	proc40	=	"Airway-King Lt Blind Insertion Airway Device"	OR	proc40	=	"Airway-Laryngeal Mask Blind Insertion Airway Device"	OR	proc40	=	"Airway-Nasotracheal Intubation"	OR	proc40	=	"Airway-Orotracheal Intubation"	OR	proc40	=	"Airway-Rapid Sequence Induction"	OR 	proc40	=	"Airway-Surgical Cricothyrotomy"
	THEN Airway = 1;																																			
	ELSE Airway = 0;
RUN;
*checking work;
PROC FREQ DATA=SBBA_all; 
	TABLE Airway*(proc1-proc40) / list missing; 
	TITLE "Confirming Airway procedures";
RUN;
PROC FREQ DATA=SBBA_all; 
	TABLE IV*(proc1-proc40) / list missing; 
	TITLE "Confirming Venous Access procedures (to be applied to nemsis.condensed_seizures_benzos_broad)";
RUN;


*Replacing med1-med30 with variables BenzoTx1 and Rescue.
	BenzoTx1 = name of benzo used for initial treatment
	Rescue = binary variable for rescue therapy (y/n);
DATA SBBA_all;
	SET SBBA_all;
	BenzoTx1 = med1; 
	IF med2 = "Alprazolam" OR med2 = "Chlordiazepoxide" OR med2 = "Benzodiazepines" OR med2 = "Clonazepam" OR med2 = "Diazepam" OR med2 = "Lorazepam" OR med2 = "Midazolam Hydrochloride" 
	THEN rescue = 1;
	ELSE rescue = 0;
RUN;
*Checking work;
PROC FREQ DATA=SBBA_all; 
	TABLE BenzoTx1*med1 / list missing; 
	TITLE "Confirming BenzoTx1 = med1";
RUN;
PROC FREQ DATA=SBBA_all; 
	TABLE Rescue*med2 / list missing; 
	TITLE "Confirming Rescue = med2";
RUN;

*Creating a numeric version of BenzoTx1, where value "benzodizepines" is coded as missing;
DATA SBBA_all;
	SET SBBA_all; 
	IF benzotx1 = "Midazolam Hydrochloride" THEN BenzoCat = 1;
	ELSE IF benzotx1 = "Lorazepam" THEN BenzoCat = 2;
	ELSE IF benzotx1 = "Diazepam" THEN BenzoCat = 3;
	ELSE IF benzotx1 = "Clonazepam" THEN BenzoCat = 4;
	ELSE IF benzotx1 = "Alprazolam" THEN BenzoCat = 5;
	ELSE IF benzotx1 = "Chlordiazepoxide" THEN BenzoCat = 6;
	ELSE IF benzotx1 = "Benzodiazepines" THEN Benzocat = .;
RUN;
*checking work;
PROC FREQ DATA=SBBA_all;
	TABLE benzotx1*benzocat / nopercent norow nocol missing;
	TITLE "confirmting appropriate creation of BenzoCat";
RUN;

*creating a binary variable, Midazolam;
DATA SBBA_all;
	SET SBBA_all;
	IF BenzoCat = 1 THEN Midazolam = 1;
	ELSE IF BenzoCat >1 THEN Midazolam = 0;
	ELSE IF BenzoCat = . THEN Midazolam = .;
RUN;
*checking work;
PROC FREQ DATA=SBBA_all;
	TABLE benzocat*midazolam / nopercent norow nocol missing;
	TITLE "confirmting appropriate creation of Midazolam binary variable";
RUN;

*extracting Month and Year from E05_04 (date/time unit notified by dispatch);
DATA SBBA_all;
	SET  SBBA_all;
	Year = SUBSTR(E05_04,1,4);
	Month = SUBSTR(E05_04,6,2);
RUN;
*checking work;
PROC FREQ DATA=SBBA_all; 
	TABLE year / list missing;
	TABLE month / list missing;
		TITLE "Confirming appropriate creation of 'Year' and 'Month' variables";
RUN;

*making Year and Month numeric variables;
DATA SBBA_all;
	SET SBBA_all;
	Yearnum = INPUT(Year,4.);
	Monthnum = INPUT(Month,2.);
RUN;
*checking work;
PROC FREQ DATA=SBBA_all;
	TABLE Year*Yearnum / list missing;
	TABLE Month*Monthnum / list missing;
	TITLE "confirming changing Year and Month to numeric variables";
RUN;

*Change month to 0-60 (2010-2014). 2010 = 1-12, 2011 = 13-24, 2012 = 25-36, 2013 = 37-48, 2014 is 49-60;
DATA SBBA_all;
	SET SBBA_all;
	IF Yearnum = 2010 THEN StudyMonth = monthnum;
	ELSE IF Yearnum = 2011 THEN StudyMonth = monthnum + 12;
	ELSE IF Yearnum = 2012 THEN StudyMonth = monthnum + 24;
	ELSE IF Yearnum = 2013 THEN StudyMonth = monthnum + 36;
	ELSE IF Yearnum = 2014 THEN StudyMonth = monthnum + 48;
RUN;
PROC FREQ DATA=SBBA_all; 
	TABLE (Monthnum Yearnum)*StudyMonth / nopercent norow nocol;
	TITLE "Ensuring that StudyMonth was applied appropriately to Month, from year 2014";
RUN;


*recoding various values for missing data (-5, -10 -15, -20, -25) to missing;
DATA SBBA_all;
	SET SBBA_all;
	IF E03_01 < 0 THEN E03_01new = .;
		ELSE E03_01new = E03_01;
	IF E09_15 < 0 THEN E09_15new = .;
		ELSE E09_15new = E09_15;
	IF E09_16 < 0 THEN E09_16new = .;
		ELSE E09_16new = E09_16;
	IF E11_01 < 0 THEN E11_01new = .;
		ELSE E11_01new = E11_01;
	IF E09_04 < 0 THEN E09_04new = .;
		ELSE E09_04new = E09_04;
	IF E06_15 < 0 THEN E06_15new = .;
		ELSE E06_15new = E06_15;
	IF E06_11 < 0 THEN E06_11new = .;
		ELSE E06_11new = E06_11;
	IF E06_12 < 0 THEN E06_12new = .;
		ELSE E06_12new = E06_12;
	IF E06_13 < 0 THEN E06_13new = .;
		ELSE E06_13new = E06_13;
	IF E07_34 < 0 THEN E07_34new = .;
		ELSE E07_34new = E07_34;
RUN;
*checking work;
PROC FREQ DATA=SBBA_all;
	TABLE E03_01*E03_01new /list missing;
	TABLE E09_15*E09_15new /list missing;
	TABLE E09_16*E09_16new /list missing;
	TABLE E11_01*E11_01new /list missing;
	TABLE E09_04*E09_04new /list missing;
	TABLE E06_15*E06_15new /list missing;
	TABLE E06_11*E06_11new /list missing;
	TABLE E06_12*E06_12new /list missing;
	TABLE E06_13*E06_13new /list missing;
	TABLE E07_34*E07_34new /list missing;
		TITLE "Confirming definition of missing";
RUN;

*making conditioncode binary (seizure =1, not=.);
DATA SBBA_all;
	SET SBBA_all;
	IF condition1 < 0 THEN condition1new = .;
		ELSE condition1new = 1;
RUN;
*checking work;
PROC FREQ DATA=SBBA_all;
	TABLE condition1*condition1new /list missing;
	TITLE "defining condition code 8017 (seizure) as 1 (yes) to condition1new";
RUN;

*changing E02_05 and E02_04 from character to numeric;
DATA SBBA_all;
	SET SBBA_all;
	E02_05num = INPUT(E02_05,2.);
	E02_04num = INPUT (E02_04,2.);
RUN;
*checking work;
PROC FREQ DATA=SBBA_all;
	TABLE E02_05*E02_05num /list missing;
	TABLE E02_04*E02_04num /list missing;
	TITLE "changing E02_05 and E02_04 from character to numeric";
RUN;

*changing E06_14 (age) from character to numeric;
DATA SBBA_all;
	SET SBBA_all;
	E06_14num = INPUT(E06_14,3.);
RUN;
*checking work;
PROC FREQ DATA=SBBA_all;
	TABLE E06_14*E06_14num /list missing;
	TITLE "changing E06_14 from character to numeric";
RUN;

*Creating a new "age in years" variable from the age and age units variables;
DATA SBBA_all;
	SET SBBA_all;
	IF E06_15new = 715 THEN age_yrs = E06_14num;
	ELSE IF E06_15new = 710 THEN age_yrs = E06_14num/12;
	ELSE IF E06_15new = 705 THEN age_yrs = E06_14num/365;
	ELSE IF E06_15new = 700 THEN age_yrs = E06_14num/8760;
RUN;
*checking work;
PROC SORT DATA=SBBA_all; BY E06_15new; RUN;
PROC FREQ DATA=SBBA_all;
	TABLE age_yrs*E06_14num / list nopercent norow nocol;
	BY E06_15new;
	TITLE "Creating a new 'age in years' variable from the age and age units variables";
RUN;

*Creating an age category, following RAMPART age categories in table 1 (assuming missing age unit = years);
DATA SBBA_all;
	SET SBBA_all;
	IF age_yrs = . THEN AGEcat = .;
	ELSE IF age_yrs <6 THEN AGEcat = 1;
	ELSE IF 6 <= age_yrs < 11 THEN AGEcat = 2;
	ELSE IF 11 <= age_yrs <21 THEN Agecat = 3;
	ELSE IF 21 <= age_yrs <41 THEN AGEcat = 4;
	ELSE IF 41 <= age_yrs <61 THEN AGEcat = 5;
	ELSE IF age_yrs >= 61 THEN AGEcat = 6;
RUN;

*condensing race variable into Black, White, and Other;
DATA SBBA_all;
	SET SBBA_all;
	IF E06_12new = . THEN RACE = .;
	ELSE IF E06_12new = 680 THEN RACE = 0;
	ELSE IF E06_12new = 670 THEN RACE = 1;
	ELSE IF E06_12new = 660 OR E06_12new = 665 OR E06_12new = 675 OR E06_12new = 685 THEN RACE = 2;
RUN;
PROC FREQ DATA=SBBA_all;
	TABLE E06_12new*RACE;
	TITLE "combining values of race into OTHER";
RUN;

*Condensing categories for service level, primary role, and type of service;
PROC FREQ DATA=SBBA_all;
	TABLE E07_34new E02_05num E02_04num;
	TITLE "original categories for agency-level factors";
RUN;
DATA SBBA_all;
	SET SBBA_all;
	IF E07_34new = 990 OR E07_34new = 995 THEN service_level = 0;
	ELSE IF E07_34new = 1000 OR E07_34new = 1005 OR  E07_34new = 1010 THEN service_level = 1;
	ELSE IF E07_34new = 1025 OR E07_34new = 1030 THEN service_level = 2;
	ELSE IF E07_34new = 1015 OR E07_34new = 1020 THEN service_level = 3;
RUN;
DATA SBBA_all;
	SET SBBA_all;
	IF E02_05num = 75 THEN primary_role = 1;
	ELSE IF E02_05num = 60 OR E02_05num = 65 OR E02_05num = 70 THEN primary_role = 0;
RUN;
DATA SBBA_all;
	SET SBBA_all;
	IF E02_04num = 30 THEN Type_service = 1;
	ELSE IF E02_04num = 40 THEN type_service = 2;
	ELSE IF E02_04num = 35 OR E02_04num = 45 OR E02_04num = 50 OR E02_04num = 55 THEN type_service = 0;
RUN;

*Condensing categories for CC by dispatch, primary and secondary impressions;
DATA SBBA_all;
	SET SBBA_all;
	IF E03_01new = . THEN CC = .;
	ELSE IF E03_01new = 455 THEN CC = 1;
	ELSE IF E03_01new = 440 THEN CC = 2;
	ELSE IF E03_01new = 510 THEN CC = 3;
	ELSE IF E03_01new = 545 THEN CC = 4;
	ELSE IF E03_01new = 515 THEN CC = 5;
	ELSE CC = 6;
RUN;
PROC FREQ DATA=SBBA_all;
	TABLE E03_01new*CC / nopercent norow nocol missing;
RUN;
DATA SBBA_all;
	SET SBBA_all;
	IF E09_15new = . THEN primary = .;
	ELSE IF E09_15new = 1710 THEN primary = 1;
	ELSE IF E09_15new = 1640 THEN primary = 2;
	ELSE IF E09_15new = 1690 THEN primary = 3;
	ELSE IF E09_15new = 1740 THEN primary = 4;
	ELSE primary = 5;
RUN;
PROC FREQ DATA=SBBA_all;
	TABLE E09_15new*primary / nopercent norow nocol missing;
RUN;
DATA SBBA_all;
	SET SBBA_all;
	IF E09_16new = . THEN secondary = .;
	ELSE IF E09_16new = 1845 THEN secondary = 1;
	ELSE IF E09_16new = 1785 THEN secondary = 2;
	ELSE IF E09_16new = 1825 THEN secondary = 3;
	ELSE IF E09_16new = 1875 THEN secondary = 4;
	ELSE secondary = 5;
RUN;
PROC FREQ DATA=SBBA_all;
	TABLE E09_16new*secondary / nopercent norow nocol missing;
RUN;

*condensing file to relevant variables;
DATA nemsis.Sz_Agency_brd_all;
	SET SBBA_all;
	KEEP eventID E02_04num type_service E03_01new CC E07_34new service_level E09_15new primary E09_16new secondary condition1new E11_01new E09_04new BenzoTx1 BenzoCat Midazolam rescue E06_14num E06_15new age_yrs AGEcat E06_11new E06_12new RACE E06_13new USCensusRegion USCensusDivision Urbanicity E02_05num primary_role Airway IV StudyMonth Yearnum AgencyID AgencyState AgencyCounty;
RUN;

***********************************************************************
Labels and Formats nemsis.condensed_seizures_benzos_broad
**********************************************************************;

*Labeling variables;
DATA nemsis.Sz_Agency_brd_all;
	SET nemsis.Sz_Agency_brd_all;
	LABEL 	E03_01new = "CC by Dispatch"
			CC = "Cheif Complain, condensed"
			E09_15new = "Primary Impression"
			Primary = "Primary Impression, condensed"
			E09_16new = "Secondary Impression"
			Secondary = "Secondary Impression, condensed"
			condition1new = "Condition Code (limited)"
			E11_01new = "Cardiac Arrest"
			E09_04new = "Possible Injury"
			E06_14num = "Age"
			E06_15new = "Age Units"
			Age_yrs = "Age in Years"
			AGEcat = "Age category"
			E06_11new = "Gender"
			E06_12new = "Race"
			RACE = "Race, condenced"
			E06_13new = "Ethnicity"
			USCensusRegion = "US Census Region"
			USCensusDivision = "US Census Division"
			Urbanicity = "Urbanicity"
			E02_04num = "Type of Service Requested for Enounter"
			Type_service = "Type of Service Requested for Enounter, condensed"
			E02_05num = "Primary Role of Unit"
			primary_role = "Primary Role of Unit, condensed"
			E07_34new = "CMS Service Level for Enounter"
			service_level = "CMS Service Level, condensed"
			BenzoTx1 = "Initial Benzodiazepine used for Treatment (character)"
			BenzoCat = "Initial Benzodiazepine used for Treatment (numeric)"
			Midazolam = "Midazolam use as Initial Benzodiazepine"
			Rescue = "Rescue Therapy Provided"
			Airway = "Airway"
			IV = "Venous Access"
			StudyMonth = "Study Month"
			Yearnum = "Year"
			AgencyID = "Agency ID"
			AgencyState = "Agency State"
			AgencyCounty = "Agency County";
RUN;

*Creating SAS formats;
LIBNAME formats "D:\tanisl\Desktop\NEMSISdata";
PROC FORMAT LIBRARY=nemsis;
	VALUE E03_01new 455 = "455: Convulsion/seizure"
					440 = "440: cardiac arrest"
					510 = "510: ingestion/poisoning"
					515 = "515: pregnancy/childbirth"
					545 = "545: traumatic injury";
	VALUE CC		1 = "1: Convulsion/seizure"
					2 = "2: cardiac arrest"
					3 = "3: ingestion/poisoning"
					4 = "4: traumatic injury"
					5 = "5: pregnancy/childbirth"
					6 = "6: Other";
	VALUE E09_15new 1710 = "1710: seizure"
					1640 = "1640: cardiac arrest"
					1690 = "1690: poisoning/drug ingestion"
					1740 = "1740: traumatic injury";
	VALUE primary	1 = "1: seizure"
					2 = "2: cardiac arrest"
					3 = "3: poisoning/drug ingestion"
					4 = "4: traumatic injury"
					5 = "5: Other";
	VALUE E09_16new 1845 = "1845: seizure"
					1785 = "1785: cardiac arrest"
					1825 = "1825: poisoning/drug ingestion"
					1875 = "1875: traumatic injury";
	VALUE secondary 1 = "1: seizure"
					2 = "2: cardiac arrest"
					3 = "3: poisoning/drug ingestion"
					4 = "4: traumatic injury"
					5 = "5: Other";
	VALUE condition1new 1 = "1: seizures";
	VALUE E11_01new 0 = "0: No"
					2240 = "2240: Yes, prior to EMS arrival"
					2245 = "2245: Yes, after EMS arrival";
	VALUE E09_04new 0 = "0: No"
					1 = "1: Yes";
	VALUE E06_15new 700 = "700: Hours"
					705 = "705: Days"
					710 = "710: Months"
					715 = "715: Years";
	VALUE AGEcat	1 = "1: 0-5 years"
					2 = "2: 6-10 years"
					3 = "3: 11-20 years"
					4 = "4: 21-40 years"
					5 = "5: 41-60 years"
					6 = "6: >= 60 years";
	VALUE E06_11new 650 = "650: Male"
					655 = "655: Female";
	VALUE E06_12new 660 = "660: American Indian or Alaska Native"
					665 = "665: Asian"
					670 = "670: Black of African American"
					675 = "675: Native Hawaiian or Other Pacific Islander"
					680 = "680: White"
					685 = "685: Other";
	VALUE RACE		0 = "0: White"
					1 = "1: Black"
					2 = "2: Other";
	VALUE E06_13new 690 = "690: Hispanic or Latino"
					695 = "695: Not Hispanic or Latino";
	VALUE E02_04num	30 = "30: 911 Response"
					35 = "35: Intercept"
					40 = "40: Interfacility Transfer"
					45 = "45: Medical Transport"
					50 = "50: Mutual Aid"
					55 = "55: Standby";
	VALUE type_service	1 = "1: 911 Response"
						2 = "2: Interfacility Transfer"
						0 = "0: Other";
	VALUE E02_05num	60 = "60: Non-transport"
					65 = "65: Rescue"
					70 = "70: supervisor"
					75 = "75: Transport";
	VALUE primary_role	1 = "1: Transport"
						0 = "0: Other";
	VALUE E07_34new	990 = "990: BLS"
					995 = "995: BLS, Emergency"
					1000 = "1000: ALS, Level 1"
					1005 = "1005: ALS, Level 1 Emergency"
					1010 = "1010: ALS, Level 2"
					1015 = "1015: Paramedic Intercept"
					1020 = "1020: Specialty Care Transport"
					1025 = "1025: Fixed Wing"
					1030 = "1030: Rotary Wing";
	VALUE service_level 0 = "0: BLS"
						1 = "1: ALS"
						2 = "2: Air"
						3 = "3: Other";
	VALUE Rescue	1 = "1: Yes"
					0 = "0: No";
	VALUE AIRWAY	1 = "1: Yes"
					0 = "0: No";
	VALUE IV 		1 = "1: Yes"
					0 = "0: No";
	VALUE BenzoCat	1 = "1: Midazolam"
					2 = "2: Lorazepam"
					3 = "3: Diazepam"
					4 = "4: Clonazepam"
					5 = "5: Alprazolam"
					6 = "6: Chlordiazepoxide"
					. = ".: 'Benzodiazepines'";
	VALUE Midazolam	1 = "1: Midazolam"
					0 = "0: Other Benzo"
					. = ".: 'Benzodiazepines'";
RUN;

*applying formats;
DATA nemsis.Sz_Agency_brd_all;
	SET nemsis.Sz_Agency_brd_all;
	OPTIONS fmtsearch = (nemsis);
	format E03_01new E03_01new. CC CC. E09_15new E09_15new. primary primary. E09_16new E09_16new. secondary secondary. condition1new condition1new. E11_01new E11_01new. E09_04new E09_04new. E06_15new E06_15new. agecat agecat. E06_11new E06_11new. E06_12new E06_12new. race race. E06_13new E06_13new. E02_04num E02_04num. E02_05num E02_05num. E07_34new E07_34new. type_service type_service. service_level service_level. primary_role primary_role. rescue rescue. airway airway. IV IV. Benzocat benzocat. midazolam midazolam.;
RUN;

*****************************************************************************************
Preparing for analysis
*************************************************************************************;

*make a narrowly defined seizure database;
DATA nemsis.Sz_Agency_narrow_all;
	SET nemsis.Sz_Agency_brd_all;
	IF E09_15new = 1710 OR E09_16new = 1845;
RUN;

*finding frequency of seizure treated by benzodiazepines in narrowly defined dataset;
PROC FREQ DATA=nemsis.Sz_Agency_narrow_all;
	TABLE yearnum; 
	TITLE "frequency of seizure treated by benzodiazepines in narrowly defined dataset";
RUN;

*creating a binary variable for being post-RAMPART;
DATA nemsis.Sz_Agency_narrow_all;
	SET nemsis.Sz_Agency_narrow_all;
	IF Studymonth >= 26 THEN post_RAMPART = 1;
	ELSE IF studymonth < 26 THEN post_RAMPART = 0;
RUN;
PROC FREQ DATA=nemsis.Sz_Agency_narrow_all;
	TABLE studymonth*post_RAMPART / list;
	TITLE "confirmtion creation of a binary variable for being post-RAMPART";
RUN;

*can IV procedure be used as proxy for IV medication? (not really, 70% of Midaz pts got IV as well);
PROC FREQ DATA=nemsis.Sz_Agency_narrow_all;
	WHERE yearnum = 2011;
	TABLE IV*BenzoTx1;
	TITLE "frequency of IV placement by different benzidiazepines 2011";
RUN;
PROC FREQ DATA=nemsis.Sz_Agency_narrow_all;
	WHERE yearnum = 2014;
	TABLE IV*BenzoTx1;
	TITLE "frequency of IV placement by different benzidiazepines 2014";
RUN;

*Race and ethnicity to R/E;
		*NOT easy to combine into one variable;
PROC FREQ DATA=nemsis.Sz_Agency_narrow_all;
	TABLE RACE*E06_13new / missing;
	TITLE "checking of race and ethnicity can be combined into one variable";
RUN;


*****************************************************************************************
Preparing agency database for analysis
*************************************************************************************;

PROC CONTENTS DATA=nemsis.Agency_all;
RUN;

*Looking for dublicates (none);
PROC FREQ DATA=nemsis.Agency_all noprint;
	TABLES eventID / out=repeventID;
RUN;
PROC CONTENTS DATA=repeventID VARNUM;
RUN;

*outputting frequency of events (agency size) per agency by year;
*2010;
PROC FREQ DATA=nemsis.randomkey2010 NOPRINT;
	TABLE agencyID / out=agency10_event_freq;
RUN;
DATA agency10_event_freq;
	SET agency10_event_freq;
	call_freq_10 = count;
	KEEP agencyID call_freq_10;
RUN;
*2011;
PROC FREQ DATA=nemsis.randomkey2011 NOPRINT;
	TABLE agencyID / out=agency11_event_freq;
RUN;
DATA agency11_event_freq;
	SET agency11_event_freq;
	call_freq_11 = count;
	KEEP agencyID call_freq_11;
RUN;
*2012;
PROC FREQ DATA=nemsis.randomkey2012 NOPRINT;
	TABLE agencyID / out=agency12_event_freq;
RUN;
DATA agency12_event_freq;
	SET agency12_event_freq;
	call_freq_12 = count;
	KEEP agencyID call_freq_12;
RUN;
*2013;
PROC FREQ DATA=nemsis.randomkey2013 NOPRINT;
	TABLE agencyID / out=agency13_event_freq;
RUN;
DATA agency13_event_freq;
	SET agency13_event_freq;
	call_freq_13 = count;
	KEEP agencyID call_freq_13;
RUN;
*2014;
PROC FREQ DATA=nemsis.randomkey2014 NOPRINT;
	TABLE agencyID / out=agency14_event_freq;
RUN;
DATA agency14_event_freq;
	SET agency14_event_freq;
	call_freq_14 = count;
	KEEP agencyID call_freq_14;
RUN;

*outputting frequency of midazolam use BY agency;
*2010;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS AgencyID;
	WHERE yearnum = 2010 and benzocat NE .;
	OUTPUT OUT = midaz_mean_10
		Mean (midazolam) = Midaz_freq;
RUN;
DATA midaz_mean_10;
	SET midaz_mean_10;
	midaz_10 = midaz_freq;
	benzo_freq_10 = _freq_;
	KEEP AgencyID midaz_10 benzo_freq_10;
RUN;
*2011;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS AgencyID;
	WHERE yearnum = 2011 and benzocat NE .;
	OUTPUT OUT = midaz_mean_11
		Mean (midazolam) = Midaz_freq;
RUN;
DATA midaz_mean_11;
	SET midaz_mean_11;
	midaz_11 = midaz_freq;
	benzo_freq_11 = _freq_;
	KEEP AgencyID midaz_11 benzo_freq_11;
RUN;
*2012;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS AgencyID;
	WHERE yearnum = 2012 and benzocat NE .;
	OUTPUT OUT = midaz_mean_12
		Mean (midazolam) = Midaz_freq;
RUN;
DATA midaz_mean_12;
	SET midaz_mean_12;
	midaz_12 = midaz_freq;
	benzo_freq_12 = _freq_;
	KEEP AgencyID midaz_12 benzo_freq_12;
RUN;
*2013;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS AgencyID;
	WHERE yearnum = 2013 and benzocat NE .;
	OUTPUT OUT = midaz_mean_13
		Mean (midazolam) = Midaz_freq;
RUN;
DATA midaz_mean_13;
	SET midaz_mean_13;
	midaz_13 = midaz_freq;
	benzo_freq_13 = _freq_;
	KEEP AgencyID midaz_13 benzo_freq_13;
RUN;
*2014;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS AgencyID;
	WHERE yearnum = 2014 and benzocat NE .;
	OUTPUT OUT = midaz_mean_14
		Mean (midazolam) = Midaz_freq;
RUN;
DATA midaz_mean_14;
	SET midaz_mean_14;
	midaz_14 = midaz_freq;
	benzo_freq_14 = _freq_;
	KEEP AgencyID midaz_14 benzo_freq_14;
RUN;

*Adding variable for ranking of midazolam use for each year; 
*2010;
PROC RANK DATA=midaz_mean_10 OUT=midaz_rank_10 DESCENDING TIES=low;
	VAR midaz_10;
	RANKS midaz_rank_10;
RUN;
*2011;
PROC RANK DATA=midaz_mean_11 OUT=midaz_rank_11 DESCENDING TIES=low;
	VAR midaz_11;
	RANKS midaz_rank_11;
RUN;
*2012;
PROC RANK DATA=midaz_mean_12 OUT=midaz_rank_12 DESCENDING TIES=low;
	VAR midaz_12;
	RANKS midaz_rank_12;
RUN;
*2013;
PROC RANK DATA=midaz_mean_13 OUT=midaz_rank_13 DESCENDING TIES=low;
	VAR midaz_13;
	RANKS midaz_rank_13;
RUN;
*2014;
PROC RANK DATA=midaz_mean_14 OUT=midaz_rank_14 DESCENDING TIES=low;
	VAR midaz_14;
	RANKS midaz_rank_14;
RUN;

*Adding variable for ranking of call volume for each year; 
*2010;
PROC RANK DATA=agency10_event_freq OUT=call_rank_10 DESCENDING TIES=low;
	VAR call_freq_10;
	RANKS call_rank_10;
RUN;
*2011;
PROC RANK DATA=agency11_event_freq OUT=call_rank_11 DESCENDING TIES=low;
	VAR call_freq_11;
	RANKS call_rank_11;
RUN;
*2012;
PROC RANK DATA=agency12_event_freq OUT=call_rank_12 DESCENDING TIES=low;
	VAR call_freq_12;
	RANKS call_rank_12;
RUN;
*2013;
PROC RANK DATA=agency13_event_freq OUT=call_rank_13 DESCENDING TIES=low;
	VAR call_freq_13;
	RANKS call_rank_13;
RUN;
*2014;
PROC RANK DATA=agency14_event_freq OUT=call_rank_14 DESCENDING TIES=low;
	VAR call_freq_14;
	RANKS call_rank_14;
RUN;

*merging agency datasets, limiting to those agencies who had at least one event (in any year) where they gave benzos for a seizure;
PROC SORT DATA=call_rank_10; BY agencyID; RUN;
PROC SORT DATA=call_rank_11; BY agencyID; RUN;
PROC SORT DATA=call_rank_12; BY agencyID; RUN;
PROC SORT DATA=call_rank_13; BY agencyID; RUN;
PROC SORT DATA=call_rank_14; BY agencyID; RUN;
PROC SORT DATA=midaz_rank_10; BY agencyID; RUN;
PROC SORT DATA=midaz_rank_11; BY agencyID; RUN;
PROC SORT DATA=midaz_rank_12; BY agencyID; RUN;
PROC SORT DATA=midaz_rank_13; BY agencyID; RUN;
PROC SORT DATA=midaz_rank_14; BY agencyID; RUN;
DATA NEMSIS.Agency_wide;
	MERGE call_rank_10 midaz_rank_10 call_rank_11 midaz_rank_11 call_rank_12 midaz_rank_12 call_rank_13 midaz_rank_13 call_rank_14 midaz_rank_14;
	BY agencyID;
	IF benzo_freq_10 NE . OR benzo_freq_11 NE . OR benzo_freq_12 NE . OR benzo_freq_13 NE . OR benzo_freq_14 NE .;
RUN;


*applying labels to nemsis.agency_wide;
DATA nemsis.agency_wide;
	SET nemsis.agency_wide;
	LABEL 	Benzo_freq_10 = "Number of Seizure Events Requiring Benzos in 2010"
		 	Benzo_freq_11 = "Number of Seizure Events Requiring Benzos in 2011"
			Benzo_freq_12 = "Number of Seizure Events Requiring Benzos in 2012"
			Benzo_freq_13 = "Number of Seizure Events Requiring Benzos in 2013"
			Benzo_freq_14 = "Number of Seizure Events Requiring Benzos in 2014"
			Midaz_10 = "Frequency of Midaz use in 2010 (out of all benzos)"
			Midaz_11 = "Frequency of Midaz use in 2011 (out of all benzos)"
			Midaz_12 = "Frequency of Midaz use in 2012 (out of all benzos)"
			Midaz_13 = "Frequency of Midaz use in 2013 (out of all benzos)"
			Midaz_14 = "Frequency of Midaz use in 2014 (out of all benzos)"
			Call_freq_10 = "Total Number of Calls to Agency in 2010"
			Call_freq_11 = "Total Number of Calls to Agency in 2011"
			Call_freq_12 = "Total Number of Calls to Agency in 2012"
			Call_freq_13 = "Total Number of Calls to Agency in 2013"
			Call_freq_14 = "Total Number of Calls to Agency in 2014"
			Call_rank_10 = "Agency Call Rank in 2010"
			Call_rank_11 = "Agency Call Rank in 2011"
			Call_rank_12 = "Agency Call Rank in 2012"
			Call_rank_13 = "Agency Call Rank in 2013"
			Call_rank_14 = "Agency Call Rank in 2014"
			Midaz_rank_10 = "Agency Rank for Frequency of Midazolam use in 2010"
			Midaz_rank_11 = "Agency Rank for Frequency of Midazolam use in 2011"
			Midaz_rank_12 = "Agency Rank for Frequency of Midazolam use in 2012"
			Midaz_rank_13 = "Agency Rank for Frequency of Midazolam use in 2013"
			Midaz_rank_14 = "Agency Rank for Frequency of Midazolam use in 2014";
RUN;

*creating a binary variable for agency completeness, and 2 variables for the change in midazolam use (absolute and relative);
DATA nemsis.agency_wide;
	SET nemsis.agency_wide;
	IF midaz_10 NE . AND midaz_11 NE . AND midaz_12 NE . AND midaz_13 NE . AND midaz_14 NE . THEN Agency_complete = 1;
	ELSE Agency_complete = 0;
	delta_midaz = (midaz_14 - midaz_10);
	percent_change = ((midaz_14 - midaz_10)/midaz_10);
RUN;

PROC PRINT DATA=nemsis.agency_wide (firstobs=1 obs=10);
	VAR agencyID midaz_10 midaz_11 midaz_12 midaz_13 midaz_14 agency_complete delta_midaz percent_change;
	TITLE "confirming creation fo agency_complete, delta-midaz, and percent_change variables";
RUN;

*creating variables for annual change in midazolam;
DATA nemsis.agency_wide;
	SET nemsis.agency_wide;
	delta_midaz_10_11 = (midaz_11 - midaz_10);
	delta_midaz_11_12 = (midaz_12 - midaz_11);
	delta_midaz_12_13 = (midaz_13 - midaz_12);
	delta_midaz_13_14 = (midaz_14 - midaz_13);
RUN;
PROC PRINT DATA=nemsis.agency_wide (obs =10);
	VAR agencyID midaz_10 midaz_11 midaz_12 midaz_13 midaz_14 delta_midaz_10_11 delta_midaz_11_12 delta_midaz_12_13 delta_midaz_13_14;
	TITLE "creating variable for annual change in midaz";
RUN; 


*****creating a variable for agency size quintiles/deciles******;
*Creating a variable for number of years the agency is represented;
DATA nemsis.agency_wide;
	SET nemsis.agency_wide;
	IF call_freq_10 NE . and call_freq_11 NE . and call_freq_12 NE . and call_freq_13 NE . and call_freq_14 NE . THEN years_rep = 5;

	ELSE IF  call_freq_10 NE . and call_freq_11 NE . and call_freq_12 NE . and call_freq_13 NE . and call_freq_14 = . THEN years_rep = 4;
	ELSE IF  call_freq_10 NE . and call_freq_11 NE . and call_freq_12 NE . and call_freq_13 = . and call_freq_14 NE . THEN years_rep = 4;
	ELSE IF  call_freq_10 NE . and call_freq_11 NE . and call_freq_12 = . and call_freq_13 NE . and call_freq_14 NE . THEN years_rep = 4;
	ELSE IF  call_freq_10 NE . and call_freq_11 = . and call_freq_12 NE . and call_freq_13 NE . and call_freq_14 NE . THEN years_rep = 4;
	ELSE IF  call_freq_10 = . and call_freq_11 NE . and call_freq_12 NE . and call_freq_13 NE . and call_freq_14 NE . THEN years_rep = 4;

	ELSE IF  call_freq_10 NE . and call_freq_11 NE . and call_freq_12 NE . and call_freq_13 = . and call_freq_14 = . THEN years_rep = 3;
	ELSE IF  call_freq_10 NE . and call_freq_11 NE . and call_freq_12 = . and call_freq_13 NE . and call_freq_14 = . THEN years_rep = 3;
	ELSE IF  call_freq_10 NE . and call_freq_11 = . and call_freq_12 NE . and call_freq_13 NE . and call_freq_14 = . THEN years_rep = 3;
	ELSE IF  call_freq_10 = . and call_freq_11 NE . and call_freq_12 NE . and call_freq_13 NE . and call_freq_14 = . THEN years_rep = 3;
	ELSE IF  call_freq_10 NE . and call_freq_11 NE . and call_freq_12 = . and call_freq_13 = . and call_freq_14 NE . THEN years_rep = 3;
	ELSE IF  call_freq_10 NE . and call_freq_11 = . and call_freq_12 NE . and call_freq_13 = . and call_freq_14 NE . THEN years_rep = 3;
	ELSE IF  call_freq_10 = . and call_freq_11 NE . and call_freq_12 NE . and call_freq_13 = . and call_freq_14 NE . THEN years_rep = 3;
	ELSE IF  call_freq_10 NE . and call_freq_11 = . and call_freq_12 = . and call_freq_13 NE . and call_freq_14 NE . THEN years_rep = 3;
	ELSE IF  call_freq_10 = . and call_freq_11 NE . and call_freq_12 = . and call_freq_13 NE . and call_freq_14 NE . THEN years_rep = 3;
	ELSE IF  call_freq_10 = . and call_freq_11 = . and call_freq_12 NE . and call_freq_13 NE . and call_freq_14 NE . THEN years_rep = 3;

	ELSE IF  call_freq_10 NE . and call_freq_11 NE . and call_freq_12 = . and call_freq_13 = . and call_freq_14 = . THEN years_rep = 2;
	ELSE IF  call_freq_10 NE . and call_freq_11 = . and call_freq_12 NE . and call_freq_13 = . and call_freq_14 = . THEN years_rep = 2;
	ELSE IF  call_freq_10 NE . and call_freq_11 = . and call_freq_12 = . and call_freq_13 NE . and call_freq_14 = . THEN years_rep = 2;
	ELSE IF  call_freq_10 NE . and call_freq_11 = . and call_freq_12 = . and call_freq_13 = . and call_freq_14 NE . THEN years_rep = 2;
	ELSE IF  call_freq_10 = . and call_freq_11 NE . and call_freq_12 NE . and call_freq_13 = . and call_freq_14 = . THEN years_rep = 2;
	ELSE IF  call_freq_10 = . and call_freq_11 NE . and call_freq_12 = . and call_freq_13 NE . and call_freq_14 = . THEN years_rep = 2;
	ELSE IF  call_freq_10 = . and call_freq_11 NE . and call_freq_12 = . and call_freq_13 = . and call_freq_14 NE . THEN years_rep = 2;
	ELSE IF  call_freq_10 = . and call_freq_11 = . and call_freq_12 NE . and call_freq_13 NE . and call_freq_14 = . THEN years_rep = 2;
	ELSE IF  call_freq_10 = . and call_freq_11 = . and call_freq_12 NE . and call_freq_13 = . and call_freq_14 NE . THEN years_rep = 2;
	ELSE IF  call_freq_10 = . and call_freq_11 = . and call_freq_12 = . and call_freq_13 NE . and call_freq_14 NE . THEN years_rep = 2;

	ELSE IF  call_freq_10 NE . and call_freq_11 = . and call_freq_12 = . and call_freq_13 = . and call_freq_14 = . THEN years_rep = 1;
	ELSE IF  call_freq_10 = . and call_freq_11 NE . and call_freq_12 = . and call_freq_13 = . and call_freq_14 = . THEN years_rep = 1;
	ELSE IF  call_freq_10 = . and call_freq_11 = . and call_freq_12 NE . and call_freq_13 = . and call_freq_14 = . THEN years_rep = 1;
	ELSE IF  call_freq_10 = . and call_freq_11 = . and call_freq_12 = . and call_freq_13 NE . and call_freq_14 = . THEN years_rep = 1;
	ELSE IF  call_freq_10 = . and call_freq_11 = . and call_freq_12 = . and call_freq_13 = . and call_freq_14 NE . THEN years_rep = 1;

	ELSE IF  call_freq_10 = . and call_freq_11 = . and call_freq_12 = . and call_freq_13 = . and call_freq_14 = . THEN years_rep = 0;
RUN;
PROC FREQ DATA=nemsis.agency_wide;
	table years_rep;
RUN;

*creating variables for total number of calls and average number of calls/year;
DATA nemsis.agency_wide;
	SET nemsis.agency_wide;
	IF call_freq_10 = . THEN call_freq_10 = 0;
	IF call_freq_11 = . THEN call_freq_11 = 0;
	IF call_freq_12 = . THEN call_freq_12 = 0;
	IF call_freq_13 = . THEN call_freq_13 = 0;
	IF call_freq_14 = . THEN call_freq_14 = 0;
	sum_calls = (call_freq_10 + call_freq_11 + call_freq_12 + call_freq_13 + call_freq_14);
	avg_callvol = sum_calls/years_rep;
RUN;

*creating agency size quintiles and deciles;
PROC RANK DATA=nemsis.agency_wide OUT=nemsis.agency_wide GROUPS=5;
	VAR avg_callvol;
	RANKS size_quintile;
	LABEL size_quintile = "Agency Size Quintile";
RUN;
PROC RANK DATA=nemsis.agency_wide OUT=nemsis.agency_wide GROUPS=10;
	VAR avg_callvol;
	RANKS size_decile;
	LABEL size_decile = "Agency Size Decile";
RUN;
PROC RANK DATA=nemsis.agency_wide OUT=nemsis.agency_wide GROUPS=20;
	VAR avg_callvol;
	RANKS size_ventile;
	LABEL size_ventile = "Agency Size 20th";
RUN;
PROC FREQ DATA=nemsis.agency_wide;
	TABLE size_quintile size_decile size_ventile;
	TITLE "confirming creation of agency size quintiles, deciles, ventiles";
RUN;

*Creating a variable for number of years the agency treated at least on seizure;
DATA nemsis.agency_wide;
	SET nemsis.agency_wide;
	IF benzo_freq_10 NE . and benzo_freq_11 NE . and benzo_freq_12 NE . and benzo_freq_13 NE . and benzo_freq_14 NE . THEN years_sz_rep = 5;

	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 NE . and benzo_freq_12 NE . and benzo_freq_13 NE . and benzo_freq_14 = . THEN years_sz_rep = 4;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 NE . and benzo_freq_12 NE . and benzo_freq_13 = . and benzo_freq_14 NE . THEN years_sz_rep = 4;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 NE . and benzo_freq_12 = . and benzo_freq_13 NE . and benzo_freq_14 NE . THEN years_sz_rep = 4;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 = . and benzo_freq_12 NE . and benzo_freq_13 NE . and benzo_freq_14 NE . THEN years_sz_rep = 4;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 NE . and benzo_freq_12 NE . and benzo_freq_13 NE . and benzo_freq_14 NE . THEN years_sz_rep = 4;

	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 NE . and benzo_freq_12 NE . and benzo_freq_13 = . and benzo_freq_14 = . THEN years_sz_rep = 3;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 NE . and benzo_freq_12 = . and benzo_freq_13 NE . and benzo_freq_14 = . THEN years_sz_rep = 3;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 = . and benzo_freq_12 NE . and benzo_freq_13 NE . and benzo_freq_14 = . THEN years_sz_rep = 3;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 NE . and benzo_freq_12 NE . and benzo_freq_13 NE . and benzo_freq_14 = . THEN years_sz_rep = 3;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 NE . and benzo_freq_12 = . and benzo_freq_13 = . and benzo_freq_14 NE . THEN years_sz_rep = 3;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 = . and benzo_freq_12 NE . and benzo_freq_13 = . and benzo_freq_14 NE . THEN years_sz_rep = 3;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 NE . and benzo_freq_12 NE . and benzo_freq_13 = . and benzo_freq_14 NE . THEN years_sz_rep = 3;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 = . and benzo_freq_12 = . and benzo_freq_13 NE . and benzo_freq_14 NE . THEN years_sz_rep = 3;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 NE . and benzo_freq_12 = . and benzo_freq_13 NE . and benzo_freq_14 NE . THEN years_sz_rep = 3;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 = . and benzo_freq_12 NE . and benzo_freq_13 NE . and benzo_freq_14 NE . THEN years_sz_rep = 3;

	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 NE . and benzo_freq_12 = . and benzo_freq_13 = . and benzo_freq_14 = . THEN years_sz_rep = 2;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 = . and benzo_freq_12 NE . and benzo_freq_13 = . and benzo_freq_14 = . THEN years_sz_rep = 2;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 = . and benzo_freq_12 = . and benzo_freq_13 NE . and benzo_freq_14 = . THEN years_sz_rep = 2;
	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 = . and benzo_freq_12 = . and benzo_freq_13 = . and benzo_freq_14 NE . THEN years_sz_rep = 2;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 NE . and benzo_freq_12 NE . and benzo_freq_13 = . and benzo_freq_14 = . THEN years_sz_rep = 2;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 NE . and benzo_freq_12 = . and benzo_freq_13 NE . and benzo_freq_14 = . THEN years_sz_rep = 2;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 NE . and benzo_freq_12 = . and benzo_freq_13 = . and benzo_freq_14 NE . THEN years_sz_rep = 2;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 = . and benzo_freq_12 NE . and benzo_freq_13 NE . and benzo_freq_14 = . THEN years_sz_rep = 2;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 = . and benzo_freq_12 NE . and benzo_freq_13 = . and benzo_freq_14 NE . THEN years_sz_rep = 2;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 = . and benzo_freq_12 = . and benzo_freq_13 NE . and benzo_freq_14 NE . THEN years_sz_rep = 2;

	ELSE IF  benzo_freq_10 NE . and benzo_freq_11 = . and benzo_freq_12 = . and benzo_freq_13 = . and benzo_freq_14 = . THEN years_sz_rep = 1;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 NE . and benzo_freq_12 = . and benzo_freq_13 = . and benzo_freq_14 = . THEN years_sz_rep = 1;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 = . and benzo_freq_12 NE . and benzo_freq_13 = . and benzo_freq_14 = . THEN years_sz_rep = 1;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 = . and benzo_freq_12 = . and benzo_freq_13 NE . and benzo_freq_14 = . THEN years_sz_rep = 1;
	ELSE IF  benzo_freq_10 = . and benzo_freq_11 = . and benzo_freq_12 = . and benzo_freq_13 = . and benzo_freq_14 NE . THEN years_sz_rep = 1;

	ELSE IF  benzo_freq_10 = . and benzo_freq_11 = . and benzo_freq_12 = . and benzo_freq_13 = . and benzo_freq_14 = . THEN years_sz_rep = 0;
RUN;
PROC FREQ DATA=nemsis.agency_wide;
	table years_rep;
RUN;

*creating an agency dataset with only non-missing values for all years;
DATA nemsis.agency_nomiss;
	SET nemsis.agency_wide;
	IF agency_complete = 1;
RUN;



********************************************
State-Level Database
*****************************************;
*outputting frequency of midazolam use BY agency;
*2010;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS agencystate;
	WHERE yearnum = 2010;
	OUTPUT OUT = state_midaz_mean_10
		Mean (midazolam) = Midaz_freq;
RUN;
DATA state_midaz_mean_10;
	SET state_midaz_mean_10;
	midaz_10 = midaz_freq;
	benzo_freq_10 = _freq_;
	KEEP agencystate midaz_10 benzo_freq_10;
RUN;
*2011;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS agencystate;
	WHERE yearnum = 2011;
	OUTPUT OUT = state_midaz_mean_11
		Mean (midazolam) = Midaz_freq;
RUN;
DATA state_midaz_mean_11;
	SET state_midaz_mean_11;
	midaz_11 = midaz_freq;
	benzo_freq_11 = _freq_;
	KEEP agencystate midaz_11 benzo_freq_11;
RUN;
*2012;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS agencystate;
	WHERE yearnum = 2012;
	OUTPUT OUT = state_midaz_mean_12
		Mean (midazolam) = Midaz_freq;
RUN;
DATA state_midaz_mean_12;
	SET state_midaz_mean_12;
	midaz_12 = midaz_freq;
	benzo_freq_12 = _freq_;
	KEEP agencystate midaz_12 benzo_freq_12;
RUN;
*2013;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS agencystate;
	WHERE yearnum = 2013;
	OUTPUT OUT = state_midaz_mean_13
		Mean (midazolam) = Midaz_freq;
RUN;
DATA state_midaz_mean_13;
	SET state_midaz_mean_13;
	midaz_13 = midaz_freq;
	benzo_freq_13 = _freq_;
	KEEP agencystate midaz_13 benzo_freq_13;
RUN;
*2014;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS agencystate;
	WHERE yearnum = 2014;
	OUTPUT OUT = state_midaz_mean_14
		Mean (midazolam) = Midaz_freq;
RUN;
DATA state_midaz_mean_14;
	SET state_midaz_mean_14;
	midaz_14 = midaz_freq;
	benzo_freq_14 = _freq_;
	KEEP agencystate midaz_14 benzo_freq_14;
RUN;

*merging agency datasets, limiting to those agencies who had at least one event (in any year) where they gave benzos for a seizure;
PROC SORT DATA=state_midaz_mean_10; BY agencystate; RUN;
PROC SORT DATA=state_midaz_mean_11; BY agencystate; RUN;
PROC SORT DATA=state_midaz_mean_12; BY agencystate; RUN;
PROC SORT DATA=state_midaz_mean_13; BY agencystate; RUN;
PROC SORT DATA=state_midaz_mean_14; BY agencystate; RUN;
DATA nemsis.state_wide;
	MERGE state_midaz_mean_10 state_midaz_mean_11 state_midaz_mean_12 state_midaz_mean_13 state_midaz_mean_14;
	BY agencystate;
	IF benzo_freq_10 NE . OR benzo_freq_11 NE . OR benzo_freq_12 NE . OR benzo_freq_13 NE . OR benzo_freq_14 NE .;
RUN;

*applying labels to nemsis.agency_wide;
DATA nemsis.state_wide;
	SET nemsis.state_wide;
	LABEL 	Benzo_freq_10 = "Number of Seizure Events Requiring Benzos in 2010"
		 	Benzo_freq_11 = "Number of Seizure Events Requiring Benzos in 2011"
			Benzo_freq_12 = "Number of Seizure Events Requiring Benzos in 2012"
			Benzo_freq_13 = "Number of Seizure Events Requiring Benzos in 2013"
			Benzo_freq_14 = "Number of Seizure Events Requiring Benzos in 2014"
			Midaz_10 = "Frequency of Midaz use in 2010 (out of all benzos)"
			Midaz_11 = "Frequency of Midaz use in 2011 (out of all benzos)"
			Midaz_12 = "Frequency of Midaz use in 2012 (out of all benzos)"
			Midaz_13 = "Frequency of Midaz use in 2013 (out of all benzos)"
			Midaz_14 = "Frequency of Midaz use in 2014 (out of all benzos)";
RUN;

*creating a binary variable for state completeness, and 2 variables for the change in midazolam use (absolute and relative);
DATA nemsis.state_wide;
	SET nemsis.state_wide;
	IF midaz_10 NE . AND midaz_11 NE . AND midaz_12 NE . AND midaz_13 NE . AND midaz_14 NE . THEN state_complete = 1;
	ELSE state_complete = 0;
	delta_midaz = (midaz_14 - midaz_10);
	percent_change = ((midaz_14 - midaz_10)/midaz_10);
RUN;
PROC PRINT DATA=nemsis.state_wide (firstobs=1 obs=10);
	VAR agencystate midaz_10 midaz_11 midaz_12 midaz_13 midaz_14 state_complete delta_midaz percent_change;
	TITLE "confirming creation fo state_complete, delta-midaz, and percent_change variables";
RUN;

*proportions among states, all years combined;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS agencystate;
	OUTPUT OUT = s_prop_midaz_t 
		Mean (midazolam) = Midaz_prop_total;
RUN;
DATA s_prop_midaz_total;
	SET s_prop_midaz_t;
	KEEP agencystate Midaz_prop_total;
RUN;


*proportions among states, per year;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS agencystate yearnum;
	OUTPUT OUT = s_prop_midaz_y
		Mean (midazolam) = Midaz_prop_year;
RUN;
DATA s_prop_midaz_year;
	SET s_prop_midaz_y;
	IF yearnum NE .;
	KEEP agencystate yearnum Midaz_prop_year;
RUN;
PROC SORT DATA=s_prop_midaz_total; BY agencystate; RUN;
PROC SORT DATA=s_prop_midaz_year; BY agencystate; RUN;
DATA nemsis.s_prop_midaz_merged;
	MERGE s_prop_midaz_total s_prop_midaz_year;
	BY agencystate;
	Label Midaz_prop_year = "Midazolam (%)";
	FORMAT Midaz_prop_year;
RUN;

*proportions among states, per month;
PROC MEANS data=nemsis.Sz_Agency_narrow_all NOPRINT;
	VAR midazolam;
	CLASS agencystate studymonth;
	OUTPUT OUT = s_prop_midaz_m
		Mean (midazolam) = Midaz_prop_month;
RUN;
DATA s_prop_midaz_month;
	SET s_prop_midaz_m;
	IF studymonth NE .;
	KEEP agencystate studymonth Midaz_prop_month;
RUN;

PROC SORT DATA=s_prop_midaz_total; BY agencystate; RUN;
PROC SORT DATA=s_prop_midaz_month; BY agencystate; RUN;
DATA nemsis.s_prop_midaz_month_merged;
	MERGE s_prop_midaz_total s_prop_midaz_month;
	BY agencystate;
	Label Midaz_prop_month = "Midazolam (%)";
	FORMAT Midaz_prop_month;
RUN;


*****************************************************************************************
Preparing a database of midazolam frequency
*************************************************************************************;

*merging agency dataset with nemsis.Sz_Agency_narrow_all;
PROC SORT DATA=nemsis.Sz_Agency_narrow_all; BY agencyID; RUN;
PROC SORT DATA=nemsis.agency_wide; BY agencyID; RUN;
DATA NEMSIS.complete;
	MERGE nemsis.Sz_Agency_narrow_all nemsis.agency_wide;
	BY agencyID;
	IF midazolam NE .;
RUN;

*creating a year variable based on studymonth/12;
DATA nemsis.complete;
	SET nemsis.complete;
	year_granular = studymonth/12;
RUN;
PROC FREQ DATA=nemsis.complete;
	table studymonth*year_granular / list;
RUN;

*creating binary variables for missingness level of character variables uscensus region and urbanicity;
DATA nemsis.complete;
	SET nemsis.complete;
	IF USCensusRegion = "Island Areas" OR USCensusRegion = "Northeast" OR USCensusRegion = "Midwest" OR USCensusRegion = "South" OR USCensusRegion = "West"
		THEN region_nomiss = 1;
		ELSE region_nomiss = 0;
	IF Urbanicity = "Urban" OR Urbanicity = "Suburban" OR Urbanicity = "Rural" OR Urbanicity = "Wilderness"
		THEN urbanicity_nomiss = 1;
		ELSE urbanicity_nomiss = 0;
RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE region_nomiss*USCensusRegion / list;
	TABLE urbanicity_nomiss*urbanicity / list;
	TITLE "confirming creation of binary indivator variables for missingness";
RUN;

*creating an indicator variable for observations that have no missing data for all covariates;
DATA nemsis.complete;
	SET nemsis.complete;
	IF post_RAMPART NE . and studymonth NE . and agecat NE . and E06_11new NE . and race NE . and E06_13new NE . and region_nomiss = 1 and Urbanicity_nomiss = 1 and Service_level NE . and primary_role NE . and type_service NE .
		THEN all_cov_nomiss = 1;
		ELSE all_cov_nomiss = 0;
RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE all_cov_nomiss / list;
	TITLE "confirming creation of indicator variable for observations without any missing data for all covaraites";
RUN;

*creating an indicator variable for observations that have no missing data for all covariates that have low missingness (<1.5%);
DATA nemsis.complete;
	SET nemsis.complete;
	IF post_RAMPART NE . and studymonth NE . and agecat NE . and E06_11new NE . and region_nomiss = 1 and Urbanicity_nomiss = 1 and primary_role NE . and type_service NE .
		THEN lowmiss_cov_nomiss = 1;
		ELSE lowmiss_cov_nomiss = 0;
RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE lowmiss_cov_nomiss / list;
	TITLE "confirming creation of indicator variable for observations without any missing data for low-missingness covaraites";
RUN;

*creating an indicator variable for observations that have no missing data for all covariates that have low missingness plus race (b models);
DATA nemsis.complete;
	SET nemsis.complete;
	IF post_RAMPART NE . and studymonth NE . and agecat NE . and E06_11new NE . and race NE . and region_nomiss = 1 and Urbanicity_nomiss = 1 and primary_role NE . and type_service NE .
		THEN lowmiss_race_nomiss = 1;
		ELSE lowmiss_race_nomiss = 0;
RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE lowmiss_race_nomiss / list;
	TITLE "confirming creation of indicator variable for observations without any missing data for low-missingness covaraites + race";
RUN;

*creating an indicator variable for observations that have no missing data for all covariates that have low missingness plus ethnicity (c models);
DATA nemsis.complete;
	SET nemsis.complete;
	IF post_RAMPART NE . and studymonth NE . and agecat NE . and E06_11new NE . and E06_13new NE . and region_nomiss = 1 and Urbanicity_nomiss = 1 and primary_role NE . and type_service NE .
		THEN lowmiss_ethnicity_nomiss = 1;
		ELSE lowmiss_ethnicity_nomiss = 0;
RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE lowmiss_ethnicity_nomiss / list;
	TITLE "confirming creation of indicator variable for observations without any missing data for low-missingness covaraites + ethnicity";
RUN;

*creating an indicator variable for observations that have no missing data for all covariates that have low missingness plus service level (d models);
DATA nemsis.complete;
	SET nemsis.complete;
	IF post_RAMPART NE . and studymonth NE . and agecat NE . and E06_11new NE . and region_nomiss = 1 and Urbanicity_nomiss = 1 and service_level NE . and primary_role NE . and type_service NE .
		THEN lowmiss_servlevel_nomiss = 1;
		ELSE lowmiss_servlevel_nomiss = 0;
RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE lowmiss_servlevel_nomiss / list;
	TITLE "confirming creation of indicator variable for observations without any missing data for low-missingness covaraites + service level";
RUN;

************************************************
Preparing table for Poisson regression
***********************************************;

*outcome variables: proportion of midaz/benzos used to treat seizures;
*Count of Midazolam use by AgencyID and Year;
PROC SORT DATA=nemsis.complete; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.complete NOPRINT;
	TABLE midazolam / out=midaz_count_year;
	BY agencyID yearnum;
RUN;
DATA midaz_count_year;
	SET midaz_count_year;
	WHERE midazolam = 1;
	midaz = count;
	KEEP agencyID yearnum midaz;
RUN;
*count of benzodiazepine use by AgencyID and year;
PROC SORT DATA=nemsis.complete; BY agencyID yearnum; RUN;
PROC MEANS DATA=nemsis.complete NOPRINT;
	VAR midazolam;
	BY agencyID yearnum;
	OUTPUT OUT=benzo_count_year n (midazolam) = count;
RUN;
DATA benzo_count_year;
	SET benzo_count_year;
	benzos = _freq_;
	KEEP agencyID yearnum benzos;
RUN;

*predictors: proportions of each predictor variable for every agency/year;

*combining datasets by year;
%MACRO agency_year (events, geocodes, randomkey, agency, year);
PROC SORT DATA=&events; BY eventID; RUN;
PROC SORT DATA=&geocodes; BY eventID; RUN;
PROC SORT DATA=&randomkey; BY eventID; RUN;
DATA &agency;
	MERGE &events &geocodes &randomkey;
	BY eventID;
	Yearnum = &year;
RUN;
%MEND;
%agency_year (nemsis.events10, nemsis.geocodes10, nemsis.randomkey2010, nemsis.agency10, 2010);
%agency_year (nemsis.events11, nemsis.geocodes11, nemsis.randomkey2011, nemsis.agency11, 2011);
%agency_year (nemsis.events12, nemsis.geocodes12, nemsis.randomkey2012, nemsis.agency12, 2012);
%agency_year (nemsis.events13, nemsis.geocodes13, nemsis.randomkey2013, nemsis.agency13, 2013);
%agency_year (nemsis.events14, nemsis.geocodes14, nemsis.randomkey2014, nemsis.agency14, 2014);

*merging agency datasets;
PROC SORT DATA=nemsis.agency10; BY agencyID yearnum; RUN;
PROC SORT DATA=nemsis.agency11; BY agencyID yearnum; RUN;
PROC SORT DATA=nemsis.agency12; BY agencyID yearnum; RUN;
PROC SORT DATA=nemsis.agency13; BY agencyID yearnum; RUN;
PROC SORT DATA=nemsis.agency14; BY agencyID yearnum; RUN;
DATA nemsis.agency_events_all;
	MERGE nemsis.agency10 nemsis.agency11 nemsis.agency12 nemsis.agency13 nemsis.agency14;
	BY agencyID yearnum;
	KEEP eventID agencyID AgencyState AgencyCounty yearnum uscensusregion urbanicity E06_14 E06_15 E06_11 E06_12 E06_13 E07_34 E02_05 E02_04;
RUN;


*preparing agency_events_all dataset with categories consistent with nemsis.complete;

*changing variables from character to numeric;
DATA nemsis.agency_events_all_intermediate;
	SET nemsis.agency_events_all;
	E02_04num = INPUT (E02_04,2.);
	E02_05num = INPUT (E02_05,2.);
	E06_11num = INPUT (E06_11,3.);
	E06_12num = INPUT (E06_12,3.);
	E06_13num = INPUT (E06_13,3.);
	E06_14num = INPUT (E06_14,3.);
	E06_15num = INPUT (E06_15,3.);
	E07_34num = INPUT (E07_34,4.);
RUN;
*checking work;
PROC FREQ DATA=nemsis.agency_events_all_intermediate;
	TABLE E02_04*E02_04num /list missing;
	TABLE E02_05*E02_05num /list missing;
	TABLE E06_11*E06_11num /list missing;
	TABLE E06_12*E06_12num /list missing;
	TABLE E06_13*E06_13num /list missing;
	TABLE E06_14*E06_14num /list missing;
	TABLE E06_15*E06_15num /list missing;
	TABLE E07_34*E07_34num /list missing;
	TITLE "changing variables from character to numeric";
RUN;

*recoding various values for missing data (-5, -10 -15, -20, -25) to missing;
DATA nemsis.agency_events_all_intermediate;
	SET nemsis.agency_events_all_intermediate;
	IF E06_11num < 0 THEN E06_11new = .;
		ELSE E06_11new = E06_11num;
	IF E06_12num < 0 THEN E06_12new = .;
		ELSE E06_12new = E06_12num;
	IF E06_13num < 0 THEN E06_13new = .;
		ELSE E06_13new = E06_13num;
	IF E06_14num < 0 THEN E06_14new = .;
		ELSE E06_14new = E06_14num;
	IF E06_15num < 0 THEN E06_15new = .;
		ELSE E06_15new = E06_15num;
	IF E07_34num < 0 THEN E07_34new = .;
		ELSE E07_34new = E07_34num;
RUN;
*checking work;
PROC FREQ DATA=nemsis.agency_events_all_intermediate;
	TABLE E06_11num*E06_11new /list missing;
	TABLE E06_12num*E06_12new /list missing;
	TABLE E06_13num*E06_13new /list missing;
	TABLE E06_14num*E06_14new /list missing;
	TABLE E06_15num*E06_15new /list missing;
	TABLE E07_34num*E07_34new /list missing;
		TITLE "Confirming definition of missing";
RUN;

*Creating a new "age in years" variable from the age and age units variables;
DATA nemsis.agency_events_all_intermediate;
	SET nemsis.agency_events_all_intermediate;
	IF E06_15new = 715 THEN age_yrs = E06_14new;
	ELSE IF E06_15new = 710 THEN age_yrs = E06_14new/12;
	ELSE IF E06_15new = 705 THEN age_yrs = E06_14new/365;
	ELSE IF E06_15new = 700 THEN age_yrs = E06_14new/8760;
RUN;
*checking work;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY E06_15new; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate;
	TABLE age_yrs*E06_14new / list nopercent norow nocol;
	BY E06_15new;
	TITLE "Creating a new 'age in years' variable from the age and age units variables";
RUN;

*Creating an age category, following RAMPART age categories in table 1 (assuming missing age unit = years);
DATA nemsis.agency_events_all_intermediate;
	SET nemsis.agency_events_all_intermediate;
	IF age_yrs = . THEN AGEcat = .;
	ELSE IF age_yrs <6 THEN AGEcat = 1;
	ELSE IF 6 <= age_yrs < 11 THEN AGEcat = 2;
	ELSE IF 11 <= age_yrs <21 THEN Agecat = 3;
	ELSE IF 21 <= age_yrs <41 THEN AGEcat = 4;
	ELSE IF 41 <= age_yrs <61 THEN AGEcat = 5;
	ELSE IF age_yrs >= 61 THEN AGEcat = 6;
RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate;
	TABLE AGEcat*age_yrs;
	TITLE "categorizing age in years";
RUN;

*condensing race variable into Black, White, and Other;
DATA nemsis.agency_events_all_intermediate;
	SET nemsis.agency_events_all_intermediate;
	IF E06_12new = . THEN RACE = .;
	ELSE IF E06_12new = 680 THEN RACE = 0;
	ELSE IF E06_12new = 670 THEN RACE = 1;
	ELSE IF E06_12new = 660 OR E06_12new = 665 OR E06_12new = 675 OR E06_12new = 685 THEN RACE = 2;
RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate;
	TABLE E06_12new*RACE;
	TITLE "categorizing race";
RUN;

*condensing service level variable into BLS, ALS, Air, other;
DATA nemsis.agency_events_all_intermediate;
	SET nemsis.agency_events_all_intermediate;
	IF E07_34new = . THEN service_level = .;
	ELSE IF E07_34new = 990 OR E07_34new = 995 THEN service_level = 0;
	ELSE IF E07_34new = 1000 OR E07_34new = 1005 OR  E07_34new = 1010 THEN service_level = 1;
	ELSE IF E07_34new = 1025 OR E07_34new = 1030 THEN service_level = 2;
	ELSE IF E07_34new = 1015 OR E07_34new = 1020 THEN service_level = 3;
RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate;
	TABLE E07_34new*service_level;
	TITLE "categorizing service level";
RUN;

*condensing primary role variable into transport and other;
DATA nemsis.agency_events_all_intermediate;
	SET nemsis.agency_events_all_intermediate;
	IF E02_05num = . THEN primary_role = .;
	ELSE IF E02_05num = 75 THEN primary_role = 1;
	ELSE IF E02_05num = 60 OR E02_05num = 65 OR E02_05num = 70 THEN primary_role = 0;
RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate;
	TABLE E02_05num*primary_role;
	TITLE "categorizing primary role";
RUN;

*condensing type of service variable into 911, transfer, and other;
DATA nemsis.agency_events_all_intermediate;
	SET nemsis.agency_events_all_intermediate;
	IF E02_04num = . THEN type_service = .;
	ELSE IF E02_04num = 30 THEN Type_service = 1;
	ELSE IF E02_04num = 40 THEN type_service = 2;
	ELSE IF E02_04num = 35 OR E02_04num = 45 OR E02_04num = 50 OR E02_04num = 55 THEN type_service = 0;
RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate;
	TABLE E02_04num*Type_service;
	TITLE "categorizing Type service";
RUN;

*count of age categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE agecat / out=age_count_year;
	BY agencyID yearnum;
RUN;
DATA agecat_1_count_year;
	SET age_count_year;
	IF agecat = 1;
	agecat_1 = count;
	KEEP agencyID yearnum agecat_1;
RUN;
DATA agecat_2_count_year;
	SET age_count_year;
	IF agecat = 2;
	agecat_2 = count;
	KEEP agencyID yearnum agecat_2;
RUN;
DATA agecat_3_count_year;
	SET age_count_year;
	IF agecat = 3;
	agecat_3 = count;
	KEEP agencyID yearnum agecat_3;
RUN;
DATA agecat_4_count_year;
	SET age_count_year;
	IF agecat = 4;
	agecat_4 = count;
	KEEP agencyID yearnum agecat_4;
RUN;
DATA agecat_5_count_year;
	SET age_count_year;
	IF agecat = 5;
	agecat_5 = count;
	KEEP agencyID yearnum agecat_5;
RUN;
DATA agecat_6_count_year;
	SET age_count_year;
	IF agecat = 6;
	agecat_6 = count;
	KEEP agencyID yearnum agecat_6;
RUN;
DATA agecat_missing_count_year;
	SET age_count_year;
	IF agecat = .;
	agecat_missing = count;
	KEEP agencyID yearnum agecat_missing;
RUN;

*count of gender categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE E06_11new / out=gender_count_year;
	BY agencyID yearnum;
RUN;
DATA Male_count_year;
	SET gender_count_year;
	IF E06_11new = 650;
	male = count;
	KEEP agencyID yearnum male;
RUN;
DATA Female_count_year;
	SET gender_count_year;
	IF E06_11new = 655;
	female = count;
	KEEP agencyID yearnum female;
RUN;
DATA Gender_missing_count_year;
	SET gender_count_year;
	IF E06_11new = .;
	gender_missing = count;
	KEEP agencyID yearnum gender_missing;
RUN;

*count of race categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE race / out=race_count_year;
	BY agencyID yearnum;
RUN;
DATA White_count_year;
	SET race_count_year;
	IF race = 0;
	White = count;
	KEEP agencyID yearnum white;
RUN;
DATA Black_count_year;
	SET race_count_year;
	IF race = 1;
	black = count;
	KEEP agencyID yearnum black;
RUN;
DATA Race_other_count_year;
	SET race_count_year;
	IF race = 2;
	race_other = count;
	KEEP agencyID yearnum race_other;
RUN;
DATA Race_missing_count_year;
	SET race_count_year;
	IF race = .;
	race_missing = count;
	KEEP agencyID yearnum race_missing;
RUN;

*count of ethnicity categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE E06_13new / out=ethnicity_count_year;
	BY agencyID yearnum;
RUN;
DATA Hispanic_count_year;
	SET ethnicity_count_year;
	IF E06_13new = 690;
	Hispanic = count;
	KEEP agencyID yearnum Hispanic;
RUN;
DATA Not_Hispanic_count_year;
	SET ethnicity_count_year;
	IF E06_13new = 695;
	Not_Hispanic = count;
	KEEP agencyID yearnum Not_Hispanic;
RUN;
DATA ethnicity_missing_count_year;
	SET ethnicity_count_year;
	IF E06_13new = .;
	ethnicity_missing = count;
	KEEP agencyID yearnum ethnicity_missing;
RUN;

*count of census region categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE USCensusRegion / out=region_count_year;
	BY agencyID yearnum;
RUN;
DATA Island_count_year;
	SET region_count_year;
	IF USCensusRegion = "Island Areas";
	Island = count;
	KEEP agencyID yearnum Island;
RUN;
DATA Midwest_count_year;
	SET region_count_year;
	IF USCensusRegion = "Midwest";
	Midwest = count;
	KEEP agencyID yearnum Midwest;
RUN;
DATA Northeast_count_year;
	SET region_count_year;
	IF USCensusRegion = "Northeast";
	Northeast = count;
	KEEP agencyID yearnum Northeast;
RUN;
DATA South_count_year;
	SET region_count_year;
	IF USCensusRegion = "South";
	South = count;
	KEEP agencyID yearnum South;
RUN;
DATA West_count_year;
	SET region_count_year;
	IF USCensusRegion = "West";
	West = count;
	KEEP agencyID yearnum West;
RUN;
DATA region_missing_count_year;
	SET region_count_year;
	IF USCensusRegion NE "Midwest" and USCensusRegion NE "Northeast" and USCensusRegion NE "West" and USCensusRegion NE "South" and USCensusRegion NE "Island Areas";
	region_missing = count;
	KEEP agencyID yearnum region_missing;
RUN;

*count of urbanicity categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE urbanicity / out=urbanicity_count_year;
	BY agencyID yearnum;
RUN;
DATA Rural_count_year;
	SET urbanicity_count_year;
	IF urbanicity = "Rural";
	Rural = count;
	KEEP agencyID yearnum Rural;
RUN;
DATA Suburban_count_year;
	SET urbanicity_count_year;
	IF urbanicity = "Suburban";
	Suburban = count;
	KEEP agencyID yearnum Suburban;
RUN;
DATA Urban_count_year;
	SET urbanicity_count_year;
	IF urbanicity = "Urban";
	Urban = count;
	KEEP agencyID yearnum Urban;
RUN;
DATA Wilderness_count_year;
	SET urbanicity_count_year;
	IF urbanicity = "Wilderness";
	Wilderness = count;
	KEEP agencyID yearnum Wilderness;
RUN;
DATA urbanicity_missing_count_year;
	SET urbanicity_count_year;
	IF urbanicity NE "Rural" and urbanicity NE "Suburban" and urbanicity NE "Urban" and urbanicity NE "Wilderness";
	urbanicity_missing = count;
	KEEP agencyID yearnum urbanicity_missing;
RUN;

*count of service level categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE service_level / out=service_level_count_year;
	BY agencyID yearnum;
RUN;
DATA BLS_count_year;
	SET service_level_count_year;
	IF service_level = 0;
	BLS = count;
	KEEP agencyID yearnum BLS;
RUN;
DATA ALS_count_year;
	SET service_level_count_year;
	IF service_level = 1;
	ALS = count;
	KEEP agencyID yearnum ALS;
RUN;
DATA Air_count_year;
	SET service_level_count_year;
	IF service_level = 2;
	Air = count;
	KEEP agencyID yearnum Air;
RUN;
DATA service_level_other_count_year;
	SET service_level_count_year;
	IF service_level = 3;
	service_level_other = count;
	KEEP agencyID yearnum service_level_other;
RUN;
DATA service_level_missing_count_year;
	SET service_level_count_year;
	IF service_level = .;
	service_level_missing = count;
	KEEP agencyID yearnum service_level_missing;
RUN;

*count of primary role categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE primary_role / out=primary_role_count_year;
	BY agencyID yearnum;
RUN;
DATA transport_count_year;
	SET primary_role_count_year;
	IF primary_role = 1;
	transport = count;
	KEEP agencyID yearnum transport;
RUN;
DATA role_other_count_year;
	SET primary_role_count_year;
	IF primary_role = 0;
	role_other = count;
	KEEP agencyID yearnum role_other;
RUN;
DATA role_missing_count_year;
	SET primary_role_count_year;
	IF primary_role = .;
	role_missing = count;
	KEEP agencyID yearnum role_missing;
RUN;

*count of service type categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE type_service / out=type_service_count_year;
	BY agencyID yearnum;
RUN;
DATA response_count_year;
	SET type_service_count_year;
	IF type_service = 1;
	response = count;
	KEEP agencyID yearnum response;
RUN;
DATA transfer_count_year;
	SET type_service_count_year;
	IF type_service = 2;
	transfer = count;
	KEEP agencyID yearnum transfer;
RUN;
DATA service_type_other_count_year;
	SET type_service_count_year;
	IF type_service = 0;
	service_type_other = count;
	KEEP agencyID yearnum service_type_other;
RUN;
DATA service_type_missing_count_year;
	SET type_service_count_year;
	IF type_service = .;
	service_type_missing = count;
	KEEP agencyID yearnum service_type_missing;
RUN;

*count of call volume by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE agencyID / out=agency_event_freq_year;
	BY yearnum;
RUN;
DATA call_count_year;
	SET agency_event_freq_year;
	calls = count;
	KEEP agencyID yearnum calls;
RUN;

*size quintiles;
PROC SORT DATA=call_count; BY yearnum; RUN;
PROC RANK DATA=call_count OUT=call_quintile_year GROUPS=5;
	VAR calls;
	RANKS size_quintile;
	BY yearnum;
	LABEL size_quintile = "call Size Quintile";
RUN;



*count of number of states by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE agencystate / out=agency_state_count_year;
	BY agencyID yearnum;
RUN;
PROC SORT DATA=agency_sate_count_year; BY agencyID; RUN;
PROC FREQ DATA=agency_state_count_year NOPRINT;
	TABLE yearnum / out=agency_state_count_2_year;
	BY agencyID;
RUN;
DATA state_count_year;
	SET agency_state_count_2_year;
	states = count;
	KEEP agencyID yearnum states;
RUN;

*count of number of counties by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID yearnum; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE agencycounty / out=agency_county_count_year;
	BY agencyID yearnum;
RUN;
PROC SORT DATA=agency_county_count_year; BY agencyID; RUN;
PROC FREQ DATA=agency_county_count_year NOPRINT;
	TABLE yearnum / out=agency_county_count_2_year;
	BY agencyID;
RUN;
DATA county_count_year;
	SET agency_county_count_2_year;
	counties = count;
	KEEP agencyID yearnum counties;
RUN;


*creating poisson dataset by merging base datasets;
PROC SORT DATA=midaz_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=benzo_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=agecat_1_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=agecat_2_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=agecat_3_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=agecat_4_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=agecat_5_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=agecat_6_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=agecat_missing_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=male_coun_yeart; BY agencyID yearnum; RUN;
PROC SORT DATA=female_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=gender_missing_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=white_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=black_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=race_other_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=race_missing_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=hispanic_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=not_hispanic_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=ethnicity_missing_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=island_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=midwest_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=northeast_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=south_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=west_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=region_missing_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=rural_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=suburban_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=urban_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=wilderness_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=urbanicity_missing_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=bls_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=als_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=air_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=service_level_other_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=service_level_missing_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=transport_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=role_other_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=role_missing_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=response_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=transfer_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=service_type_other_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=service_type_missing_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=call_quintile_year; BY agencyID yearnum; RUN;
PROC SORT DATA=state_count_year; BY agencyID yearnum; RUN;
PROC SORT DATA=county_count_year; BY agencyID yearnum; RUN;

DATA nemsis.poisson_all;
	MERGE 
		/*midazolam*/ midaz_count_year
		/*benzodiazepines*/ benzo_count_year 
		/*Age*/ agecat_1_count_year agecat_2_count_year agecat_3_count_year agecat_4_count_year agecat_5_count_year agecat_6_count_year agecat_missing_count_year
		/*Gender*/Male_count_year female_count_year gender_missing_count_year
		/*Race*/white_count_year black_count_year race_other_count_year race_missing_count_year
		/*Ethnicity*/Hispanic_count_year Not_Hispanic_count_year ethnicity_missing_count_year
		/*Region*/Island_count_year Midwest_count_year Northeast_count_year South_count_year West_count_year Region_missing_count_year
		/*Urbanicity*/Rural_count_year Suburban_count_year Urban_count_year Wilderness_count_year Urbanicity_missing_count_year
		/*Service level*/BLS_count_year ALS_count_year Air_count_year service_level_other_count_year service_level_missing_count_year
		/*primary role*/transport_count_year role_other_count_year role_missing_count_year
		/*service type*/response_count_year transfer_count_year service_type_other_count_year service_type_missing_count_year
		/*size*/ call_quintile_year		
		/*states*/ state_count_year
		/*counties*/ county_count_year;
	BY agencyID yearnum;
RUN;

DATA nemsis.poisson_all_zero;
	SET nemsis.poisson_all;
	IF midaz = . THEN midaz = 0;
	IF benzos = . THEN benzos = 0;
	IF agecat_1 = . THEN agecat_1 = 0;
	IF agecat_2 = . THEN agecat_2 = 0;
	IF agecat_3 = . THEN agecat_3 = 0;
	IF agecat_4 = . THEN agecat_4 = 0;
	IF agecat_5 = . THEN agecat_5 = 0;
	IF agecat_6 = . THEN agecat_6 = 0;
	IF agecat_missing = . THEN agecat_missing = 0;
	IF male = . THEN male = 0;
	IF female = . THEN female = 0;
	IF gender_missing = . THEN gender_missing = 0;
	IF white = . THEN white = 0;
	IF black = . THEN black = 0;
	IF race_other = . THEN race_other = 0;
	IF race_missing = . THEN race_missing = 0;
	IF hispanic = . THEN hispanic = 0;
	IF not_hispanic = . THEN not_hispanic = 0;
	IF ethnicity_missing = . THEN ethnicity_missing = 0;
	IF island = . THEN island = 0;
	IF midwest = . THEN midwest = 0;
	IF northeast = . THEN northeast = 0;
	IF south = . THEN south = 0;
	IF west = . THEN west = 0;
	IF region_missing = . THEN region_missing = 0;
	IF rural = . THEN rural = 0;
	IF suburban = . THEN suburban = 0;
	IF urban = . THEN urban = 0;
	IF wilderness = . THEN wilderness = 0;
	IF urbanicity_missing = . THEN urbanicity_missing = 0;
	IF BLS = . THEN BLS = 0;
	IF ALS = . THEN ALS = 0;
	IF Air = . THEN air = 0;
	IF service_level_other = . THEN service_level_other = 0;
	IF service_level_missing = . THEN service_level_missing = 0;
	IF transport = . THEN transport = 0;
	IF role_other = . THEN role_other = 0;
	IF role_missing = . THEN role_missing = 0;
	IF response = . THEN response = 0;
	IF transfer = . THEN transfer = 0;
	IF service_type_other = . THEN service_type_other = 0;
	IF service_type_missing = . THEN service_type_missing = 0;
	IF calls = . THEN calls = 0;
	IF size_quintile = . THEN size_quintile = 0;
	IF states = . THEN states = 0;
	IF counties = . THEN counties = 0;
RUN;

******************************************************************************************
Modifying Poisson table to actual proportions for multiple linear regression
*****************************************************************************************;

DATA poisson_linear;
	SET nemsis.poisson_all_zero;
	IF benzos NE 0;
	midaz_prop = (midaz/benzos);
	agecat_1_prop = (agecat_1/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_2_prop = (agecat_2/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_3_prop = (agecat_3/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_4_prop = (agecat_4/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_5_prop = (agecat_5/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_6_prop = (agecat_6/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_missing_prop = (agecat_missing/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6 + agecat_missing));
	male_prop = (male/(male + female));
	female_prop = (female/(male + female));
	gender_missing_prop = (gender_missing/(male + female + gender_missing));
	White_prop = (white/(white + black + race_other));
	black_prop = (black/(white + black + race_other));
	race_other_prop = (race_other/(white + black + race_other));
	race_missing_prop = (race_missing/(white + black + race_other + race_missing));
	hispanic_prop = (hispanic/(hispanic + not_hispanic));
	Not_hispanic_prop = (not_hispanic/(hispanic + not_hispanic));
	ethnicity_missing_prop = (ethnicity_missing/(hispanic + not_hispanic + ethnicity_missing));
	Island_prop = (Island/(Island + Midwest + Northeast + south + west));
	Midwest_prop = (Midwest/(Island + Midwest + Northeast + south + west));
	Northeast_prop = (Northeast/(Island + Midwest + Northeast + south + west));
	South_prop = (South/(Island + Midwest + Northeast + south + west));
	West_prop = (West/(Island + Midwest + Northeast + south + west));
	region_missing_prop = (region_missing/(Island + Midwest + Northeast + south + west + region_missing));
	Rural_prop = (Rural/(Rural + Suburban + Urban + Wilderness));
	suburban_prop = (suburban/(Rural + Suburban + Urban + Wilderness));
	urban_prop = (urban/(Rural + Suburban + Urban + Wilderness));
	wilderness_prop = (wilderness/(Rural + Suburban + Urban + Wilderness));
	urbanicity_missing_prop = (urbanicity_missing/(Rural + Suburban + Urban + Wilderness + urbanicity_missing));
	BLS_prop = (BLS/(BLS + ALS + Air + service_level_other));
	ALS_prop = (ALS/(BLS + ALS + Air + service_level_other));
	Air_prop = (Air/(BLS + ALS + Air + service_level_other));
	service_level_other_prop = (service_level_other/(BLS + ALS + Air + service_level_other));
	service_level_missing_prop = (service_level_missing/(BLS + ALS + Air + service_level_other + service_level_missing));
	transport_prop = (transport/(transport + role_other));
	role_other_prop = (role_other/(transport + role_other));
	role_missing_prop = (role_missing/(transport + role_other + role_missing));
	response_prop = (response/(response + transfer + service_type_other));
	transfer_prop = (transfer/(response + transfer + service_type_other));
	service_type_other_prop = (service_type_other/(response + transfer + service_type_other));
	service_type_missing_prop = (service_type_missing/(response + transfer + service_type_other + service_type_missing));
RUN;

*confirming appropriate creation of proportion variables;
DATA proportions_test;
	SET poisson_linear;
	age_test = sum(agecat_1_prop + agecat_2_prop + agecat_3_prop + agecat_4_prop + agecat_5_prop + agecat_6_prop);
	gender_test = sum(male_prop + female_prop);
	Race_test = sum(white_prop + black_prop + race_other_prop);
	ethnicity_test = sum(hispanic_prop + not_hispanic_prop);
	region_test = sum(island_prop + midwest_prop + northeast_prop + south_prop + west_prop);
	Urbanicity_test = sum(rural_prop + suburban_prop + urban_prop + wilderness_prop);
	Service_level_test = sum(bls_prop + als_prop + air_prop + service_level_other_prop);
	role_test = sum(transport_prop + role_other_prop);
	service_type_test = sum(response_prop + transfer_prop + service_type_other_prop);
RUN;

*reducing dataset to relavant variables;
DATA nemsis.poisson_linear;
	SET poisson_linear;
	KEEP agencyID yearnum benzos midaz_prop 
		agecat_1_prop agecat_2_prop agecat_3_prop agecat_4_prop agecat_5_prop agecat_6_prop agecat_missing_prop
		male_prop female_prop gender_missing_prop
		white_prop black_prop race_other_prop race_missing_prop
		hispanic_prop not_hispanic_prop ethnicity_missing_prop
		island_prop midwest_prop northeast_prop south_prop west_prop region_missing_prop
		rural_prop suburban_prop urban_prop wilderness_prop urbanicity_missing_prop
		bls_prop als_prop air_prop service_level_other_prop service_level_missing_prop
		transport_prop role_other_prop role_missing_prop
		response_prop transfer_prop service_type_other_prop service_type_missing_prop
		calls size_quintile states counties;
RUN;


**************************** Preparing table for analysis**************************;


*transforming variables so that an increase in 1 (for linear regression) = an absolute increase in the proportion of 10%;
	*benzos, states and counties are actual numbers
	anything ending in _prop is an untransformed proportion of the total number
	anythign ending in _transf was multiplied by 10, so an increae in 1 = 10% absolute increase
		unless it ends with transf_20, which was multiplied by 20, so an increase in 1 = 5% (since baseline % is >90%)
	calls_transf_decr_1000 was divided by 1000 so an increase in 1 = increase in 1000 calls/year;

DATA nemsis.poisson_linear_transformed;
	SET nemsis.poisson_linear;
	agecat_1_transf = 10* agecat_1_prop;
	agecat_2_transf = 10* agecat_2_prop;
	agecat_3_transf = 10* agecat_3_prop;
	agecat_4_transf = 10* agecat_4_prop;
	agecat_5_transf = 10* agecat_5_prop;
	agecat_6_transf = 10* agecat_6_prop;
	male_transf = 10* male_prop;
	female_transf = 10* female_prop;
	white_transf = 10* white_prop;
	black_transf = 10* black_prop;
	race_other_transf = 10* race_other_prop;
	hispanic_transf = 10* hispanic_prop;
	not_hispanic_transf = 10* not_hispanic_prop;
	Island_transf = 10* Island_prop;
	Midwest_transf = 10* Midwest_prop;
	Northeast_transf = 10* Northeast_prop;
	South_transf = 10* South_prop;
	West_transf = 10* West_prop;
	urban_transf = 10* urban_prop;
	suburban_transf = 10* suburban_prop;
	rural_transf = 10* rural_prop;
	wilderness_transf = 10* wilderness_prop;
	BLS_transf = 10* BLS_prop;
	ALS_transf = 10* ALS_prop;
	Air_transf = 10* Air_prop;
	service_level_other_transf = 10* service_level_other_prop;
	transport_transf_20 = 20* transport_prop;
	role_other_transf = 10* role_other_prop;
	response_transf_20 = 20* response_prop;
	transfer_transf = 10* transfer_prop;
	service_type_other_transf = 10* service_type_other_prop;
	calls_transf_decr_1000 = calls/1000;
	KEEP agencyID yearnum benzos midaz_prop 
		agecat_1_transf agecat_2_transf agecat_3_transf agecat_4_transf agecat_5_transf agecat_6_transf agecat_missing_prop
		male_transf female_transf gender_missing_prop
		white_transf black_transf race_other_transf race_missing_prop
		hispanic_transf not_hispanic_transf ethnicity_missing_prop
		island_transf midwest_transf northeast_transf south_transf west_transf region_missing_prop
		rural_transf suburban_transf urban_transf wilderness_transf urbanicity_missing_prop
		bls_transf als_transf air_transf service_level_other_transf service_level_missing_prop
		transport_transf_20 role_other_transf role_missing_prop
		response_transf_20 transfer_transf service_type_other_transf service_type_missing_prop
		calls_transf_decr_1000 size_quintile states counties;
RUN;

*creating a combined varaible for peds >5 yo (age categories 2 and 3);
DATA nemsis.poisson_linear_transformed;
	SET nemsis.poisson_linear_transformed;
	age_6_20 = (agecat_2_transf + agecat_3_transf);
RUN;


*distribution of proportions;
PROC UNIVARIATE DATA=nemsis.poisson_linear plots normal;
	VAR 
		agecat_1_prop agecat_2_prop agecat_3_prop agecat_6_prop 
		male_prop female_prop 
		white_prop black_prop race_other_prop 
		hispanic_prop not_hispanic_prop 
		island_prop midwest_prop northeast_prop south_prop west_prop 
		rural_prop suburban_prop urban_prop wilderness_prop 
		bls_prop als_prop air_prop service_level_other_prop 
		transport_prop role_other_prop 
		response_prop transfer_prop service_type_other_prop;
RUN;

*making categorical variable for midazolam proportion;
DATA nemsis.poisson_linear_transformed;
	SET nemsis.poisson_linear_transformed;
	IF midaz_prop = 0 THEN Midaz_cat = 0;
	ELSE IF 0<midaz_prop<0.5 THEN midaz_cat = 1;
	ELSE IF 0.5<=midaz_prop<1 THEN midaz_cat = 2;
	ELSE IF midaz_prop = 1 THEN midaz_cat = 3;
RUN;
PROC FREQ DATA=nemsis.poisson_linear_transformed;
	TABLE midaz_cat*yearnum / norow nopercent;
RUN;
*creating variable for maximum service level agency provides;
DATA nemsis.poisson_linear_transformed;
	SET nemsis.poisson_linear_transformed;
	IF BLS_transf >0 and ALS_transf = 0 and Air_transf = 0 THEN service_level_max = 0;
	ELSE IF ALS_transf > 0 and Air_transf = 0 THEN service_level_max = 1;
	ELSE IF Air_transf > 0 THEN service_level_max = 2;
	ELSE IF service_level_other_transf >0 and BLS_transf = 0 and ALS_transf = 0 and Air_transf = 0 THEN service_level_max = 3;
RUN;
PROC FREQ DATA=nemsis.poisson_linear_transformed;
	TABLE service_level_max / norow nopercent;
RUN;
*confirming that 2752 should be missing;
PROC FREQ DATA=nemsis.poisson_linear_transformed;
	TABLE service_level_missing_prop / norow nopercent;
	WHERE service_level_missing_prop = 1;
RUN;

*creating variable for agency's ability to provide transport services;
DATA nemsis.poisson_linear_transformed;
	SET nemsis.poisson_linear_transformed;
	IF transport_transf_20 > 0 THEN transport = 1;
	ELSE IF transport_transf_20 = 0 THEN transport = 0;
RUN;
PROC FREQ DATA=nemsis.poisson_linear_transformed;
	TABLE transport;
RUN;

*creating variable for agency's service type;
DATA nemsis.poisson_linear_transformed;
	SET nemsis.poisson_linear_transformed;
	IF transfer_transf = 10 THEN service_type = 0;
	ELSE IF response_transf_20 = 20 THEN service_type = 1;
	ELSE IF service_type_other_transf = 10 THEN service_type = 2;
	ELSE IF transfer_transf<10 and response_transf_20<20 and service_type_other_transf<10 THEN service_type = 3;
RUN;
PROC FREQ DATA=nemsis.poisson_linear_transformed;
	TABLE service_type;
RUN;

*making variable for scene response (no, some, most, only);
DATA nemsis.poisson_linear_transformed;
	SET nemsis.poisson_linear_transformed;
	IF response_transf_20 = 0 THEN response = 0;
	ELSE IF response_transf_20 > 0 THEN response = 1;
RUN;
PROC FREQ DATA=nemsis.poisson_linear_transformed;
	TABLE response;
RUN;


*making variable for urbanicity (defined by >95% of calls in one ubanicity;
DATA nemsis.poisson_linear_transformed;
	SET nemsis.poisson_linear_transformed;
	IF urban_transf > 9.5  THEN urbanicity = 0;
	ELSE IF suburban_transf > 9.5 THEN urbanicity = 1;
	ELSE IF rural_transf > 9.5 THEN urbanicity = 2;
	ELSE IF wilderness_transf > 9.5 THEN urbanicity = 3;
	ELSE IF urban_transf <= 9.5 and suburban_transf <= 9.5 and rural_transf <= 9.5 and wilderness_transf <= 9.5 THEN urbanicity = 4;
RUN;
PROC FREQ DATA=nemsis.poisson_linear_transformed;
	TABLE urbanicity;
RUN;


***************************************************************************************************
Creating the same dataset without classifying BY yearnum, to use for hierarchical regression etc.
***************************************************************************************************;

*outcome variables: proportion of midaz/benzos used to treat seizures;
	*Count of Midazolam use by AgencyID;
PROC SORT DATA=nemsis.complete; BY agencyID; RUN;
PROC FREQ DATA=nemsis.complete NOPRINT;
	TABLE midazolam / out=midaz_count;
	BY agencyID;
RUN;
DATA midaz_count;
	SET midaz_count;
	WHERE midazolam = 1;
	midaz = count;
	KEEP agencyID midaz;
RUN;
*count of benzodiazepine use by AgencyID and year;
PROC SORT DATA=nemsis.complete; BY agencyID; RUN;
PROC MEANS DATA=nemsis.complete NOPRINT;
	VAR midazolam;
	BY agencyID;
	OUTPUT OUT=benzo_count n (midazolam) = count;
RUN;
DATA benzo_count;
	SET benzo_count;
	benzos = _freq_;
	KEEP agencyID benzos;
RUN;

*count of age categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE agecat / out=age_count;
	BY agencyID;
RUN;
DATA agecat_1_count;
	SET age_count;
	IF agecat = 1;
	agecat_1 = count;
	KEEP agencyID agecat_1;
RUN;
DATA agecat_2_count;
	SET age_count;
	IF agecat = 2;
	agecat_2 = count;
	KEEP agencyID agecat_2;
RUN;
DATA agecat_3_count;
	SET age_count;
	IF agecat = 3;
	agecat_3 = count;
	KEEP agencyID agecat_3;
RUN;
DATA agecat_4_count;
	SET age_count;
	IF agecat = 4;
	agecat_4 = count;
	KEEP agencyID agecat_4;
RUN;
DATA agecat_5_count;
	SET age_count;
	IF agecat = 5;
	agecat_5 = count;
	KEEP agencyID agecat_5;
RUN;
DATA agecat_6_count;
	SET age_count;
	IF agecat = 6;
	agecat_6 = count;
	KEEP agencyID agecat_6;
RUN;
DATA agecat_missing_count;
	SET age_count;
	IF agecat = .;
	agecat_missing = count;
	KEEP agencyID agecat_missing;
RUN;

*count of gender categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE E06_11new / out=gender_count;
	BY agencyID;
RUN;
DATA Male_count;
	SET gender_count;
	IF E06_11new = 650;
	male = count;
	KEEP agencyID male;
RUN;
DATA Female_count;
	SET gender_count;
	IF E06_11new = 655;
	female = count;
	KEEP agencyID female;
RUN;
DATA Gender_missing_count;
	SET gender_count;
	IF E06_11new = .;
	gender_missing = count;
	KEEP agencyID gender_missing;
RUN;

*count of race categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE race / out=race_count;
	BY agencyID;
RUN;
DATA White_count;
	SET race_count;
	IF race = 0;
	White = count;
	KEEP agencyID white;
RUN;
DATA Black_count;
	SET race_count;
	IF race = 1;
	black = count;
	KEEP agencyID black;
RUN;
DATA Race_other_count;
	SET race_count;
	IF race = 2;
	race_other = count;
	KEEP agencyID race_other;
RUN;
DATA Race_missing_count;
	SET race_count;
	IF race = .;
	race_missing = count;
	KEEP agencyID race_missing;
RUN;

*count of ethnicity categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE E06_13new / out=ethnicity_count;
	BY agencyID;
RUN;
DATA Hispanic_count;
	SET ethnicity_count;
	IF E06_13new = 690;
	Hispanic = count;
	KEEP agencyID Hispanic;
RUN;
DATA Not_Hispanic_count;
	SET ethnicity_count;
	IF E06_13new = 695;
	Not_Hispanic = count;
	KEEP agencyID Not_Hispanic;
RUN;
DATA ethnicity_missing_count;
	SET ethnicity_count;
	IF E06_13new = .;
	ethnicity_missing = count;
	KEEP agencyID ethnicity_missing;
RUN;

*count of census region categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE USCensusRegion / out=region_count;
	BY agencyID;
RUN;
DATA Island_count;
	SET region_count;
	IF USCensusRegion = "Island Areas";
	Island = count;
	KEEP agencyID Island;
RUN;
DATA Midwest_count;
	SET region_count;
	IF USCensusRegion = "Midwest";
	Midwest = count;
	KEEP agencyID Midwest;
RUN;
DATA Northeast_count;
	SET region_count;
	IF USCensusRegion = "Northeast";
	Northeast = count;
	KEEP agencyID Northeast;
RUN;
DATA South_count;
	SET region_count;
	IF USCensusRegion = "South";
	South = count;
	KEEP agencyID South;
RUN;
DATA West_count;
	SET region_count;
	IF USCensusRegion = "West";
	West = count;
	KEEP agencyID West;
RUN;
DATA region_missing_count;
	SET region_count;
	IF USCensusRegion NE "Midwest" and USCensusRegion NE "Northeast" and USCensusRegion NE "West" and USCensusRegion NE "South" and USCensusRegion NE "Island Areas";
	region_missing = count;
	KEEP agencyID region_missing;
RUN;

*count of urbanicity categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE urbanicity / out=urbanicity_count;
	BY agencyID;
RUN;
DATA Rural_count;
	SET urbanicity_count;
	IF urbanicity = "Rural";
	Rural = count;
	KEEP agencyID Rural;
RUN;
DATA Suburban_count;
	SET urbanicity_count;
	IF urbanicity = "Suburban";
	Suburban = count;
	KEEP agencyID Suburban;
RUN;
DATA Urban_count;
	SET urbanicity_count;
	IF urbanicity = "Urban";
	Urban = count;
	KEEP agencyID Urban;
RUN;
DATA Wilderness_count;
	SET urbanicity_count;
	IF urbanicity = "Wilderness";
	Wilderness = count;
	KEEP agencyID Wilderness;
RUN;
DATA urbanicity_missing_count;
	SET urbanicity_count;
	IF urbanicity NE "Rural" and urbanicity NE "Suburban" and urbanicity NE "Urban" and urbanicity NE "Wilderness";
	urbanicity_missing = count;
	KEEP agencyID urbanicity_missing;
RUN;

*count of service level categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE service_level / out=service_level_count;
	BY agencyID;
RUN;
DATA BLS_count;
	SET service_level_count;
	IF service_level = 0;
	BLS = count;
	KEEP agencyID BLS;
RUN;
DATA ALS_count;
	SET service_level_count;
	IF service_level = 1;
	ALS = count;
	KEEP agencyID ALS;
RUN;
DATA Air_count;
	SET service_level_count;
	IF service_level = 2;
	Air = count;
	KEEP agencyID Air;
RUN;
DATA service_level_other_count;
	SET service_level_count;
	IF service_level = 3;
	service_level_other = count;
	KEEP agencyID service_level_other;
RUN;
DATA service_level_missing_count;
	SET service_level_count;
	IF service_level = .;
	service_level_missing = count;
	KEEP agencyID service_level_missing;
RUN;

*count of primary role categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE primary_role / out=primary_role_count;
	BY agencyID;
RUN;
DATA transport_count;
	SET primary_role_count;
	IF primary_role = 1;
	transport = count;
	KEEP agencyID transport;
RUN;
DATA role_other_count;
	SET primary_role_count;
	IF primary_role = 0;
	role_other = count;
	KEEP agencyID role_other;
RUN;
DATA role_missing_count;
	SET primary_role_count;
	IF primary_role = .;
	role_missing = count;
	KEEP agencyID role_missing;
RUN;

*count of service type categories by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE type_service / out=type_service_count;
	BY agencyID;
RUN;
DATA response_count;
	SET type_service_count;
	IF type_service = 1;
	response = count;
	KEEP agencyID response;
RUN;
DATA transfer_count;
	SET type_service_count;
	IF type_service = 2;
	transfer = count;
	KEEP agencyID transfer;
RUN;
DATA service_type_other_count;
	SET type_service_count;
	IF type_service = 0;
	service_type_other = count;
	KEEP agencyID service_type_other;
RUN;
DATA service_type_missing_count;
	SET type_service_count;
	IF type_service = .;
	service_type_missing = count;
	KEEP agencyID service_type_missing;
RUN;

*average annual call volume;
DATA call_count;
	SET nemsis.agency_wide;
	KEEP agencyID avg_callvol;
RUN;

*size quintiles;
PROC RANK DATA=call_count OUT=call_quintile GROUPS=5;
	VAR avg_callvol;
	RANKS size_quintile;
	LABEL size_quintile = "call Size Quintile";
RUN;

*count of number of counties by agencyID and year;
PROC SORT DATA=nemsis.agency_events_all_intermediate; BY agencyID; RUN;
PROC FREQ DATA=nemsis.agency_events_all_intermediate NOPRINT;
	TABLE agencycounty / out=agency_county_count;
	BY agencyID;
RUN;
PROC SORT DATA=agency_county_count; BY agencyID; RUN;
PROC FREQ DATA=agency_county_count NOPRINT;
	TABLE agencyID / out=agency_county_count_2;
	BY agencyID;
RUN;
DATA county_count;
	SET agency_county_count_2;
	counties = count;
	KEEP agencyID counties;
RUN;

*creating poisson dataset by merging base datasets;
PROC SORT DATA=midaz_count; BY agencyID; RUN;
PROC SORT DATA=benzo_count; BY agencyID; RUN;
PROC SORT DATA=agecat_1_count; BY agencyID; RUN;
PROC SORT DATA=agecat_2_count; BY agencyID; RUN;
PROC SORT DATA=agecat_3_count; BY agencyID; RUN;
PROC SORT DATA=agecat_4_count; BY agencyID; RUN;
PROC SORT DATA=agecat_5_count; BY agencyID; RUN;
PROC SORT DATA=agecat_6_count; BY agencyID; RUN;
PROC SORT DATA=agecat_missing_count; BY agencyID; RUN;
PROC SORT DATA=male_count; BY agencyID; RUN;
PROC SORT DATA=female_count; BY agencyID; RUN;
PROC SORT DATA=gender_missing_count; BY agencyID; RUN;
PROC SORT DATA=white_count; BY agencyID; RUN;
PROC SORT DATA=black_count; BY agencyID; RUN;
PROC SORT DATA=race_other_count; BY agencyID; RUN;
PROC SORT DATA=race_missing_count; BY agencyID; RUN;
PROC SORT DATA=hispanic_count; BY agencyID; RUN;
PROC SORT DATA=not_hispanic_count; BY agencyID; RUN;
PROC SORT DATA=ethnicity_missing_count; BY agencyID; RUN;
PROC SORT DATA=island_count; BY agencyID; RUN;
PROC SORT DATA=midwest_count; BY agencyID; RUN;
PROC SORT DATA=northeast_count; BY agencyID; RUN;
PROC SORT DATA=south_count; BY agencyID; RUN;
PROC SORT DATA=west_count; BY agencyID; RUN;
PROC SORT DATA=region_missing_count; BY agencyID; RUN;
PROC SORT DATA=rural_count; BY agencyID; RUN;
PROC SORT DATA=suburban_count; BY agencyID; RUN;
PROC SORT DATA=urban_count; BY agencyID; RUN;
PROC SORT DATA=wilderness_count; BY agencyID; RUN;
PROC SORT DATA=urbanicity_missing_count; BY agencyID; RUN;
PROC SORT DATA=bls_count; BY agencyID; RUN;
PROC SORT DATA=als_count; BY agencyID; RUN;
PROC SORT DATA=air_count; BY agencyID; RUN;
PROC SORT DATA=service_level_other_count; BY agencyID; RUN;
PROC SORT DATA=service_level_missing_count; BY agencyID; RUN;
PROC SORT DATA=transport_count; BY agencyID; RUN;
PROC SORT DATA=role_other_count; BY agencyID; RUN;
PROC SORT DATA=role_missing_count; BY agencyID; RUN;
PROC SORT DATA=response_count; BY agencyID; RUN;
PROC SORT DATA=transfer_count; BY agencyID; RUN;
PROC SORT DATA=service_type_other_count; BY agencyID; RUN;
PROC SORT DATA=service_type_missing_count; BY agencyID; RUN;
PROC SORT DATA=call_quintile; BY agencyID; RUN;
PROC SORT DATA=county_count; BY agencyID; RUN;

DATA nemsis.count_all;
	MERGE 
		/*midazolam*/ midaz_count
		/*benzodiazepines*/ benzo_count 
		/*Age*/ agecat_1_count agecat_2_count agecat_3_count agecat_4_count agecat_5_count agecat_6_count agecat_missing_count
		/*Gender*/Male_count female_count gender_missing_count
		/*Race*/white_count black_count race_other_count race_missing_count
		/*Ethnicity*/Hispanic_count Not_Hispanic_count ethnicity_missing_count
		/*Region*/Island_count Midwest_count Northeast_count South_count West_count Region_missing_count
		/*Urbanicity*/Rural_count Suburban_count Urban_count Wilderness_count Urbanicity_missing_count
		/*Service level*/BLS_count ALS_count Air_count service_level_other_count service_level_missing_count
		/*primary role*/transport_count role_other_count role_missing_count
		/*service type*/response_count transfer_count service_type_other_count service_type_missing_count
		/*size*/ call_quintile		
		/*counties*/ county_count;
	BY agencyID;
RUN;

DATA nemsis.count_all_zero;
	SET nemsis.count_all;
	IF midaz = . THEN midaz = 0;
	IF benzos = . THEN benzos = 0;
	IF agecat_1 = . THEN agecat_1 = 0;
	IF agecat_2 = . THEN agecat_2 = 0;
	IF agecat_3 = . THEN agecat_3 = 0;
	IF agecat_4 = . THEN agecat_4 = 0;
	IF agecat_5 = . THEN agecat_5 = 0;
	IF agecat_6 = . THEN agecat_6 = 0;
	IF agecat_missing = . THEN agecat_missing = 0;
	IF male = . THEN male = 0;
	IF female = . THEN female = 0;
	IF gender_missing = . THEN gender_missing = 0;
	IF white = . THEN white = 0;
	IF black = . THEN black = 0;
	IF race_other = . THEN race_other = 0;
	IF race_missing = . THEN race_missing = 0;
	IF hispanic = . THEN hispanic = 0;
	IF not_hispanic = . THEN not_hispanic = 0;
	IF ethnicity_missing = . THEN ethnicity_missing = 0;
	IF island = . THEN island = 0;
	IF midwest = . THEN midwest = 0;
	IF northeast = . THEN northeast = 0;
	IF south = . THEN south = 0;
	IF west = . THEN west = 0;
	IF region_missing = . THEN region_missing = 0;
	IF rural = . THEN rural = 0;
	IF suburban = . THEN suburban = 0;
	IF urban = . THEN urban = 0;
	IF wilderness = . THEN wilderness = 0;
	IF urbanicity_missing = . THEN urbanicity_missing = 0;
	IF BLS = . THEN BLS = 0;
	IF ALS = . THEN ALS = 0;
	IF Air = . THEN air = 0;
	IF service_level_other = . THEN service_level_other = 0;
	IF service_level_missing = . THEN service_level_missing = 0;
	IF transport = . THEN transport = 0;
	IF role_other = . THEN role_other = 0;
	IF role_missing = . THEN role_missing = 0;
	IF response = . THEN response = 0;
	IF transfer = . THEN transfer = 0;
	IF service_type_other = . THEN service_type_other = 0;
	IF service_type_missing = . THEN service_type_missing = 0;
	IF calls = . THEN calls = 0;
	IF size_quintile = . THEN size_quintile = 0;
	IF counties = . THEN counties = 0;
	WHERE benzos>0;
RUN;

DATA proportions_all;
	SET nemsis.count_all_zero;
	IF benzos NE 0;
	midaz_prop = (midaz/benzos);
	agecat_1_prop = (agecat_1/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_2_prop = (agecat_2/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_3_prop = (agecat_3/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_4_prop = (agecat_4/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_5_prop = (agecat_5/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_6_prop = (agecat_6/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6));
	agecat_missing_prop = (agecat_missing/(agecat_1 + agecat_2 + agecat_3 + agecat_4 + agecat_5 + agecat_6 + agecat_missing));
	male_prop = (male/(male + female));
	female_prop = (female/(male + female));
	gender_missing_prop = (gender_missing/(male + female + gender_missing));
	White_prop = (white/(white + black + race_other));
	black_prop = (black/(white + black + race_other));
	race_other_prop = (race_other/(white + black + race_other));
	race_missing_prop = (race_missing/(white + black + race_other + race_missing));
	hispanic_prop = (hispanic/(hispanic + not_hispanic));
	Not_hispanic_prop = (not_hispanic/(hispanic + not_hispanic));
	ethnicity_missing_prop = (ethnicity_missing/(hispanic + not_hispanic + ethnicity_missing));
	Island_prop = (Island/(Island + Midwest + Northeast + south + west));
	Midwest_prop = (Midwest/(Island + Midwest + Northeast + south + west));
	Northeast_prop = (Northeast/(Island + Midwest + Northeast + south + west));
	South_prop = (South/(Island + Midwest + Northeast + south + west));
	West_prop = (West/(Island + Midwest + Northeast + south + west));
	region_missing_prop = (region_missing/(Island + Midwest + Northeast + south + west + region_missing));
	Rural_prop = (Rural/(Rural + Suburban + Urban + Wilderness));
	suburban_prop = (suburban/(Rural + Suburban + Urban + Wilderness));
	urban_prop = (urban/(Rural + Suburban + Urban + Wilderness));
	wilderness_prop = (wilderness/(Rural + Suburban + Urban + Wilderness));
	urbanicity_missing_prop = (urbanicity_missing/(Rural + Suburban + Urban + Wilderness + urbanicity_missing));
	BLS_prop = (BLS/(BLS + ALS + Air + service_level_other));
	ALS_prop = (ALS/(BLS + ALS + Air + service_level_other));
	Air_prop = (Air/(BLS + ALS + Air + service_level_other));
	service_level_other_prop = (service_level_other/(BLS + ALS + Air + service_level_other));
	service_level_missing_prop = (service_level_missing/(BLS + ALS + Air + service_level_other + service_level_missing));
	transport_prop = (transport/(transport + role_other));
	role_other_prop = (role_other/(transport + role_other));
	role_missing_prop = (role_missing/(transport + role_other + role_missing));
	response_prop = (response/(response + transfer + service_type_other));
	transfer_prop = (transfer/(response + transfer + service_type_other));
	service_type_other_prop = (service_type_other/(response + transfer + service_type_other));
	service_type_missing_prop = (service_type_missing/(response + transfer + service_type_other + service_type_missing));
RUN;

*confirming appropriate creation of proportion variables;
DATA proportions_test;
	SET proportions_all;
	age_test = sum(agecat_1_prop + agecat_2_prop + agecat_3_prop + agecat_4_prop + agecat_5_prop + agecat_6_prop);
	gender_test = sum(male_prop + female_prop);
	Race_test = sum(white_prop + black_prop + race_other_prop);
	ethnicity_test = sum(hispanic_prop + not_hispanic_prop);
	region_test = sum(island_prop + midwest_prop + northeast_prop + south_prop + west_prop);
	Urbanicity_test = sum(rural_prop + suburban_prop + urban_prop + wilderness_prop);
	Service_level_test = sum(bls_prop + als_prop + air_prop + service_level_other_prop);
	role_test = sum(transport_prop + role_other_prop);
	service_type_test = sum(response_prop + transfer_prop + service_type_other_prop);
RUN;

*reducing dataset to relavant variables;
DATA nemsis.proportions_all;
	SET proportions_all;
	KEEP agencyID benzos midaz_prop 
		agecat_1_prop agecat_2_prop agecat_3_prop agecat_4_prop agecat_5_prop agecat_6_prop agecat_missing_prop
		male_prop female_prop gender_missing_prop
		white_prop black_prop race_other_prop race_missing_prop
		hispanic_prop not_hispanic_prop ethnicity_missing_prop
		island_prop midwest_prop northeast_prop south_prop west_prop region_missing_prop
		rural_prop suburban_prop urban_prop wilderness_prop urbanicity_missing_prop
		bls_prop als_prop air_prop service_level_other_prop service_level_missing_prop
		transport_prop role_other_prop role_missing_prop
		response_prop transfer_prop service_type_other_prop service_type_missing_prop
		calls size_quintile counties;
RUN;


*outputting regression coefficients for agencies' unadjusted change in midazolam per yaer 
to put back into a multinomial regression of odds of changing midazolam use X amount;
PROC SORT DATA=nemsis.poisson_linear_transformed; BY agencyID; RUN;
PROC REG  DATA=nemsis.poisson_linear_transformed noprint outest=reg_test;
	MODEL midaz_prop = yearnum;
	BY agencyID;
RUN;
DATA nemsis.midaz_reg_by_agency;
	SET reg_test;
	change_per_year = yearnum;
	KEEP agencyID change_per_year;
RUN;

*merging datasets to allow multivariate model of actual change in midazolam use;
DATA nemsis.midaz_change;
	MERGE nemsis.midaz_reg_by_agency nemsis.agency_wide nemsis.proportions_all;
	KEEP agencyID change_per_year agency_complete sum_calls avg_callvol years_rep years_sz_rep
		benzos midaz_prop 
		agecat_1_prop agecat_2_prop agecat_3_prop agecat_4_prop agecat_5_prop agecat_6_prop agecat_missing_prop
		male_prop female_prop gender_missing_prop
		white_prop black_prop race_other_prop race_missing_prop
		hispanic_prop not_hispanic_prop ethnicity_missing_prop
		island_prop midwest_prop northeast_prop south_prop west_prop region_missing_prop
		rural_prop suburban_prop urban_prop wilderness_prop urbanicity_missing_prop
		bls_prop als_prop air_prop service_level_other_prop service_level_missing_prop
		transport_prop role_other_prop role_missing_prop
		response_prop transfer_prop service_type_other_prop service_type_missing_prop
		calls size_quintile counties;
RUN;

*****creating variables for the multinomial model*****;

*distribution of change in midazolam;
PROC UNIVARIATE DATA=nemsis.midaz_change plots normal;
	VAR change_per_year;
	WHERE years_sz_rep >1;
RUN;

*creating variable for categories of change in midazolam;
DATA nemsis.midaz_change;
	SET nemsis.midaz_change;
	IF change_per_year = 0 THEN midaz_cat = 0;
	ELSE IF change_per_year < 0 THEN midaz_cat = 1;
	ELSE IF 0<change_per_year <0.5 THEN midaz_cat = 2;
	ELSE IF 0.5<=change_per_year<1 THEN midaz_cat = 3;
	ELSE IF change_per_year =1 THEN midaz_cat = 4;
RUN;
PROC FREQ DATA=nemsis.midaz_change;
	TABLE midaz_cat;
	WHERE years_sz_rep >1;
RUN;

*creating a combined varaible for peds >5 yo (age categories 2 and 3);
DATA nemsis.midaz_change;
	SET nemsis.midaz_change;
	age_6_20 = (agecat_2_prop + agecat_3_prop);
RUN;

*creating variable for maximum service level agency provides;
DATA nemsis.midaz_change;
	SET nemsis.midaz_change;
	IF BLS_prop >0 and ALS_prop = 0 and Air_prop = 0 THEN service_level_max = 0;
	ELSE IF ALS_prop > 0 and Air_prop = 0 THEN service_level_max = 1;
	ELSE IF Air_prop > 0 THEN service_level_max = 2;
	ELSE IF service_level_other_prop >0 and BLS_prop = 0 and ALS_prop = 0 and Air_prop = 0 THEN service_level_max = 3;
RUN;
PROC FREQ DATA=nemsis.midaz_change;
	TABLE service_level_max / norow nopercent;
RUN;
*confirming that 715 should be missing;
PROC FREQ DATA=nemsis.midaz_change;
	TABLE service_level_missing_prop / norow nopercent;
	WHERE service_level_missing_prop = 1;
RUN;

*creating variable for agency's ability to provide transport services;
DATA nemsis.midaz_change;
	SET nemsis.midaz_change;
	IF transport_prop > 0 THEN transport = 1;
	ELSE IF transport_prop = 0 THEN transport = 0;
RUN;
PROC FREQ DATA=nemsis.midaz_change;
	TABLE transport;
RUN;

*creating variable for agency's service type;
DATA nemsis.midaz_change;
	SET nemsis.midaz_change;
	IF transfer_prop = 1 THEN service_type = 0;
	ELSE IF response_prop = 1 THEN service_type = 1;
	ELSE IF service_type_other_prop = 1 THEN service_type = 2;
	ELSE IF transfer_prop<1 and response_prop<1 and service_type_other_prop<1 THEN service_type = 3;
RUN;
PROC FREQ DATA=nemsis.midaz_change;
	TABLE service_type;
RUN;

*making variable for scene response (none, some, most all);
DATA nemsis.midaz_change;
	SET nemsis.midaz_change;
	IF response_prop = 0 THEN response = 0;
	ELSE IF 0<response_prop < .5 THEN response = 1;
	ELSE IF 0.5<=response_prop <1 THEN response = 2;
	ELSE IF response_prop = 1 THEN response = 3;
RUN;
PROC FREQ DATA=nemsis.midaz_change;
	TABLE response;
RUN;

*making variable for urbanicity (defined by >95% of calls in one ubanicity;
DATA nemsis.midaz_change;
	SET nemsis.midaz_change;
	IF urban_prop > .95  THEN urbanicity = 0;
	ELSE IF suburban_prop > .95 THEN urbanicity = 1;
	ELSE IF rural_prop > .95 THEN urbanicity = 2;
	ELSE IF wilderness_prop > .95 THEN urbanicity = 3;
	ELSE IF urban_prop <= .95 and suburban_prop <= .95 and rural_prop <= .95 and wilderness_prop <= .95 THEN urbanicity = 4;
RUN;
PROC FREQ DATA=nemsis.midaz_change;
	TABLE urbanicity;
RUN;

*transforming remaining variables;
DATA nemsis.midaz_change;
	SET nemsis.midaz_change;
	agecat_1_transf = 10* agecat_1_prop;
	age_6_20_transf = 10* age_6_20;
	agecat_6_transf = 10* agecat_6_prop;
	female_transf = 10* female_prop;
	black_transf = 10* black_prop;
	race_other_transf = 10* race_other_prop;
	hispanic_transf = 10* hispanic_prop;
	calls_transf_decr_1000 = avg_callvol/1000;
RUN;

*getting rid of the observation without an agencyID;
DATA nemsis.midaz_change;
	SET nemsis.midaz_change;
	IF benzos NE 2348;
RUN;

*********merging nemsis.midaz_change in nemsis.complete to allow addition of level-2 covariates to hierarchical model;

*making a temporary dataset from midaz_change to allow change of names to agency_(urbanicity...);
DATA midaz_change;
	SET nemsis.midaz_change;
	agency_midaz_prop = midaz_prop;
	agency_benzos = benzos;
	agency_midaz_change_per_year = change_per_year;
	agency_infant_prop_10 = agecat_1_transf;
	agency_peds_prop_10 = age_6_20_transf;
	agency_elderly_prop_10 = agecat_6_transf;
	agency_female_prop_10 = female_transf;
	agency_black_prop_10 = black_transf;
	agency_hispanic_prop_10 = hispanic_transf;
	agency_urbanicity = urbanicity;
	agency_transport_capability = transport;
	agency_response_frequency_cat = response;
	agency_service_level_max = service_level_max;
	agency_change_ann_callvol_1000 = calls_transf_decr_1000;
	agency_county_count = counties;
	KEEP agencyID years_rep years_sz_rep agency_midaz_prop agency_benzos
		agency_midaz_change_per_year 
		agency_infant_prop_10
		agency_peds_prop_10 
		agency_elderly_prop_10
		agency_female_prop_10 
		agency_black_prop_10 
		agency_hispanic_prop_10 
		agency_urbanicity
		agency_service_level_max
		agency_transport_capability
		agency_response_frequency_cat
		agency_change_ann_callvol_1000 
		size_quintile 
		agency_county_count;
RUN;

*merging datasets;
PROC SORT DATA=midaz_change; BY agencyID; RUN;
PROC SORT DATA=nemsis.complete; BY agencyID; RUN;
DATA nemsis.complete;
	MERGE nemsis.complete midaz_change;
	BY agencyID;
RUN;




************************************************************************
************************************************************************
Analysis of complete dataset---primary outcomes, individual level
************************************************************************
************************************************************************;

*************************************************************
paragraph 1: flow of inclusion criteria
**************************************************************;

*total number in original datasets;
TITLE "total number of events in original datasets";
PROC MEANS DATA=nemsis.events10 n;
	VAR eventID;
RUN;
PROC MEANS DATA=nemsis.events11 n;
	VAR eventID;
RUN;
PROC MEANS DATA=nemsis.events12 n;
	VAR eventID;
RUN;
PROC MEANS DATA=nemsis.events13 n;
	VAR eventID;
RUN;
PROC MEANS DATA=nemsis.events14 n;
	VAR eventID;
RUN;

*total where narrow seizure inclusion criteria applied (broad, from above, creation of datasets);
TITLE "number of events after narrow seizure inclusion criteria";
PROC MEANS DATA=nemsis.events10 n;
	WHERE E09_15 = "1710" OR E09_16 = "1845";
	VAR eventID;
RUN;
PROC MEANS DATA=nemsis.events11 n;
	WHERE E09_15 = "1710" OR E09_16 = "1845";
	VAR eventID;
RUN;
PROC MEANS DATA=nemsis.events12 n;
	WHERE E09_15 = "1710" OR E09_16 = "1845";
	VAR eventID;
RUN;
PROC MEANS DATA=nemsis.events13 n;
	WHERE E09_15 = "1710" OR E09_16 = "1845";
	VAR eventID;
RUN;
PROC MEANS DATA=nemsis.events14 n;
	WHERE E09_15 = "1710" OR E09_16 = "1845";
	VAR eventID;
RUN;

*total where narrow seizure and benzodiazepine inclusion criteria applied;
PROC MEANS DATA=nemsis.sz_agency_narrow_all n;
	VAR eventID;
	CLASS yearnum;
	TITLE "number of events after narrow seizure and benzodiazepine inclusion criteria";
RUN;

*total where narrow seizure and benzodiazepine inclusion criteria applied, excluding those given non-specific "Benzodiazepines";
PROC MEANS DATA=nemsis.sz_agency_narrow_all n;
	VAR eventID;
	CLASS yearnum;
	WHERE benzocat NE .;
	TITLE "number of events after narrow seizure and benzodiazepine inclusion criteria, excluding those given non-specific Benzodiazepines";
RUN;

*total where agency is fully represented accross all years;
PROC MEANS DATA=nemsis.complete n;
	VAR eventID;
	CLASS yearnum;
	WHERE agency_complete = 1;
	TITLE "number of events in nemsis.complete";
RUN;

*agencies in nemsis.complete;
PROC FREQ DATA=nemsis.complete noprint;
	TABLE agencyID / out=agency_number;
RUN;

*number of states in each year;
PROC FREQ DATA=nemsis.s_prop_midaz_merged;
	table agencystate*yearnum / nopercent nocol norow;
RUN;

*************************************************************
descriptive statistics
**************************************************************;

*Descriptive statistics: mean +/- SD (Range);
PROC UNIVARIATE DATA=nemsis.complete;
	VAR age_yrs;
	TITLE "Mean age in complete dataset";
RUN;

*Descriptive statistics: # (%);
PROC FREQ DATA=nemsis.complete;
	TABLE agecat E06_11new race E06_13new UScensusregion UScensusDivision Urbanicity cc primary secondary E11_01new E09_04new service_level primary_role type_service;
	TITLE "Distribution of variables for Table 1";
RUN;

*number of agencies = 3504, with 770 present in all 5 years--see creation of agency_nomiss from agency_wide;
	*first observation each does not have an agencyID;
PROC CONTENTS DATA=nemsis.agency_wide; RUN;
PROC CONTENTS DATA=nemsis.agency_nomiss; RUN;

*************************************************************
Tables 1 and 2: Confounding 
**************************************************************;

*exposure covariate table;
PROC MEANS DATA=nemsis.complete;
	VAR age_yrs;
	CLASS yearnum;
	TITLE "Mean age in narrowly defined dataset for Table 1";
RUN;
PROC SORT DATA=nemsis.complete; BY yearnum; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE midazolam agecat E06_11new race E06_13new UScensusregion UScensusDivision Urbanicity cc primary secondary E11_01new E09_04new service_level primary_role type_service size_quintile;
	BY yearnum;
	TITLE "Distribution of variables for Table 1";
RUN;
*# agencies per year;
PROC FREQ DATA=nemsis.complete noprint;
	TABLE agencyID*yearnum / out=nemsis.agencyyear;
RUN;
PROC FREQ DATA=nemsis.agencyyear;
	TABLE yearnum;
RUN;


*outcome-covariate table: change in rate of midazolam use (2010-2014) by categorical predictors;
PROC FREQ DATA=nemsis.complete;
	TABLE midazolam*yearnum / nopercent norow;
RUN;


%MACRO confounding (predictor, out);
PROC SORT DATA=nemsis.complete; BY yearnum &predictor; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE midazolam / out=&out;
	BY yearnum &predictor;
	TITLE "change in rate of midazolam use (2010-2014) by categorical predictors";
RUN;
%MEND;
%confounding (agecat, midaz_agecat);
%confounding (E06_11new, midaz_gender);
%confounding (race, midaz_race);
%confounding (E06_13new, midaz_ethnicity);
%confounding (USCensusRegion, midaz_censusregion);
%confounding (Urbanicity, midaz_urbanicity);
%confounding (service_level, midaz_servicelevel);
%confounding (primary_role, midaz_primaryrole);
%confounding (Type_service, midaz_servicetype);
%confounding (size_quintile, midaz_sizequintile);


*outcome-covariate table by studymonth (year_granular): change in rate of midazolam use (2010-2014) by categorical predictors;
%MACRO confounding (predictor, out);
PROC SORT DATA=nemsis.complete; BY year_granular &predictor; RUN;
PROC FREQ DATA=nemsis.complete NOPRINT;
	TABLE midazolam / out=&out;
	BY year_granular &predictor;
	TITLE "change in rate of midazolam use (2010-2014, year_granular) by categorical predictors";
RUN;
%MEND;
%confounding (agecat, midaz_agecat_y);
%confounding (E06_11new, midaz_gender_y);
%confounding (race, midaz_race_y);
%confounding (E06_13new, midaz_ethnicity_y);
%confounding (USCensusRegion, midaz_censusregion_y);
%confounding (Urbanicity, midaz_urbanicity_y);
%confounding (service_level, midaz_servicelevel_y);
%confounding (primary_role, midaz_primaryrole_y);
%confounding (Type_service, midaz_servicetype_y);
%confounding (size_quintile, midaz_sizequintile_y);


DATA midaz_urbanicity_y1;
	SET midaz_urbanicity_y;
	IF Urbanicity = "Urban" THEN Urbanicity1 = 1;
	ELSE IF Urbanicity = "Suburban" THEN Urbanicity1 = 2;
	ELSE IF Urbanicity = "Rural" THEN Urbanicity1 = 3;
	ELSE IF Urbanicity = "Wilderness" THEN Urbanicity1 = 4;
	ELSE urbanicity1 = .;
RUN;
PROC FREQ DATA=midaz_urbanicity_y1; TABLE urbanicity*urbanicity1 / list; RUN;

DATA midaz_censusregion_y1;
	SET midaz_censusregion_y;
	IF USCensusRegion = "Northeast" THEN USCensusRegion1 = 1;
	ELSE IF USCensusRegion = "Midwest" THEN USCensusRegion1 = 2;
	ELSE IF USCensusRegion = "South" THEN USCensusRegion1 = 3;
	ELSE IF USCensusRegion = "West" THEN USCensusRegion1 = 4;
	ELSE IF USCensusRegion = "Island Areas" THEN USCensusRegion1 = .;
	ELSE USCensusRegion1 = .;
RUN;
PROC FREQ DATA=midaz_censusregion_y1; TABLE USCensusRegion*USCensusRegion1 / list; RUN;


Title " ";
%MACRO graphs (database, group, title);
PROC SGPLOT DATA=&database;
	SERIES x=year_granular y=percent / group=&group 
		LineAttrs=(thickness=3 pattern=1) 
		NAME="&group";
		YAXIS DISPLAY=(nolabel novalues) max=70 min=10 LABEL="Percent of Total Benzodiazepines";
		XAXIS DISPLAY=(nolabel novalues);
		KEYLEGEND "&group" / title="&title" Across=1 location=inside position=topleft;
	WHERE midazolam = 1 and &group NE .;
RUN;
%MEND;
%graphs (midaz_agecat_y, agecat, Age Category);
%graphs (midaz_gender_y, E06_11new, Gender);
%graphs (midaz_race_y, race, Race);
%graphs (midaz_ethnicity_y, E06_13new, Ethnicity);
%graphs (nemsis.midaz_censusregion_y1, USCensusRegion1, US Census Region);
%graphs (midaz_urbanicity_y1, Urbanicity1, Urbanicity);
%graphs (midaz_servicelevel_y, service_level, Ambulance Service Level);
%graphs (midaz_primaryrole_y, primary_role, Primary Role of Ambulance);
%graphs (midaz_servicetype_y, Type_service, Type of Service Requested);
%graphs (midaz_sizequintile_y, size_quintile, EMS Agency Size Quintile);

*************************************************************
Crude Analysis
**************************************************************;

*trends in midazolam use;
PROC FREQ DATA=nemsis.complete;
	TABLE midazolam;
RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE benzocat;
	WHERE midazolam = 0;
RUN;

*Frequency of Midazolam use for treatement of pre-hospital seizures;
PROC FREQ DATA=nemsis.complete;
	TABLE (Midazolam benzocat)*yearnum / norow nopercent chisq;
	TITLE "Frequency of Midazolam use by year, complete dataset";
RUN;

*Frequency of Midazolam use for treatement of pre-hospital seizures;
PROC FREQ DATA=nemsis.complete;
	TABLE Midazolam*year_granular / norow nopercent chisq;
	TITLE "Frequency of Midazolam by month, complete dataset";
RUN;



******************************************
******************************************
Regression Analysis
******************************************
******************************************;

******************************
Linear Regression
******************************;

*regression of midazolam frequency from whole dataset includes agencies that were missing some years (44% of events, 49% of agencies);
PROC FREQ DATA=nemsis.complete;
	TABLE studymonth*benzocat / noprint outpct out=nemsis.benzo_freq;
	TITLE "frequency of benzo usage by month--esp. diazepam";
RUN;

*making variable for year_granular;
DATA nemsis.benzo_freq;
	SET nemsis.benzo_freq;
	year_granular = (studymonth/12);
RUN;

*scatter plot/regression of benzo frequency by month based on precents (not raw data);
PROC SGPLOT DATA=nemsis.benzo_freq;
	SCATTER x = year_granular y = PCT_ROW / group=benzocat;
	REG x = year_granular y = PCT_ROW / group=benzocat cli clm;
	TITLE "benzodiazepine use by Study Month, all calls";
RUN;

*proc transreg of midaz use before and after RAMPART, from full dataset;
ODS html image_dpi=300;
PROC SORT DATA=nemsis.benzo_freq; BY benzocat; RUN;
PROC TRANSREG data=nemsis.benzo_freq plots=scatter rsquare cl;
	model identity(PCT_ROW) =  pspline(year_granular / degree=1 knots = 2.166666);
	WHERE benzocat = 1;
	TITLE "midazolam transreg with knot at RAMPART publication, from full dataset";
RUN;
ODS html image_dpi=100;



****proc transreg of midaz use before and after RAMPART, from agencies that contributed data every year***;
*regression of midazolam frequency from agencies that submitted data in all years (whether they treated a seizure or not);
PROC FREQ DATA=nemsis.complete;
	TABLE studymonth*benzocat / noprint outpct out=nemsis.benzo_freq_full_rep;
	WHERE years_rep = 5;
	TITLE "frequency of benzo usage by month, limited to agencies that submitted data in all years";
RUN;

*number of agencies represented;
PROC FREQ DATA=nemsis.agency_wide;
	TABLE years_rep / list nopercent norow nocol;
RUN;

*making variable for year_granular;
DATA nemsis.benzo_freq_full_rep;
	SET nemsis.benzo_freq_full_rep;
	year_granular = (studymonth/12);
RUN;

ODS html image_dpi=300;
PROC SORT DATA=nemsis.benzo_freq_full_rep; BY benzocat; RUN;
PROC TRANSREG data=nemsis.benzo_freq_full_rep plots=scatter rsquare cl;
	model identity(PCT_ROW) =  pspline(year_granular / degree=1 knots = 2.166666);
	WHERE benzocat = 1;
	TITLE "midazolam transreg with knot at RAMPART publication, from agencies that contributed data every year";
RUN;
ODS html image_dpi=100;


*****PROC TRANSREG to include splices and knots***;
*PROC TRANSREG for diazepam during shortage;
	*1st shortage started 11/24/09 (before study)
	*1st shortage ended 6/23/11. = month 18, year_granular = 1.5
	*2nd shortage began 8/12/11. = month 20, year_granular = 1.6666
	*2nd shortage was announced on ASHP 12/22/11. = month number 24, year_granular = 2
		*shortage was most significant in 2011 and 2012 (ending month 36) (except 6/23-8/12, 2011) because shortage involved both syringes and large vial
	*2nd shortage ended 10/4/13. = month number 45, year_granular = 3.75;

*knots below represent best fit;
ODS html image_dpi=300;
PROC SORT DATA=nemsis.benzo_freq; BY benzocat; RUN;
PROC TRANSREG data=nemsis.benzo_freq plots=scatter rsquare cl;
	model identity(PCT_ROW) =  pspline(year_granular / degree=1 knots = 2 2 );
	BY benzocat;
	WHERE benzocat = 3 or benzocat = 1 or  benzocat = 2 and 0<year_granular<=5;
	TITLE "benzodiazepine transreg with discontinuous knot at diazepam shortage announcement";
RUN;
ODS html image_dpi=100;
*for calculating slopes and intercepts at discontinuous point;
PROC TRANSREG data=nemsis.benzo_freq plots=scatter rsquare cl;
	model identity(PCT_ROW) =  pspline(year_granular / degree=1 knots = 2 2 );
	BY benzocat;
	WHERE benzocat = 3 or benzocat = 1 or  benzocat = 2 and 0<year_granular<2;
	TITLE "benzodiazepine transreg with discontinuous knot at diazepam shortage announcement, months 1-23 for calculation of slope and value right before months 24";
RUN;
PROC TRANSREG data=nemsis.benzo_freq plots=scatter rsquare cl;
	model identity(PCT_ROW) =  pspline(year_granular / degree=1 knots = 2 2 );
	BY benzocat;
	WHERE benzocat = 3 or benzocat = 1 or  benzocat = 2 and 2<year_granular<=5;
	TITLE "benzodiazepine transreg with discontinuous knot at diazepam shortage announcement, months 25-60 for calculation of slope and value right after month 24 and at month 60";
RUN;

*number of benzodiazepines used in Nov. 2011 and Jan. 2012 (before and after year_granular 2, announcement of diazepam shortage) 
	to use as denominator for calculation of 95%CIs of difference between proportions (VASSARstats);
PROC FREQ DATA=nemsis.complete;
	TABLE benzocat*studymonth;
	WHERE studymonth = 23;
RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE benzocat*studymonth;
	WHERE studymonth = 25;
RUN;

*95%CI of difference in slopes calculated by hand using N, coefficient variance, and slope for each segment, 1-23 months, and 25-60 months;
	*used equation for comparing two population means, pooled;




*****************************************************************
			Logistic Regression
****************************************************************;

*model 0: intercept only logistic regression of midazolam;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	MODEL midazolam = ;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "model 0a: intercept only model, limited to non-missing observations for low missingness covariates";
	TITLE "midazolam = ";
RUN;

*Model 1: unadjusted impact of RAMPART publicaition;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	MODEL midazolam = post_RAMPART;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "model 1a: unadjusted impact of RAMPART publicaition, limited to non-missing observations for low missingness covariates";
	TITLE "midazolam = post_RAMPART";
RUN;

*Model 2: Impact of RAMPART publicaition, adjusted for secular trends;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	MODEL midazolam = post_RAMPART year_granular;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 2a: Impact of RAMPART publicaition, adjusted for secular trends, limited to non-missing observations for low missingness covariates";
	TITLE "midazolam = post_RAMPART studymonth";
RUN;

*Model 3: Impact of RAMPART publicaition, adjusted for secular trends and demographic covariates;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban");
	MODEL midazolam = post_RAMPART year_granular agecat E06_11new USCensusRegion Urbanicity;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 3a: Impact of RAMPART publicaition, adjusted for secular trends and demographic covariates, limited to non-missing observations for low missingness covariates";
	TITLE "midazolam = post_RAMPART studymonth agecat E06_11new USCensusRegion Urbanicity";
	TITLE "excluded race/ethnicity due to high missingness";
RUN;

*Model 4a: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covariates;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") primary_role(ref=first) Type_service(ref=first);
	MODEL midazolam = post_RAMPART year_granular agecat E06_11new USCensusRegion Urbanicity primary_role type_service;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 4a: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates";
	TITLE "midazolam = post_RAMPART studymonth/12 agecat E06_11new USCensusRegion Urbanicity primary_role type_service";
	TITLE "excluded race, ethnicity and service level due to high missingness";
RUN;


*Sensitivity analyses with race, ethnicity and service level (highly missing varaibles);

*Model 4b: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covariates with race (17.7% missingness);
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS agecat (ref=first) E06_11new (ref=first) race (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") primary_role(ref=first) Type_service(ref=first);
	MODEL midazolam = post_RAMPART year_granular agecat E06_11new race USCensusRegion Urbanicity primary_role type_service;
	WHERE lowmiss_race_nomiss = 1;
	TITLE "Model 4b: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates + race";
	TITLE "midazolam = post_RAMPART studymonth agecat E06_11new race USCensusRegion Urbanicity primary_role type_service";
	TITLE "excluded ethnicity and service level due to high missingness. Race included (17.7% missing)";
RUN;

*Model 4c: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covariates with ethnicity (27.6% missingness);
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS agecat (ref=first) E06_11new (ref=first) E06_13new (ref=last) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") primary_role(ref=first) Type_service(ref=first);
	MODEL midazolam = post_RAMPART year_granular agecat E06_11new E06_13new USCensusRegion Urbanicity primary_role type_service;
	WHERE lowmiss_ethnicity_nomiss = 1;
	TITLE "Model 4c: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates + ethnicity";
	TITLE "midazolam = post_RAMPART studymonth agecat E06_11new E06_13new USCensusRegion Urbanicity primary_role type_service";
	TITLE "excluded race and service level due to high missingness. ethnicity included (27.6% missing)";
RUN;

*Model 4d: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covariates with service level (42.6% missingness);
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") service_level (ref=last) primary_role(ref=first) Type_service(ref=first);
	MODEL midazolam = post_RAMPART year_granular agecat E06_11new USCensusRegion Urbanicity service_level primary_role type_service;
	WHERE lowmiss_servlevel_nomiss = 1;
	TITLE "Model 4d: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates + service level";
	TITLE "midazolam = post_RAMPART studymonth agecat E06_11new USCensusRegion Urbanicity service_level primary_role type_service";
	TITLE "excluded race and ethnicity due to high missingness. service level included (42.6% missing)";
RUN;


*logistic regression of midazolam by studymonth, all data;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	MODEL midazolam = year_granular;
	TITLE "model 1: logistic regression of midazolam by studymonth, all data";
RUN;

*logistic regression of midazolam by study month and age in years (continous);
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	MODEL midazolam = year_granular age_yrs;
	TITLE "logistic regression of midazolam by studymonth and age, all data";
RUN;

*logistic regression of midazolam by study month and each categorical predective variables, individually;
%MACRO logistic (predictor, order);
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS &predictor (ref=&order);
	MODEL midazolam = year_granular &predictor;
	TITLE "logistic regression of midazolam by studymonth + other categorical predictors, all data";
RUN;
%MEND;
%logistic (agecat, first)
%logistic (E06_11new, first)
%logistic (race, first)
%logistic (E06_13new, last)
%logistic (USCensusRegion, "Northeast")
%logistic (urbanicity, "Urban")
%logistic (service_level, first)
%logistic (primary_role, first)
%logistic (Type_service, first);


*effect of race on midazolam, after adjusting for geography;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS race (ref=first) urbanicity (ref="Urban");
	MODEL midazolam = year_granular race urbanicity;
	TITLE "logistic regression of midazolam by studymonth + race after adjusting for urbanicity, all data";
RUN;
*effect of race on midazolam, after adjusting for urbanicity;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS race (ref=first) urbanicity (ref="Urban");
	MODEL midazolam = year_granular race urbanicity race*urbanicity;
	TITLE "logistic regression of midazolam by studymonth + race after adjusting for urbanicity (and interaction), all data";
RUN;

*effect of race on midazolam, after adjusting for census region;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS race (ref=first) USCensusRegion (ref="Northeast");
	MODEL midazolam = year_granular race USCensusRegion;
	TITLE "logistic regression of midazolam by studymonth + race after adjusting for USCensusRegion, all data";
RUN;

*effect of race on midazolam, after adjusting for geography;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS race (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban");
	MODEL midazolam = year_granular race USCensusRegion Urbanicity;
	TITLE "logistic regression of midazolam by studymonth + race after adjusting for geography, all data";
RUN;

*effect of race and ethnicity on midazolam, after adjusting for geography;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS race (ref=first) E06_13new (ref=last) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban");
	MODEL midazolam = year_granular race E06_13new USCensusRegion Urbanicity;
	TITLE "logistic regression of midazolam by studymonth + race and ethnicity after adjusting for geography, all data";
RUN;

*Model fully adjusted for demographic characteristics;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS agecat (ref=first) E06_11new (ref=first) race (ref=first) E06_13new (ref=last) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban");
	MODEL midazolam = year_granular agecat E06_11new race E06_13new USCensusRegion Urbanicity;
	TITLE "logistic regression of midazolam by studymonth + age_cat + gender + race + ethnicity + region + urbanicity, all data";
RUN;


*Model fully adjusted for demographic characteristics, limited to agencies that are fully represented;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS agecat (ref=first) E06_11new (ref=first) race (ref=first) E06_13new (ref=last) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban");
	MODEL midazolam = year_granular agecat E06_11new race E06_13new USCensusRegion Urbanicity;
	WHERE agency_complete = 1;
	TITLE "logistic regression of midazolam by studymonth + age_cat + gender + race + ethnicity + region + urbanicity, fully represented data";
RUN;



*Model fully adjusted for Agency variables on individual level
	(service level is heavily missing, primary role and service type are fully represented);
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS service_level (ref=last) primary_role(ref=first) Type_service(ref=first);
	MODEL midazolam = year_granular primary_role Type_service;
	TITLE "logistic regression of midazolam by studymonth + service level + service type + primary role, all data";
RUN;

*Model fully adjusted for Agency variables on individual level;
PROC LOGISTIC DATA=nemsis.complete DESCENDING;
	CLASS service_level(ref=first) primary_role(ref=first) Type_service(ref=first);
	MODEL midazolam = year_granular service_level primary_role Type_service;
	TITLE "logistic regression of midazolam by studymonth + service level + service type + primary role, all data";
RUN;





**************Sensitivty analysis**************;

*evaluation of covariate missingness (individual level) for inclusion in model;
*<1.5% missing (or passing sensitivity analysis) gets included;
PROC MEANS DATA=nemsis.complete nmiss;
	VAR agecat E06_11new race E06_13new service_level primary_role Type_service;
	TITLE "missingness of covariates";
RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE USCensusRegion urbanicity agencyID;
	TITLE "missingness of covariates";
RUN;

*missingness pattern for agencies;
PROC SORT DATA=nemsis.agency_wide; BY benzo_freq_10 benzo_freq_11 benzo_freq_12 benzo_freq_13 benzo_freq_14; RUN;
PROC PRINT DATA=nemsis.agency_wide (firstobs= 200 obs=100);
	VAR benzo_freq_10 benzo_freq_11 benzo_freq_12 benzo_freq_13 benzo_freq_14;
RUN;


*evaluating missing pattern;
PROC MI DATA=nemsis.complete nimpute=0;
	VAR AgencyID agecat E06_11new race E06_13new service_level primary_role Type_service USCensusRegion urbanicity;
	ODS select misspattern;
RUN;


*************************************
*************************************
Analysis of Agency Dataset
*************************************
************************************;

*number of agencies = 3504 (3505, but one missing agencyID);
PROC FREQ DATA=nemsis.agency_wide;
	TABLE years_rep;
RUN;

*number of states and territories in each year;
PROC FREQ DATA=nemsis.complete;
	TABLE agencystate*yearnum / nocol norow nopercent;
	/*WHERE uscensusregion = "Island Areas";*/
RUN;

*number of agencies working in >1 state (includes many agencies that did not give any benzos);
PROC FREQ DATA=nemsis.agency_all NOPRINT;
	TABLE agencyID*agencystate / list out=nemsis.agency_state_list;
RUN;
DATA nemsis.agency_state_list;
	SET nemsis.agency_state_list;
	KEEP agencyID agencystate;
RUN;
DATA nemsis.agency_state_list;
	SET nemsis.agency_state_list;
	count + 1;
	BY agencyID;
	IF first.agencyID THEN count=1;
RUN;
PROC FREQ DATA=nemsis.agency_state_list;
	TABLE count / list missing;
	TITLE "Number of states each agency operates in";
RUN;

*number of agencies working in >1 county (includes many agencies that did not give any benzos);
PROC FREQ DATA=nemsis.agency_all NOPRINT;
	TABLE agencyID*agencycounty / list out=nemsis.agency_county_list;
RUN;
DATA nemsis.agency_county_list;
	SET nemsis.agency_county_list;
	KEEP agencyID agencycounty;
RUN;
DATA nemsis.agency_county_list;
	SET nemsis.agency_county_list;
	count + 1;
	BY agencyID;
	IF first.agencyID THEN count=1;
RUN;
PROC FREQ DATA=nemsis.agency_county_list;
	TABLE count / list missing;
	TITLE "Number of counties each agency operates in";
RUN;


*Distribution of midazolam frequency by agency in each year;
%MACRO midaz (year);
PROC UNIVARIATE DATA=nemsis.agency_wide;
	VAR &year;
	HISTOGRAM &year;
	TITLE "Distribution of midazolam frequency by agency in each year";
RUN;
%MEND;
%midaz (midaz_10);
/*%midaz (midaz_11);
%midaz (midaz_12);
%midaz (midaz_13);*/
%midaz (midaz_14);

*Distribution of change in madizolam use by agency;
PROC UNIVARIATE DATA=nemsis.agency_wide CIBASIC;
	VAR delta_midaz;
	HISTOGRAM delta_midaz 
		/ vaxislabel="Percent of EMS Agencies" vscale=percent;
	TITLE "Distribution of change in madizolam use by agency";
RUN;

***changes in midaz use by agencies*******;
*Agencies that increased midazolam use;
PROC UNIVARIATE DATA=nemsis.midaz_change CIBASIC;
	WHERE change_per_year > 0 and years_sz_rep > 1;
	VAR change_per_year;
	TITLE "Agencies that increased midazolam use";
RUN;
*Agencies that decreased midazolam use;
PROC UNIVARIATE DATA=nemsis.midaz_change CIBASIC;
	WHERE change_per_year < 0 and years_sz_rep > 1;
	VAR change_per_year;
	TITLE "Agencies that decreased midazolam use";
RUN;
*Agencies that didn't change midazolam use;
PROC UNIVARIATE DATA=nemsis.midaz_change CIBASIC;
	WHERE change_per_year = 0 and years_sz_rep > 1;
	VAR change_per_year;
	TITLE "Agencies that didn't change midazolam use";
RUN;
*reason for agencies not changeing (all or none midazolam);
PROC UNIVARIATE DATA=nemsis.midaz_change CIBASIC;
	WHERE change_per_year = 0 and years_sz_rep > 1 and midaz_prop = 1;
	VAR midaz_prop;
	TITLE "midaz use = 1 among agencies that didn't change midazolam use";
RUN;
PROC UNIVARIATE DATA=nemsis.midaz_change CIBASIC;
	WHERE change_per_year = 0 and years_sz_rep > 1 and midaz_prop = 0;
	VAR midaz_prop;
	TITLE "midaz use = 0 among agencies that didn't change midazolam use";
RUN;


*Spaghetti plot of States midazolam % use per year, with regression line;
	*too many agencies to make graph legible;
PROC SGPLOT DATA=nemsis.s_prop_midaz_merged;
	SERIES x=yearnum y=Midaz_prop_year / group=agencystate LineAttrs=(pattern=1 thickness=1);
	REG x=yearnum y=Midaz_prop_year / nomarkers LineAttrs=(pattern=1 color="black" thickness=4);
	TITLE "Porportion of midazolam used by states per year";
RUN;

*Spaghetti plot of States midazolam % use per month, with regression line;
PROC SGPLOT DATA=nemsis.s_prop_midaz_month_merged;
	REG x=studymonth y=Midaz_prop_month / group=agencystate nomarkers LineAttrs=(pattern=1 thickness=1);
	REG x=studymonth y=Midaz_prop_month / nomarkers LineAttrs=(pattern=1 color="black" thickness=4);
	XAXIS DISPLAY=(novalues) values=(0 to 60 by 12);
	TITLE "Porportion of midazolam used by states per month";
RUN;


*Change in midazolam use for agencies by size categories (based on average call volume);
ODS html image_dpi=300;
PROC SGPLOT DATA=nemsis.agency_wide;
	VBOX delta_midaz / category=size_decile;
	TITLE "Box plot of change in midazolam by size decile of agency";
RUN;
ODS html image_dpi=100;

PROC GLM DATA=nemsis.agency_wide;
	CLASS size_decile;
	MODEL delta_midaz = size_decile / clb;
	TITLE "regression of change in midazolam by size decile of agency";
RUN;
PROC REG DATA=nemsis.agency_wide;
	MODEL delta_midaz = avg_callvol / clb;
	TITLE "regression of change in midazolam by size decile of agency";
RUN;

PROC SGPLOT DATA=nemsis.agency_wide;
	VBOX delta_midaz / category=size_ventile;
	TITLE "Box plot of change in midazolam by size ventile (20th) of agency";
RUN;
PROC REG DATA=nemsis.agency_wide;
	MODEL delta_midaz = size_ventile;
	TITLE "regression of change in midazolam by size ventile (20th) of agency";
RUN;
PROC REG DATA=nemsis.agency_wide;
	MODEL delta_midaz = size_ventile;
	WHERE size_ventile < 5;
	TITLE "regression of change in midazolam by size ventile of agency, among smallest 5 ventiles";
RUN;
PROC REG DATA=nemsis.agency_wide;
	MODEL delta_midaz = size_ventile;
	WHERE size_ventile > 14;
	TITLE "regression of change in midazolam by size ventile of agency, among largest 5 ventiles";
RUN;


*crude midazolam use in 2014 as a function of agency size (from 2010);
PROC SGPLOT DATA=nemsis.agency_wide;
	VBOX midaz_14 / category=size_decile;
	TITLE "Box plot of midazolam use in 2014 by size decile of agency (from 2010)";
RUN;


***************************
***************************
Hierarchical Analysis
***************************
***************************;

*creating unadjusted proportions for hierarchical model table;
%MACRO confounding (predictor, out);
PROC SORT DATA=nemsis.complete; BY &predictor; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE midazolam / out=&out;
	BY &predictor;
	TITLE "midazolam use by categorical predictors";
RUN;
%MEND;
%confounding (post_RAMPART, midaz_p_rampart);
%confounding (agecat, midaz_agecat);
%confounding (E06_11new, midaz_gender);
%confounding (race, midaz_race);
%confounding (E06_13new, midaz_ethnicity);
%confounding (USCensusRegion, midaz_censusregion);
%confounding (Urbanicity, midaz_urbanicity);
%confounding (service_level, midaz_servicelevel);
%confounding (primary_role, midaz_primaryrole);
%confounding (Type_service, midaz_servicetype);
%confounding (size_quintile, modiz_sizequintile);

*Model 0: midazolam (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID;
	MODEL midazolam (ref=first) = / dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "model 0a: intercept only model, limited to non-missing observations for low missingness covariates";
	TITLE "midazolam = (agencyID)";
RUN;

*Model 1: midazolam = post-rampart (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID;
	MODEL midazolam (ref=first) = post_rampart / dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 1a: unadjusted impact of RAMPART publicaition, limited to non-missing observations for low missingness covariates";
	TITLE "Model 1a: midazolam = post-rampart (Agency)";
RUN;

*Model 2: midazolam = post-rampart + studymonth (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID;
	MODEL midazolam (ref=first) = post_rampart year_granular / dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 2a:  Impact of RAMPART publicaition, adjusted for secular trends, limited to non-missing observations for low missingness covariates";
	TITLE "Model 2a: midazolam = post-rampart + studymonth (Agency)";
RUN;

*Model 3: midazolam = post-rampart + studymonth + demographics (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban");
	MODEL midazolam (ref=first) = post_rampart year_granular agecat E06_11new USCensusRegion Urbanicity
		/ dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 3a: Impact of RAMPART publicaition, adjusted for secular trends and demographic covariates, limited to non-missing observations for low missingness covariates";
	TITLE "Model 3a: midazolam = post-rampart + studymonth + demographics (Agency)";
	TITLE "excludes race/ethnicity due to high missingness";
RUN;

*Model 4: midazolam = post-rampart + studymonth + demographics + agency factors (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") primary_role (ref=first) type_service (ref=first) size_quintile (ref=first);
	MODEL midazolam (ref=first) = post_rampart year_granular agecat E06_11new USCensusRegion Urbanicity primary_role type_service size_quintile
		/ dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 4a: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates";
	TITLE "Model 4a: midazolam = post-rampart + studymonth + demographics + agency factors (Agency)";
	TITLE "excludes race/ethnicity/service level due to high missingness";
RUN;


*sensitivity analysis with highly missing variables;

*Model 4b: midazolam = post-rampart + studymonth + demographics + agency factors (Agency), plus race;
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID agecat (ref=first) E06_11new (ref=first) race (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") primary_role (ref=first) type_service (ref=first);
	MODEL midazolam (ref=first) = post_rampart year_granular agecat E06_11new race USCensusRegion Urbanicity primary_role type_service
		/ dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_race_nomiss = 1;
	TITLE "Model 4b: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates + race";
	TITLE "Model 4b: midazolam = post-rampart + studymonth + demographics + agency factors (Agency)";
	TITLE "excludes ethnicity/service level due to high missingness, includes race (17.7% missing)";
RUN;

*Model 4c: midazolam = post-rampart + studymonth + demographics + agency factors (Agency), plus ethnicity;
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID agecat (ref=first) E06_11new (ref=first) E06_13new (ref=last) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") primary_role (ref=first) type_service (ref=first);
	MODEL midazolam (ref=first) = post_rampart year_granular agecat E06_11new E06_13new USCensusRegion Urbanicity primary_role type_service
		/ dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_ethnicity_nomiss = 1;
	TITLE "Model 4c: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates + ethnicity";
	TITLE "Model 4c: midazolam = post-rampart + studymonth + demographics + agency factors (Agency)";
	TITLE "excludes race/service level due to high missingness, includes ethnicity (27.6% missing)";
RUN;

*Model 4d: midazolam = post-rampart + studymonth + demographics + agency factors (Agency), plus service level;
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") service_level (ref=last) primary_role (ref=first) type_service (ref=first);
	MODEL midazolam (ref=first) = post_rampart year_granular agecat E06_11new USCensusRegion Urbanicity service_level primary_role type_service
		/ dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_servlevel_nomiss = 1;
	TITLE "Model 4d: Impact of RAMPART publicaition, adjusted for secular trends, demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates + service level";
	TITLE "Model 4d: midazolam = post-rampart + studymonth + demographics + agency factors (Agency)";
	TITLE "excludes race/ethnicity due to high missingness, includes service level (42.6% missing)";
RUN;


***************************************************************************************
***************************************************************************************
Agency-Level regressions
***************************************************************************************
**************************************************************************************;



***************************************************************************************
Multivariable Linear Regression on the proportion of midazolam used based on proportions
of each categorical predictor for a given agency in a given year, from poisson table
		(easier to run and easier to interpret--but does not meet assumptions of LR)
**************************************************************************************;

*unadjusted;
%MACRO unadjust (predictor);
PROC REG DATA=nemsis.poisson_linear_transformed;
	MODEL midaz_prop = &predictor / clb;
	TITLE "linear regression of predictors (absolute increase in proportion of male patients by 10%) on proportion of midazolam use by agencies";
RUN;
%MEND;
%unadjust (yearnum);
%unadjust (agecat_1_transf);
%unadjust (agecat_2_transf);
%unadjust (agecat_3_transf);
%unadjust (agecat_4_transf);
%unadjust (agecat_5_transf);
%unadjust (agecat_6_transf);
%unadjust (male_transf);
%unadjust (female_transf);
%unadjust (white_transf);
%unadjust (black_transf);
%unadjust (race_other_transf);
%unadjust (hispanic_transf);
%unadjust (not_hispanic_transf);
%unadjust (urban_transf);
%unadjust (suburban_transf);
%unadjust (rural_transf);
%unadjust (wilderness_transf);
%unadjust (BLS_transf);
%unadjust (ALS_transf);
%unadjust (Air_transf);
%unadjust (service_level_other_transf);
%unadjust (transport_transf);
%unadjust (Role_other_transf);
%unadjust (response_transf);
%unadjust (transfer_transf);
%unadjust (service_type_other_transf);
%unadjust (calls_transf_decr_1000);
%unadjust (size_quintile);
%unadjust (states);
%unadjust (counties);


*singly adjusted for year;
%MACRO singadjust (predictor);
PROC REG DATA=nemsis.poisson_linear_transformed;
	MODEL midaz_prop = yearnum &predictor / clb;
	TITLE "linear regression of predictors (absolute increase in proportion of ___ patients by 10%) on proportion of midazolam use by agencies, singly adjusted for year";
RUN;
%MEND;
%singadjust (agecat_1_transf);
%singadjust (agecat_2_transf);
%singadjust (agecat_3_transf);
%singadjust (agecat_4_transf);
%singadjust (agecat_5_transf);
%singadjust (agecat_6_transf);
%singadjust (male_transf);
%singadjust (female_transf);
%singadjust (white_transf);
%singadjust (black_transf);
%singadjust (race_other_transf);
%singadjust (hispanic_transf);
%singadjust (not_hispanic_transf);
%singadjust (urban_transf);
%singadjust (suburban_transf);
%singadjust (rural_transf);
%singadjust (wilderness_transf);
%singadjust (BLS_transf);
%singadjust (ALS_transf);
%singadjust (Air_transf);
%singadjust (service_level_other_transf);
%singadjust (transport_transf);
%singadjust (Role_other_transf);
%singadjust (response_transf);
%singadjust (transfer_transf);
%singadjust (service_type_other_transf);
%singadjust (calls_transf_decr_1000);
%singadjust (size_quintile);
%singadjust (states);
%singadjust (counties);

*doubly adjusted for year and call volume;
%MACRO doubadjust (predictor);
PROC REG DATA=nemsis.poisson_linear_transformed;
	MODEL midaz_prop = yearnum calls_transf_decr_1000 &predictor / clb;
	TITLE "linear regression of predictors (absolute increase in proportion of ___ patients by 10%) on proportion of midazolam use by agencies, adjusted for year and call volume";
RUN;
%MEND;
%doubadjust (agecat_1_transf);
%doubadjust (agecat_2_transf);
%doubadjust (agecat_3_transf);
%doubadjust (agecat_4_transf);
%doubadjust (agecat_5_transf);
%doubadjust (agecat_6_transf);
%doubadjust (male_transf);
%doubadjust (female_transf);
%doubadjust (white_transf);
%doubadjust (black_transf);
%doubadjust (race_other_transf);
%doubadjust (hispanic_transf);
%doubadjust (not_hispanic_transf);
%doubadjust (urban_transf);
%doubadjust (suburban_transf);
%doubadjust (rural_transf);
%doubadjust (wilderness_transf);
%doubadjust (BLS_transf);
%doubadjust (ALS_transf);
%doubadjust (Air_transf);
%doubadjust (service_level_other_transf);
%doubadjust (transport_transf);
%doubadjust (Role_other_transf);
%doubadjust (response_transf);
%doubadjust (transfer_transf);
%doubadjust (service_type_other_transf);
%doubadjust (size_quintile);
%doubadjust (states);
%doubadjust (counties);


*testing collinearity of likely correlated data. VIF (1/(1-R^2)) > 5 is problem;
PROC REG DATA=nemsis.poisson_linear_transformed;
	model agecat_1_transf = age_6_20; /*R^2 = 0.1800, VIF = 1.22*/
	model agecat_1_transf = agecat_6_transf; /*R^2 = 0.1818, VIF = 1.22*/
	model age_6_20 = agecat_6_transf; RUN; /*R^2 = 0.4255, VIF = 1.74*/
	model black_transf = race_other_transf; /*R^2 = 0.0114, VIF = 1.01*/
	model rural_transf = suburban_transf ; /*R^2 = 0.0303, VIF = 1.03*/
	model rural_transf = wilderness_transf; /*R^2 = 0.0215, VIF = 1.02*/
	model suburban_transf = wilderness_transf; /*R^2 = 0.0101, VIF = 1.01*/ 
	model bls_transf = air_transf; /*R^2 = 0.0803, VIF = 1.09*/
	model bls_transf = als_transf; /*R^2 = 0.5198, VIF = 2.08*/
	model air_transf = als_transf; /*R^2 = 0.1721, VIF = 1.21*/
	model response_transf_20 = transfer_transf; /*R^2 = 0.4817, VIF = 1.93*/
	model size_quintile = calls_transf_decr_1000; /*R^2 = 0.0826, VIF = 1.09*/
	model states = counties; /*R^2 = 0.8167, VIF = 5.46*/
RUN;
*****states will be removed from model 2/2 multicollinearity with counties. Counties will be used as the sole proxy for catchment area******;

*testing multicolinearity of possibly correlated data in multiple regression model. VIF (1/(1-R^2)) > 5 is problem;
PROC REG DATA=nemsis.poisson_linear_transformed;
	model agecat_1_transf = age_6_20 agecat_6_transf female_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model age_6_20 = agecat_1_transf agecat_6_transf female_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model agecat_6_transf = agecat_1_transf age_6_20 female_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model female_transf = agecat_1_transf age_6_20 agecat_6_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model black_transf = agecat_1_transf age_6_20 agecat_6_transf female_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model hispanic_transf = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model rural_transf = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model suburban_transf = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf rural_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model bls_transf = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf rural_transf suburban_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model als_transf = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf transport_transf_20 response_transf_20 transfer_transf size_quintile counties;
	model transport_transf_20 = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf response_transf_20 transfer_transf size_quintile counties;
	model response_transf_20 = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 transfer_transf size_quintile counties;
	model transfer_transf = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 size_quintile counties;
	model size_quintile = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf counties;
	model counties = agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf rural_transf suburban_transf bls_transf als_transf transport_transf_20 response_transf_20 transfer_transf size_quintile;
RUN;

*fully adjusted linear model 
	(violates assumptions of homogeneity of variance 2/2 midaz_prop proportions are extreme, 
	multicolinearity because change in one proportion implies change in another);
PROC REG DATA=nemsis.poisson_linear_transformed;
	MODEL midaz_prop = yearnum calls_transf_decr_1000 
		agecat_1_transf  age_6_20 /*agecat_4_transf agecat_5_transf*/ agecat_6_transf
		/*male_transf*/ female_transf 
		/*white_transf*/ black_transf /*race_other_transf*/
		hispanic_transf /*not_hispanic_transf*/
		rural_transf suburban_transf /*urban_transf wilderness_transf*/
		bls_transf als_transf /*air_transf service_level_other_transf*/
		transport_transf_20 /*role_other_transf*/
		response_transf_20 transfer_transf /*service_type_other_transf*/
		size_quintile counties
			/ clb;
	TITLE "linear regression of predictors (absolute increase in proportion of ___ patients by 10%) on proportion of midazolam use by agencies, adjusted for year and call volume";
RUN;


***************************************************************************************
multivaraite logistic regression
***************************************************************************************;

*multivariate logistic regression, fully adjusted;
PROC LOGISTIC DATA=nemsis.poisson_linear_transformed DESCENDING;
	CLASS midaz_cat (ref=first) ;
	MODEL midaz_cat = yearnum calls_transf_decr_1000 
		agecat_1_transf  age_6_20 /*agecat_4_transf agecat_5_transf*/ agecat_6_transf
		/*male_transf*/ female_transf 
		/*white_transf*/ black_transf /*race_other_transf*/
		hispanic_transf /*not_hispanic_transf*/
		rural_transf suburban_transf /*urban_transf wilderness_transf*/
		bls_transf als_transf /*air_transf service_level_other_transf*/
		transport_transf_20 /*role_other_transf*/
		response_transf_20 transfer_transf /*service_type_other_transf*/
		size_quintile counties  ;
	TITLE "Multivariate logistic regression of midazolam use category by continuous covariates (proportions in agencies)";
RUN;


*multivariate logistic regression with service level categories, fully adjusted;
PROC LOGISTIC DATA=nemsis.poisson_linear_transformed DESCENDING;
	CLASS midaz_cat (ref=first) urbanicity (ref=first) service_level_max (ref=first) transport (ref=last) /*service_type (ref=last)*/ response (ref=first);
	MODEL midaz_cat = yearnum calls_transf_decr_1000 
		agecat_1_transf  age_6_20 /*agecat_4_transf agecat_5_transf*/ agecat_6_transf
		/*male_transf*/ female_transf 
		/*white_transf*/ black_transf /*race_other_transf*/
		hispanic_transf /*not_hispanic_transf*/
		urbanicity /*rural_transf suburban_transf urban_transf wilderness_transf*/
		service_level_max
		transport
		/*service_type*/ response
		size_quintile counties  ;
	TITLE "Multivariate logistic regression of midazolam use category by continuous covariates (proportions in agencies)";
RUN;

*looking for dose-response for proportion of agency's call that are urban;
PROC LOGISTIC DATA=nemsis.poisson_linear_transformed DESCENDING;
	CLASS midaz_cat (ref=first) service_level_max (ref=first) transport (ref=last) /*service_type (ref=last)*/ response (ref=first);
	MODEL midaz_cat = yearnum calls_transf_decr_1000 
		agecat_1_transf  age_6_20 /*agecat_4_transf agecat_5_transf*/ agecat_6_transf
		/*male_transf*/ female_transf 
		/*white_transf*/ black_transf /*race_other_transf*/
		hispanic_transf /*not_hispanic_transf*/
		urban_transf
		service_level_max
		transport
		/*service_type*/ response
		size_quintile counties  ;
	TITLE "Multivariate logistic regression of midazolam use category by continuous covariates (proportions in agencies)";
RUN;

*multinomial logisit regression;
	*b/c may not be able to assume jump from none to some to most to all is "ordered";
PROC GLIMMIX DATA=nemsis.poisson_linear_transformed METHOD=laplace;
	CLASS agencyID midaz_cat urbanicity (ref=first) service_level_max (ref=first) transport (ref=last) response (ref=first);
	MODEL midaz_cat (ref="0") = yearnum calls_transf_decr_1000 agecat_1_transf  age_6_20 agecat_6_transf
		female_transf black_transf hispanic_transf urbanicity service_level_max transport response size_quintile counties 
			/ dist=multinomial link=glogit oddsratio cl solution;
	RANDOM intercept / subject=agencyID group=midaz_cat;
	TITLE "hierarchical multinomial logistic regression of midazolam use category by agency-level factors";
RUN;
*non hierarchical model: basically same ORs, and shows CIs;
PROC LOGISTIC DATA=nemsis.poisson_linear_transformed DESCENDING;
	CLASS agencyID midaz_cat urbanicity (ref=first) service_level_max (ref=first) transport (ref=last) response (ref=first);
	MODEL midaz_cat (ref="0") = yearnum calls_transf_decr_1000 agecat_1_transf  age_6_20 agecat_6_transf
		female_transf black_transf hispanic_transf urbanicity service_level_max transport response size_quintile counties 
			/ link=glogit;
	TITLE "multinomial logistic regression of midazolam use category by agency-level factors";
RUN;


*finding N for each category;
proc freq data=nemsis.poisson_linear_transformed;
	TABLE midaz_cat urbanicity service_level_max transport response;
	WHERE service_level_max NE . and agecat_1_transf NE . and age_6_20 NE . and agecat_6_transf NE . and female_transf NE . and black_transf NE . and hispanic_transf NE .;
RUN;

PROC MEANS DATA=nemsis.poisson_linear_transformed;
	VAR agecat_1_transf age_6_20 agecat_6_transf female_transf black_transf hispanic_transf calls_transf_decr_1000 size_quintile counties;
	WHERE service_level_max NE . and agecat_1_transf NE . and age_6_20 NE . and agecat_6_transf NE . and female_transf NE . and black_transf NE . and hispanic_transf NE .;
RUN;


*regression on actual annual change in midazolam use;
PROC GLM DATA=nemsis.midaz_change;
	CLASS midaz_cat urbanicity (ref=first) service_level_max (ref=first) transport (ref=last) response (ref=first);
	MODEL midaz_cat = calls_transf_decr_1000 
		agecat_1_transf  age_6_20_transf  agecat_6_transf
		female_transf 
		black_transf /*race_other_transf*/
		hispanic_transf 
		urbanicity
		service_level_max
		transport
		response
		size_quintile counties /solution clparm;
	WHERE years_sz_rep =5;
	TITLE "linear logistic regression of annual CHANGE in midazolam use by agency-level factors";
RUN;

PROC LOGISTIC DATA=nemsis.midaz_change DESCENDING;
	CLASS midaz_cat (ref=first) urbanicity (ref=first) service_level_max (ref=first) transport (ref=last) response (ref=first);
	MODEL midaz_cat = calls_transf_decr_1000 
		agecat_1_transf  age_6_20_transf  agecat_6_transf
		female_transf 
		black_transf 
		hispanic_transf 
		urbanicity
		service_level_max
		transport
		response
		size_quintile counties / link=glogit;;
	WHERE years_sz_rep >1;
	TITLE "multinomial logistic regression of annual CHANGE in midazolam use category by agency-level covariates";
RUN;



********************************************************
********************************************************
Secondary Outcome Analysis
********************************************************
********************************************************;

************************************
Rescue Therapy
***********************************;

*overall frequency of rescue therapy by year;
PROC FREQ DATA=nemsis.complete;
	TABLE Rescue*yearnum / norow nopercent chisq;
	TITLE "Frequency of Rescue Therapy for all benzodiazepines by year, complete dataset";
RUN;

*Frequency of Rescue Therapy by benzodiazepine;
PROC SORT DATA=nemsis.complete; BY Midazolam; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE Rescue*yearnum / norow nopercent chisq;
		BY Midazolam;
	TITLE "Frequency of Rescue Therapy by year for different benzodiazepines, complete dataset";
RUN;

*chi-square for difference in rates of rescue therapy before and after RAMPART;
PROC SORT DATA=nemsis.complete; BY Midazolam; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE Rescue*post_RAMPART / norow nopercent chisq;
	TITLE "Frequency of Rescue Therapy before and after RAMPART, complete dataset";
RUN;

*chi-square for difference in rates of rescue therapy between midaz and other benzos (all years);
PROC SORT DATA=nemsis.complete; BY Midazolam; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE Rescue*midazolam / norow nopercent chisq;
	TITLE "Frequency of Rescue Therapy for different benzodiazepines, complete dataset";
RUN;


******hierarchical models for rescue therapy********;

*creating unadjusted proportions for hierarchical model table;
%MACRO proportions (predictor, out);
PROC SORT DATA=nemsis.complete; BY &predictor; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE rescue / out=&out;
	BY &predictor;
	TITLE "rescue therapy by categorical predictors";
RUN;
%MEND;
%proportions (post_RAMPART, rescue_rampart);
%proportions (midazolam, rescue_agecat);
%proportions (agecat, rescue_agecat);
%proportions (E06_11new, rescue_gender);
%proportions (race, rescue_race);
%proportions (E06_13new, rescue_ethnicity);
%proportions (USCensusRegion, rescue_censusregion);
%proportions (Urbanicity, rescue_urbanicity);
%proportions (service_level, rescue_servicelevel);
%proportions (primary_role, rescue_primaryrole);
%proportions (Type_service, rescue_servicetype);
%proportions (size_quintile, rescue_sizequintile);

*Model 0: rescue (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID;
	MODEL rescue (ref=first) = / dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "model 0: intercept only model, limited to non-missing observations for low missingness covariates";
	TITLE "model 0: rescue = (agencyID)";
RUN;

*Model 1: rescue = midazolam (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID;
	MODEL rescue (ref=first) = midazolam / dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 1: unadjusted impact of using midazlam (v. other benzo), limited to non-missing observations for low missingness covariates";
	TITLE "Model 1: rescue = midazolam (Agency)";
RUN;

*Model 2: rescue = midazolam + year_granular + interaction (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID;
	MODEL rescue (ref=first) = midazolam year_granular midazolam*year_granular / dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 2:  Unadjusted impact of interaction between midazolam and time, limited to non-missing observations for low missingness covariates";
	TITLE "Model 2: rescue = midazolam + year_granular + interaction (Agency)";
RUN;

*Model 3: rescue = midazolam + year_granular + interaction + studymonth + demographics (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban");
	MODEL rescue (ref=first) = midazolam year_granular midazolam*year_granular agecat E06_11new USCensusRegion Urbanicity
		/ dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 3: Impact of midazolam, adjusted for demographic covariates, limited to non-missing observations for low missingness covariates";
	TITLE "Model 3: rescue = midazolam + year_granular + interaction + demographics (Agency)";
	TITLE "excludes race/ethnicity due to high missingness";
RUN;

*Model 4: rescue = midazolam + year_granular + interaction + studymonth + demographics + agency factors (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") primary_role (ref=first) type_service (ref=first) size_quintile (ref=first);
	MODEL rescue (ref=first) = midazolam year_granular midazolam*year_granular agecat E06_11new USCensusRegion Urbanicity primary_role type_service size_quintile
		/ dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 4: Impact of midazolam use, adjusted for demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates";
	TITLE "Model 4: rescue = midazolam + year_granular + interaction + demographics + agency factors (Agency)";
	TITLE "excludes race/ethnicity/service level due to high missingness";
RUN;


************************************
Airway
***********************************;

*overall frequency of airway by year;
PROC FREQ DATA=nemsis.complete;
	TABLE airway*yearnum / norow nopercent chisq;
	TITLE "Frequency of airway for all benzodiazepines by year, complete dataset";
RUN;

*Frequency of airway by benzodiazepine;
PROC SORT DATA=nemsis.complete; BY Midazolam; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE airway*yearnum / norow nopercent chisq;
		BY Midazolam;
	TITLE "Frequency of airway by year for different benzodiazepines, complete dataset";
RUN;

*chi-square for difference in rates of airway interventions before and after RAMPART;
PROC SORT DATA=nemsis.complete; BY Midazolam; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE Airway*post_RAMPART / norow nopercent chisq;
	TITLE "Frequency of Airway intervention before and after RAMPART, complete dataset";
RUN;

*chi-square for difference in rates of airway interventions between midaz and other benzos (all years);
PROC SORT DATA=nemsis.complete; BY Midazolam; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE airway*midazolam / norow nopercent chisq;
	TITLE "Frequency of Airway interventions for different benzodiazepines, complete dataset";
RUN;

******hierarchical models for airway********;

*creating unadjusted proportions for hierarchical model table;
%MACRO proportions_a (predictor, out);
PROC SORT DATA=nemsis.complete; BY &predictor; RUN;
PROC FREQ DATA=nemsis.complete;
	TABLE airway / out=&out;
	BY &predictor;
	TITLE "airway procedures by categorical predictors";
RUN;
%MEND;
%proportions_a (post_RAMPART, airway_rampart);
%proportions_a (midazolam, airway_agecat);
%proportions_a (agecat, airway_agecat);
%proportions_a (E06_11new, airway_gender);
%proportions_a (race, airway_race);
%proportions_a (E06_13new, airway_ethnicity);
%proportions_a (USCensusRegion, airway_censusregion);
%proportions_a (Urbanicity, airway_urbanicity);
%proportions_a (service_level, airway_servicelevel);
%proportions_a (primary_role, airway_primaryrole);
%proportions_a (Type_service, airway_servicetype);
%proportions_a (size_quintile, airway_sizequintile);

*Model 0: airway (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID;
	MODEL airway (ref=first) = / dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "model 0: intercept only model, limited to non-missing observations for low missingness covariates";
	TITLE "model 0: airway = (agencyID)";
RUN;

*Model 1: airway = midazolam (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID;
	MODEL airway (ref=first) = midazolam / dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 1: unadjusted impact of using midazlam (v. other benzo), limited to non-missing observations for low missingness covariates";
	TITLE "Model 1: airway = midazolam (Agency)";
RUN;

*Model 2: airway = midazolam + year_granular + interaction (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID;
	MODEL airway (ref=first) = midazolam year_granular midazolam*year_granular / dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 2:  Unadjusted impact of interaction between midazolam and time, limited to non-missing observations for low missingness covariates";
	TITLE "Model 2: airway = midazolam + year_granular + interaction (Agency)";
RUN;

*Model 3: airway = midazolam + year_granular + interaction + studymonth + demographics (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban");
	MODEL airway (ref=first) = midazolam year_granular midazolam*year_granular agecat E06_11new USCensusRegion Urbanicity
		/ dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 3: Impact of midazolam, adjusted for demographic covariates, limited to non-missing observations for low missingness covariates";
	TITLE "Model 3: airway = midazolam + year_granular + interaction + demographics (Agency)";
	TITLE "excludes race/ethnicity due to high missingness";
RUN;

*Model 4: airway = midazolam + year_granular + interaction + studymonth + demographics + agency factors (Agency);
PROC GLIMMIX DATA=nemsis.complete METHOD=laplace;
	CLASS agencyID agecat (ref=first) E06_11new (ref=first) USCensusRegion (ref="Northeast") Urbanicity (ref="Urban") primary_role (ref=first) type_service (ref=first) size_quintile (ref=first);
	MODEL airway (ref=first) = midazolam year_granular midazolam*year_granular agecat E06_11new USCensusRegion Urbanicity primary_role type_service size_quintile
		/ dist=binary link=logit ddfm=bw oddsratio cl solution;
	Random intercept / subject=agencyID solution cl;
	WHERE lowmiss_cov_nomiss = 1;
	TITLE "Model 4: Impact of midazolam use, adjusted for demographic covariates, and agency covaraites, limited to non-missing observations for low missingness covariates";
	TITLE "Model 4: airway = midazolam + year_granular + interaction + demographics + agency factors (Agency)";
	TITLE "excludes race/ethnicity/service level due to high missingness";
RUN;



*graphs of secondary outcomes;
PROC FREQ DATA=nemsis.complete;
	TABLE year_granular*rescue*midazolam / noprint outpct out=nemsis.rescue_midazolam_freq;
	TABLE year_granular*airway*midazolam / noprint outpct out=nemsis.airway_midazolam_freq;
	TITLE "frequency of benzo usage by month--esp. diazepam, based on agency complete";
RUN;

PROC FREQ DATA=nemsis.complete;
	TABLE studymonth*rescue*midazolam / norow nopercent;
	TABLE studymonth*airway*midazolam / norow nopercent;
	WHERE studymonth = 1 or studymonth = 60;
	TITLE "frequency of benzo usage by month--esp. diazepam, based on agency complete";
RUN;

PROC SGPLOT DATA=nemsis.rescue_midazolam_freq;
	SCATTER x = year_granular y = PCT_COL / group=midazolam;
	REG x = year_granular y = PCT_COL / group=midazolam cli clm;
	WHERE rescue = 1;
	TITLE "rescue therapy by Study Month";
RUN;

PROC SGPLOT DATA=nemsis.airway_midazolam_freq;
	SCATTER x = year_granular y = PCT_COL / group=midazolam;
	REG x = year_granular y = PCT_COL / group=midazolam cli clm;
	WHERE airway = 1;
	TITLE "airway interventions by Study Month";
RUN;
