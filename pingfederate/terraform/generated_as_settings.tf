# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "oauth_server_settings"
resource "pingfederate_oauth_server_settings" "this" {
  activation_code_check_mode                 = "AFTER_AUTHENTICATION"
  admin_web_service_pcv_ref                  = null
  allow_unidentified_client_extension_grants = false
  allow_unidentified_client_ro_creds         = false
  allowed_origins                            = []
  approved_authorization_detail_attribute    = null
  approved_scopes_attribute                  = null
  authorization_code_entropy                 = 30
  authorization_code_timeout                 = 60
  bypass_activation_code_confirmation        = false
  bypass_authorization_for_approved_consents = false
  bypass_authorization_for_approved_grants   = false
  client_secret_retention_period             = 0
  consent_lifetime_days                      = -1
  device_polling_interval                    = 5
  # FAPI 2.0 Security Profile 5.3.1.1: the authorization server "shall require
  # PKCE with S256 as the code challenge method". Refusing `plain` here is what
  # makes that a requirement rather than a preference; the suite's
  # par-plain-pkce-rejected module sends plain and expects the refusal. Every
  # client of this deployment already uses S256.
  disallow_plain_pkce = true
  # RFC 9449 §11.1 and §8 (G-33): PingFederate remembers each proof's jti and
  # refuses a replay, and hands out server nonces so a proof cannot be minted
  # ahead of time. Both wallets handle use_dpop_nonce (web: dpop.ts; iOS:
  # VCCore/DPoP.swift); pf-oid4vci's own endpoints keep their jti cache in the
  # state store (G-90).
  dpop_proof_enforce_replay_prevention                    = true
  dpop_proof_lifetime_seconds                             = 120
  dpop_proof_require_nonce                                = true
  enable_cookieless_user_authorization_authentication_api = false
  exclusive_scope_groups = [
  ]
  exclusive_scopes = [
  ]
  # RFC 9207: PingFederate names itself (`iss`) in the authorization response, so a
  # wallet talking to more than one authorization server can tell which one answered
  # (the mix-up defence). FAPI 2.0 and HAIP both require it, and the OpenID Foundation
  # issuer plan fails its discovery module while the metadata says `false`
  # (EnsureAuthorizationResponseIssParameterSupportedIsTrue). Clients that ignore
  # unknown response parameters - every conforming one - are unaffected.
  include_issuer_in_authorization_response         = true
  jwt_secured_authorization_response_mode_lifetime = 600
  offline_access_require_consent_prompt            = false
  par_reference_length                             = 24
  # RFC 9126 §2.2: a request_uri should be short-lived, "5 to 600 seconds". 60
  # did not survive a federated login (the person signs in at Apple between the
  # push and the authorize), which is why PAR was once turned off at the wallet.
  # 600 keeps it within the RFC's range and lets PAR be required (G-33).
  par_reference_timeout         = 600
  par_status                    = "ENABLED"
  pending_authorization_timeout = 600
  persistent_grant_contract = {
    extended_attributes = [
      {
        name = "birthdate"
      },
      {
        name = "family_name"
      },
      {
        name = "given_name"
      },
      {
        name = "email"
      },
      {
        name = "email_verified"
      },
    ]
  }
  persistent_grant_idle_timeout                        = 30
  persistent_grant_idle_timeout_time_unit              = "DAYS"
  persistent_grant_lifetime                            = -1
  persistent_grant_lifetime_unit                       = "DAYS"
  persistent_grant_reuse_grant_types                   = ["IMPLICIT"]
  refresh_rolling_interval                             = 0
  refresh_rolling_interval_time_unit                   = "HOURS"
  refresh_token_length                                 = 42
  refresh_token_rolling_grace_period                   = 60
  require_offline_access_scope_to_issue_refresh_tokens = false
  return_id_token_on_open_id_with_device_authz_grant   = true
  roll_refresh_token_values                            = false
  scope_groups = [
  ]
  scopes = [
    {
      # Operator scope for the Java servlets' admin surfaces (AdminAuth in
      # pf-common): PF_OID4VCI_ADMIN_SCOPE / PF_DTS_ADMIN_SCOPE name it, and a
      # client_credentials token carrying it is the operator. Added 2026-09-13
      # when the portal moved from the TypeScript issuer's shared secret to the
      # Java issuer behind PingFederate authentication.
      description = "Operator access to the VC issuer, verifier and trust-service admin endpoints"
      dynamic     = false
      name        = "vc:admin"
    },
    {
      # Opening a verifier session (pf-oid4vp POST /sessions, /dcapi/sessions):
      # PF_OID4VP_SESSION_SCOPE names it. A session is a request signed under this
      # deployment's reader certificate, so only a relying party may open one.
      description = "Open a presentation session on the VC verifier"
      dynamic     = false
      name        = "vc:verify"
    },
    {
      # OIDC Core §5.4: the email and email_verified claims (identity.tf).
      description = "Email address"
      dynamic     = false
      name        = "email"
    },
    {
      description = "Mobile Driving Licence credential"
      dynamic     = false
      name        = "mdl"
    },
    {
      description = "OpenID Connect"
      dynamic     = false
      name        = "openid"
    },
    {
      description = "Person Identification Data credential"
      dynamic     = false
      name        = "pid"
    },
    {
      description = "Profile claims"
      dynamic     = false
      name        = "profile"
    },
  ]
  track_user_sessions_for_logout          = false
  user_authorization_consent_adapter      = null
  user_authorization_consent_page_setting = "INTERNAL"
}
