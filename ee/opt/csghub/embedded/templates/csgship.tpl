{{- define "config.csgship.frontend" -}}
  {{- $csgship := (datasource "config").csgship -}}
  {{- $csgshipFrontendListen := $csgship.listen.frontend -}}
  {{- $csgshipFrontendParts := $csgshipFrontendListen | strings.Split ":" -}}
  {{- $csgshipFrontendHost := index $csgshipFrontendParts 0 -}}

  {{- $csghub := tmpl.Exec "config.csghub" . | data.YAML -}}
  {{- if eq $csgshipFrontendHost "127.0.0.1" -}}
    {{- $csgshipFrontendHost = $csghub.host -}}
  {{- end -}}

  {{- $csgshipFrontendPort := "8001" -}}
  {{- if eq (len $csgshipFrontendParts) 2 -}}
     {{- $csgshipFrontendPort = index $csgshipFrontendParts 1 -}}
  {{- end }}

  {{- $result := coll.Dict "host" $csgshipFrontendHost "port" $csgshipFrontendPort -}}
  {{- $result | data.ToYAML -}}
{{- end }}

{{- define "endpoint.csgship.frontend" -}}
  {{- $csghub := tmpl.Exec "config.csghub" . | data.YAML -}}
  {{- $csgshipFrontend := tmpl.Exec "config.csgship.frontend" . | data.YAML -}}
  {{- printf "%s://%s:%v" $csghub.scheme $csghub.host $csgshipFrontend.port -}}
{{- end -}}

{{- define "config.csgship.api" -}}
  {{- $csgship := (datasource "config").csgship -}}
  {{- $csgshipApiListen := $csgship.listen.api -}}
  {{- $csgshipApiParts := $csgshipApiListen | strings.Split ":" -}}
  {{- $csgshipApiHost := index $csgshipApiParts 0 -}}

  {{- $csghub := tmpl.Exec "config.csghub" . | data.YAML -}}
  {{- if eq $csgshipApiHost "127.0.0.1" -}}
    {{- $csgshipApiHost = $csghub.host -}}
  {{- end -}}

  {{- $csgshipApiPort := "8002" -}}
  {{- if eq (len $csgshipApiParts) 2 -}}
    {{- $csgshipApiPort = index $csgshipApiParts 1 -}}
  {{- end }}

  {{- $result := coll.Dict "host" $csgshipApiHost "port" $csgshipApiPort -}}
  {{- $result | data.ToYAML -}}
{{- end -}}

{{- define "endpoint.csgship.api" -}}
  {{- $csghub := tmpl.Exec "config.csghub" . | data.YAML -}}
  {{- $csgshipApi := tmpl.Exec "config.csgship.api" . | data.YAML -}}
  {{- printf "%s://%s:%v" $csghub.scheme $csghub.host $csgshipApi.port -}}
{{- end -}}
