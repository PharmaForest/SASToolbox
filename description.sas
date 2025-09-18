Type : Package
Package : SASToolbox
Title : SASToolbox package
Version : 1.0.0
Author : Shingo Suzuki(shingo.suzuki@sas.com)
Maintainer : Shingo Suzuki(shingo.suzuki@sas.com)
License : SAS
Encoding : UTF8
Required : "Base SAS Software"
ReqPackages :  

DESCRIPTION START:
# The SASToolbox package [ver. 1.0] <a name="sastoolbox-package"></a> ###############################################
This package provides sas macros which accelerate your business with sas language.

This package provides the following 4 sas macros:
1. IncludeAll macro which includes all .sas files in the specified directory and its sub-directories.

Typical usage of "IncludeAll" macro is shown in below.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  %IncludeAll(/tmp/program)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
The all .sas programs contaied in /tmp/program and its sub-directories will be included.
See the help for the `IncludeAll` macro to find more examples. 

2. SetUTF8 macro which changes encoding of datasets to UTF8 in specified directory at once.
Typical usage of "trancd2u8_d" macro is shown in below.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  %trancd2u8_d(/tmp/program)
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
 
3. Read_csv_in_folder macro which makes datasets from all csv files in specified directory at once.
 
Typical usage of "Read_csv_in_folder" macro is shown in below.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  %Read_csv_in_folder(path="/example/homes/SampleUser/SASPac/tmp1_csvFiles")
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
All .csv file(s) to be imported exists in a folder of "/example/homes/SampleUser/SASPac/tmp1_csvFiles".
See the help for the `Read_csv_in_folder` macro to find more examples.
 
4. Read_excel_in_folder macro which makes datasets from all excel files in specified directory at once.
 
Typical usage of "Read_excel_in_folder" macro is shown in below.
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  %Read_excel_in_folder(path="/example/homes/SampleUser/SASPac/tmp1_excelFiles")
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
All .xslx file(s) to be imported exists in a folder of "/example/homes/SampleUser/SASPac/tmp1_excelFiles".
See the help for the `Read_excel_in_folder` macro to find more examples.
-----------------------------------------------------------------------------------------------------------------------------------

### Content ###################################################################

SASToolbox package contains the following components:

1. `IncludeAll` macro - the main macro available for the User
2. `Read_csv_in_folder`- the main macro available for the User
3. `Read_excel_in_folder` - the main macro available for the User
3. `trancd2u8_d` - the main macro available for the User
5. `Prv_IAI__DoIncludingProcess` internal macro used by IncludeAll macro
6. `Prv_IAI__GetContentsHelper` internal macro used by IncludeAll macro
7. `Prv_IAI__IncludeSASFileHalper` internal macro used by IncludeAll macro
8. `Prv_IAI__IncludeSASFile` internal macro used by IncludeAll macro
9. `Prv_IAI__MakeSASFileList` internal macro used by IncludeAll macro

DESCRIPTION END:
