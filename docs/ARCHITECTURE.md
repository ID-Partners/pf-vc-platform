# Architecture

What the pieces are and how they fit. Read this once; the build guide
and [credentials guide](CREDENTIALS.md) assume the vocabulary here.

## The one-paragraph version

**PingFederate stays the OAuth Authorization Server. The verifiable-credential
rails run beside it — and increasingly inside it.** An **issuer** mints
credentials (OID4VCI), a **verifier** checks presentations (OID4VP), and
**Digital Trust Services (DTS)** publish the trust material both sides rely on
(revocation status lists, the issuer/reader certificate anchors). A **wallet**
holds credentials and presents them. An **identity store (SCIM)** holds the
person's profile and scanned documents. Two credential formats are supported
end to end: **SD-JWT VC** and **ISO/IEC 18013-5 mdoc** (mDL).

## Where the rails run

**Every server is Java, inside PingFederate** (`pf-ext/`, WARs and SDK plugins
baked into the PF image): `pf-dts`, the full `pf-oid4vp` verifier (SD-JWT VC
and mdoc, over `request_uri` and over both Digital Credentials API profiles —
OID4VP Annex A and ISO 18013-7 Annex C), the `pf-oid4vci` issuer
(pre-authorized and authorization-code, with the `openid_credential` RAR
processor), the `pf-vp-adapter` wallet-login adapter, `pf-wallet-attest`
(attestation-based client authentication) and `pf-wallet-provider`. Their
shared credential crypto is the standalone `vc-core/` library.

The TypeScript issuer and verifier that once ran beside PingFederate were
retired on 2026-09-13 when the Java reached parity (the decision and the
route-by-route ledger: `design/java-first-migration.md`).
What is still TypeScript: the holder portal, the quickstart's web wallet, and
`packages/shared`, the library those use and the conformance harness drives. The identity store is
Go. The native wallet lives in its own repository.

The design of the extensions and the platform facts that shaped them are in
`design/pf-servlets.md`.

**Why layer 2 matters:** running inside PF means the credential endpoints verify
PF access tokens against PF's *own* signing keys with no network hop, read typed
RAR `authorization_details` straight off the grant, and sign status lists with a
key PF already publishes. The reason to do it is in `design/pf-servlets.md §3`.

## Components

