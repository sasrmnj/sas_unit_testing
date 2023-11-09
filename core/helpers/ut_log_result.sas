%macro ut_log_result;
/*
    Macro to insert the result of a test into the result dataset.
    This function is used by assert functions and shoudn't be used out of this scope
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

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