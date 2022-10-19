# rhacm-multi-kubernetes-example

## Status: Not Ready

Purpose of this repo is to demo an example of what is possible with Red Hat Advanced Cluster Management(ACM) running on OpenShift configuring other OpenShift clusters and xKS clusters.
Repo is structured as a series of steps that can be followed for a particular example.
Some steps can be skipped while others have a dependency on pre-completed steps.

## Prerequisites

- [OpenShift Cluster](https://docs.openshift.com/container-platform/4.9/welcome/index.html) - Version>=4.9
- [oc client](https://docs.openshift.com/container-platform/4.9/cli_reference/openshift_cli/getting-started-cli.html) >= 4.9
- [Red Hat ACM Policy Generator Kustomize Plugin](https://github.com/stolostron/policy-generator-plugin)
- [Red Hat Advanced Cluster Management - ACM](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.0/html-single/install/index#installing) - Version>=2.5
- [ACM MultiClusterHub must be created with Pull Secret Option](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html/install/installing#custom-image-pull-secret)
- [User running commands must have subscription-admin privilege](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#granting-subscription-admin-privilege)

## Steps to Run

### Create Kubernetes Clusters if Required

If you would like to use ACM to create clusters here is some tooling to help

**OCP Clusters**  
[For standard OCP clusters use ACM Cluster creation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/multicluster_engine/index#creating-a-cluster)

**xKS Clusters - Ansible**  
For xKS clusters you can use Ansible. Here's an example link below.
[Use Ansible to create xKS clusters](https://github.com/nleiva/ansible-kubernetes).
Link does not show integration between ACM and Ansible(AAP) for cluster creation - TODO

[**xKS Clusters - Crossplane**](https://github.com/MoOyeg/rhacm-multi-kubernetes-example#crossplane-provisioning)  
Use crossplane to create your clusters - [see crossplane section below](https://github.com/MoOyeg/rhacm-multi-kubernetes-example#crossplane-provisioning)

### Cluster Configuration

**Apply our Base Configuration Policies via ACM**  
This will create a namespace on every cluster that will serve as a base for any policies we wish to apply:

```bash
oc apply -k ./policy-global-namespace
```

A list of Placementrules we can pre-create to allow other policies leverage. PlacementRules are used as selectors to determine which clusters a policy should be applied to.

```bash
oc apply -k ./placementrules/
```

### Base xKS Policies

This will policy will install [Operator Lifecyle Manager](https://olm.operatorframework.io/) on every xKS cluster added into ACM:

```bash
kustomize build ./xks-general-policies/ --enable-alpha-plugins | oc create -f -
```

### Base ACM Hub Policies

This will policy will install some policies we are likely to need for later steps.

- Installs a policy for Red Hat ACS Helm Repo
- Installs a policy for Nginx Helm Repo
- Installs a policy for Ansible Automation Operator

`kustomize build ./hub-policies --enable-alpha-plugins | oc create -f -`

## Operator Installs

### Install GitOps,Pipelines on OCP

`kustomize build ./ocp-policies --enable-alpha-plugins | oc create -f -`

``kustomize build ./xks-argocd/ --enable-alpha-plugins | oc create -f -`

## Install ACS Central

oc apply -k ./acs-operator-central-gitops

## Deploy an Application

This Pacman App deployment will show a High Availibility use case.

## Crossplane Provisioning

Repo also contains examples of using crossplane for Provisoning with ACM installing.

### Install Crossplane

Policy will install crossplane from crossplane helm repo. Policy will also create included providers for aws,azure,gcp:

```bash
kustomize build --enable-alpha-plugins ./crossplane/ | oc create -f -
```

We need to setup credentials for our providers:

**[AWS Provider](https://crossplane.io/docs/v1.9/cloud-providers/aws/aws-provider.html)**:

**_Sample_**

```bash
export BASE64ENCODED_AWS_ACCOUNT_CREDS=$(echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $aws_profile)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $aws_profile)" | base64  | tr -d "\n")
```

```bash
cat ./crossplane/crossplane-providerconfig-templates/aws_provider.yaml | envsubst | oc apply -f -
```

**[Azure Provider](https://github.com/crossplane-contrib/provider-azure/blob/master/examples/azure-provider.yaml)**:

**_Sample_**  
After running 'az login' capture serviceprincipaljson file, will be a different name in your environment.

```bash
export provider_json_file='/root/.azure/osServicePrincipal.json'
```

```bash
export BASE64ENCODED_AZURE_PROVIDER_CREDS=$(base64 ${provider_json_file} | tr -d "\n")
```

```bash
cat ./crossplane/crossplane-providerconfig-templates/azure_provider.yaml | envsubst | oc apply -f -
```

**[GCP Provider](https://github.com/crossplane-contrib/provider-gcp)**:
TODO

### Create Resources required for specific xKS Cluster

Create required resources for your specific cloud provider.

**EKS Cluster**: Edit the ./crossplane-resources/aws/manifests folder as required for your own situation.A tested minimal example is provided.  
Create ACM application for AWS Resources:

```bash
oc apply -k ./crossplane/crossplane-resources/aws/acm-app/
```

## Attach Subscription Admin Policy to your user if necessary

```bash
sed -e "s/<user>/kube:admin/" ./pacman-app/deploy/policy/policy-subscription-pacman-admin.yaml | oc create -f - -n global-policies
```
