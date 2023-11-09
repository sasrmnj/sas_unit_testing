/*
    This script builds a SAS file (unit_testing.sas) that groups all the macros of the unit testing framework,
    Then it uploads the file on the Github main repository
    This allows to release the unit testing framework so it can be used with a simple "include" statement.
*/

*---------------------------------------------------------------------------------*;
*-- Settings                                                                    --*;
*---------------------------------------------------------------------------------*;

*-- Github repository --*;
%let github_repo    = https://api.github.com/repos/Gaadek/sas_unit_testing;

*-- Github token to upload file --*;
%let github_token	= ;

*-- commit message --*;
%let commit_message	= Automated unit_testing.sas build upload;

*-- Working directory path --*;
%let _work_dir      = %quote(%sysfunc(pathname(work)));

*-- Output parameters --*;
%let _out_file      = unit_testing.sas;


*---------------------------------------------------------------------------------*;
*-- Custom macros                                                               --*;
*---------------------------------------------------------------------------------*;

*-- Macro to list the content of a folder and store the result into a SAS dataset --*;
%macro get_folder_content(in_dir, out_ds);
/*
    in_dir:     input directory
    out_ds:     output dataset
*/
    filename _dir_ "%bquote(&in_dir.)";

    data &out_ds.(keep = memname);
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
%mend get_folder_content;


*-- Macro to unzip a file. Use only SAS native functions --*;
%macro unzip(in_file, out_dir);
    filename inzip zip "&in_file.";

    *-- Read the content of the zip file --*;
    data zip_content(keep=memname is_folder directory item);
        length memname $255 is_folder 8 directory $255 item $255;

        fid = dopen("inzip");
        if not fid then stop;

        memcount = dnum(fid);
        do i = 1 to memcount;
            memname = dread(fid, i);
            is_folder = (first(reverse(trim(memname))) = '/');

            *-- Remove trailing char of folders --*;
            if is_folder then memname = substr(memname, 1, length(memname) - 1);

            *-- Get item name (file or folder without its directory) --*;
            item = scan(memname, -1, '/');

            if memname ne item then directory = substr(memname, 1, length(memname) - length(item) - 1);
            output;
        end;
        rc = dclose(fid);
    run;

    filename inzip clear;

    *-- Create folder structure of zip file content --*;
    proc sort data=zip_content (where=(is_folder=1)) out=zip_folders; by memname; run;

    data _null_;
        set zip_folders;

        rc = dcreate(item, "&out_dir./" || directory);
    run;

    proc sql noprint;
        select		distinct memname
        into		:mem_lst separated by '~'
        from		zip_content
        where		is_folder = 0
        ;
    quit;

    %do i=1 %to %sysfunc(countw(&mem_lst., '~'));
        %let c_mem = %qscan(&mem_lst., &i., '~');

        *-- Create filerefs pointing to the source and target --*;
        filename _in zip "&in_file." member = "&c_mem." recfm=f lrecl=512;
        filename _out "&out_dir./&c_mem." recfm=f lrecl=512;

        *-- Copy file --*;
        data _null_;
        length msg $ 384;
            rc=fcopy('_in', '_out');
            if rc=0 then
                put 'Copied _in to _out.';
            else do;
                msg=sysmsg();
                put rc= msg=;
            end;
        run;

        filename _in clear;
        filename _out clear;
    %end;
%mend unzip;


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
        infile "&in_file." delimiter='00'x missover pad lrecl=2000 firstobs=1;

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


