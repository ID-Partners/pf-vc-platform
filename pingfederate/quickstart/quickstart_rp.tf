# QUICKSTART ONLY (see quickstart_holder.tf).
#
# quickstart-rp: the relying party the end-to-end check plays (scripts/stack-e2e.sh).
# It opens verifier sessions with a client_credentials token carrying vc:verify
# (pf-oid4vp requires one), and signs a holder in with their wallet through the
# authorization-code flow - every client the form login does not take falls
# through to main.tf's SignInWithWallet tree. Its return page is never loaded:
# the script reads the code off the redirect, so the URL is a .invalid one.

variable "quickstart_rp_secret" {
  description = "The quickstart relying party's client secret (stack-up.sh mints it into .compose/secrets.json)."
  type        = string
  sensitive   = true
}

resource "pingfederate_oauth_client" "quickstart_rp" {
  client_id     = "quickstart-rp"
  name          = "Quickstart relying party"
  enabled       = true
  grant_types   = ["CLIENT_CREDENTIALS", "AUTHORIZATION_CODE"]
  redirect_uris = ["https://quickstart-rp.invalid/callback"]

  client_auth = {
    type   = "SECRET"
    secret = var.quickstart_rp_secret
  }

  require_proof_key_for_code_exchange = true
  restrict_scopes                     = true
  restricted_scopes                   = ["openid", "profile", "vc:verify"]
  bypass_approval_page                = true
  default_access_token_manager_ref    = { id = pingfederate_oauth_access_token_manager.jwtatm.id }

  depends_on = [pingfederate_oauth_server_settings.this]
}
