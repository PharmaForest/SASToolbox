/*** HELP START ***//*

`%IncludeAll` is a macro to include all .sas file(s) in specified direcotry and its sub-direcotries.

### Parameters

	- i_dir_path             : (Positional, Required)Full path of directory where .sas files to be included stored
	- i_is_recursive =       : (Keyword, Optional)Flag to specify if .sas files in sub-directories of "i_dir_path" will be included or not
	- i_exc_dirname_regex =  : (Keyword, Optional)Regular expression for directory name to be excluded.
	- i_exc_filename_regex = : (Keyword, Optional)Regular expression for file name(without extension) to be excluded.
	- i_leading_files =      : (Keyword, Optional)List of files to be included preferentially
	- i_trailing_files =     : (Keyword, Optional)List of files to be included lastly
	- i_is_verbose =         : (Keyword, Optional)Flag of verbose log (defulat: 0)
	- i_is_debug_mode =      : (Keyword, Optional)Flag of debug mode (default: 0))

### Sample code

1. Including all .sas file(s) in "/tmp/source" and its sub-direcotries.
~~~sas
%IncludeAll(/tmp/source)
~~~

2. Including all .sas file(s) in "/tmp/source" (not in sub-direcotries).
~~~sas
%IncludeAll(/tmp/source
              , i_is_recursive = 0)
~~~

3. Including all .sas file(s) in "/tmp/source" but sub-direcotries whose name begins with "test_" are excluded.
~~~sas
%IncludeAll(/tmp/source
              , i_exc_dirname_regex = /^test_/)
~~~

4. Including all .sas file(s) in "/tmp/source" and in sub-direcotries but its file name ends with "_bk" are excluded.
~~~sas
%IncludeAll(/tmp/source
              , i_exc_filename_regex = /_bk$/)
~~~

5. Including all .sas file(s) in "/tmp/source" and in sub-direcotries but its directory name starts with "test_" are excluded.
~~~sas
%IncludeAll(/tmp/source
              , i_exc_filename_regex = /^test_/)
~~~

6. Including all .sas file(s) in "/tmp/source" and in sub-direcotries.
.sas file "first.sas" will be included first and .sas file "last1.sas" and "last2.sas" will be included last.
~~~sas
%IncludeAll(/tmp/source
              , i_leading_files = /tmp/source/first.sas
				  , i_trailing_files = /tmp/source/last1.sas|/tmp/source/last2.sas)
~~~

7. Including all .sas file(s) in "/tmp/source" and in sub-direcotries. Verbose log will be output.
~~~sas
%IncludeAll(/tmp/source
              , i_is_verbose = 1)
~~~

8. Including all .sas file(s) in "/tmp/source" with DEBUG mode(RELEASE code will be commented out when including).
Note: When "i_is_debug_mode" is omitted, DEBUG code will be commented out(it is treated as RELEASE mode)
~~~sas
%IncludeAll(/tmp/source
              , i_is_debug_mode = 1)
~~~

*//*** HELP END ***/



