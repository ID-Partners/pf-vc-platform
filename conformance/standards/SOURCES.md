# Standards corpus — pinned sources

Every row in [STANDARDS-CONFORMANCE.md](../STANDARDS-CONFORMANCE.md) cites a
section of one of these documents, *at this exact revision*. `fetch-corpus.sh`
downloads them into `corpus/` (gitignored) and fails on a hash mismatch, so a
silently-updated upstream shows up as DRIFT rather than as a row that quietly
stopped meaning what it said.

Verified: 2026-09-03. Versions were confirmed against the publishers' own status
pages on that date — see "Status" — not assumed from memory.

**Pin dated URIs, never "latest".** A hash pin is only meaningful against an
immutable URL. `w3.org/TR/digital-credentials/` is the living "latest version"
of a Working Draft and its bytes change without notice; pinning it made CI fail
on a document nobody had touched. It is now pinned to W3C's dated snapshot
(`/TR/2026/WD-…-20260903/`), which never changes. The IETF `archive/id/…-NN.txt`
URLs and the OIDF `…-final.html` URLs are already immutable by construction. The
one remaining moving target is the PID Rulebook, pinned to a branch tip
(`raw.githubusercontent.com/…/main/…`): if that drifts, re-read the diff and
re-pin to the commit SHA rather than re-hashing the branch.

