# PingFederate license, config-as-code.
#
# IMPORTANT: this provider sends `file_data` verbatim as the admin API's
# `fileData`, and PF requires it BASE64-encoded — so use filebase64(), NOT the
# file() shown in the provider docs (file() sends raw text and PF rejects it as
# license_invalid / 422).
#
# The .lic itself is gitignored (licenses aren't committed). Re-fetch a fresh
# Docker-deployment eval from the Ping DevOps license server into
# pingfederate.lic, then `terraform apply`:
#   curl -s https://license.pingidentity.com/devops/license \
#     -H "product: PingFederate" -H "version: 13.1" \
#     -H "devops-user: $PING_IDENTITY_DEVOPS_USER" -H "devops-key: $PING_IDENTITY_DEVOPS_KEY" \
#     -H "devops-app: pingfederate" -H "devops-purpose: get-license" -o pingfederate.lic
resource "pingfederate_license" "license" {
  file_data = filebase64("${path.module}/pingfederate.lic")
}
