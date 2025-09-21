/*** HELP START ***//*

This macro copies folders under the specified folder and converts SAS datasets in ‘sas7bdat’ format within them to UTF-8 encoding.
Only files in the ‘sas7bdat’ format and the folder containing them will be copied. Other files and folders not containing SAS datasets will not be copied.
The copied files are output to a list containing table names, column information, column lengths, and other details. The list is output to the Work library by default, but you can also output it as a CSV file by specifying a filename as an option.

This macro program will only run in environments that meet the following conditions.
・SAS 9.4 running on Japanese Windows
・SAS 9.4 uses Unicode encoding with LOCALE=JA_JP

### Parameters
- directory_path : Specify the full path to the directory where the data to be converted is stored.
- transcode_dir_path : Specify the full path to the folder where the converted data and folder structure will be placed.
- compress_yn : Specifies whether to perform the conversion process using the compress option. The default is ‘y’. Specifying a value other than ‘y’ will not use compress.
- contents_yn : Specify whether to output the results list to a CSV file.If you specify anything other than ‘n’, a CSV file will be saved directly under the folder specified in ‘transcode_dir_path’, using the specified value as the filename.
- length_obs : Specifies whether to obtain the maximum length of the actual data for character variables contained in the converted data. In the case of ‘n’, the process to obtain the maximum data length is not performed. If a number is specified, the maximum length is checked up to that number of rows. When ‘MAX’ is specified, the maximum length is checked for all rows.

### Sample code
Execute by specifying only the target directory.
%trancd2u8_d(D:\SASPSD\SASPJ-93\SASData);

Output the converted results to the ‘result.csv’ file.
%trancd2u8_d(D:\SASPSD\SASPJ-93\SASData,D:\SASPSD\SASPJ-93\SASData_UTF8,contents_yn=result.csv);

Determine the actual length of the converted character variable for all records and obtain the maximum length.
%trancd2u8_d(D:\SASPSD\SASPJ-93\SASData,D:\SASPSD\SASPJ-93\SASData_UTF8,length_obs=MAX);

*//*** HELP END ***/


%macro trancd2u8_d(directory_path, transcode_dir_path, compress_yn=y, contents_yn=n, length_obs=n);
*Initialization of Macro Variables;
/*
%global directory_path transcode_dir_path compress_yn contents_yn length_obs;
*/
*options mprint;
options validvarname=any ;run;
options validmemname=extend;run;

/********************* Processing when no destination directory is specified ************************/
%if %bquote(&transcode_dir_path.)= %then %do;
   %let transcode_dir_path=%bquote(&directory_path.)_u8;
%end;

/***************** compressUsage determination *******************/
%macro mac01;
%if &compress_yn.=y %then %do;
   options compress=yes;
%end;
%mend mac01;
%mac01;

/********** Getting the folder list **********/
*Getting the contents list;
data _null_;
   length dirlist_com $273.;
   dirlist_com="'dir /s /b "||'"'||"&directory_path."||'"'||"'";
   call symput('dirlist_com',dirlist_com);
run;
%put &dirlist_com.;

