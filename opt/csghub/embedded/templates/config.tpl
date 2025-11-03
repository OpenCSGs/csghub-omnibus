{{- define "config.casdoor.conn" -}}
  {{- $config := (datasource "config") -}}
  {{- $csghub := $config.csghub }}
  {{- $url := conv.URL $csghub.external_url -}}
  {{- $host := (index (strings.Split ":" $url.Host) 0) | default "csghub.example.com" -}}

  {{- $casdoor := $config.casdoor }}
  {{- $casdoorParts := strings.Split ":" $casdoor.listen -}}
  {{- $casdoorHost := index $casdoorParts 0 | default "127.0.0.1" -}}
  {{- $casdoorPort := index $casdoorParts 1 | default "8000" -}}

  {{- if eq $casdoorHost "127.0.0.1" -}}
    {{- $casdoorHost = $host -}}
  {{- end -}}

  {{- $result := coll.Dict "scheme" $url.Scheme "host" $casdoorHost "port" $casdoorPort -}}
  {{- $result | data.ToYAML -}}
{{- end -}}

{{- define "endpoint.casdoor" -}}
  {{- $casdoor := tmpl.Exec "config.casdoor.conn" . | data.YAML -}}
  {{- printf "%s://%s:%v" $casdoor.scheme $casdoor.host $casdoor.port -}}
{{- end -}}

{{- define "config.casdoor.db" -}}
  {{- $casdoor := (datasource "config").casdoor }}
  {{- $db := $casdoor.postgresql -}}
  {{- $config := coll.Dict
    "dbname"   ( $db.dbname | default "csghub_casdoor" )
    "host"     ( $db.host | default "127.0.0.1" )
    "port"     ( $db.port | default 5432 )
    "user"     ( $db.user | default "csghub" )
    "password" ( $db.password | default (crypto.PBKDF2 ($db.user | default "csghub") "opencsg" 2048 8) )
  -}}

  {{- $config | data.ToYAML -}}
{{- end -}}

{{- define "config.casdoor.db.dsn" -}}
{{- $config := tmpl.Exec "config.casdoor.db" . | data.YAML -}}
{{- printf "postgresql://%s:%s@%s:%v/%s?sslmode=disable" $config.user $config.password $config.host $config.port $config.dbname -}}
{{- end -}}