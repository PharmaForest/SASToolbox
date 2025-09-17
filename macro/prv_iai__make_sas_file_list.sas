/*** HELP START ***//*

[Internal used only]
This macro is called from IncludeAllIn macro.

*//*** HELP END ***/
%macro Prv_IAI__MakeSASFileList(i_dir_path =
                              , i_path_separator =
                              , i_is_recursive =
                              , i_exc_dirname_regex =
                              , i_exc_filename_regex =
                              , i_leading_files =
                              , i_trailing_files =
                              , ods_output_ds =
                              , ovar_no_of_sas_files =);
	data &ods_output_ds.;
		attrib
			_entry_type length = $1.
			_entry_name length = $100.
			_entry_parent_path length = $1000.
			_entry_full_path length = $1000.
		;
		stop;
	run;
   quit;
	
   %Prv_IAI__GetContentsHelper(i_dir_path = &i_dir_path.
                              , i_path_separator = &i_path_separator.
                              , i_is_recursive = &i_is_recursive.
                              , ods_output_ds = &ods_output_ds.)
   /*
   /* 絞り込み
   /* - ファイルタイプ = 'F'
   /* - ".sas"で終わるファイル名（case insensitive）
   /* - （オプション） ディレクトリ名がフィルタ条件にマッチしないもの
   /* - （オプション） 拡張子を除いた部分に対するフィルタ条件にマッチしないもの
   */
   %let &ovar_no_of_sas_files. = 0;
   data &ods_output_ds.(keep = _entry_full_path _order);
      set &ods_output_ds. end = eof;
      retain index 0;
      _depth = count(_entry_parent_path, "&i_path_separator.");
      _parent_dir_name = scan(_entry_parent_path, -1, "&i_path_separator.");
      _file_name_body = scan(_entry_name, 1, '.');
   %if (not %sysevalf(%superq(i_exc_dirname_regex) =, boolean)) %then %do;
      _regex_exc_dirname = prxparse(symget('i_exc_dirname_regex'));
   %end;
   %if (not %sysevalf(%superq(i_exc_filename_regex) =, boolean)) %then %do;
      _regex_exc_filename = prxparse(symget('i_exc_filename_regex'));
   %end;

      if (_entry_type = 'F'
   %if (not %sysevalf(%superq(i_exc_dirname_regex) =, boolean)) %then %do;
         and not (2 <= _depth and prxmatch(_regex_exc_dirname, trim(_parent_dir_name)))
   %end;
   %if (not %sysevalf(%superq(i_exc_filename_regex) =, boolean)) %then %do;
         and not prxmatch(_regex_exc_filename, trim(_file_name_body))
   %end;
         ) then do;
         index = index + 1;
         _order = 0;
         output;   
      end;
      if (eof) then do;
         call symputx("&ovar_no_of_sas_files.", index);
      end;
   run;
   quit;
   
   %if (&&&ovar_no_of_sas_files. = 0) %then %do;
      %return;
   %end;

   /* 順番調整 */
   %if (not %sysevalf(%superq(i_leading_files) =, boolean)) %then %do;
   /* 優先読込ファイル */
      %local _leading_file_index;
      %local _leading_file_path;
      %local /readonly _NO_OF_LEADING_FILES = %sysfunc(count(&i_leading_files., |));
      %do _leading_file_index = 1 %to %eval(&_NO_OF_LEADING_FILES. + 1);
         %let _leading_file_path = %scan(&i_leading_files., &_leading_file_index., |);
         proc sql noprint;
            update &ods_output_ds.
            set _order = - (&_NO_OF_LEADING_FILES. + 2) + &_leading_file_index.
            where _entry_full_path = "&_leading_file_path.";
         quit;
      %end;
   %end;
   %if (not %sysevalf(%superq(i_trailing_files) =, boolean)) %then %do;
   /* 劣後読込ファイル */
      %local _trailing_file_index;
      %local _trailing_file_path;
      %local /readonly _NO_OF_trailing_FILES = %sysfunc(count(&i_trailing_files., |));
      %do _trailing_file_index = 1 %to %eval(&_NO_OF_trailing_FILES. + 1);
         %let _trailing_file_path = %scan(&i_trailing_files., &_trailing_file_index., |);
         proc sql noprint;
            update &ods_output_ds.
            set _order = &_trailing_file_index.
            where _entry_full_path = "&_trailing_file_path.";
         quit;
      %end;
   %end;
   proc sort data = &ods_output_ds;
      by
         _order
         _entry_full_path
      ;
   run;
   quit;
%mend Prv_IAI__MakeSASFileList;