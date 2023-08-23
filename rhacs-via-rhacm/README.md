# Install RHACS automagically using RHACM

This repository leverages the RHACM policy mechanism to install and configure RHACS seamlessly.

A RHACM policy is a Kubernetes resource of kind *Policy* (in the *policy.open-cluster-management.io/v1* API group).
It is applied to a set of target clusters using a *PlacementBinding* (in the same API group) and a *PlacementRule* (in the *apps.open-cluster-management.io/v1* API group):

* the *PlacementRule* specifies the list of target clusters
* the *PlacementBinding* binds a *Policy* with a *PlacementRule*

> A common pattern is to target the same cluster as the one where RHACM is installed, called the "local-cluster"

## Prerequisites

* an OCP 4 cluster
* RHACM installed on this cluster (managed clusters can be added at anytime)

## Usage

Using a user with *cluster-admin* role connected to the cluster.

### Create the *PlacementRules*

*PlacementRules* are used to target the "local cluster" (where the RHACM hub is installed and where the RHACS central will be installed) on one side and the managed clusters (where the RHACS *SecuredClusters* will be created) on the other side.

```shell
oc create namespace rhacs-operator # because placement rule are bound to a namespace, we need to create "rhacs-operator" before RHACS setup
oc apply -f rhacs-via-rhacm/placement-rules/local-cluster.yaml
oc apply -f rhacs-via-rhacm/placement-rules/managed-clusters.yaml
```

> *PlacementRules* are created once and for all and reused in *PlacementBindings*

### Install RHACS

```shell
oc apply -f rhacs-via-rhacm/policies/rhacs-operator-and-central
```

### Configure the RHACS service account

```shell
oc apply -f rhacs-via-rhacm/policies/rhacs-bootstrap-serviceaccount
```

### Create a *Build* to create the image with the RHACS bootstrap script

```shell
oc apply -f rhacs-via-rhacm/policies/rhacs-bootstrap-job-image
```

> Wait for the image to be built (check with ```oc get -n rhacs-operator imagestreamtag rhacs-bootstrapper-job-image:latest```)

### Create a bootstrap job to create the RHACS init bundle

```shell
oc apply -f rhacs-via-rhacm/policies/rhacs-bootstrap-job
```

### Propagate certificates created in managed clusters

```shell
oc apply -f rhacs-via-rhacm/policies/rhacs-secrets
```

### Create a SecuredCluster in RHACS

```shell
oc apply -f rhacs-via-rhacm/policies/rhacs-secured-cluster
```

## Tear down

To clean up the cluster where RHACM is installed:

* First delete all policies:
```shell
find rhacs-via-rhacm/policies -name "*.yml" -exec oc delete -f {} \;
```

* Then, uninstall RHACS:
```shell
oc patch -n rhacs-operator central stackrox-central-services -p '{"metadata": {"finalizers": null}}' --type merge
oc delete namespace rhacs-operator
oc get clusterrole,clusterrolebinding,role,rolebinding -o name | grep stackrox | xargs oc delete --wait
oc delete scc -l "app.kubernetes.io/name=stackrox"
oc delete ValidatingWebhookConfiguration stackrox
for namespace in $(oc get ns | tail -n +2 | awk '{print $1}'); do     oc label namespace $namespace namespace.metadata.stackrox.io/id-;     oc label namespace $namespace namespace.metadata.stackrox.io/name-;     oc annotate namespace $namespace modified-by.stackrox.io/namespace-label-patcher-;   done
```

> Based on https://access.redhat.com/documentation/fr-fr/red_hat_advanced_cluster_security_for_kubernetes/4.1/html/installing/uninstall-acs

To clean up the managed clusters:
```shell
oc patch -n rhacs-operator securedcluster stackrox-secured-cluster-services -p '{"metadata": {"finalizers": null}}' --type merge
oc delete namespace rhacs-operator
```