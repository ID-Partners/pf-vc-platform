# Running the identity store

The identity store (`services/scim`) holds each holder's scanned documents,
profile, consents and credential grants. This page covers what an operator
needs to run it: its settings, its encryption key, upgrades, backup and
restore, and key rotation. How callers authenticate is in
`design/scim-auth.md`.

`conformance/test-scim-g92.mjs` runs every procedure on this page against the
real service on a real Postgres: the upgrade, a restart, a wrong key, rotation,
and a `pg_dump` restored into a new database.

## Settings

| Variable | What it does |
|---|---|
| `DATABASE_URL` | The Postgres the store keeps everything in. |
| `SCIM_DATA_KEY` | **Required.** 32 random bytes, base64 (`openssl rand -base64 32`). Encrypts every document, profile, consent and grant at rest. The store refuses to start without it. |
| `SCIM_DATA_KEY_PREVIOUS` | Only while rotating (below). |
| `SCIM_ALLOW_PLAINTEXT` | `true` stores records in the clear. Local development only; the store says so at every start, and refuses anyway if the database already holds sealed records. |
| `PF_JWKS_URL`, `PF_ISSUER`, `PF_ALLOWED_CLIENTS` | Which PingFederate access tokens the store accepts. |
| `SCIM_USER_CLIENTS` | The clients whose tokens act for a signed-in person (the portal). Such a token reaches only the records of the user whose `userName` is its `sub`. |
| `SCIM_WRITE_CLIENTS` | The service clients that may write. Every other service client reads only. |
| `SCIM_READONLY_CLIENTS` | Holds a client to reads whatever else is set. |
| `SCIM_STATE_CLIENTS` | The clients that may keep PingFederate's protocol state (G-90). |

## The data key

The key is the only way back to the records. The database, its backups and
its replicas hold ciphertext, so:

- **Keep the key apart from the backups.** A backup and its key together are
  the plaintext. Put the key in your secrets manager, not in the same bucket.
- **Losing the key loses the records.** No procedure here recovers them.
- A record is bound to its row: the additional data is the table, the user's
  id and the row's id. A sealed blob copied into another user's row does not
  open.
- The store checks the key at start against a sealed row in every table. With
  the wrong key it refuses to start. It does not wait for a holder's first read
  to find out.

## Upgrades

The schema is versioned (`schema_migrations`). Each step is applied once, in
order, in a transaction, under an advisory lock, so replicas starting together
are safe. A restart applies nothing twice.

Upgrading a store from before 2026-09-30 does three things, in order:

1. Adds a `sealed` column to each per-user table.
2. Renames each user to the subject PingFederate names them by:
   - `apple:<sub>` becomes `<sub>`;
   - an email-keyed user whose profile recorded an Apple `sub` becomes that `sub`;
   - `demo:` users are left alone;
   - a user whose new name is already taken is left as it is, and the count is
     logged. Two records for one person need a person to resolve them; the
     store never merges them.
3. Seals every record still in the clear, at start, in batches.

Set `SCIM_DATA_KEY` before starting the new version. Without it the store
refuses to start, and changes nothing.

## Backup

```bash
pg_dump --format=custom --file=scim-$(date +%F).dump "$DATABASE_URL"
```

The dump is ciphertext for every per-user record. It includes
`schema_migrations`, so a restore knows which version it is. Back up
`SCIM_DATA_KEY` separately (see above).

## Restore

```bash
createdb scim_restored
pg_restore --no-owner --dbname=scim_restored scim-2026-09-30.dump
```

Point `DATABASE_URL` at the restored database and start the store with the
**same** `SCIM_DATA_KEY` it had when the dump was taken. If the key has been
rotated since, set the current key as `SCIM_DATA_KEY` and the one from the
dump's time as `SCIM_DATA_KEY_PREVIOUS`. Check it:

- the store starts. A wrong key refuses at start and names the table;
- `/health` answers 200;
- the log shows no `applied migration` line, unless the dump predates a step
  the new version has, in which case the step runs once, as in an upgrade.

## Rotating the key

1. Generate a new key.
2. Set it as `SCIM_DATA_KEY`, and move the old one to `SCIM_DATA_KEY_PREVIOUS`.
3. Restart. At start, every record sealed under the old key is re-sealed under
   the new one, and the log counts them.
4. Once every replica has restarted, remove `SCIM_DATA_KEY_PREVIOUS`.

Keep the old key with any backups taken before the rotation. Those backups are
sealed under it.
