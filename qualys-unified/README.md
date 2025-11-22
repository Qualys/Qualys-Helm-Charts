# Qualys Unified Helm Chart

A comprehensive Helm chart for deploying Qualys security sensors in Kubernetes and OpenShift clusters. This unified chart allows you to selectively install:

- **Host Sensor** - Scans hosts and containers
- **Cluster Sensor** - Discovers and monitors Kubernetes resources
- **Runtime Sensor** - Monitors runtime behavior and detects anomalies
- **General Sensor** - Scans container images for vulnerabilities
- **Admission Controller** - Controls deployments based on security policy

## Prerequisites

- Kubernetes 1.16+
- Helm 3.0+
- Qualys subscription with:
  - Customer ID
  - Activation ID
  - Gateway URL

## Quick Start

### 1. Add the Helm Repository

```bash
helm repo add qualys-helm-chart https://qualys.github.io/Qualys-Helm-Charts/
helm repo update
```

### 2. Create a values file

Create a `my-values.yaml` file with your Qualys credentials:

```yaml
global:
  customerId: "your-customer-id"           # Shared by all sensors
  activationId: "container-activation-id"  # For cluster/runtime/general sensors
  qualysPod: "US2"                         # Auto-fills gatewayUrl and cmsqagPublicUrl
  clusterInfoArgs:
    cloudProvider: "AWS"                   # Shared by all sensors
    AWS:
      arn: "your-cluster-arn"

# Enable the sensors you need
hostsensor:
  enabled: true
  qualys:
    args:
      activationId: "host-sensor-activation-id"  # Different activation ID

qualysTc:
  enabled: true
  clusterSensor:
    enabled: true
  runtimeSensor:
    enabled: true
  qcsSensor:
    enabled: true
```

### 3. Install the chart

**Option A: Install with values file**

```bash
helm install qualys-sensors qualys-helm-chart/qualys-unified \
  -f my-values.yaml \
  -n qualys --create-namespace
```

**Option B: Install with command-line flags**

```bash
# Example: Cluster + General Sensors only
helm install qualys-sensors qualys-helm-chart/qualys-unified \
  --set global.customerId=YOUR_CUSTOMER_ID \
  --set global.activationId=CONTAINER_SENSOR_ACTIVATION_ID \
  --set global.qualysPod=US2 \
  --set global.clusterInfoArgs.cloudProvider=AWS \
  --set global.clusterInfoArgs.AWS.arn="arn:aws:eks:region:account:cluster/name" \
  --set hostsensor.enabled=false \
  --set qualysTc.enabled=true \
  --set qualysTc.clusterSensor.enabled=true \
  --set qualysTc.qcsSensor.enabled=true \
  --set qualysTc.qcsSensor.qualys.args.performScaScan=true \
  --set qualysTc.qcsSensor.qualys.args.enableConsoleLogs=true \
  --set qualysTc.qcsSensor.qualys.args.withoutPersistentStorage=true \
  --namespace qualys --create-namespace

# Example: Host Sensor only
helm install qualys-sensors qualys-helm-chart/qualys-unified \
  --set global.customerId=YOUR_CUSTOMER_ID \
  --set global.qualysPod=US2 \
  --set global.clusterInfoArgs.cloudProvider=AWS \
  --set hostsensor.enabled=true \
  --set hostsensor.qualys.args.activationId=HOST_SENSOR_ACTIVATION_ID \
  --set qualysTc.enabled=false \
  --namespace qualys --create-namespace

# Example: All Sensors (with different activation IDs)
helm install qualys-sensors qualys-helm-chart/qualys-unified \
  --set global.customerId=YOUR_CUSTOMER_ID \
  --set global.activationId=CONTAINER_SENSOR_ACTIVATION_ID \
  --set global.qualysPod=US2 \
  --set global.clusterInfoArgs.cloudProvider=AWS \
  --set global.clusterInfoArgs.AWS.arn="arn:aws:eks:region:account:cluster/name" \
  --set hostsensor.enabled=true \
  --set hostsensor.qualys.args.activationId=HOST_SENSOR_ACTIVATION_ID \
  --set qualysTc.enabled=true \
  --set qualysTc.clusterSensor.enabled=true \
  --set qualysTc.qcsSensor.enabled=true \
  --set qualysTc.qcsSensor.qualys.args.performScaScan=true \
  --namespace qualys --create-namespace
```

## Configuration

### Important: Separate Activation IDs

**The host sensor uses a DIFFERENT activation ID than cluster/runtime/general sensors.**

