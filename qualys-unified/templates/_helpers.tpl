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
Validate required values
*/}}
{{- define "qualys-unified.validateValues" -}}
{{- if or .Values.hostsensor.enabled .Values.qualysTc.enabled -}}
  {{- if not .Values.global.customerId -}}
    {{- fail "global.customerId is required when any sensor is enabled" -}}
  {{- end -}}
  {{- if not .Values.global.gatewayUrl -}}
    {{- fail "global.gatewayUrl is required when any sensor is enabled" -}}
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
