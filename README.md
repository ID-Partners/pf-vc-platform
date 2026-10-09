# A PingFederate-based verifiable-credential platform

Turn **PingFederate** into a verifiable-credential platform: an **issuer**
(OID4VCI 1.0), a **verifier** (OID4VP 1.0 + HAIP), **Digital Trust Services**
(revocation status lists, certificate anchors, VICAL and RICAL trust lists) and a
**wallet provider**, with a holder portal beside it and a web wallet for the
quickstart. It issues and verifies **SD-JWT VC** and **ISO/IEC 18013-5 mdoc
(mDL)** credentials.

This repository is a **release**: compiled PingFederate extensions, container
images, configuration and docs. It holds no source code and is written by the
release process - changes made here by hand are overwritten by the next release.

## Run it

```bash
./scripts/stack-up.sh
```

[QUICKSTART.md](QUICKSTART.md) has the prerequisites (Docker, Terraform, curl and
a free Ping DevOps account for the PingFederate licence) and the steps. The
script builds a PingFederate image on your machine from Ping's public image and
this release's extensions, pulls the other images, configures PingFederate from
`pingfederate/terraform`, then proves the stack end to end: it issues an SD-JWT
PID and an mdoc mDL, presents both to the verifier, and signs the quickstart's
holder in at PingFederate and at the portal.

## What's here

| Path | What |
|---|---|
| `VERSION` | the release this tree belongs to |
| `docker-compose.yml` | the whole platform on one machine; every image pinned by digest |
| `scripts/stack-up.sh` | stands the stack up from this release and checks it |
| `pingfederate/terraform/` | PingFederate's configuration, as code: what a deployment applies |
| `pingfederate/quickstart/` | what the local stack adds on top: a test holder's login and a relying-party client. Never part of a deployment |
| `services/pingfederate/` | the recipe for the PingFederate image: Ping's image plus the release's WARs and jars |
| `catalog/` | the credential types the platform issues |
| `policy/` | the issuance policy |
| `compose/` | the local TLS edge |
| `docs/` | how the platform works: architecture, credentials, trust lists, keys, the identity store |
| `conformance/` | the standards conformance matrix and coverage dashboard for this release |

The WARs and plugin jars are this release's assets, beside a `SHA256SUMS` the
stack checks before it uses them.

## Licence

Configuration, scripts and documentation in this repository are under the
[Apache License 2.0](LICENSE). The compiled extensions and container images
are under the evaluation terms in [BINARY-LICENSE.md](BINARY-LICENSE.md).
PingFederate itself is Ping Identity's and is not redistributed: your machine
pulls Ping's public image and you accept Ping's licence for it.
