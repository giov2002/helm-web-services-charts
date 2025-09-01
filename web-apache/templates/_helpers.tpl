{{- define "web-apache.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "web-apache.name" -}}
{{ .Chart.Name }}
{{- end }}
