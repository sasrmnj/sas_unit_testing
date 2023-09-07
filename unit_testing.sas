/**************************************************************************************************************************************************
Program Name   : unit_testing.sas
Purpose        : SAS unit testing framework
Date created   : 07SEP2023
Details        : The `build.sas` file in the repo is used to create this file.
***************************************************************************************************************************************************/

%macro ut_setup;
/*
    Macro to set up the unit testing environment.
    To be run first and once.
*/
    %global ut_grp_id ut_grp_desc
            ut_tst_seq ut_tst_id ut_tst_type ut_tst_desc ut_tst_exp_res ut_tst_res ut_tst_det
            ut_work_dir ut_log_file
    ;

    *--
        Unique identifier of a group of tests.
        Call to "ut_grp_init" increments increments its value by 1.
    --*;
    %let ut_grp_id = 0;

    *--
        Description of a group of tests.
        Value is set when invoking "ut_grp_init"
        Value is output in the validation report.
    --*;
    %let ut_grp_desc = ;

    *--
        Sequence of a test within a group of tests
        Call to "ut_grp_init" reset this value to 0
        Call to an assert function increase this value by 1
    --*;
    %let ut_tst_seq = 0;

    *--
        Unique identifier of a test.
        Call to an assert function derive this value ut_grp_id.ut_tst_seq
    --*;
    %let ut_tst_id = ;

    *--
        Type of test.
        Value is set when invoking an assert function
    --*;
    %let ut_tst_type = ;

    *--
        Description of a test.
        Value is set when invoking an assert function
        Value is output in the validation report.
    --*;
    %let ut_tst_desc = ;

    *-- Expected result of a test --*;
    %let ut_tst_exp_res = ;

    *-- Result of a test --*;
    %let ut_tst_res = ;

    *-- Details about the result of a test --*;
    %let ut_tst_det = ;

    *-- Get the SAS work directory (used as a temporary directory to store the SAS logs generated by ut_run) --*;
    %let ut_work_dir = %quote(%sysfunc(pathname(work)));

    *-- Name of a file to store the SAS logs generated by ut_run --*;
    %let ut_log_file = dummy.log;

    *--
        Dataset to store the results of the tests
        Each call to an assert function insert a record in this dataset
    --*;
    data _ut_results (drop = _i_);
        attrib  ut_grp_id   format=best.    label="Testing group ID"
                ut_grp_desc format=$200.    label="Testing group description"
                ut_tst_seq      format=best.    label="Test ordering value"
                ut_tst_id       format=$20.     label="Test ID"
                ut_tst_type     format=$30.     label="Test type"
                ut_tst_desc     format=$200.    label="Test description"
                ut_tst_exp_res  format=$10.     label="Expected test result"
                ut_tst_res      format=$10.     label="Test result"
                ut_tst_stat     format=$10.     label="Test status"
                ut_tst_det      format=$500.    label="Test details"
        ;

        set _null_;

        *-- Init all char variables --*;
        array my_chars[*] _character_;
        do _i_=1 to dim(my_chars);
            my_chars[_i_] = '';
        end;

        *-- Init all num variables --*;
        array my_nums[*] _numeric_;
        do _i_=1 to dim(my_nums);
            my_nums[_i_] = .;
        end;
    run;
%mend ut_setup;

%macro ut_grp_init(description);
/*
    Macro to initialize a group of test.
    A group can be used when multiple tests are needed to validate a feature.
    In this case, all the tests can be grouped with a common description
    description:        description of the group of tests
*/
    *-- Increment test group id by 1 --*;
    %let ut_grp_id = %eval(&ut_grp_id. + 1);

    *-- Reset test order --*;
    %let ut_tst_seq = 0;

    *-- Set test group description --*;
    %if %sysevalf(%superq(description) ne, boolean) %then   %let ut_grp_desc = %nrbquote(&description.);
    %else                                                   %let ut_grp_desc = Testing group #&ut_grp_id.;
%mend ut_grp_init;

