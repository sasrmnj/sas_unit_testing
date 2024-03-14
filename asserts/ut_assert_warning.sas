%macro ut_assert_warning(description=, warning_msg=, expected_result=PASS);
/*
    To be used to assert a warning is expected
    Note: this function searches for the current warning message
    If you search for a specific warning that could have occured earlier, you might have to use ut_assert_log
    description:        description to explain why a warning is expected
    warning_msg:        warning message expected either in the SAS log or in the system
    expected_result:    either PASS or FAIL
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

    %ut_tst_init(type=ut_assert_warning, description=&description., expected_result=&expected_result.);

    %if &syscc. %then %do;
        %if %sysevalf(%superq(warning_msg) ne, boolean) %then %do;
            *-- If expected warning message is provided, then SAS warning message must match --*;
            
            *-- Remove the leading "WARNING:" tag from the warning message if any --*;
            %let warning_msg = %sysfunc(prxchange(s/^WARNING:\s*(.*)$/$1/oi, -1, %nrbquote(&warning_msg.)));

            *-- Define a macro variable to store the result of ut_search_log --*;
            %local ut_search_log;
            %let ut_search_log=;

            *-- Search for the warning message in the SAS log --*;
            %ut_search_log(log_type=warning, log_msg=%nrbquote(&warning_msg.), res_var=ut_search_log);

            %if &ut_search_log. = TRUE %then %do;
                %let ut_tst_res = PASS;
                %let ut_tst_det = Expected warning:^n%nrbquote(&warning_msg.)^n^nfound in the SAS log;
            %end;
            %else %do;
                %let ut_tst_res = FAIL;
                %let ut_tst_det = Expected warning:^n%nrbquote(&warning_msg.)^n^nnot found in the SAS log;
            %end;
        %end;
        %else %do;
            %let ut_tst_res = PASS;
            %let ut_tst_det = Warning reported by SAS is:^n%nrbquote(&syswarningtext.);
        %end;
    %end;

    %ut_log_result;
%mend ut_assert_warning;
