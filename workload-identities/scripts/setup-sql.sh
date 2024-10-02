#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -h|--help)
      echo "Usage: ./set-sql.sh 
      "
      exit 0
      ;;
    --) 
      shift
      break
      ;;
    -*|--*=) 
      echo "Error: Unsupported flag $1" >&2
      exit 1
      ;;
  esac
done

source $(dirname $0)/setup-env.sh

SQL_AUTH_METHOD=ActiveDirectoryAzCli
SQL_DB_NAME=todo

export OBJECT_ID=`az ad signed-in-user show -o tsv --query id`
export AZURE_USERNAME=`az ad signed-in-user show -o tsv --query userPrincipalName`
echo "Setting ${AZURE_USERNAME} as the default Entra ID Admin for ${SQL_SERVER_NAME} . . ."
az sql server ad-admin update --display-name ${AZURE_USERNAME}  --object-id ${OBJECT_ID} --resource-group $RG --server ${SQL_SERVER_NAME}

echo "Creating user ${MANAGED_IDENTITY_NAME} in ${SQL_SERVER_NAME} with db_datareader and db_datawriter roles . . ."
sqlcmd --authentication-method=${SQL_AUTH_METHOD} -U ${AZURE_USERNAME} -S ${SQL_SERVER_FQDN} -d ${SQL_DB_NAME} --query "CREATE USER [${MANAGED_IDENTITY_NAME}] FROM EXTERNAL PROVIDER;" 
sqlcmd --authentication-method=${SQL_AUTH_METHOD} -U ${AZURE_USERNAME} -S ${SQL_SERVER_FQDN} -d ${SQL_DB_NAME} --query "ALTER ROLE db_datareader ADD MEMBER [${MANAGED_IDENTITY_NAME}];"
sqlcmd --authentication-method=${SQL_AUTH_METHOD} -U ${AZURE_USERNAME} -S ${SQL_SERVER_FQDN} -d ${SQL_DB_NAME} --query "ALTER ROLE db_datawriter ADD MEMBER [${MANAGED_IDENTITY_NAME}]" 

echo "Creating Todos table and inserting a record . . ."
sqlcmd --authentication-method=${SQL_AUTH_METHOD} -U ${AZURE_USERNAME} -S ${SQL_SERVER_FQDN} -d ${SQL_DB_NAME} --query "CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);"
sqlcmd --authentication-method=${SQL_AUTH_METHOD} -U ${AZURE_USERNAME} -S ${SQL_SERVER_FQDN} -d ${SQL_DB_NAME} --query "INSERT INTO todos VALUES ( 9999, 'Learn about Azure', 0);"
sqlcmd --authentication-method=${SQL_AUTH_METHOD} -U ${AZURE_USERNAME} -S ${SQL_SERVER_FQDN} -d ${SQL_DB_NAME} --query "SELECT * FROM todos;"
