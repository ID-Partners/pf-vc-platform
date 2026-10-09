#!/usr/bin/env bash
#
# Stand the whole platform up locally with docker-compose.yml, configured from
# this repository and nothing else, then prove it answers.
#
#   ./scripts/stack-up.sh            everything below, idempotently
#   ./scripts/stack-up.sh --check    only step 9, against a stack already up
#
# Two modes, one script (scripts/stack-lib.sh; design/repo-split.md):
#   source   (the default in idp-pf-vcs)  the PF extensions built from pf-ext/ and
#            every image built from this checkout
#   release  (the default in the public repo)  the extensions from the release's
#            assets/, checked against its SHA256SUMS, and every image but
#            PingFederate's pulled. STACK_MODE=release runs it here.
# Either way the host needs Docker, Terraform and curl - and source mode Maven and
# git for stage-pf.sh. Node and OpenSSL run in the tools image (services/tools).
#
#   1. a PingFederate licence   pingfederate/terraform/pingfederate.lic, fetched with
#                               PING_IDENTITY_DEVOPS_USER/_KEY when it is missing
#   2. the stack's TLS          a local CA and one certificate for the *.localhost hosts
#   3. secrets and keys         .compose/secrets.json, the PKI (pki-quickstart.mjs),
#                               the attestation keys (keygen-attestation.mjs)
#   4. configuration            .compose/*.env + terraform.tfvars.json (stack-env.mjs)
#   5. images                   source: pf-ext built and staged (stage-pf.sh), compose
#                               builds the rest. release: the assets checked and
#                               staged, PingFederate built, the rest pulled
#   6. start PingFederate       docker compose up pingfederate, until it is healthy
#   7. configure PingFederate   pingfederate/terraform applied to it; restarted if that
#                               changed anything, so the extensions load their keys;
#                               then everything else is started against it
#   8. quickstart holder        quickstart-holder in SCIM, matching the quickstart login (stack-seed.mjs)
#   9. check                    every public surface answers, and the stack issues and
#                               verifies end to end (stack-e2e.sh)
#
# Everything generated lives in .compose/ (gitignored, never in an image). It is
# ONE local trust domain: delete .compose/ and `docker compose down -v` together
# to found another. STACK_PORT (default 9443) is the public port, and is part of
# every identifier - the PKI is minted for it, so changing it means a new .compose/.
# PF_ADMIN_PORT (default 9899) moves the admin console.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
STATE=$ROOT/.compose
TF=$ROOT/pingfederate/terraform
LIC=$TF/pingfederate.lic
export PF_ADMIN_PORT=${PF_ADMIN_PORT:-9899}
export STACK_PORT=${STACK_PORT:-9443}
# docker-compose.yml names its project, so every checkout's stack is the SAME
# project unless COMPOSE_PROJECT_NAME says otherwise - and an `up` from a second
# worktree silently replaces the first one's containers and images, on the first
# one's volumes (2026-09-30: it locked the other stack's PingFederate admin). A
# second stack needs its own COMPOSE_PROJECT_NAME, STACK_PORT and PF_ADMIN_PORT.
PROJECT=${COMPOSE_PROJECT_NAME:-idp-pf-vcs}
export COMPOSE_PROJECT_NAME=$PROJECT
PF=https://pf.localhost:$STACK_PORT
. scripts/stack-lib.sh
trap tool_stop EXIT

say() { printf '\n==> %s\n' "$*"; }
die() { echo "stack-up: $*" >&2; exit 1; }

check_only=false
[ "${1:-}" = "--check" ] && check_only=true

# Refuse to touch a project another checkout is running.
if command -v docker >/dev/null; then
  others=$(docker ps -a --filter "label=com.docker.compose.project=$PROJECT" \
    --format '{{.Label "com.docker.compose.project.working_dir"}}' 2>/dev/null | sort -u | grep -vx "$ROOT" || true)
  [ -z "$others" ] || die "compose project '$PROJECT' belongs to another checkout ($others). Leave it alone: run this one as
  COMPOSE_PROJECT_NAME=<another name> STACK_PORT=<another port> PF_ADMIN_PORT=<another port> $0"
fi

