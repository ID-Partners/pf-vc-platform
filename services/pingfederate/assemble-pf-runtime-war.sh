#!/usr/bin/env bash
# Assemble pf-runtime.war = the STOCK PingFederate runtime war + pf-wallet-attest.jar in
# WEB-INF/lib + two filters registered in its web.xml:
#
#   ClientAttestationAuth (ClientAttestationAuthFilter) over /as/token.oauth2 + /as/par.oauth2
#     — attest_jwt_client_auth (draft-ietf-oauth-attestation-based-client-auth). PF has no
#     SDK seam for client authentication, so this is the lever: verify the two headers
#     in-process, then hand PF a private_key_jwt it understands. Fail closed.
#   AsMetadataAttest (AsMetadataFilter) over the two .well-known metadata paths
#     — advertises the method, and ONLY while the filter above is armed. The wallet sends
#     the headers iff the metadata lists the method, so these are one change.
#
# The stock war is tiny (web.xml only — PF's classes live on the server classpath), so
# the assembled war is the jar plus that one edited file. Idempotent: re-running over an
# already-assembled war leaves it as is. Verified at the end: the build fails if either
# mapping is missing, because a filter that quietly failed to register looks exactly like
# stock PF, and stock PF is the thing this exists to change.
#
#   $1 STOCK_WAR   the stock pf-runtime.war (from the image: /opt/server/server/default/deploy)
#   $2 MODULE_JAR  pf-ext/pf-wallet-attest/target/pf-wallet-attest.jar
#   $3 OUT_WAR     where to write the assembled war
set -euo pipefail
STOCK_WAR="$1"; MODULE_JAR="$2"; OUT_WAR="$3"
[ -f "$STOCK_WAR" ] || { echo "ERROR: stock war not found: $STOCK_WAR" >&2; exit 1; }
[ -f "$MODULE_JAR" ] || { echo "ERROR: module jar not found: $MODULE_JAR (run: cd pf-ext && mvn -o -q package -pl pf-wallet-attest)" >&2; exit 1; }

work="$(mktemp -d)"; trap 'rm -rf "$work"' EXIT
cp "$STOCK_WAR" "$OUT_WAR"
OUT_WAR="$(cd "$(dirname "$OUT_WAR")" && pwd)/$(basename "$OUT_WAR")"

mkdir -p "$work/WEB-INF/lib"
cp "$MODULE_JAR" "$work/WEB-INF/lib/pf-wallet-attest.jar"
( cd "$work" && zip -q "$OUT_WAR" WEB-INF/lib/pf-wallet-attest.jar )

unzip -oq "$OUT_WAR" WEB-INF/web.xml -d "$work"
WEBXML="$work/WEB-INF/web.xml"
[ -f "$WEBXML" ] || { echo "ERROR: stock pf-runtime.war has no WEB-INF/web.xml" >&2; exit 1; }
grep -q "</web-app>" "$WEBXML" || { echo "ERROR: web.xml has no </web-app> to insert before" >&2; exit 1; }

if grep -q "ClientAttestationAuth" "$WEBXML"; then
  echo "web.xml: ClientAttestationAuth already registered — leaving as is"
else
  # NB: no '--' inside these comments — a double hyphen in an XML comment fails the parse,
  # Jetty marks the context UNAVAILABLE, and every PF endpoint 404s.
  awk '
    /<\/web-app>/ && !done {
      print "  <!-- pf-wallet-attest: attest_jwt_client_auth for the wallet (services/pingfederate/assemble-pf-runtime-war.sh) -->"
      print "  <filter>"
      print "    <filter-name>ClientAttestationAuth</filter-name>"
      print "    <filter-class>au.com.idpartners.pf.attest.ClientAttestationAuthFilter</filter-class>"
      print "  </filter>"
      print "  <filter>"
      print "    <filter-name>AsMetadataAttest</filter-name>"
      print "    <filter-class>au.com.idpartners.pf.attest.AsMetadataFilter</filter-class>"
      print "  </filter>"
      print "  <filter-mapping>"
      print "    <filter-name>ClientAttestationAuth</filter-name>"
      print "    <url-pattern>/as/token.oauth2</url-pattern>"
      print "    <url-pattern>/as/par.oauth2</url-pattern>"
      print "  </filter-mapping>"
      print "  <filter-mapping>"
      print "    <filter-name>AsMetadataAttest</filter-name>"
      print "    <url-pattern>/.well-known/oauth-authorization-server</url-pattern>"
      print "    <url-pattern>/.well-known/openid-configuration</url-pattern>"
      print "  </filter-mapping>"
      done=1
    }
    { print }
  ' "$WEBXML" > "$WEBXML.new" && mv "$WEBXML.new" "$WEBXML"
  ( cd "$work" && zip -q "$OUT_WAR" WEB-INF/web.xml )
  echo "web.xml: registered ClientAttestationAuth (/as/token.oauth2, /as/par.oauth2) + AsMetadataAttest (.well-known)"
fi

# The listing is captured first, NOT piped into `grep -q`: under pipefail, grep -q exits at its
# first match, unzip can then die of SIGPIPE writing the rest, and the pipeline reports failure for
# a war that is fine. It did, intermittently, in conformance/test-wallet-attest-filter.mjs.
listing="$(unzip -l "$OUT_WAR")"
grep -q "WEB-INF/lib/pf-wallet-attest.jar" <<<"$listing" \
  || { echo "ERROR: pf-wallet-attest.jar not present in $OUT_WAR" >&2; exit 1; }
for name in ClientAttestationAuth AsMetadataAttest; do
  n=$(unzip -p "$OUT_WAR" WEB-INF/web.xml | grep -c "<filter-name>$name</filter-name>" || true)
  [ "$n" -ge 2 ] || { echo "ERROR: $name is not both declared and mapped in $OUT_WAR (found $n)" >&2; exit 1; }
done
# The XML must still parse: a war whose web.xml Jetty cannot read deploys and then serves nothing.
if command -v python3 >/dev/null 2>&1; then
  unzip -p "$OUT_WAR" WEB-INF/web.xml | python3 -c 'import sys,xml.dom.minidom; xml.dom.minidom.parseString(sys.stdin.read())' \
    || { echo "ERROR: assembled web.xml does not parse" >&2; exit 1; }
fi
echo "assembled $OUT_WAR ($(wc -c < "$OUT_WAR" | tr -d ' ') bytes): pf-wallet-attest.jar + 2 filters, web.xml parses"
