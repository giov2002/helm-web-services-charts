{{- define "monitoring.fullname" -}}
{{- /*
Le nom complet d’une ressource Helm. Pour éviter les conflits de noms,
ce nom combine le nom de la release et tronque à 63 caractères si
nécessaire. */ -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "monitoring.labels" -}}
{{- /*
Jeu standard de labels appliqué aux ressources. Ces labels sont utilisés
pour la sélection des pods et permettent de suivre l’origine du chart.
*/ -}}
app.kubernetes.io/name: {{ include "monitoring.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version | replace "+" "_" }}
{{- end -}}