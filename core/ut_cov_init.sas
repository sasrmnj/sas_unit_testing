%macro ut_cov_init(in_file, out_file);
/*
    Macro to initialize code coverage.
    It processes the source code of the macro to be tested, identifies execution branches and adds trackers.
    Each call to the tested macro triggers (or not) trackers so we can identify executed branches.
    Eventually, we can count how many trackers have been triggered to estimate the code coverage
    in_file:    path to the file with macro code to update for code coverage feature
    out_file:   name of a macro variable into which path to the file with code coverage implemented will be provided.
*/
    *-- Exit if framework state is erroneous --*;
    %if &ut_state. %then %do;
        %return;
    %end;

    %if %sysevalf(%superq(in_file) =, boolean) %then %do;
        %put ERROR: IN_FILE is mandatory when calling ut_cov_init;
        %let ut_state = 1;
        %return;
    %end;

    %if not %sysfunc(fileexist(%nrbquote(&in_file.))) %then %do;
        %put ERROR: IN_FILE does not target an existing file when calling ut_cov_init;
        %let ut_state = 1;
        %return;
    %end;

    %if %sysevalf(%superq(out_file) =, boolean) %then %do;
        %put ERROR: OUT_FILE is mandatory when calling ut_cov_init;
        %let ut_state = 1;
        %return;
    %end;

    *-- Update code coverage setting (1: enabled) --*;
    %let ut_cov = 1;

    *-- Extract the name of the macro from file name --*;
    %local macro_name;

    %let macro_name = %sysfunc(prxchange(s/.*\/(.+\..+)$/$1/oi, -1, %nrbquote(&in_file.)));

    *-------------------------------------------------------------*;
    *-- Read the input file                                     --*;
    *-------------------------------------------------------------*;

    filename i_file "&in_file.";

    data _ut_code;
        infile i_file length=line_len truncover;

        attrib  row_no  format=8.
                raw_txt format=$2000.
                txt     format=$2000.
                txt_len format=8.
                txt_off format=8.
        ;

        *-- Read the input file --*;
        input raw_txt $char2000.;

        *-- Define the row number in the raw input file --*;
        row_no  = _n_;

        *-- Define the offset (indentation) of the row --*;
        txt_off = notspace(raw_txt);

        *-- Remove leading/trailing spacing chars --*;
        txt = strip(raw_txt);

        *-- Define the length of the row --*;
        txt_len = length(txt);
    run;

    filename i_file clear;


    *-------------------------------------------------------------*;
    *-- Remove PL/1 style comments                              --*;
    *-------------------------------------------------------------*;

    data macro_code (drop = _:);
        set _ut_code end=eof;

        attrib  _flag   format=8.
                _idx    format=8.
        ;

        retain _flag 0;

        do while (1);
            *-- If we are not already processing a comment --*;
            if not _flag then do;
                *-- Remove comment reported on 1 line --*;
                txt = prxchange('s/\/\*.*?\*\///oi', -1, txt);

                *-- Search for comment opening tag (OT) --*;
                _idx = findvalidtext(txt, '/*');

                if _idx then do;
                    *-- Output the text before the OT, if any --*;
                    if _idx > 1 then do;
                        txt = substr(txt, 1, _idx - 1);
                        if not missing(txt) then output;
                    end;

                    *-- Flag comment processing in progress --*;
                    _flag = 1;
                end;
                else do;
                    *-- Processing standard text --*;

                    *-- Output string --*;
                    output;

                    *-- Leave loop to process next line of code --*;
                    leave;
                end;
            end;

            *-- If we are processing a comment --*;
            if _flag then do;
                *-- Search for a comment closing tag (CT) --*;
                _idx = find(txt, '*/');

                if _idx then do;
                    *-- Remove text until the CT --*;
                    txt = substr(txt, _idx + 2);

                    *-- Reset comment flag --*;
                    _flag = 0;
                end;
                else do;
                    *-- Processing commented text --*;

                    *-- Output null string --*;
                    txt = "";
                    output;

                    *-- Leave loop to process next line of code --*;
                    leave;
                end;
            end;
        end;
    run;


    *-------------------------------------------------------------*;
    *-- Split multiples statements reported on the same line    --*;
    *-------------------------------------------------------------*;

    data macro_code (drop = _:);
        set macro_code;

        attrib  _flag format=8.
                _bak format=$2000.
        ;

        *-- Search for non quoted semicolon --*;
        _idx = findvalidtext(txt, ';');

        _flag = 0;

        do while(_idx);
            _flag = 1;

            *-- Backup text after the semicolon, if any --*;
            if _idx < lengthn(txt) then _bak = substr(txt, _idx + 1);
            else                        _bak = "";

            *-- Output text until the found semicolon --*;
            txt = substr(txt, 1, _idx);
            output;

            *-- Restore backup text into txt if any --*;
            txt = _bak;

            _idx = findvalidtext(txt, ';');
        end;

        if not _flag then output;
    run;


    *-------------------------------------------------------------*;
    *-- Remove asterisk style comments                          --*;
    *-------------------------------------------------------------*;

    data macro_code (drop = _:);
        set macro_code end=eof;

        attrib  _flag   format=8.
                _idx    format=8.
        ;

        retain _flag 0;

        do while (1);
            *-- If we are not processing a comment --*;
            if not _flag then do;
                *-- Remove single line comments --*;
                txt = prxchange('s/^\s*\*.*;\s*$//oi', -1, txt);

                *-- Search for comment opening tag (OT) --*;
                _idx = prxmatch('/^\s*\*/oi', txt);

                if _idx then do;
                    *-- Flag comment processing in progress --*;
                    _flag = 1;
                end;
                else do;
                    *-- Processing standard text --*;

                    *-- Output string --*;
                    output;

                    *-- Leave loop to process next line of code --*;
                    leave;
                end;
            end;

            *-- If we are processing a comment --*;
            if _flag then do;
                *-- Search for a comment closing tag (CT) --*;
                _idx = findvalidtext(txt, ';');

                if _idx then do;
                    *-- Remove text until the CT --*;
                    txt = substr(txt, _idx + 2);

                    *-- Reset comment flag --*;
                    _flag = 0;
                end;
                else do;
                    *-- Processing commented text --*;

                    *-- Output null string --*;
                    txt = "";
                    output;

                    *-- Leave loop to process next line of code --*;
                    leave;
                end;
            end;
        end;
    run;


    *-------------------------------------------------------------*;
    *-- Identify SAS statement type                             --*;
    *-------------------------------------------------------------*;

    data macro_code;
        set macro_code;

        attrib stmt_typ format=$10.;
        retain stmt_typ;

        if prxmatch('/^\s*data\s/oi', txt) then             stmt_typ = 'data';
        else if prxmatch('/^\s*proc fcmp\s/oi', txt) then   stmt_typ = 'fcmp';
        else if prxmatch('/^\s*proc\s/oi', txt) then        stmt_typ = 'proc';

        output;

        if prxmatch('/(^|\s)(run|quit);/oi', txt) then  stmt_typ = '';
    run;


    *-------------------------------------------------------------*;
    *-- Insert do..end statements to allow cct code injection   --*;
    *-------------------------------------------------------------*;

    *-- Identify then/else statements not followed by a do..end block. --*;
    data ins (keep = txt do_: end_: type);
        set macro_code;

        attrib _flag format=8.;
        retain _flag 0;

        attrib _buf format=$2000.;
        retain _buf;

        attrib _start_row _start_idx format=8. _type format=$1.;
        retain _start_row _start_idx _type;

        attrib  do_row format=8.
                do_pos format=8.
                end_row format=8.
                end_pos format=8.
                type    format=$1.
        ;

        if not missing(txt) then do;
            if not _flag then do;
                *-- Search for "%then" keywords --*;
                _idx = findvalidtext(txt, '%then');

                if _idx then do;
                    *-- Store the text after the keyword --*;
                    _buf = substr(txt, _idx);

                    *-- Set a flag so we know we are processing something --*;
                    _flag = 1;

                    *-- Store keyword type (m: macro, s: sas) --*;
                    _type = 'm';

                    *-- Save position where '%do' must be inserted --*;
                    _start_row = row_no;
                    _start_idx = _idx + 5;
                end;
            end;

            if not _flag then do;
                *-- Search for "%else" keywords --*;
                _idx = findvalidtext(txt, '%else');

                if _idx then do;
                    *-- Store the text after the keyword --*;
                    _buf = substr(txt, _idx);

                    *-- Set a flag so we know we are processing something --*;
                    _flag = 1;

                    *-- Store keyword type (m: macro, s: sas) --*;
                    _type = 'm';

                    *-- Save position where '%do' must be inserted --*;
                    _start_row = row_no;
                    _start_idx = _idx + 5;
                end;
            end;

            if not _flag then do;
                *-- Search for "then" keywords --*;
                _idx = findvalidtext(txt, 'then');

                if _idx and stmt_typ not in ('proc', 'fcmp') then do;
                    *-- Store the text after the keyword --*;
                    _buf = substr(txt, _idx);

                    *-- Set a flag so we know we are processing something --*;
                    _flag = 1;

                    *-- Store keyword type (m: macro, s: sas) --*;
                    _type = 's';

                    *-- Save position where '%do' must be inserted --*;
                    _start_row = row_no;
                    _start_idx = _idx + 4;
                end;
            end;

            if not _flag then do;
                *-- Search for "else" keywords --*;
                _idx = findvalidtext(txt, 'else');

                if _idx and stmt_typ not in ('proc', 'fcmp') then do;
                    *-- Store the text after the keyword --*;
                    _buf = substr(txt, _idx);

                    *-- Set a flag so we know we are processing something --*;
                    _flag = 1;

                    *-- Store keyword type (m: macro, s: sas) --*;
                    _type = 's';

                    *-- Save position where '%do' must be inserted --*;
                    _start_row = row_no;
                    _start_idx = _idx + 4;
                end;
            end;

