set -euo pipefail

_set_v() {
  cat - | awk '{ print "'"$1"'="$0}' | tee -a $GITHUB_ENV | echo "::debug::$(cat -)"
}

_mask() {
  echo "::debug::masking value of $2"
  echo "::add-mask::${!1}"
}

_param() {
  local P
  local V
  P="$(aws ssm get-parameter --with-decryption --name "$1")"
  V="$(echo "$P" | jq -r '.Parameter.Value')"
  eval "$(echo "$P" | jq -r '.Parameter |
  if .Type == "SecureString" then "_mask V '"$2"'"
  else "echo -n"
  end')"
  echo "$V" | _set_v $2
}

_secret() {
  local SEC
  local CMD
  SEC="$(aws secretsmanager get-secret-value --secret-id $1 | jq -r .SecretString)"
  _mask SEC "$2"
  echo "$SEC" | _set_v $2
}

eval "$(echo "$PARAMS" | docker run -i --rm ghcr.io/itchyny/gojq -r --yaml-input '
to_entries[] | "_param \(.value) \(.key)"
')"

eval "$(echo "$SECRETS" | docker run -i --rm ghcr.io/itchyny/gojq -r --yaml-input '
to_entries[] | "_secret \(.value) \(.key)"
')"
