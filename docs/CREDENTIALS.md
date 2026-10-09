# Configuring credentials

How to define and configure the credential types your platform issues and
verifies. The set of credentials is mostly **data**, not code: one catalogue
entry drives both the issuer and the verifier, so they can't drift.

Read [ARCHITECTURE.md](ARCHITECTURE.md) for the two formats first.

## The one source of truth: the catalogue

Every credential type is one entry in `CREDENTIAL_CATALOG`
(`packages/shared/src/index.ts`). The issuer derives its OID4VCI metadata from
it and the verifier derives its DCQL from it, so a new credential appears in
both the moment you add the entry.

```ts
export interface CatalogEntry {
  id: string;          // OID4VCI credential_configuration_id, e.g. 'pid-sd-jwt'
  format: 'dc+sd-jwt' | 'mso_mdoc';
  display: string;     // human name, e.g. 'Person Identification Data'
  scope: string;       // groups the sd-jwt/mdoc pair, e.g. 'pid'
  vct?: string;        // SD-JWT only: the credential type URI, e.g. 'urn:eudi:pid:1'
  doctype?: string;    // mdoc only: e.g. 'org.iso.18013.5.1.mDL'
  namespace?: string;  // mdoc only: e.g. 'org.iso.18013.5.1'
  claims: string[];    // the claim/element names to issue and disclose
}
```

The catalogue already carries: the EUDI PID in both formats (`pid-sd-jwt`,
`pid-mdoc`), the mDL (`mdl-mdoc`), proof-of-age in both, an ePassport, Medicare,
a bank-account and a loyalty card. Use these as templates.

## The trap that this repo takes seriously: claim NAMES are not portable

The same attribute has **different names in SD-JWT and mdoc**, and getting it
wrong produces a credential that looks right and fails interop. From the real
PID entries:

| Attribute | SD-JWT claim | mdoc element | Value shape |
|---|---|---|---|
| date of birth | `birthdate` | `birth_date` | full-date |
| nationality | `nationalities` (array) | `nationality` (array) | alpha-2 codes |
| portrait | `picture` (data URL) | `portrait` (byte string) | JPEG |
| place of birth | `place_of_birth` | `place_of_birth` (object) | object |

**Use the names the credential's rulebook fixes, not the attribute's plain
name.** For the EUDI PID, that's the PID Rulebook §3.1.2 (mdoc) / §3.2 (SD-JWT).
The catalogue comments cite the clause for each. When in doubt, the conformance
suite (`conformance/test-pid-rulebook.mjs`) asserts these names against the
rulebook — add a credential, add its assertions.

## Adding a credential — the four steps

Worked with a hypothetical "diploma" SD-JWT VC.

### 1. Add the catalogue entry

```ts
// packages/shared/src/index.ts
{
  id: 'diploma-sd-jwt',
  format: 'dc+sd-jwt',
  display: 'University Diploma',
  scope: 'diploma',
  vct: 'https://credentials.example/diploma/1',
  claims: ['given_name', 'family_name', 'degree', 'institution', 'conferred_date'],
},
```

The issuer now advertises it in `/.well-known/openid-credential-issuer` and the
wallet's "Add to wallet" picker shows it — no other change for a plain SD-JWT.

### 2. Supply the claim values (`holderSubject`)

The issuer builds the credential from the person's real data, keyed by the
credential id, in `HolderSubject.forConfig()` (`pf-ext/pf-oid4vci/.../HolderSubject.java`):

```ts
case 'diploma-sd-jwt': {
  const dip = doc('diploma');           // a document from the SCIM store
  if (!dip) return { error: 'No diploma on your identity profile.' };
  return { ok: {
    given_name: givenName, family_name: familyName,
    degree: s(dip.degree), institution: s(dip.institution), conferred_date: s(dip.conferred_date),
  }};
}
```

Values come from the SCIM profile/documents — never sample data. Omit a claim
(don't invent it) when the evidence doesn't carry it; the issuer skips
empty/absent claims.

### 3. Shape the values if a rulebook fixes them (encodings)

Plain string claims need nothing. When a rulebook fixes a value's *shape* (an
alpha-2 array, a data URL, a full-date, a byte string), add an encoder keyed by
`vct` (SD-JWT) or `doctype` (mdoc):

- `SD_JWT_ENCODINGS` (keyed by vct) and `MDOC_ENCODINGS` (keyed by doctype) in
  `pf-ext/pf-oid4vci/.../HolderSubject.java` (the TypeScript issuer that used to hold this was retired on 2026-09-13).
- These are where `nationalities` becomes an alpha-2 array, `picture` becomes a
  data URL, `birth_date` becomes a CBOR full-date, `portrait` becomes a byte
  string. Each encoder is idempotent and returns `undefined` to drop a value it
  can't represent (better a missing claim than a malformed one).

### 4. Let the verifier ask for it (DCQL)

The verifier requests specific credentials + claims via DCQL. Today the built-in
queries (`Dcql.forCatalogId()` / `Dcql.pid()` in
`pf-ext/pf-oid4vp`) cover the PID and mDL. To request your new credential, add a
DCQL entry naming its `vct`/`doctype` and the claim paths you want. The wallet
matches by `vct`/`doctype` generically — no wallet change needed.

## Issuance policy: consent and face-verification

Beyond *what* is in a credential, you control *whether* it issues, per type, in
the SCIM **credential policies** store:

- `require_consent` + `consent_prompt` — the wallet shows a consent step before
  issuing (the iOS/web wallet handle `consent_required`).
- `require_face_verification` — issuance is gated on a passed biometric check.
- `enabled` — turn a type off without removing it.

Read/write them via SCIM (`GET/PUT /policies/{id}`) or the issuer's admin UI.
The issuer caches and enforces them at issuance time.

## Trust material for a new credential

- **SD-JWT VC** — verifiers resolve your issuer's signing keys from
  `/.well-known/jwt-vc-issuer`. Nothing per-credential; the issuer signs with
  its configured key.
- **mdoc** — the credential is rooted in the IACA → Document Signer chain. The
  IACA anchor is published by **DTS** (`/pf-dts/pki/iaca.pem`); a verifier
  trusts mdocs that chain to it. Generate this PKI **offline** and load it into
  the issuer (`MDOC_IACA_PEM`/`MDOC_DS_PEM`/`MDOC_DS_JWK`) — see BUILD.md step 2.
- **Revocation** — a credential that carries a `status.status_list` reference is
  revocable via DTS: allocate an index at issuance, flip it with the DTS admin
  API, and the verifier enforces it.

## Verify your new credential end to end

Add it to the flow the repo already runs:

1. A conformance assertion for any fixed encoding (mirror `test-pid-rulebook.mjs`).
2. The e2e (`scripts/e2e.mjs`) — issue it, then present it, assert the claims.
3. Run `./conformance/run.sh` — it must stay green (the catalogue-parity, issuance and DCQL suites read `catalog/`).

The rule holds for credentials too: **anchor the encoding to its rulebook, and
prove issue-then-present works, before shipping.**