need=(docker curl terraform)
[ "$STACK_MODE" = source ] && need+=(mvn git)
for t in "${need[@]}"; do
  command -v "$t" >/dev/null || die "needs $t on PATH (QUICKSTART.md in a release, docs/BUILD.md in the source repo)"
done

# ---------------------------------------------------------------------------
# 9. check - defined first so --check can run it alone.
# ---------------------------------------------------------------------------
check() {
  say "checking the stack"
  export NODE_EXTRA_CA_CERTS=$STATE/certs/ca.crt
  tool_net
  local fail=0
  probe() { # name url expect-substring
    local body
    body=$(curl -fsS --max-time 10 --cacert "$STATE/certs/ca.crt" "$2" 2>&1) || { echo "  FAIL $1: $2 -> $body"; fail=1; return; }
    if [ -n "${3:-}" ] && ! grep -q -- "$3" <<<"$body"; then
      echo "  FAIL $1: $2 has no '$3': ${body:0:300}"; fail=1; return
    fi
    echo "  ok   $1"
  }
  probe "PingFederate runtime"        "$PF/pf/heartbeat.ping"
  probe "OpenID configuration"        "$PF/.well-known/openid-configuration" "\"issuer\":\"$PF\""
  probe "attest_jwt_client_auth"      "$PF/.well-known/oauth-authorization-server" "attest_jwt_client_auth"
  probe "issuer (pf-oid4vci)"         "$PF/pf-oid4vci/health" '"status_lists":"armed"'
  probe "issuer metadata"             "$PF/.well-known/openid-credential-issuer/pf-oid4vci" "\"credential_issuer\":\"$PF/pf-oid4vci\""
  probe "verifier (pf-oid4vp)"        "$PF/pf-oid4vp/health" '"reader":"x509_hash:'
  probe "trust services (pf-dts)"     "$PF/pf-dts/health" '"ok":true'
  probe "wallet provider"             "$PF/pf-wallet-provider/health"
  for root in iaca reader-root sdjwt-issuer-ca vical-root rical-root; do
    probe "CRL $root"                 "$PF/pf-dts/pki/$root.crl"
  done
  probe "web wallet"                  "https://wallet.localhost:$STACK_PORT/health"
  probe "portal"                      "https://portal.localhost:$STACK_PORT/health"
  # The microsite is private: it runs from a source checkout and never ships in a release.
  [ "$STACK_MODE" = source ] && probe "docs (source checkout only)" "https://docs.localhost:$STACK_PORT/"
  # Every root's CRL is current and is what pf-dts serves (G-60).
  if TOOL_ENV=NODE_EXTRA_CA_CERTS tool node scripts/pki-crls.mjs status --pki "$STATE/pki" --base "$PF" >/dev/null 2>&1; then
    echo "  ok   every root's CRL current and published"
  else
    echo "  FAIL CRLs: scripts/pki-crls.mjs status --pki .compose/pki --base $PF (in the tools image)"; fail=1
  fi
  # Answering is not working: issue both formats, present them, and sign in.
  ./scripts/stack-e2e.sh || fail=1
  [ $fail = 0 ] || die "the stack is up but not healthy - see FAIL lines; docker compose logs <service>"
  cat <<EOF

The stack is up.
  PingFederate   $PF                   admin https://localhost:$PF_ADMIN_PORT/pingfederate/app
  web wallet     https://wallet.localhost:$STACK_PORT      portal  https://portal.localhost:$STACK_PORT
$( [ "$STACK_MODE" = source ] && echo "  docs           https://docs.localhost:$STACK_PORT")
  Logins: PF admin 'administrator', holder 'quickstart-holder' - passwords in .compose/secrets.json.
  Browsers warn once per host unless you trust .compose/certs/ca.crt (docs/BUILD.md).
EOF
}

if $check_only; then check; exit 0; fi

mkdir -p "$STATE" && chmod 700 "$STATE"

# The tools image comes first: steps 2-4 run in it.
say "0. tools ($STACK_MODE mode, version $VERSION)"
if [ "$STACK_MODE" = source ]; then
  docker compose --profile tools build tools
else
  docker image inspect "$TOOLS_IMAGE" >/dev/null 2>&1 || docker pull "$TOOLS_IMAGE"
fi
echo "   $TOOLS_IMAGE"

