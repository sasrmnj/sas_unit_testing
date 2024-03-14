%macro ut_assert_error(description=, error_msg=, expected_result=PASS);
/*
    To be used to assert an error is expected
    Note: this function searches for the current error message
    If you search for a specific error that could have occured earlier, you might have to use ut_assert_log
    description:        description to explain why an error is expected
    error_msg:          error message expected either in the SAS log or in the system
    expected_result:    either PASS or FAIL
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

    %ut_tst_init(type=ut_assert_error, description=&description., expected_result=&expected_result.);

	*-- Define a macro variable to store the result of ut_search_log --*;
	%local ut_search_log;
	%let ut_search_log=;

	%if %sysevalf(%superq(error_msg) ne, boolean) %then %do;
	    *-- Remove the leading "ERROR:" tag from the error message if any --*;
        %let error_msg = %sysfunc(prxchange(s/^ERROR:\s*(.*)$/$1/oi, -1, %nrbquote(&error_msg.)));

		*-- Search for the error message in the SAS log --*;
		%ut_search_log(log_type=error, log_msg=%nrbquote(&error_msg.), res_var=ut_search_log);

		%if &ut_search_log. = TRUE %then %do;
			%let ut_tst_res = PASS;
			%let ut_tst_det = Expected error:^n%nrbquote(&error_msg.)^n^nfound in the SAS log;
		%end;
		%else %do;
			%let ut_tst_res = FAIL;
			%let ut_tst_det = Expected error:^n%nrbquote(&error_msg.)^n^nnot found in the SAS log;
		%end;
	%end;
	%else %do;
		*-- Search for error in the SAS log --*;
        %ut_search_log(log_type=error, log_msg=, res_var=ut_search_log);
        
		%if &ut_search_log. = TRUE %then %do;
            %let ut_tst_res = PASS;
            %let ut_tst_det = Error found in the SAS log;
        %end;
        %else %do;
            %let ut_tst_res = FAIL;
            %let ut_tst_det = No error found in the SAS log;
        %end;
    %end;

    %ut_log_result;
%mend ut_assert_error;
