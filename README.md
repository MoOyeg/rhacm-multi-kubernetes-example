# rhacm-multi-kubernetes-example

Purpose of this repo is to demo an example of what is possible with Red Hat Advanced Cluster Management(ACM) running on OpenShift configuring other OpenShift clusters and xKS clusters.
Repo is structured as a series of steps that can be followed for a particular example.
Some steps can be skipped while others have a dependency on pre-completed steps.

## Contents

- [Use Red Hat Advanced Cluster Security(ACS) to secure xKS clusters installed via ACM](#red-hat-advanced-cluster-securityrhacs)
- [Use Crossplane with ACM to provision xKS Clusters](#crossplane-provisioning)
- [Ancillary Provisoning: ACM+Crossplane can be used to implement the AWS Load Balancer Controller add-on](#crossplane-aws-lb-controller-addon)
- [Ancillary Provisoning: ACM can be used to deploy the Nginx Ingress Controller on xKS Clusters](#nginx-ingress-controller)
- [Certificate Management with cert-manager](#cert-manager-example)

## General Prerequisites

- [OpenShift Cluster](https://docs.openshift.com/container-platform/4.9/welcome/index.html) - Version>=4.9
- [oc client](https://docs.openshift.com/container-platform/4.9/cli_reference/openshift_cli/getting-started-cli.html) >= 4.9
- [Red Hat ACM Policy Generator Kustomize Plugin](https://github.com/stolostron/policy-generator-plugin)
- [Red Hat Advanced Cluster Management - ACM](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.0/html-single/install/index#installing) - Version>=2.5
- [User running commands must have subscription-admin privilege](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#granting-subscription-admin-privilege).
  - [Sample Solution](https://access.redhat.com/solutions/6010251)
  - [CLI Example](https://github.com/MoOyeg/rhacm-multi-kubernetes-example#attach-subscription-admin-policy-to-your-user-if-necessary)
- [If creating xKS clusters you must add your custom pull secret to ACM multiclusterhub object](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html/install/installing#custom-image-pull-secret)

## Steps to Run

### Create Kubernetes Clusters if Required

If you would like to use ACM to create clusters here is some tooling to help

**OCP Clusters**

- [For standard OCP clusters use ACM Cluster creation](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/multicluster_engine/index#creating-a-cluster)

**xKS Clusters - Ansible**

- For xKS clusters you can use Ansible. Here's an example link below.
  [Use Ansible to create xKS clusters](https://github.com/nleiva/ansible-kubernetes).
  Link does not show integration between ACM and Ansible(AAP) for cluster creation - TODO

**xKS Clusters - Crossplane**

- Use crossplane to create your clusters - [see crossplane section below](#crossplane-provisioning)

## Basic Cluster Configuration

Cluster configuration that will serve as the base for our ACM Policies and all our other examples.

### Apply our Base Configuration Policies via ACM

- Create a namespace to host our ACM policies.

  ```bash
  oc new-project global-policies
  ```

- Create the ManagedClusterSetBinding

  ```bash
  oc create -f ./managedclustersetbinding.yaml
  ```

- Attach subscription-admin role to the user that requested the global-policies namespace above.
  ```bash
  oc adm policy add-cluster-role-to-user open-cluster-management:subscription-admin $(oc whoami)
  ```

- Create an ACM Policy that does the following.

  - Create our global-policies namesapce in every Kubernetes Cluster
  - Create List Of PlacementRules we want ACM to use from the placmentrules folder and can be leveraged by other policies. PlacementRules are used as selectors to determine which clusters a policy should be applied to.Might need to run this command twice to allow the previous policy to be enforced..

  You can create the ACM policy via a pre-generated yaml:

  ```bash
  oc create -f ./policy-global-base/generated-policy.yaml
  ```

  OR

  You can edit the files in the [folders](./policy-global-base) and generate your own policy and then create:

  ```bash
  kustomize build ./policy-global-base --enable-alpha-plugins | oc create -f -
  ```

## Install Operator Framework on xKS

With OLM provided we can run operators from operatorhub.io on xKS clusters.

### Operator Framework Steps Prerequisites

- Run [Basic Cluster Configuration](#basic-cluster-configuration) steps from above.
- [User running commands must have subscription-admin privilege](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#granting-subscription-admin-privilege). [Sample Solution](https://access.redhat.com/solutions/6010251)

### Install OLM on xKS Clusters

This will policy will install [Operator Lifecyle Manager](https://olm.operatorframework.io/) on every xKS cluster added into ACM:

- Install OLM via the pre-generated yaml

  ```bash
  oc create -f ./xks-policies/xks-olm/generated-policy.yaml
  ```

OR

- Generate your own policy and then create

  ```bash
  kustomize build ./xks-policies/xks-olm/ --enable-alpha-plugins | oc create -f -
  ```

## Crossplane Provisioning

Repo contains examples of using crossplane with ACM.

### What example does repo provide?

- ACM will install crossplane from crossplane helm repo.
- ACM will also create crossplane providers for aws,azure,gcp.
- ACM will also use crossplane to create xKS clusters(non-composition).
- ACM will also attempt to import created clusters into ACM for management
- Running steps in reverse should also delete/detach objects in ACM and Cloud Provider

### Crossplane Provisioning Steps Prerequisites

- Run [Basic Cluster Configuration](#basic-cluster-configuration) steps from above.
- [User running commands must have subscription-admin privilege](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#granting-subscription-admin-privilege). [Sample Solution](https://access.redhat.com/solutions/6010251)

### Steps

**1 Run ACM Policies and Applications to create repo and install crossplane. Make sure to run prerequisites above first.**

- Create via the pre-generated yaml

  ```bash
  oc create -f ./crossplane/generated-policy.yaml
  ```

OR

- Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./crossplane/ | oc create -f -
  ```

**2 When Crossplane is installed and crossplane providers created. We need to create credentials for respective cloud providers that crossplane can use to access the cloudprovider API.**

**_[Setup AWS Provider](https://crossplane.io/docs/v1.9/cloud-providers/aws/aws-provider.html)_**:

**_*Sample Setup*_**

```bash
export aws_profile=...
```

```bash
export BASE64ENCODED_AWS_ACCOUNT_CREDS=$(echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $aws_profile)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $aws_profile)" | base64  | tr -d "\n")
```

Create AWS ProviderConfig

```bash
cat ./crossplane/crossplane-providerconfig-templates/aws_provider.yaml | envsubst | oc apply -f -
```

**_[Setup Azure Provider](https://github.com/crossplane-contrib/provider-azure/blob/master/examples/azure-provider.yaml)_**:

**_*Sample Setup*_**

- If you already have your credentials/service principal/resourcegroup you can export them as variables.

  ```bash
  export CLIENT_ID=""
  export PASSWORD=""
  export TENANT=""
  export SUBSCRIPTION=""
  export RESOURCEGROUP=""
  ```

  ```bash
  export BASE64ENCODED_AZURE_PROVIDER_CREDS=$(cat ./crossplane/crossplane-providerconfig-templates/azure_credentials.json | envsubst | base64 | tr -d "\n")

  ```

  OR  
   If you dont have created credentials, follow ProviderConfig [steps](https://github.com/crossplane/crossplane/blob/master/docs/cloud-providers/azure/azure-provider.md)

- With your credentials from step above create your Azure ProviderConfig

  ```bash
  cat ./crossplane/crossplane-providerconfig-templates/azure_provider.yaml | envsubst | oc apply -f -
  ```

**_[Setup GCP Provider](https://github.com/crossplane-contrib/provider-gcp)_**:  
 **_*Sample Setup*_**

TODO

**3 Create Crossplane Resources required for specific xKS Cluster. See Samples for Provider Resources and Clusters below.**

**_EKS Cluster Sample_**

Edit the [aws resources manifests](./crossplane/crossplane-resources/aws/manifests) folder as required for your own situation.A tested minimal example is provided.

- Use ACM application to create AWS Resources:

  ```bash
  oc apply -k ./crossplane/crossplane-resources/aws/acm-app/
  ```

- Use ACM application to create xKS Clusters.This will provision all the defined xKS clusters so if you are creating other xks clusters you might want to run the resources commands like above for those clouds.To edit which clusters you want created, edit the [kustomization.yaml](./crossplane/crossplane-clusters/acm-app/kustomization.yaml).  
  **_Please note there seems to be a bug where the cluster application appears blank.Application still works,will file a bug._**

  ```bash
  oc apply -k ./crossplane/crossplane-clusters/acm-app/
  ```

- To create new clusters make copies of the eks-cluster-1 sample under `./crossplane/crossplane-clusters/acm-app/` and crossplane-eks-cluster1 under eks-cluster-overlays.

**AKS Cluster Sample**

Edit the [azure resources manifests](./crossplane/crossplane-resources/azure/manifests) folder as required for your own situation.A tested minimal example is provided.

- Example provided does not create resourcegroup, and hardcodes the value of the resourcegroupname

- To replace the hardcoded value of resourcegroupname with your pre-created resourgroup.

  ```bash
  grep -rli 'resourcegroup-replaceme' * | grep yaml | xargs -i@ sed -i 's/resourcegroup-replaceme/'${RESOURCEGROUP}'/g' @
  ```

  OR

- If you do not have a pre-created resourgreoup, and would like the resourcegroup to be created as part of the list of objects.

  Run Utility script to update manifests or update manifests manually

  ```bash
   ./crossplane/crossplane-utlility-scripts/switch-azure-create-rg.sh ${RESOURCEGROUP}
  ```

- Use ACM application to create Azure Resources:

  ```bash
  oc apply -k ./crossplane/crossplane-resources/azure/acm-app/
  ```

- Use ACM application to create xKS Clusters.This will provision all the defined xKS clusters.To edit which clusters you want created, edit the [kustomization.yaml](./crossplane/crossplane-clusters/acm-app/kustomization.yaml).  
  **_Please note there seems to be a bug where the cluster application appears blank.Application still works,will file a bug._**

  ```bash
  oc apply -k ./crossplane/crossplane-clusters/acm-app/
  ```

**GKE Cluster Sample**  
TODO

## Crossplane AWS LB Controller Addon

Leveraging crossplane and Red Hat Advanced Cluster Management we can also do ancillary provisioning steps like creating an EKS Ingress Controller.

### Crossplane AWS LB Controller Addon Prerequisites

- Run [Basic Cluster Configuration](#basic-cluster-configuration) steps from above.
- [User running commands must have subscription-admin privilege](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#granting-subscription-admin-privilege). [Sample Solution](https://access.redhat.com/solutions/6010251)
- Example provided here only works with clusters provisioned via [Crossplane Provisioning example in this repo](#crossplane-provisioning).
- VPC Subnets used by EKS Ingress Controller must be tagged with certain tags. Example [Subnet Files](./crossplane/crossplane-resources/aws/manifests/overlays/region-us-east-1/patches/patch-subnet1.yaml) are tagged for eks-cluster-1 sample. Kindly update if yours are different.
- The sample provided is for eks-cluster-1, you can make a copy of the overlay.

### Crossplane AWS LB Controller Addon Steps

- Use ACM/Crossplane to create the IAM Role Permission Policy and Helm EKS Charts Repo.Make sure created ACM policy object is compliant before next steps.  
   Create via the pre-generated yaml

  ```bash
  oc create -f ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/global/generated-policy.yaml
  ```

  OR

  Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/global/ | oc create -f -
  ```

- Use ACM/Crossplane to create the OpenID Provider in AWS.Make sure created ACM policy object is compliant before next steps.

  ```bash
  oc apply -k ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/overlays/eks-cluster-1/oidc/
  ```

- Use ACM/Crossplane to create the AWS LoadBalancer Control Role and attach our previously created IAM permission policy.Make sure created ACM policy object is compliant before next steps.

  ```bash
  oc apply -k ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/overlays/eks-cluster-1/role/
  ```

- Use ACM/Crossplane to create the AWS LoadBalancer ServiceAccount on EKS-Clusters.

  ```bash
  oc apply -k ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/overlays/eks-cluster-1/sa/
  ```

- Use ACM subscription to install helm eks ingress-controller application.

  ```bash
  oc apply -k ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/overlays/eks-cluster-1/subscription/
  ```

- OPTIONAL: Use ACM to deploy AWS Sample Ingress Application.

  ```bash
  oc apply -k ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/overlays/eks-cluster-1/aws-sample-app/
  ```

- OPTIONAL: Verify Sample APP URL.Please note it might take a few minutes for the url of the sample nlb to become resolvable/accessible.

  ```bash
  mkdir /tmp/kubeconfig && oc extract secret/eks-cluster-1 -n crossplane-system --keys=kubeconfig --to=/tmp/kubeconfig && oc get svc/nlb-sample-service -n nlb-sample-app -o jsonpath='{.status.loadBalancer.ingress[0].hostname}' --kubeconfig /tmp/kubeconfig/kubeconfig
  ```

## Nginx Ingress Controller

Leveraging Red Hat Advanced Cluster Management we can also do ancillary provisioning steps like creating an Nginx Ingress Controller on our xKS Clusters.

### Nginx Ingress Controller Prerequisites

- Run [Install Operator Framework on xKS](#install-operator-framework-on-xks) steps.
- Run [Basic Cluster Configuration](#basic-cluster-configuration) steps.
- [User running commands must have subscription-admin privilege](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#granting-subscription-admin-privilege). [Sample Solution](https://access.redhat.com/solutions/6010251)

### Nginx Ingress Controller Steps

- Use ACM to create Helm Nginx Charts Repo.Make sure created ACM policy object is compliant before next steps.  
   Create via the pre-generated yaml

  ```bash
  oc create -f ./xks-policies/policy-xks-nginx-ingresscontroller/global-generator/generated-policy.yaml
  ```

  OR

  Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./xks-policies/policy-xks-nginx-ingresscontroller/global-generator | oc create -f -
  ```

- Use ACM to to install Nginx IngressController Chart on EKS.Make sure created ACM policy object is compliant before next steps.  
   Create via the pre-generated yaml

  ```bash
  oc create -f ./xks-policies/policy-xks-nginx-ingresscontroller/eks-overlay-generator/generated-policy.yaml
  ```

  OR

  Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./xks-policies/policy-xks-nginx-ingresscontroller/eks-overlay-generator/ | oc create -f -
  ```

- Use ACM to to install Nginx IngressController Chart on AKS.Make sure created ACM policy object is compliant before next steps.  
   Create via the pre-generated yaml

  ```bash
  oc create -f ./xks-policies/policy-xks-nginx-ingresscontroller/aks-overlay-generator/generated-policy.yaml
  ```

  OR

  Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./xks-policies/policy-xks-nginx-ingresscontroller/aks-overlay-generator/ | oc create -f -
  ```

## Red Hat Advanced Cluster Security(RHACS)

Repo provides an example of using ACM to install Red Hat Advanced Cluster Security on OCP Clusters and on xKS Clusters.

### What example does repo provide?

- ACM will install ACS Operator on OCP Clusters
- ACM will install ACS Central on OCP Hub
- ACM will install ACS SecuredCluster on OCP Clusters
- ACM will install ACS SecuredCluster via Helm on xKS Clusters

### Red Hat Advanced Cluster Security Prerequisites

- Run [Basic Cluster Configuration](#basic-cluster-configuration) steps from above.
- [User running commands must have subscription-admin privilege](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#granting-subscription-admin-privilege). [Sample Solution](https://access.redhat.com/solutions/6010251)

### Steps

**1 Create Placementrules we will leverage for ACS Policies. Make sure to run prerequisites above first.**

```bash
oc apply -k ./acs/acs-placementrules/
```

**2 Create ACS Operator installation policy for all OpenShift Clusters.**

- Create via the pre-generated yaml

  ```bash
  oc create -f ./acs/acs-operator/generated-policy.yaml
  ```

OR

- Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./acs/acs-operator | oc create -f -
  ```

**3 Create ACS Central policy for only hub Openshift Cluster.**

- Create via the pre-generated yaml

  ```bash
  oc create -f ./acs/acs-central/generated-policy.yaml
  ```

OR

- Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./acs/acs-central | oc create -f -
  ```

**4 Create ACS SecuredClusters Policy for Openshift Clusters.**

- Create via the pre-generated yaml

  ```bash
  oc create -f ./acs/acs-ocp-operator-secured-instance/generated-policy.yaml
  ```

OR

- Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./acs/acs-ocp-operator-secured-instance | oc create -f -
  ```

**5 Create Image Secret Pull Policy to allow ACS Pods pull required images.**

- Create policy to allow ACS pods access pull-secret

  ```bash
  oc create -f ./acs/acs-xks-helm-secured-instance/policy-pullsecret.yaml
  ```

**6 Create ACS SecuredClusters Policy for xKS Clusters.**  
Policy presently creates a job which then creates an ACM helm securedcluster application for each xks managedcluster.You can add new xks clusters by deleting the job and allowing ACM recreate it.  
TODO: Research a way to accomplish without using a Job.

- Create via the pre-generated yaml

  ```bash
  oc create -f ./acs/acs-xks-helm-secured-instance/generated-policy.yaml
  ```

OR

- Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./acs/acs-xks-helm-secured-instance/ | oc create -f -
  ```

## cert-manager-example

Example provided uses cert-manager with ACME and Route53 so requires AWS Credentials.

### cert-manager-example Prerequisites

- Run [Basic Cluster Configuration](#basic-cluster-configuration) steps from above.
- [User running commands must have subscription-admin privilege](https://access.redhat.com/documentation/en-us/red_hat_advanced_cluster_management_for_kubernetes/2.6/html-single/applications/index#granting-subscription-admin-privilege). [Sample Solution](https://access.redhat.com/solutions/6010251)

- Use ACM to to install the Cert-Manager Operator On OpenShift.Example presently uses Tech-Preview Version, update manifest if GA.

  Create via the pre-generated yaml

  ```bash
  oc create -f ./cert-manager/ocp-cert-manager-operator/generated-policy.yaml
  ```

  OR

  Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./cert-manager/ocp-cert-manager-operator | oc create -f -
  ```

- Use ACM to to install Cert-Manager Operator On xKS. You can change between the community and Red Hat supported versions in [Policy Generator](./cert-manager/ocp-cert-manager-operator/policygenerator.yaml)

  Create via the pre-generated yaml.

  ```bash
  oc create -f ./cert-manager/xks-cert-manager/cert-manager-operator/generated-policy.yaml
  ```

  OR

  Generate your own policy and then create

  ```bash
  kustomize build --enable-alpha-plugins ./cert-manager/xks-cert-manager/cert-manager-operator/ | oc create -f -
  ```

- Use ACM to create ACME ClusterIssuer(LetsEncrypt).Step will use your LetsEncypt email address to create Acme ClusterIssuer.

  ```bash
  export EMAIL_ADDRESS=<ACME_EMAIL_ADDRESS>
  ```

  Create via the pre-generated yaml.

  ```bash
  cat ./cert-manager/ocp-cert-manager-acme-ca/generated-policy.yaml | envsubst | oc create -f -
  ```
  
  OR

  Generate your own policy and then create.

  ```bash
  kustomize build --enable-alpha-plugins ./cert-manager/ocp-cert-manager-acme-ca/ | envsubst | oc create -f -
  ```

- Use ACM to create ACME Certificates for OCP Wildcard Domains

  ```bash
  oc create -f ./cert-manager/ocp-cert-manager-acme-certrequests/generated-policy.yaml
  ```

  OR

  Generate your own policy and then create.

  ```bash
  kustomize build --enable-alpha-plugins ./cert-manager/ocp-cert-manager-acme-certrequests/ | oc create -f -  
  ```
  
## Attach Subscription Admin Policy to your user if necessary

```bash
 oc adm policy add-cluster-role-to-user open-cluster-management:subscription-admin $(oc whoami)
```