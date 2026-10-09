# Service clients for the SCIM protected resource.
#
# SCIM is called server-to-server by the issuer, verifier and portal. Each is a
# confidential OAuth client here, using the client_credentials grant to get a
# PingFederate access token; SCIM validates that JWT (ES256 against PF's JWKS)
# and checks the client_id is one of these three. This replaces the single
# shared static bearer the SCIM service used before.
#
# No redirect URIs, no user login, no scope catalog: client_credentials is
# machine-to-machine, and SCIM authorises on client_id, not scope. (Add
# scim.read/scim.write here later if finer control is wanted.)

variable "issuer_svc_secret" {
  description = "The issuer-svc client's secret. No default: a committed one is a secret everybody has."
  type        = string
  sensitive   = true
}
variable "verifier_svc_secret" {
  description = "The verifier-svc client's secret. No default: a committed one is a secret everybody has."
  type        = string
  sensitive   = true
}
variable "portal_svc_secret" {
  description = "The portal-svc client's secret. No default: a committed one is a secret everybody has."
  type        = string
  sensitive   = true
}

locals {
  scim_service_clients = {
    "issuer-svc"   = { name = "Issuer → SCIM", secret = var.issuer_svc_secret }
    "verifier-svc" = { name = "Verifier → SCIM", secret = var.verifier_svc_secret }
    "portal-svc"   = { name = "Portal → SCIM", secret = var.portal_svc_secret }
  }
}

resource "pingfederate_oauth_client" "scim_service" {
  for_each = local.scim_service_clients

  client_id = each.key
  name      = each.value.name
  enabled   = true

  grant_types = ["CLIENT_CREDENTIALS"]

  client_auth = {
    type   = "SECRET"
    secret = each.value.secret
  }

  bypass_approval_page             = true
  default_access_token_manager_ref = { id = pingfederate_oauth_access_token_manager.jwtatm.id }
}
