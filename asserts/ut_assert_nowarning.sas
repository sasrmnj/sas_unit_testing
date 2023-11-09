%macro ut_assert_nowarning(description=, expected_result=PASS);
/*
    To be used to assert a warning is not expected
    description:        description to explain why a warningis not expected
    expected_result:    either PASS or FAIL
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

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