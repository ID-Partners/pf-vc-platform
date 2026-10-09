# What makes one instance of the platform different from another: where it is.
#
# Every URL PingFederate hands out - its issuer, its token endpoint, the base of
# the extensions under it - is built from pf_base_url, and the wallet's return
# URL is wherever that instance's wallet lives. These were fixed hostnames
# written into the resources that use them; they are variables so the same
# configuration stands up any instance, starting with docker-compose.yml's.
# scripts/stack-up.sh writes the local values into .compose/terraform.tfvars.json.

variable "pf_base_url" {
  description = "The public origin PingFederate is reached at (the gateway): its base URL, and the issuer of the access tokens jwtatm signs."
  type        = string
  validation {
    condition     = can(regex("^https://[^/]+$", var.pf_base_url))
    error_message = "pf_base_url is an https origin with no path or trailing slash, e.g. https://pf.localhost."
  }
}

variable "pf_virtual_host_names" {
  description = "Every host PingFederate answers on besides the base URL's. PingFederate emits per-host URLs for these."
  type        = list(string)
  default     = []
}

variable "wallet_redirect_uris" {
  description = "Return URLs of the wallet client: the web wallet's /callback, and the native wallet's scheme."
  type        = list(string)
}

# Roots PingFederate trusts for its OWN outbound TLS - the extensions' calls to the
# token endpoint, the trust services and the wallet provider's JWKS, which go out
# through the public URL. PingFederate answers those with its Trusted CAs, not the
# JVM's truststore (a -Djavax.net.ssl.trustStore was tried and ignored), so a root
# no public CA chains to - docker-compose.yml's local CA - has to be one of them.
variable "outbound_tls_ca_pem_paths" {
  description = "name => PEM path of a root PingFederate should trust for outbound TLS. Empty for an instance behind a public certificate."
  type        = map(string)
  default     = {}
}

resource "pingfederate_certificate_ca" "outbound_tls" {
  for_each  = var.outbound_tls_ca_pem_paths
  ca_id     = "tls-${each.key}"
  file_data = filebase64(each.value)
}
