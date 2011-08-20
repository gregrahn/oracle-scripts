-- 
--  dump_optimizer_trace.sql
--
--  DESCRIPTION
--    dump Optimizer trace for a given sql_id & print out the trace file name
--
--  Created by Greg Rahn on 2011-08-19.
--  Copyright (c) 2011 Greg Rahn. All rights reserved.
-- 

set verify off linesize 132

begin
    dbms_sqldiag.dump_trace(
        p_sql_id=>'&&sql_id',
        p_child_number=>&&child_number,
        p_component=>'Compiler',
        p_file_id=>'&&trace_file_identifier');
end;
/

select value ||'/'||(select instance_name from v$instance) ||'_ora_'||
(select spid||case when traceid is not null then '_'||traceid else null end
from v$process 
where addr = (select paddr from v$session where sid = (select sid from v$mystat where rownum = 1))
) || '.trc' tracefile
from v$parameter where name = 'user_dump_dest'
/

undef sql_id
undef child_number
undef trace_file_identifier