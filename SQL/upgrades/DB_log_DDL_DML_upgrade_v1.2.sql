--------------------------------------------------------
--------------------------------------------------------
--Database Name: Database Log
--Database Description: This module was created to log information in the database for various backend operations.  This is preferable to a file-based log since it can be easily queried, filtered, searched, and used for reporting purposes
--------------------------------------------------------
--------------------------------------------------------


--------------------------------------------------------
--Database Log - version 1.2 updates:
--------------------------------------------------------

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

	--procedure to add a database log entry into the database with the specific parameters in an autonomous transaction:
	--Parameter List:
	--p_entry_type_code: this is a string that defines the type of log entry, these correspond to DB_LOG_ENTRY_TYPES.ENTRY_TYPE_CODE values
	--p_log_source: The application/module/script that produced the database log entry
	--p_entry_content: The content of the database log entry
	--Example Usage (to enter a debugging entry):
	/*
	DECLARE
	  P_ENTRY_TYPE_CODE VARCHAR2(200);
	  P_LOG_SOURCE VARCHAR2(200);
	  P_ENTRY_CONTENT CLOB;
	BEGIN
	  P_ENTRY_TYPE_CODE := 'DEBUG';
	  P_LOG_SOURCE := 'Module Name';
	  P_ENTRY_CONTENT := 'Content for DB Log Entry';

	  DB_LOG_PKG.ADD_LOG_ENTRY(
		P_ENTRY_TYPE_CODE => P_ENTRY_TYPE_CODE,
		P_LOG_SOURCE => P_LOG_SOURCE,
		P_ENTRY_CONTENT => P_ENTRY_CONTENT
	  );
	END;
	*/
	procedure ADD_LOG_ENTRY (p_entry_type_code IN VARCHAR2, p_log_source IN VARCHAR2, p_entry_content IN CLOB);

END DB_LOG_PKG;
/

--Database Log Package Body:
create or replace PACKAGE BODY DB_LOG_PKG
--this package provides functions and procedures to interact with the database log package module
AS

	--package string variable to store the production status of the logging module, this determines if debug messages will be logged (FALSE) or not (TRUE)
	PV_PROD_STATUS BOOLEAN;
	
	--package variable to store the DLM configuration for the system status
	PV_DLM_SYSTEM_STATUS VARCHAR2(500);


	--procedure to add a database log entry into the database with the specific parameters in an autonomous transaction:
	--Parameter List:
	--p_entry_type_code: this is a string that defines the type of log entry, these correspond to DB_LOG_ENTRY_TYPES.ENTRY_TYPE_CODE values
	--p_log_source: The application/module/script that produced the database log entry
	--p_entry_content: The content of the database log entry
	--p_proc_return_code: return variable to indicate the result of the database log entry attempt, it will contain 1 if the database log entry was successfully inserted into the database and 0 if it was not
	PROCEDURE ADD_LOG_ENTRY (p_entry_type_code IN VARCHAR2, p_log_source IN VARCHAR2, p_entry_content IN CLOB, p_proc_return_code OUT PLS_INTEGER) IS

		--procedure variable to store the return codes from each procedure call to determine the results of the procedure execution
		v_proc_return_code PLS_INTEGER;

		--DECLARE THIS AS AN AUTONOMOUS TRANSACTION:
		PRAGMA AUTONOMOUS_TRANSACTION;

	BEGIN

		--check the production status, if it's not in production status then log the message, if it is in production status and it's not a debugging message then log the message:
		IF ((NOT PV_PROD_STATUS) OR (PV_PROD_STATUS AND UPPER(p_entry_type_code) <> 'DEBUG')) THEN
			--insert the db_log_entries record based on the procedure parameters:
			INSERT INTO DB_LOG_ENTRIES (ENTRY_TYPE_ID, LOG_SOURCE, ENTRY_CONTENT, ENTRY_DTM) VALUES ((select entry_type_id from db_log_entry_types where upper(entry_type_code) = upper(p_entry_type_code)), p_log_source, p_entry_content, SYSDATE);

			--commit the DB log entry independent of any ongoing transaction
			COMMIT;
		END IF;
		
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

			-- raise the exception
			RAISE;

	END ADD_LOG_ENTRY;


	--procedure to add a database log entry into the database with the specific parameters in an autonomous transaction:
	--Parameter List:
	--p_entry_type_code: this is a string that defines the type of log entry, these correspond to DB_LOG_ENTRY_TYPES.ENTRY_TYPE_CODE values
	--p_log_source: The application/module/script that produced the database log entry
	--p_entry_content: The content of the database log entry
	PROCEDURE ADD_LOG_ENTRY (p_entry_type_code IN VARCHAR2, p_log_source IN VARCHAR2, p_entry_content IN CLOB) IS

		--procedure variable to store the return codes from each procedure call to determine the results of the procedure execution
		v_proc_return_code PLS_INTEGER;

	BEGIN

		--call the ADD_LOG_ENTRY procedure
		ADD_LOG_ENTRY (p_entry_type_code, p_log_source, p_entry_content, v_proc_return_code);

	EXCEPTION
	
		--catch all PL/SQL database exceptions:
		WHEN OTHERS THEN
			--catch all other errors:

			--log the processing error:
			ADD_LOG_ENTRY ('ERROR', p_log_source, SQLERRM, v_proc_return_code);
			
			RAISE;

	END ADD_LOG_ENTRY;
	
	--package initialization
	BEGIN
	
		--check if the CC_CONFIG_OPTIONS table exists, if so attempt to retrieve the configuration variable from the DB:
		SELECT OPTION_VALUE INTO PV_DLM_SYSTEM_STATUS FROM CC_CONFIG_OPTIONS WHERE UPPER(OPTION_NAME) = UPPER('DLM_SYSTEM_STATUS');
		
		--check the value of the production status configuration option value
		IF (UPPER(PV_DLM_SYSTEM_STATUS) = 'PROD') THEN 
			--the production configuration is enabled
			PV_PROD_STATUS := TRUE;
			
		ELSE
			--the production configuration is NOT enabled
			PV_PROD_STATUS := FALSE;

		END IF;
			
	EXCEPTION
		WHEN OTHERS THEN
			--the configuration table doesn't exist or the PROD_STATUS configuration value is not defined.  Default to non-production status
			PV_PROD_STATUS := FALSE;
end DB_LOG_PKG;
/

--define the upgrade version in the database upgrade log table:
INSERT INTO DB_UPGRADE_LOGS (UPGRADE_APP_NAME, UPGRADE_VERSION, UPGRADE_DATE, UPGRADE_DESC) VALUES ('Database Log', '1.2', TO_DATE('06-OCT-26', 'DD-MON-YY'), 'Improved exception handling to alert developers when the DB_LOG_PKG causes PL/SQL code to fail');
