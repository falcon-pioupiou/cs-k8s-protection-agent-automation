# Full manifest generation with Kustomize

Requirements:
- helm
- kubectl
- curl
## Configuration

Open the `0-config.env` file and configure each parameters

## Generate all files

To generate all files from the configuration defined in `0-config.env`, run the command :
```
make
```

## Deployment

Once all of your templates/overlays/configs are ready, you can generate the manifest with Kustomize for a specific cluster.

For cluster : k8s-us-cluster-1:
```bash
kustomize build config/overlays/k8s-us-cluster-1/falcon-kubernetes-protection-agent
kustomize build config/overlays/k8s-us-cluster-1/falcon-sensor
```

For cluster : openshift-us-cluster-1:
```bash
kustomize build config/overlays/openshift-us-cluster-1/falcon-kubernetes-protection-agent
kustomize build config/overlays/openshift-us-cluster-1/falcon-sensor
```

---

# Detailed explanation

## Configuration

Open the `0-config.env` file and configure each parameters

## Generating manifests and configs

Once your `0-config.env` file is ready, you can run this command to generate everything.
```bash
make
```

## Template Generation

Done via the script `1-generate_base_template.sh` 
This script is generating manifests from the Helm charts with some parameters :
- without hooking ( `--no-hooks` ) 
- for Openshift manifest ( `--api-versions "security.openshift.io/v1"` )

## Overlays Generation

Done via the script `2-generate_overlays.sh` 

This script is reading file `target_openshift_clusters.txt` and `target_k8s_clusters.txt` to create all directories for each cluster listed in these files.


## Configs Generation

Done via the script `3-generate_configs.sh` 

This script is generating the default/base config files:
- config/base/falcon-sensor/daemonset/config/falcon.env
    Default CID
    Default Tags
    Default Proxy
- config/base/falcon-kubernetes-protection/secrets/.dockerconfigjson
    Secret to pull Kubernetes Protection Agent from CrowdStrike Registry
- config/base/falcon-kubernetes-protection/secrets/api-secret.env
    API Client Secret for the Kubernetes Protection Agent to send data to CS Cloud
- config/base/falcon-kubernetes-protection/config/api-client-id.env
    API Client ID for the Kubernetes Protection Agent to send data to CS Cloud
