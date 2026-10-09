#!/usr/bin/env sh
# Sync baked deploy artifacts into the LIVE instance before PF starts.
#
# The image puts WARs/plugin jars in /opt/in, but the Ping hooks only overlay
# /opt/in when CREATING an instance — where the instance lives on a
# persistent volume, so a redeploy shipped new artifacts that never reached
# server/default/deploy (verified: present in /opt/in, absent in /opt/out).
# This shim closes that gap on every boot, then hands off to Ping's bootstrap.
#
# NOTE deliberate asymmetry: artifacts REMOVED from the image are not removed
# from the instance — deletion is a manual step until a manifest is worth it.
# RETIRED is that manifest's first line: artifacts named here are deleted from
# the live instance on boot. Only things nothing in PF's own configuration can
# depend on belong here - a WAR is a standalone webapp; a pf.plugins.* jar may
# back a configured plugin instance, and removing it under one is not this
# script's call.
set -e
SRC=/opt/in/instance/server/default/deploy
DST=/opt/out/instance/server/default/deploy
RETIRED="pf-hello.war"
if [ -d "$DST" ]; then
  for name in $RETIRED; do
    if [ -f "$DST/$name" ]; then
      rm -f "$DST/$name" && echo "sync-deploy: retired $name"
    fi
  done
fi
if [ -d "$SRC" ] && [ -d "$DST" ]; then
  for f in "$SRC"/*; do
    [ -f "$f" ] || continue
    cp -f "$f" "$DST/" && echo "sync-deploy: $(basename "$f") -> deploy/"
  done
fi
cd /opt && exec ./bootstrap.sh "$@"