| ID | URL | File | SHA-256 | Status (2026-09-03) |
|---|---|---|---|---|
| OID4VCI-1.0 | https://openid.net/specs/openid-4-verifiable-credential-issuance-1_0-final.html | oid4vci-1_0-final.html | f123c3178cacd27688b15b762098a045e9eb35eccfe2f5f18a357c3815e06ba7 | **Final**, approved 2025-09-16 (v1.1 in progress, not used) |
| OID4VP-1.0 | https://openid.net/specs/openid-4-verifiable-presentations-1_0-final.html | oid4vp-1_0-final.html | 08e635ea3563b192309c627382c281c81de176e94cdb5ffb11b13ac624f7e12e | **Final**, July 2025 |
| HAIP-1.0 | https://openid.net/specs/openid4vc-high-assurance-interoperability-profile-1_0-final.html | haip-1_0-final.html | 3996e0479d06b72d6d68668b8ae3cd39fddfc29ae9220c0c3fead7dc060ec4fb | **Final**, 2025-12-24 |
| OIDFED-1.0 | https://openid.net/specs/openid-federation-1_0-final.html | openid-federation-1_0-final.html | 4a71afdfbed5755d6704d6a089f450f10aa9914204b283eae5fadee2897d1911 | **Final**, 2026-02-17 |
| W3C-DC-API-WD | https://www.w3.org/TR/2026/WD-digital-credentials-20260903/ | w3c-digital-credentials-wd.html | 8394193b04152645080304b8a8d37c7cdf4e484f044d9646e68612c7ae7596f5 | W3C **Working Draft**, dated snapshot 2026-09-03. Re-pinned 2026-10-09: W3C dropped a dark-mode `<meta name="color-scheme">` and `<link>` from the page; the text is unchanged (diffed). **Pinned to the dated URI, not `/TR/digital-credentials/`** — the latter is the living "latest version" and its bytes change under the pin (CI caught exactly that on 2026-09-03, first run of this branch). Protocol ids: `openid4vp-v1-unsigned/-signed/-multisigned`, `org-iso-mdoc`, `openid4vci-v1` |
| RFC9901 | https://www.rfc-editor.org/rfc/rfc9901.txt | rfc9901-sd-jwt.txt | fd4cb79184162fa7ef95f4f63abab8ee6d03c9a04c19b8f83758946464b284eb | **RFC**, Nov 2025 (was draft-ietf-oauth-selective-disclosure-jwt) |
| SD-JWT-VC-19 | https://www.ietf.org/archive/id/draft-ietf-oauth-sd-jwt-vc-19.txt | draft-ietf-oauth-sd-jwt-vc-19.txt | 394c4640c581c301adaf24d1d356238e2c290b5c9e8b130141ca0e28732144fb | Internet-Draft -19, 2026-08-31, **IETF Last Call ends 2026-09-15** |
| TSL-21 | https://www.ietf.org/archive/id/draft-ietf-oauth-status-list-21.txt | draft-ietf-oauth-status-list-21.txt | 21e4867a01f73cee2ebc1408d150c87f77898c3d1549ebc25c80fa352221f846 | Internet-Draft -21, 2026-06-21, **RFC Editor queue** |
| EUDI-PID-RULEBOOK | https://raw.githubusercontent.com/eu-digital-identity-wallet/eudi-doc-attestation-rulebooks-catalog/main/rulebooks/pid/pid-rulebook.md | pid-rulebook.md | 6251416f6f67fb6f9e5db1cddf5947d09d7bd46e4abf248d31f9f34f466b2c04 | **v1.7, 2026-07-17** — the code cites v1.6; 1.7 adds one requirement (PID key must not sign transactional data), no attribute changes |
| RFC9396 | https://www.rfc-editor.org/rfc/rfc9396.txt | rfc9396.txt | d6a8f032d8a585daae1c33a8c7b6e539d199f886ec8cc1c7898436f7f2eed29c | RFC (RAR) |
| RFC9126 | https://www.rfc-editor.org/rfc/rfc9126.txt | rfc9126.txt | a79d0e30fcc24a22b79c8e18aa82362f6e63a7b8a5d58b480e746360e97388db | RFC (PAR) |
| RFC9101 | https://www.rfc-editor.org/rfc/rfc9101.txt | rfc9101.txt | a1400b5b8d27cfabb127325458a88415f83bb04b2ff9e6facbe50b8ef4ea2b60 | RFC (JAR) |
| RFC8414 | https://www.rfc-editor.org/rfc/rfc8414.txt | rfc8414.txt | 16c816e4e0fdbffb7e910ff3017867bf39debe9cb7f52f5cbc508a052ed660e8 | RFC (AS metadata) |
| RFC7636 | https://www.rfc-editor.org/rfc/rfc7636.txt | rfc7636.txt | 1972e5d81cbaba7066cfd46374207bc2b4546b085ed5dd9b034e79e023e0ca31 | RFC (PKCE) |
| RFC9449 | https://www.rfc-editor.org/rfc/rfc9449.txt | rfc9449.txt | 3842c58e1f6043389416023b9bb8d765048266024982fbbd90640e05943f4e13 | RFC (DPoP) |
| RFC8725 | https://www.rfc-editor.org/rfc/rfc8725.txt | rfc8725.txt | 737b7013a2495dcfd5481cf4c57c87e2455d537c4cec1140c9096a71fcef0812 | RFC (JWT BCP) |
| RFC9700 | https://www.rfc-editor.org/rfc/rfc9700.txt | rfc9700.txt | 9919d061d40a97886ca866b51c69389b6c81c65cd4b979056c14fdbebfcf622a | RFC (OAuth Security BCP) |
| RFC7515 | https://www.rfc-editor.org/rfc/rfc7515.txt | rfc7515.txt | ecbf84674118e62526511c1237e1deaa86aada86d25b247623a2a7e04ae62e40 | RFC (JWS) |
| RFC7516 | https://www.rfc-editor.org/rfc/rfc7516.txt | rfc7516.txt | 722cfcddc15f58e746891ba4b846853d3711153a774e4dd55ad6db100474a21f | RFC (JWE) |
| RFC7517 | https://www.rfc-editor.org/rfc/rfc7517.txt | rfc7517.txt | 681c19b92a85068716b7e89c5815aa821bd3f11c755ff1c641b40ae9851bb33c | RFC (JWK) |
| RFC7518 | https://www.rfc-editor.org/rfc/rfc7518.txt | rfc7518.txt | 9a9ae524b09ea700ad3f189bac115df95ba69af84b26ffdbe3cdfb8d2152b1fc | RFC (JWA) |
| RFC7519 | https://www.rfc-editor.org/rfc/rfc7519.txt | rfc7519.txt | fecd930e9ccf2276b95c0017c6c4ff5d09352e4bc3c7629946447894e0f97248 | RFC (JWT) |
| RFC8949 | https://www.rfc-editor.org/rfc/rfc8949.txt | rfc8949.txt | f1164a5b31a39350ad46abe29b83575eb933ca6c45366989c118b6b1058a214a | RFC (CBOR) |
| RFC9052 | https://www.rfc-editor.org/rfc/rfc9052.txt | rfc9052.txt | 01eecd7f646537600e7aad665b1fa581ce6ec33dae4ef4add0997aaf38cd0a45 | RFC (COSE structures) |
| RFC9053 | https://www.rfc-editor.org/rfc/rfc9053.txt | rfc9053.txt | 3d470615875620375f8453ba25b8dce7e4d0271e76b0b79a46df34ccb2d56ab0 | RFC (COSE algorithms) |
| RFC9360 | https://www.rfc-editor.org/rfc/rfc9360.txt | rfc9360.txt | 3dbe546adf08e309b429c8e71b2ee8384292fb8767338d3eb17d1c4e5adefc23 | RFC (COSE x5chain) |
| RFC5280 | https://www.rfc-editor.org/rfc/rfc5280.txt | rfc5280.txt | a2f2628c0a83b873fc4786abd921f9b2c02395954b655d190bf16b831633345d | RFC (X.509 PKIX) |
| RFC6749 | https://www.rfc-editor.org/rfc/rfc6749.txt | rfc6749.txt | f204fc8661d6c92d2ec6e0b54808f961a9ad26e792f57f312d9528335519bd71 | RFC (OAuth 2.0) |
| RFC9068 | https://www.rfc-editor.org/rfc/rfc9068.txt | rfc9068.txt | 68d3ff3910c0f2340fd7b93b430e00053da845b6eebe095ebef0c8bfda5e14c5 | RFC (JWT access tokens) |
| RFC8693 | https://www.rfc-editor.org/rfc/rfc8693.txt | rfc8693.txt | 358d658014738bf4dc56c8aae2094ce716ede23b6d5a80488a7dc8e8d72da609 | RFC (Token Exchange) |
| RFC8785 | https://www.rfc-editor.org/rfc/rfc8785.txt | rfc8785.txt | 63d52294eb0e3f0014174288186d388b4ddbf2c67d1ce8af1d9726eb0c3ab240 | RFC (JCS) |

