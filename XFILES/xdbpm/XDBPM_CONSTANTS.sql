
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

--
-- XDBPM_constants should be created under XDBPM
--
alter session set current_schema = XDBPM
/
create or replace package XDBPM_USERNAME
as
  function GET_USERNAME return VARCHAR2 deterministic;
end;
/
show errors
/
create or replace synonym XDB_USERNAME for XDBPM_USERNAME
/
grant execute on XDBPM_USERNAME to public
/
create or replace package body XDBPM_USERNAME
as
function GET_USERNAME return VARCHAR2 deterministic
as
begin
 if (USER = 'ANONYMOUS') then
   return sys_context('USERENV','CURRENT_SCHEMA');
 else
   return USER;
 end if;
end;
--
end;
/
show errors
--
create or replace package XDBPM_CONSTANTS
as
    C_PATH_HOME    constant VARCHAR2(700) := '/home';
    C_PATH_DEBUG   constant VARCHAR2(128) := '/debug';
    C_PATH_PUBLIC  constant VARCHAR2(700) := '/publishedContent';
  
    C_PATH_SYSTEM                 constant VARCHAR2(700) := '/sys';
    C_PATH_SYSTEM_ACLS            constant VARCHAR2(700) := C_PATH_SYSTEM  || '/' || 'acls';
    C_PATH_SYSTEM_SCHEMAS         constant VARCHAR2(700) := C_PATH_SYSTEM  || '/' || 'schemas';
    C_PATH_SYSTEM_SCHEMAS_PUBLIC  constant VARCHAR2(700) := C_PATH_SYSTEM_SCHEMAS || '/' || 'PUBLIC';
    C_PATH_SYSTEM_SCHEMAS_PRIVATE constant VARCHAR2(700) := C_PATH_SYSTEM_SCHEMAS || '/' || XDBPM_USERNAME.GET_USERNAME();
    
    C_ACL_ALL_PUBLIC              constant VARCHAR2(700) := C_PATH_SYSTEM_ACLS  || '/' || 'all_all_acl.xml';
    C_ACL_ALL_OWNER               constant VARCHAR2(700) := C_PATH_SYSTEM_ACLS  || '/' || 'all_owner_acl.xml';
    C_ACL_READONLY_ALL            constant VARCHAR2(700) := C_PATH_SYSTEM_ACLS  || '/' || 'ro_all_acl.xml';
    C_ACL_BOOTSTRAP               constant VARCHAR2(700) := C_PATH_SYSTEM_ACLS  || '/' || 'bootstrap_acl.xml';

    C_PATH_USER_HOME   constant VARCHAR2(700) := C_PATH_HOME || '/' || XDBPM_USERNAME.GET_USERNAME();
    C_PATH_USER_DEBUG  constant VARCHAR2(128) := C_PATH_DEBUG || '/' || XDBPM_USERNAME.GET_USERNAME();
    C_PATH_USER_PUBLIC constant VARCHAR2(700) := C_PATH_PUBLIC || '/' || XDBPM_USERNAME.GET_USERNAME(); 

    C_VERSION         constant VARCHAR2(12)  := 'VERSION';
    C_OVERWRITE       constant VARCHAR2(12)  := 'OVERWRITE';
    C_RAISE_ERROR     constant VARCHAR2(12)  := 'RAISE';
    C_SKIP            constant VARCHAR2(12)  := 'SKIP';

    function FOLDER_SYSTEM                       return VARCHAR2 deterministic;
    function FOLDER_SYSTEM_ACLS                  return VARCHAR2 deterministic;
    function FOLDER_SYSTEM_SCHEMAS               return VARCHAR2 deterministic;
    function FOLDER_SYSTEM_SCHEMAS_PUBLIC        return VARCHAR2 deterministic;
    function FOLDER_SYSTEM_SCHEMAS_PRIVATE       return VARCHAR2 deterministic;

    function ACL_ALL_PUBLIC                     return VARCHAR2 deterministic;      
    function ACL_ALL_OWNER                      return VARCHAR2 deterministic;
    function ACL_READONLY_ALL                   return VARCHAR2 deterministic;
    function ACL_BOOTSTRAP                      return VARCHAR2 deterministic;

    function FOLDER_HOME          return VARCHAR2 deterministic;
    function FOLDER_DEBUG         return VARCHAR2 deterministic;
    function FOLDER_PUBLIC        return VARCHAR2 deterministic;
    function FOLDER_USER_HOME     return VARCHAR2 deterministic;
    function FOLDER_USER_DEBUG    return VARCHAR2 deterministic;
    function FOLDER_USER_PUBLIC   return VARCHAR2 deterministic;

    function ENCODING_UTF8        return VARCHAR2 deterministic;
    function ENCODING_WIN1252     return VARCHAR2 deterministic;
    function ENCODING_ISOLATIN1   return VARCHAR2 deterministic;
    function ENCODING_DEFAULT     return VARCHAR2 deterministic;

    function VERSION              return VARCHAR2 deterministic;
    function OVERWRITE            return VARCHAR2 deterministic;
    function RAISE_ERROR          return VARCHAR2 deterministic;
    function SKIP                 return VARCHAR2 deterministic;
