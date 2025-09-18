/*** HELP START ***//*

[Internal used only]
This macro is called from Prv_IAI__MakeSASFileList macro.

*//*** HELP END ***/
%macro Prv_IAI__GetContentsHelper(i_dir_path =
                                 , i_path_separator =
                                 , i_is_recursive =
                                 , ods_output_ds =);
	%local _rc;
	%local _tmp_fileref_parent_dir;
   %let _rc = %sysfunc(filename(_tmp_fileref_parent_dir, &i_dir_path.));
	%local _did_parent_dir;
	%let _did_parent_dir = %sysfunc(dopen(&_tmp_fileref_parent_dir));	
	%local _no_of_entries_in_parent_dir;
	%let _no_of_entries_in_parent_dir = %sysfunc(dnum(&_did_parent_dir));

	%local _entry_name;
	%local _entry_path;
	%local _entry_index;
	%local _tmp_fileref_child_dir;
   /* ディレクトリに含まれる全オブジェクト（ファイル、ディレクトリ）についてループ  */
	%do _entry_index = 1 %to &_no_of_entries_in_parent_dir.;
		%let _entry_name = %qsysfunc(dread(&_did_parent_dir, &_entry_index));
		%let _entry_path = &i_dir_path.&i_path_separator.&_entry_name.;
      %let _rc = %sysfunc(filename(_tmp_fileref_child_dir, &_entry_path.));
		%let _did_child_dir = %sysfunc(dopen(&_tmp_fileref_child_dir.));	/* ディレクトリを開く */
		%if (0 < &_did_child_dir.) %then %do;
			/* オープン成功: このオブジェクトはディレクトリ */
			%let _rc = %sysfunc(dclose(&_did_child_dir.));
         %let _rc = %sysfunc(filename(_tmp_fileref_child_dir));
			%if (&i_is_recursive.) %then %do;
				/* 再帰呼び出し */
				%Prv_IAI__GetContentsHelper(i_dir_path = &_entry_path.
                                       , ods_output_ds = &ods_output_ds.
                                       , i_is_recursive = &i_is_recursive.
                                       , i_path_separator = &i_path_separator.)
			%end;
			proc sql noprint;
				insert into &ods_output_ds.(_entry_type, _entry_name, _entry_parent_path, _entry_full_path)
				values("D", "&_entry_name.", "&i_dir_path.", "&_entry_path.");
			quit;
		%end;
		%else %do;
			/* オープン失敗: このオブジェクトはファイル */
         %let _rc = %sysfunc(filename(_tmp_fileref_child_dir));
			proc sql noprint;
				insert into &ods_output_ds.(_entry_type, _entry_name, _entry_parent_path, _entry_full_path)
				values("F", "&_entry_name.", "&i_dir_path.", "&_entry_path.");
			quit;
		%end;
	%end;
	%let _rc = %sysfunc(dclose(&_did_parent_dir.));
   %let _rc = %sysfunc(filename(_tmp_fileref_parent_dir));
%mend Prv_IAI__GetContentsHelper;
