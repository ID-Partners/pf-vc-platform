# Sourced by scripts/stack-up.sh and scripts/stack-e2e.sh: which mode the stack
# runs in, which images it uses, and tool() - how both scripts run the stack's
# setup tools without Node, OpenSSL or anything else on the host but Docker.
#
# Expects ROOT (the checkout, or the unpacked public release) and STATE (.compose).

# Source mode builds everything from this checkout; release mode runs a release:
# the WARs and jars from its assets (checked against SHA256SUMS), every image but
# PingFederate's pulled. A checkout with pf-ext/ in it is the source repo, and one
# without is the public repo, so each defaults to its own. STACK_MODE overrides.
if [ -z "${STACK_MODE:-}" ]; then
  if [ -f "$ROOT/pf-ext/pom.xml" ]; then STACK_MODE=source; else STACK_MODE=release; fi
fi
case $STACK_MODE in source|release) ;; *) echo "STACK_MODE is source or release, not '$STACK_MODE'" >&2; exit 1 ;; esac
export STACK_MODE
VERSION=$(tr -d '[:space:]' < "$ROOT/VERSION")
export COMPOSE_PROJECT_NAME=${COMPOSE_PROJECT_NAME:-idp-pf-vcs}
if [ "$STACK_MODE" = source ]; then
  # One tag per compose project: docker-compose.yml names its images, so two
  # checkouts building under one tag would swap images under each other's stacks.
  export PFVC_TAG=${PFVC_TAG:-src-$COMPOSE_PROJECT_NAME}
  TOOLS_IMAGE=${TOOLS_IMAGE:-${REGISTRY:-ghcr.io/id-partners}/pfvc-tools:$PFVC_TAG}
else
  export PFVC_TAG=${PFVC_TAG:-$VERSION}
  # The public docker-compose.yml names every image in full, pinned by digest.
  TOOLS_IMAGE=${TOOLS_IMAGE:-$(sed -n '/^  tools:/,/^  [^ ]/s/^    image: *//p' "$ROOT/docker-compose.yml" | head -1)}
fi
export TOOLS_IMAGE

# One tools container per run, started on first use: `docker exec` is quick
# enough for stack-e2e.sh's many small JSON reads, where a `docker run` each
# would not be. It runs as the caller's uid, with .compose/ mounted at the SAME
# absolute path - the generators write paths into what they produce, and
# Terraform, on the host, reads them back.
tool_start() {
  [ -z "${TOOL_CID:-}" ] || return 0
  TOOL_CID=$(docker run -d --rm --init --user "$(id -u):$(id -g)" -e HOME=/tmp \
    -v "$STATE:$STATE" -w /app "$TOOLS_IMAGE" sleep 86400) || { echo "stack: cannot start $TOOLS_IMAGE" >&2; exit 1; }
  TOOL_OWNED=1
  export TOOL_CID
}
tool_stop() {
  if [ -n "${TOOL_OWNED:-}" ] && [ -n "${TOOL_CID:-}" ]; then docker rm -f "$TOOL_CID" >/dev/null 2>&1 || true; fi
}
# Join the stack's network, once it exists, so the tools reach https://pf.localhost
# the way the services do - through the edge's aliases.
tool_net() {
  tool_start
  docker network connect "${COMPOSE_PROJECT_NAME}_default" "$TOOL_CID" 2>/dev/null || true
}
# tool <command...>: run it in the tools container. The two ports are always
# passed - stack-env.mjs writes both into Terraform's variables, and a missing
# PF_ADMIN_PORT there points Terraform at the DEFAULT stack's PingFederate (on
# 2026-10-01 that locked another checkout's administrator). Name more variables
# in TOOL_ENV and their values pass BY NAME (`-e NAME`), so a secret never
# appears in a process listing.
tool() {
  tool_start
  local envs=(-e STACK_PORT -e PF_ADMIN_PORT) v
  for v in ${TOOL_ENV:-}; do envs+=(-e "$v"); done
  docker exec -i "${envs[@]}" "$TOOL_CID" "$@"
}

# A value from .compose/secrets.json, which stack-up.sh writes with
# JSON.stringify(_, null, 2): one "key": "value" pair per line, and no value holds
# a quote or a backslash (they are base64 or base64url).
secret() {
  local v
  v=$(sed -n "s/^  \"$1\": \"\\([^\"]*\\)\",\\{0,1\\}\$/\\1/p" "$STATE/secrets.json")
  [ -n "$v" ] || { echo "stack: no $1 in $STATE/secrets.json" >&2; return 1; }
  printf '%s' "$v"
}
