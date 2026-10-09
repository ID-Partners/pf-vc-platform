#!/usr/bin/env bash
#
# Prove the local stack (docker-compose.yml) issues and verifies, end to end,
# through the same public URLs a browser and a wallet use:
#
#   1. pre-authorized issuance: an operator offer (pf-oid4vci admin, as portal-svc
#      with vc:admin) redeemed by the web wallet - attestation, DPoP, a status entry
#   2. presentation: a pf-oid4vp session answered by that wallet, for both formats
#   3. authorization-code issuance: the wallet signs in at PingFederate's HTML form
#      as the quickstart holder, and gets credentials sourced from SCIM (stack-seed.mjs)
#   4. the portal: the holder signs in through PingFederate and sees their records
#   5. sign in with your wallet: this script plays a relying party (quickstart-rp),
#      PingFederate sends it to the wallet-login adapter, the web wallet presents the
#      PID issued in step 1, and the ID token names the person it was issued to
#
#   ./scripts/stack-e2e.sh           (stack-up.sh runs it as part of its check)
#
# Leaves the credentials it issued in a throwaway wallet session; nothing else.
set -uo pipefail
cd "$(dirname "$0")/.."
ROOT=$PWD
STATE=$ROOT/.compose
PORT=${STACK_PORT:-9443}
# JSON is read in the tools image (scripts/stack-lib.sh), so the host needs no
# Node - stack-up.sh passes its own tools container in TOOL_CID.
. scripts/stack-lib.sh
PF=https://pf.localhost:$PORT
W=https://wallet.localhost:$PORT
export CURL_CA_BUNDLE=$STATE/certs/ca.crt
WORK=$(mktemp -d); trap 'rm -rf "$WORK"; tool_stop' EXIT
field() { tool node -e "let o;try{o=JSON.parse(require('fs').readFileSync(0,'utf8'))}catch{o={}};const v=($1);process.stdout.write(v==null?'':String(v))"; }
jstr() { tool node -p 'JSON.stringify(process.argv[1])' "$1" </dev/null; }

fail=0
# What this run did, not what an earlier one left in the logs.
STARTED=$(date -u +%Y-%m-%dT%H:%M:%SZ)
pass() { echo "  ok   $1"; }
bad() { echo "  FAIL $1: ${2:0:400}"; fail=1; }

# A wallet session: a cookie jar the web wallet keys its in-memory wallet on.
wallet() { # method path [json]
  curl -s -c "$WORK/jar" -b "$WORK/jar" -H "origin: $W" -H 'sec-fetch-site: same-origin' \
    ${3:+-H 'content-type: application/json' --data "$3"} -X "$1" "$W$2"
}
wallet GET /api/credentials >/dev/null

TOKEN=$(curl -s -u "portal-svc:$(secret portal_svc_secret)" -d grant_type=client_credentials -d scope=vc:admin \
  "$PF/as/token.oauth2" | field o.access_token)
[ -n "$TOKEN" ] && pass "operator token (portal-svc, vc:admin)" || bad "operator token" "none"

# The relying party: the quickstart's (pingfederate/quickstart/quickstart_rp.tf). A
# verifier session is a request signed under this deployment's reader certificate,
# so pf-oid4vp opens one only for a client token carrying vc:verify.
RP_TOKEN=$(curl -s -u "quickstart-rp:$(secret quickstart_rp_secret)" -d grant_type=client_credentials -d scope=vc:verify \
  "$PF/as/token.oauth2" | field o.access_token)
[ -n "$RP_TOKEN" ] && pass "relying party token (quickstart-rp, vc:verify)" || bad "relying party token" "none"
code=$(curl -s -o /dev/null -w '%{http_code}' -X POST "$PF/pf-oid4vp/sessions?credential=pid")
[ "$code" = 401 ] && pass "pf-oid4vp refuses to open a session for a caller with no token (401)" \
  || bad "an untokened session" "HTTP $code"

