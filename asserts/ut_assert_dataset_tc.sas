%macro ut_assert_dataset_tc(ds=, desc_var=, eval_stmt=, det_var=);
/*
    To be used to run test cases provided in a dataset
    ds:                 dataset with test cases
    desc_var:           variable name within ds that contains the test description
    eval_stmt:          SAS statement to evaluate if the test is PASS or FAIL
    det_stmt:           SAS statement to define the value of the test details
*/
    *-- Extract libname and memname of "ds" --*;
    %let lib_name = %scan(&ds., -2, .);
    %let ds_name = %scan(&ds., -1, .);

    *-- Count number of test cases present in driver ds --*;
    proc sql noprint;
        select      nobs
        into        :_tc_count trimmed
        from        dictionary.tables
        where       strip(lowcase(libname)) = strip(lowcase(coalescec("&lib_name.", "work")))
            and     strip(lowcase(memname)) = strip(lowcase("&ds_name."))
        ;
    quit;

    *-- Loop throught the tests cases --*;
    %do _i_ = 1 %to &_tc_count.;
        *-- Extract the test description --*;
        %let description=;
        proc sql noprint;
            select      description
            into        :description trimmed
            from        &ds. (firstobs=&_i_. obs=&_i_.)
            ;
        quit;

        %ut_tst_init(type=ut_assert_dataset_tc, description=&description., expected_result=&expected_result.);

        *-- Evaluate the test case --*;
        data _null_;
            set &ds. (firstobs=&_i_. obs=&_i_.);

            if %unquote(&eval_stmt.) then do;
                call symputx('ut_tst_stat', "PASS");
                call symputx('ut_tst_det', "Test '&eval_stmt.' valid.^n" || strip(&det_var.));
            end;
            else do;
                call symputx('ut_tst_stat', "FAIL");
                call symputx('ut_tst_det', "Test '&eval_stmt.' is not successful.^n" || strip(&det_var.));
            end;
        run;

        %ut_log_result;
    %end;
%mend ut_assert_dataset_tc;