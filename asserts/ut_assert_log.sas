%macro ut_assert_log(description=, log_type=, log_msg=, expected_result=PASS);
/*
    To be used to assert a log message is expected
    Note: this function searches for SAS log for a specific message
    description:        description to explain why a message in the log is expected
    log_type:           type of log message (ERROR, WARNING, NOTE...)
    log_msg:            expected text in the log
    expected_result:    either PASS or FAIL
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_err. %then %do;
        %return;
    %end;

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