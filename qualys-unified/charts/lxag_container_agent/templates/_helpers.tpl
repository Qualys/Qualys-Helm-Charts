{{/*
Expand the name of the chart.
*/}}
{{- define "lxagent.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "lxagent.fullname" -}}
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
{{- define "lxagent.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "lxagent.labels" -}}
helm.sh/chart: {{ include "lxagent.chart" . }}
{{ include "lxagent.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "lxagent.selectorLabels" -}}
app.kubernetes.io/name: {{ include "lxagent.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "lxagent.serviceAccountName" -}}
{{- if .Values.serviceAccount.create }}
{{- default (include "lxagent.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Get host sensor provider name (derived from cloud provider via global values)
*/}}
{{- define "lxagent.providerName" -}}
{{- $override := .Values.qualys.args.providerName | default "" -}}
{{- if and $override (ne $override "") -}}
  {{- $override -}}
{{- else -}}
  {{- $openshift := .Values.global.openshift | default false -}}
  {{- $cloudProvider := .Values.global.cloudProvider -}}
  {{- if $openshift -}}
    COREOS
  {{- else if eq $cloudProvider "AWS" -}}
    AWS
  {{- else if eq $cloudProvider "GCP" -}}
    GCP
  {{- else -}}
    {{- fail (printf "Host sensor is not supported for cloud provider: %s. Supported providers: AWS, GCP, or OpenShift (set global.openshift=true)" $cloudProvider) -}}
  {{- end -}}
{{- end -}}
{{- end -}}

{{/*
Get host sensor image repository (auto-selected based on provider)
*/}}
{{- define "lxagent.imageRepository" -}}
{{- $override := .Values.qualys.image.repository | default "" -}}
{{- if and $override (ne $override "") -}}
  {{- $override -}}
{{- else -}}
  {{- $providerName := include "lxagent.providerName" . -}}
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
Get customer ID (with inheritance from global)
*/}}
{{- define "lxagent.customerId" -}}
{{- .Values.qualys.args.customerId | default .Values.global.customerId -}}
{{- end -}}

{{/*
Get server URI (with inheritance from global)
*/}}
{{- define "lxagent.serverUri" -}}
{{- .Values.qualys.args.serverUri | default .Values.global.gatewayUrl -}}
{{- end -}}
