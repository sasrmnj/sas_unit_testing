/*
    This script builds a SAS file that contains all the macros of the unit testing framework.
    This allows to use the unit testing framework with a simple "include" statement.
*/

*-- Path of the project --*;
%let project_path       = ~/sas_unit_testing;

*-- Path to the SAS file containing the macro to be tested --*;
%let macro_path         = &project_path./unit_testing.sas;

*-- Path to the unit testing framework --*;
%let ut_framework       = &project_path./unit_testing.sas;

*-- Report parameters --*;
%let script_name        = unit_testing;
%let report_path        = &project_path./tests/reports;

***************************** Start of study-specific programming ******************************;


*-- Load the unit testing framework --*;
%include "&ut_framework.";

*-- Include the definition of the macro to be validated --*;
%include "&macro_path.";

*---------------------------------------------------------------------------------------------*;
*-- Initialize the testing framework                                                        --*;
*---------------------------------------------------------------------------------------------*;

%ut_setup;

*---------------------------------------------------------------------------------------------*;
*-- testing                                                                                 --*;
*---------------------------------------------------------------------------------------------*;

*-------------------------------------------------------------------------*;
*-- Testing of "ut_setup"                                               --*;
*-------------------------------------------------------------------------*;
%ut_grp_init(description=Testing of "ut_setup");

%ut_assert_macro(
    description = %nrstr("ut_setup" must create macro variable "ut_grp_id"),
    stmt        = %nrstr(%symexist(ut_grp_id))
);

%ut_assert_macro(
    description = %nrstr("ut_setup" must create macro variable "ut_grp_desc"),
    stmt        = %nrstr(%symexist(ut_grp_desc))
);

%ut_assert_macro(
    description = %nrstr("ut_setup" must create macro variable "ut_tst_seq"),
    stmt        = %nrstr(%symexist(ut_tst_seq))
);

%ut_assert_macro(
    description = %nrstr("ut_setup" must create macro variable "ut_tst_id"),
    stmt        = %nrstr(%symexist(ut_tst_id))
);

%ut_assert_macro(
    description = %nrstr("ut_setup" must create macro variable "ut_tst_type"),
    stmt        = %nrstr(%symexist(ut_tst_type))
);

%ut_assert_macro(
    description = %nrstr("ut_setup" must create macro variable "ut_tst_desc"),
    stmt        = %nrstr(%symexist(ut_tst_desc))
);

%ut_assert_macro(
    description = %nrstr("ut_setup" must create macro variable "ut_tst_exp_res"),
    stmt        = %nrstr(%symexist(ut_tst_exp_res))
);

%ut_assert_macro(
    description = %nrstr("ut_setup" must create macro variable "ut_tst_res"),
    stmt        = %nrstr(%symexist(ut_tst_res))
);

%ut_assert_macro(
    description = %nrstr("ut_setup" must create macro variable "ut_tst_det"),
    stmt        = %nrstr(%symexist(ut_tst_det))
);


*-- Check the dataset created by ut_setup --*;

*-- The expected dataset --*;
data expected_dataset (drop = _i_);
    attrib  ut_grp_id       format=best.    label="Testing group ID"
            ut_grp_desc     format=$200.    label="Testing group description"
            ut_tst_seq      format=best.    label="Test ordering value"
            ut_tst_id       format=$20.     label="Test ID"
            ut_tst_type     format=$30.     label="Test type"
            ut_tst_desc     format=$200.    label="Test description"
            ut_tst_exp_res  format=$10.     label="Expected test result"
            ut_tst_res      format=$10.     label="Test result"
            ut_tst_stat     format=$10.     label="Test status"
            ut_tst_det      format=$500.    label="Test details"
    ;

    set _null_;

    *-- Init all variables --*;
    array my_chars[*] _character_;
    do _i_=1 to dim(my_chars);
        my_chars[_i_] = '';
    end;

    array my_nums[*] _numeric_;
    do _i_=1 to dim(my_nums);
        my_nums[_i_] = .;
    end;
run;

