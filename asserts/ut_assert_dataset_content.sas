%macro ut_assert_dataset_content(description=, ds_01=, ds_02=, expected_result=PASS);
/*
    To be used to assert dataset contents are equals
    description:        description to explain why ds_01 content should be equal to ds_02 content
    ds_01:              name of the first dataset
    ds_02:              name of the second dataset
*/
    %ut_tst_init(type=ut_assert_dataset_content, description=&description., expected_result=&expected_result.);

    proc compare data=&ds_01. compare=&ds_02. noprint;
    run;

    *-- Statement provided to check macro variable value, so continue testing --*;
    *--
        Note: sysinfo is a binary number
        bit #1 (1)      Dataset labels differ
        bit #2 (2)      Dataset types differ
        bit #3 (4)      Variable informats differ
        bit #4 (8)      Variable formats differ
        bit #5 (16)     Variable lengths differ
        bit #6 (32)     Variable labels differ
        bit #7 (64)     Base dataset has obs not in comparison dataset
        bit #8 (128)    Comparison dataset has obs not in base dataset
        bit #9 (256)    Base dataset has BY group not in comparison dataset
        bit #10 (512)   Comparison dataset has BY group not in base dataset
        bit #11 (1024)  Base dataset has variable not in comparison dataset
        bit #12 (2048)  Comparison dataset has variable not in base dataset
        bit #13 (4096)  A value comparison was unequal
        bit #14 (8192)  Conflicting variable type
        bit #15 (16384) BY variables do not match
        bit #16 (32768) Fatal error, comparison not done

        So any code >= 64 reports an issue with the content
    --*;
    %if &sysinfo. < 64  %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have the same content;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have different content;
    %end;

    %ut_log_result;
%mend ut_assert_dataset_content;