/*
                *-- Search for then/else keywords --*;
                _idx = prxmatch('/(^|\s|%)(then|else)(\s|$)/oi', txt);

                *-- Keyword found --*;
                if _idx then do;
                    *-- Store the text after the keyword --*;
                    _buf = substr(txt, _idx);

                    if char(_buf, 1) = '%' then _type = 'm';
                    else                        _type = 's';

                    *-- Do not process then/else keywords within a SAS proc --*;
                    *-- This is to avoid to handle case..when..then..else..end statements --*;
                    if not (_type = 's' and stmt_typ in ('proc', 'fcmp')) then do;
                        *-- Set a flag so we know we are processing something --*;
                        _flag = 1;

                        *-- Save position where 'do'/'%do' should be inserted --*;
                        _start_row = row_no;
                        if _type = 'm' then _start_idx = _idx + 5;
                        else                _start_idx = _idx + 4;
                    end;
                end;
            end;
*/

            if _flag then do;
                *--
                    If here, processing is in progress
                    The idea is to find the first semicolon that ends the SAS statement
                    Then to identify if a do..end block is already present
                --*;

                *-- Append current line of text to the buffer --*;
                if row_no ne _start_row then  _buf = catx(" ", _buf, txt);

                *-- Search for a semicolon --*;
                _idx = findvalidtext(txt, ';');

                if _idx then do;
                    *-- Search for a 'do'/'%do' statement --*;
                    if _type = 'm' then do;
                        if not prxmatch('/%do\s*;/', _buf) then do;
                            do_row = _start_row;
                            do_pos = _start_idx;
                            end_row = row_no;
                            end_pos = _idx;
                            type = 'm';
                            output;

                            _reset = 1;
                        end;
                        else do;
                            _reset = 1;
                        end;
                    end;
                    else if _type = 's' then do;
                        if not prxmatch('/(^|\s)do\s*;/', _buf) then do;
                            do_row = _start_row;
                            do_pos = _start_idx;
                            end_row = row_no;
                            end_pos = _idx;
                            type = 's';
                            output;

                            _reset = 1;
                        end;
                        else do;
                            _reset = 1;
                        end;
                    end;

                    if _reset then do;
                        _flag = 0;
                        _buf = '';
                        do_row = .;
                        do_pos = .;
                        end_row = .;
                        end_pos = .;
                        type = '';
                    end;
                end;
            end;
        end;
    run;

    *-- Flag in macro code where do..end must be inserted --*;
    proc sql noprint undo_policy=none;
        create table macro_code as
            select      m.*,
                        coalescec(i1.type, i2.type) as type,
                        i1.do_pos,
                        i2.end_pos

            from        macro_code m

            left join   ins i1
            on          i1.do_row = m.row_no

            left join   ins i2
            on          i2.end_row = m.row_no
        ;
    quit;

    *-- Insert do..end statements --*;
    data macro_code (drop = do_pos end_pos type);
        set macro_code;

        if not missing(end_pos) then    txt = strip(substr(txt, 1, end_pos)) || ' ' || ifc(type='m', '%end;', 'end;') || ' ' || strip(substr(txt, end_pos+1));
        if not missing(do_pos) then     txt = strip(substr(txt, 1, do_pos)) || ' ' || ifc(type='m', '%do;', 'do;') || ' ' || strip(substr(txt, do_pos+1));
    run;


    *-------------------------------------------------------------*;
    *-- Add code coverage trackers                              --*;
    *-------------------------------------------------------------*;

    *-- Identify where code coverage trackers must be inserted --*;
    data cct_ins (keep = cct_row cct_pos cct_typ);
        set macro_code;

        attrib _flag format=8.;
        retain _flag 0;

        attrib  cct_row format=8.
                cct_pos format=8.
                cct_typ format=$1.
        ;

        retain cct_typ;

        if not missing(txt) and stmt_typ ne 'fcmp' and _flag = 0 then do;
            *-- Add tracker after labels ('%xxx:') --*;
            _rgx    = prxparse('/%[a-z\d]+:/');
            _start  = 1;
            _stop   = length(txt);

            call prxnext(_rgx, _start, _stop, txt, _pos, _len);

            if _pos then do;
                cct_row = row_no;
                cct_pos = _pos + _len;
                cct_typ = 'm';
                output;
            end;

            *-- Add trackers before '%mend' statements --*;
            _pos = prxmatch('/%mend(\s|;)/', txt);
            if _pos then do;
                cct_row = row_no;
                cct_pos = _pos;
                cct_typ = 'm';
                output;
            end;

            *-- Add trackers after '%macro' statements --*;
            _pos = prxmatch('/%macro\s/', txt);

            if _pos then do;
                *-- Set a flag so we know we are processing something --*;
                *-- The cct must be injected after the first semicolon following the keyword --*;
                _flag = 1;
                cct_typ = 'm';
            end;

            *-- Add trackers after 'do'/'%do' statements --*;
            _pos = prxmatch('/%?do(\s|;|$)/', txt);
            if _pos then do;
                *-- Set a flag so we know we are processing something --*;
                *-- The cct must be injected after the first semicolon following the keyword --*;
                _flag = 1;
                if char(txt, _pos) = '%' then   cct_typ = 'm';
                else                            cct_typ = 's';
            end;
        end;

        if _flag then do;
            *-- If here, a keyword has been found and we must search for a semicolon --*;

            *-- Search for the 1st semicolon following the keyword --*;
            _idx = findvalidtext(txt, ';');

            if _idx then do;
                *-- Semicolon found --*;
                cct_row = row_no;
                cct_pos = _idx + 1;
                output;

                *-- Processing completed, reset status --*;
                _flag = 0;
                cct_row = .;
                cct_pos = .;
                cct_typ = '';
            end;
        end;
    run;

    *-- Flag rows and positions where cct must be injected --*;
    proc sql noprint undo_policy=none;
        create table macro_code as
            select      m.*,
                        i.cct_pos,
                        i.cct_typ

            from        macro_code m

            left join   cct_ins i
            on          i.cct_row = m.row_no
        ;
    quit;

    *-- Add code coverage trackers --*;
    data macro_code;
        set macro_code end=eof;

        attrib  cct_id      format=8.
                cct_stmt    format=$50.
        ;
        retain cct_id 0;

        if not missing(cct_pos) then do;
            cct_id + 1;

            if cct_typ = 'm' then   cct_stmt = '%put #cct#' || strip(put(cct_id, best.)) || '#;';
            else                    cct_stmt = 'putlog "#cct#' || strip(put(cct_id, best.)) || '#";';

            if cct_pos < 2 then     txt = strip(cct_stmt) || " " || strip(txt);
            else                    txt = strip(substr(txt, 1, cct_pos)) || " " || strip(cct_stmt) || " " || strip(substr(txt, cct_pos +  1));
        end;
    run;


    *-------------------------------------------------------------*;
    *-- Output modified file with code coverage trackers        --*;
    *-------------------------------------------------------------*;

    filename o_file "&ut_work_dir./&macro_name." lrecl=32000;

    data _null_;
        set macro_code;

        file o_file;

        txt = coalescec(txt, raw_txt);

        if (lengthn(txt) > 0) then
            put @txt_off txt;
        else
            put ;
    run;

    filename o_file;


    *-------------------------------------------------------------*;
    *-- Build a dataset to track the state of cct               --*;
    *-------------------------------------------------------------*;

    proc sort data=macro_code; by cct_id row_no; run;

    data _ut_cct_state;
        set macro_code (keep = cct_id row_no);
        by cct_id row_no;

        attrib status format=8.;
        status = .;

        if first.cct_id then output;
    run;


    *-------------------------------------------------------------*;
    *-- Return the path to the modified macro with cct embedded --*;
    *-------------------------------------------------------------*;
    %let &out_file. = &ut_work_dir./&macro_name.;


    *-------------------------------------------------------------*;
    *-- Clean the work library                                  --*;
    *-------------------------------------------------------------*;

    proc datasets library=work nolist;
        delete ins cct_ins;
    run; quit;
%mend ut_cov_init;