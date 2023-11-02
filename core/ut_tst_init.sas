%macro ut_tst_init(type=, description=, expected_result=);
/*
    Macro to create and initialize a test.
    For that, it defines and initializes some global variables which are used to fill the result dataset.
    This function is used by assert functions and shoudn't be used out of this scope
    type:               type of test
    description:        description of the test
    expected_result:    expected result of the test (either PASS or FAIL)
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_err. %then %do;
        %return;
    %end;

    *-- Increment test sequence by 1 --*;
    %let ut_tst_seq = %eval(&ut_tst_seq. + 1);

    *-- Derive test id --*;
    %let ut_tst_id = %cmpres(&ut_grp_id..&ut_tst_seq.);

    *-- Set test type --*;
    %if %sysevalf(%superq(type) ne, boolean) %then              %let ut_tst_type = %nrbquote(&type.);
    %else                                                       %let ut_tst_type = %lowcase(%sysmexecname(%sysmexecdepth - 2));

    *-- Set test description --*;
    %if %sysevalf(%superq(description) ne, boolean) %then       %let ut_tst_desc = %nrbquote(&description.);
    %else                                                       %let ut_tst_desc = Test #&ut_tst_id.;

    *-- Set expected test result (PASS by default) --*;
    %if %sysevalf(%superq(expected_result) =, boolean) %then    %let expected_result = PASS;
    %let ut_tst_exp_res = &expected_result.;

    *-- Set test result to FAIL by default --*;
    %let ut_tst_res = FAIL;

    *-- Reset test details --*;
    %let ut_tst_det = ;
%mend ut_tst_init;