#!/bin/bash

CLUSTER_LOGGING_OPERATOR_NAMESPACE=openshift-logging
LOKI_OPERATOR_NAMESPACE=openshift-operators-redhat

DEPLOYDIR=$(dirname $0)/deploy

# Deploy operators
echo "[] Deploying Operators.."
oc apply -k ${DEPLOYDIR}/operators/

# Wait for operators to become available
echo "[] Waiting for Cluster Logging Operator to become available.."
until oc get -n ${CLUSTER_LOGGING_OPERATOR_NAMESPACE} deployment/cluster-logging-operator >/dev/null ; do sleep 2; done
oc wait -n ${CLUSTER_LOGGING_OPERATOR_NAMESPACE} --timeout=180s --for=condition=available deployment/cluster-logging-operator

echo "[] Waiting for Loki Operator to become available.."
until oc get -n ${LOKI_OPERATOR_NAMESPACE} deployment/loki-operator-controller-manager >/dev/null ; do sleep 2; done
oc wait -n ${LOKI_OPERATOR_NAMESPACE} --timeout=180s --for=condition=available deployment/loki-operator-controller-manager

# Deploy a LokiStack
echo "[] Deploying LokiStack.."
oc apply -k ${DEPLOYDIR}/lokistack/ -n ${CLUSTER_LOGGING_OPERATOR_NAMESPACE}

echo "[] Waiting for the LokiStack to become available.."
oc wait -n ${CLUSTER_LOGGING_OPERATOR_NAMESPACE} --timeout=180s --for condition=Ready lokistack/lokistack-dev

# Deploy ClusterLogging
echo "[] Deploying ClusterLogging CR.."
oc apply -k ${DEPLOYDIR}/clusterlogging/ -n ${CLUSTER_LOGGING_OPERATOR_NAMESPACE}

echo "[] Waiting for collector (Vector) to become available.."
oc wait -n ${CLUSTER_LOGGING_OPERATOR_NAMESPACE} --timeout=180s --for condition=Ready pod -l component=collector