%macro ut_tst_init(type=, description=, expected_result=);
/*
    Macro to create and initialize a test "container".
    This "container" is inserted once the test is complete into the result dataset
    This function is used by assert functions and shoudn't be used out of this scope
    type:               type of test
    description:        description of the test
    expected_result:    expected result of the test (either PASS or FAIL)
*/
    *-- Increment test sequence by 1 --*;
    %let ut_tst_seq = %eval(&ut_tst_seq. + 1);

    *-- Derive test id --*;
    %let ut_tst_id = %cmpres(&ut_grp_id..&ut_tst_seq.);

    *-- Set test type --*;
    %if %sysevalf(%superq(type) ne, boolean) %then              %let ut_tst_type = %nrbquote(&type.);
    %else                                                       %let ut_tst_type = %lowcase(%sysmexecname(%sysmexecdepth - 2));

    *-- Set test description --*;
    %if %sysevalf(%superq(description) ne, boolean) %then       %let ut_tst_desc = %nrbquote(&description.);
    %else                                                       %let ut_tst_desc = Test #&ut_tst_id.;

    *-- Set expected test result (PASS by default) --*;
    %if %sysevalf(%superq(expected_result) =, boolean) %then    %let expected_result = PASS;
    %let ut_tst_exp_res = &expected_result.;

    *-- Set test result to FAIL by default --*;
    %let ut_tst_res = FAIL;

    *-- Reset test details --*;
    %let ut_tst_det = ;
%mend ut_tst_init;

%macro ut_run(stmt=, debug=);
/*
    Macro to run some SAS code in a controled environement where ERROR and WARNINGS are not output in the SAS log.
    Allow to perform some tests whose result is an ERROR or a WARNING.
    stmt:   the SAS code to execute.
    debug:  any non null value enables the debug mode and so disable the SAS log redirection
*/
    %if %sysevalf(%superq(debug) =, boolean) %then %do;
        *-- This option allows to have SAS log lines up to 256 chars (the max) --*;
        option linesize=max;

        *-- Redirect the SAS log --*;
        proc printto log="&ut_work_dir./&ut_log_file." new;
        run;
    %end;

    *-- Reset warning status --*;
    %put WARNING: %str( );

    *-- Reset error status --*;
    %put ERROR: %str( );

    %let syscc = 0;

    *-- Execute the provided SAS statement --*;
    %unquote(&stmt.);

    %if %sysevalf(%superq(debug) =, boolean) %then %do;
        *-- Disable SAS log redirection --*;
        proc printto;
        run;
    %end;
%mend ut_run;

%macro ut_log_result;
/*
    Macro to insert the result of a test into the result dataset.
    This function is used by assert functions and shoudn't be used out of this scope
*/
    *-- Define test status --*;
    %if %lowcase(&ut_tst_res.) = %lowcase(&ut_tst_exp_res.) %then   %let ut_tst_stat = PASS;
    %else                                                           %let ut_tst_stat = FAIL;

    proc sql noprint;
        insert into _ut_results
        set ut_grp_id       = &ut_grp_id.,
            ut_grp_desc     = "%nrbquote(&ut_grp_desc.)",
            ut_tst_seq      = &ut_tst_seq.,
            ut_tst_id       = strip("&ut_tst_id."),
            ut_tst_type     = strip("&ut_tst_type."),
            ut_tst_desc     = "%nrbquote(&ut_tst_desc.)",
            ut_tst_exp_res  = strip("&ut_tst_exp_res."),
            ut_tst_res      = strip("&ut_tst_res."),
            ut_tst_stat     = strip("&ut_tst_stat."),
            ut_tst_det      = "%nrbquote(&ut_tst_det.)"
        ;
    quit;
%mend ut_log_result;

