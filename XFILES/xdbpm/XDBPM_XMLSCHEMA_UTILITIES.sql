
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
-- XDBPM_XMLSCHEMA_UTILITIES should be created under XDBPM
--
alter session set current_schema = XDBPM
/
ALTER SESSION SET PLSQL_CCFLAGS = 'DEBUG:FALSE'
/
--
set define on
--
create or replace package XDBPM_XMLSCHEMA_UTILITIES
authid CURRENT_USER
as

  procedure scopeXMLReferences;
  procedure indexXMLReferences(INDEX_NAME VARCHAR2);
  procedure prepareBulkLoad(P_TABLE_NAME VARCHAR2, P_OWNER VARCHAR2 DEFAULT USER);
  procedure completeBulkLoad(P_TABLE_NAME VARCHAR2, P_OWNER VARCHAR2 DEFAULT USER);
  procedure renameCollectionTable (XMLTABLE VARCHAR2, XPATH VARCHAR2, COLLECTION_TABLE_PREFIX VARCHAR2);
 
  function printNestedTables(XML_TABLE VARCHAR2) return XMLType;
  function getDefaultTableName(P_RESOURCE_PATH VARCHAR2) return VARCHAR2;
  
  function generateSchemaFromTable(P_TABLE_NAME VARCHAR2, P_OWNER VARCHAR2 default USER) return XMLTYPE;  
  function generateCreateTableStatement(XML_TABLE_NAME VARCHAR2, NEW_TABLE_NAME VARCHAR2) return CLOB;

  procedure cleanupSchema(P_OWNER VARCHAR2);

  procedure generateCycleReport(P_RESOURCE_PATH VARCHAR2 DEFAULT '/public/cycleReport.log');            
  procedure deleteOrphanTypes(P_REGISTRATION_DATE TIMESTAMP);
  
  procedure disableTableReferencedElements(P_XML_SCHEMA IN OUT XMLTYPE);
  procedure disableTableSubgroupMembers(P_XML_SCHEMA IN OUT XMLTYPE);
  procedure disableTableNonRootElements(P_XML_SCHEMA IN OUT XMLTYPE);

end XDBPM_XMLSCHEMA_UTILITIES;
/
show errors
--
create or replace synonym XDB_XMLSCHEMA_UTILITIES for XDBPM_XMLSCHEMA_UTILITIES
/
create or replace package body XDBPM_XMLSCHEMA_UTILITIES
as
  TYPE TYPE_DEFINITION_T 
  is RECORD
  (
    TYPE_NAME VARCHAR2(30),
    OWNER     VARCHAR2(30)
  );
--
  TYPE TYPE_LIST_T 
    is TABLE of TYPE_DEFINITION_T;
--
  TYPE CYCLE_LIST_ENTRY_T 
  is RECORD
  (
    TYPE            TYPE_DEFINITION_T,
    SUPER_TYPE_LIST TYPE_LIST_T
  );
--
  TYPE CYCLE_LIST_T
    is TABLE of CYCLE_LIST_ENTRY_T;
--  
  G_KNOWN_CYCLE_LIST TYPE_LIST_T;
--
  G_PROCESSED_TYPE_LIST TYPE_LIST_T;
--
procedure scopeXMLReferences
as
begin
  XDB.DBMS_XMLSTORAGE_MANAGE.scopeXMLReferences;
end;
--
procedure indexXMLReferences(INDEX_NAME VARCHAR2)
as
  cursor getTables
  is
  select distinct TABLE_NAME
    from USER_REFS
   where IS_SCOPED = 'NO';
   
begin
  for t in getTables loop
    XDB.DBMS_XMLSTORAGE_MANAGE.indexXMLReferences(USER,t.TABLE_NAME,null,INDEX_NAME);
  end loop;
end;
--  
procedure renameCollectionTable (XMLTABLE VARCHAR2, XPATH VARCHAR2, COLLECTION_TABLE_PREFIX VARCHAR2)
as
begin
  XDB.DBMS_XMLSTORAGE_MANAGE.renameCollectionTable(USER,XMLTABLE,NULL,XPATH,COLLECTION_TABLE_PREFIX || 'TABLE');
end;
--
procedure prepareBulkLoad(P_TABLE_NAME VARCHAR2, P_OWNER VARCHAR2 DEFAULT USER)
as
begin
  XDB.DBMS_XMLSTORAGE_MANAGE.enableIndexesAndConstraints(P_TABLE_NAME, P_OWNER);
end;
--
procedure completeBulkLoad(P_TABLE_NAME VARCHAR2, P_OWNER VARCHAR2 DEFAULT USER)
as
begin
  XDB.DBMS_XMLSTORAGE_MANAGE.enableIndexesAndConstraints(P_TABLE_NAME, P_OWNER);
end;
--
procedure cleanupSchema(P_OWNER VARCHAR2)
as
  V_OBJECT_COUNT number;
begin

  select count(*) 
    into V_OBJECT_COUNT
    from ALL_USERS
   where USERNAME = P_OWNER;
   
  if (V_OBJECT_COUNT > 0) then
    RAISE_APPLICATION_ERROR( -20000, 'User "' || P_OWNER || '" exists. XML Schema clean up only valid for dropped users.');
  end if;

  select count(*) 
    into V_OBJECT_COUNT
    from XDB.XDB$SCHEMA x
   where x.XMLDATA.SCHEMA_OWNER = P_OWNER;
  
  if (V_OBJECT_COUNT > 0) then
    delete 
      from XDB.XDB$SCHEMA x
     where x.XMLDATA.SCHEMA_OWNER = P_OWNER;
     commit;
  end if;
    
  select count(*) 
    into V_OBJECT_COUNT
    from XDB.XDB$COMPLEX_TYPE x
   where x.XMLDATA.SQLSCHEMA = P_OWNER;
  
  if (V_OBJECT_COUNT > 0) then
    delete 
      from XDB.XDB$COMPLEX_TYPE x
     where x.XMLDATA.SQLSCHEMA = P_OWNER;
     commit;
  end if;

  select count(*) 
    into V_OBJECT_COUNT
    from XDB.XDB$ELEMENT x
   where x.XMLDATA.PROPERTY.SQLSCHEMA = P_OWNER;
  
  if (V_OBJECT_COUNT > 0) then
    delete 
      from XDB.XDB$ELEMENT x
     where x.XMLDATA.PROPERTY.SQLSCHEMA = P_OWNER;
     commit;
  end if;

  select count(*) 
    into V_OBJECT_COUNT
    from XDB.XDB$ATTRIBUTE x
   where x.XMLDATA.SQLSCHEMA = P_OWNER;
  
  if (V_OBJECT_COUNT > 0) then
    delete 
      from XDB.XDB$ATTRIBUTE x
     where x.XMLDATA.SQLSCHEMA = P_OWNER;
     commit;
  end if;

  select count(*) 
    into V_OBJECT_COUNT
    from XDB.XDB$ANYATTR x
   where x.XMLDATA.PROPERTY.SQLSCHEMA = P_OWNER;
  
  if (V_OBJECT_COUNT > 0) then
    delete 
      from XDB.XDB$ANYATTR x
     where x.XMLDATA.PROPERTY.SQLSCHEMA = P_OWNER;
     commit;
  end if;

  select count(*) 
    into V_OBJECT_COUNT
    from XDB.XDB$ANY x
   where x.XMLDATA.PROPERTY.SQLSCHEMA = P_OWNER;
  
  if (V_OBJECT_COUNT > 0) then
    delete 
      from XDB.XDB$ANY x
     where x.XMLDATA.PROPERTY.SQLSCHEMA = P_OWNER;
     commit;
  end if;

end;
--
function processNestedTable(currentLevel in out number, currentNode in out XMLType, query SYS_REFCURSOR)
return XMLType
is 
  thisLevel  number;
  thisNode   xmlType;
  result xmlType;
begin
  thisLevel := currentLevel;
  thisNode := currentNode;
  fetch query into currentLevel, currentNode;
  if (query%NOTFOUND) then 
    currentLevel := -1;
  end if;
  while (currentLevel >= thisLevel) loop
    -- Next Node is a decendant of sibling of this Node.
    if (currentLevel > thisLevel) then
      -- Next Node is a decendant of this Node. 
      result := processNestedTable(currentLevel, currentNode, query);
      select xmlElement
             (
                "Collection",
                extract(thisNode,'/Collection/*'),
                xmlElement
                (
                  "NestedCollections",
                  result
                )
              )
         into thisNode
         from dual;
    else
      -- Next node is a sibling of this Node. 
      result := processNestedTable(currentLevel, currentNode, query);
      select xmlconcat(thisNode,result) into thisNode from dual;
    end if;
  end loop;

  -- Next Node is a sibling of some ancestor of this node.

  return thisNode;
  
end;
--
function printNestedTables(XML_TABLE VARCHAR2)
return XMLType
is
   query SYS_REFCURSOR;
   result XMLType;
   rootLevel number := 0;
   rootNode xmlType; 
begin
   open query for 
        select level, xmlElement
                      (
                        "Collection",
                        xmlElement
                        (
                          "CollectionId",
                          PARENT_TABLE_COLUMN
                        )
                      ) as XML
          from USER_NESTED_TABLES
       connect by PRIOR TABLE_NAME = PARENT_TABLE_NAME
               start with PARENT_TABLE_NAME = XML_TABLE;
    fetch query into rootLevel, rootNode;
    result := processNestedTable(rootLevel, rootNode, query);
    select xmlElement
           (
              "NestedTableStructure",
              result
           )
      into result 
      from dual;
    return result;
end;
--
function getDefaultTableName(P_RESOURCE_PATH VARCHAR2)
return VARCHAR2
as 
  V_TARGET_URL          VARCHAR2(4096);
  V_SCHEMA_URL          VARCHAR2(1024);
  V_ELEMENT_NAME        VARCHAR2(2000);
  V_DEFAULT_TABLE_NAME  VARCHAR2(32);
begin
  select extractValue(res,'/Resource/SchemaElement')
    into V_TARGET_URL
    from RESOURCE_VIEW
   where equals_path(res,P_RESOURCE_PATH) = 1;

  V_SCHEMA_URL := substr(V_TARGET_URL,1,instr(V_TARGET_URL,'#')-1);
  V_ELEMENT_NAME := substr(V_TARGET_URL,instr(V_TARGET_URL,'#')+1);

  select extractValue
         (
            SCHEMA,
            '/xsd:schema/xsd:element[@name="' || V_ELEMENT_NAME || '"]/@xdb:defaultTable',
            xdb_namespaces.XMLSCHEMA_PREFIX_XSD || ' ' || xdb_namespaces.XDBSCHEMA_PREFIX_XDB
         )
    into V_DEFAULT_TABLE_NAME
    from USER_XML_SCHEMAS
   where SCHEMA_URL = V_SCHEMA_URL;
     
  return V_DEFAULT_TABLE_NAME;
end;
--
function generateSchemaFromTable(P_TABLE_NAME VARCHAR2, P_OWNER VARCHAR2 default USER)
return XMLTYPE
as
  xmlSchema XMLTYPE;
begin
  select xmlElement
         (
           "xsd:schema",
           xmlAttributes
           (
             'http://www.w3.org/2001/XMLSchema' as "xmlns:xsd",
             'http://xmlns.oracle.com/xdb' as "xmlns:xdb"
           ),
           xmlElement
           (
             "xsd:element",
             xmlAttributes
             (
               'ROWSET' as "name",
               'rowset' as "type"
             )
           ),
           xmlElement 
           (
             "xsd:complexType",
             xmlAttributes
             (
               'rowset' as "name"
             ),
             xmlElement
             (
               "xsd:sequence",
               xmlElement
               (
                  "xsd:element",
                  xmlAttributes
                  (
                    'ROW' as "name",
                    table_name || '_T' as "type",
                    'unbounded' as "maxOccurs"
                  )
                )
              )
           ),
           xmlElement
           (
             "xsd:complexType",
             xmlAttributes
             (
               table_name || '_T' as "name"
             ),
             xmlElement
             (
               "xsd:sequence",
               (
                 xmlAgg(ELEMENT order by INTERNAL_COLUMN_ID)
               )
             )
           )
         )
    into xmlSchema
    from (select TABLE_NAME, INTERNAL_COLUMN_ID,
                 case 
                   when DATA_TYPE in ('VARCHAR2','CHAR') then
                     xmlElement
                     (
                       "xsd:element",
                       xmlattributes
                       (
                         column_name as "name", 
                         decode(NULLABLE, 'Y', 0, 1) as "minOccurs",
                         column_name as "xdb:SQLName", 
                         DATA_TYPE as "xdb:SQLType"
                       ),
                       xmlElement
                       (
                         "xsd:simpleType",
                         xmlElement
                         (
                           "xsd:restriction",
                           xmlAttributes
                           (
                             'xsd:string' as "base"
                           ),
                           xmlElement
                           (
                             "xsd:maxLength",
                             xmlAttributes
                             (
                               DATA_LENGTH  as "value"
                             )
                           )
                         )
                       )
                     )
                   when DATA_TYPE = 'NUMBER' then
                     xmlElement
                     (
                       "xsd:element",
                       xmlattributes
                       (
                         column_name as "name", 
                         decode(NULLABLE, 'Y', 0, 1) as "minOccurs",
                         column_name as "xdb:SQLName", 
                         DATA_TYPE as "xdb:SQLType"
                       ),
                       xmlElement
                       (
                         "xsd:simpleType",
                         xmlElement
                         (
                           "xsd:restriction",
                           xmlAttributes
                           (
                              decode(DATA_SCALE, 0, 'xsd:integer', 'xsd:double') as "base"
                           ),
                           xmlElement
                           (
                             "xsd:totalDigits",
                             xmlAttributes
                             (
                               DATA_PRECISION  as "value"
                             )
                           )
                         )
                       )
                     )
                   when DATA_TYPE = 'DATE' then
                     xmlElement
                     (
                       "xsd:element",
                       xmlattributes
                       (
                         column_name as "name", 
                         decode(NULLABLE, 'Y', 0, 1) as "minOccurs",
                         'xsd:date' as "type",
                         column_name as "xdb:SQLName", 
                         DATA_TYPE as "xdb:SQLType"
                       )
                     )
                   when DATA_TYPE like 'TIMESTAMP%WITH TIME ZONE' then
                     xmlElement
                     (
                       "xsd:element",
                       xmlattributes
                       (
                         column_name as "name", 
                         decode(NULLABLE, 'Y', 0, 1) as "minOccurs",
                         'xsd:dateTime' as "type",
                         column_name as "xdb:SQLName", 
                         DATA_TYPE as "xdb:SQLType"
                       )
                     )
                   else
                     xmlElement
                     (
                       "xsd:element",
                       xmlattributes
                       (
                         column_name as "name", 
                         decode(NULLABLE, 'Y', 0, 1) as "minOccurs",
                         'xsd:anySimpleType' as "type",
                         column_name as "xdb:SQLName", 
                         DATA_TYPE as "xdb:SQLType"
                       )
                     )
                 end ELEMENT
            from all_tab_cols c 
           where c.TABLE_NAME = P_TABLE_NAME
             and c.OWNER = P_OWNER
          )
    group by TABLE_NAME;
  return xmlSchema;
end;
--
function generateCreateTableStatement(XML_TABLE_NAME VARCHAR2, NEW_TABLE_NAME VARCHAR2)
return CLOB
is
  DDL_STATEMENT CLOB;
  cursor getStructure (XML_TABLE_NAME VARCHAR2) is
  select level, PARENT_TABLE_NAME, PARENT_TABLE_COLUMN, TABLE_TYPE_NAME, TABLE_NAME
    from USER_NESTED_TABLES
         connect by PRIOR TABLE_NAME = PARENT_TABLE_NAME
                 start with PARENT_TABLE_NAME = XML_TABLE_NAME;
  current_level pls_integer := 0;
  clause VARCHAR2(4000);
  indent VARCHAR2(4000); 
  table_number pls_integer := 0;
  
  XMLSCHEMA VARCHAR2(700);
  ELEMENT   VARCHAR2(2000);
  
begin
  dbms_lob.createTemporary(DDL_STATEMENT,FALSE,DBMS_LOB.SESSION);
  current_level := 0;

  select XMLSCHEMA, ELEMENT_NAME 
    into XMLSCHEMA, ELEMENT
    from USER_XML_TABLES
   where TABLE_NAME = XML_TABLE_NAME;

  clause := 'create table "' || NEW_TABLE_NAME ||'" of XMLType' || chr(10) ||
            'XMLSCHEMA "' || XMLSCHEMA || '" ELEMENT "' || ELEMENT || '"' || CHR(10);
  dbms_lob.writeAppend(DDL_STATEMENT,length(clause),clause);            
  for nt in getStructure(XML_TABLE_NAME) loop
     clause := null;
     if nt.level <= current_level then
       while current_level  >= nt.level loop
         indent := lpad(' ',current_level * 2,' ');
         clause := clause || indent || ')' || chr(10);
         current_level := current_level - 1;
       end loop;
     end if;
     current_level := nt.level;
     table_number := table_number + 1;
     indent := lpad(' ',nt.level * 2,' ');
     clause := clause ||
               indent || 'varray ' || nt.PARENT_TABLE_COLUMN || chr(10) || 
               indent || 'store as table "' || NEW_TABLE_NAME || '_NT' || lpad(table_number,4,'0') || '"' || chr(10) ||
               indent || '(' || chr(10) ||
               indent || '  ( constraint "' || NEW_TABLE_NAME || '_NT' || lpad(table_number,4,'0') || '_PKEY" primary key (NESTED_TABLE_ID, SYS_NC_ARRAY_INDEX$))' || chr(10);
     dbms_lob.writeAppend(DDL_STATEMENT,length(clause),clause);
  end loop;
  clause := null;
  while current_level  > 0 loop
    indent := lpad(' ',current_level * 2,' ');
    clause := clause || indent || ')' || chr(10);
    current_level := current_level - 1;
  end loop;
  if clause is not null then
    dbms_lob.writeAppend(DDL_STATEMENT,length(clause),clause);
  end if;
  return DDL_STATEMENT;
end;
--
procedure disableTableReferencedElements(P_XML_SCHEMA IN OUT XMLTYPE)
as
	cursor getElementReferences
	is
	select REF
    from XMLTABLE
         (
            xmlNamespaces
            (
              'http://www.w3.org/2001/XMLSchema' as "xsd"
            ),
            '/xsd:schema//xsd:element[@ref]'
            passing P_XML_SCHEMA
            columns REF VARCHAR2(4000) path '@ref'
        );
begin 
  for ge in getElementReferences loop
    DBMS_XMLSCHEMA_ANNOTATE.disableDefaultTableCreation(P_XML_SCHEMA,ge.REF); 
  end loop;
end;
--
procedure disableTableSubgroupMembers(P_XML_SCHEMA IN OUT XMLTYPE)
as
	cursor getSubstitutionMembers
	is
	select NAME
    from XMLTABLE
         (
            xmlNamespaces
            (
              'http://www.w3.org/2001/XMLSchema' as "xsd"
            ),
            '/xsd:schema/xsd:element[@substitutionGroup]/@name'
            passing P_XML_SCHEMA
            columns NAME VARCHAR2(4000) path '@name'
        );
        
begin 
  for ge in getSubstitutionMembers loop
    DBMS_XMLSCHEMA_ANNOTATE.disableDefaultTableCreation(P_XML_SCHEMA,ge.NAME); 
  end loop;
end;
--
procedure disableTableNonRootElements(P_XML_SCHEMA IN OUT XMLTYPE)
as
begin
	 XDB_XMLSCHEMA_UTILITIES.disableTableSubgroupMembers(P_XML_SCHEMA);
	 XDB_XMLSCHEMA_UTILITIES.disableTableReferencedElements(P_XML_SCHEMA);
end;
--
function initializeSchemaAnnotations(P_SCHEMA_LOCATION_HINT VARCHAR2)
return CLOB
as
  V_BUFFER  VARCHAR2(4000);
  V_CONTENT CLOB;
begin
	  
	return V_CONTENT;
end;
--
function isCyclicReference(P_TYPE_NAME VARCHAR2, P_OWNER VARCHAR2, P_ATTR_NAME VARCHAR2, P_ATTR_TYPE_NAME VARCHAR2, P_ATTR_TYPE_OWNER VARCHAR2, P_LEVEL NUMBER,  P_CYCLE_LIST CYCLE_LIST_T)
return BOOLEAN
as
begin	
	if (P_LEVEL > 50) then
	  XDB_OUTPUT.WRITEOUTPUTFILEENTRY('Level limit excceeded.',TRUE);
	  return true;
	end if;
	if P_CYCLE_LIST.count() > 0 then
	  for i in P_CYCLE_LIST.first .. P_CYCLE_LIST.last loop
	    if P_CYCLE_LIST(i).TYPE.TYPE_NAME = P_ATTR_TYPE_NAME and P_CYCLE_LIST(i).TYPE.OWNER = P_ATTR_TYPE_OWNER then
     	  XDB_OUTPUT.WRITEOUTPUTFILEENTRY('isCyclicReference [' || P_LEVEL || '] : "' || P_OWNER || '"."' || P_TYPE_NAME || '"."' || P_ATTR_NAME || '"  of type "' || P_ATTR_TYPE_OWNER || '"."' || P_ATTR_TYPE_NAME || '". Cycle Detected.',TRUE);
	      G_KNOWN_CYCLE_LIST.extend();
	      G_KNOWN_CYCLE_LIST(G_KNOWN_CYCLE_LIST.last).TYPE_NAME := P_TYPE_NAME;
	      G_KNOWN_CYCLE_LIST(G_KNOWN_CYCLE_LIST.last).OWNER := P_OWNER;
        return true;
      end if;
      if P_CYCLE_LIST(i).SUPER_TYPE_LIST.count() > 0 then
        for j in P_CYCLE_LIST(i).SUPER_TYPE_LIST.first .. P_CYCLE_LIST(i).SUPER_TYPE_LIST.last loop
    	    if P_CYCLE_LIST(i).SUPER_TYPE_LIST(j).TYPE_NAME = P_ATTR_TYPE_NAME and P_CYCLE_LIST(i).SUPER_TYPE_LIST(j).OWNER = P_ATTR_TYPE_OWNER then
        	  XDB_OUTPUT.WRITEOUTPUTFILEENTRY('isCyclicReference [' || P_LEVEL || '] : "' || P_OWNER || '"."' || P_TYPE_NAME || '"."' || P_ATTR_NAME || '"  of type "' || P_ATTR_TYPE_OWNER || '"."' || P_ATTR_TYPE_NAME || '". Cycle by Supertype Detected.',TRUE);
     	      G_KNOWN_CYCLE_LIST.extend();
	          G_KNOWN_CYCLE_LIST(G_KNOWN_CYCLE_LIST.last).TYPE_NAME := P_TYPE_NAME;
	          G_KNOWN_CYCLE_LIST(G_KNOWN_CYCLE_LIST.last).OWNER := P_OWNER;
            return true;
          end if;
        end loop;
      end if;
    end loop;
  end if;    
	return false;
end;
--
procedure processType(P_TYPE_NAME VARCHAR2, P_OWNER VARCHAR2,P_LEVEL NUMBER,  P_CYCLE_LIST CYCLE_LIST_T)
as
  V_CYCLE_LIST CYCLE_LIST_T := P_CYCLE_LIST;
  V_LEVEL NUMBER := P_LEVEL + 1;
  cursor findChildren 
  is
  select ATTR_NAME, ATTR_TYPE_NAME, ATTR_TYPE_OWNER
    from XDBPM.MISSING_TYPE_ATTRS
   where TYPE_NAME = P_TYPE_NAME
     and P_OWNER = P_OWNER;
     
  cursor findSubTypes
  is
  select TYPE_NAME, OWNER
    from XDBPM.MISSING_TYPES
   where SUPERTYPE_NAME = P_TYPE_NAME
    and SUPERTYPE_OWNER = P_OWNER;
    
  cursor findSuperTypes 
  is
  select SUPERTYPE_NAME, SUPERTYPE_OWNER
    FROM XDBPM.XDBPM_ALL_TYPES
         CONNECT BY prior SUPERTYPE_NAME = TYPE_NAME
                      and SUPERTYPE_OWNER = OWNER
         START WITH TYPE_NAME = P_TYPE_NAME
                and OWNER = P_OWNER;
                   
  V_CYCLE_DETECTED BOOLEAN := FALSE;
  
begin
	
	if G_KNOWN_CYCLE_LIST.count() > 0 then
	  for i in G_KNOWN_CYCLE_LIST.first .. G_KNOWN_CYCLE_LIST.last loop
	    if G_KNOWN_CYCLE_LIST(i).TYPE_NAME = P_TYPE_NAME and G_KNOWN_CYCLE_LIST(i).OWNER = P_OWNER then
        XDB_OUTPUT.WRITEOUTPUTFILEENTRY('Skipping known cyclic type : "' || P_OWNER || '"."' || P_TYPE_NAME || '".',TRUE);
	      return;
	    end if;
	  end loop;
  end if;
	    
	if G_PROCESSED_TYPE_LIST.count() > 0 then
	  for i in G_PROCESSED_TYPE_LIST.first .. G_PROCESSED_TYPE_LIST.last loop
	    if G_PROCESSED_TYPE_LIST(i).TYPE_NAME = P_TYPE_NAME and G_PROCESSED_TYPE_LIST(i).OWNER = P_OWNER then
        XDB_OUTPUT.WRITEOUTPUTFILEENTRY('Skipping known non-cyclic type : "' || P_OWNER || '"."' || P_TYPE_NAME || '".',TRUE);
	      return;
	    end if;
	  end loop;
  end if;
  
	V_CYCLE_LIST.extend();
	V_CYCLE_LIST(V_CYCLE_LIST.last).TYPE.TYPE_NAME := P_TYPE_NAME;
	V_CYCLE_LIST(V_CYCLE_LIST.last).TYPE.OWNER := P_OWNER;
	V_CYCLE_LIST(V_CYCLE_LIST.last).SUPER_TYPE_LIST := TYPE_LIST_T();
	for s in findSupertypes loop
	  V_CYCLE_LIST(V_CYCLE_LIST.last).SUPER_TYPE_LIST.extend();
	  V_CYCLE_LIST(V_CYCLE_LIST.last).SUPER_TYPE_LIST(V_CYCLE_LIST(V_CYCLE_LIST.last).SUPER_TYPE_LIST.last).TYPE_NAME := s.SUPERTYPE_NAME;
	  V_CYCLE_LIST(V_CYCLE_LIST.last).SUPER_TYPE_LIST(V_CYCLE_LIST(V_CYCLE_LIST.last).SUPER_TYPE_LIST.last).OWNER := s.SUPERTYPE_OWNER;
  end loop;
	  
  XDB_OUTPUT.WRITEOUTPUTFILEENTRY('processType [' || P_LEVEL || '] : Checking "' || P_OWNER || '"."' || P_TYPE_NAME || '".',TRUE);
	for c in findChildren() loop 
   	XDB_OUTPUT.WRITEOUTPUTFILEENTRY('Child : "' || c.ATTR_TYPE_OWNER || '"."' || c.ATTR_TYPE_NAME || '"."' || c.ATTR_NAME || '".',TRUE);
	  V_CYCLE_DETECTED := isCyclicReference(P_TYPE_NAME, P_OWNER, c.ATTR_NAME, c.ATTR_TYPE_NAME, c.ATTR_TYPE_OWNER, V_LEVEL,V_CYCLE_LIST);
	  if ( not V_CYCLE_DETECTED) then
   	  processType(c.ATTR_TYPE_NAME,C.ATTR_TYPE_OWNER,V_LEVEL,V_CYCLE_LIST);
	  end if;
	end loop;
	
  for st in findSubTypes() loop
    XDB_OUTPUT.WRITEOUTPUTFILEENTRY('SubType : "' || st.OWNER || '"."' || st.TYPE_NAME || '".',TRUE);
 	  processType(st.TYPE_NAME,st.OWNER,V_LEVEL,V_CYCLE_LIST);
	end loop;

  G_KNOWN_CYCLE_LIST.extend();
  G_KNOWN_CYCLE_LIST(G_KNOWN_CYCLE_LIST.last).TYPE_NAME := P_TYPE_NAME;
  G_KNOWN_CYCLE_LIST(G_KNOWN_CYCLE_LIST.last).OWNER := P_OWNER;
	  	    
end;
--
procedure generateCycleReport(P_RESOURCE_PATH VARCHAR2 DEFAULT '/public/cycleReport.log')
as
  cursor findUnresolvedElements
  is
  select ge.XMLDATA.PROPERTY.SQLTYPE  TYPE_NAME,
         ge.XMLDATA.PROPERTY.SQLSCHEMA OWNER
    from xdb.xdb$ELEMENT ge, XDBPM.MISSING_TYPES mt
   where ge.XMLDATA.PROPERTY.SQLTYPE = mt.TYPE_NAME
     and ge.XMLDATA.PROPERTY.SQLSCHEMA = mt.OWNER
     and ge.XMLDATA.PROPERTY.GLOBAL = hexToRaw('01')
     and ge.XMLDATA.HEAD_ELEM_REF is null
     and not exists
         (
           select 1 
             from XDB.XDB$ELEMENT le
            where le.XMLDATA.PROPERTY.PROPREF_REF = ref(ge)
              and le.XMLDATA.PROPERTY.GLOBAL = hexToRaw('00')
         )
   order by ge.XMLDATA.PROPERTY.SQLTYPE;

  V_CYCLE_LIST CYCLE_LIST_T;
  V_TYPE_SUMMARY_SIZE NUMBER :=0;
  
begin
	select count(*) 
	  into V_TYPE_SUMMARY_SIZE
	  from XDBPM.TYPE_SUMMARY;
	  
	if (V_TYPE_SUMMARY_SIZE = 0) then
	  XDB_OPTIMIZE_XMLSCHEMA.generateTypeSummary();
	end if;

	XDB_OUTPUT.createOutputFile(P_RESOURCE_PATH,TRUE);
	G_KNOWN_CYCLE_LIST := TYPE_LIST_T();
	G_PROCESSED_TYPE_LIST := TYPE_LIST_T();
  for ge in findUnresolvedElements() loop
    V_CYCLE_LIST := CYCLE_LIST_T();
    processType(ge.TYPE_NAME,ge.OWNER,1,V_CYCLE_LIST);
  end loop;
end;
--
procedure deleteOrphanTypes(P_REGISTRATION_DATE TIMESTAMP)
as
  cursor getOrphanTypes 
  is
  select OBJECT_NAME 
    from USER_OBJECTS
   where OBJECT_TYPE = 'TYPE'
     and to_timestamp(TIMESTAMP,'YYYY-MM-DD:HH24:MI:SS') > P_REGISTRATION_DATE
     and not exists
         (
           select 1
             from XDB.XDB$COMPLEX_TYPE ct, XDB.XDB$SCHEMA s
            where ct.XMLDATA.SQLTYPE = OBJECT_NAME
              and ref(s) = ct.XMLDATA.PARENT_SCHEMA 
              and s.XMLDATA.SCHEMA_OWNER = USER           
            union all
           select 1
             from XDB.XDB$ELEMENT e, XDB.XDB$SCHEMA s
            where e.XMLDATA.PROPERTY.SQLCOLLTYPE = OBJECT_NAME
              and ref(s) = e.XMLDATA.PROPERTY.PARENT_SCHEMA 
              and s.XMLDATA.SCHEMA_OWNER = USER     
         );
begin
	for t in getOrphanTypes loop
	  execute immediate 'drop type "' || t.OBJECT_NAME || '" force';
	end loop;
end;
--
end XDBPM_XMLSCHEMA_UTILITIES;
/
show errors
--
grant execute on XDBPM_XMLSCHEMA_UTILITIES to public
/