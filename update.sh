#!/bin/bash
#	= ^ . ^ =

# https://docs.openshift.com/container-platform/4.10/updating/index.html
# https://access.redhat.com/documentation/en-us/openshift_container_platform/4.10/html-single/updating_clusters/index
# https://access.redhat.com/labs/ocpupgradegraph/update_path
# https://access.redhat.com/articles/6329921
# https://access.redhat.com/support/policy/updates/openshift
# https://access.redhat.com/support/policy/updates/openshift-eus

#	4.6.56
#	4.7.50
#	4.8.45
#	4.9.40
#	4.10.25

VERSION=4.10
NEW_VERSION=4.10.25
# stable, candidate or fast
CHANNEL=stable-${VERSION}
RHT_OCP4_DEV_USER=
RHT_OCP4_DEV_PASSWORD=
RHT_OCP4_MASTER_API=

set -x

oc login --insecure-skip-tls-verify\
  -u ${RHT_OCP4_DEV_USER} \
  -p ${RHT_OCP4_DEV_PASSWORD} \
  ${RHT_OCP4_MASTER_API}

oc patch clusterversion version \
  --type="merge" \
  --patch '{"spec":{"channel":"'${CHANNEL}'"}}' \
;

sleep 1

if [ "${VERSION}" = "4.9" ]
then
  oc get configmap admin-acks -n openshift-config &>/dev/null
  test "$?" -ne 0 && \
    oc create configmap admin-acks -n openshift-config

  oc patch configmap admin-acks -n openshift-config \
    --type="merge" \
    --patch '{"data":{"ack-4.8-kube-1.22-api-removals-in-4.9":"true"}}' \
  ;
fi

sleep 30

date

if [ "${NEW_VERSION}" = "latest" ]
then
  oc adm upgrade --to-latest="true"
else
  oc adm upgrade --to="${NEW_VERSION}"
fi

sleep 1

watch -n 15 -d \
  oc get -A \
    clusterversion,clusteroperators,operators,subscriptions,clusterserviceversions
