# PingFederate with the credential-rails extensions baked in.
# See design/pf-servlets.md + pf-ext/README.md.
#
# PINNED BY DIGEST: :latest would let any redeploy silently jump PF versions.
# This digest is the 13.1.0.5 build (13.1.0-alpine_3.24.1-al21).
FROM pingidentity/pingfederate@sha256:3a74b4d40398202d7f32b029da4d59c73471bad952dec6225ca22f8857fa6be0

# /opt/in is overlaid onto the live instance on EVERY container start, so these
# land in server/default/deploy next to pf-ws.war without touching the
# volume-persisted config. 9031:0 is the image's ping user.
COPY --chown=9031:0 deploy/ /opt/in/instance/server/default/deploy/

# pf-runtime.war with attest_jwt_client_auth (pf-ext/pf-wallet-attest) merged in.
# The stock war is the image's own; the jar is staged by scripts/stage-pf.sh into
# runtime/. Assembled HERE, not on the laptop, so the war always starts from the
# exact stock file of the pinned image and the build fails loudly if the filter
# mappings did not land (a filter that quietly failed to register is stock PF,
# which is precisely what this exists to change). sync-deploy.sh then copies it
# over the live instance's pf-runtime.war on every boot, like every other
# artifact in deploy/. See services/pingfederate/assemble-pf-runtime-war.sh.
USER root
COPY assemble-pf-runtime-war.sh /tmp/assemble-pf-runtime-war.sh
COPY runtime/pf-wallet-attest.jar /tmp/pf-wallet-attest.jar
RUN apk add --no-cache bash zip unzip python3 \
 && bash /tmp/assemble-pf-runtime-war.sh /opt/server/server/default/deploy/pf-runtime.war \
      /tmp/pf-wallet-attest.jar /opt/in/instance/server/default/deploy/pf-runtime.war \
 && chown 9031:0 /opt/in/instance/server/default/deploy/pf-runtime.war \
 && rm -f /tmp/assemble-pf-runtime-war.sh /tmp/pf-wallet-attest.jar
USER 9031:0

# The Ping hooks only overlay /opt/in when creating a NEW instance; on the
# persistent volume that never happens again, so baked artifacts were
# reaching /opt/in and stopping there. The shim syncs them into the live
# instance's deploy dir on every boot, then execs Ping's own bootstrap.
COPY --chown=9031:0 --chmod=755 sync-deploy.sh /opt/sync-deploy.sh
ENTRYPOINT ["/opt/sync-deploy.sh"]
CMD ["start-server"]
