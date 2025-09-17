/*** HELP START ***//*

[Internal used only]
This macro is called from Prv_IAI__DoIncludingProcess macro.

*//*** HELP END ***/
%macro Prv_IAI__IncludeSASFile(i_sas_file =
                        , i_including_mode =
                        , i_is_verbose =
                        , ovar_lines =);
   %if (&i_is_verbose. = 1) %then %do;
      data WORK.__TEMP_MACROS_BEFORE_INC__(keep = created objname rename = created = created_before);
         set SASHELP.vcatalg(where = (libname = 'WORK'));
      run;
   %end;

   %Prv_IAI__IncludeSASFileHalper(i_sas_file = &i_sas_file.
                                 , i_including_mode = &i_including_mode.
                                 , ovar_lines = &ovar_lines.)

   %if (&i_is_verbose. = 1) %then %do;
      data WORK.__TEMP_MACROS_AFTER_INC__(keep = created objname);
         set SASHELP.vcatalg(where = (libname = 'WORK'));
      run;
      
      data WORK.__TEMP_MACROS_NEW_(keep = objname status);
         attrib
            status length = $20.
         ;
         if (0) then do;
            set WORK.__TEMP_MACROS_BEFORE_INC__;
         end;
         set WORK.__TEMP_MACROS_AFTER_INC__;
         if (_N_ = 1) then do;
            dcl hash h_macro_before(dataset: "WORK.__TEMP_MACROS_BEFORE_INC__");
            rc = h_macro_before.definekey('objname');
            rc = h_macro_before.definedata('created_before');
            rc = h_macro_before.definedone();
         end;
         rc = h_macro_before.find();
         if (rc = 0) then do;
            if (created ne created_before) then do;
               status = '(*)';
               output;
            end;
         end;
         else do;
            call missing(status);
            output;
         end;
      run;
      quit;

      proc sort data = WORK.__TEMP_MACROS_NEW_;
         by
            objname
         ;
      run;
      quit;

      data _null_;
         set WORK.__TEMP_MACROS_NEW_;
         if (_N_ = 1) then do;
            put "[Macro(s) defined in ""&i_sas_file.""]";
         end;
         put '   ' status objname;
      run;
      quit;

      proc delete
         data = WORK.__TEMP_MACROS_BEFORE_INC__ WORK.__TEMP_MACROS_AFTER_INC__  WORK.__TEMP_MACROS_NEW_;
      run;
   %end;
%mend Prv_IAI__IncludeSASFile;