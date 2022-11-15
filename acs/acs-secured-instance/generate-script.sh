#!/bin/bash
BASEDIR="${2:-$(dirname "$0")}"

 # Get list of managed clusters 
readarray -t CLUSTER_LIST_NAME < <(oc get managedcluster -A -o name| grep -v local-cluster | cut -d "/" -f2)

 #Exit if not enough clusters
if [ "${#CLUSTER_LIST_NAME[@]}" -lt 1 ]
then
  exit_message "Did not get any other clusters(apart from maybe the local cluster), exiting"
fi

#Delete Previous Placementrule Files
find ${BASEDIR}/manifests -name "placementrule-*.yaml" | xargs -i@ rm -rf @

#Delete Previous Subscription Files
find ${BASEDIR}/manifests -name "subscription-*.yaml" | xargs -i@ rm -rf @

#Create New Placementrule Files
for cluster_name in "${CLUSTER_LIST_NAME[@]}"
do
  sed "s/managedcluster-replace-me/$cluster_name/g" ${BASEDIR}/placementrule-base/placementrule.yaml > ${BASEDIR}/manifests/placementrule-$cluster_name.yaml
done

#Create New Subscription Files
for cluster_name in "${CLUSTER_LIST_NAME[@]}"
do
  sed "s/managedcluster-replace-me/$cluster_name/g" ${BASEDIR}/subscription-base/subscription.yaml > ${BASEDIR}/manifests/subscription-$cluster_name.yaml
done