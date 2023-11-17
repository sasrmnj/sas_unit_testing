%macro ut_setup;
/*
    Macro to set up the unit testing environment.
    To be run first and once.
*/
    %global ut_state
            ut_grp_id ut_grp_desc
            ut_tst_seq ut_tst_id ut_tst_type ut_tst_desc ut_tst_exp_res ut_tst_res ut_tst_det
            ut_work_dir ut_log_file
            ut_cov
    ;

    *-- Set framework state --*;
    %let ut_state = 0;

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

    *-- Flag to state if code coverage is enabled (1) or not (0) --*;
    %let ut_cov = 0;

    *--
        Dataset to store the results of the tests
        Each call to an assert function insert a record in this dataset
    --*;
    data _ut_results;
        attrib  ut_grp_id       format=best.    label="Testing group ID"
                ut_grp_desc     format=$200.    label="Testing group description"
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

        *-- Init all variables --*;
        call missing(of _all_);
    run;
%mend ut_setup;