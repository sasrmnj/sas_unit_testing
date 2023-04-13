%macro ut_log_result;
/*
    Macro to insert the result of a test into the result dataset.
    This function is used by assert functions and shoudn't be used out of this scope
*/
    *-- Define test status --*;
    %if %lowcase(&ut_res.) = %lowcase(&ut_exp_res.) %then   %let ut_stat = PASS;
    %else                                                   %let ut_stat = FAIL;

    proc sql noprint;
        insert into _ut_results
        set ut_grp_id   = &ut_grp_id.,
            ut_grp_desc = "%nrbquote(&ut_grp_desc.)",
            ut_seq      = &ut_seq.,
            ut_id       = strip("&ut_id."),
            ut_type     = strip("&ut_type."),
            ut_desc     = "%nrbquote(&ut_desc.)",
            ut_exp_res  = strip("&ut_exp_res."),
            ut_res      = strip("&ut_res."),
            ut_stat     = strip("&ut_stat."),
            ut_det      = "%nrbquote(&ut_det.)"
        ;
    quit;
%mend ut_log_result;