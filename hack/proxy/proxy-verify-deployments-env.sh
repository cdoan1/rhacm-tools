#!/bin/bash

echo ""
echo "Date: $(date)"
echo "Date: $(date -u)"
echo "Cluster: $(oc cluster-info | grep api)"
echo ""

for NS in open-cluster-management hive open-cluster-management-hub open-cluster-management-agent open-cluster-management-agent-addon
do
  for p in `oc get deployments -n $NS | awk '{print $1}' | grep -v NAME`
  do
    if oc get deployment $p -n $NS -o yaml | grep PROXY > /dev/null ; then
      :
    else
      echo "no proxy in deployment: $p"
    fi
  done
done
