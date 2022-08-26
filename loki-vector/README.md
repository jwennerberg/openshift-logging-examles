## OpenShift Logging with Loki and Vector

Quick howto on configuring OpenShift Logging with Vector as a collector and Loki as a log store.

### Automated installation

1. Create s3 bucket
2. Configure s3 env file for your environment

```
cat deploy/lokistack/env-s3
```

```
bucketnames=loki-logging
region=us-east-2
access_key_id=foo
access_key_secret=bar
endpoint=https://s3.us-east-2.amazonaws.com
```

3. Deploy!

```bash
./deploy.sh
```

4. [Verify](#verify-installation)

### (Semi) Manual installation

#### Install Operators

##### 1. Install Loki Operator 5.5+
##### 2. Install OpenShift Logging Operator 5.5+

```bash
oc apply -k deploy/operators/
```

#### Deploy Loki

##### 1. Create a s3 bucket
##### 2. Create a `Secret` with s3 bucket information

Example script for configuring it on AWS:
```
./deploy/aws-s3-secret.sh BUCKET-NAME
```

##### 3. Create a `LokiStack` CR

```bash
oc apply -f deploy/lokistack/lokistack.yaml -n openshift-logging
```

```yaml
apiVersion: loki.grafana.com/v1
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

#### Deploy Cluster Logging components

##### 1. ClusterLogging CR

Create a `ClusterLogging` CR referencing the LokiStack as a Log store and `vector` as a collector.

```bash
oc apply -f deploy/clusterlogging/clusterlogging.yaml -n openshift-logging
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

### Verify installation


Verify that the Loki stack is up and running:

```bash
oc get pods -n openshift-logging -l app.kubernetes.io/instance=lokistack-dev
NAME                                            READY   STATUS    RESTARTS   AGE
lokistack-dev-compactor-0                       1/1     Running   0          3h28m
lokistack-dev-distributor-6c4bc8b44-fl9jh       1/1     Running   0          3h28m
lokistack-dev-gateway-5cb6c47496-6764p          2/2     Running   0          3h28m
lokistack-dev-index-gateway-0                   1/1     Running   0          3h28m
lokistack-dev-ingester-0                        1/1     Running   0          3h28m
lokistack-dev-querier-68bd6f4cdf-2dtmn          1/1     Running   0          3h28m
lokistack-dev-query-frontend-85c6c44746-85pg4   1/1     Running   0          3h28m
lokistack-dev-ruler-0                           1/1     Running   0          3h28m
```

Verify that `Vector` collector pods are running:

```bash
oc get pods -n openshift-logging -l component=collector
NAME              READY   STATUS    RESTARTS   AGE
collector-cn6sr   2/2     Running   0          3h25m
collector-dm277   2/2     Running   0          3h25m
collector-rj8cj   2/2     Running   0          3h25m
collector-stgd2   2/2     Running   0          3h25m
collector-txtcr   2/2     Running   0          3h25m
collector-w7sn9   2/2     Running   0          3h25m
collector-wvwrk   2/2     Running   0          3h25m
```

Verify log exploration in the OpenShift Console:

<img width="1000" alt="logging-console-plugin" src="https://user-images.githubusercontent.com/4189904/185391043-4451a9cd-fef1-4055-aa3c-cc2287cdf0be.png">

