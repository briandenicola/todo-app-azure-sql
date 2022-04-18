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

OIDC_FEATURE_ENABLED=`az aks show --resource-group ${CLUSTER_RG} --name ${CLUSTER_NAME} --query "oidcIssuerProfile.enabled" -o tsv`
if [ ${OIDC_FEATURE_ENABLED} == "false" ]; then
  echo OIDC Feature NOT enabled... Updating Cluster to enable.
  az aks update -g ${CLUSTER_RG} -n ${CLUSTER_NAME} --enable-oidc-issuer
fi
   
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