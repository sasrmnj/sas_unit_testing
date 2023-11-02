%macro ut_search_log(log_file=&ut_work_dir./&ut_log_file., log_type=, log_msg=, res_var=);
/*
    Macro to search for specific content in a SAS log file.
    This function is used by assert functions and shoudn't be used out of this scope
    log_file:   the path to the log file to check
    log_type:   the type of log message to search for (ERROR, WARNING, NOTE or anything else)
    log_msg:    the text tp search for
    res_var:    the variable name to return the result (if "log_msg" has been found, then TRUE else FALSE)
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_err. %then %do;
        %return;
    %end;

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

    %if %sysevalf(%superq(log_type) =, boolean) and %sysevalf(%superq(log_msg) =, boolean) %then %do;
        %put ERROR: either LOG_TYPE or LOG_MSG (or both) are expected when calling ut_search_log;
        %return;
    %end;

    *-- By default, set res_var to FALSE --*;
    %let &res_var. = FALSE;

        *-- Determine the length of the buffer to search for text --*;
    *-- NOTE: we read at least 256 chars from log, so the buffer length is 512 char at the minimum --*;
    %if %sysevalf(%superq(log_msg) ne, boolean) %then   %let buf_size = %eval(%length(&log_msg.) * 2);
    %else                                               %let buf_size = 512;

    %let buf_size = %sysfunc(max(&buf_size., 512));


    *-- Open the log file --*;
    filename log_in "&log_file.";

    data _null_;
        infile log_in lrecl=256 length=line_len truncover;

        attrib  log_no  format=8.
                log_len format=8.
                log_txt format=$256.
                buf     format=$&buf_size..
                buf_len format=8.
                flag    format=8.
        ;

        retain  flag buf_len buf;

        if _n_ = 1 then do;
            flag    = 0;
            buf     = "";
            buf_len = 0;
        end;

        *-- Read log --*;
        input;

        log_no  = _n_;
        log_len = line_len;
        log_txt = _infile_;

        %if %sysevalf(%superq(log_msg) =, boolean) %then %do;
            *-- If log_msg is null, we just have to search for the log_type value at the beginning of a line --*;

            if prxmatch("/^&log_type..*/oi", strip(log_txt)) then do;
                call symputx("&res_var.", "TRUE");
                stop;
            end;
        %end;
        %else %do;
            *-- If log_msg is not null, it is a little bit more complex :) --*;

            *-- Condition to start filling the buffer used to search text --*;
            if      flag = 0
                and prxmatch("/^[a-z]/oi", strip(log_txt))
                and prxmatch("/^&log_type..*/oi", strip(log_txt))
            then do;
                flag        = 1;
                buf         = "";
                buf_len     = 0;
                log_line    = _n_;
            end;

            *-- Process current log line --*;
            if flag and not missing(log_txt) then do;
                *-- Ensure there is enough space in the buffer to add current log line --*;
                if buf_len + log_len > &buf_size. then do;
                    buf = substr(buf, (log_len-(&buf_size. - buf_len)) + 1);
                    buf_len = buf_len - (log_len-(&buf_size. - buf_len));
                end;

                *-- Append the current log line to the buffer --*;
                if buf_len = 0 then buf = substr(log_txt, 1, log_len);
                else                buf = substr(buf, 1, buf_len) || substr(log_txt, 1, log_len);

                *-- Update length value of buffer content --*;
                buf_len = buf_len + log_len;

                *-- Log entry found --*;
                if find(buf, strip("&log_msg."), 'it') then do;
                    call symputx("&res_var.", "TRUE");
                    stop;
                end;
            end;

            output;

            *-- Condition to stop filling the buffer used to search text --*;
            if      flag
                and (
                            missing(log_txt)
                        or  prxmatch("/^\d/oi", strip(log_txt))
                    )
            then do;
                flag        = 0;
                buf         = "";
                buf_len     = 0;
                log_no      = _n_;
            end;
        %end;
    run;

    filename log_in;
%mend ut_search_log;