/*===================================================================================*/
/* IncludeAll
/*
/* Description
/*    指定ディレクトリ内（サブディレクトリも含む）の .sas ファイルを一括インクルードします
/*
/* Arguments
/*    i_dir_path           : （必須）読み込み対象ディレクトリパス）
/*    i_is_recursive       : （オプション）サブディレクトリも読み込むか否か（デフォルト: 1）
/*    i_exc_dirname_regex  : （オプション）除外ディレクトリ名フィルタ（正規表現）
/*    i_exc_filename_regex : （オプション）除外ファイル名フィルタ（拡張子を覗いた部分に対する正規表現）
/*    i_leading_files      : （オプション）優先読込ファイルリスト（'|' 区切りで複数指定可）
/*    i_trailing_files     : （オプション）劣後読込ファイルリスト（'|' 区切りで複数指定可）
/*    i_is_verbose         : （オプション）冗長ログ出力フラグ（デフォルト：0）
/*    i_is_debug_mode      : （オプション）デバッグモードフラグ（デフォルト：0）
/*===================================================================================*/
%macro IncludeAll(i_dir_path
                  , i_is_recursive = 1
                  , i_exc_dirname_regex =
                  , i_exc_filename_regex =
                  , i_leading_files =
                  , i_trailing_files =
                  , i_is_debug_mode = 0
                  , i_is_verbose = 0);
   /* Step1. Preparation */
   %local _path_separator;
   %if (%upcase(&sysscpl.) = LINUX) %then %do;
      %let _path_separator = /;
   %end;
   %else %do;
      %let _path_separator = \;
   %end;
   %local _dir_path_in_message;
   %if (&i_is_recursive.) %then %do;
      %let _dir_path_in_message = "&i_dir_path." and sub-directories;
   %end;
   %else %do;
      %let _dir_path_in_message = "&i_dir_path.";
   %end;
   %local _mode;
   %if (&i_is_debug_mode.) %then %do;
      %let _mode = DEBUG;
   %end;
   %else %do;
      %let _mode = RELEASE;
   %end;
   %local _exc_dir_regex;
   %let _exc_dir_regex = &i_exc_dirname_regex.;
   %if (%sysevalf(%superq(i_exc_dirname_regex) =, boolean)) %then %do;
      %let _exc_dir_regex = <NONE>;
   %end;
   %local _exc_file_regex;
   %let _exc_file_regex = &i_exc_filename_regex.;
   %if (%sysevalf(%superq(i_exc_filename_regex) =, boolean)) %then %do;
      %let _exc_file_regex = <NONE>;
   %end;
   %put Including all .sas files in &_dir_path_in_message.;
   %put Includeing Mode                : &_mode.;
   %put Excluding Dirname filter regex : &_exc_dir_regex.;
   %put Excluding Filename filter regex: &_exc_file_regex.;

   /* Step2. Collecting .sas files */
   %local /readonly _TMPDS_INCLUDING_FILE_LIST_ = WORK.___SAS_FILE_LIST___;
   %local _no_of_sas_files;
   %local /readonly _TEMP_OPTIONS_DS = WORK._TEMP_OPTIONS_DS;
   %if (not &i_is_verbose.) %then %do;
      proc optsave out = &_TEMP_OPTIONS_DS.;
      run;
      quit;
      options nonotes;
   %end;
	%Prv_IAI__MakeSASFileList(i_dir_path = &i_dir_path.
                           , i_path_separator = &_path_separator.
                           , i_is_recursive = &i_is_recursive.
                           , i_exc_dirname_regex = &i_exc_dirname_regex.
                           , i_exc_filename_regex = &i_exc_filename_regex.
                           , i_leading_files = &i_leading_files.
                           , i_trailing_files = &i_trailing_files.
                           , ods_output_ds = &_TMPDS_INCLUDING_FILE_LIST_.
                           , ovar_no_of_sas_files = _no_of_sas_files)
	%if (1 <= &_no_of_sas_files.) %then %do;
   /* Step3. Including all files */
   	%put &_no_of_sas_files. .sas file(s) found in the directory.;
      %Prv_IAI__DoIncludingProcess(ids_files = &_TMPDS_INCLUDING_FILE_LIST_.
                                 , i_no_of_sas_files = &_no_of_sas_files.
                                 , i_including_mode = &_mode.
                                 , i_is_verbose = &i_is_verbose.)
	%end;
   %else %do;
		%put No .sas file found;
   %end;
	proc delete
		data = &_TMPDS_INCLUDING_FILE_LIST_.;
	run;
   %if (not &i_is_verbose.) %then %do;
      proc optload data = &_TEMP_OPTIONS_DS.(where = (upcase(optname) = 'NOTES'));
      run;
      quit;
	proc delete
		data = &_TEMP_OPTIONS_DS.;
	run;
   %end;
%mend IncludeAll;
