%macro ut_run(stmt=, debug=);
/*
    Macro to run some SAS code in a controled environement where ERROR and WARNINGS are not output in the SAS log.
    Allow to perform some tests whose result is an ERROR or a WARNING.
    stmt:   the SAS code to execute.
    debug:  any non null value enables the debug mode and so disable the SAS log redirection
*/
    %if %sysevalf(%superq(debug) =, boolean) %then %do;
        *-- This option allows to have SAS log lines up to 256 chars (the max) --*;
        option linesize=max;

        *-- Redirect the SAS log --*;
        proc printto log="&ut_work_dir./&ut_log_file." new;
        run;
    %end;

    *-- Reset warning status --*;
    %put WARNING: %str( );

    *-- Reset error status --*;
    %put ERROR: %str( );

    %let syscc = 0;

    *-- Execute the provided SAS statement --*;
    %unquote(&stmt.);

    %if %sysevalf(%superq(debug) =, boolean) %then %do;
        *-- Disable SAS log redirection --*;
        proc printto;
        run;
    %end;
%mend ut_run;
