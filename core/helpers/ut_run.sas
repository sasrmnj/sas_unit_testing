%macro ut_run(stmt=, debug=);
/*
    Macro to run some SAS code in a controled environement where ERROR and WARNING are not output in the SAS log.
    This allows to perform some tests whose result is an ERROR or a WARNING.
    stmt:   the SAS code to execute.
    debug:  any non null value enables the debug mode and so disable the SAS log redirection
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

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

        *-- If code coverage is enabled --*;
        %if &ut_cov. %then %do;
            filename i_file "&ut_work_dir./&ut_log_file.";

            *-- Read the input file and find code coverage trackers --*;
            data cct;
                infile i_file;

                *-- Read the input file --*;
                input;

                *-- Identify code coverage trackers --*;
                if prxmatch('/#cct#\d+#/oi', _infile_) then do;
                    attrib cct_id status format=8.;
                    cct_id = input(prxchange('s/#cct#(\d)+#/$1/oi', -1, _infile_), best.);
                    status = 1;
                    output;
                end;
            run;

            filename i_file clear;

            proc sort data=cct nodupkey; by cct_id; run;

            *-- Save code coverage trackers found during that run --*;
            proc sql noprint undo_policy=none;
                create table _ut_cct_state as
                    select      c.cct_id,
                                c.row_no,
                                c.raw_txt,
                                coalesce(c.status, t.status) as status

                    from        _ut_cct_state c

                    left join   cct t
                    on          t.cct_id = c.cct_id

                    order by    c.cct_id
                ;
            quit;

            proc datasets library=work nolist;
                delete cct;
            run; quit;
        %end;
    %end;
%mend ut_run;
