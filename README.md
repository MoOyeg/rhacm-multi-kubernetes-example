# rhacm-multi-kubernetes-example

Example to Deploy an app across multiple kubernetes clusters using ACM and GitOps

oc apply -k ./policy-global-namespace/

oc apply -k ./placementrules/

kustomize build ./xks-general-policies/ --enable-alpha-plugins | oc create -f -

kustomize build ./hub-policies --enable-alpha-plugins | oc create -f -

## Operator Installs

### Install GitOps,Pipelines on OCP

kustomize build ./ocp-policies --enable-alpha-plugins | oc create -f -

kustomize build ./xks-argocd/ --enable-alpha-plugins | oc create -f -

## Install ACS Central

oc apply -k ./acs-operator-central-gitops

Apps:
Deploy Pacman App
oc apply -k ./pacman-app/deploy
