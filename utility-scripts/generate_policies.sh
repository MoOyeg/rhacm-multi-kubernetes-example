#!/bin/bash 
#Run policy generator files to refresh generated policy yamls

kustomize build --enable-alpha-plugins ./policy-global-base > ./policy-global-base/generated-policy.yaml
kustomize build --enable-alpha-plugins ./crossplane/ > ./crossplane/generated-policy.yaml
kustomize build --enable-alpha-plugins ./acs/acs-operator > ./acs/acs-operator/generated-policy.yaml
kustomize build --enable-alpha-plugins ./acs/acs-central > ./acs/acs-central/generated-policy.yaml
kustomize build --enable-alpha-plugins ./acs/acs-xks-helm-secured-instance/ > ./acs/acs-xks-helm-secured-instance/generated-policy.yaml
kustomize build --enable-alpha-plugins ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/global/ > ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/global/generated-policy.yaml
kustomize build --enable-alpha-plugins ./xks-policies/xks-olm/ > ./xks-policies/xks-olm/generated-policy.yaml
kustomize build --enable-alpha-plugins ./xks-policies/policy-xks-nginx-ingresscontroller/aks-overlay-generator/ > ./xks-policies/policy-xks-nginx-ingresscontroller/aks-overlay-generator/generated-policy.yaml
kustomize build --enable-alpha-plugins ./xks-policies/policy-xks-nginx-ingresscontroller/eks-overlay-generator/ > ./xks-policies/policy-xks-nginx-ingresscontroller/eks-overlay-generator/generated-policy.yaml
kustomize build --enable-alpha-plugins ./xks-policies/policy-xks-nginx-ingresscontroller/global-generator/ > ./xks-policies/policy-xks-nginx-ingresscontroller/global-generator/generated-policy.yaml
kustomize build --enable-alpha-plugins ./xks-policies/xks-argocd/ > ./xks-policies/xks-argocd/generated-policy.yaml


#Cert-manager
kustomize build --enable-alpha-plugins ./cert-manager/ocp-cert-manager-operator/ > ./cert-manager/ocp-cert-manager-operator/generated-policy.yaml
kustomize build --enable-alpha-plugins ./cert-manager/xks-cert-manager/cert-manager-operator/ > ./cert-manager/xks-cert-manager/cert-manager-operator/generated-policy.yaml
kustomize build --enable-alpha-plugins ./cert-manager/ocp-cert-manager-acme-ca/ > ./cert-manager/ocp-cert-manager-acme-ca/generated-policy.yaml
#kustomize build --enable-alpha-plugins ./cert-manager/ocp-cert-manager-acme-ca/ | envsubst > ./cert-manager/ocp-cert-manager-acme-ca/generated-policy.yaml
kustomize build --enable-alpha-plugins ./cert-manager/ocp-cert-manager-acme-certrequests/ > ./cert-manager/ocp-cert-manager-acme-certrequests/generated-policy.yaml