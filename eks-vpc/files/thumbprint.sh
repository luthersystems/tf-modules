#/bin/bash

# This script comes from the following github issue:
#   https://github.com/terraform-providers/terraform-provider-aws/issues/10104

# Determine the platform specific command for "reversed cat"
TAC=tac
if ! which tac > /dev/null; then
  TAC="tail -r"
fi

THUMBPRINT=$(echo | \
    openssl s_client -servername oidc.eks.${1}.amazonaws.com -showcerts -connect oidc.eks.${1}.amazonaws.com:443 2>&- | \
    $TAC | \
    sed -n '/-----END CERTIFICATE-----/,/-----BEGIN CERTIFICATE-----/p; /-----BEGIN CERTIFICATE-----/q' | \
    $TAC | \
    openssl x509 -fingerprint -noout | \
    sed 's/://g' | awk -F= '{print tolower($2)}')

THUMBPRINT_JSON="{\"thumbprint\": \"${THUMBPRINT}\"}"

echo $THUMBPRINT_JSON
