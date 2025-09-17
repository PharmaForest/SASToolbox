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

3. Read_csv_in_folder macro which makes datasets from all csv files in specified directory at once.

4. Read_excel_in_folder macro which makes datasets from all excel files in specified directory at once.

### Content ###################################################################

SQLinDS package contains the following components:

1. `IncludeAll` macro - the main package macro available for the User
2. `Prv_DoIncludingProcess.sas` internal used macro
3. `Prv_IncludeSASFile` internal used macro
4. `Prv_IncludeSASFileHalper` internal used macro
5. `Prv_MakeIncludingFileList.sas` internal used macro
6. `Prv_RSUFile_GetContentsHelper.sas` internal used macro
7.
8.
9.

DESCRIPTION END:
