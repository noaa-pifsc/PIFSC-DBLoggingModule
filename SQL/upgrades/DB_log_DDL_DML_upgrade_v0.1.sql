--------------------------------------------------------
--------------------------------------------------------
--Database Name: Database Log
--Database Description: This module was created to log information in the database for various backend operations.  This is preferable to a file-based log since it can be easily queried, filtered, searched, and used for reporting purposes
--------------------------------------------------------
--------------------------------------------------------


--------------------------------------------------------
--Database Log - version 0.1 updates:
--------------------------------------------------------




CREATE TABLE DB_LOG_ENTRIES
(
  LOG_ENTRY_ID NUMBER NOT NULL
, ENTRY_TYPE_ID NUMBER NOT NULL
, LOG_SOURCE VARCHAR2(200) NOT NULL
, ENTRY_CONTENT CLOB NOT NULL
, ENTRY_DTM DATE NOT NULL
, CONSTRAINT DB_LOG_ENTRIES_PK PRIMARY KEY
  (
    LOG_ENTRY_ID
  )
  ENABLE
);

COMMENT ON COLUMN DB_LOG_ENTRIES.ENTRY_TYPE_ID IS 'Foreign key reference to the DB_ENTRY_TYPES table that defines the type of database log entry';

COMMENT ON COLUMN DB_LOG_ENTRIES.LOG_SOURCE IS 'The application/module/script that produced the database log entry';

COMMENT ON COLUMN DB_LOG_ENTRIES.ENTRY_CONTENT IS 'The content of the database log entry';

COMMENT ON COLUMN DB_LOG_ENTRIES.ENTRY_DTM IS 'The date/time the database log entry was made';

ALTER TABLE DB_LOG_ENTRIES
ADD (CREATED_BY VARCHAR2(30) );

COMMENT ON COLUMN DB_LOG_ENTRIES.CREATED_BY IS 'The Oracle username of the person creating this record in the database';


CREATE SEQUENCE DB_LOG_ENTRIES_SEQ INCREMENT BY 1 START WITH 1;

COMMENT ON TABLE DB_LOG_ENTRIES IS 'Database Log Entries

This table stores log entries for a given module to enable debugging, logging errors, etc.  This table is used in the Database Logging Module (DLM)';

COMMENT ON COLUMN DB_LOG_ENTRIES.LOG_ENTRY_ID IS 'Primary Key for the DB_LOG_ENTRIES table';

