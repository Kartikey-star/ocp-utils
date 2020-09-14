#!/bin/bash -x

CLUSTER_BASE_NAME=${CLUSTER_BASE_NAME:-dev-svc}
# OI_VERSION="4.4.0-0.nightly-2020-01-22-045318"
# OCP_RELEASE_DIR="ocp-dev-preview"
# OCP_RELEASE="4.4"

if [ -z $OCP_RELEASE ]; then
    #detect OCP_RELEASE for given OI_VERSION
    export OCP_RELEASE=$(echo $OI_VERSION | sed 's,\([0-9]\+\.[0-9]\+\)\..*,\1,g')
else
    #detect OI_VERSION for given OCP_RELEASE
    export OI_VERSION=${OI_VERSION:-$(curl -s -L https://mirror.openshift.com/pub/openshift-v4/clients/$OCP_RELEASE_DIR/latest-$OCP_RELEASE/release.txt | grep 'Name:' | sed -e 's,Name:\s\+\(.*\),\1,g')}
fi

cd $WORKSPACE

wget -O oi.tar.gz https://mirror.openshift.com/pub/openshift-v4/clients/${OCP_RELEASE_DIR}/${OI_VERSION}/openshift-install-linux-${OI_VERSION}.tar.gz
tar -xvf oi.tar.gz
rm -rvf oi.tar.gz

export PATH=$PATH:$WORKSPACE:$WORKSPACE/ocp-utils.git/ocp4-aws

openshift-install version

export OCP4_AWS_WORKSPACE=$WORKSPACE/ocp4-aws

ocp4-aws -l $CLUSTER_BASE_NAME >> vpc.list


for DAY in $(seq 1 7); do
    VPC_PREFIX=$CLUSTER_BASE_NAME-${OCP_RELEASE//\./\-}-$(date -d "$DAY day ago" +%m%d);
    for VPC in $(cat vpc.list); do
        if [[ $VPC == $VPC_PREFIX* ]]; then
            echo "Deleting $VPC VPC..."
            ocp4-aws -D $VPC
        fi
    done
done