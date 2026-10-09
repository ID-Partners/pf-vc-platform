# From a login to a token: the contract every login fills, and how its attributes
# reach the access token, the persistent grant and the ID token.
#
# These once existed only in an instance's admin console, referenced here by a
# generated id (main.tf's apc_wallet_identity_id was "DglrB5MqZHwCVrGG"). A PingFederate built from this directory had logins that
# fulfilled a contract it did not have and a token manager nothing mapped into,
# so an instance could not be stood up from the repository at all. Declared here,
# an empty PingFederate becomes a working one with `terraform apply`.

# The authentication policies in main.tf only take effect with IdP authentication
# selection switched on, and a new PingFederate has it off: every authorization
# request then fails "There are no authentication methods available for OAuth".
resource "pingfederate_authentication_policies_settings" "this" {
  enable_idp_authn_selection = true
  enable_sp_authn_selection  = false
}

# WalletIdentity: what every login source in main.tf and apple.tf fulfils -
# subject, the three person claims the credentials carry, and the email the
# identity provider vouches for with whether it verified it (G-92). Only Apple
# supplies an email; the HTML form and the wallet login map none.
resource "pingfederate_authentication_policy_contract" "wallet_identity" {
  contract_id = "WalletIdentity"
  name        = "WalletIdentity"
  extended_attributes = [
    { name = "given_name" },
    { name = "family_name" },
    { name = "birthdate" },
    { name = "email" },
    { name = "email_verified" },
  ]
}

# Contract -> persistent grant. USER_KEY is the grant's owner (the login's
# subject); the three extended attributes are generated_as_settings.tf's
# persistent_grant_contract, so the claims outlive the login into refresh.
resource "pingfederate_oauth_authentication_policy_contract_mapping" "wallet_identity" {
  authentication_policy_contract_ref = { id = pingfederate_authentication_policy_contract.wallet_identity.id }
  attribute_sources                  = []
  attribute_contract_fulfillment = {
    USER_KEY    = { source = { type = "AUTHENTICATION_POLICY_CONTRACT" }, value = "subject" }
    USER_NAME   = { source = { type = "AUTHENTICATION_POLICY_CONTRACT" }, value = "subject" }
    given_name  = { source = { type = "AUTHENTICATION_POLICY_CONTRACT" }, value = "given_name" }
    family_name = { source = { type = "AUTHENTICATION_POLICY_CONTRACT" }, value = "family_name" }
    birthdate   = { source = { type = "AUTHENTICATION_POLICY_CONTRACT" }, value = "birthdate" }
    # The provider's email and its own word on whether it verified it; a
    # relying party (the portal) keeps the address only when it did (G-103).
    email          = { source = { type = "AUTHENTICATION_POLICY_CONTRACT" }, value = "email" }
    email_verified = { source = { type = "AUTHENTICATION_POLICY_CONTRACT" }, value = "email_verified" }
  }
  # The person attributes are declared by the persistent grant contract;
  # on an empty PingFederate, created first they are "not defined" (422).
  depends_on = [pingfederate_oauth_server_settings.this]
}

# Persistent grant -> jwtatm, for every grant a user stands behind (authorization
# code, refresh). jwtatm's contract (generated_settings.tf) is these four.
resource "pingfederate_oauth_access_token_mapping" "default" {
  access_token_manager_ref = { id = pingfederate_oauth_access_token_manager.jwtatm.id }
  context                  = { type = "DEFAULT" }
  attribute_sources        = []
  attribute_contract_fulfillment = {
    sub            = { source = { type = "OAUTH_PERSISTENT_GRANT" }, value = "USER_KEY" }
    given_name     = { source = { type = "OAUTH_PERSISTENT_GRANT" }, value = "given_name" }
    family_name    = { source = { type = "OAUTH_PERSISTENT_GRANT" }, value = "family_name" }
    birthdate      = { source = { type = "OAUTH_PERSISTENT_GRANT" }, value = "birthdate" }
    email          = { source = { type = "OAUTH_PERSISTENT_GRANT" }, value = "email" }
    email_verified = { source = { type = "OAUTH_PERSISTENT_GRANT" }, value = "email_verified" }
  }
  depends_on = [pingfederate_oauth_server_settings.this] # the grant's attributes are declared there
}

# Client credentials -> jwtatm: the service clients (scim_clients.tf, vci-svc).
# No person stands behind these, so the subject is the client and the person
# claims are left out. SCIM authorises on client_id, which jwtatm adds itself.
resource "pingfederate_oauth_access_token_mapping" "client_credentials" {
  access_token_manager_ref = { id = pingfederate_oauth_access_token_manager.jwtatm.id }
  context                  = { type = "CLIENT_CREDENTIALS" }
  attribute_sources        = []
  attribute_contract_fulfillment = {
    sub            = { source = { type = "CONTEXT" }, value = "ClientId" }
    given_name     = { source = { type = "NO_MAPPING" } }
    family_name    = { source = { type = "NO_MAPPING" } }
    birthdate      = { source = { type = "NO_MAPPING" } }
    email          = { source = { type = "NO_MAPPING" } }
    email_verified = { source = { type = "NO_MAPPING" } }
  }
}

# The ID token, for the clients that ask for openid (the wallet, and relying parties that sign in with a wallet):
# the access token's attributes, the person claims released under `profile`.
resource "pingfederate_openid_connect_policy" "wallet_identity" {
  policy_id                = "walletIdentity"
  name                     = "Wallet identity" # "Default" is PingFederate's reserved name
  access_token_manager_ref = { id = pingfederate_oauth_access_token_manager.jwtatm.id }
  include_sri_in_id_token  = true

  attribute_contract = {
    extended_attributes = [
      { name = "given_name", include_in_id_token = true, include_in_user_info = true },
      { name = "family_name", include_in_id_token = true, include_in_user_info = true },
      { name = "birthdate", include_in_id_token = true, include_in_user_info = true },
      { name = "email", include_in_id_token = true, include_in_user_info = true },
      { name = "email_verified", include_in_id_token = true, include_in_user_info = true },
    ]
  }

  attribute_mapping = {
    attribute_sources = []
    attribute_contract_fulfillment = {
      sub            = { source = { type = "TOKEN" }, value = "sub" }
      given_name     = { source = { type = "TOKEN" }, value = "given_name" }
      family_name    = { source = { type = "TOKEN" }, value = "family_name" }
      birthdate      = { source = { type = "TOKEN" }, value = "birthdate" }
      email          = { source = { type = "TOKEN" }, value = "email" }
      email_verified = { source = { type = "TOKEN" }, value = "email_verified" }
    }
  }

  # OIDC Core §5.4: `email` releases email and email_verified; the portal asks
  # for it (G-92).
  scope_attribute_mappings = {
    profile = { values = ["given_name", "family_name", "birthdate"] }
    email   = { values = ["email", "email_verified"] }
  }

  depends_on = [pingfederate_oauth_server_settings.this] # `profile` is declared there
}

resource "pingfederate_openid_connect_settings" "this" {
  default_policy_ref = { id = pingfederate_openid_connect_policy.wallet_identity.id }
}