%macro ut_search_log(log_file=&ut_work_dir./&ut_log_file., log_type=, log_msg=, res_var=);
/*
    Macro to search for specific content in a SAS log file.
    This function is used by assert functions and shoudn't be used out of this scope
    log_file:   the path to the log file to check
    log_type:   the type of log message to search for (ERROR, WARNING, NOTE or anything else)
    log_msg:    the text tp search for
    res_var:    the variable name to return the result (if "log_msg" has been found, then TRUE else FALSE)
*/
    %if %sysevalf(%superq(log_file) =, boolean) %then %do;
        %put ERROR: LOG_FILE is mandatory when calling ut_search_log;
        %return;
    %end;

    %if not %sysfunc(fileexist("&log_file.")) %then %do;
        %put ERROR: LOG_FILE does not exist;
        %return;
    %end;

    %if %sysevalf(%superq(res_var) =, boolean) %then %do;
        %put ERROR: RES_VAR is mandatory when calling ut_search_log;
        %return;
    %end;

    %if %sysevalf(%superq(log_type) =, boolean) and %sysevalf(%superq(log_msg) =, boolean) %then %do;
        %put ERROR: either LOG_TYPE or LOG_MSG (or both) are expected when calling ut_search_log;
        %return;
    %end;

    *-- By default, set res_var to FALSE --*;
    %let &res_var. = FALSE;

        *-- Determine the length of the buffer to search for text --*;
    *-- NOTE: we read at least 256 chars from log, so the buffer length is 512 char at the minimum --*;
    %if %sysevalf(%superq(log_msg) ne, boolean) %then   %let buf_size = %eval(%length(&log_msg.) * 2);
    %else                                               %let buf_size = 512;

    %let buf_size = %sysfunc(max(&buf_size., 512));


    *-- Open the log file --*;
    filename log_in "&log_file.";

    data _null_;
        infile log_in lrecl=256 length=line_len truncover;

        attrib  log_no  format=8.
                log_len format=8.
                log_txt format=$256.
                buf     format=$&buf_size..
                buf_len format=8.
                flag    format=8.
        ;

        retain  flag buf_len buf;

        if _n_ = 1 then do;
            flag    = 0;
            buf     = "";
            buf_len = 0;
        end;

        *-- Read log --*;
        input;

        log_no  = _n_;
        log_len = line_len;
        log_txt = _infile_;

        %if %sysevalf(%superq(log_msg) =, boolean) %then %do;
            *-- If log_msg is null, we just have to search for the log_type value at the beginning of a line --*;

            if prxmatch("/^&log_type..*/oi", strip(log_txt)) then do;
                call symputx("&res_var.", "TRUE");
                stop;
            end;
        %end;
        %else %do;
            *-- If log_msg is not null, it is a little bit more complex :) --*;

            *-- Condition to start filling the buffer used to search text --*;
            if      flag = 0
                and prxmatch("/^[a-z]/oi", strip(log_txt))
                and prxmatch("/^&log_type..*/oi", strip(log_txt))
            then do;
                flag        = 1;
                buf         = "";
                buf_len     = 0;
                log_line    = _n_;
            end;

            *-- Process current log line --*;
            if flag and not missing(log_txt) then do;
                *-- Ensure there is enough space in the buffer to add current log line --*;
                if buf_len + log_len > &buf_size. then do;
                    buf = substr(buf, (log_len-(&buf_size. - buf_len)) + 1);
                    buf_len = buf_len - (log_len-(&buf_size. - buf_len));
                end;

                *-- Append the current log line to the buffer --*;
                if buf_len = 0 then buf = substr(log_txt, 1, log_len);
                else                buf = substr(buf, 1, buf_len) || substr(log_txt, 1, log_len);

                *-- Update length value of buffer content --*;
                buf_len = buf_len + log_len;

                *-- Log entry found --*;
                if find(buf, strip("&log_msg."), 'it') then do;
                    call symputx("&res_var.", "TRUE");
                    stop;
                end;
            end;

            output;

            *-- Condition to stop filling the buffer used to search text --*;
            if      flag
                and (
                            missing(log_txt)
                        or  prxmatch("/^\d/oi", strip(log_txt))
                    )
            then do;
                flag        = 0;
                buf         = "";
                buf_len     = 0;
                log_no      = _n_;
            end;
        %end;
    run;

    filename log_in;
%mend ut_search_log;

%macro ut_assert_dataset(description=, ds_01=, ds_02=, expected_result=PASS);
/*
    To be used to assert datasets are identical
    description:        description to explain why ds_01 should be equal to ds_02
    ds_01:              name of the first dataset
    ds_02:              name of the second dataset
*/
    %ut_tst_init(type=ut_assert_dataset, description=&description., expected_result=&expected_result.);

    proc compare data=&ds_01. compare=&ds_02. noprint;
    run;

    *-- Check the result of the proc compare (store into sysinfo) --*;
    %if &sysinfo. = 0 %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. are identical;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. are different;
    %end;

    %ut_log_result;
%mend ut_assert_dataset;

%macro ut_assert_dataset_content(description=, ds_01=, ds_02=, expected_result=PASS);
/*
    To be used to assert dataset contents are equals
    description:        description to explain why ds_01 content should be equal to ds_02 content
    ds_01:              name of the first dataset
    ds_02:              name of the second dataset
*/
    %ut_tst_init(type=ut_assert_dataset_content, description=&description., expected_result=&expected_result.);

    proc compare data=&ds_01. compare=&ds_02. noprint;
    run;

    *-- Statement provided to check macro variable value, so continue testing --*;
    *--
        Note: sysinfo is a binary number
        bit #1 (1)      Dataset labels differ
        bit #2 (2)      Dataset types differ
        bit #3 (4)      Variable informats differ
        bit #4 (8)      Variable formats differ
        bit #5 (16)     Variable lengths differ
        bit #6 (32)     Variable labels differ
        bit #7 (64)     Base dataset has obs not in comparison dataset
        bit #8 (128)    Comparison dataset has obs not in base dataset
        bit #9 (256)    Base dataset has BY group not in comparison dataset
        bit #10 (512)   Comparison dataset has BY group not in base dataset
        bit #11 (1024)  Base dataset has variable not in comparison dataset
        bit #12 (2048)  Comparison dataset has variable not in base dataset
        bit #13 (4096)  A value comparison was unequal
        bit #14 (8192)  Conflicting variable type
        bit #15 (16384) BY variables do not match
        bit #16 (32768) Fatal error, comparison not done

        So any code >= 64 reports an issue with the content
    --*;
    %if &sysinfo. < 64  %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have the same content;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have different content;
    %end;

    %ut_log_result;