%ut_assert_dataset_structure(
    description     = %nrstr("ut_setup" must create an empty dataset to store testing results),
    ds_01           = _ut_results,
    ds_02           = expected_dataset
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_grp_init"                                            --*;
*-------------------------------------------------------------------------*;

*-- Store the value of ut_grp_id before calling ut_grp_init --*;
%let prv_ut_grp_id = &ut_grp_id.;

*-- Set ut_tst_seq value to something <> 0 to ensure it is reset by ut_grp_init --*;
%let ut_tst_seq = 1;

*-- Define a custom description --*;
%let custom_desc=Testing of "ut_grp_init";

%ut_grp_init(description=&custom_desc.);

*-- Copy value of ut_tst_seq because any unit testing helper will update that value --*;
%let ut_tst_seq_copy = &ut_tst_seq.;

%ut_assert_macro(
    description = %nrstr("ut_grp_init" must increment ut_grp_id by 1),
    stmt        = %nrstr(&ut_grp_id. = &prv_ut_grp_id. + 1)
);

%ut_assert_macro(
    description = %nrstr("ut_grp_init" must reset the value of ut_tst_seq to 0),
    stmt        = %nrstr(&ut_tst_seq_copy. = 0)
);

%ut_assert_macro(
    description = %nrstr("ut_grp_init" must set the value of ut_grp_desc),
    stmt        = %nrstr(&ut_grp_desc. = &custom_desc.)
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_run"                                                 --*;
*-------------------------------------------------------------------------*;

*-- Nothing to test so far --*;


*-------------------------------------------------------------------------*;
*-- Testing of "ut_tst_init"                                            --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_tst_init");

*-- Define parameters in macro varialbes to allow testing --*;
%let prv_ut_tst_seq         = &ut_tst_seq.;
%let custom_type            = custom_type;
%let custom_desc            = Testing of "ut_tst_init";
%let custom_ut_tst_exp_res  = PASS;

%ut_tst_init(type=&custom_type., description=&custom_desc., expected_result=&custom_ut_tst_exp_res.);

*-- Copy values of macro variables because any unit testing helper will update their value --*;
%let ut_tst_seq_copy        = &ut_tst_seq.;
%let ut_tst_type_copy       = &ut_tst_type.;
%let ut_tst_desc_copy       = &ut_tst_desc.;
%let ut_tst_exp_res_copy    = &ut_tst_exp_res.;

%ut_assert_macro(
    description = %nrstr("ut_tst_init" must increment ut_tst_seq by 1),
    stmt        = %nrstr(&ut_tst_seq_copy. = &prv_ut_tst_seq. + 1)
);

%ut_assert_macro(
    description = %nrstr("ut_tst_init" must set the value of ut_tst_id),
    stmt        = %nrstr(&ut_tst_id. = %cmpres(&ut_grp_id..&ut_tst_seq.))
);

%ut_assert_macro(
    description = %nrstr("ut_tst_init" must set the value of ut_tst_type with the given type value),
    stmt        = %nrstr(&ut_tst_type_copy. = &custom_type.)
);

%ut_assert_macro(
    description = %nrstr("ut_tst_init" must set the value of ut_tst_desc),
    stmt        = %nrstr(&ut_tst_desc_copy. = &custom_desc.)
);

%ut_assert_macro(
    description = %nrstr("ut_tst_init" must set the value of ut_tst_exp_res),
    stmt        = %nrstr(&ut_tst_exp_res_copy. = &custom_ut_tst_exp_res.)
);

%ut_assert_macro(
    description = %nrstr("ut_tst_init" must reset the value of ut_tst_res),
    stmt        = %nrstr(&ut_tst_res. = FAIL)
);

%ut_assert_macro(
    description = %nrstr("ut_tst_init" must reset the value of ut_tst_det),
    stmt        = %nrstr(&ut_tst_det. =)
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_log_result"                                          --*;
*-------------------------------------------------------------------------*;

*-- Nothing to test so far --*;


*-------------------------------------------------------------------------*;
*-- Testing of "ut_search_log"                                          --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_search_log");


*-- Create a dummy log file --*;
data test_data;
    attrib txt format=$256.;

    txt="NOTE: as simple line";
    output;

    txt="WARNING: a warning message";
    output;

    txt="ERROR: an error message";
    output;

    txt="OTHER: a message with a different tag";
    output;
run;

%let work = %quote(%sysfunc(pathname(work)));

proc export data=test_data dbms=csv outfile="&work./sample.log" replace;
    putnames=no;
run;


*-- TEST: LOG_FILE is mandatory --*;
%ut_run(
    stmt = %nrstr(
        %ut_search_log(log_file=, log_type=, log_msg=, res_var=);
    )
);

%ut_assert_error(
    description = %nrstr("ut_search_log" must raise an error when LOG_FILE is missing),
    error_msg   = LOG_FILE is mandatory when calling ut_search_log
);


*-- TEST: LOG_FILE must be a valid file --*;
*-- note: use "ut_run" to capture WARNING/ERROR --*;
%ut_run(
    stmt = %nrstr(
        %ut_search_log(log_file=&work./popcorn.log, log_type=, log_msg=, res_var=);
    )
);

%ut_assert_error(
    description = %nrstr("ut_search_log" must raise an error when LOG_FILE is invalid),
    error_msg   = LOG_FILE does not exist
);


*-- TEST: RES_VAR is mandatory --*;
%ut_run(
    stmt = %nrstr(
        %ut_search_log(log_file=&work./sample.log, log_type=, log_msg=, res_var=);
    )
);

%ut_assert_error(
    description = %nrstr("ut_search_log" must raise an error when RES_VAR is missing),
    error_msg   = RES_VAR is mandatory when calling ut_search_log
);


*-- Define a macro variable to store the result of ut_search_log for the following tests --*;
%let res=;

*-- TEST: valid LOG_TYPE --*;
%ut_search_log(log_file=&work./sample.log, log_type=OTHER, log_msg=, res_var=res);

%ut_assert_macro(
    description = %nrstr("ut_search_log" must return TRUE when LOG_TYPE type exists in the log file),
    stmt        = %nrstr(&res. = TRUE)
);


*-- TEST: invalid LOG_TYPE --*;
%ut_search_log(log_file=&work./sample.log, log_type=NOTEXISTING, log_msg=, res_var=res);

%ut_assert_macro(
    description = %nrstr("ut_search_log" must return FALSE when LOG_TYPE type does not exist in the log file),
    stmt        = %nrstr(&res. = FALSE)
);


*-- TEST: valid LOG_MSG --*;
%ut_search_log(log_file=&work./sample.log, log_type=, log_msg=message, res_var=res);

%ut_assert_macro(
    description = %nrstr("ut_search_log" must return TRUE when LOG_MSG exists in the log file),
    stmt        = %nrstr(&res. = TRUE)
);


*-- TEST: invalid LOG_MSG --*;
%ut_search_log(log_file=&work./sample.log, log_type=, log_msg=popcorn, res_var=res);

%ut_assert_macro(
    description = %nrstr("ut_search_log" must return FALSE when LOG_MSG does not exist in the log file),
    stmt        = %nrstr(&res. = FALSE)
);


*-- TEST: valid LOG_TYPE/LOG_MSG --*;
%ut_search_log(log_file=&work./sample.log, log_type=WARNING, log_msg=message, res_var=res);

%ut_assert_macro(
    description = %nrstr("ut_search_log" must return TRUE when LOG_TYPE/LOG_MSG type exists in the log file),
    stmt        = %nrstr(&res. = TRUE)
);


*-- TEST: invalid LOG_TYPE/LOG_MSG --*;
%ut_search_log(log_file=&work./sample.log, log_type=WARNING, log_msg=error, res_var=res);

%ut_assert_macro(
    description = %nrstr("ut_search_log" must return FALSE when LOG_TYPE/LOG_MSG type exists in the log file),
    stmt        = %nrstr(&res. = FALSE)
);


*-- TEST: ut_search_log is case insensitive --*;
%ut_search_log(log_file=&work./sample.log, log_type=ErrOr, log_msg=MeSsaGe, res_var=res);

%ut_assert_macro(
    description = %nrstr("ut_search_log" is not case sensitive),
    stmt        = %nrstr(&res. = TRUE)
);


*-- TEST: call to "ut_search_log" must NOT increment ut_grp_id by 1 --*;

*-- Store ut_tst_seq before calling ut_assert_log --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_search_log(log_file=&work./sample.log, log_type=ErrOr, log_msg=MeSsaGe, res_var=res);

*-- Store ut_tst_seq after calling ut_assert_log --*;
%let cur_ut_tst_seq = &ut_tst_seq.;

*-- Ensure ut_tst_seq did not change --*;
%ut_assert_macro(
    description = "ut_search_log" must not alter ut_tst_seq value,
    stmt        = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq.)
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_log"                                          --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_log");

*-- TEST: call to "ut_assert_log" must increment ut_grp_id by 1 --*;

*-- Store ut_tst_seq before calling ut_assert_log --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_assert_log(
    description = "ut_assert_log" must increment ut_tst_seq by 1 (increment),
    log_msg     = note
);

*-- Store ut_tst_seq after calling ut_assert_log --*;
%let cur_ut_tst_seq = &ut_tst_seq.;

*-- Ensure ut_tst_seq has been incremented by ut_assert_log --*;
%ut_assert_macro(
    description = "ut_assert_log" must increment ut_tst_seq by 1 (test increment),
    stmt        = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);


*-- TEST: "ut_assert_log" must allow to search specific text into a log file  --*;
%ut_run(
    stmt = %nrstr(
        %put some message;
    )
);

%ut_assert_log(
    description     = %nrstr("ut_assert_log" must be PASS when expected message exists in the log),
    log_msg         = some message
);

%ut_assert_log(
    description     = %nrstr("ut_assert_log" must be FAIL when expected message does not exist in the log),
    log_msg         = another message,
    expected_result = FAIL
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_error"                                        --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_error");

*-- TEST: call to "ut_assert_error" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

*-- Raise an error so the call to ut_assert_error will not appear as a validation error --*;
%ut_run(
    stmt = %nrstr(
        %put ERROR: error message;
    )
);

%ut_assert_error(
    description = "ut_assert_error" must increment ut_tst_seq by 1 (increment)
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description = "ut_assert_error" must increment ut_tst_seq by 1 (test increment),
    stmt        = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);


*-- TEST: in case of error --*;

*-- Statement that simulates an error --*;
%ut_run(
    stmt = %nrstr(
        %put ERROR: error message;
    )
);

%ut_assert_error(
    description     = %nrstr("ut_assert_error" in case of ERROR must be PASS)
);

%ut_assert_error(
    description     = %nrstr("ut_assert_error", with expected error message, must be PASS in case of ERROR with the correct message),
    error_msg       = error message
);

%ut_assert_error(
    description     = %nrstr("ut_assert_error", with expected error message, must be FAIL in case of ERROR with the incorrect message),
    error_msg       = invalid error message,
    expected_result = FAIL
);


*-- TEST: when no error --*;

*-- Statement that simulates an errorless situation  --*;
%ut_run(
    stmt = %nrstr(
        %put no error;
    )
);

%ut_assert_error(
    description     = %nrstr("ut_assert_error" must be FAIL if no ERROR),
    expected_result = FAIL
);

%ut_assert_error(
    description     = %nrstr("ut_assert_error", with expected error message, must be FAIL if no ERROR),
    error_msg       = error message,
    expected_result = FAIL
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_noerror"                                      --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_noerror");

*-- TEST: call to "ut_assert_noerror" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_assert_noerror(
    description     = %nrstr("ut_assert_noerror" must increment ut_tst_seq by 1 (increment))
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description     = %nrstr("ut_assert_noerror" must increment ut_tst_seq by 1 (test)),
    stmt            = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);

*-- TEST: in case of error --*;

*-- Statement that simulates an error  --*;
%ut_run(
    stmt = %nrstr(
        %put ERROR: error message;
    )
);

%ut_assert_noerror(
    description     = %nrstr("ut_assert_noerror" in case of ERROR must be FAIL),
    expected_result = FAIL
);


*-- TEST: when no error --*;

*-- Statement that simulates an errorless situation  --*;
%ut_run(
    stmt = %nrstr(
        %put no error;
    )
);

%ut_assert_noerror(
    description     = %nrstr("ut_assert_noerror" must be PASS if no ERROR)
);



*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_warning"                                      --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_warning");

*-- TEST: call to "ut_assert_warning" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

*-- Raise a warning so the call to ut_assert_warning will not appear as a validation error --*;
%ut_run(
    stmt = %nrstr(
        %put WARNING: warning message;
    )
);

%ut_assert_warning(
    description     = %nrstr("ut_assert_warning" must increment ut_tst_seq by 1 (increment))
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description     = %nrstr("ut_assert_warning" must increment ut_tst_seq by 1 (test)),
    stmt            = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);

*-- TEST: in case of warning --*;

*-- Statement that simulates a warning --*;
%ut_run(
    stmt = %nrstr(
        %put WARNING: warning message;
    )
);

%ut_assert_warning(
    description     = Call to "ut_assert_warning" in case of WARNING must be PASS
);

%ut_assert_warning(
    description     = %nrstr("ut_assert_warning", with expected warning message, must be PASS in case of WARNING with the correct message),
    warning_msg     = warning message
);

%ut_assert_warning(
    description     = %nrstr("ut_assert_warning", with expected warning message, must be FAIL in case of WARNING with the incorrect message),
    warning_msg     = invalid warning message,
    expected_result = FAIL
);

*-- TEST: when no warning --*;

*-- Statement that simulates no warning --*;
%ut_run(
    stmt = %nrstr(
        %put no warning;
    )
);

%ut_assert_warning(
    description     = Call to "ut_assert_warning" must be FAIL if no WARNING,
    expected_result = FAIL
);

%ut_assert_warning(
    description     = %nrstr("ut_assert_warning", with expected warning message, must be FAIL if no WARNING),
    warning_msg     = warning message,
    expected_result = FAIL
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_nowarning"                                    --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_nowarning");

*-- TEST: call to "ut_assert_nowarning" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_assert_nowarning(
    description     = %nrstr("ut_assert_nowarning" must increment ut_tst_seq by 1)
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description     = %nrstr("ut_assert_nowarning" must increment ut_tst_seq by 1 (test)),
    stmt            = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);


*-- TEST: in case of warning --*;

*-- Statement that simulates a warning --*;
%ut_run(
    stmt = %nrstr(
        %put WARNING: warning message;
    )
);

%ut_assert_nowarning(
    description     = %nrstr("ut_assert_nowarning" in case of WARNING must be FAIL),
    expected_result = FAIL
);


*-- TEST: when no warning --*;

*-- Statement that simulates no warning --*;
%ut_run(
    stmt = %nrstr(
        %put no warning;
    )
);

%ut_assert_nowarning(
    description     = %nrstr("ut_assert_nowarning" must be PASS if no WARNING)
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_noissue"                                      --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_noissue");

*-- TEST: call to "ut_assert_noissue" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_assert_noissue(
    description     = %nrstr("ut_assert_noissue" must increment ut_tst_seq by 1)
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description     = %nrstr("ut_assert_noissue" must increment ut_tst_seq by 1 (test)),
    stmt            = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);


*-- TEST: in case of warning --*;

*-- Statement that simulates a warning --*;
%ut_run(
    stmt = %nrstr(
        %put WARNING: warning message;
    )
);

%ut_assert_noissue(
    description     = %nrstr("ut_assert_noissue" in case of WARNING must be FAIL),
    expected_result = FAIL
);


*-- TEST: in case of error --*;

*-- Statement that simulates a error --*;
%ut_run(
    stmt = %nrstr(
        %put ERROR: error message;
    )
);

%ut_assert_noissue(
    description     = %nrstr("ut_assert_noissue" in case of ERROR must be FAIL),
    expected_result = FAIL
);


*-- TEST: in case of issue --*;

*-- Statement that simulates an issue --*;
%ut_run(
    stmt = %nrstr(
        %let syscc = 99;
    )
);

%ut_assert_noissue(
    description     = %nrstr("ut_assert_noissue" in case of invalid SYSCC must be FAIL),
    expected_result = FAIL
);


*-- TEST: when no issue --*;

*-- Statement that simulates an issue --*;
%ut_run(
    stmt = %nrstr(
        %put no issue;
    )
);

%ut_assert_noissue(
    description     = %nrstr("ut_assert_noissue" must be PASS if no WARNING and no ERROR)
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_file"                                         --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_file");

*-- TEST: call to "ut_assert_file" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_assert_file(
    description = %nrstr("ut_assert_file" must increment ut_tst_seq by 1 (increment)),
    filepath    = &macro_path.
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description = %nrstr("ut_assert_file" must increment ut_tst_seq by 1 (test)),
    stmt        = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);

*-- Testing in case of existing file --*;
%ut_assert_file(
    description     = %nrstr("ut_assert_file" in case of existing file must be PASS),
    filepath        = &macro_path.
);

*-- Testing in case of existing file --*;
%ut_assert_file(
    description     = %nrstr("ut_assert_file" in case of non existing file must be FAIL),
    filepath        = &macro_path._not_valid,
    expected_result = FAIL
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_macro"                                        --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_macro");

*-- TEST: call to "ut_assert_macro" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description = %nrstr("ut_assert_macro" must increment ut_tst_seq by 1 (increment)),
    stmt        = %nrstr(1 = 1)
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description = %nrstr("ut_assert_macro" must increment ut_tst_seq by 1 (test)),
    stmt        = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);