- **`global.customerId`**: Shared by ALL sensors (same value)
- **`global.cloudProvider`**: Shared by ALL sensors (same cluster, same provider)
- **`global.activationId`**: Used by cluster/runtime/general/admission sensors
- **`hostsensor.qualys.args.activationId`**: Used ONLY by host sensor (different value)

You can obtain these separate activation IDs from different sections in the Qualys platform:
- **Host sensor activation**: Container Security > Sensors > Host Sensor section
- **Container sensor activation**: Container Security > Sensors > Kubernetes section

### Global Settings

Global settings apply to cluster sensor, runtime sensor, general sensor, and admission controller:

| Parameter | Description | Required |
|-----------|-------------|----------|
| `global.customerId` | Qualys Customer ID (shared by all sensors) | Yes |
| `global.activationId` | Activation ID for cluster/runtime/general sensors | Yes (for container sensors) |
| `global.qualysPod` | Qualys Platform Pod (e.g., "US2", "EU1") - Auto-fills URLs | **Recommended** |
| `global.clusterInfoArgs.cloudProvider` | Cloud provider (AWS/AZURE/GCP/OCI/SELF_MANAGED_K8S) | Yes |
| `global.gatewayUrl` | Qualys Gateway URL (auto-filled if qualysPod is set) | Optional if qualysPod set |
| `global.cmsqagPublicUrl` | Container Security URL (auto-filled if qualysPod is set) | Optional if qualysPod set |

### Qualys Platform Pod Identifier (Recommended)

Instead of manually specifying `gatewayUrl` and `cmsqagPublicUrl`, you can simply set `global.qualysPod` to your Qualys platform identifier. The chart will automatically configure the correct URLs for you.

**Supported Platform Identifiers:**

| Pod ID | Gateway URL | Container Security URL |
|--------|-------------|------------------------|
| US1 | https://gateway.qg1.apps.qualys.com | https://cmsqagpublic.qg1.apps.qualys.com/ContainerSensor |
| US2 | https://gateway.qg2.apps.qualys.com | https://cmsqagpublic.qg2.apps.qualys.com/ContainerSensor |
| US3 | https://gateway.qg3.apps.qualys.com | https://cmsqagpublic.qg3.apps.qualys.com/ContainerSensor |
| US4 | https://gateway.qg4.apps.qualys.com | https://cmsqagpublic.qg4.apps.qualys.com/ContainerSensor |
| GOV1 | https://gateway.gov1.qualys.us | https://cmsqagpublic.gov1.qualys.us/ContainerSensor |
| EU1 | https://gateway.qg1.apps.qualys.eu | https://cmsqagpublic.qg1.apps.qualys.eu/ContainerSensor |
| EU2 | https://gateway.qg2.apps.qualys.eu | https://cmsqagpublic.qg2.apps.qualys.eu/ContainerSensor |
| EU3 | https://gateway.qg3.apps.qualys.it | https://cmsqagpublic.qg3.apps.qualys.it/ContainerSensor |
| IN1 | https://gateway.qg1.apps.qualys.in | https://cmsqagpublic.qg1.apps.qualys.in/ContainerSensor |
| CA1 | https://gateway.qg1.apps.qualys.ca | https://cmsqagpublic.qg1.apps.qualys.ca/ContainerSensor |
| AE1 | https://gateway.qg1.apps.qualys.ae | https://cmsqagpublic.qg1.apps.qualys.ae/ContainerSensor |
| UK1 | https://gateway.qg1.apps.qualys.co.uk | https://cmsqagpublic.qg1.apps.qualys.co.uk/ContainerSensor |
| AU1 | https://gateway.qg1.apps.qualys.com.au | https://cmsqagpublic.qg1.apps.qualys.com.au/ContainerSensor |
| KSA1 | https://gateway.qg1.apps.qualysksa.com | https://cmsqagpublic.qg1.apps.qualysksa.com/ContainerSensor |

**Example:**
```yaml
global:
  qualysPod: "US2"  # Automatically sets both gateway and CMS URLs
```

Not sure which platform you're on? Visit: https://www.qualys.com/platform-identification/

### Host Sensor

Deploy the Linux Agent for containers to scan host nodes. **Note: Requires separate activation ID.**

#### Automatic Image Selection

The host sensor Docker image is **automatically selected** based on your cloud provider:

| Cloud Provider Setting | Detected Provider | Docker Image Used |
|------------------------|-------------------|-------------------|
| `global.clusterInfoArgs.cloudProvider: "AWS"` | AWS | `qualys/qagent_bottlerocket` |
| `global.clusterInfoArgs.cloudProvider: "GCP"` | GCP | `qualys/qagent_googlecos` |
| `global.openshift: true` | COREOS | `qualys/qagent-rhcos` |

