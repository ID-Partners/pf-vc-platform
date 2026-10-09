# Signing keys as PingFederate objects — Stage 2.
#
# The condition this file removes: private keys living in the deployment's
# environment variables (ISSUER_SIGNING_JWK, MDOC_DS_JWK, READER_LEAF_JWK). Each keypair
# becomes a PF keystore entry with an id; the WARs are given the ID (an
# ordinary, non-secret variable) and read the material through KeyAccessor at
# runtime. The private key crosses the wire once, at import, over the admin
# API — and never again.
#
# The three keypairs are GUARDED (lifecycle.prevent_destroy). `count` is gated
# on the bundle path, so an apply run without the var-file that names the
# bundles plans these for DESTRUCTION — and the issuer and verifier then refuse
# to start, because the ids they were given no longer resolve. The guard turns
# that plan into an error. Rotation therefore adds a keypair under a NEW id,
# moves PF_*_KEYPAIR_ID to it, and retires the old one in a change that lifts
# its guard on purpose — never a silent swap of file_data under a live id.
#
# Import, not generation, on purpose. PF can generate
# (pingfederate_keypairs_signing_key also generates when file_data is absent),
# but the mdoc DS and reader leaf must be SIGNED BY the offline IACA / reader
# root per ISO 18013-5 Annex B — a self-signed PF-generated cert chains to
# nothing a wallet trusts. Generation stays in the offline ceremony
# (scripts/pki.mjs); PF holds and uses, per design/pf-servlets.md §5.
#
# The variables are file paths to PKCS12 bundles, not the material itself, so
# nothing secret lands in tfvars — and the state file still receives what the
# provider reads, which is why the backend must be the remote one (Stage 0
# item 6) before this is applied in anger. Until then this file is the shape,
# gated off by count so `terraform plan` without the bundles is a no-op rather
# than an error.

variable "sdjwt_signing_p12_path" {
  description = "PKCS12 bundle for the SD-JWT issuer key. Empty = not managed here yet."
  type        = string
  default     = ""
}

variable "mdoc_ds_p12_path" {
  description = "PKCS12 bundle for the mdoc Document Signer (leaf signed by the IACA)."
  type        = string
  default     = ""
}

variable "reader_leaf_p12_path" {
  description = "PKCS12 bundle for the reader authentication leaf (signed by the reader root)."
  type        = string
  default     = ""
}

# The keystore ids. They are not cosmetic: pf-oid4vci uses the SD-JWT keypair
# id as the credential's `kid`, so importing an EXISTING key under a new id
# changes the kid, and credentials issued before the import stop resolving
# against /.well-known/jwt-vc-issuer. A migration sets these to the ids the
# keys already carry (scripts/pki-bundle-env.mjs writes them); a fresh
# quickstart leaves the defaults.
variable "sdjwt_keypair_id" {
  description = "PF keystore id for the SD-JWT issuer key — also the credentials' kid."
  type        = string
  default     = "sdjwt-issuer-1"
}

variable "mdoc_ds_keypair_id" {
  description = "PF keystore id for the mdoc Document Signer."
  type        = string
  default     = "mdoc-ds-1"
}

variable "reader_keypair_id" {
  description = "PF keystore id for the reader authentication leaf."
  type        = string
  default     = "reader-leaf-1"
}

variable "signing_p12_password" {
  description = "Password for the PKCS12 bundles."
  type        = string
  default     = ""
  sensitive   = true
}

resource "pingfederate_keypairs_signing_key" "sdjwt_issuer" {
  count     = var.sdjwt_signing_p12_path != "" ? 1 : 0
  key_id    = var.sdjwt_keypair_id
  file_data = filebase64(var.sdjwt_signing_p12_path)
  password  = var.signing_p12_password
  format    = "PKCS12"

  lifecycle {
    prevent_destroy = true # see the header: an apply without the var-file must fail, not destroy
  }
}

resource "pingfederate_keypairs_signing_key" "mdoc_ds" {
  count     = var.mdoc_ds_p12_path != "" ? 1 : 0
  key_id    = var.mdoc_ds_keypair_id
  file_data = filebase64(var.mdoc_ds_p12_path)
  password  = var.signing_p12_password
  format    = "PKCS12"

  lifecycle {
    prevent_destroy = true # see the header: an apply without the var-file must fail, not destroy
  }
}

resource "pingfederate_keypairs_signing_key" "reader_leaf" {
  count     = var.reader_leaf_p12_path != "" ? 1 : 0
  key_id    = var.reader_keypair_id
  file_data = filebase64(var.reader_leaf_p12_path)
  password  = var.signing_p12_password
  format    = "PKCS12"

  lifecycle {
    prevent_destroy = true # see the header: an apply without the var-file must fail, not destroy
  }
}

# The ids the WARs consume — PF_SDJWT_KEYPAIR_ID / PF_MDOC_DS_KEYPAIR_ID /
# PF_READER_KEYPAIR_ID. Outputs so the WARs' variables are set FROM Terraform
# rather than retyped: a mistyped id is refused at startup by KeySource (never
# silently substituted), but not needing to type it is better still.
output "sdjwt_keypair_id" {
  value = var.sdjwt_signing_p12_path != "" ? pingfederate_keypairs_signing_key.sdjwt_issuer[0].key_id : null
}

output "mdoc_ds_keypair_id" {
  value = var.mdoc_ds_p12_path != "" ? pingfederate_keypairs_signing_key.mdoc_ds[0].key_id : null
}

output "reader_keypair_id" {
  value = var.reader_leaf_p12_path != "" ? pingfederate_keypairs_signing_key.reader_leaf[0].key_id : null
}

# Trust anchors: the IACA and reader root as PF trusted CAs, read by
# TrustedCAAccessor.getAllTrustAnchors(). getAllTrustAnchors returns ALL
# anchors unfiltered, so per-tenant selection happens by SKI in the WAR —
# these just get the anchors INTO the store.
variable "mdoc_iaca_pem_path" {
  description = "The IACA root certificate (PEM). Empty = not managed here yet."
  type        = string
  default     = ""
}

resource "pingfederate_certificate_ca" "mdoc_iaca" {
  count     = var.mdoc_iaca_pem_path != "" ? 1 : 0
  ca_id     = "mdoc-iaca-1"
  file_data = filebase64(var.mdoc_iaca_pem_path)
}
