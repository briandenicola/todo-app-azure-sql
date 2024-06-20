SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
INFRA_PATH=$(realpath "${SCRIPT_DIR}/../infrastructure")

export RG=$(terraform -chdir=${INFRA_PATH} output -raw APP_RESOURCE_GROUP)
export APP_NAME=$(terraform -chdir=${INFRA_PATH} output -raw APP_NAME)
export ARM_WORKLOAD_APP_ID=$(terraform -chdir=${INFRA_PATH} output -raw ARM_WORKLOAD_APP_ID)
export ARM_TENANT_ID=$(terraform -chdir=${INFRA_PATH} output -raw ARM_TENANT_ID)
export MANAGED_IDENTITY_NAME=$(terraform -chdir=${INFRA_PATH} output -raw MANAGED_IDENTITY_NAME)
export SQL_SERVER_FQDN=$(terraform -chdir=${INFRA_PATH} output -raw SQL_SERVER_FQDN)
export SQL_SERVER_NAME=$(terraform -chdir=${INFRA_PATH} output -raw SQL_SERVER_NAME)