end;
/
show errors
--
create or replace synonym XDB_CONSTANTS for XDBPM_CONSTANTS
/
grant execute on XDBPM_CONSTANTS to public
/
create or replace package body XDBPM_CONSTANTS
as
--
function FOLDER_SYSTEM                       return VARCHAR2 deterministic as begin return C_PATH_SYSTEM; end;
--
function FOLDER_SYSTEM_ACLS                  return VARCHAR2 deterministic as begin return C_PATH_SYSTEM_ACLS; end;
--
function FOLDER_SYSTEM_SCHEMAS               return VARCHAR2 deterministic as begin return C_PATH_SYSTEM_SCHEMAS; end;
--
function FOLDER_SYSTEM_SCHEMAS_PUBLIC        return VARCHAR2 deterministic as begin return C_PATH_SYSTEM_SCHEMAS_PUBLIC; end;
--
function FOLDER_SYSTEM_SCHEMAS_PRIVATE       return VARCHAR2 deterministic as begin return C_PATH_SYSTEM_SCHEMAS_PRIVATE; end;
--
function ACL_ALL_PUBLIC                      return VARCHAR2 deterministic as begin return C_ACL_ALL_PUBLIC; end;      
-- 
function ACL_ALL_OWNER                       return VARCHAR2 deterministic as begin return C_ACL_ALL_OWNER; end;
-- 
function ACL_READONLY_ALL                    return VARCHAR2 deterministic as begin return C_ACL_READONLY_ALL; end;
-- 
function ACL_BOOTSTRAP                       return VARCHAR2 deterministic as begin return C_ACL_BOOTSTRAP; end;
--
function FOLDER_HOME                         return VARCHAR2 deterministic as begin return C_PATH_HOME; end;
--                                           
function FOLDER_DEBUG                        return VARCHAR2 deterministic as begin return C_PATH_DEBUG; end;
--                                           
function FOLDER_PUBLIC                       return VARCHAR2 deterministic as begin return C_PATH_PUBLIC; end;
--                                           
function FOLDER_USER_HOME                    return VARCHAR2 deterministic as begin return C_PATH_USER_HOME; end;
--                                           
function FOLDER_USER_DEBUG                   return VARCHAR2 deterministic as begin return C_PATH_USER_DEBUG; end;
--                                           
function FOLDER_USER_PUBLIC                  return VARCHAR2 deterministic as begin return C_PATH_USER_PUBLIC; end;
--                                           
function ENCODING_UTF8                       return VARCHAR2 deterministic as begin return DBMS_XDB_CONSTANTS.ENCODING_UTF8; end;
--                                           
function ENCODING_WIN1252                    return VARCHAR2 deterministic as begin return DBMS_XDB_CONSTANTS.ENCODING_WIN1252; end;
--                                           
function ENCODING_ISOLATIN1                  return VARCHAR2 deterministic as begin return DBMS_XDB_CONSTANTS.ENCODING_ISOLATIN1; end;
--                                           
function ENCODING_DEFAULT                    return VARCHAR2 deterministic as begin return DBMS_XDB_CONSTANTS.ENCODING_DEFAULT; end;
--                                           
function OVERWRITE                           return VARCHAR2 deterministic as begin return C_OVERWRITE ; end;
--                                           
function VERSION                             return VARCHAR2 deterministic as begin return C_VERSION ; end;
--                                           
function RAISE_ERROR                         return VARCHAR2 deterministic as begin return C_RAISE_ERROR ; end;
--                                           
function SKIP                                return VARCHAR2 deterministic as begin return C_SKIP ; end;
--
end XDBPM_CONSTANTS;
/
show errors
--
alter session set current_schema = SYS
/
