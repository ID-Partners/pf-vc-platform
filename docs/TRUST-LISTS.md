# VICAL and RICAL — running the trust lists

What an operator does, and what the standard expects of them. The design is in
`design/pf-servlets.md`; the clause-by-clause verdicts are in
`conformance/STANDARDS-CONFORMANCE.md`.

## What these are

A **VICAL** (ISO/IEC DIS 18013-5 Annex C) tells a READER which credential
issuers to trust. A **RICAL** (Annex F) tells a WALLET which readers to trust.
Both are signed CBOR lists of CA certificates, fetched over HTTPS and validated
against a provider root the consumer obtained **out of band**.

This deployment is both a **consumer** and a **provider**:

| | Where | Configured by |
|---|---|---|
| Consumes VICALs | `pf-oid4vp` (issuer trust for mdoc verification) | `MDOC_VICAL_SOURCES` |
| Consumes VICALs | `pf-oid4vp` (`IssuerTrust` + `VicalTrustStore`, `MDOC_VICAL_SOURCES`) — the verifier inside PingFederate, on every mdoc path including both Digital Credentials API profiles. The TypeScript verifier this row once named was retired on 2026-09-13. |
| Publishes a VICAL | `pf-dts` → `GET /pf-dts/vical` | the register + `POST /admin/vical/issue` |
| Publishes a RICAL | `pf-dts` → `GET /pf-dts/rical` | the register + `POST /admin/rical/issue` |

`MDOC_IACA_PEM` still works and is what runs when no VICAL is configured;
`/pf-oid4vp/health` reports `issuer_trust` as `vical`, `static` or `none` so the
mode is never a guess. **The two are never combined** — a VICAL can suspend an
issuer, and a union with a pinned PEM would make that suspension do nothing.

## 1. The ceremony (once, offline)

The root's private key signs the signer certificate and the CRL, and nothing
else. Run this on a machine that holds no deployment credential, and keep the
`*-root.key.jwk` files off every server afterwards.

```bash
P12_PASSWORD='…' node scripts/pki.mjs init \
  --out /secure/trust-pki --host <public-pf-host> \
  --org "ID Partners" --country AU --policy-oid 1.3.6.1.4.1.<your-arc>
```

It writes, per list: `<list>-root.pem`, `<list>-root.key.jwk`,
`<list>-signer.pem`, `<list>-signer.key.jwk`, `<list>-root.crl` and
`<list>-signer.p12`. It **refuses to overwrite** an existing root, because the
root is what every consumer pins.

The profiles it mints are not obvious and are worth knowing, because a
hand-built certificate usually gets them wrong:

- the signer's keyUsage is **nonRepudiation**, not digitalSignature (Table C.1,
  Table F.1 — the reverse of a Document Signer);
- the VICAL signer carries EKU `1.0.18013.5.1.8` (mandatory) and
  `1.0.23220.4.1.8` (recommended); the **RICAL signer carries no EKU at all** and
  is identified by its certificatePolicies OID instead (Table F.1, F.3.5);
- both cap at 1187 days and carry a CRL distribution point.

## 2. Import the signers, publish the roots

```bash
cd pingfederate/terraform
terraform apply \
  -var vical_signer_p12_path=/secure/trust-pki/vical-signer.p12 \
  -var rical_signer_p12_path=/secure/trust-pki/rical-signer.p12 \
  -var vical_root_pem_path=/secure/trust-pki/vical-root.pem \
  -var rical_root_pem_path=/secure/trust-pki/rical-root.pem \
  -var signing_p12_password="$P12_PASSWORD"

terraform output vical_keypair_id   # → PF_VICAL_KEYPAIR_ID on the pingfederate service
terraform output rical_keypair_id   # → PF_RICAL_KEYPAIR_ID
```

**Precondition:** the remote state backend. State receives what the provider
reads; do not run this against local state. Until it exists, pf-dts falls back to
`VICAL_SIGNER_JWK` + `VICAL_SIGNER_PEM` and `/pf-dts/health` reports the signer
as `environment` — which is the point of that token. It cannot pass for done.

## 2a. Get an admin token

Admin calls authenticate with a **PingFederate access token**, not a shared
secret. Set `PF_DTS_ADMIN_SCOPE` on the `pingfederate` service (e.g.
`dts.admin`); with it unset the admin routes refuse everything with 503 rather
than defaulting open. Optionally set `PF_DTS_ADMIN_CLIENT_IDS` to restrict which
OAuth clients may present one.

```bash
DTS_TOKEN=$(curl -sf -X POST "$PF/as/token.oauth2" \
  -u "$DTS_CLIENT_ID:$DTS_CLIENT_SECRET" \
  -d 'grant_type=client_credentials&scope=dts.admin' | jq -r .access_token)
```

**Why not a shared secret.** The old `PF_DTS_ADMIN_SECRET` authenticated a caller
and identified nobody: the operator's name came from an `X-DTS-Actor` header the
caller set themselves. ISO/IEC DIS 18013-5 C.1.5.4.1 wants the audit log to
record *the identity of the person making the entry*, and a self-asserted name is
not that. The operator recorded now is the `sub` of the token, which
PingFederate signed.

