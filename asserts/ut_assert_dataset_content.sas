%macro ut_assert_dataset_content(description=, ds_01=, ds_02=, bmask=1111111100000000, expected_result=PASS);
/*
    To be used to assert dataset contents are equals
    description:        description to explain why ds_01 content should be equal to ds_02 content
    ds_01:              name of the first dataset
    ds_02:              name of the second dataset
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

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

        To define if content mismatch, we focus on bits 7 to 16
        Bits 1 to 8 are not significant in the scope of content mismatch
    --*;

    *-- Convert the binary mask to numeric --*;
    %local nmask;
    %let nmask = %sysfunc(inputn(&bmask., binary16.));

    *-- Use sysinfo and bmask to identify if any relevant bit is active --*;
    %local rec;
    %let res = %sysfunc(band(&sysinfo., &nmask.));
    
    %if &res. = 0  %then %do;
        %let ut_tst_res = PASS;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have the same content;
    %end;
    %else %do;
        %let ut_tst_res = FAIL;
        %let ut_tst_det = Datasets &ds_01. and &ds_02. have different content;
    %end;

    %ut_log_result;
%mend ut_assert_dataset_content;
