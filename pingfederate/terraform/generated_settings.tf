# __generated__ by Terraform
# Please review these resources and move them into your main configuration files.

# __generated__ by Terraform from "server_settings"
resource "pingfederate_server_settings" "this" {
  contact_info = {
    company    = null
    email      = null
    first_name = null
    last_name  = null
    phone      = null
  }
  federation_info = {
    base_url         = var.pf_base_url
    saml_2_entity_id = "idp-pf-vcs"
  }
  notifications = {
    account_changes_notification_publisher_ref               = null
    bulkhead_alert_notification_settings                     = null
    certificate_expirations                                  = null
    expired_certificate_administrative_console_warning_days  = 14
    expiring_certificate_administrative_console_warning_days = 14
    license_events                                           = null
    metadata_notification_settings                           = null
    notify_admin_user_password_changes                       = false
    thread_pool_exhaustion_notification_settings = {
      email_address              = ""
      notification_mode          = "LOGGING_ONLY"
      notification_publisher_ref = null
      thread_dump_enabled        = true
    }
  }

  # Not at the same moment as the licence. On a new PingFederate the two ran in
  # parallel and the settings came back as they were before the write (base_url
  # https://localhost:9031), so the apply failed "inconsistent result" and the
  # resource was left tainted - found standing the stack up from nothing.
  depends_on = [pingfederate_license.license]
}

# __generated__ by Terraform from "jwtatm"
resource "pingfederate_oauth_access_token_manager" "jwtatm" {
  access_control_settings = {
    allowed_clients = [
    ]
    restrict_clients = false
  }
  attribute_contract = {
    default_subject_attribute = null
    extended_attributes = [
      {
        multi_valued = false
        name         = "birthdate"
      },
      {
        multi_valued = false
        name         = "family_name"
      },
      {
        multi_valued = false
        name         = "given_name"
      },
      {
        multi_valued = false
        name         = "sub"
      },
      {
        multi_valued = false
        name         = "email"
      },
      {
        multi_valued = false
        name         = "email_verified"
      },
    ]
  }
  configuration = {
    fields = [
      {
        name  = "Access Grant GUID Claim Name"
        value = ""
      },
      {
        name  = "Active Signing Certificate Key ID"
        value = ""
      },
      {
        name  = "Active Symmetric Encryption Key ID"
        value = ""
      },
      {
        name  = "Active Symmetric Key ID"
        value = ""
      },
      {
        name  = "Asymmetric Encryption JWKS URL"
        value = ""
      },
      {
        name  = "Asymmetric Encryption Key"
        value = ""
      },
      {
        name  = "Audience Claim Value"
        value = ""
      },
      {
        name  = "Authorization Details Claim Name"
        value = "authorization_details"
      },
      {
        name  = "Client ID Claim Name"
        value = "client_id"
      },
      {
        name  = "Default JWKS URL Cache Duration"
        value = "720"
      },
      {
        name  = "Enable Token Revocation"
        value = "false"
      },
      {
        name  = "Expand Scope Groups"
        value = "false"
      },
      {
        name  = "Include Issued At Claim"
        value = "true"
      },
      {
        name  = "Include JWE Key ID Header Parameter"
        value = "true"
      },
      {
        name  = "Include JWE X.509 Thumbprint Header Parameter"
        value = "false"
      },
      {
        name  = "Include Key ID Header Parameter"
        value = "true"
      },
      {
        name  = "Include X.509 Thumbprint Header Parameter"
        value = "false"
      },
      {
        name  = "Issuer Claim Value"
        value = var.pf_base_url
      },
      {
        name  = "JWE Algorithm"
        value = ""
      },
      {
        name  = "JWE Content Encryption Algorithm"
        value = ""
      },
      {
        name  = "JWKS Endpoint Cache Duration"
        value = "720"
      },
      {
        name  = "JWKS Endpoint Path"
        value = ""
      },
      {
        name  = "JWS Algorithm"
        value = "ES256"
      },
      {
        name  = "JWT ID Claim Length"
        value = "0"
      },
      {
        name  = "Not Before Claim Offset"
        value = ""
      },
      {
        name  = "Publish Key ID X.509 URL"
        value = "false"
      },
      {
        name  = "Publish Keys to the PingFederate JWKS Endpoint"
        value = "false"
      },
      {
        name  = "Publish Thumbprint X.509 URL"
        value = "false"
      },
      {
        name  = "Scope Claim Name"
        value = "scope"
      },
      {
        name  = "Space Delimit Scope Values"
        value = "true"
      },
      {
        name  = "Token Lifetime"
        value = "120"
      },
      {
        name  = "Type Header Value"
        value = ""
      },
      {
        name  = "Use Centralized Signing Key"
        value = "true"
      },
    ]
    sensitive_fields = [
    ]
    tables = [
      {
        name = "Symmetric Keys"
        rows = null
      },
      {
        name = "Certificates"
        rows = null
      },
    ]
  }
  manager_id = "jwtatm"
  name       = "JWT Access Tokens"
  parent_ref = null
  plugin_descriptor_ref = {
    id = "com.pingidentity.pf.access.token.management.plugins.JwtBearerAccessTokenManagementPlugin"
  }
  selection_settings = {
    resource_uris = []
  }
  session_validation_settings = {
    check_session_revocation_status = false
    check_valid_authn_session       = false
    include_session_id              = false
    update_authn_session_activity   = false
  }
  token_endpoint_attribute_contract = {
    attributes = [
    ]
  }
}
