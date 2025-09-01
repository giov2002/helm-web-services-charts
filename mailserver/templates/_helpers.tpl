{{/*
Expand the name of the chart.
*/}}
{{- define "mailstack.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "mailstack.fullname" -}}
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
{{- define "mailstack.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "mailstack.labels" -}}
helm.sh/chart: {{ include "mailstack.chart" . }}
{{ include "mailstack.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "mailstack.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mailstack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Mailserver labels
*/}}
{{- define "mailstack.mailserver.labels" -}}
helm.sh/chart: {{ include "mailstack.chart" . }}
{{ include "mailstack.mailserver.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: mailserver
{{- end }}

{{/*
Mailserver selector labels
*/}}
{{- define "mailstack.mailserver.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mailstack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
app: mailserver
{{- end }}

{{/*
Roundcube labels
*/}}
{{- define "mailstack.roundcube.labels" -}}
helm.sh/chart: {{ include "mailstack.chart" . }}
{{ include "mailstack.roundcube.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/component: roundcube
{{- end }}

{{/*
Roundcube selector labels
*/}}
{{- define "mailstack.roundcube.selectorLabels" -}}
app.kubernetes.io/name: {{ include "mailstack.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Generate the postfix accounts configuration
*/}}
{{- define "mailstack.postfix.accounts" -}}
{{- range .Values.mailserver.accounts }}
{{ .email }}|{PLAIN}{{ .password }}
{{- end }}
{{- end }}

{{/*
Generate the postfix aliases configuration
*/}}
{{- define "mailstack.postfix.aliases" -}}
{{- range .Values.mailserver.aliases }}
{{ .alias }} {{ .target }}
{{- end }}
{{- end }}