*---------------------------------------------------------------------------------*;
*-- Main macro                                                                  --*;
*---------------------------------------------------------------------------------*;
%macro run_me;
    *---------------------------------------------*;
    *-- Download the framework from Github      --*;
    *---------------------------------------------*;

    *-- Define a name for a temporary zip file --*;
    %let temp_zip = &_work_dir./test.zip;

    *-- Download the remote repository as a zip file --*;
    filename resp "&temp_zip.";

    proc http method="get" url="&github_repo./zipball" out=resp;
    run;


    *---------------------------------------------*;
    *-- Extract zip file content                --*;
    *---------------------------------------------*;

    data _null_;
        rc = dcreate("sas_unit", "&_work_dir.");
    run;

    %unzip(in_file=&temp_zip., out_dir=&_work_dir./sas_unit);

    *-- Get zipball folder name --*;
    %get_folder_content(&_work_dir./sas_unit, sas_unit);

    %local zb_name;
    %let zb_name=;
    proc sql noprint;
        select      distinct memname
        into        :zb_name trimmed
        from        sas_unit
        ;
    quit;


    *---------------------------------------------*;
    *-- Build the output file                   --*;
    *---------------------------------------------*;

    %macro build_file;
        %local dt9 root_path;

        *-- Get curent date in DDMONYYY format --*;
        %let dt9 = %cmpres(%sysfunc(date(), date9.));

        *-- Get root path of zip file content --*;
        %let root_path = &_work_dir./sas_unit/&zb_name.;


        *-------------------------------------*;
        *-- Header                          --*;
        *-------------------------------------*;

        *-- Define the output file --*;
        filename out_file "&_out_dir./&_out_file." lrecl=2000;

        data _null_;
            file out_file;
            put "/**************************************************************************************************************************************************";
            put "Program Name   : &_out_file.";
            put "Purpose        : SAS unit testing framework";
            put "Date created   : &dt9.";
            put "Details        : The `build.sas` file in the repo is used to create this file.";
            put "***************************************************************************************************************************************************/";
        run;

        filename out_file;

        *-------------------------------------------------*;
        *-- Handle core scripts                         --*;
        *-------------------------------------------------*;

        *-- ut_fcmp --*;
        %append_data(&root_path./core/helpers/ut_fcmp.sas, &_out_dir./&_out_file.);

        *-- ut_setup --*;
        %append_data(&root_path./core/ut_setup.sas, &_out_dir./&_out_file.);

        *-- ut_cov_init --*;
        %append_data(&root_path./core/ut_cov_init.sas, &_out_dir./&_out_file.);

        *-- ut_grp_init --*;
        %append_data(&root_path./core/ut_grp_init.sas, &_out_dir./&_out_file.);

        *-- ut_tst_init --*;
        %append_data(&root_path./core/ut_tst_init.sas, &_out_dir./&_out_file.);

        *-- ut_run --*;
        %append_data(&root_path./core/helpers/ut_run.sas, &_out_dir./&_out_file.);

        *-- ut_log_result --*;
        %append_data(&root_path./core/helpers/ut_log_result.sas, &_out_dir./&_out_file.);

        *-- ut_search_log --*;
        %append_data(&root_path./core/helpers/ut_search_log.sas, &_out_dir./&_out_file.);


        *-------------------------------------------------*;
        *-- Handle asserts scripts                      --*;
        *-------------------------------------------------*;

        *-- List files --*;
        %get_folder_content(&root_path./asserts, asserts);

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

            %append_data(&root_path./asserts/&cur_assert., &_out_dir./&_out_file.);
        %end;

        *-------------------------------------------------*;
        *-- Handle report script                        --*;
        *-------------------------------------------------*;

        *-- ut_report --*;
        %append_data(&root_path./core/ut_report.sas, &_out_dir./&_out_file.);
    %mend build_file;

    %build_file;


    *---------------------------------------------*;
    *-- Upload the built file to Github         --*;
    *---------------------------------------------*;

    %if %sysevalf(%superq(github_token) =, boolean) %then %do;
        %put WARNING: Github token not provided, skipping file upload.;
        %return;
    %end;

    *-- Build the data for the github API (jSON + content in base64) --*;
    filename ifile "&_out_dir./&_out_file.";
    filename ofile "&_out_dir./data.txt";

    data _null_;
        length ifileid 8 ofileid 8 fdata $3 b64 $80;

        *---------------------------------------------*;
        *-- Write json file + commit message		--*;
        *---------------------------------------------*;

        *-- Define data to write in the file --*;
        attrib txt format=$2000.;
        txt = "{""message"":""&commit_message."",""content"":""";

        ofileid = fopen('ofile', 'o', length(txt), 'B');
        rc = fput(ofileid, strip(txt));
        rc = fwrite(ofileid);
        rc = fclose(ofileid);

        *---------------------------------------------*;
        *-- Write file to upload as base64 content	--*;
        *---------------------------------------------*;

        *-- Create handles for input and output files --*;
        ifileid = fopen('ifile', 'i', 3, 'B');
        ofileid = fopen('ofile', 'a', 4, 'B');

        *-- Loop while there is something to read from the input file --*;
        do while(fread(ifileid)=0);
            *-- Read 3 bytes of data --*;
            rc = fget(ifileid, fdata, 3);

            *-- Convert to base64 (3 bytes are converted to 4 bytes) --*;
            if fcol(ifileid) = 4 then 	b64 = put(fdata, $base64x64.);
            else 						b64 = put(trim(fdata), $base64x64.);

            *-- Write converted data to the output file --*;
            rc = fput(ofileid, b64);
            rc = fwrite(ofileid);
        end;

        rc = fclose(ifileid);
        rc = fclose(ofileid);

        *---------------------------------------------*;
        *-- Ends json file 							--*;
        *---------------------------------------------*;

        attrib txt format=$2000.;
        txt = """}";

        ofileid = fopen('ofile', 'a', length(txt), 'B');
        rc = fput(ofileid, strip(txt));
        rc = fwrite(ofileid);
        rc = fclose(ofileid);
    run;

    filename ifile clear;
    filename ofile clear;

    *-- Invoke the github API to upload the file --*;
    filename data "&_out_dir./data.txt";
    filename resp temp;

    proc http
        method	= "put"
        url		= "&github_repo./contents/&_out_file."
        in		= data
        out		= resp
    ;
        headers
            "Accept"		= "application/vnd.github+json"
            "Authorization"	= "Bearer &github_token."
        ;
    run;

    data _null_;
        infile resp;
        input;
        put _infile_;
    run;
%mend run_me;

%run_me;