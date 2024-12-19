#!/bin/bash

while (( "$#" )); do
  case "$1" in
    -n|--acr-name)
      ACR=$2
      shift 2
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

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
source ${SCRIPT_DIR}/setup-env.sh

ACR_RG=`az acr list --query "[?name=='${ACR}']" | jq -r ".[].resourceGroup"`

ROLE_ID="7f951dda-4ed3-4680-a7ca-43fe172d538d"
SUBSCRIPTION_ID=$(az account show -o tsv --query id)
SCOPE_ID="/subscriptions/${SUBSCRIPTION_ID}/resourcegroups/${ACR_RG}/providers/Microsoft.ContainerRegistry/registries/${ACR}"
PRINCIPAL_ID=$(az ad sp list --all --filter "displayName eq '${AKS_NODE_POOL_IDENTITY}' and servicePrincipalType eq 'ManagedIdentity'" -o tsv --query "[].id")

echo "Update ${ACR} network rule to add ${AKS_OUTBOUND_IP} to allow list . . ."
az acr network-rule add -n ${ACR} --ip-address ${AKS_OUTBOUND_IP}

echo "Add AcrPull role to ${AKS_NODE_POOL_IDENTITY} (${PRINCIPAL_ID}) on ${ACR} . . ."
az role assignment create --assignee ${PRINCIPAL_ID} --role ${ROLE_ID} --scope ${SCOPE_ID}
