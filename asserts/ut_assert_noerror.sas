%macro ut_assert_noerror(description=, expected_result=PASS);
/*
    To be used to assert an error is not expected
    description:        description to explain why an error is not expected
    expected_result:    either PASS or FAIL
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

    *-- Create a new test --*;
    %ut_tst_init(type=ut_assert_noerror, description=&description., expected_result=&expected_result.);

    %if %sysevalf(%superq(syserrortext) =, boolean) and &syscc. < 5 %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = No error message reported by SAS;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Error reported by SAS is:^n%nrbquote(&syserrortext.)^n^nwhereas no error was expected;
    %end;

    %ut_log_result;
%mend ut_assert_noerror;