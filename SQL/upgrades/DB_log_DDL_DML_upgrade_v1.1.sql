--------------------------------------------------------
--------------------------------------------------------
--Database Name: Database Log
--Database Description: This module was created to log information in the database for various backend operations.  This is preferable to a file-based log since it can be easily queried, filtered, searched, and used for reporting purposes
--------------------------------------------------------
--------------------------------------------------------


--------------------------------------------------------
--Database Log - version 1.1 updates:
--------------------------------------------------------

-- increase the size of the created/modified by fields
ALTER TABLE DB_LOG_ENTRIES  
MODIFY (CREATED_BY VARCHAR2(128 BYTE) );

-- increase the size of the created/modified by fields
ALTER TABLE DB_LOG_ENTRY_TYPES  
MODIFY (CREATED_BY VARCHAR2(128 BYTE) );
ALTER TABLE DB_LOG_ENTRY_TYPES
MODIFY (LAST_MOD_BY VARCHAR2(128 BYTE) );

-- recompile the dependent views
ALTER VIEW DB_LOG_ENTRIES_V COMPILE;

--redefine the triggers to use flexible auditing field values
create or replace TRIGGER DB_LOG_ENTRIES_AUTO_BRI
before insert on DB_LOG_ENTRIES
for each row
begin
  select DB_LOG_ENTRIES_SEQ.nextval into :new.LOG_ENTRY_ID from dual;
  :NEW.CREATED_BY := SUBSTR(
            COALESCE(
                SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'),
                SYS_CONTEXT('USERENV', 'OS_USER'),
                SYS_CONTEXT('USERENV', 'SESSION_USER')
            ), 1, 128);
end;
/

create or replace TRIGGER DB_LOG_ENTRY_TYPES_AUTO_BRI
before insert on DB_LOG_ENTRY_TYPES
for each row
begin
  select DB_LOG_ENTRY_TYPES_SEQ.nextval into :new.ENTRY_TYPE_ID from dual;
  :NEW.CREATE_DATE := SYSDATE;
  :NEW.CREATED_BY := SUBSTR(
            COALESCE(
                SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'),
                SYS_CONTEXT('USERENV', 'OS_USER'),
                SYS_CONTEXT('USERENV', 'SESSION_USER')
            ), 1, 128);
end;
/

CREATE OR REPLACE TRIGGER DB_LOG_ENTRY_TYPES_AUTO_BRU BEFORE
  UPDATE
    ON DB_LOG_ENTRY_TYPES FOR EACH ROW
    BEGIN
      :NEW.LAST_MOD_DATE := SYSDATE;
      :NEW.LAST_MOD_BY := SUBSTR(
            COALESCE(
                SYS_CONTEXT('USERENV', 'CLIENT_IDENTIFIER'),
                SYS_CONTEXT('USERENV', 'OS_USER'),
                SYS_CONTEXT('USERENV', 'SESSION_USER')
            ), 1, 128);
END;
/

--define the upgrade version in the database upgrade log table:
INSERT INTO DB_UPGRADE_LOGS (UPGRADE_APP_NAME, UPGRADE_VERSION, UPGRADE_DATE, UPGRADE_DESC) VALUES ('Database Log', '1.1', TO_DATE('03-AUG-26', 'DD-MON-YY'), 'Updated the auditing text fields to increase the size to 128 characters. Updated triggers to use the client identifier, OS user, and session user when available (in order of precedence)');
