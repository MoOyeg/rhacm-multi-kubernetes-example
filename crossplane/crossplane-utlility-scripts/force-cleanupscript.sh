#!/bin/bash -x

## Extremely dangerous script to try to remove crossplane resources ##
## Does not clean up CCSP Side ##
### Use at your own risk ###



readarray -t CRDS < <(oc get crd -o name | grep -i crossplane)
for crd in "${CRDS[@]}"
do
  short_name=$(echo "${crd}" | cut -d "/" -f2)
  
  for name in "${short_name[@]}"
  do
    readarray -t objects < <(oc get ${name} -o name -A)
    for object in "${objects[@]}"
    do
      echo "Attempting to Force Delete ${object}"
      oc delete ${object} --force --grace-period=0 --timeout=5s

      if oc get ${object}
      then
        #Patch Finalizer, this is a very bad thing to do. Forget you ever saw this
        echo "Removing Finalizer for Object ${object}"
        oc patch ${object} --type=merge -p '{"metadata":{"finalizers":[]}}'

      fi
    done  
  
  done
done