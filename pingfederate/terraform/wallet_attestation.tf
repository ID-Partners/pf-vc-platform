# attest_jwt_client_auth for the wallet client - see generated_wallet_client.tf.
#
# The bridge key's PUBLIC half, as a JWKS document. Not a secret: it is what PF
# verifies the bridge private_key_jwt against, exactly as any private_key_jwt
# client's JWKS. Generate with scripts/keygen-attestation.mjs; the matching
# private key is PF_ATTEST_BRIDGE_JWK in the pingfederate service's environment, and
# the two rotate together.
variable "wallet_attest_bridge_jwks" {
  description = "JWKS (JSON) holding the public half of PF_ATTEST_BRIDGE_JWK - the wallet client's private_key_jwt key."
  type        = string
}