%mend ut_assert_dataset_content;

%macro ut_assert_dataset_structure(description=, ds_01=, ds_02=, expected_result=PASS);
/*
    To be used to assert dataset structures are the same
    description:        description to explain why ds_01 structure should be equal to ds_02 structure
    ds_01:              name of the first dataset
    ds_02:              name of the second dataset
*/
    %ut_tst_init(type=ut_assert_dataset_structure, description=&description., expected_result=&expected_result.);

    proc contents data=&ds_01. out=content_01(keep=name type length varnum label format formatl formatd informat informl informd just npos) noprint;
    run;

    proc contents data=&ds_02. out=content_02(keep=name type length varnum label format formatl formatd informat informl informd just npos) noprint;
    run;

    proc compare data=content_01 compare=content_02 noprint;
    run;

    *-- Check the result of the proc compare (store into sysinfo) --*;
    %if &sysinfo. = 0 %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have the same structure;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have different structures;
    %end;

    %ut_log_result;
%mend ut_assert_dataset_structure;

%macro ut_assert_dataset_tc(ds=, desc_var=, eval_stmt=, exp_status_var=, det_var=);
/*
    To be used to run test cases provided in a dataset
    ds:                 dataset with test cases
    desc_var:           variable name within ds that contains the test description
    eval_stmt:          SAS statement to evaluate if the test is PASS or FAIL
    exp_status_var:     variable name within ds that contains the expected status of the test
    det_var:            variable name within ds that contains the test details
*/
    %local lib_name ds_name _tc_count _i_ cnt description status details;

    *-- Extract libname and memname of "ds" --*;
    %let lib_name   = work;
    %let ds_name    = &ds.;

    %if %sysfunc(countw(&ds_name., '.')) > 1 %then %do;
        %let lib_name    = %scan(&ds., 1, '.');
        %let ds_name     = %scan(&ds., 2, '.');
    %end;

    *-- Count number of test cases present in driver ds --*;
    proc sql noprint;
        select      nobs
        into        :_tc_count trimmed
        from        dictionary.tables
        where       strip(lowcase(libname)) = strip(lowcase("&lib_name."))
            and     strip(lowcase(memname)) = strip(lowcase("&ds_name."))
        ;
    quit;

    *-- Loop throught the tests cases --*;
    %do _i_ = 1 %to &_tc_count.;
        *-- Extract the test description --*;
        %let description=;
        proc sql noprint;
            select      count(*)
            into        :cnt trimmed
            from        dictionary.columns
            where       strip(lowcase(libname)) = strip(lowcase("&lib_name."))
                and     strip(lowcase(memname)) = strip(lowcase("&ds_name."))
                and     strip(lowcase(name)) = strip(lowcase("&desc_var."))
            ;
        quit;

        %if &cnt = 1 %then %do;
            proc sql noprint;
                select      &desc_var.
                into        :description trimmed
                from        &ds. (firstobs=&_i_. obs=&_i_.)
                ;
            quit;
        %end;

        *-- Extract the expected test status --*;
        %let status=PASS;

        proc sql noprint;
            select      count(*)
            into        :cnt trimmed
            from        dictionary.columns
            where       strip(lowcase(libname)) = strip(lowcase("&lib_name."))
                and     strip(lowcase(memname)) = strip(lowcase("&ds_name."))
                and     strip(lowcase(name)) = strip(lowcase("&exp_status_var."))
            ;
        quit;

        %if &cnt = 1 %then %do;
            proc sql noprint;
                select      upcase(&exp_status_var.)
                into        :status trimmed
                from        &ds. (firstobs=&_i_. obs=&_i_.)
                ;
            quit;
        %end;

        %ut_tst_init(type=ut_assert_dataset_tc, description=&description., expected_result=&status.);

        *-- Extract the test details --*;
        %let details="";

        proc sql noprint;
            select      count(*)
            into        :cnt trimmed
            from        dictionary.columns
            where       strip(lowcase(libname)) = strip(lowcase("&lib_name."))
                and     strip(lowcase(memname)) = strip(lowcase("&ds_name."))
                and     strip(lowcase(name)) = strip(lowcase("&det_var."))
            ;
        quit;

        %if &cnt = 1 %then %do;
            proc sql noprint;
                select      &det_var.
                into        :details trimmed
                from        &ds. (firstobs=&_i_. obs=&_i_.)
                ;
            quit;
        %end;

        *-- Evaluate the test case --*;
        data _null_;
            set &ds. (firstobs=&_i_. obs=&_i_.);

            if %unquote(&eval_stmt.) then do;
                call symputx('ut_tst_res', "PASS");
                call symputx('ut_tst_det', "Test '&eval_stmt.' valid.^n" || strip(&det_var.));
            end;
            else do;
                call symputx('ut_tst_res', "FAIL");
                call symputx('ut_tst_det', "Test '&eval_stmt.' is not successful.^n" || strip(&det_var.));
            end;
        run;

        %ut_log_result;
    %end;