PERSON='"given_name":"Erika","family_name":"Mustermann","birthdate":"1986-03-14","age_over_18":true,"nationality":"AU"'
# An mDL is offered with every mandatory Table 20 element or refused (G-111); the
# issuing country is the stack IACA's (pki-quickstart.mjs), as a reader checks.
JPEG='/9j/4AAQSkZJRgABAQEASABIAAD/2wBDAAEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEBAQEB/8AAEQgAAQABAwEiAAIRAQMRAf/EABUAAQEAAAAAAAAAAAAAAAAAAAAJ/8QAFBABAAAAAAAAAAAAAAAAAAAAAP/EABQBAQAAAAAAAAAAAAAAAAAAAAD/xAAUEQEAAAAAAAAAAAAAAAAAAAAA/9oADAMBAAIRAxEAPwCdABmX/9k='
LICENCE=',"document_number":"DL1234567","issue_date":"2025-03-13","expiry_date":"2030-03-13","issuing_country":"AU","issuing_authority":"Transport for NSW","un_distinguishing_sign":"AUS","driving_privileges":[{"vehicle_category_code":"C"}],"portrait":"'$JPEG'"'

issue_and_present() { # credential_configuration_id verifier-credential label [extra claims]
  local offer uri acc sess link review id answer result
  offer=$(curl -s -H "authorization: Bearer $TOKEN" -H 'content-type: application/json' "$PF/pf-oid4vci/admin/offers" \
    -d "{\"credential_configuration_ids\":[\"$1\"],\"claims\":{$PERSON${4:-}},\"consent\":{\"acknowledged\":true}}")
  uri=$(echo "$offer" | field o.credential_offer_uri)
  [ -n "$uri" ] || { bad "$3: offer" "$offer"; return; }
  acc=$(wallet POST /api/offers "{\"uri\":$(jstr "$uri")}")
  if echo "$acc" | grep -q "\"configurationId\":\"$1\""; then
    pass "$3: offer redeemed by the web wallet"
  else
    bad "$3: offer redeemed" "$acc"; return
  fi
  sess=$(curl -s -X POST -H "authorization: Bearer $RP_TOKEN" "$PF/pf-oid4vp/sessions?credential=$2")
  link=$(echo "$sess" | field o.wallet_link)
  [ -n "$link" ] || { bad "$3: verifier session" "$sess"; return; }
  review=$(wallet POST /api/presentations/review "{\"uri\":$(jstr "$link")}")
  id=$(echo "$review" | field o.id)
  [ -n "$id" ] || { bad "$3: wallet review" "$review"; return; }
  answer=$(wallet POST "/api/presentations/$id/decision" '{"decision":"share"}')
  # The creator's poll secret releases the verified claims (G-95); the holder's
  # name coming back is the proof the presentation was read, not just received.
  result=$(curl -s "$PF/pf-oid4vp/sessions/$(echo "$sess" | field o.session_id)?poll_secret=$(echo "$sess" | field o.poll_secret)")
  if echo "$result" | grep -q '"status":"verified"' && echo "$result" | grep -q '"Mustermann"'; then
    pass "$3: presented to pf-oid4vp, verified, and the relying party reads the holder's claims"
  else
    bad "$3: presentation" "$answer $result"
  fi
}

issue_and_present pid-sd-jwt pid "SD-JWT PID"
issue_and_present mdl-mdoc mdl "mdoc mDL" "$LICENCE"

# OID4VCI §11 (G-42): the wallet told pf-oid4vci it stored both, and pf-oid4vci
# recorded it beside the issuance records.
# The container's output tails PingFederate's server.log, a beat behind it.
for _ in $(seq 1 20); do
  notes=$(docker compose logs --no-color --since "$STARTED" pingfederate 2>/dev/null | grep -c '"event":"credential_notification".*"notification_event":"credential_accepted"')
  [ "${notes:-0}" -ge 2 ] && break
  sleep 1
done
if [ "${notes:-0}" -ge 2 ]; then
  pass "notification: the wallet reported both credentials stored, and pf-oid4vci recorded it"
else
  bad "notification" "pf-oid4vci recorded ${notes:-0} credential_accepted notifications"
fi

# Authorization code: wallet -> PF authorize (after PAR) -> HTML form -> back.
authz=$(curl -s -c "$WORK/jar" -b "$WORK/jar" -H "origin: $W" -o /dev/null -w '%{redirect_url}' "$W/oidc/start")
page=$(curl -s -L -c "$WORK/pf" -b "$WORK/pf" -w '\nFINAL_URL %{url_effective}' "$authz")
action=$(echo "$page" | grep -oE 'action="[^"]+"' | head -1 | sed -E 's/action="([^"]+)"/\1/; s/&amp;/\&/g')
if [ -z "$action" ]; then
  bad "authorization code: PingFederate's login form" "$(echo "$page" | sed -n 's/^FINAL_URL //p')"
else
  loc=$(curl -s -c "$WORK/pf" -b "$WORK/pf" -o /dev/null -w '%{redirect_url}' \
    --data-urlencode "pf.username=quickstart-holder" --data-urlencode "pf.pass=$(secret quickstart_holder_password)" \
    -d pf.ok=clicked -d pf.adapterId=htmlFormAdapter "$PF$action")
  for _ in 1 2 3 4 5; do
    case "$loc" in "$W"/callback*|"") break ;; esac
    loc=$(curl -s -c "$WORK/pf" -b "$WORK/pf" -o /dev/null -w '%{redirect_url}' "$loc")
  done
  case "$loc" in
    "$W"/callback*)
      pass "authorization code: the quickstart holder signed in at PingFederate"
      back=$(curl -s -c "$WORK/jar" -b "$WORK/jar" -o /dev/null -w '%{redirect_url}' "$loc")
      case "$back" in
        *issued=[1-9]*) pass "authorization code: credentials issued from SCIM (${back##*issued=})" ;;
        *) bad "authorization code: issuance" "$back" ;;
      esac ;;
    *) bad "authorization code: sign-in" "${loc:-no redirect}" ;;
  esac
fi

# The holder portal (G-92): the quickstart holder signs in through PingFederate,
# and their dashboard is read from SCIM with their own token - the store gives
# that token their records and nobody else's.
P=https://portal.localhost:$PORT
authz=$(curl -s -c "$WORK/portal" -b "$WORK/portal" -o /dev/null -w '%{redirect_url}' "$P/auth/pf")
page=$(curl -s -L -c "$WORK/pfp" -b "$WORK/pfp" -w '\nFINAL_URL %{url_effective}' "$authz")
action=$(echo "$page" | grep -oE 'action="[^"]+"' | head -1 | sed -E 's/action="([^"]+)"/\1/; s/&amp;/\&/g')
if [ -z "$action" ]; then
  bad "portal: PingFederate's login form" "$(echo "$page" | sed -n 's/^FINAL_URL //p')"
else
  loc=$(curl -s -c "$WORK/pfp" -b "$WORK/pfp" -o /dev/null -w '%{redirect_url}' \
    --data-urlencode "pf.username=quickstart-holder" --data-urlencode "pf.pass=$(secret quickstart_holder_password)" \
    -d pf.ok=clicked -d pf.adapterId=htmlFormAdapter "$PF$action")
  for _ in 1 2 3 4 5; do
    case "$loc" in "$P"/auth/pf/callback*|"") break ;; esac
    loc=$(curl -s -c "$WORK/pfp" -b "$WORK/pfp" -o /dev/null -w '%{redirect_url}' "$loc")
  done
  case "$loc" in
    "$P"/auth/pf/callback*)
      next=$(curl -s -c "$WORK/portal" -b "$WORK/portal" -o /dev/null -w '%{redirect_url}' "$loc")
      dash=$(curl -s -c "$WORK/portal" -b "$WORK/portal" "$P/dashboard")
      if echo "$dash" | grep -q "DL1234567" && echo "$dash" | grep -q "C01X00T47"; then
        pass "portal: the quickstart holder signed in through PingFederate and sees their passport and licence"
      else
        bad "portal: dashboard" "${next} $(echo "$dash" | head -c 300)"
      fi ;;
    *) bad "portal: sign-in" "${loc:-no redirect}" ;;
  esac
