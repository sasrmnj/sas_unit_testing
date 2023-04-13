%macro ut_assert_nowarning(description=, expected_result=PASS);
/*
    To be used to assert a warning is not expected
    description:        description to explain why a warningis not expected
    expected_result:    either PASS or FAIL
*/
    %ut_init(type=ut_assert_nowarning, description=&description., expected_result=&expected_result.);

    %if %sysevalf(%superq(syswarningtext) =, boolean) and &syscc. < 4 %then %do;
        %let ut_res = PASS;
        %let ut_det = No warning message reported by SAS.;
    %end;
    %else %do;
        %let ut_res = FAIL;
        %let ut_det = Warning reported by SAS is:^n%nrbquote(&syswarningtext.)^n^nwhereas no warning was expected;
    %end;

    %ut_log_result;
%mend ut_assert_nowarning;