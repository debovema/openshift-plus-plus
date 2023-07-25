# Install RHACS automagically using RHACM

This repository leverages the RHACM policy mechanism to install and configure RHACS seamlessly.

A RHACM policy is a Kubernetes resource of kind *Policy* in the *policy.open-cluster-management.io/v1* API group.
It is applied to a set of target clusters using a *PlacementRule* and a *PlacementBinding* (in the same API group):

* the *PlacementRule* specifies the list of target clusters
* the *PlacementBinding* binds a *Policy* with a *PlacementRule*

> A common pattern is to target the same cluster as the one where RHACM is installed, called the "local-cluster".

## Prerequisites

* OCP 4 cluster
* RHACM installed

## Usage

Using a user with *cluster-admin* role connected to the cluster.

### Install RHACS

```shell
oc apply -f rhacs-via-rhacm/policies/central-policy.yml
oc apply -f rhacs-via-rhacm/policies/central-policy-bindings.yml
```

### Configure the RHACS service account

```shell
oc apply -f rhacs-via-rhacm/policies/bootstrap/bootstrap-policy-sa.yml
oc apply -f rhacs-via-rhacm/policies/bootstrap/bootstrap-sa-placement.yml
```

### Create a bootstrap job to create the RHACS init bundle

```shell
oc apply -f rhacs-via-rhacm/policies/bootstrap-job/bootstrapper-policy.yml
oc apply -f rhacs-via-rhacm/policies/bootstrap-job/boostrapper-job-placement.yml
```

### Propagate certificates created in managed clusters

```shell
oc apply -f rhacs-via-rhacm/policies/secured-cluster/sc-policy.yml
oc apply -f rhacs-via-rhacm/policies/secured-cluster/sc-policy-binding.yml
```

### Create a SecuredCluster in RHACS

```shell
oc apply -f rhacs-via-rhacm/policies/secured-cluster-cr/sc.yml
oc apply -f rhacs-via-rhacm/policies/secured-cluster-cr/sc-binding.yml
```