# PingFederate's runtime TLS certificate, issued under the product's internal CA
# (scripts/gen-internal-tls.mjs) so the gateway can VERIFY it - G-110.
#
# The gateway reaches PingFederate over the private network, and PingFederate's
# runtime listener presented the self-signed certificate it makes for itself, so
# the gateway accepted any certificate there (`tls_insecure_skip_verify`). With
# this applied, the runtime listener presents a certificate for the name the
# gateway dials, and the gateway checks it against PF_UPSTREAM_CA_PEM
# (services/pf-gateway/entrypoint.sh).
#
# Gated like the signing keys: unset, nothing here is managed. Set, the admin
# console keeps the certificate it has - PingFederate's settings resource names
# both, so the admin console's id is a variable an operator reads off their own
# PingFederate (Security > SSL Server Certificates), never a guess.

variable "pf_runtime_tls_p12_path" {
  description = "PKCS12 bundle for PingFederate's runtime TLS certificate (scripts/gen-internal-tls.mjs). Empty = not managed here."
  type        = string
  default     = ""
}

variable "pf_runtime_tls_p12_password" {
  description = "Password for that bundle (gen-internal-tls.mjs writes it to runtime-tls.auto.tfvars)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "pf_runtime_tls_key_id" {
  description = "PF keystore id for the runtime TLS certificate. Rotation adds a new id."
  type        = string
  default     = "pf-runtime-tls-1"
}

variable "pf_admin_console_ssl_key_id" {
  description = "The id of the admin console's existing SSL server certificate - kept as it is."
  type        = string
  default     = ""

  validation {
    condition     = var.pf_runtime_tls_p12_path == "" || var.pf_admin_console_ssl_key_id != ""
    error_message = "pf_admin_console_ssl_key_id is required with pf_runtime_tls_p12_path: PingFederate's SSL settings name the admin console's certificate too, and this must not replace it."
  }
}

resource "pingfederate_keypairs_ssl_server_key" "pf_runtime" {
  count     = var.pf_runtime_tls_p12_path != "" ? 1 : 0
  key_id    = var.pf_runtime_tls_key_id
  file_data = filebase64(var.pf_runtime_tls_p12_path)
  password  = var.pf_runtime_tls_p12_password
  format    = "PKCS12"

  lifecycle {
    # In use by the runtime listener: an apply without the var-file must fail, not delete it.
    prevent_destroy = true
  }
}

resource "pingfederate_keypairs_ssl_server_settings" "this" {
  count                       = var.pf_runtime_tls_p12_path != "" ? 1 : 0
  runtime_server_cert_ref     = { id = pingfederate_keypairs_ssl_server_key.pf_runtime[0].key_id }
  active_runtime_server_certs = [{ id = pingfederate_keypairs_ssl_server_key.pf_runtime[0].key_id }]
  admin_console_cert_ref      = { id = var.pf_admin_console_ssl_key_id }
  active_admin_console_certs  = [{ id = var.pf_admin_console_ssl_key_id }]
}
