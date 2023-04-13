%macro ut_assert_file(description=, filepath=, expected_result=PASS);
/*
    To be used to assert a file is expected
    description:        description to explain why a file is expected
    filepath:           the expected file full path
    expected_result:    either PASS or FAIL
*/
    %ut_init(type=ut_assert_file, description=&description., expected_result=&expected_result.);

    %if %sysfunc(fileexist("&filepath.")) %then %do;
        %let ut_res = PASS;
        %let ut_det = Expected file %nrbquote(&filepath.) found;
    %end;
    %else %do;
        %let ut_res = FAIL;
        %let ut_det = Expected file %nrbquote(&filepath.) not found;
    %end;

    %ut_log_result;
%mend ut_assert_file;