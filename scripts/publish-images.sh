#!/usr/bin/env bash
#
# Push a release's images and pin docker-compose.yml to them - the public half of
# a release, run by .github/workflows/publish.yml (and by hand only to rehearse
# one against a local registry):
#
#   REGISTRY=ghcr.io/<owner> scripts/publish-images.sh pfvc-images-<VERSION>.tar
#
# Loads the tarball, tags each image under REGISTRY at this tree's VERSION, pushes
# it, and rewrites its image: line in docker-compose.yml to <name>:<VERSION>@<digest>
# - the digest the registry returned, so what a user pulls is byte for byte what
# was pushed. Fails unless every pfvc image but PingFederate's ends up pinned.
set -euo pipefail
cd "$(dirname "$0")/.."
[ -n "${REGISTRY:-}" ] || { echo "set REGISTRY (e.g. ghcr.io/<owner>)" >&2; exit 2; }
[ -f "${1:-}" ] || { echo "usage: REGISTRY=... $0 <images.tar>" >&2; exit 2; }
VERSION=$(tr -d '[:space:]' < VERSION)

loaded=$(docker load -i "$1" | sed -n 's/^Loaded image: //p')
[ -n "$loaded" ] || { echo "publish-images: $1 held no images" >&2; exit 1; }
for img in $loaded; do
  name=${img##*/}; name=${name%%:*}
  case $name in pfvc-*) ;; *) echo "publish-images: unexpected image $img" >&2; exit 1 ;; esac
  ref=$REGISTRY/$name:$VERSION
  docker tag "$img" "$ref"
  digest=$(docker push "$ref" | sed -n 's/.*digest: \(sha256:[0-9a-f]\{64\}\).*/\1/p' | tail -1)
  [ -n "$digest" ] || { echo "publish-images: pushing $ref returned no digest" >&2; exit 1; }
  sed -i.bak -E "s#^(    image: )[^ ]*/$name:[^ ]*\$#\\1$ref@$digest#" docker-compose.yml && rm -f docker-compose.yml.bak
  echo "$ref@$digest"
done

unpinned=$(grep -E '^    image: .*/pfvc-' docker-compose.yml | grep -v '@sha256:' || true)
[ -z "$unpinned" ] || { echo "publish-images: not pinned:" >&2; echo "$unpinned" >&2; exit 1; }
