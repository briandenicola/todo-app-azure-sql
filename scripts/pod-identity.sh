#!/bin/bash

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
    -i|--identity)
      IDENTITY_NAME=$2
      shift 2
      ;;

    -h|--help)
      echo "Usage: ./pod-identity.sh --cluster-name --namespace
        Overview: This script will federate an Azure AD SPN with a Kubernetes Service Account
        --cluster-name(c) - The AKS cluster where this identity will be used
        --namespace(n)    - The Kuberentes namespace where this identity will be used
        --identity(i)     - The managed identity used by this application
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
RESOURCEID=`az identity list --query "[?name=='${IDENTITY_NAME}']" | jq -r ".[].id"`

az aks pod-identity add --resource-group ${CLUSTER_RG} --cluster-name ${CLUSTER_NAME} --namespace ${NAMESPACE} --name ${IDENTITY_NAME} --identity-resource-id ${RESOURCEID}