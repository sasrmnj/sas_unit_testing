%macro ut_assert_dataset_structure(description=, ds_01=, ds_02=, expected_result=PASS);
/*
    To be used to assert dataset structures are the same
    description:        description to explain why ds_01 structure should be equal to ds_02 structure
    ds_01:              name of the first dataset
    ds_02:              name of the second dataset
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_err. %then %do;
        %return;
    %end;

    %ut_tst_init(type=ut_assert_dataset_structure, description=&description., expected_result=&expected_result.);

    proc contents data=&ds_01. out=content_01(keep=name type length varnum label format formatl formatd informat informl informd just npos) noprint;
    run;

    proc contents data=&ds_02. out=content_02(keep=name type length varnum label format formatl formatd informat informl informd just npos) noprint;
    run;

    proc compare data=content_01 compare=content_02 noprint;
    run;

    *-- Check the result of the proc compare (store into sysinfo) --*;
    %if &sysinfo. = 0 %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have the same structure;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have different structures;
    %end;

    %ut_log_result;
%mend ut_assert_dataset_structure;