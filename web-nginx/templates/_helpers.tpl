{{- define "web-nginx.fullname" -}}
{{ .Release.Name }}-{{ .Chart.Name }}
{{- end }}

{{- define "web-nginx.name" -}}
{{ .Chart.Name }}
{{- end }}
