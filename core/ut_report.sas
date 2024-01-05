%macro ut_report(test_suite=, report_path=);
/*
    Macro to generate a PDF report of the tests performed.
    test_suite:     name of the test suite (identify with program or macro is valdiated)
    report_path:    full path to the PDF file to be created
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

    %local yyyymmdd not_pass_cnt code_coverage code_coverage_pct ut_grp_id_lst ut_grp_desc;

    *-- Get the current date in yyyymmdd format --*;
    %let yyyymmdd = %sysfunc(date(), yymmddn8.);

    *-- Build a PDF report --*;
    ods listing close;
    ods noresults;
    options nodate nonumber;
    options orientation=landscape;
    ods escapechar '^';

    ods pdf file="&report_path./unit_testing_&test_suite._&yyyymmdd..pdf";

    title;
    footnote;

    title1 justify=center height=12pt "&test_suite. - Test suite report";
    footnote1 justify=right height=10pt "^{thispage} | ^{lastpage}";

    proc sql noprint;
        create table rpt as
            select      "x" as dummy,
                        ut_grp_id,
                        catx(' - ', ut_grp_id, ut_grp_desc) as ut_grp_desc,
                        ut_tst_seq,
                        ut_tst_id,
                        ut_tst_type,
                        ut_tst_desc,
                        ut_tst_exp_res,
                        ut_tst_res,
                        ut_tst_stat,
                        ut_tst_det
            from        _ut_results
            order by    ut_grp_id, ut_tst_seq
        ;
    quit;

    *-------------------------------------------------*;
    *-- Overall status                              --*;
    *-------------------------------------------------*;

    proc sql noprint;
        select      count(*)
        into        :not_pass_cnt trimmed
        from        rpt
        where       strip(lowcase(ut_tst_stat)) ne "pass"
        ;
    quit;

    *-- If code coverage is enabled --*;
    %if &ut_cov. %then %do;
        proc sql noprint;
            select      round(coalesce(sum(status), 0)/count(*), 0.01)
            into        :code_coverage_pct trimmed
            from        _ut_cct_state
            ;
        quit;
    %end;

    data overall;
        attrib dummy format=$1.;    dummy = "x";
        attrib desc format=$50.;
        attrib value format=$100.;

        desc = "Test suite name";
        value = strip("&test_suite.");
        output;

        desc = "Validation report run by";
        value = strip("&sysuserid.");
        output;

        desc = "Validation report run";
        value = strip(put(datetime(), datetime22.));
        output;

        *-- If code coverage is enabled --*;
        %if &ut_cov. %then %do;
            desc = "Code coverage";
            value = strip(put(&code_coverage_pct., percent6.2));
            output;
        %end;

        desc = "Overall validation status";
        if &not_pass_cnt. = 0 then  value = 'PASS';
        else                        value = 'FAIL';
        output;
    run;

    ods proclabel 'Overall status';
    title2 "Overall status";

    proc report data=overall contents="" nowindows missing
        style (header)={font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l}
        style (report)={background=white}
        ;

        column dummy desc value;

        define dummy    / order noprint;
        define desc     / display "";
        define value    / display "";

        *-- This hack removes TOC entries --*;
        break before dummy / page contents='';

        compute value;
            if strip(lowcase(desc)) = "overall validation status" then do;
                if strip(lowcase(value)) = "pass" then  call define(_col_, "style", "style={background=cxa7e8b8}");
                else                                    call define(_col_, "style", "style={background=cxfab4b4}");
            end;
        endcomp;
    run;

    *-------------------------------------------------*;
    *-- Validation overview report                  --*;
    *-------------------------------------------------*;

    ods proclabel 'Validation overview';
    title2 "Validation overview";

    proc report data=rpt contents="" nowindows missing
        style (header)={font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l}
        style (report)={background=white}
        ;

        column dummy ut_grp_id ut_grp_desc ut_tst_id ut_tst_desc ut_tst_stat;

        define dummy        / order noprint;
        define ut_grp_id    / order noprint;
        define ut_grp_desc  / group noprint;
        define ut_tst_id    / display "Test ID" style={width=100};
        define ut_tst_desc  / display "Test description";
        define ut_tst_stat  / display "Status" style={width=80};

        *-- This hack removes TOC entries --*;
        break before dummy / page contents='';

        *-- Display the group description as a header row --*;
        compute before ut_grp_desc / style={font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l};
            line ut_grp_desc $500.;
        endcomp;

        compute ut_tst_stat;
            if strip(lowcase(ut_tst_stat)) = "pass" then    call define(_col_, "style", "style={background=cxa7e8b8}");
            else                                            call define(_col_, "style", "style={background=cxfab4b4}");
        endcomp;
    run;


    *-------------------------------------------------*;
    *-- Failed tests report                         --*;
    *-------------------------------------------------*;

    ods proclabel 'Failed tests';

    data err_rpt (keep = dummy ut_grp_id ut_tst_seq ut_grp_desc ut_tst_id ut_tst_type row_nfo row_data);
        set rpt (where = (strip(lowcase(ut_tst_stat)) ne "pass"));

        attrib row_nfo format=$50.;
        attrib row_data format=$500.;

        row_nfo="Test description"; row_data=strip(ut_tst_desc);    output;
        row_nfo="Test type";        row_data=strip(ut_tst_type);    output;
        row_nfo="Test details";     row_data=strip(ut_tst_det);     output;
        row_nfo="Expected result";  row_data=strip(ut_tst_exp_res); output;
        row_nfo="Result";           row_data=strip(ut_tst_res);     output;
    run;

    proc report data=err_rpt contents="" nowindows missing headline headskip spacing=1 spanrows
        style (header)=[font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l]
        style (report)={background=white}
        ;

        column dummy ut_grp_id ut_tst_seq ut_grp_desc ut_tst_id row_nfo row_data;

        define dummy        / order noprint;
        define ut_grp_id    / order noprint;
        define ut_tst_seq   / order noprint;
        define ut_grp_desc  / group noprint;
        define ut_tst_id    / order "Test ID"  style={verticalalign=middle width=100};
        define row_nfo      / display "";
        define row_data     / display "";

        *-- This hack removes TOC entries --*;
        break before dummy / page contents='';

        *-- Display the group description as a header row --*;
        compute before ut_grp_desc / style={font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l};
            line ut_grp_desc $500.;
        endcomp;
    run;


    *-------------------------------------------------*;
    *-- Detailed validation reports                 --*;
    *-------------------------------------------------*;

    data full_rpt (keep = dummy ut_grp_id ut_grp_desc ut_tst_seq ut_tst_id ut_tst_type ut_tst_exp_res ut_tst_res ut_tst_stat row_nfo row_data);
        set rpt;

        attrib row_nfo format=$50.;
        attrib row_data format=$500.;

        row_nfo="Test description"; row_data=strip(ut_tst_desc);    output;
        row_nfo="Test type";        row_data=strip(ut_tst_type);    output;
        row_nfo="Test details";     row_data=strip(ut_tst_det);     output;
        row_nfo="Expected result";  row_data=strip(ut_tst_exp_res); output;
        row_nfo="Result";           row_data=strip(ut_tst_res);     output;
    run;

    proc sql noprint;
        select      distinct ut_grp_id
        into        :ut_grp_id_lst separated by '|'
        from        full_rpt
        order by    ut_grp_id
        ;
    quit;

    %do _i_ = 1 %to %sysfunc(countw(&ut_grp_id_lst., '|'));
        %let cur_ut_grp_id = %scan(&ut_grp_id_lst., &_i_., '|');

        proc sql noprint;
            select      distinct ut_grp_desc
            into        :ut_grp_desc trimmed
            from        full_rpt
            where       ut_grp_id = &cur_ut_grp_id.
            ;
        quit;

        ods proclabel "Detailed report. %nrbquote(&ut_grp_desc.)";
        title2 "%nrbquote(&ut_grp_desc.)";


        proc report data=full_rpt (where=(ut_grp_id=&cur_ut_grp_id.)) contents="" nowindows missing headline headskip spacing=1 spanrows
            style (header)=[font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l]
            style (report)={background=white}
            ;

            column dummy ut_grp_id ut_tst_seq ut_tst_id row_nfo row_data ut_tst_stat;

            define dummy        / order noprint;
            define ut_grp_id    / order noprint;
            define ut_tst_seq   / order noprint;
            define ut_tst_id    / order "Test ID"  style={verticalalign=middle width=100};
            define row_nfo      / display "";
            define row_data     / display "";
            define ut_tst_stat  / order "Status"  style={verticalalign=middle width=80};

            *-- This hack removes TOC entries --*;
            break before dummy / page contents='';

            compute ut_tst_stat;
                if strip(lowcase(ut_tst_stat)) = "pass" then    call define(_col_, "style", "style={background=cxa7e8b8}");
                else                                            call define(_col_, "style", "style={background=cxfab4b4}");
            endcomp;
        run;
    %end;

    *-------------------------------------------------*;
    *-- Code coverage report                        --*;
    *-------------------------------------------------*;

    *-- If code coverage is enabled --*;
    %if &ut_cov. %then %do;
        ods proclabel 'Code coverage report';
        title2 "Code coverage report";

        *-- Retrieve 2 lines before/after the tested line of code --*;
        proc sql noprint;
            create table cct_rpt as
                select      'x' as dummy,
                            c.row_no,
                            c.raw_txt,
                            s.row_no as cct_row,
                            s.cct_id,
                            s.status

                from        _ut_code c

                left join   _ut_cct_state s
                on          c.row_no between s.row_no - 2 and s.row_no + 2

                where       not missing(cct_id)

                order by    s.cct_id, c.row_no
            ;
        quit;

        data cct_rpt;
            set cct_rpt;
            by cct_id row_no;

            attrib txt format=$5000.;
            retain txt;

            attrib tmp format=$1000.;

            if first.cct_id then do;
                txt = "";

                if row_no > 1 then txt = repeat(' ', 8) || '...';
            end;

            attrib row_no_str format=$10.;
            row_no_str = strip(put(row_no, 8.)) || '.';

            *-- Highlight tested code --*;
            if row_no = cct_row then do;
                if status then tmp = "^{style[foreground=cx00b050]";
                else           tmp = "^{style[foreground=cxc0504d]";

                tmp = strip(tmp) || strip(raw_txt) || "}";
            end;
            else do;
                tmp = strip(raw_txt);
            end;

            txt = strip(txt) || '^n' || strip(row_no_str) ||  repeat(' ', 8 - lengthn(row_no_str)) || strip(tmp);

            if last.cct_id then do;
                txt = strip(txt) || '^n' || repeat(' ', 8) || '...';
                output;
            end;
        run;

        proc report data=cct_rpt contents="" nowindows missing headline headskip spacing=1 spanrows
            style (header)=[font_size=9pt font_weight=bold background=cxffffff foreground=black vjust=center just=l]
            style (report)={background=white}
            ;

            column dummy txt;

            define dummy        / order noprint;
            define txt          / display "SAS statement" style(column)={font_face=courier};

            *-- This hack removes TOC entries --*;
            break before dummy / page contents='';
        run;
    %end;

    ods pdf close;

    proc datasets library=work nolist;
        delete  rpt overall err_rpt full_rpt
                %if &ut_cov. %then %do;
                    cct_rpt
                %end;
        ;
    run; quit;
%mend ut_report;
