#!/bin/bash

[[ -z "${CONFIG_DIRECTORY}" ]] && CONFIG_DIRECTORY="config/"
mkdir -p ${CONFIG_DIRECTORY}base


# TODO Check if helm is present

helm repo add crowdstrike https://crowdstrike.github.io/falcon-helm
helm repo add kpagent-helm https://registry.crowdstrike.com/kpagent-helm
helm repo update



############################################################################################
#### FALCON SENSOR
############################################################################################

SENSOR_BASE_DIR="${CONFIG_DIRECTORY}base"

# Generate templates for Falcon-sensor
mkdir -p ${SENSOR_BASE_DIR}/falcon-sensor/{daemonset,daemonset-openshift} # ,-sidecar,-sidecar-aks}"

# Falcon-Sensor-DaemonSet
helm template --no-hooks \
    --set falcon.cid="22222222222222222222222222222222-11" \
    --set node.image.repository="<Your_Registry>/falcon-node-sensor" \
    crowdstrike crowdstrike/falcon-sensor > ${SENSOR_BASE_DIR}/falcon-sensor/daemonset/daemonset.yaml

cat <<EOF > ${SENSOR_BASE_DIR}/falcon-sensor/daemonset/namespace.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: falcon-system
EOF

cat <<EOF > ${SENSOR_BASE_DIR}/falcon-sensor/daemonset/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: falcon-system

resources:
- namespace.yaml
- daemonset.yaml

configMapGenerator:
- name: crowdstrike-falcon-sensor-config
  behavior: merge
  envs:
  - config/falcon.env

patches:
# Delete test cluster-role and test cluster-role binding 
#- path: delete-test-clusterrole.yaml
#- path: delete-test-clusterrole-binding.yaml
# Default image for all clusters
- patch: |-
    - op: add
      path: /spec/template/spec/containers/0/image
      value: YOUR_REGISTRY/falcon-sensor:YOUR_IMAGE_TAG
    - op: add
      path: /spec/template/spec/initContainers/0/image
      value: YOUR_REGISTRY/falcon-sensor:YOUR_IMAGE_TAG
  target:
    kind: DaemonSet
EOF


#########
# Delete test cluster-role and test cluster-role binding
#cat <<EOF > ${SENSOR_BASE_DIR}/falcon-sensor/daemonset/delete-test-clusterrole.yaml
#\$patch: delete
#apiVersion: rbac.authorization.k8s.io/v1
#kind: ClusterRole
#metadata:
#  name: crowdstrike-falcon-sensor-test-access-role
#EOF

#cat <<EOF > ${SENSOR_BASE_DIR}/falcon-sensor/daemonset/delete-test-clusterrole-binding.yaml
#\$patch: delete
#apiVersion: rbac.authorization.k8s.io/v1
#kind: ClusterRoleBinding
#metadata:
#  name: crowdstrike-falcon-sensor-test-access-binding
#EOF


#########
# Openshift Template

## Generate Cluster Role
helm template --api-versions "security.openshift.io/v1" --no-hooks \
    --set falcon.cid="22222222222222222222222222222222-11" \
    --set node.image.repository="<Your_Registry>/falcon-node-sensor" \
    -s templates/clusterrole.yaml \
    crowdstrike crowdstrike/falcon-sensor > ${SENSOR_BASE_DIR}/falcon-sensor/daemonset-openshift/clusterrole.yaml

## Generate SecurityContextConstraint
#helm template --api-versions "security.openshift.io/v1" --no-hooks \
#    --set falcon.cid="22222222222222222222222222222222-11" \
#    --set node.image.repository="<Your_Registry>/falcon-node-sensor" \
#    -s templates/node_scc.yaml \
#    crowdstrike crowdstrike/falcon-sensor > ${SENSOR_BASE_DIR}/falcon-sensor/daemonset-openshift/node_scc.yaml

cat <<EOF > ${SENSOR_BASE_DIR}/falcon-sensor/daemonset-openshift/kustomization.yaml
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: falcon-system

resources:
- ../daemonset
#- node_scc.yaml

patches:
- path: clusterrole.yaml
EOF


############################################################################################
#### KUBERNETES PROTECTION AGENT
############################################################################################

BASE_KPA_DIR="${CONFIG_DIRECTORY}base/falcon-kubernetes-protection-agent"

# Generate templates For Kubernetes-Protection
mkdir -p ${BASE_KPA_DIR}

# cid is only the value WITHOUT the checksum and in lowercase
helm template --no-hooks --create-namespace -n falcon-kubernetes-protection \
    --set crowdstrikeConfig.clientID="FALCON_K8S_PROTECTION_AGENT_API_ID" \
    --set crowdstrikeConfig.clientSecret="FALCON_K8S_PROTECTION_AGENT_API_SECRET" \
    --set crowdstrikeConfig.clusterName="MY-CLUSTER" \
    --set crowdstrikeConfig.env="FALCON_CLOUD" \
    --set crowdstrikeConfig.cid="22222222222222222222222222222222" \
    --set crowdstrikeConfig.dockerAPIToken="dockerAPIToken" \
    -s templates/serviceaccount.yaml \
    -s templates/configmap.yaml \
    -s templates/cluster-role-read-access.yaml \
    -s templates/cluster-role-read-access-binding.yaml \
    -s templates/deployment.yaml \
    kpagent kpagent-helm/cs-k8s-protection-agent > "${BASE_KPA_DIR}/kubernetes-protection.yaml"

cat <<EOF > "${BASE_KPA_DIR}/namespace.yaml"
apiVersion: v1
kind: Namespace
metadata:
  name: falcon-kubernetes-protection
EOF

cat <<EOF > "${BASE_KPA_DIR}/kustomization.yaml"
apiVersion: kustomize.config.k8s.io/v1beta1
kind: Kustomization

namespace: falcon-kubernetes-protection

resources:
- namespace.yaml
- kubernetes-protection.yaml

configMapGenerator:
- name: kpagent-cs-k8s-protection-agent
  behavior: merge
  literals:
  - AGENT_CLUSTER_NAME="default-cluster-name"
  - AGENT_DEBUG="false"
  - AGENT_ENV="us-1"
- name: kpagent-cs-k8s-protection-agent
  behavior: merge
  envs:
  - config/api-client-id.env

secretGenerator:
- name: kpagent-cs-k8s-protection-agent
  envs:
  - secrets/api-secret.env
- name: kpagent-cs-k8s-protection-agent-regsecret
  files:
  - secrets/.dockerconfigjson
  type: kubernetes.io/dockerconfigjson

#patches:
# Default image for all clusters
#- patch: |-
#    - op: add
#      path: /spec/template/spec/containers/0/image
#      value: YOUR_REGISTRY/falcon-kpa:your_tag
#  target:
#    kind: Deployment

EOF