%mend ut_assert_dataset_tc;

%macro ut_assert_error(description=, error_msg=, expected_result=PASS);
/*
    To be used to assert an error is expected
    Note: this function searches for the current error message
    If you search for a specific error that could have occured earlier, you might have to use ut_assert_log
    description:        description to explain why an error is expected
    error_msg:          error message expected either in the SAS log or in the system
    expected_result:    either PASS or FAIL
*/
    %ut_tst_init(type=ut_assert_error, description=&description., expected_result=&expected_result.);

    *-- Remove the leading "ERROR:" tag if any --*;
    %let error_msg = %sysfunc(prxchange(s/^ERROR:\s*(.*)$/$1/oi, -1, %nrbquote(&error_msg.)));

    %if %sysevalf(%superq(syserrortext) ne, boolean) or &syscc. > 4 %then %do;
        *-- Overall status is erroneous (either error message or error code) --*;
        *-- http://support.sas.com/kb/35/553.html --*;
        %if %sysevalf(%superq(error_msg) ne, boolean) %then %do;
            *-- If expected error message is provided, then SAS error message must match --*;
            %if %nrbquote(&syserrortext.) = %nrbquote(&error_msg.) %then %do;
                %let ut_tst_res = PASS;
                %let ut_tst_det = Expected error is:^n%nrbquote(&error_msg.)^n^nError reported by SAS is:^n%nrbquote(&syserrortext.);
            %end;
            %else %do;
                %let ut_tst_res = FAIL;
                %let ut_tst_det = Expected error is:^n%nrbquote(&error_msg.)^n^nError reported by SAS is:^n%nrbquote(&syserrortext.);
            %end;
        %end;
        %else %do;
            %let ut_tst_res = PASS;
            %let ut_tst_det = Error reported by SAS is:^n%nrbquote(&syserrortext.);
        %end;
    %end;

    %ut_log_result;
%mend ut_assert_error;

%macro ut_assert_file(description=, filepath=, expected_result=PASS);
/*
    To be used to assert a file is expected
    description:        description to explain why a file is expected
    filepath:           the expected file full path
    expected_result:    either PASS or FAIL
*/
    %ut_tst_init(type=ut_assert_file, description=&description., expected_result=&expected_result.);

    %if %sysfunc(fileexist("&filepath.")) %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = Expected file %nrbquote(&filepath.) found;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Expected file %nrbquote(&filepath.) not found;
    %end;

    %ut_log_result;
%mend ut_assert_file;

%macro ut_assert_log(description=, log_type=, log_msg=, expected_result=PASS);
/*
    To be used to assert a log message is expected
    Note: this function searches for SAS log for a specific message
    description:        description to explain why a message in the log is expected
    log_type:           type of log message (ERROR, WARNING, NOTE...)
    log_msg:            expected text in the log
    expected_result:    either PASS or FAIL
*/
    %ut_tst_init(type=ut_assert_log, description=&description., expected_result=&expected_result.);

    *-- Define a macro variable to store the result of ut_search_log --*;
    %let ut_search_log=;

    %ut_search_log(log_type=&log_type., log_msg=&log_msg., res_var=ut_search_log);

    %if %sysevalf(%superq(log_type) ne, boolean) %then  %let ut_tst_det = Expected log type %nrbquote(&log_type.) with message:^n;
    %else                                               %let ut_tst_det = Expected log message:^n;
    %let ut_tst_det = &ut_tst_det.%nrbquote(&log_msg.)^n;

    %if &ut_search_log. = TRUE %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = &ut_tst_det.found in the SAS log;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = &ut_tst_det.not found in the SAS log;
    %end;

    %ut_log_result;