## ISO/IEC — licensed, supplied by hand, never committed

| ID | Document | File (from pdftotext) | Status |
|---|---|---|---|
| ISO18013-5-DIS2026 | ISO/IEC DIS 18013-5:2026(en) — mDL application, 2nd edition **Draft International Standard** (ballot 2026-01-01 → 2026-03-26), 184 pp | iso-18013-5-dis-2026.txt | Replaces the WG10 N2549 / CD-ballot-resolution working drafts previously cited in GAP-REGISTER §1 |
| ISO18013-7-2025 | ISO/IEC TS 18013-7:2025(en) — mDL add-on functions, **2nd edition, published 2025-05**, 50 pp | iso-18013-7-2025.txt | Cancels and replaces TS 18013-7:2024. Annex B still profiles OID4VP **Draft 18** (April 2023), not 1.0 — see the matrix's P-01 row |

Place the PDFs in `.specs/` (gitignored). `fetch-corpus.sh` converts them if
`pdftotext` is installed. ISO rows in `requirements.jsonl` carry the clause number
and a hash of the sentence, **not the sentence** — the text is licensed.

## What is deliberately not here

- **ISO/IEC 23220 series** (building blocks for mdoc; referenced by OID4VP B.2 for
  non-mDL doctypes). Not held; the mdoc code targets 18013-5 and treats other
  doctypes structurally. Recorded as a gap in the matrix, not silently omitted.
- **ICAO Doc 9303** (ePassport). The passport reader cites it, but the PDFs are
  large and the passport path is a proofing input, not a credential protocol
  surface. Recorded as a gap in the matrix.
- **OID4VCI 1.1 / OID4VP 1.1 drafts.** Not Final; the code targets 1.0 Final and
  HAIP 1.0, which pin 1.0.
