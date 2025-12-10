{{- define "postgresql.fullname" -}}
{{- if .Values.nameOverride }}
{{- .Values.nameOverride }}
{{- else }}
{{- printf "%s" .Chart.Name }}
{{- end -}}
{{- end -}}
