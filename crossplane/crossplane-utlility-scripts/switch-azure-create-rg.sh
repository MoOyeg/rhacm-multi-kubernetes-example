#!/bin/bash 

RESOURCEGROUP=${1:-crossplane-azure-rg}

#Comment Out HardCoded RG
grep -rli 'resourceGroupName: resourcegroup-replaceme' * | grep yaml | xargs -i@ sed -E -i 's/^( +)resourceGroupName: resourcegroup-replaceme/\1#resourceGroupName: resourcegroup-replaceme/g' @

#Uncomment Out Reference
grep -rli 'resourceGroupName: resourcegroup-replaceme' * | grep yaml | xargs -i@ sed -E -i 's/^( +)#resourceGroupNameRef:/\1resourceGroupNameRef:/g' @

#Uncomment Out Name and Set to expected
#Uncomment Out Reference
grep -rli 'resourceGroupName: resourcegroup-replaceme' * | grep yaml | xargs -i@ sed -E -i 's/^( +)#(  +)name: resourcegroup-replaceme/\1\2name: '${RESOURCEGROUP}'/g' @

#update the kustomization.yaml file
grep -rli 'Uncomment Resourcegroup if you would like it created' * | grep yaml | xargs -i@ sed -i 's/resources: \[\]/resources:/g' @
grep -rli 'Uncomment Resourcegroup if you would like it created' * | grep yaml | xargs -i@ sed -E -i 's/^#( +.*)/\1/g' @