Use a token minted for a PERSON where you can — client credentials names the
client, not the human, and the audit log can only be as good as what the token
says. GAP-REGISTER G-61 also wants dual control and a hardware key boundary
before an issue is signed; neither exists yet.

Then publish the roots AND their CRLs, and check pf-dts serves them:

```bash
PF_DTS_ADMIN_BEARER=$DTS_TOKEN node scripts/pki-crls.mjs publish --pki /secure/pki --base "$PF"
```

`/secure/pki` is the directory `scripts/pki-quickstart.mjs` writes (the trust-list
PKI under `trust/`). This used to be a loop that uploaded the two `.pem` files and
not the CRLs, and on the first instance neither CRL was ever published. That did
not matter while nothing checked; since G-60 every consumer refuses a list whose
signer's CRL it cannot fetch, and pf-dts itself refuses to publish one (the
precheck runs the consumer's check against what it serves). Renew before each
CRL's `nextUpdate` - `node scripts/pki-crls.mjs status --pki /secure/pki --base "$PF"`
exits 1 inside 30 days, and pf-dts's `/health` reports each CRL as `ok`,
`expiring`, `expired` or `missing`.

Also set on the `pingfederate` service: `PF_DTS_TRUST_PROVIDER` (the name that
goes in `vicalProvider`), `VICAL_PUBLIC_URL`, `RICAL_PUBLIC_URL`.

## 3. Register a CA, and decide about it

Registration is an application; listing is a decision. Both are recorded.

```bash
# apply — validated on the way in (must be a CA, must have a SubjectKeyIdentifier,
# a VICAL entry must name at least one docType)
curl -sf -X POST "$PF/pf-dts/admin/registry/vical/entries" \
  -H "Authorization: Bearer $DTS_TOKEN" \
  -d '{"certificatePem":"…","docTypes":["org.iso.18013.5.1.mDL"],
       "issuingAuthority":"Example Roads Authority","reason":"onboarding"}'

# accept it (id is the certificate's SubjectKeyIdentifier, hex)
curl -sf -X POST "$PF/pf-dts/admin/registry/vical/entries/$ID/accept" \
  -H "Authorization: Bearer $DTS_TOKEN" \
  -d '{"reason":"checks passed"}'
```

States are `PENDING → ACTIVE → SUSPENDED ⇄ ACTIVE`, and `REMOVED` from any of
them. **`REMOVED` is terminal**: C.1.4.8 ends a subscription and C.1.4.5 treats a
re-key as a new application, so a CA that comes back applies again with fresh
checks rather than inheriting an old approval.

Only `ACTIVE`, in-date entries are published.

## 4. Publish

```bash
curl -sf -X POST "$PF/pf-dts/admin/vical/issue" \
  -H "Authorization: Bearer $DTS_TOKEN" \
  -d '{"nextUpdateDays":30,"reason":"scheduled"}'
```

The publisher refuses rather than producing something unusable: a signer that
does not chain to the published root, a `nextUpdateDays` over 90 (C.1.2 — refused,
not clamped, so an operator is never surprised by a lifetime they did not ask
for), or a RICAL with no active CA (F.3.2.5 forbids an empty one). Every issue is
**self-verified with the consumer's own code** before it is stored.

**Emergency** (`{"emergency":true}`) publishes with a 24-hour `nextUpdate`. Use it
when a listed CA is compromised: suspend the entry, issue, and consumers pick it
up within one refresh. An empty VICAL is valid — "this provider currently vouches
for nobody" is a publishable statement.

## 5. Consume

On the `pingfederate` service:

```
MDOC_VICAL_SOURCES=[{"url":"https://<host>/pf-dts/vical",
                     "roots_pem":"-----BEGIN CERTIFICATE-----\n…",
                     "provider":"<PF_DTS_TRUST_PROVIDER>"}]
```

`roots_subject` may be used instead of `roots_pem` to name a CA in PingFederate's
own trusted-CA store (managed by `trust_lists.tf`). A **blank** subject filter is
refused: `getAllTrustAnchors()` returns every CA PF trusts for anything, TLS
included, and resolving a missing filter to "all of them" would make the whole
store a valid VICAL signer.

A plaintext `http` source URL is refused at startup. The list decides which
issuers exist; fetching it over a channel anyone can rewrite makes every
downstream check theatre.

## 5a. Consuming AAMVA's VICAL as a second source

AAMVA's DTS publishes a production VICAL of US issuing authorities. Adding it
makes this deployment consume an ecosystem rather than only its own list — which
is the difference between a trust list and a renamed PEM.

**The download is yours to make, not a script's.** AAMVA gates it behind Terms
and Conditions that carry liability limitations for AAMVA and every participating
issuing authority. Accepting an agreement like that on someone's behalf is not
something automation should do, so nothing here fetches it.

1. Read and accept the terms, then download the VICAL from
   <https://vical.dts.aamva.org/> (linked from AAMVA's
   [For Relying Parties](https://www.aamva.org/identity/mobile-driver-license-digital-trust-service/for-relying-parties)
   page).
