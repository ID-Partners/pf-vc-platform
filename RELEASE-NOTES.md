# Release notes

## 1.0.0-beta.1

The first public build. It's a beta: the issuer, verifier, trust services and
wallet provider run inside PingFederate and pass the conformance suite, but some
parts aren't production-grade yet - they're listed below rather than left for you
to find. Run it with the quickstart, evaluate it, and tell us what breaks. It is
not licensed for production use (see [BINARY-LICENSE.md](BINARY-LICENSE.md)).

### What's in it

- **Issuer** (OID4VCI 1.0): pre-authorised and authorisation-code issuance of
  SD-JWT VC and ISO/IEC 18013-5 mdoc, with status lists for revocation.
- **Verifier** (OID4VP 1.0 + HAIP): cross-device and same-device presentation,
  and the W3C Digital Credentials API.
- **Sign in with your wallet**: any OIDC client of PingFederate can sign a person
  in with a credential presentation.
- **Digital Trust Services**: status lists, certificate anchors and CRLs, and
  VICAL / RICAL trust lists.
- **Wallet provider**: attestation-based client authentication for wallets.
- **Holder portal**: sign-in through PingFederate, document capture, and
  credential offers.
- **The quickstart**: the whole platform on one machine, configured as code and
  proved end to end by `./scripts/stack-up.sh`.

### Before you deploy it anywhere but your laptop

The quickstart sets all of these. A deployment of `pingfederate/terraform` has to:

- **Name the holder login's validator.** `form_login_pcv_id` is your directory's
  password credential validator. There is no built-in user store.
- **Give relying parties a token to open a presentation.** The verifier opens a
  session only for a PingFederate access token carrying `vc:verify`
  (`PF_OID4VP_SESSION_SCOPE`); `PF_OID4VP_SESSION_CLIENT_IDS` can narrow it to
  named clients. The wallet-login adapter is one such client (`vp-wallet-login`).
- **Allow the pages a same-device presentation returns to.** A relying party names
  its `redirect_uri` when it opens a same-device session, and the verifier only
  sends a person to a page in `PF_OID4VP_REDIRECT_URIS`.
- **List the issuers the verifier trusts.** `PF_OID4VP_TRUSTED_ISSUERS` names them;
  there is no accept-everyone setting.
- **Set every client secret.** None has a default.
- **Verify the admin API's certificate.** Terraform does unless
  `pf_admin_insecure_tls` is set, which is meant for a local PingFederate only.

### Known limitations in this beta

- **Identity documents are not verified.** The portal captures a passport or
  licence from a scan or typed entry, and no document-verification or face-match
  service is connected. The portal's assurance level counts verified evidence
  only, so it stays at Basic - but the issuer will still issue a passport, mDL or
  PID credential from captured data. Don't use it with real identities.
- **Medicare and bank-account credentials are off by default.** Each needs an
  authorised data source and a legal basis before a deployment issues it, and
  neither has a data source in this release.
- **Credential type identifiers are placeholders** for the types that have no
  standard identifier (passport, age over 18 as SD-JWT, Medicare, bank account,
  loyalty). They'll become per-issuer configuration.
- **One PingFederate node.** Flow state can live in a shared store, but a
  two-node deployment hasn't been proved yet.
- **Keys in software.** Signing keys are PingFederate keypairs; HSM or KMS custody
  and dual control over trust-list signing aren't in this release.
- **No external penetration test or hosted certification run** yet.
