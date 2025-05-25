{{/* Full name: <release>-<chart> lowercase */}}
{{- define "awslab.fullname" -}}
{{- printf "%s-%s" .Release.Name .Chart.Name | trunc 63 | trimSuffix "-" | lower -}}
{{- end }}

{{/* Common labels for all resources */}}
{{- define "awslab.labels" -}}
app.kubernetes.io/name: {{ include "awslab.fullname" . }}
helm.sh/chart: {{ .Chart.Name }}-{{ .Chart.Version }}
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: Helm
{{- end }}

{{/* Selector labels for Deployment/ReplicaSet */}}
{{- define "awslab.selectorLabels" -}}
app.kubernetes.io/name: {{ include "awslab.fullname" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}
