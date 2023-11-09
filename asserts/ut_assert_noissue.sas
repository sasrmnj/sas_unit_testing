%macro ut_assert_noissue(description=, expected_result=PASS);
/*
    To be used to assert an issue is not expected (i.e. no error, no warning)
    description:        description to explain why an issue is not expected
    expected_result:    either PASS or FAIL
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

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