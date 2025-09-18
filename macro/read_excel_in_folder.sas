/*** HELP START ***//*

`%Read_excel_in_folder` is a macro to import all excel files in the specified directory as individual SAS datasets in bulk.
Each excel file will be imported as a SAS dataset with the same name and saved in the work library.
If the filename exceeds 32 characters, that file will be skipped, but the others will be processed.

Note:
　Only the first sheet of each excel file will be imported.
 
### Parameters

	- path : Full path to the folder where the excel files are stored. The folder must contain only excel files.
 
### Sample code
 
All .xlsx file(s) to be imported exists in a folder of "/example/homes/SampleUser/SASPac/tmp1_excelFiles".
~~~sas
%Read_excel_in_folder(path="/example/homes/SampleUser/SASPac/tmp1_excelFiles")
~~~

*//*** HELP END ***/

%macro Read_excel_in_folder(path=);

filename dir1 &path;

data work.TableList;
    length Name $400;
    did = dopen('dir1');
    path_ = &path;
    if did > 0 then do;
        num = dnum(did);
        call symputx('FileNumber', num);
        do i = 1 to num;
            Name = catx("/", &path, dread(did, i));
            File = dread(did, i);
            output;
        end;
        rc = dclose(did);
    end;
    else putlog "ERROR";
run;

%do no = 1 %to &FileNumber;

data work.tmp1_&no;
	set work.TableList(where=(i=&no));
    call symput('Name', trim(Name));
    call symput('File', trim(File));
run;

%macro remove_ext(filename);
    %scan(&filename, 1, .);
%mend;

%let File_ = %remove_ext(&File);
%let File_ = %sysfunc(compress(&File_, ";"));

proc import datafile="&Name"
    out=&File_
    dbms=xlsx
    replace;
run;

proc delete data=work.tmp1_&no; run;

%end;

proc delete data=work.TableList; run;

%mend Read_excel_in_folder;


