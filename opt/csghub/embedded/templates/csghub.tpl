{{- define "config.csghub" -}}
  {{- $csghub := (datasource "config").csghub -}}
  {{- $url := conv.URL $csghub.external_url -}}
  {{- $urlParts := $url.Host | strings.Split ":" -}}
  {{- $host := index $urlParts 0 | default "csghub.example.com" -}}
  {{- $port := "" -}}
  {{- if gt (len $urlParts) 1 -}}
    {{- $port = index $urlParts 1 -}}
  {{- else -}}
    {{- if eq $url.Scheme "https" -}}
      {{- $port = "443" -}}
    {{- else -}}
      {{- $port = "80" -}}
    {{- end -}}
  {{- end -}}

  {{- $result := coll.Dict
    "external" $csghub.external_url
    "scheme" $url.Scheme
    "host" $host
    "port" $port
  -}}
  {{- $result | data.ToYAML -}}
{{- end -}}

{{- define "domain.root" -}}
  {{- $rootDomain := "example.com" }}
  {{- $csghub := tmpl.Exec "config.csghub" . | data.YAML -}}

  {{- if and $csghub.host (regexp.Match `^[a-zA-Z0-9.-]+$` $csghub.host) }}
    {{- $hostParts := strings.Split "." $csghub.host }}
    {{- if le (len $hostParts) 2 }}
      {{- $rootDomain = $csghub.host }}
    {{- else }}
      {{- $rootDomain = regexp.Replace "^[^.]+\\." "" $csghub.host }}
    {{- end }}
  {{- end }}
  {{- $rootDomain -}}
{{- end -}}