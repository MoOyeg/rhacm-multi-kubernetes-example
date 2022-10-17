# rhacm-multi-kubernetes-example
# Status: Not Ready

Purpose of this repo is to demo an example of what is possible with Red Hat Advanced Cluster Management running on OpenShift configuring other OpenShift clusters and xKS clusters.
Repo is structured as a series of steps that can be followed for a particular example.
Some steps can be skipped while others have a dependency on pre-completed steps.

## Pre-Requisites

- OpenShift Cluster - Version>=4.9
- [Red Hat Advanced Cluster Management - ACM](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.0/html-single/install/index#installing) - Version>=2.5
- [ACM MultiClusterHub must be created with Pull Secret Option](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html/install/installing#custom-image-pull-secret)
- [User running commands must have subscription-admin privilege](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#granting-subscription-admin-privilege)

## Base Steps

### Base Policies

This will create a namespace on every cluster that will serve as a base for any policies we wish to apply:  

oc apply -k ./policy-global-namespace/

A list of Placementrules we can pre-create to allow other polcies leverage:  

oc apply -k ./placementrules/

### Base xKS Policies  

This will create a namespace on every cluster that will serve as a base for any policies we wish to apply:  

kustomize build ./xks-general-policies/ --enable-alpha-plugins | oc create -f -

kustomize build ./hub-policies --enable-alpha-plugins | oc create -f -

## Operator Installs

### Install GitOps,Pipelines on OCP

kustomize build ./ocp-policies --enable-alpha-plugins | oc create -f -

kustomize build ./xks-argocd/ --enable-alpha-plugins | oc create -f -

## Install ACS Central

oc apply -k ./acs-operator-central-gitops

## Deploy an Application

This Pacman App deployment will show a High Availibility use case of

### Attach Subscription Policy to your user if necessary

example

```bash
sed -e "s/<user>/kube:admin/" ./pacman-app/deploy/policy/policy-subscription-pacman-admin.yaml | oc create -f - -n global-policies
```

oc apply -k ./pacman-app/deploy
