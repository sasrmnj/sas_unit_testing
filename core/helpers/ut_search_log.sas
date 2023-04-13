%macro ut_search_log(log_file=&ut_work_dir./&ut_log_file., log_type=, log_msg=, res_var=);
/*
    Macro to search for specific content in a SAS log file.
    This function is used by assert functions and shoudn't be used out of this scope
    log_file:   the path to the log file to check
    log_type:   the type of log message to search for (ERROR, WARNING, NOTE or anything else)
    log_msg:    the text tp search for
    res_var:    the variable name to return the result (if "log_msg" has been found, then TRUE else FALSE)
*/
    %if %sysevalf(%superq(log_file) =, boolean) %then %do;
        %put ERROR: LOG_FILE is mandatory when calling ut_search_log;
        %return;
    %end;

    %if not %sysfunc(fileexist("&log_file.")) %then %do;
        %put ERROR: LOG_FILE does not exist;
        %return;
    %end;

    %if %sysevalf(%superq(res_var) =, boolean) %then %do;
        %put ERROR: RES_VAR is mandatory when calling ut_search_log;
        %return;
    %end;

    *-- By default, set res_var to FALSE --*;
    %let &res_var. = FALSE;

    *-- Open the log file --*;
    filename log_in "&log_file.";

    data log;
        infile log_in lrecl=256 pad;

        attrib  log_line    format=8.
                log_text    format=$256.
        ;

        *-- Read in log --*;
        input log_text $ 1-256;

        log_line = _n_;

        *-- Log entry found --*;
        if prxmatch("/^&log_type..*&log_msg..*/oi", strip(log_text)) then do;
            call symputx("&res_var.", "TRUE");
            output;
            stop;
        end;
    run;

    filename log_in;
%mend ut_search_log;