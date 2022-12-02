#!/bin/bash

source 0-config.env

[[ -z "${CONFIG_DIRECTORY}" ]] && CONFIG_DIRECTORY="config/"
SENSOR_BASE_DIR="${CONFIG_DIRECTORY}base"

############################################################################################
#### FALCON SENSOR
############################################################################################

echo "#####################################"
echo "#### FALCON SENSOR: Generating config"
echo ""
echo "[*] Generating default config for Facon Sensor"

echo "> Creating config directories [${SENSOR_BASE_DIR}/falcon-sensor/daemonset/config]"
mkdir -p ${SENSOR_BASE_DIR}/falcon-sensor/daemonset/config

echo "[*] Generating \"${SENSOR_BASE_DIR}/falcon-sensor/daemonset/config/falcon.env\""
cat <<EOF > "${SENSOR_BASE_DIR}/falcon-sensor/daemonset/config/falcon.env"
# Put here the target cid including the checksum
# Format: XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX-YY
FALCONCTL_OPT_CID=$FALCON_CID

# Tags
#FALCONCTL_OPT_TAGS="tag1,tag2"

# Proxy
#FALCONCTL_OPT_APD=false
#FALCONCTL_OPT_APH=proxy_hostname
#FALCONCTL_OPT_APP=3128
EOF



############################################################################################
#### KUBERNETES PROTECTION AGENT
############################################################################################
echo ""
echo "####################################################"
echo "#### KUBERNETES PROTECTION AGENT : Generating config"
echo ""
echo "[*] Generating default config and secrets for Falcon Kubernetes Protection"
BASE_KPA_DIR="${CONFIG_DIRECTORY}base/falcon-kubernetes-protection-agent"

echo "> Creating secrets and config directories in ${BASE_KPA_DIR}"
mkdir -p ${BASE_KPA_DIR}/{secrets,config}

#
#kubectl create secret docker-registry --dry-run=client kpagent-cs-k8s-protection-agent-regsecret \
#  --docker-server="registry.crowdstrike.com" \
#  --docker-username="kp-22222222222222222222222222222222-11" \
#  --docker-password="dockerAPITokenA" \
#  --docker-email="kubernetes-protection@crowdstrike.com" -o yaml > "${BASE_KPA_DIR}/docker-secret.yaml"

echo "> Get an OAuth Token on CrowdStrike api [server: ${FALCON_CLOUD_API}]"
FALCON_API_BEARER_TOKEN=$(curl \
--silent \
--header "Content-Type: application/x-www-form-urlencoded" \
--data "client_id=${FALCON_CLIENT_ID}&client_secret=${FALCON_CLIENT_SECRET}" \
--request POST \
--url "https://$FALCON_CLOUD_API/oauth2/token" | \
python3 -c "import sys, json; print(json.load(sys.stdin)['access_token'])"
)
kpa_config=$(curl -sL -X GET "https://${FALCON_CLOUD_API}/kubernetes-protection/entities/integration/agent/v1?cluster_name=default_cluster&is_self_managed_cluster=true" \
  -H "Accept: application/yaml" \
  -H "Authorization: Bearer ${FALCON_API_BEARER_TOKEN}")

echo "> Extracting Kubernetes Protection Agent config from API"
kpa_registry_login="kp-$(echo "${kpa_config}" | awk '/cid:/ {print $2}' )"
kpa_registry_password=$(echo "${kpa_config}" | awk '/dockerAPIToken:/ {print $2}'  )
kpa_registry_creds_base64=$( echo -n "${kpa_registry_login}:${kpa_registry_password}" | base64 -w 0 )

echo "[*] Generating \"${BASE_KPA_DIR}/secrets/.dockerconfigjson\""
cat <<EOF > "${BASE_KPA_DIR}/secrets/.dockerconfigjson"
{
  "auths": {
    "registry.crowdstrike.com": {
      "username": "${kpa_registry_login}",
      "password": "${kpa_registry_password}",
      "email": "kubernetes-protection@crowdstrike.com",
      "auth": "${kpa_registry_creds_base64}"
    }
  }
}
EOF

echo "[*] Generating \"${BASE_KPA_DIR}/secrets/api-secret.env\""
cat <<EOF > "${BASE_KPA_DIR}/secrets/api-secret.env"
# Put here your KPA Agent API SECRET
AGENT_CLIENT_SECRET="${FALCON_K8S_PROTECTION_AGENT_API_SECRET}"
EOF

echo "[*] Generating \"${BASE_KPA_DIR}/config/api-client-id.env\""
cat <<EOF > "${BASE_KPA_DIR}/config/api-client-id.env"
# Put here your KPA Agent API CLIENT ID
AGENT_CLIENT_ID=${FALCON_K8S_PROTECTION_AGENT_API_ID}
EOF