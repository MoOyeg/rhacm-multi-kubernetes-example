# rhacm-multi-kubernetes-example

Example to Deploy an app across multiple kubernetes clusters using ACM and GitOps

oc apply -k ./policy-global-namespace/

oc apply -k ./placementrules/

kustomize build ./xks-general-policies/ --enable-alpha-plugins | oc create -f -

kustomize build ./openshift-gitops/base --enable-alpha-plugins | oc create -f -

kustomize build ./argocd/ --enable-alpha-plugins | oc create -f -