filename dirlist pipe &dirlist_com.;
data filelist;
   infile dirlist truncover;
    input fullpath $256.;
	item=scan(fullpath,countw(fullpath,"\"),"\");
run;

*Extract only records containing .sas7bdat from the content list and get that folder path;
data sas7bdatlist;
   set filelist;
   length folderpath $256.;
   if scan(item,2,'.')='sas7bdat' then do;
      folderpath=substr(fullpath,1,length(fullpath)-length(item)-1);
      output ;
	end;
run;

/******* Create a list of new and old folders to be processed *******/
proc sql;
   create table work.folderpathlist as 
   select distinct t1.folderpath, 
          /* trans_folderpath */
            (tranwrd(t1.folderpath,"&directory_path.","&transcode_dir_path.")) length=256 as trans_folderpath
      from work.sas7bdatlist t1;
quit;

/**************** Create New Folders ****************/
options noxwait;
data _null_;
   set work.folderpathlist(keep=trans_folderpath);
   length mkdir_cmd $264.;
   mkdir_cmd="mkdir "||'"'||trim(trans_folderpath)||'"';
   call system(mkdir_cmd);
run;

/**************Submacro Library Settings - Data transcoding and copying - Acquisition of Content Information **************/
%macro trancd2u8_d_s1(path,newpath,pathno);
*Library Settings;
libname inlib cvp "&path." access=readonly;
libname inlib2 "&path." access=readonly;
libname outlib "&newpath." outencoding='utf8';
;
*Data transcoding and copying;
proc copy noclone in=inlib out=outlib;
   select : ; *: mean select all sas files;
run;

* Acquisition of Content Information;
*Original Data Content Information;
*ods trace on / listing;
ods output EngineHost=work.orgtable_info0_&pathno.;
proc contents data=inlib2._all_ out=orgcolumn_info_&pathno.(keep=memname name type length);
run;
ods output close;
data orgtable_info_&pathno.(keep=memname filesize_org);
   set orgtable_info0_&pathno.;
   length memname $32. filesize_org $44.;
   memname=substr(member,8,length(member));
   if label1='ファイルサイズ (バイト)' then do;
      filesize_org=cvalue1;
      output;
   end;
run;

*Converted Data Content Information;
*ods trace on / listing;
ods output EngineHost=work.newtable_info0_&pathno.;
proc contents data=outlib._all_ out=newcolumn_info_&pathno.(keep=memname memlabel varnum name label type length label format informat nobs engine crdate);
run;
ods output close;


data newtable_info_&pathno.(keep=memname host filesize_new);
   set newtable_info0_&pathno.;
   length memname $32. host  filesize_new $44.;
   memname=substr(member,8,length(member));
   retain host;
   if label1='作成したホスト' then host=cvalue1;
   else if label1='ファイルサイズ (バイト)' then do;
      filesize_new=cvalue1;
      output;
	  host=' ';
   end;
run;

*Verifying the actual data length;
%if &length_obs. ne n %then %do;
   proc sort data=newcolumn_info_&pathno.(where=(type=2) keep=memname name type varnum) out=column_info2_&pathno.;
      by memname varnum;
   run;

   *Output processing programs to external files;
   data _null_;
      set column_info2_&pathno. end=eof;
      file "&transcode_dir_path.\getlength.sas";
      by memname varnum;
      length columnlist $2048. memno 8.;
      retain columnlist memno;
      if memno=. then memno=0;
      if first.memname then do;
         columnlist=name;
   	  memno=memno+1;
   	  put 'proc sql;';
	  put '   create table work.max_varlength_' memno +(-1) ' as';
	  put '   select';
      end;
      else columnlist=trim(columnlist)||' '|| trim(name);
       put '      (MAX(length(t1.' name ' ))) as '  name ',';
      if last.memname then do;
         put '"' memname +(-1) '"'  ' as  memname';
         put 'from outlib.'  memname  ' (keep='  columnlist   "obs= &length_obs."    ') t1;';
         put 'quit;';
         put 'proc transpose data=work.max_varlength_' memno +(-1) ' out=work.max_varlength_tran_' memno +(-1)  ';' ;
         put '   var _all_;' ;
         put '   by memname;' ;
         put 'run;' ;
      end;
      if eof then call symput('lastdatno',compress(put(memno,best.)));
   run;

   *Execute the SAS program generated in an external file;
   %include "&transcode_dir_path.\getlength.sas";
   *Delete the executed program file;
   data _null_;
       fname="tempfile";
       rc=filename(fname, "&transcode_dir_path.\getlength.sas");
       if rc = 0 and fexist(fname) then
          rc=fdelete(fname);
       rc=filename(fname);
   run;

   data work.max_varlength_path_&pathno.;
      length memname _NAME_ $32.;
      set work.max_varlength_tran_1 - work.max_varlength_tran_&lastdatno. ;
   run;
   *Deletion of Intermediate Dataset 1;
   proc datasets lib=work memtype=data;
      delete max_varlength_1 - max_varlength_&lastdatno.  max_varlength_tran_1 - max_varlength_tran_&lastdatno.;
   run;
   quit;

   data datlength_&pathno.;
      length memname name $32.;
   run; 
   data datlength_&pathno.(drop=_name_ col1);
      set work.max_varlength_path_&pathno.;
      length name $32. max_var_length 8.;
      if left(col1)=left(memname) then delete;
      name=_name_;
      max_var_length=input(col1,best.);
   run;
%symdel lastdatno;
%end;

*Merging New and Old Table Information;
data work.table_info_&pathno.;
run;
proc sql;
   create table work.table_info_&pathno. as 
   select
        "&path." as folderpath_org length=256 label='Original Data Path',
         "&newpath." as folderpath_new length=256 label='Transcoded Data Path',
         t2.memname label='Data Set Name', 
         t2.memlabel label='Data Set Label',
         t2.nobs label='Observations',
         t2.crdate label='Created',
         t2.varnum label='Variable Number',
         t2.name label='Variable Name', 
         t2.label label='Variable Label',
         t2.format label='Format',
         t2.informat label='InFormat',
         t2.type label='Variable Type', 
         t2.length label='Variable Length (Converted)', 
         t3.length as length_org label='Variable Length (Original)',
         %if &length_obs. ne n %then %do;
            t5.max_var_length label='Max Data Length',
         %end;
          t1.host label='Host Created',
          t1.filesize_new label='File Size (bytes) (Converted)', 
          t4.filesize_org label='File Size (bytes) (Original)'
      from work.newtable_info_&pathno. t1
          inner join work.newcolumn_info_&pathno. t2 on (t1.memname = t2.memname)
          inner join work.orgcolumn_info_&pathno. t3 on (t2.name = t3.name and t2.memname = t3.memname)
          inner join work.orgtable_info_&pathno. t4 on (t3.memname = t4.memname)
          %if &length_obs. ne n %then %do;
             left join work.datlength_&pathno. t5 on (t2.memname=t5.memname and t2.name=t5.name)
          %end;
         ;
quit;

*Initialization of the libname statement;
libname inlib;
libname inlib2;
libname outlib;
*Deletion of Intermediate Dataset 2;
proc datasets lib=work memtype=data;
   delete orgtable_info0_&pathno. orgtable_info_&pathno. orgcolumn_info_&pathno.  newtable_info0_&pathno. newtable_info_&pathno. newcolumn_info_&pathno. column_info2_&pathno. datlength_&pathno. max_varlength_path_&pathno.;
run;
quit;
%mend trancd2u8_d_s1;

/***************** Execute submacro ***************/
data _null_;
   set WORK.folderpathlist end=eof;
   obsno=_n_;
   call execute('%trancd2u8_d_s1(path='||folderpath|| ',newpath='||trans_folderpath||',pathno='||obsno||')');
   if eof then call symput('lastno',compress(put(obsno,best.)));
run;

data table_info;
   set table_info_1 - table_info_%left(&lastno.);
run;

*Deletion of Intermediate Dataset 3;
proc datasets  lib=work memtype=data;
   delete table_info_1 - table_info_%left(&lastno.);
run;
quit;

*Output the information of the converted dataset to a CSV file;
%if &contents_yn. ne n %then %do;
proc export data=table_info
   outfile="&transcode_dir_path.\&contents_yn."
   dbms=csv
   replace;
run;
%end;


%mend trancd2u8_d;

/***************************************** Program E N D *****************************************/
