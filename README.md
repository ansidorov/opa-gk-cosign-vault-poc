# [Proof Of Concept] Integration Open Policy Agent Gatekeeper with cosign

## Requirements

- `docker`
- `kind`
- `terraform`
- `docker-compose`
- `cosign`
- `jq`
- `kubectl`
- `git`

## Setup Docker Registry

```bash
❯ bash steps/01_docker_registry.sh
49b5aa64db6131ecc0ffcc3d53a63618902ad9132c8c56704eb1365f06b45ad7
1e2f6ba4c5117d59f1a876d1520dc5d10e28f251531e17ed2b1887639deeffa3
Docker registry runnin on 10.201.23.2
```

## Setup local Kubernetes cluster with kind

```bash
❯ bash steps/02_deploy_kind.sh
Creating cluster "kind" ...
 ✓ Ensuring node image (kindest/node:v1.21.1) 🖼
 ✓ Preparing nodes 📦 📦 📦
 ✓ Writing configuration 📜
 ✓ Starting control-plane 🕹️
 ✓ Installing CNI 🔌
 ✓ Installing StorageClass 💾
 ✓ Joining worker nodes 🚜
Set kubectl context to "kind-kind"
You can now use your cluster with:

kubectl cluster-info --context kind-kind

Have a question, bug, or feature request? Let us know! https://kind.sigs.k8s.io/#community 🙂
configmap/local-registry-hosting created
NAME                 STATUS   ROLES                  AGE   VERSION
kind-control-plane   Ready    control-plane,master   68s   v1.21.1
kind-worker          Ready    <none>                 42s   v1.21.1
kind-worker2         Ready    <none>                 42s   v1.21.1
```

## Deploy OPAA Gatekeeper to Kubernetes cluster

```bash
❯ bash steps/03_deploy_opa_gatekeeper.sh
namespace/gatekeeper-system created
resourcequota/gatekeeper-critical-pods created
customresourcedefinition.apiextensions.k8s.io/configs.config.gatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/constraintpodstatuses.status.gatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/constrainttemplatepodstatuses.status.gatekeeper.sh created
customresourcedefinition.apiextensions.k8s.io/constrainttemplates.templates.gatekeeper.sh created
serviceaccount/gatekeeper-admin created
Warning: policy/v1beta1 PodSecurityPolicy is deprecated in v1.21+, unavailable in v1.25+
podsecuritypolicy.policy/gatekeeper-admin created
role.rbac.authorization.k8s.io/gatekeeper-manager-role created
clusterrole.rbac.authorization.k8s.io/gatekeeper-manager-role created
rolebinding.rbac.authorization.k8s.io/gatekeeper-manager-rolebinding created
clusterrolebinding.rbac.authorization.k8s.io/gatekeeper-manager-rolebinding created
secret/gatekeeper-webhook-server-cert created
service/gatekeeper-webhook-service created
deployment.apps/gatekeeper-audit created
deployment.apps/gatekeeper-controller-manager created
Warning: policy/v1beta1 PodDisruptionBudget is deprecated in v1.21+, unavailable in v1.25+; use policy/v1 PodDisruptionBudget
poddisruptionbudget.policy/gatekeeper-controller-manager created
validatingwebhookconfiguration.admissionregistration.k8s.io/gatekeeper-validating-webhook-configuration created
NAME                                            READY   STATUS    RESTARTS   AGE
gatekeeper-audit-6c558d7455-q7lxs               1/1     Running   0          20s
gatekeeper-controller-manager-ff8849b64-htlf2   1/1     Running   0          20s
gatekeeper-controller-manager-ff8849b64-rsbfm   1/1     Running   0          20s
gatekeeper-controller-manager-ff8849b64-tb97h   1/1     Running   0          20s
```

## Deploy and configure HashiCorp Vault in Docker

```bash
❯ bash steps/04_deploy_hashicorp_vault.sh
d81f4f5ad47291659087ba6d6baad10ad44f231a4f363bc918299a72ed5b97c5

❯ bash steps/05_setup_hashicorp_vault.sh
Initializing the backend...
Initializing provider plugins...
- Finding latest version of hashicorp/vault...
- Installing hashicorp/vault v2.22.1...
- Installed hashicorp/vault v2.22.1 (signed by HashiCorp)
...
Apply complete! Resources: 7 added, 0 changed, 0 destroyed.

Outputs:
cosign-token = <sensitive>
```

