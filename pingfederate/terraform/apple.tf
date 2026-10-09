# Sign in with Apple as an external OIDC IdP that PingFederate (the SP/relying
# party) federates to. Wired into the authentication policy (main.tf) so the
# console + wallet OAuth clients authenticate via Apple.
#
# Apple's client secret is a short-lived ES256 JWT (<=6 months) — pass it via
# TF_VAR_apple_client_secret (regenerate with pingfederate/apple/gen-client-secret.mjs).

# Off unless apple_login is true. Apple sends a user back only to a return URL
# registered for the Services ID, so an instance whose PingFederate is not at one
# (docker-compose.yml's pf.localhost is not) cannot use it, and its wallet client
# logs in at the HTML form instead (main.tf, RouteByClient).
variable "apple_login" {
  description = "Wire Sign in with Apple into the authentication policy, ahead of the HTML form, for the wallet client."
  type        = bool
  default     = false
}

variable "apple_client_secret" {
  type      = string
  sensitive = true
  default   = "" # set via TF_VAR_apple_client_secret when applying Apple changes
}

resource "pingfederate_authentication_selector" "console_apple" {
  count       = var.apple_login ? 1 : 0
  selector_id = "issuerConsoleApple"
  name        = "Console + Wallet Apple"
  plugin_descriptor_ref = {
    id = "com.pingidentity.pf.selectors.oauthclient.OAuthClientAdapterSelector"
  }
  attribute_contract = { extended_attributes = null }
  configuration = {
    fields           = []
    sensitive_fields = []
    tables = [
      {
        name = "Clients"
        rows = concat([
          # issuer-console and verifier-console were rows here too; their clients
          # are gone (see main.tf, byOAuthClient), and PingFederate refuses a
          # selector naming a client it does not have.
          { default_row = false, sensitive_fields = [], fields = [{ name = "Client ID", value = pingfederate_oauth_client.wallet.client_id }] },
          ],
          # The holder portal signs in with Apple too (portal_client.tf, G-92) -
          # a row only once the client exists, since PingFederate refuses a
          # selector naming a client it does not have.
          local.portal_client_enabled ? [
            { default_row = false, sensitive_fields = [], fields = [{ name = "Client ID", value = pingfederate_oauth_client.portal[0].client_id }] },
          ] : [],
        )
      },
    ]
  }
}

resource "pingfederate_sp_idp_connection" "apple" {
  count         = var.apple_login ? 1 : 0
  active        = true
  connection_id = "EXvhFFjoxcfFty0n8qp0_Z5AU8P"
  entity_id     = "https://appleid.apple.com"
  base_url      = "https://appleid.apple.com"
  name          = "Sign in with Apple"
  logging_mode  = "STANDARD"

  additional_allowed_entities_configuration = {
    additional_allowed_entities = []
    allow_additional_entities   = false
    allow_all_entities          = false
  }

  oidc_client_credentials = {
    client_id     = "info.makefish.pf"
    client_secret = var.apple_client_secret
  }

  idp_browser_sso = {
    protocol             = "OIDC"
    idp_identity_mapping = "ACCOUNT_MAPPING"
    # The ID token claims mapped below beyond sub (G-92).
    attribute_contract = { extended_attributes = [{ name = "email", masked = false }, { name = "email_verified", masked = false }] }

    oidc_provider_settings = {
      authorization_endpoint = "https://appleid.apple.com/auth/authorize"
      token_endpoint         = "https://appleid.apple.com/auth/token"
      jwks_url               = "https://appleid.apple.com/auth/keys"
      # `email`: Apple puts the address in the ID token, with email_verified,
      # so the portal can keep a verified one (G-92, G-103). Apple requires
      # response_mode=form_post whenever it is asked for more than openid.
      scopes                                       = "openid email"
      login_type                                   = "CODE"
      authentication_scheme                        = "POST"
      enable_pkce                                  = false
      include_not_before_claim                     = false
      jwt_secured_authorization_response_mode_type = "DISABLED"
      track_user_sessions_for_logout               = false
      request_parameters = [{
        name                          = "response_mode"
        attribute_value               = { source = { type = "TEXT" }, value = "form_post" }
        application_endpoint_override = false
      }]
    }

    # Apple returns sub and, with the email scope, email and email_verified;
    # the person claims are static so the WalletIdentity contract is satisfied.
    authentication_policy_contract_mappings = [
      {
        attribute_sources                  = []
        authentication_policy_contract_ref = { id = local.apc_wallet_identity_id }
        issuance_criteria                  = { conditional_criteria = [] }
        restrict_virtual_server_ids        = false
        restricted_virtual_server_ids      = []
        attribute_contract_fulfillment = {
          subject        = { source = { type = "CLAIMS" }, value = "sub" }
          given_name     = { source = { type = "TEXT" }, value = "Apple" }
          family_name    = { source = { type = "TEXT" }, value = "User" }
          birthdate      = { source = { type = "TEXT" }, value = "1970-01-01" }
          email          = { source = { type = "CLAIMS" }, value = "email" }
          email_verified = { source = { type = "CLAIMS" }, value = "email_verified" }
        }
      },
    ]
  }
}
