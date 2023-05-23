#!/bin/bash

[[ -z "${CONFIG_DIRECTORY}" ]] && CONFIG_DIRECTORY="config/"
mkdir -p ${CONFIG_DIRECTORY}overlays

OPENSHIFT_CLUSTERS_NAME_FILE="target_openshift_clusters.txt"
OPENSHIFT_CLUSTERS_NAME_LIST=$(cat $OPENSHIFT_CLUSTERS_NAME_FILE | grep -v "\#" )
K8S_CLUSTERS_NAME_FILE="target_k8s_clusters.txt"
K8S_CLUSTERS_NAME_LIST=$(cat $K8S_CLUSTERS_NAME_FILE | grep -v "\#" )

# Create all Falcon-sensor directories
xargs -I {} mkdir -p "config/overlays/{}/falcon-sensor" < $OPENSHIFT_CLUSTERS_NAME_FILE
xargs -I {} mkdir -p "config/overlays/{}/falcon-sensor" < $K8S_CLUSTERS_NAME_FILE

# Create all Falcon-Kubernetes-protection directories
xargs -I {} mkdir -p "config/overlays/{}/falcon-kubernetes-protection-agent" < $OPENSHIFT_CLUSTERS_NAME_FILE
xargs -I {} mkdir -p "config/overlays/{}/falcon-kubernetes-protection-agent" < $K8S_CLUSTERS_NAME_FILE


####################################################################################
# K8S CLUSTERS
####################################################################################
for cluster in $K8S_CLUSTERS_NAME_LIST
do

  # Create the Falcon-sensor config
  cat << EOF > "config/overlays/$cluster/falcon-sensor/kustomization.yaml"
resources:
- ../../../base/falcon-sensor/daemonset

# Uncomment if you want to change the image ONLY for $cluster
# patches:
#- patch: |-
#    - op: add
#      path: /spec/template/spec/containers/0/image
#      value: mytest:6.45
#    - op: add
#      path: /spec/template/spec/initContainers/0/image
#      value: mytest:6.45
#  target:
#    labelSelector: "app.kubernetes.io/name=falcon-sensor"
#    kind: DaemonSet

# Specify CID for this cluster $cluster
#configMapGenerator:
#- name: crowdstrike-falcon-sensor-config
#  behavior: merge
#  literals:
#  - FALCONCTL_OPT_CID=33333333333333333333333333333333-99
EOF

  # Create the Falcon Kubernetes Protection config
  cat << EOF > "config/overlays/$cluster/falcon-kubernetes-protection-agent/kustomization.yaml"
resources:
- ../../../base/falcon-kubernetes-protection-agent

configMapGenerator:
- name: kpagent-cs-k8s-protection-agent
  behavior: merge
  literals:
  - AGENT_CLUSTER_NAME="$cluster"
EOF


done


####################################################################################
# OPENSHIFT CLUSTERS
####################################################################################
for cluster in $OPENSHIFT_CLUSTERS_NAME_LIST
do

  # Create the Falcon-sensor config
  cat << EOF > "config/overlays/$cluster/falcon-sensor/kustomization.yaml"
resources:
- ../../../base/falcon-sensor/daemonset-openshift

# Uncomment if you want to change the image ONLY for $cluster
# patches:
#- patch: |-
#    - op: add
#      path: /spec/template/spec/containers/0/image
#      value: mytest:6.45
#    - op: add
#      path: /spec/template/spec/initContainers/0/image
#      value: mytest:6.45
#  target:
#    labelSelector: "app.kubernetes.io/name=falcon-sensor"
#    kind: DaemonSet

# Specify CID for this cluster $cluster
#configMapGenerator:
#- name: crowdstrike-falcon-sensor-config
#  behavior: merge
#  literals:
#  - FALCONCTL_OPT_CID=33333333333333333333333333333333-99
EOF

  # Create the Falcon Kubernetes Protection config
  cat << EOF > "config/overlays/$cluster/falcon-kubernetes-protection-agent/kustomization.yaml"
resources:
- ../../../base/falcon-kubernetes-protection-agent

configMapGenerator:
- name: kpagent-cs-k8s-protection-agent
  behavior: merge
  literals:
  - AGENT_CLUSTER_NAME="$cluster"
EOF


done
