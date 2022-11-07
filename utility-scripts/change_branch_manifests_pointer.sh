#!/bin/bash 
#Utility script to reset application subscription yamls, argo application yamls to match current branch
#Will also make changes to resourcegroup file to my default
#Script Requires GIT

BRANCH=${1:-main}
NONPOINTER_CHANGE=${2:-yes}
RESOURCEGROUP=${3:-resourcegroup-replaceme}

REPO_NAME=$(git remote -v | grep fetch | grep -o -E "github.com[:/]+.* " | sed 's$:$/$g' | sed 's$\.git$$g')

#Change All Subscriptions to Branch Current Branch
grep -rli 'apps.open-cluster-management.io/git-branch:' * | grep yaml | xargs -i@ sed -E -i 's/^( *apps.open-cluster-management.io\/git-branch:) .*/\1 '${BRANCH}'/g' @

#Change All ArgoCD Applications in our repo(only origin) to Current Branch

grep -rli 'targetRevision:' * |  grep -rli ${REPO_NAME} | grep yaml | xargs -i@ sed -E -i 's/^( *targetRevision:) .*/\1 '${BRANCH}'/g' @


if [ "${NONPOINTER_CHANGE}" = "yes" ]
then
    #Reset resourcegroupname to default
    echo "test"
    grep -rli 'resourceGroupName:' * | grep yaml | xargs -i@ sed -E -i 's/^( +)resourceGroupName: .*/\1resourceGroupName: '${RESOURCEGROUP}'/g' @
fi
