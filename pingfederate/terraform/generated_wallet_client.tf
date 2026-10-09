# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "wallet"
resource "pingfederate_oauth_client" "wallet" {
  allow_authentication_api_init                = false
  authorization_detail_types                   = []
  bypass_activation_code_confirmation_override = null
  # Issuing into the holder's own wallet: no OAuth scope-approval/consent page.
  bypass_approval_page                         = true
  ciba_delivery_mode                           = null
  ciba_notification_endpoint                   = null
  ciba_polling_interval                        = null
  ciba_request_object_signing_algorithm        = null
  ciba_require_signed_requests                 = null
  ciba_user_code_supported                     = null
  # attest_jwt_client_auth (draft-ietf-oauth-attestation-based-client-auth; HAIP
  # 1.0 §4.4). PF cannot verify a client attestation itself, so the
  # ClientAttestationAuth filter baked into pf-runtime.war (pf-ext/pf-wallet-attest)
  # verifies the OAuth-Client-Attestation + PoP headers and forwards the request
  # with a private_key_jwt client_assertion signed by the deployment's BRIDGE key
  # - whose public half is the JWKS below. So PF sees a method it supports, and
  # a request that skipped attestation (or failed it) has no assertion and is
  # invalid_client. `client_id=wallet` stops being a claim anyone can make.
  #
  # The bridge private key lives ONLY in the pingfederate service's environment
  # (PF_ATTEST_BRIDGE_JWK); scripts/keygen-attestation.mjs mints the pair.
  client_auth = {
    client_cert_issuer_dn     = null
    client_cert_subject_dn    = null
    # PF reads this back as false for a PRIVATE_KEY_JWT client (null never
    # converges). Replay prevention for the BRIDGE assertion is beside the
    # point: the PoP jti is what the filter replay-checks, and the bridge
    # assertion is minted once per verified request and never leaves the JVM.
    enforce_replay_prevention = false
    secondary_secrets = [
    ]
    secret                                = null # sensitive
    token_endpoint_auth_signing_algorithm = "ES256"
    type                                  = "PRIVATE_KEY_JWT"
  }
  client_id                           = "wallet"
  client_secret_retention_period      = null
  client_secret_retention_period_type = "SERVER_DEFAULT"
  default_access_token_manager_ref = {
    id = pingfederate_oauth_access_token_manager.jwtatm.id
  }
  description                                                          = null
  device_flow_setting_type                                             = "SERVER_DEFAULT"
  device_polling_interval_override                                     = null
  enable_cookieless_authentication_api                                 = false
  enabled                                                              = true
  exclusive_scopes                                                     = []
  extended_parameters                                                  = null
  # REFRESH_TOKEN lets the wallet keep a session: after one login it silently
  # mints new access tokens without another PingFederate sign-in.
  grant_types                                                          = ["AUTHORIZATION_CODE", "REFRESH_TOKEN"]
  jwks_settings = {
    jwks     = var.wallet_attest_bridge_jwks
    jwks_url = null
  }
  jwt_secured_authorization_response_mode_content_encryption_algorithm = null
  jwt_secured_authorization_response_mode_encryption_algorithm         = null
  jwt_secured_authorization_response_mode_signing_algorithm            = null
  lockout_max_malicious_actions                                        = null
  lockout_max_malicious_actions_type                                   = "SERVER_DEFAULT"
  logo_url                                                             = null
  name                                                                 = "Web Wallet"
  offline_access_require_consent_prompt                                = "SERVER_DEFAULT"
  oidc_policy = {
    back_channel_logout_uri                         = null
    grant_access_session_revocation_api             = false
    grant_access_session_session_management_api     = false
    id_token_content_encryption_algorithm           = null
    id_token_encryption_algorithm                   = null
    id_token_signing_algorithm                      = null
    logout_mode                                     = "NONE"
    logout_uris                                     = null
    pairwise_identifier_user_type                   = false
    ping_access_logout_capable                      = false
    policy_group                                    = null
    post_logout_redirect_uris                       = null
    sector_identifier_uri                           = null
    user_info_response_content_encryption_algorithm = null
    user_info_response_encryption_algorithm         = null
    user_info_response_signing_algorithm            = null
  }
  pending_authorization_timeout_override               = null
  persistent_grant_expiration_type                     = "SERVER_DEFAULT"
  persistent_grant_idle_timeout                        = 0
  persistent_grant_idle_timeout_time_unit              = "DAYS"
  persistent_grant_idle_timeout_type                   = "SERVER_DEFAULT"
  persistent_grant_reuse_grant_types                   = []
  persistent_grant_reuse_type                          = "SERVER_DEFAULT"
  redirect_uris                                        = var.wallet_redirect_uris
  refresh_rolling                                      = "SERVER_DEFAULT"
  refresh_token_rolling_grace_period                   = null
  refresh_token_rolling_grace_period_type              = "SERVER_DEFAULT"
  refresh_token_rolling_interval                       = null
  refresh_token_rolling_interval_type                  = "SERVER_DEFAULT"
  request_object_signing_algorithm                     = null
  request_policy_ref                                   = null
  # RFC 9449 / HAIP 1.0 §4: the wallet's tokens are sender-constrained. Every
  # wallet this product ships sends a DPoP proof (the web wallet since G-33 on
  # 2026-09-27, the iOS wallet's VCCore/DPoP.swift) and handles use_dpop_nonce,
  # so REQUIRING it closes the gap where a wallet that did not send one got a
  # bearer token anyone holding it could use.
  require_dpop                                         = true
  require_jwt_secured_authorization_response_mode      = false
  require_offline_access_scope_to_issue_refresh_tokens = "SERVER_DEFAULT"
  require_proof_key_for_code_exchange                  = true
  # RFC 9126 / HAIP 1.0 §4: the wallet MUST push its authorization request.
  #
  # Turned on for THIS client only. The wallet already implements the client
  # side - PFSession reads require_pushed_authorization_requests from the AS
  # metadata and POSTs to pushed_authorization_request_endpoint - so requiring it
  # here closes the loop rather than breaking the flow.
  #
  # The two console clients keep it false deliberately: they build an authorize
  # URL directly (services/issuer/src/index.ts:446) and do not implement PAR, so
  # requiring it would break operator login with no security gain. A flag flipped
  # everywhere because it is good in principle is how a working flow stops working.
  #
  # 2026-09-07: PAR was backed out at one instance because PF's 60 s request_uri
  # expiry did not survive a federated (Sign in with Apple) login. That was a
  # server setting, not a reason to leave the wallet unpushed: since 2026-09-30
  # par_reference_timeout is 600 s (generated_as_settings.tf), RFC 9126's upper
  # bound, and both wallets push when the server requires it (the web wallet's
  # par.ts, the iOS wallet's PFSession). So the product requires it (G-33).
  require_pushed_authorization_requests                = true
  require_signed_requests                              = false
  restrict_scopes                                      = false
  restrict_to_default_access_token_manager             = false
  restricted_response_types                            = []
  restricted_scopes                                    = []
  token_exchange_processor_policy_ref                  = null
  token_introspection_content_encryption_algorithm     = null
  token_introspection_encryption_algorithm             = null
  token_introspection_signing_algorithm                = null
  user_authorization_url_override                      = null
  validate_using_all_eligible_atms                     = false
}