## Deploy REST API cosignHTTPWrapper

```bash
❯ bash steps/06_deploy_api.sh
~/cosign-opa
Docker Compose is now in the Docker CLI, try `docker compose up`

Creating network "api_default" with the default driver
Creating api_api_1       ... done
Creating api_memcached_1 ... done
~/cosign-opa
```

## Copy docker images from public registry to private

```bash
❯ bash steps/07_deploy_images_to_registry.sh
20.04: Pulling from library/ubuntu
Digest: sha256:82becede498899ec668628e7cb0ad87b6e1c371cb8a1e597d83a47fac21d6af3
Status: Image is up to date for ubuntu:20.04
docker.io/library/ubuntu:20.04
The push refers to repository [localhost:5000/ubuntu]
7555a8182c42: Pushed
20.04: digest: sha256:1e48201ccc2ab83afc435394b3bf70af0fa0055215c1e26a5da9b50a1ae367c9 size: 529
1.14.2: Pulling from library/nginx
Digest: sha256:f7988fb6c02e0ce69257d9bd9cf37ae20a60f1df7563c3a2a6abe24160306b8d
Status: Image is up to date for nginx:1.14.2
docker.io/library/nginx:1.14.2
The push refers to repository [localhost:5000/nginx]
82ae01d5004e: Pushed
b8f18c3b860b: Pushed
5dacd731af1b: Pushed
1.14.2: digest: sha256:706446e9c6667c0880d5da3f39c09a6c7d2114f5a5d6b74a2fafd24ae30d2078 size: 948
1.0: Pulling from google-samples/hello-app
Digest: sha256:95214fdf834ae96b1969e38c9768f5180366fdf430e5e31b39f7defb584698fb
Status: Image is up to date for gcr.io/google-samples/hello-app:1.0
gcr.io/google-samples/hello-app:1.0
The push refers to repository [localhost:5000/hello-app]
e5589cd18adc: Pushed
72e830a4dff5: Pushed
1.0: digest: sha256:95214fdf834ae96b1969e38c9768f5180366fdf430e5e31b39f7defb584698fb size: 739
```

## Sign images with cosign

```bash
~/cosign-opa
Generate root key pair for cosign
Public key written to cosign.pub
Signing hello-app with cosign
Pushing signature to: localhost:5000/hello-app:sha256-95214fdf834ae96b1969e38c9768f5180366fdf430e5e31b39f7defb584698fb.sig
Verify hello-app image with cosign

Verification for localhost:5000/hello-app:1.0 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - The signatures were verified against the specified public key
  - Any certificates were verified against the Fulcio roots.
{"critical":{"identity":{"docker-reference":"localhost:5000/hello-app"},"image":{"docker-manifest-digest":"sha256:95214fdf834ae96b1969e38c9768f5180366fdf430e5e31b39f7defb584698fb"},"type":"cosign container image signature"},"optional":null}
error: fetching signatures: getting signature manifest: GET http://localhost:5000/v2/ubuntu/manifests/sha256-1e48201ccc2ab83afc435394b3bf70af0fa0055215c1e26a5da9b50a1ae367c9.sig: MANIFEST_UNKNOWN: manifest unknown; map[Tag:sha256-1e48201ccc2ab83afc435394b
3bf70af0fa0055215c1e26a5da9b50a1ae367c9.sig]
```

## Configure OPA Gatekeeper

```bash
❯ bash steps/09_configure_opa_gatekeeper.sh
constrainttemplate.templates.gatekeeper.sh/k8sonlysignedimages created
k8sonlysignedimages.constraints.gatekeeper.sh/signed-images created
```

## Deploy Kubernetes Deployments

```bash
❯ bash steps/10_deploy_manifests.sh
Warning: [signed-images] Deployment/nginx-deployment in test-opa namespace have unsigned image: nginx:1.14.2 for container: nginx
deployment.apps/nginx-deployment created
deployment.apps/signed-deployment created
```

## Cleanup

```bash
❯ bash steps/11_clean_all.sh
```