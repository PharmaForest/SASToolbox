/*** HELP START ***//*

`%trancd2u8_d` is a macro to change encoding of dataset to UTF8.
 
### Parameters

	- directory_path     : directory path contains datasets to be processed.
	- transcode_dir_path : directory path where processed datasets will be stored.
	- compress_yn        : compress option
	- contents_yn        : ******
	- length_obs        : ******
 
### Sample code
 

*//*** HELP END ***/
%macro trancd2u8_d(directory_path,transcode_dir_path,compress_yn,contents_yn,length_obs);
*マクロ変数の初期化;
%global directory_path transcode_dir_path compress_yn contents_yn length_obs;

options validvarname=any ;run;
options validmemname=extend;run;
/********** フォルダリストの取得 **********/
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

*コンテンツリストの中から.sas7bdatのあるレコードのみを抽出;
data sas7bdatlist;
   set filelist;
   length folderpath $256.;
   if scan(item,2,'.')='sas7bdat' then do;
      folderpath=substr(fullpath,1,length(fullpath)-length(item)-1);
      output ;
	end;
run;

/******* 処理対象新旧フォルダリストに加工 *******/
PROC SQL;
   CREATE TABLE WORK.folderpathlist AS 
   SELECT DISTINCT t1.folderpath, 
          /* trans_folderpath */
            (tranwrd(t1.folderpath,"&directory_path.","&transcode_dir_path.")) LENGTH=256 AS trans_folderpath
      FROM WORK.SAS7BDATLIST t1;
QUIT;

/**************** 新フォルダ作成 ****************/
options noxwait;
data _null_;
   set WORK.folderpathlist(keep=trans_folderpath);
   length mkdir_cmd $264.;
   mkdir_cmd="mkdir "||'"'||trim(trans_folderpath)||'"';
   call system(mkdir_cmd);
run;

/**************サブマクロフォルダ毎の処理 ライブラリ設定 - データのトランスコードとコピー - コンテンツ情報の取得 **************/
%macro trancd2u8_d_s1(path,newpath,pathno);
*ライブラリ設定;
libname inlib cvp "&path." access=readonly;
libname inlib2 "&path." access=readonly;
libname outlib "&newpath." outencoding='utf8';
/*
　　%if "&compress_yn." not in ( 'n','N') %then compress=yes;
*/
   ;
*proc copy でデータセットファイルをコピー;
proc copy noclone in=inlib out=outlib;
   select : ; *: mean select all sas files;
run;

*元データコンテンツ情報取得;
ods trace on / listing;
ods output EngineHost=work.orgtable_info0_&pathno.;
proc contents data=inlib2._all_ out=orgcolumn_info_&pathno.(keep=memname name type length);
run;
ods output close;
data orgtable_info_&pathno.(keep=memname cvalue1 rename=(cvalue1=filesize_org));
   set orgtable_info0_&pathno.;
   length memname $32.;
   memname=substr(member,8,length(member));
   if label1='ファイルサイズ (バイト)' then output;
run;

*変換後データコンテンツ情報取得;
ods trace on / listing;
ods output EngineHost=work.newtable_info0_&pathno.;
proc contents data=outlib._all_ out=newcolumn_info_&pathno.(keep=memname memlabel varnum name label type length label format informat nobs engine crdate);
run;
ods output close;
data newtable_info_&pathno.(keep=memname cvalue1 rename=(cvalue1=filesize_new));
   set newtable_info0_&pathno.;
   length memname $32.;
   memname=substr(member,8,length(member));
   if label1='ファイルサイズ (バイト)' then output;
run;

data WORK.TABLE_INFO_&pathno.;
run;
PROC SQL;
   CREATE TABLE WORK.TABLE_INFO_&pathno. AS 
   SELECT t2.MEMNAME, 
         t2.MEMLABEL,
		 t2.NOBS,
		 t2.CRDATE,
		 t2.VARNUM,
          t2.NAME, 
		  t2.LABEL,
		  t2.FORMAT,
		  t2.INFORMAT,
          t2.TYPE, 
          t2.LENGTH, 
          t3.LENGTH AS LENGTH_org, 
          t1.filesize_new AS filesiz_new, 
          t4.filesize_org AS filesiz_org
      FROM work.NEWTABLE_INFO_&pathno. t1, work.NEWCOLUMN_INFO_&pathno. t2, work.ORGCOLUMN_INFO_&pathno. t3, 
          work.ORGTABLE_INFO_&pathno. t4
      WHERE (t1.memname = t2.MEMNAME AND t2.NAME = t3.NAME AND t3.MEMNAME = t4.memname AND t2.MEMNAME = t3.MEMNAME);
QUIT;



*マクロ終了処理;
*libnameステートメントの初期化;
libname inlib;
libname inlib2;
libname outlib;
*中間データセットの削除;
%mend trancd2u8_d_s1;

/***************** サブマクロの 処理を実行 ***************/
data _null_;
   set WORK.folderpathlist;
   obsno=_n_;
   call execute('%trancd2u8_d_s1(path='||folderpath|| ',newpath='||trans_folderpath||',pathno='||obsno||')');
run;

/***************** 処理を行ったテーブル情報をまとめる ***************/
data Table_info;
   set Table_info_1 - Table_info_45;
run;

%mend trancd2u8_d;
