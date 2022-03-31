# Overview 

Example code to show how to use Azure AD Workload Identities and Azure AD Managed Identities. There are two different examples - one using a VM as client and one with a pod running in AKS.  

[[toc]]

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

## Test
```bash
curl -kv -X POST https://localhost:8443/api/todo/ -d '{"Id": 123456, "Name": "Take out trash"}' -H "Content-Type: application/json"
curl -kv -X POST https://localhost:8443/api/todo/ -d '{"Id": 7891011, "Name": "Clean your bathroom"}' -H "Content-Type: application/json"
curl -kv https://localhost:8443/api/todo/123456
curl -kv https://localhost:8443/api/todo/
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
* CREATE USER [${MSI_IDENTITY_NAME}] FROM EXTERNAL PROVIDER
* ALTER ROLE db_datareader ADD MEMBER [${MSI_IDENTITY_NAME}]
* ALTER ROLE db_datawriter ADD MEMBER [${MSI_IDENTITY_NAME}]
* CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);
```

### Example:
```sql
    CREATE USER [jackal-59934-aks-default-identity] FROM EXTERNAL PROVIDER
    ALTER ROLE db_datareader ADD MEMBER [jackal-59934-aks-default-identity]
    ALTER ROLE db_datawriter ADD MEMBER [jackal-59934-aks-default-identity]
    CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);
```

### Notes:
* Add AKS's outbound IP Address to the Azure SQL Firewall which can be found in the AKS Node Resource Group

## Deploy API
```bash
cd pod-identities/src
docker build -t ${existing_docker_repo}/todoapi:1.0 .
docker push ${existing_docker_repo}/todoapi:1.0
cd pod-identities/chart
helm upgrade -i podid . --set "COMMIT_VERSION=1.0' --set "ACR_NAME=${existing_docker_repo}" --set "APP_NAME=${app_name_from_terraform}" --set "MSI_SELECTOR=${managed_identity_name}
```
## Test
```bash
kubectl run --restart=Never --rm -it --image=bjd145/utils:2.2 utils
kubectl exec -it utils -- bash
curl -kv -X POST https://todoapi-svc:8443/api/todo/ -d '{"Id": 123456, "Name": "Take out trash"}' -H "Content-Type: application/json"
curl -kv -X POST https://todoapi-svc:8443/api/todo/ -d '{"Id": 7891011, "Name": "Clean your bathroom"}' -H "Content-Type: application/json"
curl -kv https://todoapi-svc:8443/api/todo/123456
curl -kv https://todoapi-svc:8443/api/todo/
```

# Workload Identity Example
## Infrastructure Setup
```bash
cd workload-identities/infrastructure
terraform init
terraform apply
az aks get-credentials -n ${CLUSTER_NAME} -g ${CLUSTER_RG}
helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts
helm repo update
helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook \
   --namespace azure-workload-identity-system \
   --create-namespace \
   --set azureTenantID="${AZURE_TENANT_ID}"
./scripts/workload-identity.sh --cluster-name ${aks_cluster_name} 
```

## SQL Setup
```sql
CREATE USER [${AZURE_AD_SPN}] FROM EXTERNAL PROVIDER
ALTER ROLE db_datareader ADD MEMBER [${AZURE_AD_SPN}]
ALTER ROLE db_datawriter ADD MEMBER [${AZURE_AD_SPN}]
CREATE TABLE dbo.Todos ( [Id] INT PRIMARY KEY, [Name] VARCHAR(250) NOT NULL, [IsComplete] BIT);
```
### Notes
* Add AKS's outbound IP Address to the Azure SQL Firewall which can be found in the AKS Node Resource Group

## Deploy API
```bash
cd workload-identities/src
docker build -t ${existing_docker_repo}/todoapi:1.0 .
docker push ${existing_docker_repo}/todoapi:1.0
cd workload-identities/chart
helm upgrade -i wki . --set "COMMIT_VERSION=1.0' --set "ACR_NAME=existing_docker_repo" --set "APP_NAME=${app_name_from_terraform}" --set "ARM_WORKLOAD_APP_ID=${workload_app_id} --set "ARM_TENANT_ID=${azure_ad_tenant_id}"
```

## Test
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