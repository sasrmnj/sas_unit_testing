%macro ut_grp_init(description);
/*
    Macro to initialize a group of test.
    A group can be used when multiple tests are needed to validate a feature.
    In this case, all the tests can be grouped with a common description
    description:        description of the group of tests
*/
    *-- Increment test group id by 1 --*;
    %let ut_grp_id = %eval(&ut_grp_id. + 1);

    *-- Reset test order --*;
    %let ut_seq = 0;

    *-- Set test group description --*;
    %if %sysevalf(%superq(description) ne, boolean) %then   %let ut_grp_desc = %nrbquote(&description.);
    %else                                                   %let ut_grp_desc = Testing group #&ut_grp_id.;
%mend ut_grp_init;
