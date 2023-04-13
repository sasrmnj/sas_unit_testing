%macro ut_assert_dataset(description=, ds_01=, ds_02=, expected_result=PASS);
/*
    To be used to assert datasets are identical
    description:        description to explain why ds_01 should be equal to ds_02
    ds_01:              name of the first dataset
    ds_02:              name of the second dataset
*/
    %ut_init(type=ut_assert_dataset, description=&description., expected_result=&expected_result.);

    proc compare data=&ds_01. compare=&ds_02. noprint;
    run;

    *-- Check the result of the proc compare (store into sysinfo) --*;
    %if &sysinfo. = 0 %then %do;
        %let ut_res = PASS;
        %let ut_det = Datasets &ds_01. and &ds_02. are identical;
    %end;
    %else %do;
        %let ut_res = FAIL;
        %let ut_det = Datasets &ds_01. and &ds_02. are different;
    %end;

    %ut_log_result;
%mend ut_assert_dataset;
