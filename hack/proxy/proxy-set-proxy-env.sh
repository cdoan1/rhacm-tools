#!/bin/bash

export _HTTP_PROXY=$(oc get proxy cluster -n openshift-config -ojsonpath='{.status.httpProxy}')
export _HTTPS_PROXY=$(oc get proxy cluster -n openshift-config -ojsonpath='{.status.httpsProxy}')
export _NO_PROXY=$(oc get proxy cluster -n openshift-config -ojsonpath='{.status.noProxy}')

set_deployment_env() {
  kubectl patch deployment $1 -n $3 \
-p '{"spec":{"template":{"spec":{"containers":[{"env":[{"name":"HTTPS_PROXY","value":"'${_HTTPS_PROXY}'"},{"name":"HTTP_PROXY","value":"'${_HTTP_PROXY}'"},{"name":"NO_PROXY","value":"'${_NO_PROXY}'"}],"name":"'$2'"}]}}}}'
}

echo "Using these current proxy settings fromt the current cluster proxy settings ..."
echo "  HTTP_PROXY: ${_HTTP_PROXY}"
echo "  HTTPS_PROXY: ${_HTTPS_PROXY}"
echo "  NO_PROXY: ${_NO_PROXY}"
echo ""

# Pause the hub management of the klusterlet agent and addon operator for hub, and all managed clusters across the fleet
# oc annotate -n open-cluster-management `oc get mch -oname -n open-cluster-management | head -n1` mch-pause=true --overwrite=true

# oc annotate klusterletaddonconfig -n local-cluster local-cluster klusterletaddonconfig-pause=false --overwrite=true
oc annotate klusterletaddonconfig -n local-cluster local-cluster klusterletaddonconfig-pause=true --overwrite=true
echo "Paused the auto management of the addon components on: local-cluster."
echo ""

for NS in open-cluster-management-agent open-cluster-management-agent-addon
do
  list=`oc get deployment -n $NS --no-headers -o custom-columns=":metadata.name"`
  for deployment in $list
  do
    if oc get deployment $deployment -n $NS -o yaml | grep "HTTP_PROXY" > /dev/null; then
      :
    else
      echo "updating deployment: $deployment"
      if [ ! -z $DEBUG ]; then
        oc get deployment $deployment -n $NS -ojsonpath='{.spec.template.spec.containers}' | jq . | grep '\"name\":'
      fi    
      c=$(oc get deployment $deployment -n $NS -ojsonpath='{.spec.template.spec.containers}' | jq . | grep '^    \"name\":' | awk '{print $2}' | tr -d "\"" | tr -d ",")
      for container_name in $c
      do
        # echo $deployment, $container_name, $NS
        # if [[ $deployment == "klusterlet" || 
        #      $deployment == "klusterlet-work-agent" ||
        #      $deployment == "klusterlet-registration-agent"
        # ]]; then
        #  echo "skipping $deployment ..."
        #  continue
        # fi
        set_deployment_env $deployment $container_name $NS
      done
      echo ""
    fi
  done
done
