-- 
--  dba_col_usage.sql
--
--  DESCRIPTION
--    View/query to show predicate information used by dbms_stats for histogram candidates.
--    Requires sys as sysdba privs.
--    Monitoring info can be flushed immediately using dbms_stats.flush_database_monitoring_info;
--
--  Created by Greg Rahn on 2011-08-19.
-- 

connect / as sysdba
create or replace view dba_col_usage
as
select  
   u.name owner,
   o.name table_name,
   c.name column_name,
   cu.equality_preds,
   cu.equijoin_preds,
   cu.nonequijoin_preds,
   cu.range_preds,
   cu.like_preds,
   cu.null_preds,
   cu.timestamp
from
   sys.obj$ o,
   sys.col$ c,
   sys.user$ u,
   sys.col_usage$ cu
where   o.obj#  = cu.obj#
and     u.user# = o.owner#
and     c.obj#  = cu.obj#
and     c.col#  = cu.intcol#;

create public synonym dba_col_usage for dba_col_usage;
