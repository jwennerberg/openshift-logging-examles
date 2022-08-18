## OpenShift Logging with Loki and Vector

Quick howto on configuring OpenShift Logging with Vector as a collector and Loki as a log store.

### Install Operators

##### 1. Install Loki Operator
##### 2. Install OpenShift Logging Operator 5.5

Until OpenShift Logging 5.5 is GA and available in the Operator Hub you can install it from the upstream repository.
```
git clone https://github.com/openshift/cluster-logging-operator.git
git checkout 5.5
./olm_deploy/scripts/catalog-deploy.sh
./olm_deploy/scripts/operator-install.sh
```

### Deploy Loki

##### 1. Create an object store (s3) bucket
##### 2. Create a `Secret` with s3 information 
```
./deploy-aws-s3-secret.sh
oc apply -f lokistack.yaml
```

##### 3. Create a `LokiStack` CR

```yaml
apiVersion: loki.grafana.com/v1beta1
kind: LokiStack
metadata:
  name: lokistack-dev
  namespace: openshift-logging
spec:
  size: 1x.extra-small
  storage:
    schemas:
    - version: v12
      effectiveDate: 2022-06-01
    secret:
      name: loki-aws-s3
      type: s3
  storageClassName: gp2
  tenants:
    mode: openshift-logging
  rules:
    enabled: true
    selector:
      matchLabels:
        openshift.io/cluster-monitoring: "true"
    namespaceSelector:
      matchLabels:
        openshift.io/cluster-monitoring: "true"
```

### Deploy Cluster Logging components

##### 1. ClusterLogging CR

Create a `ClusterLogging` CR referencing the LokiStack as a Log store and `vector` as a collector.

```
oc apply -f clusterlogging.yaml
```

```yaml
apiVersion: logging.openshift.io/v1
kind: ClusterLogging
metadata:
  name: instance
  namespace: openshift-logging
spec:
  managementState: Managed
  logStore:
    type: lokistack
    lokistack:
      name: lokistack-dev
  collection:
    logs:
      type: vector
      vector: {}
```

##### 2. Enable the Console Plugin

Enable the console plugin for the OpenShift Logging Operator to explore the logs inside the OpenShift Console.

```
Operators -> Installed Operators -> Red Hat OpenShift Logging
```
On the right hand side click "Console plugin" and select "Enabled". Wait for the plugin to install and then refresh the console with the link in the popup notification
