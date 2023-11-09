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