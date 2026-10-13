# Database Logging Module Documentation

## Overview:
There is a need for application-level logging for database applications for informational and debugging purposes that is independent of any ongoing SQL transactions. The Database Logging Module (DLM) was developed to provide a method to log entries in an Oracle database for any modules that utilize an Oracle database.  A view object is available for viewing log entries that can be filtered and searched for certain types of log entries or log entries with certain types of content based on SQL query logic.  The DLM has been provided to log the different types of information from a given module independent of SQL transactions performed by that module.

## Resources:
- Database Logging Module Version Control Information:
  -  URL: git@github.com:noaa-pifsc/PIFSC-DBLoggingModule.git
  - Database: 1.0 (Git tag: db_log_db_v1.0)
-  [Database Diagram](./data_model/DB_Log_diagram.png)
-  [Database Naming Conventions](./Database%20Logging%20Module%20DB%20Naming%20Conventions.MD)

## <a name="database_setup"></a>Database Setup:
-  ### Install the Database Version Control Module (VCM)
  - VCM Version Control Information:
    - URL: git@github.com:noaa-pifsc/PIFSC-DBVersionControlModule.git
    - Database: 1.0 (git tag: [db_vers_ctrl_db_v1.0](https://github.com/noaa-pifsc/PIFSC-DBVersionControlModule/releases/tag/db_vers_ctrl_db_v1.0))
    - SOP: 1.1 (git tag: [db_vers_ctrl_v1.1](https://github.com/noaa-pifsc/PIFSC-DBVersionControlModule/releases/tag/db_vers_ctrl_v1.1))
-  ### Install the Centralized Configuration Module (CCM)
  - CCM Version Control Information:
    - URL: git@github.com:noaa-pifsc/Centralized-Configuration.git
    - Database: 1.1 (git tag: [centralized_configuration_db_v1.1](https://github.com/noaa-pifsc/Centralized-Configuration/releases/tag/centralized_configuration_db_v1.1))
- ### [Install the DLM](./Installing%20or%20Upgrading%20the%20Database%20Logging%20Module.MD)
  - Load the DLM Log Type Records by running the [load_db_log_entry_types.sql](../SQL/scripts/load_db_log_entry_types.sql) script
  - \*Note: These Log Type Records must be loaded before the DB_LOG_PKG can be executed successfully
- ### Load the runtime configuration options
  - To set the DLM data system status configuration to allow or prevent debugging messages from being inserted in the database, insert a CC_CONFIG_OPTIONS record  with the following values:
    - OPTION_NAME: DLM_SYSTEM_STATUS
    - (for production systems) OPTION_VALUE: PROD
      - This will prevent debugging messages from being logged in the database
    - (for development or test systems) OPTION_VALUE: DEBUG
      - This will allow debugging messages from being logged in the database
    -   \*Note: the [cc_data_generator.xlsx](https://github.com/noaa-pifsc/Centralized-Configuration/blob/master/docs/cc_data_generator.xlsx) in the Centralized Configuration project can be used to generate DML INSERT statements to load data into the CC_CONFIG_OPTIONS table

## Database Design:
-  [Naming Conventions](./Database%20Logging%20Module%20DB%20Naming%20Conventions.MD)
-  Tables:
  - DB_LOG_ENTRY_TYPES: This table stores the different types of database log entries.  Entry types include informational, errors, and success
  - DB_LOG_ENTRIES: This table stores log entries for a given module to enable debugging, logging errors, etc.  This table is used in the DLM
-  Views:
  - DB_LOG_ENTRIES_V: This query returns all log entries stored in the DB_LOG_ENTRIES table that includes the associated DB_LOG_ENTRY_TYPES information for each log entry
- Packages:
  - DB_LOG_PKG: This package provides a single procedure ADD_LOG_ENTRY() that will insert a database log entry into the DB_LOG_ENTRIES table based on the parameters passed to the procedure.  This procedure commits the DB_LOG_ENTRIES record in an autonomous transaction that is independent of any ongoing SQL transactions in the given module's execution so even if the transaction is rolled back the database log entry will be inserted barring any database errors encountered when the log entry is inserted.

## Example Implementation:
- When connected to a database with the DLM installed execute the commands listed in [execute DB_LOG_PKG.sql](../SQL/scripts/execute%20DB_LOG_PKG.sql)

## Best Practices:
- When implementing the DLM on a PL/SQL procedure/function to log successful/unsuccessful actions standardize the LOG_SOURCE parameter value to include any parameters for the procedure/function call to make it easier to troubleshoot and debug the PL/SQL code.
- Log all application/database errors so they can be used for troubleshooting purposes
- Avoid excessive logging messages in production applications and PL/SQL code.  Since each logging message is stored in the database it can cause the DB_LOG_ENTRIES table to require a substantial amount of database tablespace.   
  - Debugging messages should be used to facilitate the development and troubleshooting process but the DLM procedure calls should be removed or commented out before migrating to the production platform
  - \*Note: Debugging messages can be prevented from being logged in the database by  [loading the runtime configuration option](#load-the-runtime-configuration-options) appropriately

## DB Upgrade and Rollback Testing
-   (using G:\security\DB\TEST_JDA\SQL\deploy_rollback_dev_DLM.sql):
    -   version 1.0:
        -   TEST_JDA_COMP: run SQL/deploy_dev.sql
        -   TEST_JDA: run version 0.1, 0.2, 0.3, 1.0 upgrade files
        -   verified no invalid objects
        -   verified data models are equivalent
    -   Version 0.3:
        -   TEST_JDA_COMP:
            -   run deploy_dev.sql
            -   run rollback v1.0.sql
        -   TEST_JDA: run version 0.1, 0.2, 0.3 upgrade files
        -   verified no invalid objects
        -   verified data models are equivalent
    -   Version 0.2:
        -   TEST_JDA_COMP:
            -   run deploy_dev.sql
            -   run rollback v1.0.sql
            -   run rollback v0.3.sql
        -   TEST_JDA: run version 0.1, 0.2 upgrade files
        -   verified no invalid objects
        -   verified data models are equivalent
    -   Version 0.1:
        -   TEST_JDA_COMP:
            -   run deploy_dev.sql
            -   run rollback v1.0.sql
            -   run rollback v0.3.sql
            -   run rollback v0.2.sql
        -   TEST_JDA: run version 0.1 upgrade files
        -   verified no invalid objects
        -   verified data models are equivalent
    -   Version 0.0:
        -   TEST_JDA_COMP:
            -   run SQL/deploy_dev.sql
            -   run rollback v1.0.sql
            -   run rollback v0.3.sql
            -   run rollback v0.2.sql
            -   run rollback v0.1.sql
        -   confirmed TEST_JDA_COMP schema has no objects
