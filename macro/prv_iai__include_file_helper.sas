/*** HELP START ***//*

[Internal used only]
This macro is called from Prv_IAI__IncludeSASFile macro.

*//*** HELP END ***/
%macro Prv_IAI__IncludeSASFileHalper(i_sas_file =
                                    , i_including_mode =
                                    , ovar_lines =);
   %local _comment_out;
   %if (&i_including_mode. = RELEASE) %then %do;
      %let _comment_out = DEBUG;
   %end;
   %else %if (&i_including_mode. = DEBUG) %then %do;
      %let _comment_out = RELEASE;
   %end;

   filename f_saso temp;
   filename f_sasi "&i_sas_file.";
   data _null_;
      attrib
         _line length = $32700.
         _in_comment_out_block length = 8.
         _output_flg length = 8.
      ;
      infile f_sasi lrecl = 32700 dsd missover end = eof;
      file f_saso;
      input;
      _line = _infile_;
      retain _line_no 0;
   %if (not %sysevalf(%superq(_comment_out) =, boolean)) %then %do;
      retain _in_comment_out_block 0;
      _output_flg = 1;
      if (prxmatch("/\/\*\s*#&_comment_out.-\s*\*\//o", _line)) then do;
         _in_comment_out_block = 1;
         _output_flg = 0;
      end;
      if (prxmatch("/\/\*\s*-&_comment_out.#\s*\*\//o", _line)) then do;
         _in_comment_out_block = 0;
         _output_flg = 0;
      end;
      if (_output_flg) then do;
         if (_in_comment_out_block = 1 or prxmatch("/#&_comment_out.#\s*\*\/$/o", trim(_line))) then do;
            _line = cat('/*', strip(_line));
         end;
      end;
   %end;
      _line_no = _line_no + 1;
      put _line;
      if (eof) then do;
         call symputx("&ovar_lines.", _line_no);
      end;
   run;
   quit;
   filename f_sasi clear;

   %include f_saso;
   filename f_saso clear;
%mend Prv_IAI__IncludeSASFileHalper;