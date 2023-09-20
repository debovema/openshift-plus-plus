#!/bin/sh

SCRIPT_DIRECTORY=$(dirname "$0")

ansible-galaxy collection install -r $SCRIPT_DIRECTORY/../ansible/requirements.yml > /dev/null

echo "Creating one hub cluster (3 master nodes) and 3 single-node managed clusters"
echo

STDOUT=/dev/null
# STDOUT=/dev/fd/1 # uncomment to output to stdout

CLUSTERS="rhacm-hub rhacm-managed1 rhacm-managed2 rhacm-managed3"
for CLUSTER_NAME in $CLUSTERS; do
    export CLUSTER_NAME
    echo "Creating VPC for '$CLUSTER_NAME' cluster..."
    ansible-playbook ./fleet-on-aws/ansible/playbooks/vpc-for-ocp.yml > $STDOUT 2>&1
    echo "Creating DNS public hosted zone for '$CLUSTER_NAME' cluster..."
    ansible-playbook ./fleet-on-aws/ansible/playbooks/public-hosted-zone-for-ocp.yml > $STDOUT 2>&1
    echo "Generating installation configuration file for '$CLUSTER_NAME' cluster..."
    $SCRIPT_DIRECTORY/../generate-install-config.sh > $STDOUT 2>&1
    echo
done

echo Spawning openshift-install processes with prefixed output...

# exit 0
# launch openshift-install in parallel for the 4 clusters with prefixed output
for CLUSTER_NAME in $CLUSTERS; do
    export CLUSTER_NAME
    openshift-install create cluster --dir $SCRIPT_DIRECTORY/../clusters/$CLUSTER_NAME      --log-level=INFO 2> >(sed "s/^/[$CLUSTER_NAME]      /") &
done