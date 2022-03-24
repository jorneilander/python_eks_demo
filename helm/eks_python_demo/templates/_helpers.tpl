{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "eks_python_demo.chart" -}}
{{ printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Expand the name of the chart.
*/}}
{{- define "eks_python_demo.name" -}}
{{ .Values.application.name | default .Chart.Name | trunc 63 | trimSuffix "-" }}
{{- end }}

{{- define "eks_python_demo.namespace" -}}
{{ .Values.overrides.namespace | default (printf "%s" (include "eks_python_demo.name" .)) }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "eks_python_demo.labels" -}}
helm.sh/chart: {{ include "eks_python_demo.chart" . }}
{{ include "eks_python_demo.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "eks_python_demo.selectorLabels" -}}
app.kubernetes.io/name: {{ include "eks_python_demo.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Image
*/}}
{{- define "eks_python_demo.image" -}}
{{ printf "%s:%s" (required  ".Values.image.repository is required" .Values.image.repository) (required ".Values.image.tag is required" .Values.image.tag) | quote }}
{{- end }}

{{/*
Application port
*/}}
{{- define "eks_python_demo.port" -}}
{{ .Values.application.port | default 80 }}
{{- end }}
