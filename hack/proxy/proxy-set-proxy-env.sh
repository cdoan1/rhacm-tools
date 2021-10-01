#!/bin/bash

export xHTTP_PROXY=$(oc get proxy cluster -n openshift-config -ojsonpath='{.status.httpProxy}')
export xHTTPS_PROXY=$(oc get proxy cluster -n openshift-config -ojsonpath='{.status.httpsProxy}')
export xNO_PROXY=$(oc get proxy cluster -n openshift-config -ojsonpath='{.status.noProxy}')

set_deployment_env() {
  kubectl patch deployment $1 -n $3 \
-p '{"spec":{"template":{"spec":{"containers":[{"env":[{"name":"HTTPS_PROXY","value":"'${xHTTPS_PROXY}'"},{"name":"HTTP_PROXY","value":"'${xHTTP_PROXY}'"},{"name":"NO_PROXY","value":"'${xNO_PROXY}'"}],"name":"'$2'"}]}}}}'
}

echo "Using these current proxy settings fromt the current cluster proxy settings ..."
echo "  HTTP_PROXY: ${xHTTP_PROXY}"
echo "  HTTPS_PROXY: ${xHTTPS_PROXY}"
echo "  NO_PROXY: ${xNO_PROXY}"
echo ""

# Pause Hub Management
# oc annotate -n open-cluster-management `oc get mch -oname -n open-cluster-management | head -n1` mch-pause=true --overwrite=true

# Pause Spoke Management on local-cluster
# oc annotate klusterletaddonconfig -n local-cluster local-cluster klusterletaddonconfig-pause=false --overwrite=true
oc annotate klusterletaddonconfig -n local-cluster local-cluster klusterletaddonconfig-pause=true --overwrite=true
echo "Paused the managed cluster addonconifg on: local-cluster"
echo ""

for NS in open-cluster-management-agent open-cluster-management-agent-addon
do
  list=`oc get deployment -n $NS --no-headers -o custom-columns=":metadata.name"`
  for y in $list
  do
    if oc get deployment $y -n $NS -o yaml | grep "HTTP_PROXY" > /dev/null; then
      :
    else
      echo "updating deployment: $y"
      if [ ! -z $DEBUG ]; then
        oc get deployment $y -n $NS -ojsonpath='{.spec.template.spec.containers}' | jq . | grep '\"name\":'
      fi    
      c=$(oc get deployment $y -n $NS -ojsonpath='{.spec.template.spec.containers}' | jq . | grep '^    \"name\":' | awk '{print $2}' | tr -d "\"" | tr -d ",")
      for container_name in $c
      do
        echo $y, $container_name, $NS
        #if [[ $y == "klusterlet" || 
        #      $y == "klusterlet-work-agent" ||
        #      $y == "klusterlet-registration-agent"
        #]]; then
        #  echo "skipping ...$y"
        #  continue
        #fi
        set_deployment_env $y $container_name $NS
      done
      echo ""
    fi
  done
done
