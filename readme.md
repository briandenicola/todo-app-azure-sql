# Overview 

Example code to show how to use Azure AD Workload Identities and Azure AD Managed Identities. There are two different examples - one using a VM as client and one with a pod running in AKS.  

# Managed Identity Example
## Infrastructure Setup
* cd ./infrastructure
* terraform init
* terraform apply

## SQL Setup
* CREATE USER [${MSI_IDENTITY}] FROM EXTERNAL PROVIDER
* ALTER ROLE db_datareader ADD MEMBER [${MSI_IDENTITY}]
* ALTER ROLE db_datawriter ADD MEMBER [${MSI_IDENTITY}]
* CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);

## Run API
* ssh manager@${vm-pip}
* cd src
* dotnet run --keyvault ${vault_name} --sqlserver ${db_name}

## Test
* curl -kv -X POST https://localhost:8443/api/todo/ -d '{"Id": 123456, "Name": "Take out trash"}' -H "Content-Type: application/json"
* curl -kv -X POST https://localhost:8443/api/todo/ -d '{"Id": 7891011, "Name": "Clean your bathroom"}' -H "Content-Type: application/json"
* curl -kv https://localhost:8443/api/todo/123456
* curl -kv https://localhost:8443/api/todo/

# Workload Identity Example
## Infrastructure Setup
* cd ./infrastructure/workload-identity-example
* terraform init
* terraform apply
* ./scripts/workload-identity.sh --cluster-name ${aks_cluster_name} 

## SQL Setup
* CREATE USER [${AZURE_AD_SPN}] FROM EXTERNAL PROVIDER
* ALTER ROLE db_datareader ADD MEMBER [${AZURE_AD_SPN}]
* ALTER ROLE db_datawriter ADD MEMBER [${AZURE_AD_SPN}]
* CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);

## Run API
* cd src
* docker build -t ${docker_repo}/todoapi:1.0 .
* docker push ${docker_repo}/todoapi:1.0
* Update Helm chart
* helm upgrade -i wki .

## Test
* TBD

# Reference 
* https://github.com/davidfowl/Todos/tree/master/TodoWithDI