# ---------------------------------------------------------------------------
say "1. PingFederate licence"
if [ ! -s "$LIC" ]; then
  [ -n "${PING_IDENTITY_DEVOPS_USER:-}" ] && [ -n "${PING_IDENTITY_DEVOPS_KEY:-}" ] ||
    die "no $LIC - set PING_IDENTITY_DEVOPS_USER and PING_IDENTITY_DEVOPS_KEY (a free Ping DevOps account) to fetch one"
  curl -fsS https://license.pingidentity.com/devops/license \
    -H "product: PingFederate" -H "version: 13.1" \
    -H "devops-user: $PING_IDENTITY_DEVOPS_USER" -H "devops-key: $PING_IDENTITY_DEVOPS_KEY" \
    -H "devops-app: pingfederate" -H "devops-purpose: get-license" -o "$LIC"
fi
grep -q '^Product=PingFederate' "$LIC" || die "$LIC is not a PingFederate licence"
echo "   $(grep '^ExpirationDate=' "$LIC")"

# ---------------------------------------------------------------------------
say "2. TLS for *.localhost"
CERTS=$STATE/certs
mkdir -p "$CERTS"
if [ ! -s "$CERTS/ca.crt" ]; then
  cat > "$CERTS/ca.cnf" <<'EOF'
[req]
distinguished_name = dn
[dn]
[ca]
basicConstraints = critical,CA:TRUE,pathlen:0
keyUsage = critical,keyCertSign,cRLSign
subjectKeyIdentifier = hash
EOF
  tool openssl req -x509 -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -keyout "$CERTS/ca.key" -out "$CERTS/ca.crt" -days 3650 \
    -subj "/CN=idp-pf-vcs local stack CA" -config "$CERTS/ca.cnf" -extensions ca 2>/dev/null
  rm -f "$CERTS/stack.crt"
fi
# The server certificate: re-issued under the same CA when it is inside 30 days
# of expiry, so a trusted CA stays trusted. 397 days - what browsers accept.
if [ ! -s "$CERTS/stack.crt" ] || ! tool openssl x509 -in "$CERTS/stack.crt" -noout -checkend 2592000 >/dev/null; then
  cat > "$CERTS/stack.cnf" <<'EOF'
[req]
distinguished_name = dn
[dn]
[leaf]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = serverAuth
subjectAltName = DNS:pf.localhost,DNS:wallet.localhost,DNS:portal.localhost,DNS:docs.localhost
EOF
  tool openssl req -new -newkey ec -pkeyopt ec_paramgen_curve:P-256 -nodes \
    -keyout "$CERTS/stack.key" -out "$CERTS/stack.csr" -subj "/CN=pf.localhost" -config "$CERTS/stack.cnf" 2>/dev/null
  tool openssl x509 -req -in "$CERTS/stack.csr" -CA "$CERTS/ca.crt" -CAkey "$CERTS/ca.key" -CAcreateserial \
    -out "$CERTS/stack.crt" -days 397 -extfile "$CERTS/stack.cnf" -extensions leaf 2>/dev/null
  rm -f "$CERTS/stack.csr"