| Component | Path | What it does |
|---|---|---|
| **PingFederate** | `services/pingfederate`, `pingfederate/terraform` | The OAuth Authorization Server. Runs the `pf-ext` WARs baked into its image. Config is Terraform (`pingfederate/terraform/*.tf`). |
| **pf-dts** (DTS) | `pf-ext/pf-dts` | Runs inside PF. Serves PF-key-signed Token Status Lists and distributes the IACA / reader-root certificate anchors. **Live.** |
| **pf-oid4vp** (verifier) | `pf-ext/pf-oid4vp` | Runs inside PF. Builds the signed OID4VP request (JAR) and verifies the encrypted response — **both SD-JWT VC and ISO mdoc**. **Live.** |
| **pf-oid4vci** (issuer) | `pf-ext/pf-oid4vci` | Runs inside PF. OID4VCI issuer for SD-JWT VC and mdoc; verifies PF access tokens **in-process** via `JwksEndpointKeyAccessor` (no JWKS fetch). Pre-authorized *and* authorization-code. **Live.** |
| **pf-vp-adapter** | `pf-ext/pf-vp-adapter` | PF `IdpAuthnAdapter` plugin making a wallet presentation a first-class PF authentication source. Replaced the standalone verifier's OIDC OP facade. **Live.** |
| **pf-vc-rar** | `pf-ext/pf-vc-rar` | PF `AuthorizationDetailProcessor` plugin validating `openid_credential` RAR `authorization_details` at authorization time. **Live.** |
| **pf-wallet-attest** | `pf-ext/pf-wallet-attest` | Attestation-based client authentication (`attest_jwt_client_auth`). Not a WAR and not a plugin — a jar merged **into `pf-runtime.war`**, whose two `Filter`s sit in front of PF's own token/PAR endpoints and its metadata. PF has no SDK seam for client authentication, so this is the only lever. **Live.** |
| **vc-core** | `vc-core/` | The Java credential crypto shared by both PF WARs: CBOR, COSE_Sign1, mdoc issue + verify, the OID4VP session transcript, SD-JWT VC. A standalone library that imports no PingFederate type, so it builds and is reusable outside PF. |
| **wallet** | `services/wallet`; native iOS in [vc-wallet-sdk](https://github.com/dphhyland/vc-wallet-sdk) | Holder wallet. Web service + a native iOS app. Holds credentials, accepts offers, answers presentation requests, does in-person (BLE) presentation. |
| **wallet-provider** | `pf-ext/pf-wallet-provider` (a WAR inside PingFederate, served at `/pf-wallet-provider`) | The wallet provider that vouches for a wallet **instance**: mints the Client Attestation JWT binding an install's key, and publishes the JWKS PingFederate verifies it against. The other half of `pf-wallet-attest`. |
| **portal** | `services/portal` | Self-service holder onboarding: Sign in with Apple, scan documents, request issuance. |
| **scim** | `services/scim` | Identity store (Go + Postgres). Holds users, profiles, scanned documents, credential grants, consents, issuance policies. OAuth-protected by PF tokens. |
| **pf-gateway** | `services/pf-gateway` | Caddy TLS front for the PF runtime (valid cert, styled login pages). |
| **shared** | `packages/shared` | The TypeScript library the web wallet, the portal and the conformance harness use: CBOR/COSE/mdoc, SD-JWT, X.509/PKI, session transcripts, status lists, trust lists. It is not the oracle for the Java — external vectors and third-party libraries are (below). |
| **conformance** | `conformance/`, `vectors/` | Spec-cited assertions cross-checking every port against ISO/OID4VP vectors and the reference library. `vectors/mdoc/` is a committed cross-port corpus with fixed expected verdicts — the check that catches two ports drifting together. |

## The four flows

**Issuance (OID4VCI).** The issuer makes an *offer* (a JSON blob naming the
credential type and either a pre-authorized code or an authorization-code
grant). The wallet reads it, gets an access token (its own `/token` for
pre-auth, or PingFederate for auth-code — see the flows below), then calls
`/credential` with a proof of its key, and receives the signed credential. The
claim values come from the person's SCIM profile/documents, never sample data.

**Presentation (OID4VP).** The verifier makes a *request* (a DCQL query for
specific claims), signs it (so the wallet can trust it — reader PKI, `x509_hash`
client id), and hands the wallet a link. The wallet fetches the signed request,
verifies the verifier's signature, shows the holder what's being asked, and on
approval sends an **encrypted** response. The verifier decrypts it and verifies
the credential (issuer signature + holder key-binding), plus revocation via DTS.

**Client authentication (attestation).** `client_id=wallet` is a claim anyone
can make: a public client has no secret. So the wallet provider
(`pf-ext/pf-wallet-provider`, inside PingFederate) vouches for each *install* — a Client Attestation
JWT binding that instance's key — and the wallet sends it, plus a per-request
proof signed by that key, on every token and PAR request. Inside PingFederate,
`pf-wallet-attest` verifies both and translates them into a credential PF
natively understands. The two halves are one change: the wallet only sends the
headers when PF's metadata advertises `attest_jwt_client_auth`, and PF only
advertises it while it can verify it. **The instance key is deliberately not the
holder key** — one key for both would make a login at PF linkable to a
presentation at an unrelated verifier.

**Trust (DTS).** Both sides need shared trust material. DTS publishes:
revocation **status lists** (signed by PF's key, verifiable against PF's JWKS);
the **IACA** anchor that roots issued mdocs; and the **reader-root** anchor the
wallet uses to trust a verifier's signed request.

## Two credential formats

| | SD-JWT VC | ISO 18013-5 mdoc (mDL) |
|---|---|---|
| Encoding | JSON, JOSE-signed | CBOR, COSE-signed |
| Selective disclosure | salted-hash disclosures | per-element digests in the MSO |
| Holder binding | `cnf` key + KB-JWT | device key + device signature |
| Example | `urn:eudi:pid:1` (EUDI PID) | `org.iso.18013.5.1.mDL` |

The same credential can exist in both (e.g. the EUDI PID is issued as both
`pid-sd-jwt` and `pid-mdoc`). See [CREDENTIALS.md](CREDENTIALS.md).

## Two PingFederate login flows

- **Wallet → PF (authorization-code issuance):** the person signs in at PF
  (currently via Sign in with Apple) and PF issues the access token the wallet
  uses at `/credential`.
- **Wallet → PF (sign in with your wallet):** a relying party (any OIDC client of PF)
  sends the person to PF; PF consumes a wallet *presentation* as the login, via the `pf-vp-adapter`
  IdP adapter driving a `pf-oid4vp` session. (This replaced the standalone
  verifier's OIDC OP facade, which has been deleted.)

## Cross-language integrity — the rule the whole repo follows

There are two implementations of the credential crypto in this repository
(Java in `vc-core`, which runs in production; TypeScript in `packages/shared`,
which the web wallet uses) and a third in the native wallet's own repository.
**Every cryptographic byte each produces is anchored to an external reference —
ISO 18013-5 Annex D vectors, OID4VP's printed transcripts, RFC 9180 vectors,
the EUDI PID rulebook, third-party libraries — never to the other port.** Two
ports that agree with each other prove nothing: the mdoc holder-binding bypass
of 2026-09-27 (GAP-REGISTER G-84) lived in both, and the committed corpus had
no vector for it. The conformance suite (`conformance/run.sh`) is where the
anchoring is enforced, and a negative vector is added for every defect found.
When you add a credential or port a piece, you anchor it the same way.
