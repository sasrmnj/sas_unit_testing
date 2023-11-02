/*
    User package to store custom SAS functions
*/

*-- Option to avoid warnings in case of re-run of proc fcmp --*;
options cmplib = _null_;

*-- Build a user package to store custom SAS functions --*;
proc fcmp outlib=work.custom.fct;
    *-- Function to check if a character at position (pos) within a string (str) is quoted --*;
    function isquoted(str $, pos);
        _rgx    = prxparse('/(["''])(.+?)(\1)/');
        _start  = 1;
        _stop   = length(str);

        *-- Search for quoted text --*;
        call prxnext(_rgx, _start, _stop, str, _pos, _len);

        *-- Quoted text found --*;
        do while (_pos > 0);
            if _pos < pos < (_pos + _len) then do;
                return(1);
            end;

            call prxnext(_rgx, _start, _stop, str, _pos, _len);
        end;

        return(0);
    endsub;

    *-- Function to check if a character at position (pos) within a string (str) is enclosed between parentheses --*;
    function isenclosed(str $, pos);
        _rgx    = prxparse('/\(.+\)/');
        _start  = 1;
        _stop   = length(str);

        *-- Search for (nr)stred text --*;
        call prxnext(_rgx, _start, _stop, str, _pos, _len);

        *-- (nr)stred text found --*;
        do while (_pos > 0);
            if _pos < pos < (_pos + _len) then do;
                return(1);
            end;

            call prxnext(_rgx, _start, _stop, str, _pos, _len);
        end;

        return(0);
    endsub;

    *-- Function to find a value (val) within a string (str) that is neither quoted nor enclosed between parentheses --*;
    function findvalidtext(str $, val $);
            _idx = find(str, val);

            do while (_idx);
                if isquoted(str, _idx) then         _idx = find(str, val, _idx+1);
                else if isenclosed(str, _idx) then  _idx = find(str, val, _idx+1);
                else leave;
            end;

            return(_idx);
    endsub;
run;

options cmplib=work.custom;