-- 
--  gen_et.sql
--
--  DESCRIPTION
--    generate external table ddl from dictionary information
--    external table name is ET_<table_name> so table names longer than 29 chars or more need manual naming
--    assumes flat file column order matches DDL of table and flat file name is based on table name
--  NOTES
--    adjust date/timestamp masks, source files, parallel degree, etc. as necessary
--    by default runs on all tables in a schema not matching 'ET_%'
--
--  Created by Greg Rahn on 2011-08-19.
--  Copyright (c) 2011 Greg Rahn. All rights reserved.
-- 

set serveroutput on echo off feedback off timing off termout off

spool &&1._et.sql

declare
   v_user varchar2(32);
   num_cols number := 0;
begin
   -- get the username to use for directory naming
   select user into v_user from dual;
   
   -- print the directory DDL
   dbms_output.put_line('create or replace directory '||v_user||'_DATA as ''<changme>'';');
   dbms_output.put_line('create or replace directory '||v_user||'_LOG  as ''<changme>'';');
   -- for PREPROCESSOR, if necessary
   dbms_output.put_line('create or replace directory EXEC_DIR as ''<changme>'';');

   -- generate the ddl for every table in the schema whose table name does not start with ET_
   for tab_name_rec in (select table_name from user_tables where table_name not like 'ET_%' order by table_name)
   -- single table hack below, comment out above line, uncomment below line
   -- for tab_name_rec in (select 'CUSTOMER' table_name from dual)
   loop
      dbms_output.put_line('--');
      dbms_output.put_line('-- ET_'||tab_name_rec.table_name);
      dbms_output.put_line('--');

      dbms_output.put_line('DROP TABLE ET_'||tab_name_rec.table_name||';');
      dbms_output.put_line('CREATE TABLE ET_'||tab_name_rec.table_name);
      dbms_output.put_line('(');
      num_cols :=0 ;
      for col_name_rec in (select column_name,
                                  data_type,
                                  case when data_type in('VARCHAR2','CHAR') then '('||data_length||')'
                                  end data_len
                           from user_tab_columns
                           where table_name = tab_name_rec.table_name
                           order by column_id)
      loop
         -- dbms_output.put_line('col_name_rec.column_name');
         if num_cols = 0 then
            dbms_output.put_line(chr(9)||' '||rpad('"'||col_name_rec.column_name||'"',33,' ')||col_name_rec.data_type||col_name_rec.data_len);
         else
            dbms_output.put_line(chr(9)||','||rpad('"'||col_name_rec.column_name||'"',33,' ')||col_name_rec.data_type||col_name_rec.data_len);
         end if;
         num_cols := num_cols + 1;
      end loop; /* for each column */
      dbms_output.put_line(')');
      dbms_output.put_line('ORGANIZATION EXTERNAL');
      dbms_output.put_line('(');
      dbms_output.put_line(chr(9)||'TYPE oracle_loader');
      dbms_output.put_line(chr(9)||'DEFAULT DIRECTORY '||v_user||'_DATA');
      dbms_output.put_line(chr(9)||'ACCESS PARAMETERS');
      dbms_output.put_line(chr(9)||'(');
      dbms_output.put_line(chr(9)||chr(9)||'RECORDS DELIMITED BY NEWLINE');
      -- dbms_output.put_line(chr(9)||chr(9)||'PREPROCESSOR EXEC_DIR:''gunzip.sh''');
      -- dbms_output.put_line(chr(9)||chr(9)||'SKIP 1');
      dbms_output.put_line(chr(9)||chr(9)||'BADFILE '||v_user||'_LOG: '''||tab_name_rec.table_name||'.bad''');
      dbms_output.put_line(chr(9)||chr(9)||'LOGFILE '||v_user||'_LOG: '''||tab_name_rec.table_name||'.log''');
      dbms_output.put_line(chr(9)||chr(9)||'FIELDS LRTRIM TERMINATED BY ''|''');
      dbms_output.put_line(chr(9)||chr(9)||'MISSING FIELD VALUES ARE NULL');
      dbms_output.put_line(chr(9)||chr(9)||'(');

      num_cols :=0 ;
      for col_name_rec in (select   column_name,
                                    case 
                                       -- strings longer than 255 need a declaration
                                       when data_type in ('VARCHAR2','CHAR') and data_length > 255 then 'CHAR('||data_length||')'
                                       -- set your date masks appropriately
                                       when data_type = 'DATE' then 'DATE mask "YYYY-MM-DD"'
                                       -- when data_type = 'DATE' then 'DATE mask "MM/DD/YYYY hh24:mi:ss"'
                                       -- when data_type = 'DATE' then 'DATE mask "YYYY/MM/DD"'
                                       when data_type = 'TIMESTAMP(6)' then 'CHAR(26) DATE_FORMAT TIMESTAMP MASK "YYYY-MM-DD HH24:MI:SSXFF"'
                                       when data_type = 'TIMESTAMP(3)' then 'CHAR(26) DATE_FORMAT TIMESTAMP MASK "YYYY-MM-DD HH24:MI:SSXFF"'
                                       when data_type = 'TIMESTAMP(0)' then 'CHAR(26) DATE_FORMAT TIMESTAMP MASK "YYYY-MM-DD HH24:MI:SS"'
                                       else null
                                    end x
                           from user_tab_columns
                           where table_name = tab_name_rec.table_name
                           order by column_id)
      loop
         if num_cols = 0 then
            dbms_output.put_line(chr(9)||chr(9)||chr(9)||' "'||col_name_rec.column_name||'"'||'  '||col_name_rec.x);
         else
            dbms_output.put_line(chr(9)||chr(9)||chr(9)||',"'||col_name_rec.column_name||'"'||'  '||col_name_rec.x);
         end if;
         num_cols := num_cols + 1;
      end loop; /* for each column 2 */

      dbms_output.put_line(chr(9)||chr(9)||')');
      dbms_output.put_line(chr(9)||')');
      dbms_output.put_line(chr(9)||'LOCATION (');
      dbms_output.put_line(chr(9)||''''||(tab_name_rec.table_name)||'.dat''');
      -- dbms_output.put_line(chr(9)||'''prefix_'||lower(tab_name_rec.table_name)||'.gz''');
      dbms_output.put_line(chr(9)||')');
      dbms_output.put_line(')');
      dbms_output.put_line('REJECT LIMIT 1000');
      -- dbms_output.put_line('PARALLEL');
      dbms_output.put_line(';');

   end loop; /* for each table */
end;
/

spool off
set feedback on termout on
