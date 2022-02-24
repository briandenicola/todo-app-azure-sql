# Overview 

Example code to show how to use Azure User Assign Manage Identities with Azure SQL

# Infrastructure Setup
* cd ./infrastructure
* terraform init
* terraform plan 
* terraform apply

# SQL Setup
* CREATE USER [${MSI_IDENTITY}] FROM EXTERNAL PROVIDER
* ALTER ROLE db_datareader ADD MEMBER [${MSI_IDENTITY}]
* ALTER ROLE db_datawriter ADD MEMBER [${MSI_IDENTITY}]
* CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);

# Run API
* cd src
* dotnet run --keyvault ${vault_name} --sqlserver ${db_name}

# Test
* curl -kv -X POST https://localhost:8443/api/todo/ -d '{"Id": 123456, "Name": "Take out trash"}' -H "Content-Type: application/json"
* curl -kv -X POST https://localhost:8443/api/todo/ -d '{"Id": 7891011, "Name": "Clean your bathroom"}' -H "Content-Type: application/json"
* curl -kv https://localhost:8443/api/todo/123456
* curl -kv https://localhost:8443/api/todo/

# Reference 
* https://github.com/davidfowl/Todos/tree/master/TodoWithDI