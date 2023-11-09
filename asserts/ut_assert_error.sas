%macro ut_assert_error(description=, error_msg=, expected_result=PASS);
/*
    To be used to assert an error is expected
    Note: this function searches for the current error message
    If you search for a specific error that could have occured earlier, you might have to use ut_assert_log
    description:        description to explain why an error is expected
    error_msg:          error message expected either in the SAS log or in the system
    expected_result:    either PASS or FAIL
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

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