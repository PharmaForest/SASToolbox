/*** HELP START ***//*

[Internal used only]
This macro is called from IncludeAllIn macro.

*//*** HELP END ***/
%macro Prv_IAI__DoIncludingProcess(ids_files =
                                 , i_no_of_sas_files =
                                 , i_including_mode =
                                 , i_is_verbose =);
	%local _file_index;
	%do _file_index = 1 %to &i_no_of_sas_files.;
		%local _file_path_&_file_index.;
	%end;
	data _null_;
		set &ids_files.;
		call symputx(cats('_file_path_', _N_), _entry_full_path, 'L');
	run;
	quit;

   %local _lines;
	%local _entry_full_path;
	%do _file_index = 1 %to &i_no_of_sas_files.;
		%let _entry_full_path = &&&_file_path_&_file_index.;
      %if (&i_is_verbose.) %then %do;
         %put [&_file_index./&i_no_of_sas_files.] &_entry_full_path....Including;
      %end;
      %Prv_IAI__IncludeSASFile(i_sas_file = &_entry_full_path.
                              , i_including_mode = &i_including_mode.
                              , i_is_verbose = &i_is_verbose.
                              , ovar_lines = _lines)
      %put [&_file_index./&i_no_of_sas_files.] &_entry_full_path....Included(&_lines. lines);
	%end;
	%put &i_no_of_sas_files. .sas file(s) included.;
%mend Prv_IAI__DoIncludingProcess;