# Quickstart

The whole platform on one machine, from this release. Fresh, it takes about ten
minutes; most of that is PingFederate starting.

## You need

- **Docker** (Docker Desktop, or Docker Engine with the compose plugin).
- **Terraform** 1.5 or later - it configures PingFederate from `pingfederate/terraform`.
- **curl.**
- A **PingFederate licence.** A free Ping DevOps account gives one: set
  `PING_IDENTITY_DEVOPS_USER` and `PING_IDENTITY_DEVOPS_KEY` and the script fetches
  it, or put a licence at `pingfederate/terraform/pingfederate.lic`.

No Node, Java or OpenSSL: the setup tools run in this release's tools image.

## Steps

1. **Get the release's assets.** Download every file attached to the release
   whose number is in `VERSION` - the WARs, the jars and `SHA256SUMS` - into
   `assets/` at the top of this repository. Or set `PFVC_RELEASE_URL` to the
   release's download URL and the script fetches them.

2. **Stand it up.**

   ```bash
   ./scripts/stack-up.sh
   ```

   It refuses any asset that does not match `SHA256SUMS`. A clean run ends with
   every check `ok` and the URLs below.

3. **Use it.**

   | URL | What |
   |---|---|
   | `https://pf.localhost:9443` | PingFederate: issuer `/pf-oid4vci`, verifier `/pf-oid4vp`, trust services `/pf-dts`, wallet provider `/pf-wallet-provider` |
   | `https://wallet.localhost:9443` | web wallet |
   | `https://portal.localhost:9443` | holder portal |
   | `https://localhost:9899/pingfederate/app` | PingFederate admin console |

   The administrator and the quickstart holder (`quickstart-holder`) have passwords in
   `.compose/secrets.json`. Browsers warn once per host unless you trust
   `.compose/certs/ca.crt`.

## Everyday

```bash
./scripts/stack-up.sh --check    # the checks again, against the running stack
docker compose down              # stop; keeps PingFederate's configuration and the identity store
docker compose down -v && rm -rf .compose    # forget everything, keys included
```

`.compose/` holds the stack's keys, certificates and secrets. It is one local
trust domain: remove it and the volumes together, or not at all.

**Ports.** `STACK_PORT` (default 9443) moves the public port and `PF_ADMIN_PORT`
(default 9899) the admin console. A second stack on the same machine needs its
own `COMPOSE_PROJECT_NAME` as well as its own ports.
