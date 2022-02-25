#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -c|--cluster-name)
      CLUSTER_NAME+=($2)
      shift 2
      ;;
    -n|--namespace)
      NAMESPACE=$2
      shift 2
      ;;
    -h|--help)
      echo "Usage: ./workload-identity.sh --cluster-name --namespace
        Overview: This script will federate an Azure AD SPN with a Kubernetes Service Account
        --cluster-name(c) - The AKS cluster where this identity will be used
        --namespace(n)    - The Kuberentes namespace where this identity will be used
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

CLUSTER_DETAILS=`az aks list --query "[?name=='${CLUSTER_NAME}']"`
CLUSTER_RG=`echo ${CLUSTER_DETAILS} | jq -r ".[].resourceGroup"`
AZURE_TENANT_ID=`echo ${CLUSTER_DETAILS} | jq -r ".[].identity.tenantId"`

SERVICE_ACCOUNT_NAME=${CLUSTER_NAME}-${NAMESPACE}-identity
SERVICE_ACCOUNT_ISSUER=`az aks show --resource-group ${CLUSTER_RG} --name ${CLUSTER_NAME} --query "oidcIssuerProfile.issuerUrl" -o tsv`
APPLICATION_CLIENT_ID=`az ad sp list --display-name ${SERVICE_ACCOUNT_NAME} -o tsv --query "[0].appId"`
APPLICATION_OBJECT_ID=`az ad app show --id "${APPLICATION_CLIENT_ID}" --query objectId -o tsv`

cat <<EOF > body.json
{
  "name": "kubernetes-federated-identity",
  "issuer": "${SERVICE_ACCOUNT_ISSUER}",
  "subject": "system:serviceaccount:${NAMESPACE}:${SERVICE_ACCOUNT_NAME}",
  "description": "Kubernetes service account federated identity",
  "audiences": [
    "api://AzureADTokenExchange"
  ]
}
EOF

az rest --method POST --uri "https://graph.microsoft.com/beta/applications/${APPLICATION_OBJECT_ID}/federatedIdentityCredentials" --body @body.json
rm -rf body.json

az aks get-credentials -n ${CLUSTER_NAME} -g ${CLUSTER_RG}
helm repo add azure-workload-identity https://azure.github.io/azure-workload-identity/charts
helm repo update
helm install workload-identity-webhook azure-workload-identity/workload-identity-webhook \
   --namespace azure-workload-identity-system \
   --create-namespace \
   --set azureTenantID="${AZURE_TENANT_ID}"