You don't need to specify the image repository - it's selected automatically!

```yaml
global:
  customerId: "your-customer-id"
  gatewayUrl: "https://gateway.qg1.apps.qualys.com"
  clusterInfoArgs:
    cloudProvider: "AWS"           # Automatically selects qagent_bottlerocket

hostsensor:
  enabled: true
  qualys:
    args:
      activationId: "HOST_SENSOR_ACTIVATION_ID"  # Different from global.activationId
      logLevel: "3"
    # image.repository is auto-selected based on cloudProvider
    # Override only if you need a specific image:
    # image:
    #   repository: "qualys/custom-image"
    #   tag: "latest"
```

**For OpenShift:**
```yaml
global:
  customerId: "your-customer-id"
  openshift: true                  # Automatically selects qualys/qagent-rhcos
  gatewayUrl: "https://gateway.qg1.apps.qualys.com"
  clusterInfoArgs:
    cloudProvider: "AWS"           # Or any provider, openshift flag determines image

hostsensor:
  enabled: true
  qualys:
    args:
      activationId: "HOST_SENSOR_ACTIVATION_ID"
```

**Supported Cloud Providers for Host Sensor:**
- `AWS` - Amazon Web Services → `qualys/qagent_bottlerocket`
- `GCP` - Google Cloud Platform → `qualys/qagent_googlecos`
- OpenShift (`global.openshift: true`) → `qualys/qagent-rhcos`

**Note:** Azure, OCI, and SELF_MANAGED_K8S are supported for cluster sensors but NOT for host sensor. If you enable hostsensor with these providers, deployment will fail with a clear error message.

**Value Inheritance:**
- `customerId`: Inherits from `global.customerId`
- `image.repository`: Automatically selected from `global.cloudProvider` or `global.openshift`
- `providerName`: Auto-derived from `global.cloudProvider` or `global.openshift` (AWS/GCP/COREOS)
- `serverUri`: Inherits from `global.gatewayUrl`
- `activationId`: Must be explicitly set (different from cluster sensors)

### Cluster Sensor

Discovers and monitors Kubernetes cluster resources:

```yaml
qualysTc:
  enabled: true
  clusterSensor:
    enabled: true
```

Requires `global.clusterInfoArgs.cloudProvider` to be set.

### Runtime Sensor

Monitors container runtime behavior:

```yaml
qualysTc:
  enabled: true
  runtimeSensor:
    enabled: true
```

### General Sensor

Scans container images for vulnerabilities:

```yaml
qualysTc:
  enabled: true
  qcsSensor:
    enabled: true
    qualys:
      args:
        concurrentScan: "5"  # Range: 1-20
```

### Admission Controller

Controls which images can be deployed:

```yaml
qualysTc:
  enabled: true
  admissionController:
    enabled: true
```

## Cloud Provider Configuration

### AWS

```yaml
global:
  clusterInfoArgs:
    cloudProvider: "AWS"
    AWS:
      arn: "arn:aws:eks:region:account-id:cluster/cluster-name"

hostsensor:
  enabled: true
  qualys:
    args:
      activationId: "host-activation-id"
  # Image automatically selected: qualys/qagent_bottlerocket
```

### Azure

```yaml
global:
  clusterInfoArgs:
    cloudProvider: "AZURE"
    AZURE:
      id: "your-cluster-id"
      region: "eastus"

hostsensor:
  enabled: false  # Azure not supported for host sensor
```

### Google Cloud Platform (GCP)

```yaml
global:
  clusterInfoArgs:
    cloudProvider: "GCP"
    GCP:
      krn: "krn:qgcp:project-id:region:cluster-name"

hostsensor:
  enabled: true
  qualys:
    args:
      activationId: "host-activation-id"
  # Image automatically selected: qualys/qagent_googlecos
```

### Self-Managed Kubernetes

```yaml
global:
  clusterInfoArgs:
    cloudProvider: "SELF_MANAGED_K8S"
    SELF_MANAGED_K8S:
      clusterName: "my-cluster"

hostsensor:
  enabled: false  # Not supported for SELF_MANAGED_K8S
```

## Deployment Scenarios

### Scenario 1: Complete Security Stack (AWS)

Deploy all sensors for comprehensive coverage:

```yaml
global:
  customerId: "ABC12345"
  activationId: "container-sensor-activation"
  qualysPod: "US2"  # Auto-fills gatewayUrl and cmsqagPublicUrl
  clusterInfoArgs:
    cloudProvider: "AWS"
    AWS:
      arn: "arn:aws:eks:us-east-1:123456789:cluster/prod-cluster"

hostsensor:
  enabled: true
  qualys:
    args:
      activationId: "host-sensor-activation"
  # Image: qualys/qagent_bottlerocket (auto-selected)

qualysTc:
  enabled: true
  clusterSensor:
    enabled: true
  runtimeSensor:
    enabled: true
  qcsSensor:
    enabled: true
  admissionController:
    enabled: true
```

### Scenario 2: Host Scanning Only

Deploy only the host sensor:

```yaml
global:
  customerId: "ABC12345"
  qualysPod: "EU1"  # Auto-fills gatewayUrl and cmsqagPublicUrl
  cloudProvider: "GCP"

hostsensor:
  enabled: true
  qualys:
    args:
      activationId: "host-sensor-activation"
  # Image: qualys/qagent_googlecos (auto-selected)

qualysTc:
  enabled: false
```

### Scenario 3: Container Image Scanning (GCP)

Deploy cluster and general sensors for image vulnerability scanning:

```yaml
global:
  customerId: "ABC12345"
  activationId: "container-sensor-activation"
  qualysPod: "EU1"  # Auto-fills gatewayUrl and cmsqagPublicUrl
  clusterInfoArgs:
    cloudProvider: "GCP"
    GCP:
      krn: "krn:qgcp:my-project:us-central1:my-cluster"

hostsensor:
  enabled: false

qualysTc:
  enabled: true
  clusterSensor:
    enabled: true
  qcsSensor:
    enabled: true
    qualys:
      args:
        concurrentScan: "10"
```

### Scenario 4: Runtime Protection (Azure)

Focus on runtime security monitoring:

```yaml
global:
  customerId: "ABC12345"
  activationId: "container-sensor-activation"
  qualysPod: "US2"  # Auto-fills gatewayUrl and cmsqagPublicUrl
  clusterInfoArgs:
    cloudProvider: "AZURE"
    AZURE:
      id: "cluster-resource-id"
      region: "eastus"

hostsensor:
  enabled: false  # Azure not supported for host sensor

qualysTc:
  enabled: true
  clusterSensor:
    enabled: true
  runtimeSensor:
    enabled: true
```

## OpenShift Configuration

For OpenShift clusters, enable the OpenShift flag:

```yaml
global:
  openshift: true

hostsensor:
  openshift: true
```

## Proxy Configuration

If your cluster requires a proxy to reach Qualys Cloud:

```yaml
global:
  proxy:
    value: "proxy.example.com:8080"
    certificate: "base64-encoded-ca-cert"
    skipVerifyTLS: false
```

## GKE Autopilot

For GKE Autopilot clusters:

```yaml
global:
  gkeAutopilot:
    enabled: true
    allowlistLabelForQcsSensor: "autopilot.gke.io/workload-type=system"
```

## Verification

After installation, verify your sensors are running:

```bash
# Check all Qualys pods
kubectl get pods -n qualys

# Check DaemonSet (host-based sensor)
kubectl get daemonset -n qualys

# Check Deployments (other sensors)
kubectl get deployments -n qualys

# View sensor logs
kubectl logs -n qualys -l app=qualys --tail=100
```

## Upgrading

To upgrade the chart with new values:

```bash
helm upgrade qualys-sensors qualys-helm-chart/qualys-unified \
  -f my-values.yaml \
  -n qualys
```

## Uninstallation

To remove all Qualys sensors:

```bash
helm uninstall qualys-sensors -n qualys
```

## Troubleshooting

### Pods not starting

1. Check if credentials are correct:
   ```bash
   kubectl get pods -n qualys
   kubectl logs -n qualys <pod-name>
   ```

2. Verify cloud provider configuration matches your cluster

3. Ensure namespace exists:
   ```bash
   kubectl create namespace qualys
   ```

### Host sensor failing

- Verify `providerName` is one of: AWS, GCP, COREOS
- Check if the sensor has host access (hostNetwork, hostPID, hostIPC)
- Review DaemonSet status:
  ```bash
  kubectl describe daemonset -n qualys qualys-cloud-agent
  ```

### Cluster sensor not reporting

- Verify `global.clusterInfoArgs.cloudProvider` is set correctly
- Check the cluster ARN/ID matches your cloud provider format
- Review sensor logs for authentication errors

## Support

For support and documentation:
- Qualys Documentation: https://docs.qualys.com/
- Helm Chart Repository: https://github.com/Qualys/Qualys-Helm-Charts

## Version Information

- Chart Version: 1.0.0
- qualys-tc: 2.6.1
- lxag_container_agent: 1.0.0
- qcs-sensor: 1.19.0
