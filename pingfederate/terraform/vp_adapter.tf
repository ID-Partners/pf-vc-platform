# Sign in with your wallet: the IdP adapter (design/pf-servlets.md §2.1) that
# main.tf's SignInWithWallet tree sends every relying party to. The jar
# (pf.plugins.pf-vp-adapter.jar, au.idp.pf.vpadapter.VpAdapter) is baked into the
# PF image by scripts/stage-pf.sh.
#
# It opens each presentation as a session on pf-oid4vp, which requires a client
# token carrying the session scope (PF_OID4VP_SESSION_SCOPE, vc:verify): the
# adapter is the vp-wallet-login client below, and its secret has no default.

variable "vp_wallet_login_secret" {
  description = "Secret of the vp-wallet-login client the wallet-login adapter opens verifier sessions as."
  type        = string
  sensitive   = true
}

resource "pingfederate_oauth_client" "vp_wallet_login" {
  client_id   = "vp-wallet-login"
  name        = "Wallet login adapter -> verifier sessions"
  enabled     = true
  grant_types = ["CLIENT_CREDENTIALS"]

  client_auth = {
    type   = "SECRET"
    secret = var.vp_wallet_login_secret
  }

  restrict_scopes                  = true
  restricted_scopes                = ["vc:verify"]
  bypass_approval_page             = true
  default_access_token_manager_ref = { id = pingfederate_oauth_access_token_manager.jwtatm.id }

  depends_on = [pingfederate_oauth_server_settings.this] # vc:verify is declared there
}

resource "pingfederate_idp_adapter" "vp_wallet_login" {
  adapter_id = "vpWalletLogin"
  name       = "VC Wallet Login"

  plugin_descriptor_ref = {
    id = "au.idp.pf.vpadapter.VpAdapter"
  }

  configuration = {
    tables = []
    fields = [
      { name = "Credential", value = "pid" },
      { name = "Client ID", value = pingfederate_oauth_client.vp_wallet_login.client_id },
      { name = "Session Scope", value = "vc:verify" },
    ]
    sensitive_fields = [
      { name = "Client Secret", value = var.vp_wallet_login_secret },
    ]
  }

  # Matches VpAdapterLogic.CONTRACT exactly (pf-ext/pf-vp-adapter) — PF requires
  # every declared contract attribute to be fulfilled below.
  attribute_contract = {
    core_attributes = [
      { name = "given_name" },
      # PF requires exactly one contract attribute flagged as the pseudonym
      # (its subject/SLO identifier); the adapter's real subject comes from
      # AuthnAdapterResponse.setUsername(), so this flag is a form-validation
      # requirement rather than a functional one — family_name is always
      # populated (default "" — see VpAdapterLogic.extractAttributes).
      { name = "family_name", pseudonym = true },
      { name = "birthdate" },
      { name = "document_number" },
      { name = "credential_format" },
    ]
  }

  attribute_mapping = {
    attribute_contract_fulfillment = {
      "given_name"        = { source = { type = "ADAPTER" }, value = "given_name" }
      "family_name"       = { source = { type = "ADAPTER" }, value = "family_name" }
      "birthdate"          = { source = { type = "ADAPTER" }, value = "birthdate" }
      "document_number"    = { source = { type = "ADAPTER" }, value = "document_number" }
      "credential_format"  = { source = { type = "ADAPTER" }, value = "credential_format" }
    }
  }
}