%mend ut_assert_log;

%macro ut_assert_macro(description=, stmt=, expected_result=PASS);
/*
    To be used to assert some macro code is valid
    description:        description to explain why a macro statement should be valid (or not)
    stmt:               macro statement to evaluate
    expected_result:    either PASS or FAIL
*/
    %ut_tst_init(type=ut_assert_macro, description=&description., expected_result=&expected_result.);

    *-- Statement provided to check macro varialbe value, so continue testing --*;
    %if %unquote(&stmt.) %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = Test %superq(stmt) (evaluated as %unquote(&stmt.)) is valid;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Test %superq(stmt) (evaluated as %nrbquote(&stmt.)) is not successful;
    %end;

    %ut_log_result;
%mend ut_assert_macro;

%macro ut_assert_noerror(description=, expected_result=PASS);
/*
    To be used to assert an error is not expected
    description:        description to explain why an error is not expected
    expected_result:    either PASS or FAIL
*/
    *-- Create a new test --*;
    %ut_tst_init(type=ut_assert_noerror, description=&description., expected_result=&expected_result.);

    %if %sysevalf(%superq(syserrortext) =, boolean) and &syscc. < 5 %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = No error message reported by SAS;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Error reported by SAS is:^n%nrbquote(&syserrortext.)^n^nwhereas no error was expected;
    %end;

    %ut_log_result;
%mend ut_assert_noerror;

%macro ut_assert_noissue(description=, expected_result=PASS);
/*
    To be used to assert an issue is not expected (i.e. no error, no warning)
    description:        description to explain why an issue is not expected
    expected_result:    either PASS or FAIL
*/
    %ut_tst_init(type=ut_assert_noissue, description=&description., expected_result=&expected_result.);

    %if %sysevalf(%superq(syswarningtext) =, boolean) and %sysevalf(%superq(syserrortext) =, boolean) and &syscc. = 0 %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = No warning and no error message reported by SAS.;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %if %sysevalf(%superq(syserrortext) ne, boolean) %then %do;
            %let ut_tst_det = Error reported by SAS is:^n%nrbquote(&syserrortext.)^n^nwhereas no error was expected;
        %end;
        %else %if %sysevalf(%superq(syswarningtext) ne, boolean) %then %do;
            %let ut_tst_det = Warning reported by SAS is:^n%nrbquote(&syswarningtext.)^n^nwhereas no warning was expected;
        %end;
        %else %do;
            %let ut_tst_det = SAS session status (syscc) reported by SAS is:^n&syscc^n^nwhereas 0 was expected;
        %end;
    %end;

    %ut_log_result;
%mend ut_assert_noissue;

%macro ut_assert_nowarning(description=, expected_result=PASS);
/*
    To be used to assert a warning is not expected
    description:        description to explain why a warningis not expected
    expected_result:    either PASS or FAIL
*/
    %ut_tst_init(type=ut_assert_nowarning, description=&description., expected_result=&expected_result.);

    %if %sysevalf(%superq(syswarningtext) =, boolean) and &syscc. < 4 %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = No warning message reported by SAS.;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Warning reported by SAS is:^n%nrbquote(&syswarningtext.)^n^nwhereas no warning was expected;
    %end;

    %ut_log_result;
%mend ut_assert_nowarning;

%macro ut_assert_warning(description=, warning_msg=, expected_result=PASS);
/*
    To be used to assert a warning is expected
    Note: this function searches for the current warning message
    If you search for a specific warning that could have occured earlier, you might have to use ut_assert_log
    description:        description to explain why a warning is expected
    warning_msg:        warning message expected either in the SAS log or in the system
    expected_result:    either PASS or FAIL
*/
    %ut_tst_init(type=ut_assert_warning, description=&description., expected_result=&expected_result.);

    *-- Remove the leading "WARNING:" tag if any --*;
    %let warning_msg = %sysfunc(prxchange(s/^WARNING:\s*(.*)$/$1/oi, -1, %nrbquote(&warning_msg.)));

    %if %sysevalf(%superq(syswarningtext) ne, boolean) or (0 < &syscc. and &syscc. < 4) %then %do;
        *-- Warning text exists or overall status is warning --*;
        *-- http://support.sas.com/kb/35/553.html --*;
        %if %sysevalf(%superq(warning_msg) ne, boolean) %then %do;
            *-- If expected warning message is provided, then SAS warning message must match --*;
            %if %nrbquote(&syswarningtext.) = %nrbquote(&warning_msg.) %then %do;
                %let ut_tst_res = PASS;
                %let ut_tst_det = Expected warning is:^n%nrbquote(&warning_msg.)^n^nWarning reported by SAS is:^n%nrbquote(&syswarningtext.);
            %end;
            %else %do;
                %let ut_tst_res = FAIL;
                %let ut_tst_det = Expected warning is:^n%nrbquote(&warning_msg.)^n^nWarning reported by SAS is:^n%nrbquote(&syswarningtext.);
            %end;
        %end;
        %else %do;
            %let ut_tst_res = PASS;
            %let ut_tst_det = Warning reported by SAS is:^n%nrbquote(&syswarningtext.);
        %end;
    %end;

    %ut_log_result;
