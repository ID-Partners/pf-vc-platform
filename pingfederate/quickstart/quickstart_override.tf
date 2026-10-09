# QUICKSTART ONLY (see quickstart_holder.tf). Puts the quickstart holder's
# validator behind the HTML form login, by overriding the local main.tf reads.
# An override file because Terraform merges a local value from one, where a
# second ordinary definition would be an error.
locals {
  form_login_pcv_id = pingfederate_password_credential_validator.quickstart_holder.id
}
