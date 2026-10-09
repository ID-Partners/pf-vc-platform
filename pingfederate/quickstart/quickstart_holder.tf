# QUICKSTART ONLY - never part of a production apply.
#
# pingfederate/terraform is the product: a deployment applies that directory as it
# is. scripts/stack-up.sh applies it from .compose/terraform/, where this directory's
# files are linked in beside it, so the local stack can sign a holder in without the
# product carrying a user store.
#
# One holder, `quickstart-holder`, for the HTML form login the wallet and the
# portal use. Its password is minted into .compose/secrets.json and has no default.
# scripts/stack-seed.mjs puts the same holder's identity-store records in place.

variable "quickstart_holder_password" {
  description = "The quickstart holder's password (stack-up.sh mints it into .compose/secrets.json)."
  type        = string
  sensitive   = true
}

resource "pingfederate_password_credential_validator" "quickstart_holder" {
  validator_id = "quickstartHolderPCV"
  name         = "Quickstart holder"

  plugin_descriptor_ref = {
    id = "org.sourceid.saml20.domain.SimpleUsernamePasswordCredentialValidator"
  }

  attribute_contract = {}

  configuration = {
    tables = [
      {
        name = "Users"
        rows = [
          {
            fields = [
              { name = "Username", value = "quickstart-holder" },
              { name = "Relax Password Requirements", value = "true" },
            ]
            sensitive_fields = [
              { name = "Password", value = var.quickstart_holder_password },
              { name = "Confirm Password", value = var.quickstart_holder_password },
            ]
            default_row = false
          },
        ]
      }
    ]
    fields = []
  }
}