*-- TEST: valid test --*;
%ut_assert_macro(
    description     = %nrstr("ut_assert_macro" in case of valid and true statement must be PASS),
    stmt            = %nrstr(&syscc. = &syscc.)
);


*--TEST: invalid test --*;
%ut_assert_macro(
    description     = %nrstr("ut_assert_macro" in case of valid and true statement must be PASS),
    stmt            = %nrstr(&syscc. = %eval(&syscc. + 1)),
    expected_result = FAIL
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_dataset_structure"                            --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_dataset_structure");

*-- TEST: call to "ut_assert_dataset_structure" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_assert_dataset_structure(
    description = %nrstr("ut_assert_dataset_structure" must increment ut_tst_seq by 1 (increment)),
    ds_01       = _ut_results,
    ds_02       = _ut_results
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description = %nrstr("ut_assert_dataset_structure" must increment ut_tst_seq by 1 (test)),
    stmt        = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);


*-- TEST: identical datasets --*;

*-- Create datasets --*;
data ds_01 ds_02;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output;
run;

%ut_assert_dataset_structure(
    description     = %nrstr("ut_assert_dataset_structure" in case of identical datasets must be PASS),
    ds_01           = ds_01,
    ds_02           = ds_02
);

*-- TEST: datasets with same structure/different content --*;

