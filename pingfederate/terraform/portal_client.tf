# The holder portal's sign-in client (G-92).
#
# The portal signed people in with Apple itself and filed them in the identity
# store as `apple:<sub>`; PingFederate names the same person by the bare sub, so
# the issuer never found a holder the portal onboarded. And the portal reached
# the store with a service token that could read and write every holder's
# documents. Now the portal is a confidential OIDC client of PingFederate:
# authorization code with PKCE, and refresh tokens because the jwtatm access
# token lives two minutes. PingFederate authenticates the holder where it
# authenticates the wallet's user - Apple when apple_login is on (apple.tf), the
# HTML form otherwise (main.tf, byOAuthClient) - and names them. The portal files them under that name and reaches the store
# with the holder's own access token, which the store holds to that holder: the
# scim service lists `portal` in PF_ALLOWED_CLIENTS and SCIM_USER_CLIENTS.
#
# Created only when portal_client_secret is set, so an instance that has not
# moved its portal yet plans no change. The secret is the portal's
# PORTAL_CLIENT_SECRET; it never has a default here.

variable "portal_client_secret" {
  type        = string
  sensitive   = true
  default     = ""
  description = "The portal's PingFederate client secret (its PORTAL_CLIENT_SECRET). Empty: no portal client."

  validation {
    condition     = var.portal_client_secret == "" || length(var.portal_client_secret) >= 32
    error_message = "portal_client_secret must be at least 32 characters (openssl rand -base64 32)."
  }
}

variable "portal_redirect_uris" {
  type        = list(string)
  default     = []
  description = "The portal's sign-in callback, https://<portal>/auth/pf/callback. Required with portal_client_secret."
}

locals {
  portal_client_enabled = var.portal_client_secret != ""
}

resource "pingfederate_oauth_client" "portal" {
  count = local.portal_client_enabled ? 1 : 0

  client_id   = "portal"
  name        = "Holder portal"
  description = "Holder sign-in for the portal; its access tokens reach only the holder's own records in the identity store."
  enabled     = true

  grant_types = ["AUTHORIZATION_CODE", "REFRESH_TOKEN"]
  client_auth = {
    type   = "SECRET"
    secret = var.portal_client_secret
  }
  require_proof_key_for_code_exchange = true
  redirect_uris                       = var.portal_redirect_uris
  restricted_response_types           = ["code"]

  # The holder is signing in to their own records: no scope-approval page.
  bypass_approval_page = true
  # By reference, not the literal "jwtatm": on an empty PingFederate a literal
  # id gives Terraform no ordering, and the client is created before its manager.
  default_access_token_manager_ref = { id = pingfederate_oauth_access_token_manager.jwtatm.id }

  lifecycle {
    precondition {
      condition     = length(var.portal_redirect_uris) > 0 && alltrue([for u in var.portal_redirect_uris : startswith(u, "https://") && endswith(u, "/auth/pf/callback")])
      error_message = "portal_redirect_uris must name the portal's https://<portal>/auth/pf/callback."
    }
  }
}
