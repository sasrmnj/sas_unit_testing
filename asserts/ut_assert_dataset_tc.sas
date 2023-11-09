%macro ut_assert_dataset_tc(ds=, desc_var=, eval_stmt=, exp_status_var=, det_var=);
/*
    To be used to run test cases provided in a dataset
    ds:                 dataset with test cases
    desc_var:           variable name within ds that contains the test description
    eval_stmt:          SAS statement to evaluate if the test is PASS or FAIL
    exp_status_var:     variable name within ds that contains the expected status of the test
    det_var:            variable name within ds that contains the test details
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

    %local lib_name ds_name _tc_count _i_ cnt description status details;

    *-- Extract libname and memname of "ds" --*;
    %let lib_name   = work;
    %let ds_name    = &ds.;

    %if %sysfunc(countw(&ds_name., '.')) > 1 %then %do;
        %let lib_name    = %scan(&ds., 1, '.');
        %let ds_name     = %scan(&ds., 2, '.');
    %end;

    *-- Count number of test cases present in driver ds --*;
    proc sql noprint;
        select      nobs
        into        :_tc_count trimmed
        from        dictionary.tables
        where       strip(lowcase(libname)) = strip(lowcase("&lib_name."))
            and     strip(lowcase(memname)) = strip(lowcase("&ds_name."))
        ;
    quit;

    *-- Loop throught the tests cases --*;
    %do _i_ = 1 %to &_tc_count.;
        *-- Extract the test description --*;
        %let description=;
        proc sql noprint;
            select      count(*)
            into        :cnt trimmed
            from        dictionary.columns
            where       strip(lowcase(libname)) = strip(lowcase("&lib_name."))
                and     strip(lowcase(memname)) = strip(lowcase("&ds_name."))
                and     strip(lowcase(name)) = strip(lowcase("&desc_var."))
            ;
        quit;

        %if &cnt = 1 %then %do;
            proc sql noprint;
                select      &desc_var.
                into        :description trimmed
                from        &ds. (firstobs=&_i_. obs=&_i_.)
                ;
            quit;
        %end;

        *-- Extract the expected test status --*;
        %let status=PASS;

        proc sql noprint;
            select      count(*)
            into        :cnt trimmed
            from        dictionary.columns
            where       strip(lowcase(libname)) = strip(lowcase("&lib_name."))
                and     strip(lowcase(memname)) = strip(lowcase("&ds_name."))
                and     strip(lowcase(name)) = strip(lowcase("&exp_status_var."))
            ;
        quit;

        %if &cnt = 1 %then %do;
            proc sql noprint;
                select      upcase(&exp_status_var.)
                into        :status trimmed
                from        &ds. (firstobs=&_i_. obs=&_i_.)
                ;
            quit;
        %end;

        %ut_tst_init(type=ut_assert_dataset_tc, description=&description., expected_result=&status.);

        *-- Extract the test details --*;
        %let details="";

        proc sql noprint;
            select      count(*)
            into        :cnt trimmed
            from        dictionary.columns
            where       strip(lowcase(libname)) = strip(lowcase("&lib_name."))
                and     strip(lowcase(memname)) = strip(lowcase("&ds_name."))
                and     strip(lowcase(name)) = strip(lowcase("&det_var."))
            ;
        quit;

        %if &cnt = 1 %then %do;
            proc sql noprint;
                select      &det_var.
                into        :details trimmed
                from        &ds. (firstobs=&_i_. obs=&_i_.)
                ;
            quit;
        %end;

        *-- Evaluate the test case --*;
        data _null_;
            set &ds. (firstobs=&_i_. obs=&_i_.);

            if %unquote(&eval_stmt.) then do;
                call symputx('ut_tst_res', "PASS");
                call symputx('ut_tst_det', "Test '&eval_stmt.' valid.^n" || strip(&det_var.));
            end;
            else do;
                call symputx('ut_tst_res', "FAIL");
                call symputx('ut_tst_det', "Test '&eval_stmt.' is not successful.^n" || strip(&det_var.));
            end;
        run;

        %ut_log_result;
    %end;
%mend ut_assert_dataset_tc;