*-- Create datasets --*;
data ds_01 ds_02;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output ds_01;
    var_01=1; var_02="y"; output ds_02;
run;

%ut_assert_dataset_structure(
    description     = %nrstr("ut_assert_dataset_structure" in case of same structure/different content must be PASS),
    ds_01           = ds_01,
    ds_02           = ds_02,
    expected_result = PASS
);


*-- TEST: datasets with same variables but some differences --*;

*-- Create datasets --*;
data ds_01;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output;
run;

data ds_02;
    attrib var_01 format=2. var_02 format=$10.;
    var_01=1; var_02="x"; output;
run;

%ut_assert_dataset_structure(
    description     = %nrstr("ut_assert_dataset_structure" in case of same structure with some differences (length, format) must be FAIL),
    ds_01           = ds_01,
    ds_02           = ds_02,
    expected_result = FAIL
);


*-- TEST: datasets with different structure --*;

*-- Create datasets --*;
data ds_01;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output;
run;

data ds_02;
    set ds_01;
    attrib var_03 format=$5.;
    var_03="";
run;

%ut_assert_dataset_structure(
    description     = %nrstr("ut_assert_dataset_structure" in case of structural differences (not the same variables) must be FAIL),
    ds_01           = ds_01,
    ds_02           = ds_02,
    expected_result = FAIL
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_dataset_content"                              --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_dataset_content");