create or replace TRIGGER DB_LOG_ENTRIES_AUTO_BRI
before insert on DB_LOG_ENTRIES
for each row
begin
  select DB_LOG_ENTRIES_SEQ.nextval into :new.LOG_ENTRY_ID from dual;
  :NEW.CREATED_BY := nvl(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'),user);
end;
/

CREATE TABLE DB_LOG_ENTRY_TYPES
(
  ENTRY_TYPE_ID NUMBER NOT NULL
, ENTRY_TYPE_CODE VARCHAR2(10) NOT NULL
, ENTRY_TYPE_NAME VARCHAR2(100) NOT NULL
, ENTRY_TYPE_DESC VARCHAR2(500)
, CONSTRAINT DB_LOG_ENTRY_TYPES_PK PRIMARY KEY
  (
    ENTRY_TYPE_ID
  )
  ENABLE
);

ALTER TABLE DB_LOG_ENTRY_TYPES
ADD CONSTRAINT DB_LOG_ENTRY_TYPES_U1 UNIQUE
(
  ENTRY_TYPE_CODE
)
ENABLE;

ALTER TABLE DB_LOG_ENTRY_TYPES
ADD CONSTRAINT DB_LOG_ENTRY_TYPES_U2 UNIQUE
(
  ENTRY_TYPE_NAME
)
ENABLE;

COMMENT ON COLUMN DB_LOG_ENTRY_TYPES.ENTRY_TYPE_CODE IS 'The alphabetic code of the given database log entry type';

COMMENT ON COLUMN DB_LOG_ENTRY_TYPES.ENTRY_TYPE_NAME IS 'The name of the given database log entry type';

COMMENT ON COLUMN DB_LOG_ENTRY_TYPES.ENTRY_TYPE_DESC IS 'The description of the given database log entry type';


CREATE INDEX DB_LOG_ENTRIES_I1 ON DB_LOG_ENTRIES (ENTRY_TYPE_ID);

ALTER TABLE DB_LOG_ENTRIES
ADD CONSTRAINT DB_LOG_ENTRIES_FK1 FOREIGN KEY
(
  ENTRY_TYPE_ID
)
REFERENCES DB_LOG_ENTRY_TYPES
(
  ENTRY_TYPE_ID
)
ENABLE;

CREATE SEQUENCE DB_LOG_ENTRY_TYPES_SEQ INCREMENT BY 1 START WITH 1;

ALTER TABLE DB_LOG_ENTRY_TYPES ADD (CREATE_DATE DATE );
ALTER TABLE DB_LOG_ENTRY_TYPES
ADD (CREATED_BY VARCHAR2(30) );
ALTER TABLE DB_LOG_ENTRY_TYPES
ADD (LAST_MOD_DATE DATE );
ALTER TABLE DB_LOG_ENTRY_TYPES
ADD (LAST_MOD_BY VARCHAR2(30) );
COMMENT ON COLUMN DB_LOG_ENTRY_TYPES.CREATE_DATE IS 'The date on which this record was created in the database';
COMMENT ON COLUMN DB_LOG_ENTRY_TYPES.CREATED_BY IS 'The Oracle username of the person creating this record in the database';
COMMENT ON COLUMN DB_LOG_ENTRY_TYPES.LAST_MOD_DATE IS 'The last date on which any of the data in this record was changed';
COMMENT ON COLUMN DB_LOG_ENTRY_TYPES.LAST_MOD_BY IS 'The Oracle username of the person making the most recent change to this record';
COMMENT ON TABLE DB_LOG_ENTRY_TYPES IS 'Database Log Entry Types

This table stores the different types of database log entries.  Entry types include informational, errors, and success ';
COMMENT ON COLUMN DB_LOG_ENTRY_TYPES.ENTRY_TYPE_ID IS 'Primary Key for the DB_LOG_ENTRY_TYPES table';

create or replace TRIGGER DB_LOG_ENTRY_TYPES_AUTO_BRI
before insert on DB_LOG_ENTRY_TYPES
for each row
begin
  select DB_LOG_ENTRY_TYPES_SEQ.nextval into :new.ENTRY_TYPE_ID from dual;
  :NEW.CREATE_DATE := SYSDATE;
  :NEW.CREATED_BY := nvl(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'),user);
end;
/
CREATE OR REPLACE TRIGGER DB_LOG_ENTRY_TYPES_AUTO_BRU BEFORE
  UPDATE
    ON DB_LOG_ENTRY_TYPES FOR EACH ROW
    BEGIN
      :NEW.LAST_MOD_DATE := SYSDATE;
      :NEW.LAST_MOD_BY := nvl(SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'),user);
END;
/


--Database Log Package Specification:
CREATE OR REPLACE PACKAGE DB_LOG_PKG
--this package provides functions and procedures to interact with the database log package module

AS

--procedure to add a database log entry into the database with the specific parameters in an autonomous transaction:
--Parameter List:
--p_entry_type_code: this is a string that defines the type of log entry, these correspond to DB_LOG_ENTRY_TYPES.ENTRY_TYPE_CODE values
--p_log_source: The application/module/script that produced the database log entry
--p_entry_content: The content of the database log entry
--p_proc_return_code: return variable to indicate the result of the database log entry attempt, it will contain 1 if the database log entry was successfully inserted into the database and 0 if it was not
--Example Usage (to enter a debugging entry):
/*
DECLARE
  P_ENTRY_TYPE_CODE VARCHAR2(200);
  P_LOG_SOURCE VARCHAR2(200);
  P_ENTRY_CONTENT CLOB;
  P_PROC_RETURN_CODE BINARY_INTEGER;
BEGIN
  P_ENTRY_TYPE_CODE := 'DEBUG';
  P_LOG_SOURCE := 'Module Name';
  P_ENTRY_CONTENT := 'Content for DB Log Entry';

  DB_LOG_PKG.ADD_LOG_ENTRY(
    P_ENTRY_TYPE_CODE => P_ENTRY_TYPE_CODE,
    P_LOG_SOURCE => P_LOG_SOURCE,
    P_ENTRY_CONTENT => P_ENTRY_CONTENT,
    P_PROC_RETURN_CODE => P_PROC_RETURN_CODE
  );
END;
*/
procedure ADD_LOG_ENTRY (p_entry_type_code IN VARCHAR2, p_log_source IN VARCHAR2, p_entry_content IN CLOB, p_proc_return_code OUT PLS_INTEGER);


END DB_LOG_PKG;
/

--Database Log Package Body:
create or replace PACKAGE BODY DB_LOG_PKG
--this package provides functions and procedures to interact with the database log package module
AS



    --procedure to add a database log entry into the database with the specific parameters in an autonomous transaction:
    --Parameter List:
    --p_entry_type_code: this is a string that defines the type of log entry, these correspond to DB_LOG_ENTRY_TYPES.ENTRY_TYPE_CODE values
    --p_log_source: The application/module/script that produced the database log entry
    --p_entry_content: The content of the database log entry
    --p_proc_return_code: return variable to indicate the result of the database log entry attempt, it will contain 1 if the database log entry was successfully inserted into the database and 0 if it was not
    --Example Usage (to enter a debugging entry):
    /*
    DECLARE
      P_ENTRY_TYPE_CODE VARCHAR2(200);
      P_LOG_SOURCE VARCHAR2(200);
      P_ENTRY_CONTENT CLOB;
      P_PROC_RETURN_CODE BINARY_INTEGER;
    BEGIN
      P_ENTRY_TYPE_CODE := 'DEBUG';
      P_LOG_SOURCE := 'Module Name';
      P_ENTRY_CONTENT := 'Content for DB Log Entry';

      DB_LOG_PKG.ADD_LOG_ENTRY(
        P_ENTRY_TYPE_CODE => P_ENTRY_TYPE_CODE,
        P_LOG_SOURCE => P_LOG_SOURCE,
        P_ENTRY_CONTENT => P_ENTRY_CONTENT,
        P_PROC_RETURN_CODE => P_PROC_RETURN_CODE
      );
    END;
    */
    PROCEDURE ADD_LOG_ENTRY (p_entry_type_code IN VARCHAR2, p_log_source IN VARCHAR2, p_entry_content IN CLOB, p_proc_return_code OUT PLS_INTEGER) IS

        --procedure variable to store the return codes from each procedure call to determine the results of the procedure execution
        v_proc_return_code PLS_INTEGER;

        --DECLARE THIS AS AN AUTONOMOUS TRANSACTION:
        PRAGMA AUTONOMOUS_TRANSACTION;


    BEGIN


        --insert the db_log_entries record based on the procedure parameters:
        INSERT INTO DB_LOG_ENTRIES (ENTRY_TYPE_ID, LOG_SOURCE, ENTRY_CONTENT, ENTRY_DTM) VALUES ((select entry_type_id from db_log_entry_types where upper(entry_type_code) = upper(p_entry_type_code)), p_log_source, p_entry_content, SYSDATE);

        --commit the DB log entry independent of any ongoing transaction
        COMMIT;

        --define the return code that indicates that the database log entry was successfully added to the database:
        p_proc_return_code := 1;


    EXCEPTION

        --catch all PL/SQL database exceptions:
        WHEN OTHERS THEN
            --catch all other errors:

            --print out error message:
            DBMS_OUTPUT.PUT_LINE('The error code is ' || SQLCODE || '- ' || SQLERRM);

            --define the return code that indicates that the database log entry was not successfully added to the database:
            p_proc_return_code := 0;


    END ADD_LOG_ENTRY;


end DB_LOG_PKG;
/


--view to return all database log entries:
create or replace view DB_LOG_ENTRIES_V
AS
select
db_log_entries.LOG_ENTRY_ID,
db_log_entry_types.ENTRY_TYPE_ID,
db_log_entry_types.ENTRY_TYPE_CODE,
db_log_entry_types.ENTRY_TYPE_NAME,
db_log_entry_types.ENTRY_TYPE_DESC,
db_log_entries.LOG_SOURCE,
db_log_entries.ENTRY_CONTENT,
db_log_entries.ENTRY_DTM,
to_char(ENTRY_DTM, 'MM/DD/YYYY HH24:MI') format_entry_dtm,
db_log_entries.CREATED_BY

from db_log_entries
inner join db_log_entry_types on
db_log_entries.entry_type_id = db_log_entry_types.entry_type_id

order by log_source, entry_dtm, LOG_ENTRY_ID
;

COMMENT ON COLUMN DB_LOG_ENTRIES_V.LOG_ENTRY_ID IS 'Primary Key for the DB_LOG_ENTRIES table';
COMMENT ON COLUMN DB_LOG_ENTRIES_V.ENTRY_TYPE_ID IS 'Foreign key reference to the DB_ENTRY_TYPES table that defines the type of database log entry';
COMMENT ON COLUMN DB_LOG_ENTRIES_V.ENTRY_TYPE_CODE IS 'The alphabetic code of the given database log entry type';
COMMENT ON COLUMN DB_LOG_ENTRIES_V.ENTRY_TYPE_NAME IS 'The name of the given database log entry type';
COMMENT ON COLUMN DB_LOG_ENTRIES_V.ENTRY_TYPE_DESC IS 'The description of the given database log entry type';
COMMENT ON COLUMN DB_LOG_ENTRIES_V.LOG_SOURCE IS 'The application/module/script that produced the database log entry';
COMMENT ON COLUMN DB_LOG_ENTRIES_V.ENTRY_CONTENT IS 'The content of the database log entry';
COMMENT ON COLUMN DB_LOG_ENTRIES_V.ENTRY_DTM IS 'The date/time the database log entry was made';
COMMENT ON COLUMN DB_LOG_ENTRIES_V.FORMAT_ENTRY_DTM IS 'The formatted date/time the database log entry was made in MM/DD/YYYY HH24:MI format';
COMMENT ON COLUMN DB_LOG_ENTRIES_V.CREATED_BY IS 'The Oracle username of the person creating this record in the database';

COMMENT ON TABLE DB_LOG_ENTRIES_V IS 'Database Log Entries (View)

This query returns all log entries stored in the DB_LOG_ENTRIES table that includes the associated DB_LOG_ENTRY_TYPES information for each log entry';


--define the upgrade version in the database upgrade log table:
INSERT INTO DB_UPGRADE_LOGS (UPGRADE_APP_NAME, UPGRADE_VERSION, UPGRADE_DATE, UPGRADE_DESC) VALUES ('Database Log', '0.1', TO_DATE('18-OCT-17', 'DD-MON-YY'), 'Initial version of the Database Logging Module.  This module has mechanisms to log information in the database independent of other ongoing SQL transactions so that the log entries are committed regardless of whether ongoing transactions are rolled back.  Created two tables to define the log entry type (DB_LOG_ENTRY_TYPES) and the actual log entries (DB_LOG_ENTRIES).  Also created a new View (DB_LOG_ENTRIES_V) to return all of the database log entries with their associated log entry types.  The DB_LOG_PKG package provides a ADD_LOG_ENTRY method to add a log entry to the database in a separate transaction so even if there is a transaction in progress and it is rolled back the database log entries will be committed immediately for debugging and error tracking purposes');
