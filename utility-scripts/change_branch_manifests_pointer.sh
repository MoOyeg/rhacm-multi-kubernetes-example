#!/bin/bash 
#Utility script to reset application subscription yamls, argo application yamls to match current branch
#Will also make changes to resourcegroup file to my default

BRANCH=${1:-main}
RESOURCEGROUP=${2:-resourcegroup-replaceme}

#Change All Subscriptions to Branch Current Branch
grep -rli 'apps.open-cluster-management.io/git-branch:' * | grep yaml | xargs -i@ sed -E -i 's/^( *apps.open-cluster-management.io\/git-branch:) .*/\1 '${BRANCH}'/g' @

#Change All ArgoCD Applications to Current Branch
grep -rli 'targetRevision:' * | grep yaml | xargs -i@ sed -E -i 's/^( *targetRevision:) .*/\1 '${BRANCH}'/g' @

#Reset resourcegroupname to default
grep -rli 'resourceGroupName:' * | grep yaml | xargs -i@ sed -E -i 's/^( +)resourceGroupName: .*/\1resourceGroupName: '${RESOURCEGROUP}'/g' @