*-- TEST: call to "ut_assert_dataset_content" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_assert_dataset_content(
    description = %nrstr("ut_assert_dataset_content" must increment ut_tst_seq by 1 (increment)),
    ds_01       = _ut_results,
    ds_02       = _ut_results
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description = %nrstr("ut_assert_dataset_content" must increment ut_tst_seq by 1 (test)),
    stmt        = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);


*-- TEST: identical datasets --*;

*-- Create datasets --*;
data ds_01 ds_02;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output;
run;

%ut_assert_dataset_content(
    description     = %nrstr("ut_assert_dataset_content" in case of identical datasets must be PASS),
    ds_01           = ds_01,
    ds_02           = ds_02
);

*-- TEST: datasets with same variables but some differences --*;

*-- Create datasets --*;
data ds_01;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output;
run;

data ds_02;
    attrib var_01 format=2. var_02 format=$10.;
    var_01=1; var_02="x"; output;
run;

%ut_assert_dataset_content(
    description     = %nrstr("ut_assert_dataset_content" in case of same structure with some differences (length, format) must be PASS),
    ds_01           = ds_01,
    ds_02           = ds_02,
    expected_result = PASS
);


*-- TEST: datasets with different structure --*;

*-- Create datasets --*;
data ds_01;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output;
run;

