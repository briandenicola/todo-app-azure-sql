# Overview 

A Managed Identity is an Azure AD Service Principal (aka App Registration) in which the credentials are managed by Azure AD instead of being statically defined.  A Identity is assoicated with a resource (Virtual Machine or a Pod inside AKS) and then assigned roles to other Azure resources (like Key Vault or Azure SQL)

This repo has example code to show how to leverage these Identities. All examples leverage an identity to authenticate to Azure Key Vault to for a TLS certificate and to authenticate to a simple Azure SQL Todo databasde.

All infrastructure is configured with Terraform and the Code is written in C#.

* The [Managed Identity Example](#managed-identity-example) is a simple example using Azure AD Managed Identity associated with an Azure VM.
* The [Pod Identity Example](#pod-identity-example) is an example using Azure AD Managed Identity with [AKS Pod Identity](https://docs.microsoft.com/en-us/azure/aks/use-azure-ad-pod-identity) which is still supported but considered legacy inside AKS
* The [Workload Identity Example](#workload-identity-example) is an example using Azure AD Managed Identity with [AKS Workload Identity](https://azure.github.io/azure-workload-identity/docs/introduction.html) which is in preview (as of 4/26/22) but is the direction forward for identities in AKS

# Managed Identity Example
## Infrastructure Setup
```bash
cd managed-identities/infrastructure
terraform init
terraform apply
```

## SQL Setup
```sql
CREATE USER [${MSI_IDENTITY}] FROM EXTERNAL PROVIDER
ALTER ROLE db_datareader ADD MEMBER [${MSI_IDENTITY}]
ALTER ROLE db_datawriter ADD MEMBER [${MSI_IDENTITY}]
CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);
```

## Run API
```bash
sh scripts/publish.sh
scp managed-identities/src/publish/linux/todoapi manager@${vm-pip}:/tmp/
ssh manager@${vm-pip}
/tmp/todoapi --keyvault ${vault_name} --sqlserver ${db_name}
```

# Pod Identity Example
## Infrastructure Setup
```bash
cd pod-identities/infrastructure
terraform init
terraform apply
./scripts/pod-identity.sh --cluster-name ${aks_cluster_name} -n default -i ${managed_identity_name}
```
### Notes
* The cluster name and managed identity name will be known after terraform creates the resources in Azure.
* The managed identity name should be in the form of ${aks_cluster_name}-default-identity
    * For example: jackal-59934-aks-default-identity

## SQL Setup
```sql
CREATE USER [${MSI_IDENTITY_NAME}] FROM EXTERNAL PROVIDER
ALTER ROLE db_datareader ADD MEMBER [${MSI_IDENTITY_NAME}]
ALTER ROLE db_datawriter ADD MEMBER [${MSI_IDENTITY_NAME}]
CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);
```

## Deploy API
```bash
cd pod-identities/src
docker build -t ${existing_docker_repo}/todoapi:1.0 .
docker push ${existing_docker_repo}/todoapi:1.0
cd pod-identities/chart
helm upgrade -i podid . --set "COMMIT_VERSION=1.0" --set "ACR_NAME=${existing_docker_repo}" --set "APP_NAME=${app_name_from_terraform}" --set "MSI_SELECTOR=${managed_identity_name}"
```

# Workload Identity Example
## Prerequisties 
* azure-cli -- version >= 2.40 (Required for `az identity federated-credential` command )
* az feature register --name EnableWorkloadIdentityPreview --namespace Microsoft.ContainerService
* az feature register --name EnableOIDCIssuerPreview --namespace Microsoft.ContainerService
* az feature list --namespace Microsoft.ContainerService -o table | grep -i Registering
* az provider register --namespace Microsoft.ContainerService

## Infrastructure Setup
```bash
cd workload-identities/infrastructure
terraform init
terraform apply
```

## SQL Setup
```sql
CREATE USER [${AZURE_AD_SPN}] FROM EXTERNAL PROVIDER
ALTER ROLE db_datareader ADD MEMBER [${MSI_IDENTITY_NAME}]
ALTER ROLE db_datawriter ADD MEMBER [${MSI_IDENTITY_NAME}]
CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);
```

## Deploy API
```bash
cd workload-identities/src
docker build -t ${existing_docker_repo}/todoapi:1.0 .
docker push ${existing_docker_repo}/todoapi:1.0
cd workload-identities/chart
helm upgrade -i wki . --set "COMMIT_VERSION=1.0" --set "ACR_NAME=existing_docker_repo" --set "APP_NAME=${app_name_from_terraform}" --set "ARM_WORKLOAD_APP_ID=${managed_identity_client_id} --set "ARM_TENANT_ID=${azure_ad_tenant_id}"
```

# Testing
## Virtual Machine 
```bash
ssh manager@${vm-pip}
curl -kv -X POST https://localhost:8443/api/todo/ -d '{"Id": 123456, "Name": "Take out trash"}' -H "Content-Type: application/json"
curl -kv -X POST https://localhost:8443/api/todo/ -d '{"Id": 7891011, "Name": "Clean your bathroom"}' -H "Content-Type: application/json"
curl -kv https://localhost:8443/api/todo/123456
curl -kv https://localhost:8443/api/todo/
```
## AKS
```bash
kubectl run --restart=Never --rm -it --image=bjd145/utils:2.2 utils
kubectl exec -it utils -- bash
curl -kv -X POST https://todoapi-svc:8443/api/todo/ -d '{"Id": 123456, "Name": "Take out trash"}' -H "Content-Type: application/json"
curl -kv -X POST https://todoapi-svc:8443/api/todo/ -d '{"Id": 7891011, "Name": "Clean your bathroom"}' -H "Content-Type: application/json"
curl -kv https://todoapi-svc:8443/api/todo/123456
curl -kv https://todoapi-svc:8443/api/todo/
```

# Reference 
* https://github.com/davidfowl/Todos/tree/master/TodoWithDI
