{{/*
Expand the name of the chart.
*/}}
{{- define "qualys-unified.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "qualys-unified.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "qualys-unified.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "qualys-unified.labels" -}}
helm.sh/chart: {{ include "qualys-unified.chart" . }}
{{ include "qualys-unified.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "qualys-unified.selectorLabels" -}}
app.kubernetes.io/name: {{ include "qualys-unified.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Get host sensor provider name (derived from cloud provider)
*/}}
{{- define "qualys-unified.hostsensorProviderName" -}}
{{- $openshift := .Values.global.openshift | default false -}}
{{- $cloudProvider := .Values.global.cloudProvider -}}
{{- $override := .Values.hostsensor.qualys.args.providerName | default "" -}}
{{- if and $override (ne $override "") -}}
  {{- $override -}}
{{- else if $openshift -}}
  COREOS
{{- else if eq $cloudProvider "AWS" -}}
  AWS
{{- else if eq $cloudProvider "GCP" -}}
  GCP
{{- else -}}
  {{- fail (printf "Host sensor is not supported for cloud provider: %s. Supported providers: AWS, GCP, or OpenShift (COREOS)" $cloudProvider) -}}
{{- end -}}
{{- end -}}

{{/*
Get host sensor image repository (auto-selected based on provider)
*/}}
{{- define "qualys-unified.hostsensorImageRepository" -}}
{{- $override := .Values.hostsensor.qualys.image.repository | default "" -}}
{{- if and $override (ne $override "") -}}
  {{- $override -}}
{{- else -}}
  {{- $providerName := include "qualys-unified.hostsensorProviderName" . -}}
  {{- if eq $providerName "COREOS" -}}
    qualys/qagent-rhcos
  {{- else if eq $providerName "AWS" -}}
    qualys/qagent_bottlerocket
  {{- else if eq $providerName "GCP" -}}
    qualys/qagent_googlecos
  {{- else -}}
    {{- fail (printf "Cannot determine host sensor image for provider: %s" $providerName) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get Qualys Gateway URL based on qualysPod identifier
*/}}
{{- define "qualys-unified.gatewayUrl" -}}
{{- $override := .Values.global.gatewayUrl | default "" -}}
{{- if and $override (ne $override "") -}}
  {{- $override -}}
{{- else if .Values.global.qualysPod -}}
  {{- $pod := .Values.global.qualysPod | upper -}}
  {{- if eq $pod "US1" -}}
    https://gateway.qg1.apps.qualys.com
  {{- else if eq $pod "US2" -}}
    https://gateway.qg2.apps.qualys.com
  {{- else if eq $pod "US3" -}}
    https://gateway.qg3.apps.qualys.com
  {{- else if eq $pod "US4" -}}
    https://gateway.qg4.apps.qualys.com
  {{- else if eq $pod "GOV1" -}}
    https://gateway.gov1.qualys.us
  {{- else if eq $pod "EU1" -}}
    https://gateway.qg1.apps.qualys.eu
  {{- else if eq $pod "EU2" -}}
    https://gateway.qg2.apps.qualys.eu
  {{- else if eq $pod "EU3" -}}
    https://gateway.qg3.apps.qualys.it
  {{- else if eq $pod "IN1" -}}
    https://gateway.qg1.apps.qualys.in
  {{- else if eq $pod "CA1" -}}
    https://gateway.qg1.apps.qualys.ca
  {{- else if eq $pod "AE1" -}}
    https://gateway.qg1.apps.qualys.ae
  {{- else if eq $pod "UK1" -}}
    https://gateway.qg1.apps.qualys.co.uk
  {{- else if eq $pod "AU1" -}}
    https://gateway.qg1.apps.qualys.com.au
  {{- else if eq $pod "KSA1" -}}
    https://gateway.qg1.apps.qualysksa.com
  {{- else -}}
    {{- fail (printf "Unknown qualysPod '%s'. Supported: US1, US2, US3, US4, GOV1, EU1, EU2, EU3, IN1, CA1, AE1, UK1, AU1, KSA1" $pod) -}}
  {{- end -}}
{{- else -}}
  {{- fail "Either global.qualysPod or global.gatewayUrl must be specified" -}}
{{- end -}}
{{- end -}}

{{/*
Get Qualys CMS Public URL based on qualysPod identifier
*/}}
{{- define "qualys-unified.cmsqagPublicUrl" -}}
{{- $override := .Values.global.cmsqagPublicUrl | default "" -}}
{{- if and $override (ne $override "") -}}
  {{- $override -}}
{{- else if .Values.global.qualysPod -}}
  {{- $pod := .Values.global.qualysPod | upper -}}
  {{- if eq $pod "US1" -}}
    https://cmsqagpublic.qg1.apps.qualys.com/ContainerSensor
  {{- else if eq $pod "US2" -}}
    https://cmsqagpublic.qg2.apps.qualys.com/ContainerSensor
  {{- else if eq $pod "US3" -}}
    https://cmsqagpublic.qg3.apps.qualys.com/ContainerSensor
  {{- else if eq $pod "US4" -}}
    https://cmsqagpublic.qg4.apps.qualys.com/ContainerSensor
  {{- else if eq $pod "GOV1" -}}
    https://cmsqagpublic.gov1.qualys.us/ContainerSensor
  {{- else if eq $pod "EU1" -}}
    https://cmsqagpublic.qg1.apps.qualys.eu/ContainerSensor
  {{- else if eq $pod "EU2" -}}
    https://cmsqagpublic.qg2.apps.qualys.eu/ContainerSensor
  {{- else if eq $pod "EU3" -}}
    https://cmsqagpublic.qg3.apps.qualys.it/ContainerSensor
  {{- else if eq $pod "IN1" -}}
    https://cmsqagpublic.qg1.apps.qualys.in/ContainerSensor
  {{- else if eq $pod "CA1" -}}
    https://cmsqagpublic.qg1.apps.qualys.ca/ContainerSensor
  {{- else if eq $pod "AE1" -}}
    https://cmsqagpublic.qg1.apps.qualys.ae/ContainerSensor
  {{- else if eq $pod "UK1" -}}
    https://cmsqagpublic.qg1.apps.qualys.co.uk/ContainerSensor
  {{- else if eq $pod "AU1" -}}
    https://cmsqagpublic.qg1.apps.qualys.com.au/ContainerSensor
  {{- else if eq $pod "KSA1" -}}
    https://cmsqagpublic.qg1.apps.qualysksa.com/ContainerSensor
  {{- else -}}
    {{- fail (printf "Unknown qualysPod '%s'. Supported: US1, US2, US3, US4, GOV1, EU1, EU2, EU3, IN1, CA1, AE1, UK1, AU1, KSA1" $pod) -}}
  {{- end -}}
{{- else -}}
  {{- fail "Either global.qualysPod or global.cmsqagPublicUrl must be specified" -}}
{{- end -}}
{{- end -}}

{{/*
Validate required values
*/}}
{{- define "qualys-unified.validateValues" -}}
{{- if or .Values.hostsensor.enabled .Values.qualysTc.enabled -}}
  {{- if not .Values.global.customerId -}}
    {{- fail "global.customerId is required when any sensor is enabled" -}}
  {{- end -}}
  {{- if and (not .Values.global.qualysPod) (not .Values.global.gatewayUrl) -}}
    {{- fail "Either global.qualysPod (e.g., 'US2') or global.gatewayUrl must be specified" -}}
  {{- end -}}
{{- end -}}

{{- if .Values.hostsensor.enabled -}}
  {{- if not .Values.hostsensor.qualys.args.activationId -}}
    {{- fail "hostsensor.qualys.args.activationId is required when hostsensor is enabled" -}}
  {{- end -}}
  {{- if not .Values.global.cloudProvider -}}
    {{- fail "global.cloudProvider is required when hostsensor is enabled" -}}
  {{- end -}}
  {{- $cloudProvider := .Values.global.cloudProvider -}}
  {{- $openshift := .Values.global.openshift | default false -}}
  {{- if and (not $openshift) (not (has $cloudProvider (list "AWS" "GCP"))) -}}
    {{- fail (printf "Host sensor is not supported for cloud provider '%s'. Supported: AWS, GCP, or OpenShift (set global.openshift=true)" $cloudProvider) -}}
  {{- end -}}
{{- end -}}

{{- if .Values.qualysTc.enabled -}}
  {{- if not .Values.global.activationId -}}
    {{- fail "global.activationId is required when qualysTc (cluster/runtime/general sensors) is enabled" -}}
  {{- end -}}
  {{- if not .Values.global.cloudProvider -}}
    {{- fail "global.cloudProvider is required when qualysTc is enabled" -}}
  {{- end -}}
{{- end -}}
{{- end -}}
