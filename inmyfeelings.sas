
/*
________________________________________________________________________________________


									IN MY FEELINGS (REMIX)

________________________________________________________________________________________


		   Only edits needed are at the very bottom when calling the remix macro

					
																						*/


data _all;	     	/*creating base dataset*/
length STUDY $8. DATASETS VARS OBS 8. PATH $200.;       	/*setting length of PID*/
set _null_;
STUDY='';
DATASETS=.;
VARS =.;
OBS =.;
PATH ='';

run;
/* Original Macro dealt with just SAS files. Run the Remix for SAS or CSV
%macro inmyfeelings (STUDY,PATH);

			libname lib "&PATH";

 
			ods output members=memout;
			proc datasets details library=lib memtype=data;
			contents data=_all_ nods;
			run;
			quit;

			proc summary data=memout;
			format obs vars 8.;
			var Obs vars;
			output out=totals sum=;
			run;

			data &STUDY.;

			length STUDY $8. VARS OBS 8. PATH $200.;
			set totals;
			drop _freq_ _type_;
			STUDY="&STUDY.";
			PATH="&PATH.";
			run;


			proc append base=ALL data=&STUDY. force; run;              	       	appending all datasets together
			    	   run;

%mend;
*/


options validmemname=extend validvarname=any;

/*from the internet - to fix bad name of excel doc. this macro is called within francis.*/
%macro fixname(badname); 
    %if %datatyp(%qsubstr(&badname,1,1))=NUMERIC 
         %then %let badname=_&badname;
    %let badname=
         %sysfunc(compress(
             %sysfunc(translate(&badname,_,%str( ))),,kn));
    %substr(&badname,1,%sysfunc(min(%length(&badname),32)))
%mend fixname;


/*both francis and fixname allow for conversion of non-SAS files (csv, xls, xlsx) to SAS. 
	fixname is called within francis; francis is called within Remix.*/
%macro francis (dir);

%do i=1 %to &dnum;


  	%let name&i=%sysfunc(dread(&did,&i));

 			proc import datafile = "&dir\%qsysfunc(dread(&did,&i))"
			DBMS = &EXT. OUT = super.%fixname(%qscan(%qsysfunc(dread(&did,&i)),1,.)) replace; 
			datarow=2;
			getnames=yes;
			guessingrows=max;
			
			run;
	
%end;
%mend;

%macro remix (STUDY, PATH, EXT);

options DLCREATEDIR=1; 
libname super "%sysfunc(pathname(work,L))/subfolderinwork"; /*from the internet. creating a subfolder in temp workfolder in SAS. 
							Wanted a seperate temp folder for when we convert files to sas as to not to co-mingle with the memeout files created
							https://communities.sas.com/t5/SAS-Procedures/create-sub-folder-in-work/td-p/214934*/

%if &EXT=SAS %then %do;

libname lib "&PATH";

 
			ods output members=memout;
			proc datasets details library=lib memtype=data;
			contents data=ignore nods;
			run;
			quit;

			proc summary data=memout;
			format obs vars 8.;
			var Obs vars;
			output out=totals sum=;
			run;

			data &STUDY.;

			length STUDY $8. _FREQ_ VARS OBS 8. PATH $200.;
			set totals;
			drop _type_;
			STUDY="&STUDY.";
			PATH="&PATH.";
			rename _freq_=DATASETS;

			run;


			proc append base=_ALL data=&STUDY. force; run;              	       	/*appending all datasets together*/
			    	   run;
			proc print data=_all;
			run;
%end;
%else /*%if &EXT=CSV %then*/ %do;

			proc datasets library=super kill; /*killing the super library in case other files reside there from previous conversions;
												this way things don't get duplicated*/
			run;
			quit;


			%let rc=%sysfunc(filename(rawdata,"&PATH")); /*these sysfuncs are needed to run francis*/
			%let did=%sysfunc(dopen(&rawdata));
			%let dnum=%sysfunc(dnum(&did));

			%francis (&PATH.);
		
  			ods output members=memout;
			proc datasets details library=super memtype=data;
			contents data=ignore nods;
			run;
			quit;

			proc summary data=memout;
			format obs vars 8.;
			var Obs vars;
			output out=totals sum=;
			run;

			

			data &STUDY.;
			length STUDY $8. _freq_ VARS OBS 8. PATH $200.;
			set totals;
			drop _type_;
			STUDY="&STUDY.";
			PATH="&PATH.";
			rename _freq_=DATASETS;
			run;


			proc append base=_ALL data=&STUDY. force; run;              	       	/*appending all datasets together*/
			    	   run;
			proc print data=_all;
			run;
%end;
%mend;


/*
NOTES:
				%remix (STUDY,filepath,TYPE)

- Follow the example structure below to call remix macro; file type should be in all caps.
- When running for the first time, run the entire code plus first line of remix
- For second line onward, just highlight the new addition and run the selection */

%remix (POI,D:\Submissions by Users\POI\POI Data Transmission 20180215\StudyData, XLSX);

%remix (ATN086,D:\DM Thumb Drive\Dina Backup 20170719\ATN\ATN086\_working data\CSV, CSV);
%remix (ATN086,D:\DM Thumb Drive\Dina Backup 20170719\ATN\ATN086\_working data\SAS, SAS);


%remix (ATN114,D:\DM Thumb Drive\Dina Backup 20170719\ATN\ATN114\_working data\CSV, CSV);

%remix (ATN114,D:\DM Thumb Drive\Dina Backup 20170719\ATN\ATN114\_working data\SAS, SAS);



	