data ds_02;
    set ds_01;
    attrib var_03 format=$5.;
    var_03="";
run;

%ut_assert_dataset_content(
    description     = %nrstr("ut_assert_dataset_content" in case of structural differences (not the same variables) must be FAIL),
    ds_01           = ds_01,
    ds_02           = ds_02,
    expected_result = FAIL
);


*-------------------------------------------------------------------------*;
*-- Testing of "ut_assert_dataset"                                      --*;
*-------------------------------------------------------------------------*;

%ut_grp_init(description=Testing of "ut_assert_dataset");

*-- TEST: call to "ut_assert_dataset" must increment ut_grp_id by 1 --*;
%let prv_ut_tst_seq = &ut_tst_seq.;

%ut_assert_dataset(
    description = %nrstr("ut_assert_dataset" must increment ut_tst_seq by 1 (increment)),
    ds_01       = _ut_results,
    ds_02       = _ut_results
);

%let cur_ut_tst_seq = &ut_tst_seq.;

%ut_assert_macro(
    description = %nrstr("ut_assert_dataset" must increment ut_tst_seq by 1 (test)),
    stmt        = %nrstr(&cur_ut_tst_seq. = &prv_ut_tst_seq. + 1)
);


*-- TEST: identical datasets --*;

*-- Create datasets --*;
data ds_01 ds_02;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output;
run;