2. Obtain **AAMVA's DTS root certificate out of band**. C.1.8 requires the
   provider root to arrive by some path other than the list itself, and this code
   refuses a list that carries its own anchor in `x5chain`. If AAMVA supplies the
   root only inside the chain, that is a question to put to them before
   depending on the list — pinning a root you received from the thing you are
   checking is not pinning.
3. Look before you wire it in:

   ```bash
   node scripts/trustlist.mjs inspect \
     --file .specs/vical/aamva.cwt --root .specs/vical/aamva-root.pem \
     --doctype org.iso.18013.5.1.mDL
   ```

   That prints the provider, issue number, `nextUpdate`, the docTypes it
   licenses, the issuing authorities, and — the part worth reading — any way its
   signer departs from the Table C.1 issuance profile. A departure is not a
   failure: Table C.1 binds the CA that issues a signer certificate, while a
   consumer's rule is RFC 5280 §6.1 path validation. Departures are recorded and
   the list is used; `keyCertSign` and a missing mdlVICAL EKU are still refusals.

4. Put the files where the PF service can read them (the volume, not the image),
   add AAMVA's root to `external_trust_list_roots`, and append the source:

   ```json
   [{"url": "https://<host>/pf-dts/vical", "roots_pem": "…", "provider": "…"},
    {"file": "/opt/out/instance/server/default/data/pf-oid4vp/aamva.cwt",
     "roots_subject": "AAMVA", "provider": "<their vicalProvider>"}]
   ```

   Sources are additive and independent: §12.8.1 says a VICAL that does not list
   an issuer "does not preclude relying on another", and a source that fails to
   load contributes nothing rather than failing the request.

5. `/pf-oid4vp/health` then shows both under `trust_sources`, each with its
   state, entry count and the NUMBER of signer deviations. The deviation text is
   in the PF log at load and in `inspect` — not on an endpoint anyone can reach,
   because it describes another organisation's certificate practices.

**Keeping it fresh is manual, and that is the real cost.** A `file` source is
only as current as the last download; AAMVA re-issues frequently. Put a reminder
against `nextUpdate` — `scripts/trustlist.mjs validate` exits non-zero past
`notAfter` and 2 when `nextUpdate` is within seven days, so it can drive an
alert — and re-download on that schedule. A stale AAMVA list keeps verifying
(F.3.3) but stops reflecting suspensions, which is precisely what you added it
for.

`conformance/test-vical-external.mjs` reads the real file when it is present and
skips when it is not. It is the only oracle this codec has that we did not write
ourselves, so a run where it skips is a run where the CBOR is checked only
against our own encoder.

## 6. Cadence and monitoring

C.1.2 asks for updates at least every 90 days; 30 is the default here and
re-issuing around day 14 leaves room for a failure. Watch:

- `/pf-dts/health` → `vical_next_update`, `rical_next_update`, `vical_signer`,
  `rical_signer`
- `/pf-oid4vp/health` → `issuer_trust`
- the signer certificates' own expiry (1187 days maximum), and the CRLs'
  `nextUpdate` — re-sign with `node scripts/pki.mjs crl --list vical --out …`

A **stale** list (past `nextUpdate`) keeps verifying deliberately: F.3.3 permits
it, and refusing would turn a provider outage into a total verification outage.
Past `notAfter` it contributes nothing. Last-good lists are cached on the PF
volume and re-verified on load, so a WAR redeploy during a provider outage does
not leave the verifier with no anchors.

## The RICAL is published, and the web wallet reads it

This deployment **publishes** a RICAL for other people's wallets, and the web
wallet (`services/wallet`) **reads** one: it fetches the RICAL it is pointed at,
verifies it under the RICAL root, and checks a verifier's reader certificate
against it before showing the holder who is asking (F.3.2.5 structure, F.3.2.6
reader matching; G-68, closed 2026-09-27). The iOS wallet is in the SDK and is not
measured here.

## What this does not do

Recorded here so it is not inferred as done, and tracked in
`conformance/GAP-REGISTER.md`:

- Revocation **is** checked since G-60 (2026-09-29): every consumer here fetches
  the signer's CRL and refuses a list whose signer is revoked, or whose CRL it
  cannot fetch. So each root's CRL must be published and kept current -
  `scripts/pki-crls.mjs` (the IACA's at least every 90 days, ISO/IEC 18013-5 B.2).
- **No dual control** over the signing key (G-61) — C.1.6.2 asks for it; a single
  bearer secret publishes an issue.
- **No trust-constraint types** are implemented (G-62), so a RICAL entry carrying
  a constraint is currently unusable — the fail-closed reading F.3.2.6 requires.
- **Applicant vetting is out of band** (G-63): the register records a decision,
  it does not perform the checks behind it.
- **No third-party list is consumed in production** (G-64).
- **No CP/CPS.** This is a runbook, not a policy document; C.1.1/C.1.2 and F.3.5
  expect a published policy the signer's policy OID points at.
