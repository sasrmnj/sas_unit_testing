/*
    This script builds a SAS file that contains all the macros of the unit testing framework.
    This allows to use the unit testing framework with a simple "include" statement.
*/

*-- Path of the project --*;
%let project_path       = ~/sas_unit_testing;

*-- Output file --*;
%let out_file           = unit_testing.sas;

*-- Curent date in DDMONYYY format --*;
%let dt9 = %cmpres(%sysfunc(date(), date9.));

*-- Macro to append the content of a file to an existing file --*;
%macro append_data(in_file, out_file);
    %if not %sysfunc(fileexist("&in_file.")) %then %do;
        %put ERROR: IN_FILE does not exist;
        %return;
    %end;

    %if not %sysfunc(fileexist("&out_file.")) %then %do;
        %put ERROR: OUT_FILE does not exist;
        %return;
    %end;

    *-- Read the input file content --*;
    data tmp;
        infile "&in_file." delimiter='0A'x missover pad lrecl=2000 firstobs=1;

        attrib row_data format=$2000. informat=$char2000.;
        input row_data $;

        *-- Calculate row offset (ie. column position of 1st non null char) --*;
        attrib offset format=8.;
        offset = notspace(row_data);
    run;

    *-- Define the output file --*;
    filename out_file "&out_file." lrecl=2000;

    data _null_;
        file out_file mod;

        set tmp;

        *-- Add a blank line between input SAS files --*;
        if _n_ = 1 then put;

        *-- Then output the read SAS script --*;
        if not missing(row_data) then
            put @offset row_data;
        else
            put ;
    run;

    filename out_file;

    proc datasets nolist;
        delete tmp;
    run; quit;
%mend append_data;

*-- Macro to list the content of a folder and store the result into a SAS dataset --*;
%macro get_folder_content(in_dir, ds_out);
/*
    in_dir:     input directory
    out_ds:     output dataset
*/
    filename _dir_ "%bquote(&in_dir.)";

    data &ds_out.(keep = memname);
        handle = dopen( '_dir_' );

        if handle > 0 then do;
            count = dnum(handle);

            do i = 1 to count;
                memname = dread(handle,i);
                output;
            end;
        end;

        rc = dclose(handle);
    run;
%mend;


*---------------------------------------------------------------------------------*;
*-- Build the output file                                                       --*;
*---------------------------------------------------------------------------------*;

%macro build_file;
    *-------------------------------------*;
    *-- Header                          --*;
    *-------------------------------------*;

    *-- Define the output file --*;
    filename out_file "&project_path./&out_file." lrecl=2000;

    data _null_;
        file out_file;
        put "/**************************************************************************************************************************************************";
        put "Program Name   : &out_file.";
        put "Purpose        : SAS unit testing framework";
        put "Date created   : &dt9.";
        put "Details        : The `build.sas` file in the repo is used to create this file.";
        put "***************************************************************************************************************************************************/";
    run;

    filename out_file;

    *-------------------------------------------------*;
    *-- Core scripts                                --*;
    *-------------------------------------------------*;

    *-- ut_setup --*;
    %append_data(&project_path./core/ut_setup.sas, &project_path./&out_file.);

    *-- ut_cov_init --*;
    %append_data(&project_path./core/ut_cov_init.sas, &project_path./&out_file.);

    *-- ut_grp_init --*;
    %append_data(&project_path./core/ut_grp_init.sas, &project_path./&out_file.);

    *-- ut_tst_init --*;
    %append_data(&project_path./core/ut_tst_init.sas, &project_path./&out_file.);

    *-- ut_run --*;
    %append_data(&project_path./core/helpers/ut_run.sas, &project_path./&out_file.);

    *-- ut_log_result --*;
    %append_data(&project_path./core/helpers/ut_log_result.sas, &project_path./&out_file.);

    *-- ut_search_log --*;
    %append_data(&project_path./core/helpers/ut_search_log.sas, &project_path./&out_file.);

    *-------------------------------------------------*;
    *-- Asserts                                     --*;
    *-------------------------------------------------*;

    *-- List files --*;
    %get_folder_content(~/sas_unit_testing/asserts, asserts);

    %let asserts_list=;
    proc sql noprint;
        select      distinct memname
        into        :asserts_list separated by "|"
        from        asserts
        ;
    quit;

    *-- Process all asserts --*;
    %do i=1 %to %sysfunc(countw(&asserts_list., "|"));
        %let cur_assert = %scan(&asserts_list., &i., "|");

        %append_data(&project_path./asserts/&cur_assert., &project_path./&out_file.);
    %end;

    *-- ut_report --*;
    %append_data(&project_path./core/ut_report.sas, &project_path./&out_file.);
%mend build_file;

%build_file;