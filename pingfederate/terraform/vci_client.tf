# The OID4VCI issuer's authorization-code client.
#
# A client the wallet uses to obtain a PingFederate access token that carries an
# `openid_credential` Rich Authorization Request (RFC 9396); pf-oid4vci verifies
# that token IN-PROCESS (JwksEndpointKeyAccessor — no JWKS fetch), gates on
# client_id (PF_OID4VCI_CLIENTS), and enforces that the requested
# credential_configuration_id appears in the token's authorization_details.
#
# `authorization_detail_types = ["openid_credential"]` is what lets the client
# request that RAR type. It depends on a RAR *processor instance* + a registered
# `openid_credential` authorization-detail *type* — neither has a Terraform
# resource in the provider, so both are created via the admin API and captured
# into the config archive (data.zip):
#
#   POST /oauth/authorizationDetailProcessors
#        {"id":"vcrar","pluginDescriptorRef":{"id":"au.idp.pf.rar.RarProcessor"},…}
#   POST /oauth/authorizationDetailTypes
#        {"type":"openid_credential","authorizationDetailProcessorRef":{"id":"vcrar"}}
#
# (the plugin id is the processor FQCN, which PF caps at 32 chars — hence the
# short au.idp.pf.rar package.)
#
# This is a client_credentials client for the headless conformance path; the
# real wallet flow adds AUTHORIZATION_CODE + a redirect_uri and a user login,
# whose token then carries the user's sub for SCIM claim sourcing.

variable "vci_svc_secret" {
  description = "The vci-svc client's secret. No default: a committed one is a secret everybody has."
  type        = string
  sensitive   = true
}

resource "pingfederate_oauth_client" "vci_service" {
  client_id = "vci-svc"
  name      = "OID4VCI issuer client"
  enabled   = true

  grant_types                = ["CLIENT_CREDENTIALS"]
  authorization_detail_types = ["openid_credential"]

  client_auth = {
    type   = "SECRET"
    secret = var.vci_svc_secret
  }

  bypass_approval_page             = true
  default_access_token_manager_ref = { id = pingfederate_oauth_access_token_manager.jwtatm.id }
}
