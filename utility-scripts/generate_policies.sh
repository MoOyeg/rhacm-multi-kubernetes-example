#!/bin/bash 
#Run policy generator files to create refresh generated policies

kustomize build --enable-alpha-plugins ./crossplane/ > ./crossplane/generated-policy.yaml
kustomize build --enable-alpha-plugins ./acs/acs-operator > ./acs/acs-operator/generated-policy.yaml
kustomize build --enable-alpha-plugins ./acs/acs-central > ./acs/acs-central/generated-policy.yaml
kustomize build --enable-alpha-plugins ./acs/acs-xks-helm-secured-instance/ > ./acs/acs-xks-helm-secured-instance/generated-policy.yaml
kustomize build --enable-alpha-plugins ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/global/ > ./xks-policies/policy-eks-ingresscontroller/crossplane-aws-lb-controller/global/generated-policy.yaml
kustomize build --enable-alpha-plugins ./xks-policies/xks-general-policies/ > ./xks-policies/xks-general-policies/generated-policy.yaml
