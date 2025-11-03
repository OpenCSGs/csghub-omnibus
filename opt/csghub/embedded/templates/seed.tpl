# Generate or retrieve a persistent random seed used for cryptographic operations.
# The seed is stored in /opt/csghub/etc/csghub/.seed to ensure consistency across runs.
{{- define "GenSeed" -}}
  {{- $seedFile := "/opt/csghub/etc/csghub/.seed" -}}
  {{- $seed := "" -}}
  {{- if file.Exists $seedFile -}}
    {{- $seed = file.Read $seedFile -}}
  {{- end -}}
  {{- if not $seed -}}
    {{- $seed = random.Alpha 48 -}}
    {{- file.Write $seedFile $seed -}}
  {{- end -}}
  {{- $seed -}}
{{- end -}}

# Generate a deterministic Hub API token based on a PBKDF2 hash.
# The token is derived using the static string "opencsg" as the password,
# the persistent seed as the salt, and a key length of 64 bytes.
{{- define "GenHubApiToken" -}}
{{- crypto.PBKDF2 "opencsg" (tmpl.Exec "GenSeed" .) 1024 64 -}}
{{- end }}

# Generate a deterministic Client ID using the seed and input context.
# The ID is a SHA256 hash truncated to 20 characters.
{{- define "GenClientId" -}}
  {{- printf "%s%s" (tmpl.Exec "GenSeed" .) . | crypto.SHA256 | strings.Trunc 20 -}}
{{- end -}}

# Generate a deterministic Client Secret using the seed and input context.
# The secret is derived from the SHA256 hash with the first 24 characters removed.
{{- define "GenClientSecret" -}}
  {{- printf "%s%s" (tmpl.Exec "GenSeed" .) . | crypto.SHA256 | regexp.Replace "^.{24}" "" -}}
{{- end -}}