fi
chmod 600 "$CERTS"/*.key
chmod 644 "$CERTS"/*.crt # read by containers running as other users (PingFederate is uid 9031)
echo "   CA $CERTS/ca.crt"

# ---------------------------------------------------------------------------
say "3. secrets, PKI and attestation keys"
# Merged, never regenerated: a secret already in the file keeps its value, and one
# added since (G-92's scim_data_key and portal_client_secret) is minted into it.
tool node --input-type=module -e "
  import { randomBytes } from 'node:crypto';
  import { existsSync, readFileSync, writeFileSync } from 'node:fs';
  const r = (n = 24) => randomBytes(n).toString('base64url').replace(/[-_]/g, 'x');
  const f = '$STATE/secrets.json';
  const have = existsSync(f) && readFileSync(f, 'utf8').trim() ? JSON.parse(readFileSync(f, 'utf8')) : {};
  const want = {
    // PingFederate's password policy wants mixed case, a digit and a symbol.
    pf_admin_password: () => 'Pf1!' + r(18), quickstart_holder_password: () => 'Qs1!' + r(12),
    issuer_svc_secret: r, verifier_svc_secret: r, portal_svc_secret: r, vci_svc_secret: r,
    vp_wallet_login_secret: r, quickstart_rp_secret: r,
    session_secret: () => r(32), scim_db_password: r, p12_password: () => r(18),
    // The identity store's data key: 32 random bytes, base64 (docs/SCIM-OPERATIONS.md).
    scim_data_key: () => randomBytes(32).toString('base64'),
    // The portal's PingFederate client (portal_client.tf wants 32+ characters).
    portal_client_secret: () => r(32),
  };
  const s = { ...have };
  // Renamed 2026-10-09 from demo_user_password: a stack made before keeps its password.
  if (s.demo_user_password && !s.quickstart_holder_password) s.quickstart_holder_password = s.demo_user_password;
  delete s.demo_user_password;
  for (const [k, make] of Object.entries(want)) if (!s[k]) s[k] = make();
  writeFileSync(f, JSON.stringify(s, null, 2) + '\\n', { mode: 0o600 });"
# The PKI names the origin it was minted for (issuer id, CRL URLs), so it and the
# port go together: a different STACK_PORT is a different trust domain.
if [ -d "$STATE/pki" ] && [ "$(cat "$STATE/pki-origin" 2>/dev/null)" != "$PF" ]; then
  die "$STATE/pki was minted for $(cat "$STATE/pki-origin" 2>/dev/null || echo 'another origin'), not $PF - to change STACK_PORT, docker compose down -v and remove .compose/"
fi
if [ ! -d "$STATE/pki" ]; then
  P12_PASSWORD=$(secret p12_password) TOOL_ENV=P12_PASSWORD \
    tool node scripts/pki-quickstart.mjs --out "$STATE/pki" --host pf.localhost --port "$STACK_PORT" \
      --pf-upstream-host pingfederate >/dev/null
  echo "$PF" > "$STATE/pki-origin"
fi
[ -s "$STATE/attestation.json" ] || (umask 077 && tool node scripts/keygen-attestation.mjs > "$STATE/attestation.json")
echo "   $STATE/{secrets.json,pki/,attestation.json}"

# ---------------------------------------------------------------------------
say "4. configuration"
tool node scripts/stack-env.mjs --state "$STATE"

# ---------------------------------------------------------------------------
say "5. images"
if [ "$STACK_MODE" = source ]; then
  ./scripts/stage-pf.sh >/dev/null
  docker compose build
else
  # The release's WARs and jars, from assets/ (or PFVC_ASSETS) - fetched from
  # PFVC_RELEASE_URL when they are not there - and refused unless every one
  # matches SHA256SUMS. Then staged exactly where stage-pf.sh puts them.
  ASSETS=${PFVC_ASSETS:-$ROOT/assets}
  if [ ! -s "$ASSETS/SHA256SUMS" ]; then
    [ -n "${PFVC_RELEASE_URL:-}" ] ||
      die "no $ASSETS/SHA256SUMS - download release $VERSION's assets into $ASSETS (QUICKSTART.md), or set PFVC_RELEASE_URL to the release's download URL"
    mkdir -p "$ASSETS"
    curl -fsSL "$PFVC_RELEASE_URL/SHA256SUMS" -o "$ASSETS/SHA256SUMS"
    while read -r _ f; do curl -fsSL "$PFVC_RELEASE_URL/$f" -o "$ASSETS/$f"; done < "$ASSETS/SHA256SUMS"
  fi
  if command -v sha256sum >/dev/null; then sum=(sha256sum); else sum=(shasum -a 256); fi
  (cd "$ASSETS" && "${sum[@]}" -c --quiet SHA256SUMS) || die "$ASSETS does not match its SHA256SUMS - download the release again"
  grep -q " pf-dts-$VERSION.war\$" "$ASSETS/SHA256SUMS" || die "$ASSETS holds another release than $VERSION (VERSION)"
  mkdir -p services/pingfederate/deploy services/pingfederate/runtime
  rm -f services/pingfederate/deploy/*.war services/pingfederate/deploy/*.jar services/pingfederate/runtime/*.jar
  while read -r _ f; do
    case $f in
      pf-wallet-attest-*.jar) cp "$ASSETS/$f" services/pingfederate/runtime/pf-wallet-attest.jar ;;
      *.war|*.jar)            cp "$ASSETS/$f" "services/pingfederate/deploy/${f%-"$VERSION".*}.${f##*.}" ;;
    esac
  done < "$ASSETS/SHA256SUMS"
  ls services/pingfederate/deploy/ services/pingfederate/runtime/ | sed 's/^/   /'
  docker compose build pingfederate
  docker compose pull --ignore-buildable --quiet
fi

# ---------------------------------------------------------------------------
say "6. start"
# A PingFederate volume created by THIS up is an empty PingFederate: whatever
# terraform state says about the last one describes objects that are gone.
fresh_pf=false
docker volume inspect "${PROJECT}_pf-data" >/dev/null 2>&1 || fresh_pf=true
if $fresh_pf; then rm -f "$STATE/terraform.tfstate" "$STATE/terraform.tfstate.backup"; fi
# PingFederate alone first: everything else reads from a CONFIGURED PingFederate
# at start-up (the wallet fetches the reader trust anchor once), and until step 7
# gives it the runtime certificate the gateway verifies (G-110), the gateway
# rightly refuses it.
docker compose up -d --wait --wait-timeout 900 pingfederate

# ---------------------------------------------------------------------------
say "7. configure PingFederate"
ADMIN=https://localhost:$PF_ADMIN_PORT/pf-admin-api/v1
# Terraform logs in wherever terraform.tfvars.json says. If that is not THIS
# stack's admin port it is another stack's PingFederate, and this stack's
# password locks that one's administrator out (2026-10-01) - so it is checked.
grep -q "\"pf_admin_host\": \"https://localhost:$PF_ADMIN_PORT\"" "$STATE/terraform.tfvars.json" ||
  die "$STATE/terraform.tfvars.json names another PingFederate than https://localhost:$PF_ADMIN_PORT - rerun from step 4"
PW=$(secret pf_admin_password)
admin() { # method path [json] -> HTTP status; the body lands in $STATE/admin-response.json
  curl -sk -u "administrator:$PW" -H 'X-XSRF-Header: PingFederate' -H 'Content-Type: application/json' \
    -o "$STATE/admin-response.json" -w '%{http_code}' -X "$1" "$ADMIN$2" ${3:+--data "$3"}
}
for _ in $(seq 1 60); do
  [ "$(admin GET /version)" = 200 ] && break
  sleep 5
done
[ "$(admin GET /version)" = 200 ] || die "PingFederate's admin API refuses the administrator: $(cat "$STATE/admin-response.json")"
# The two objects the provider has no resource for (vci_client.tf says why): the
# RAR processor instance and the openid_credential authorization-detail type the
# vci-svc client names. Created once, before terraform needs them.
if [ "$(admin GET /oauth/authorizationDetailProcessors/vcrar)" != 200 ]; then
  code=$(admin POST /oauth/authorizationDetailProcessors \
    '{"id":"vcrar","name":"VC Credential (openid_credential)","pluginDescriptorRef":{"id":"au.idp.pf.rar.RarProcessor"},"configuration":{"fields":[],"tables":[]}}')
  [ "$code" = 201 ] || die "creating the RAR processor: HTTP $code $(cat "$STATE/admin-response.json")"
fi
if ! curl -sk -u "administrator:$PW" -H 'X-XSRF-Header: PingFederate' "$ADMIN/oauth/authorizationDetailTypes" | grep -q '"type":"openid_credential"'; then
  code=$(admin POST /oauth/authorizationDetailTypes \
    '{"id":"openidcredential","type":"openid_credential","description":"OID4VCI Credential Request","authorizationDetailProcessorRef":{"id":"vcrar"},"active":true}')
  [ "$code" = 201 ] || die "creating the openid_credential type: HTTP $code $(cat "$STATE/admin-response.json")"
fi
# runtime_tls.tf keeps the admin console's certificate as it is, by id - and a new
# PingFederate made that certificate itself, under an id of its own choosing.
[ "$(admin GET /keyPairs/sslServer/settings)" = 200 ] || die "reading PingFederate's SSL settings: $(cat "$STATE/admin-response.json")"
ADMIN_SSL_KEY=$(tool node -p "require('$STATE/admin-response.json').adminConsoleCertRef.id")
# The directory terraform runs in: the product's configuration (pingfederate/terraform,
# exactly what a deployment applies) with the quickstart overlay linked in beside it
# (pingfederate/quickstart: the quickstart holder's login), and in a source checkout
# the OpenID Foundation suite's clients when their keys exist (conformance/oidf/terraform).
# Links, rebuilt every run, so a file removed from either side leaves with it.
TFW=$STATE/terraform
mkdir -p "$TFW"
find "$TFW" -maxdepth 1 -type l -delete
for f in "$TF"/*.tf "$ROOT"/pingfederate/quickstart/*.tf "$TF/.terraform.lock.hcl" "$LIC"; do ln -s "$f" "$TFW/"; done
OIDF_KEYS=$ROOT/conformance/oidf/.keys/suite-clients.public.jwks.json
oidf_args=()
if [ "$STACK_MODE" = source ] && [ -f "$OIDF_KEYS" ]; then
  for f in "$ROOT"/conformance/oidf/terraform/*.tf; do ln -s "$f" "$TFW/"; done
  oidf_args=(-var "oidf_suite_public_jwks_path=$OIDF_KEYS")
  echo "   with the OpenID Foundation suite's clients (conformance/oidf/terraform)"
fi
(
  cd "$TFW"
  [ -d .terraform ] || terraform init -input=false >/dev/null
  # Its own state, beside the rest of this stack - never the working directory's
  # terraform.tfstate, which belongs to whatever instance that checkout manages.
  args=(-input=false -state="$STATE/terraform.tfstate" -var-file="$STATE/terraform.tfvars.json"
        -var-file="$STATE/pki/pf-import/pki.auto.tfvars" -var-file="$STATE/pki/internal-tls/runtime-tls.auto.tfvars"
        -var "pf_admin_console_ssl_key_id=$ADMIN_SSL_KEY" ${oidf_args[@]+"${oidf_args[@]}"})
  set +e; terraform plan "${args[@]}" -detailed-exitcode -out="$STATE/tfplan" >"$STATE/terraform-plan.log" 2>&1; rc=$?; set -e
  case $rc in
    0) echo "   PingFederate already matches pingfederate/terraform (+ quickstart)" ;;
    2) terraform apply -input=false -state="$STATE/terraform.tfstate" "$STATE/tfplan" >"$STATE/terraform-apply.log" 2>&1 ||
         { tail -40 "$STATE/terraform-apply.log"; exit 1; }
       grep -E '^Apply complete' "$STATE/terraform-apply.log" | sed 's/^/   /'
       touch "$STATE/.pf-restart" ;;
    *) tail -40 "$STATE/terraform-plan.log"; exit 1 ;;
  esac
) || die "terraform failed - full output in .compose/terraform-*.log"
rm -f "$STATE/tfplan"
if [ -e "$STATE/.pf-restart" ]; then
  # The extensions resolve their keypair ids when they start; ids that did not
  # exist yet at the first boot resolve now.
  say "   restarting PingFederate so the extensions load what terraform imported"
  docker compose restart pingfederate
  docker compose up -d --wait --wait-timeout 900 pingfederate
  rm -f "$STATE/.pf-restart"
fi

say "   starting everything else"
docker compose up -d --wait --wait-timeout 300

# Every root's certificate and CRL, published by pf-dts: relying parties refuse
# everything under a root whose CRL they cannot fetch (G-60).
tool_net
PF_TOKEN_URL=$PF/as/token.oauth2 PF_DTS_ADMIN_CLIENT_ID=portal-svc \
  PF_DTS_ADMIN_CLIENT_SECRET=$(secret portal_svc_secret) NODE_EXTRA_CA_CERTS=$STATE/certs/ca.crt \
  TOOL_ENV="PF_TOKEN_URL PF_DTS_ADMIN_CLIENT_ID PF_DTS_ADMIN_CLIENT_SECRET NODE_EXTRA_CA_CERTS" \
  tool node scripts/pki-crls.mjs publish --pki "$STATE/pki" --base "$PF" >/dev/null ||
  die "publishing the roots' CRLs to pf-dts failed"

say "8. quickstart holder"
# The seed script ships in the tools image, so release mode has it too.
tool cat scripts/stack-seed.mjs | docker compose exec -T portal node --input-type=module -

check
