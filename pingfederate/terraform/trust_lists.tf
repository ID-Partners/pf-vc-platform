# VICAL and RICAL provider identities — ISO/IEC DIS 18013-5 Annex C and Annex F.
#
# Two more keys on the Stage 2 path signing_keys.tf opened, and the trust anchors
# a consumer pins. Same shape, same preconditions, same gate: file paths rather
# than material, so nothing secret lands in tfvars, and count-gated so a plan
# without the bundles is a no-op rather than an error.
#
# IMPORT, NOT GENERATE, and here the reason is sharper than it is for the mdoc DS.
# PingFederate can generate a signing key, but the certificate it generates is
# SELF-SIGNED — and C.1.8 / F.3.2.5 refuse a self-signed trust-list signer
# outright, because the whole model is that a subscriber pins the provider ROOT
# out of band and checks that the signer chains to it. A PF-generated signer
# would chain to nothing anyone pinned. So the root and signer come from the
# offline ceremony (scripts/pki.mjs), PF holds and uses the signer, and the root's
# private key never comes near this deployment.
#
# PRECONDITION, unchanged from signing_keys.tf: the remote state backend
# (Stage 0 item 6). State receives what the provider reads; do not run this
# against local state. Until then pf-dts falls back to VICAL_SIGNER_JWK /
# RICAL_SIGNER_JWK and /pf-dts/health reports the signer as "environment", which
# is the point of that token — the fallback cannot pass for finished.

variable "vical_signer_p12_path" {
  description = "PKCS12 bundle for the VICAL signer (leaf signed by the offline VICAL root). Empty = not managed here yet."
  type        = string
  default     = ""
}

variable "rical_signer_p12_path" {
  description = "PKCS12 bundle for the RICAL signer (leaf signed by the offline RICAL root)."
  type        = string
  default     = ""
}

variable "vical_root_pem_path" {
  description = "The VICAL provider root certificate (PEM). Public — it is what subscribers pin."
  type        = string
  default     = ""
}

variable "rical_root_pem_path" {
  description = "The RICAL provider root certificate (PEM)."
  type        = string
  default     = ""
}

# Third-party providers whose lists this deployment CONSUMES — e.g. AAMVA's DTS,
# or a MATTR ecosystem. Their roots are static configuration a runtime fetch can
# never influence, which is exactly what a trusted-CA store is for; pf-oid4vp
# names one by subject via MDOC_VICAL_SOURCES `roots_subject`.
#
# Note what is NOT here: the IACAs a VICAL lists. Those stay in the list, never
# materialised into PF's store — the store has no docType metadata, no
# provenance and no lifecycle, so an IACA copied into it would be trusted for
# everything and could not be suspended by the provider that vouched for it.
variable "external_trust_list_roots" {
  description = <<-EOT
    name => PEM path, for VICAL/RICAL providers whose lists we consume.

    The AAMVA DTS is the intended first entry:

      external_trust_list_roots = { aamva = "/secure/trust-pki/aamva-root.pem" }

    which pf-oid4vp then names by subject in MDOC_VICAL_SOURCES:

      [{"file":"/opt/out/instance/.../aamva.cwt",
        "roots_subject":"AAMVA","provider":"<their vicalProvider>"}]

    AAMVA's VICAL is behind Terms and Conditions with liability limitations, so
    the download is a person's act, not a pipeline's — hence a `file` source
    rather than a `url` one, and hence the root arriving here as a path an
    operator placed rather than something fetched.
  EOT
  type        = map(string)
  default     = {}
}

resource "pingfederate_keypairs_signing_key" "vical_signer" {
  count     = var.vical_signer_p12_path != "" ? 1 : 0
  key_id    = "vical-signer-1"
  file_data = filebase64(var.vical_signer_p12_path)
  password  = var.signing_p12_password
  format    = "PKCS12"
}

resource "pingfederate_keypairs_signing_key" "rical_signer" {
  count     = var.rical_signer_p12_path != "" ? 1 : 0
  key_id    = "rical-signer-1"
  file_data = filebase64(var.rical_signer_p12_path)
  password  = var.signing_p12_password
  format    = "PKCS12"
}

# The roots, as PF trusted CAs. Read through TrustedCAAccessor.getAllTrustAnchors(),
# which returns EVERY anchor PF holds — TLS and OAuth CAs among them — so the
# consumer selects by subject and refuses an empty filter rather than resolving
# it to "all of them".
resource "pingfederate_certificate_ca" "vical_root" {
  count     = var.vical_root_pem_path != "" ? 1 : 0
  ca_id     = "vical-root-1"
  file_data = filebase64(var.vical_root_pem_path)
}

resource "pingfederate_certificate_ca" "rical_root" {
  count     = var.rical_root_pem_path != "" ? 1 : 0
  ca_id     = "rical-root-1"
  file_data = filebase64(var.rical_root_pem_path)
}

resource "pingfederate_certificate_ca" "external_trust_list_root" {
  for_each  = var.external_trust_list_roots
  ca_id     = "trust-list-root-${each.key}"
  file_data = filebase64(each.value)
}

# The ids the WAR consumes — PF_VICAL_KEYPAIR_ID / PF_RICAL_KEYPAIR_ID. Outputs
# so the WAR's variables are set FROM Terraform rather than retyped: a mistyped
# id is refused at startup by KeySource (never silently substituted), but not
# needing to type it is better still.
output "vical_keypair_id" {
  value = var.vical_signer_p12_path != "" ? pingfederate_keypairs_signing_key.vical_signer[0].key_id : null
}

output "rical_keypair_id" {
  value = var.rical_signer_p12_path != "" ? pingfederate_keypairs_signing_key.rical_signer[0].key_id : null
}
