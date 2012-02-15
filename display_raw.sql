-- 
--  display_raw.sql
--
--  DESCRIPTION
--    helper function to print raw representation of column stats minimum or maximum
--  
--  Created by Greg Rahn on 2011-08-19.
-- 

create or replace function display_raw (rawval raw, type varchar2)
return varchar2
is
    cn     number;
    cv     varchar2(32);
    cd     date;
    cnv    nvarchar2(32);
    cr     rowid;
    cc     char(32);
    cbf    binary_float;
    cbd    binary_double;
begin
    if (type = 'VARCHAR2') then
        dbms_stats.convert_raw_value(rawval, cv);
        return to_char(cv);
    elsif (type = 'DATE') then
        dbms_stats.convert_raw_value(rawval, cd);
        return to_char(cd);
    elsif (type = 'NUMBER') then
        dbms_stats.convert_raw_value(rawval, cn);
        return to_char(cn);
    elsif (type = 'BINARY_FLOAT') then
        dbms_stats.convert_raw_value(rawval, cbf);
        return to_char(cbf);
    elsif (type = 'BINARY_DOUBLE') then
        dbms_stats.convert_raw_value(rawval, cbd);
        return to_char(cbd);
    elsif (type = 'NVARCHAR2') then
        dbms_stats.convert_raw_value(rawval, cnv);
        return to_char(cnv);
    elsif (type = 'ROWID') then
        dbms_stats.convert_raw_value(rawval, cr);
        return to_char(cr);
    elsif (type = 'CHAR') then
        dbms_stats.convert_raw_value(rawval, cc);
        return to_char(cc);
    else
        return 'UNKNOWN DATATYPE';
    end if;
end;
/
show errors

-- ===================================
-- = Example query using display_raw =
-- ===================================
/*
col low_val for a32
col high_val for a32
col data_type for a32

select
   a.column_name,
   display_raw(a.low_value,b.data_type) as low_val,
   display_raw(a.high_value,b.data_type) as high_val,
   b.data_type
from
   user_tab_col_statistics a, 
   user_tab_cols b
where
   a.table_name='ORDERS' and
   a.table_name=b.table_name and
   a.column_name=b.column_name
/

*/