%ut_assert_dataset(
    description     = %nrstr("ut_assert_dataset" in case of identical datasets must be PASS),
    ds_01           = ds_01,
    ds_02           = ds_02
);

*-- TEST: datasets with same strucutre but different content --*;

*-- Create datasets --*;
data ds_01 ds_02;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output ds_01;
    var_01=1; var_02="y"; output ds_02;
run;

%ut_assert_dataset(
    description     = %nrstr("ut_assert_dataset" in case of content difference must be FAIL),
    ds_01           = ds_01,
    ds_02           = ds_02,
    expected_result = FAIL
);


*-- TEST: datasets with different structure but same content --*;

*-- Create datasets --*;
data ds_01;
    attrib var_01 format=8. var_02 format=$5.;
    var_01=1; var_02="x"; output;
run;

data ds_02;
    set ds_01;
    attrib var_03 format=$5.;
    var_03="";
run;

%ut_assert_dataset(
    description     = %nrstr("ut_assert_dataset" in case of structural differences must be FAIL),
    ds_01           = ds_01,
    ds_02           = ds_02,
    expected_result = FAIL
);


*-------------------------------------------------------------------------*;
*-- Reporting                                                           --*;
*-------------------------------------------------------------------------*;

%ut_report(
    pgm_name    = &script_name.,
    report_path = &report_path.
);