fi

# Sign in with your wallet: an OIDC relying party (quickstart-rp, the quickstart
# overlay's) sends the person to PingFederate, whose SignInWithWallet tree hands
# them to the wallet-login adapter. Its page carries the wallet link, the poll URL
# and the resume URL; this script is the browser. The web wallet presents the PID
# step 1 put in it, and the ID token the relying party gets must name its holder.
RP=quickstart-rp
RP_CB=https://quickstart-rp.invalid/callback
cv=$(head -c 32 /dev/urandom | base64 | tr '+/' '-_' | tr -d '=\n')
cc=$(printf '%s' "$cv" | openssl dgst -sha256 -binary | base64 | tr '+/' '-_' | tr -d '=\n')
page=$(curl -s -L -c "$WORK/rp" -b "$WORK/rp" "$PF/as/authorization.oauth2?client_id=$RP&response_type=code&scope=openid%20profile&redirect_uri=$(printf %s "$RP_CB" | sed 's#:#%3A#g; s#/#%2F#g')&code_challenge=$cc&code_challenge_method=S256&state=st1&nonce=nc1")
link=$(printf '%s' "$page" | sed -n 's/.*<a href="\([^"]*\)">Open wallet<\/a>.*/\1/p' | sed 's/&amp;/\&/g' | head -1)
poll=$(printf '%s' "$page" | sed -n 's/.*fetch("\([^"]*\)").*/\1/p' | head -1)
resume=$(printf '%s' "$page" | sed -n 's/.*location\.href = "\([^"]*\)".*/\1/p' | head -1)
if [ -z "$link" ] || [ -z "$poll" ] || [ -z "$resume" ]; then
  bad "sign in with your wallet: PingFederate's wallet-login page" "$(printf '%s' "$page" | head -c 300)"
else
  review=$(wallet POST /api/presentations/review "{\"uri\":$(jstr "$link")}")
  id=$(echo "$review" | field o.id)
  answer=$(wallet POST "/api/presentations/$id/decision" '{"decision":"share"}')
  case "$poll" in http*) ;; *) poll=$PF$poll ;; esac
  case "$resume" in http*) ;; *) resume=$PF$resume ;; esac
  status=
  for _ in $(seq 1 10); do
    status=$(curl -s "$poll" | field o.status)
    [ "$status" = verified ] && break
    sleep 1
  done
  if [ "$status" != verified ]; then
    bad "sign in with your wallet: the presentation" "${status:-no status} $answer"
  else
    loc=$(curl -s -c "$WORK/rp" -b "$WORK/rp" -o /dev/null -w '%{redirect_url}' "$resume")
    for _ in 1 2 3 4 5; do
      case "$loc" in "$RP_CB"*|"") break ;; esac
      case "$loc" in http*) ;; *) loc=$PF$loc ;; esac
      loc=$(curl -s -c "$WORK/rp" -b "$WORK/rp" -o /dev/null -w '%{redirect_url}' "$loc")
    done
    code=$(printf '%s' "$loc" | sed -n 's/.*[?&]code=\([^&]*\).*/\1/p')
    if [ -z "$code" ]; then
      bad "sign in with your wallet: PingFederate's redirect to the relying party" "${loc:-no redirect}"
    else
      tok=$(curl -s -u "$RP:$(secret quickstart_rp_secret)" -d grant_type=authorization_code -d "code=$code" \
        --data-urlencode "redirect_uri=$RP_CB" -d "code_verifier=$cv" "$PF/as/token.oauth2")
      name=$(echo "$tok" | field "JSON.parse(Buffer.from((o.id_token||'..').split('.')[1],'base64url').toString()||'{}').family_name")
      if [ "$name" = Mustermann ]; then
        pass "sign in with your wallet: the relying party's ID token names the PID's holder"
      else
        bad "sign in with your wallet: the ID token" "$(echo "$tok" | head -c 300)"
      fi
    fi
  fi
fi

exit $fail