%mend ut_assert_warning;

%macro ut_report(pgm_name=, report_path=);
/*
    Macro to generate a PDF report of the tests performed.
    pgm_name:       name of the SAS program being tested
    report_path:    full path to the PDF file to be created
*/
    *-- Get the current date in yyyymmdd format --*;
    %let yyyymmdd = %sysfunc(date(), yymmddn8.);

    *-- Build a PDF report --*;
    ods listing close;
    ods noresults;
    options nodate nonumber;
    options orientation=landscape;
    ods escapechar '^';

    ods pdf file="&report_path./unit_testing_&pgm_name._&yyyymmdd..pdf";

    title;
    footnote;

    title1 justify=center height=12pt "&pgm_name. - Validation report";
    footnote1 justify=right height=10pt "^{thispage} | ^{lastpage}";

    proc sql noprint;
        create table rpt as
            select      "x" as dummy,
                        ut_grp_id,
                        catx(' - ', ut_grp_id, ut_grp_desc) as ut_grp_desc,
                        ut_tst_seq,
                        ut_tst_id,
                        ut_tst_type,
                        ut_tst_desc,
                        ut_tst_exp_res,
                        ut_tst_res,
                        ut_tst_stat,
                        ut_tst_det
            from        _ut_results
            order by    ut_grp_id, ut_tst_seq
        ;
    quit;

    *-------------------------------------------------*;
    *-- Overall status                              --*;
    *-------------------------------------------------*;

    proc sql noprint;
        select      count(*)
        into        :not_pass_cnt trimmed
        from        rpt
        where       strip(lowcase(ut_tst_stat)) ne "pass"
        ;
    quit;

    data overall;
        attrib dummy format=$1.;    dummy = "x";
        attrib desc format=$50.;
        attrib value format=$100.;

        desc = "Validation report run by";
        value = strip("&sysuserid.");
        output;

        desc = "Validation report run";
        value = strip(put(datetime(), datetime22.));
        output;

        desc = "Overall validation status";

        if &not_pass_cnt. = 0 then  value = 'PASS';
        else                        value = 'FAIL';
        output;
    run;

    ods proclabel 'Overall status';
    title2 "Overall status";

    proc report data=overall contents="" nowindows missing
        style (header)={font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l}
        style (report)={background=white}
        ;

        column dummy desc value;

        define dummy    / order noprint;
        define desc     / display "";
        define value    / display "";

        *-- This hack removes TOC entries --*;
        break before dummy / page contents='';

        compute value;
            if strip(lowcase(desc)) = "overall validation status" then do;
                if strip(lowcase(value)) = "pass" then  call define(_col_, "style", "style={background=cxa7e8b8}");
                else                                    call define(_col_, "style", "style={background=cxfab4b4}");
            end;
        endcomp;
    run;

    *-------------------------------------------------*;
    *-- Validation overview report                  --*;
    *-------------------------------------------------*;

    ods proclabel 'Validation overview';
    title2 "Validation overview";

    proc report data=rpt contents="" nowindows missing
        style (header)={font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l}
        style (report)={background=white}
        ;

        column dummy ut_grp_id ut_grp_desc ut_tst_id ut_tst_desc ut_tst_stat;

        define dummy        / order noprint;
        define ut_grp_id    / order noprint;
        define ut_grp_desc  / group noprint;
        define ut_tst_id    / display "Test ID" style={width=100};
        define ut_tst_desc  / display "Test description";
        define ut_tst_stat  / display "Status" style={width=80};

        *-- This hack removes TOC entries --*;
        break before dummy / page contents='';

        *-- Display the group description as a header row --*;
        compute before ut_grp_desc / style={font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l};
            line ut_grp_desc $500.;
        endcomp;

        compute ut_tst_stat;
            if strip(lowcase(ut_tst_stat)) = "pass" then    call define(_col_, "style", "style={background=cxa7e8b8}");
            else                                            call define(_col_, "style", "style={background=cxfab4b4}");
        endcomp;
    run;


    *-------------------------------------------------*;
    *-- Failed tests report                         --*;
    *-------------------------------------------------*;

    ods proclabel 'Failed tests';

    data err_rpt (keep = dummy ut_grp_id ut_tst_seq ut_grp_desc ut_tst_id ut_tst_type row_nfo row_data);
        set rpt (where = (strip(lowcase(ut_tst_stat)) ne "pass"));

        attrib row_nfo format=$50.;
        attrib row_data format=$500.;

        row_nfo="Test description"; row_data=strip(ut_tst_desc);    output;
        row_nfo="Test type";        row_data=strip(ut_tst_type);    output;
        row_nfo="Test details";     row_data=strip(ut_tst_det);     output;
        row_nfo="Expected result";  row_data=strip(ut_tst_exp_res); output;
        row_nfo="Result";           row_data=strip(ut_tst_res);     output;
    run;

    proc report data=err_rpt contents="" nowindows missing headline headskip spacing=1 spanrows
        style (header)=[font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l]
        style (report)={background=white}
        ;

        column dummy ut_grp_id ut_tst_seq ut_grp_desc ut_tst_id row_nfo row_data;

        define dummy        / order noprint;
        define ut_grp_id    / order noprint;
        define ut_tst_seq   / order noprint;
        define ut_grp_desc  / group noprint;
        define ut_tst_id    / order "Test ID"  style={verticalalign=middle width=100};
        define row_nfo      / display "";
        define row_data     / display "";

        *-- This hack removes TOC entries --*;
        break before dummy / page contents='';

        *-- Display the group description as a header row --*;
        compute before ut_grp_desc / style={font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l};
            line ut_grp_desc $500.;
        endcomp;
    run;


    *-------------------------------------------------*;
    *-- Detailed validation reports                 --*;
    *-------------------------------------------------*;

    data full_rpt (keep = dummy ut_grp_id ut_grp_desc ut_tst_seq ut_tst_id ut_tst_type ut_tst_exp_res ut_tst_res ut_tst_stat row_nfo row_data);
        set rpt;

        attrib row_nfo format=$50.;
        attrib row_data format=$500.;

        row_nfo="Test description"; row_data=strip(ut_tst_desc);    output;
        row_nfo="Test type";        row_data=strip(ut_tst_type);    output;
        row_nfo="Test details";     row_data=strip(ut_tst_det);     output;
        row_nfo="Expected result";  row_data=strip(ut_tst_exp_res); output;
        row_nfo="Result";           row_data=strip(ut_tst_res);     output;
    run;

    proc sql noprint;
        select      distinct ut_grp_id
        into        :ut_grp_id_lst separated by '|'
        from        full_rpt
        order by    ut_grp_id
        ;
    quit;

    %do _i_ = 1 %to %sysfunc(countw(&ut_grp_id_lst., '|'));
        %let cur_ut_grp_id = %scan(&ut_grp_id_lst., &_i_., '|');

        proc sql noprint;
            select      distinct ut_grp_desc
            into        :ut_grp_desc trimmed
            from        full_rpt
            where       ut_grp_id = &cur_ut_grp_id.
            ;
        quit;

        ods proclabel "Detailed report. %nrbquote(&ut_grp_desc.)";
        title2 "%nrbquote(&ut_grp_desc.)";


        proc report data=full_rpt (where=(ut_grp_id=&cur_ut_grp_id.)) contents="" nowindows missing headline headskip spacing=1 spanrows
            style (header)=[font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l]
            style (report)={background=white}
            ;

            column dummy ut_grp_id ut_tst_seq ut_tst_id row_nfo row_data ut_tst_stat;

            define dummy        / order noprint;
            define ut_grp_id    / order noprint;
            define ut_tst_seq   / order noprint;
            define ut_tst_id    / order "Test ID"  style={verticalalign=middle width=100};
            define row_nfo      / display "";
            define row_data     / display "";
            define ut_tst_stat  / order "Status"  style={verticalalign=middle width=80};

            *-- This hack removes TOC entries --*;
            break before dummy / page contents='';

            compute ut_tst_stat;
                if strip(lowcase(ut_tst_stat)) = "pass" then    call define(_col_, "style", "style={background=cxa7e8b8}");
                else                                            call define(_col_, "style", "style={background=cxfab4b4}");
            endcomp;
        run;
    %end;

    ods pdf close;
%mend ut_report;
