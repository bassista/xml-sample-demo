
/* ================================================  
 * Oracle XFiles Demonstration.  
 *    
 * Copyright (c) 2014 Oracle and/or its affiliates.  All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * ================================================ */

set echo on 
spool XDBPM_SET_DB_VERSION.log
set timing on
--
DEF SCRIPT_LOCATION = &1
--
var XDBPM_LOG_FILE        VARCHAR2(120)
--
declare
  V_XDBPM_LOG_FILE         VARCHAR2(120);
begin
  $IF DBMS_DB_VERSION.VER_LE_10_2 $THEN
    V_XDBPM_LOG_FILE       := 'XDBPM_INSTALLATION_10200.log';
  $ELSIF DBMS_DB_VERSION.VER_LE_11_1 $THEN
    V_XDBPM_LOG_FILE       := 'XDBPM_INSTALLATION_11106.log';
  $ELSIF DBMS_DB_VERSION.VER_LE_11_2 $THEN
    V_XDBPM_LOG_FILE       := 'XDBPM_INSTALLATION_11201.log';
  $ELSIF DBMS_DB_VERSION.VER_LE_12_1 $THEN
    V_XDBPM_LOG_FILE       := 'XDBPM_INSTALLATION_12100.log';
  $ELSE
    V_XDBPM_LOG_FILE := 'XDBPM_INSTALLATION_UNKNOWN.log';
  $END
  :XDBPM_LOG_FILE       := V_XDBPM_LOG_FILE;
end;
/
undef XDBPM_LOG_FILE 
--
column XDBPM_LOG_FILE  new_value XDBPM_LOG_FILE 
--
select :XDBPM_LOG_FILE XDBPM_LOG_FILE
  from dual
/
def XDBPM_LOG_FILE
--
spool off
spool &XDBPM_LOG_FILE
--
DEF SCRIPT_LOCATION
--
var DBMSXUTIL_SCRIPT      VARCHAR2(120)
var PRVTXUTIL_SCRIPT      VARCHAR2(120)
--
declare
  V_DBMSXUTIL_SCRIPT       VARCHAR2(120);
  V_PRVTXUTIL_SCRIPT       VARCHAR2(120);
begin
	begin
    select '/XDBPM_DO_NOTHING.sql','/XDBPM_DO_NOTHING.sql'
      into V_DBMSXUTIL_SCRIPT, V_PRVTXUTIL_SCRIPT
      from ALL_OBJECTS
     where OBJECT_NAME = 'DBMS_XMLSCHEMA_ANNOTATE' 
       and OBJECT_TYPE = 'PACKAGE' 
      and OWNER = 'XDB';
  exception
    when no_data_found then
	    V_DBMSXUTIL_SCRIPT := '/manageability/dbmsxutil.sql';
  	  V_PRVTXUTIL_SCRIPT := '/manageability/prvtxutil.plb';
    when others then
      RAISE;
  end;
  :DBMSXUTIL_SCRIPT     := V_DBMSXUTIL_SCRIPT;
  :PRVTXUTIL_SCRIPT     := V_PRVTXUTIL_SCRIPT;
end;
/
undef DBMSXUTIL_SCRIPT
undef PRVTXUTIL_SCRIPT
--
column DBMSXUTIL_SCRIPT new_value DBMSXUTIL_SCRIPT
column PRVTXUTIL_SCRIPT new_value PRVTXUTIL_SCRIPT
--
select :DBMSXUTIL_SCRIPT DBMSXUTIL_SCRIPT,
       :PRVTXUTIL_SCRIPT PRVTXUTIL_SCRIPT
  from dual
/
set trimspool on
set long 10000 pages 0 lines 140
--
def DBMSXUTIL_SCRIPT
def PRVTXUTIL_SCRIPT
--
@&SCRIPT_LOCATION\&DBMSXUTIL_SCRIPT
@&SCRIPT_LOCATION\&PRVTXUTIL_SCRIPT
--
set define off
set termout off
--
-- Release specific scritps
--
var XDBPM_11100_FEATURES VARCHAR2(120)
--
declare
  V_XDBPM_11100_FEATURES VARCHAR2(120);
begin
$IF DBMS_DB_VERSION.VER_LE_10_2 $THEN
  V_XDBPM_11100_FEATURES := 'XDBPM_DO_NOTHING.sql';
$ELSE
  V_XDBPM_11100_FEATURES := 'XDBPM_SCRIPTS_11100.sql';
$END
  :XDBPM_11100_FEATURES := V_XDBPM_11100_FEATURES;
end;
/
undef XDBPM_11100_FEATURES
--
column XDBPM_11100_FEATURES new_value XDBPM_11100_FEATURES
--
select :XDBPM_11100_FEATURES XDBPM_11100_FEATURES from dual
/
var XDBPM_12100_FEATURES    VARCHAR2(120)
var XDBPM_12100_PERMISSIONS VARCHAR2(120)
--
declare
  V_XDBPM_12100_FEATURES    VARCHAR2(120);
  V_XDBPM_12100_PERMISSIONS VARCHAR2(120);
begin
$IF DBMS_DB_VERSION.VER_LE_11_2 $THEN
  V_XDBPM_12100_FEATURES    := 'XDBPM_DO_NOTHING.sql';
  V_XDBPM_12100_PERMISSIONS := 'XDBPM_DO_NOTHING.sql';
$ELSE
  V_XDBPM_12100_FEATURES    := 'XDBPM_SCRIPTS_12100.sql';
  V_XDBPM_12100_PERMISSIONS := 'XDBPM_SET_PERMISSIONS_12100.sql';
$END
  :XDBPM_12100_FEATURES    := V_XDBPM_12100_FEATURES;
  :XDBPM_12100_PERMISSIONS := V_XDBPM_12100_PERMISSIONS;
end;
/
undef XDBPM_12100_FEATURES
undef XDBPM_12100_PERMISSIONS
--
column XDBPM_12100_FEATURES    new_value XDBPM_12100_FEATURES
column XDBPM_12100_PERMISSIONS new_value XDBPM_12100_PERMISSIONS
--
select :XDBPM_12100_FEATURES XDBPM_12100_FEATURES, :XDBPM_12100_PERMISSIONS XDBPM_12100_PERMISSIONS from dual
/
def XDBPM_12100_FEATURES
def XDBPM_12100_PERMISSIONS
--
@@XDBPM_SCRIPTS
--
set define on
--
@@&XDBPM_11100_FEATURES
--
set define on
--
@@&XDBPM_12100_FEATURES
--
set define on
--
@@XDBPM_CONFIGURE_USER
@@XDBPM_REGISTER_SCHEMAS
@@XDBPM_ZIP_SUPPORT
--
set termout on
--
@@XDBPM_CHECK_STATUS
--
spool off
quit
