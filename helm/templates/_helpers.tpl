{{- define "vprofile-chart.name" -}}
vprofile
{{- end }}

{{- define "vprofile-chart.fullname" -}}
{{ include "vprofile-chart.name" . }}-{{ .Release.Name }}
{{- end }}