# Test and conformance coverage dashboard

Generated 2026-10-09T00:35:44+00:00 by `conformance/standards/render-dashboard.py` at `e8d82a8` (v1-ci). **Do not edit by hand** — every figure is derived; re-render instead. The HTML view is `standards/dashboard.html`; the snapshot behind both is `standards/dashboard.json`.

| | |
|---|---|
| Sentence-level conformance | **51%** — 789 covered of 1559 scored (2629 in-scope statements, 999 n/a) |
| Assertions executed | **4202** passed, 0 failed — verdict `PASSED WITH GAPS — 0 failures, but 1 suite(s) never ran (1 declared in CONFORMANCE_ALLOWED_SKIPS).`, exit 0 |
| Suites | 116 registered in `run.sh`, 116 reachable, 0 unreachable; 115 node files on disk; no Swift suites in this repository |
| Gaps | 27 open, 100 closed, 128 entries in the register |

## Findings against the test estate

These are defects in the harness, not in the specifications. Each answers one of GAP-REGISTER.md's four questions — *absent, unrecognised, unreached, unfalsified* — pointed at the checks rather than at the product.

| | Check | Question | What the derivation found |
|---|---|---|---|
| ✅ | every suite registered in run.sh is reached before the script exits | *unreached* | all 116 registrations sit above the terminal `exit` at run.sh:792 |
| ✅ | every suite file on disk is named by run.sh | *unreached* | 115 node + 0 swift suite files, all registered or declared |
| ✅ | the run.sh parser finds every node_test invocation a cruder scan finds | *unreached* | both passes agree on 116 node invocations |
| ✅ | every suite path run.sh names exists on disk | *unrecognised* | all 116 registered paths resolve |
| ✅ | the conformance matrix credits the suites that run | *unreached* | 64 of 116 node suites are cited by a coverage.jsonl row; 52 assert things the matrix credits to nobody |
| ✅ | GAP-REGISTER.md's summary line agrees with its own rows | *unfalsified* | 128 entries, all accounted for in the summary |
| ✅ | the numbers on this page come from a suite that actually ran | *absent* | 4202 assertions passed, 0 failed, 1 suite(s) skipped; verdict "PASSED WITH GAPS — 0 failures, but 1 suite(s) never ran (1 declared in CONFORMANCE_ALLOWED_SKIPS).", exit 0 |
| ✅ | the two independent assertion counts agree | *unrecognised* | 4202 tick lines, 4202 summed from 114 per-suite tallies |
| ❌ | no suite silently declined to run, and none died without reporting | *absent* | test-vical-external.mjs did not run — DECLARED in CONFORMANCE_ALLOWED_SKIPS, so not fatal; see the ⚠ above it |
| ✅ | conformance gains since the last snapshot came from new evidence, not a smaller denominator | *unrecognised* | e8d82a8 → e8d82a8: +0 covered, +0 n/a, +0 scored, +0 pp |
| ❌ | code-execution coverage is measured, not assumed from the register | *absent* | measured for typescript, java but over an INCOMPLETE suite population — typescript: measured over a PARTIAL set; java: measured over a PARTIAL set. A percentage over a partial set is not a coverage figure. |
| ✅ | every OpenID Foundation result shown names the deployed commit it tested | *unrecognised* | 230 module results across 7 plan configurations, each tied to a deployed commit |

## Progress over time

147 snapshots, `467f9ac` → `e8d82a8`. Rows marked *git* were reconstructed from committed revisions of `dashboard.json`, not recorded live.

**Read `covered`, not the percentage.** Conformance is `covered / scored`, so the headline rises two ways: by covering more, or by scoring less. Moving an `UNREVIEWED` row to `n/a` does the second — it shrinks the denominator and lifts the number without one new assertion. `covered` only rises when a named test starts forcing a requirement, which is why it is the first column and why a gain in one without the other is a finding above.

| Snapshot | When | covered | implemented | gap | UNREVIEWED | n/a | scored | Axis B | Axis A | assertions | gaps open | Source |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `467f9ac` | 2026-09-04 04:59 | **364** | 671 | 470 | 208 | 800 | 1753 | 21% | — | 1265 | 23 | git |
| `fc7afce` | 2026-09-04 05:39 | **367** | 692 | 474 | 152 | 828 | 1725 | 21% | — | 1278 | 23 | git |
| `a6604df` | 2026-09-04 05:53 | **367** | 692 | 474 | 152 | 828 | 1725 | 21% | 51.09% | 1279 | 23 | git |
| `c22cf88` | 2026-09-04 06:09 | **367** | 692 | 474 | 152 | 828 | 1725 | 21% | 51.09% | 1279 | 23 | render |
| `04cbb10` | 2026-09-04 06:32 | **367** | 692 | 474 | 152 | 828 | 1725 | 21% | 51.09% | 1298 | 24 | render |
| `8d258f2` | 2026-09-04 06:43 | **367** | 692 | 474 | 152 | 828 | 1725 | 21% | 51.09% | 1299 | 24 | render |
| `f96f1cd` | 2026-09-04 06:59 | **388** | 671 | 474 | 152 | 828 | 1725 | 22% | 51.09% | 1409 | 24 | render |
| `ac43783` | 2026-09-04 07:16 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.09% | 1445 | 24 | render |
| `01f5519` | 2026-09-04 07:40 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.18% | 1410 | 24 | render |
| `6ba8294` | 2026-09-04 07:55 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.3% | 1446 | 24 | render ⚠ +5 uncommitted |
| `b4a340c` | 2026-09-05 07:05 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.09% | 1224 | 24 | render |
| `13d5ba2` | 2026-09-05 07:15 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.09% | 1224 | 24 | render |
| `c0ab9e3` | 2026-09-05 08:26 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.3% | 1446 | 24 | render ⚠ +98 uncommitted |
| `028ff3a` | 2026-09-05 08:38 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.3% | 1224 | 24 | render ⚠ +6 uncommitted |
| `72708d4` | 2026-09-05 08:48 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.09% | 1245 | 24 | render |
| `9d02cb6` | 2026-09-05 08:50 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.3% | 1224 | 24 | render ⚠ +9 uncommitted |
| `88f0820` | 2026-09-05 08:54 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.3% | 1246 | 24 | render ⚠ +4 uncommitted |
| `d28d4c0` | 2026-09-05 08:56 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.09% | 1246 | 24 | render |
| `a96e7fc` | 2026-09-05 08:58 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.3% | 1246 | 24 | render ⚠ +6 uncommitted |
| `db66825` | 2026-09-05 09:02 | **406** | 653 | 474 | 152 | 828 | 1725 | 24% | 51.3% | 1247 | 24 | render ⚠ +4 uncommitted |
| `0114f86` | 2026-09-05 09:13 | **411** | 648 | 474 | 152 | 828 | 1725 | 24% | 51.09% | 1252 | 24 | render |
| `b73aa78` | 2026-09-05 09:14 | **411** | 648 | 474 | 152 | 828 | 1725 | 24% | 51.09% | 1252 | 24 | render |
| `004ed94` | 2026-09-05 09:23 | **411** | 648 | 474 | 152 | 828 | 1725 | 24% | 51.3% | 1253 | 24 | render ⚠ +5 uncommitted |
| `a428079` | 2026-09-05 09:27 | **411** | 648 | 474 | 152 | 828 | 1725 | 24% | 51.3% | 1253 | 24 | render ⚠ +5 uncommitted |
| `36ea438` | 2026-09-05 09:30 | **421** | 638 | 474 | 152 | 828 | 1725 | 24% | 51.09% | 1268 | 24 | render ⚠ +3 uncommitted |
| `55251e2` | 2026-09-05 09:34 | **427** | 632 | 474 | 152 | 828 | 1725 | 25% | 51.09% | 1268 | 24 | render ⚠ +2 uncommitted |
| `b8cdc28` | 2026-09-05 11:22 | **427** | 632 | 474 | 152 | 828 | 1725 | 25% | 51.3% | 1253 | 24 | render ⚠ +8 uncommitted |
| `cb23dc1` | 2026-09-05 11:23 | **430** | 629 | 474 | 152 | 828 | 1725 | 25% | 51.09% | 1280 | 24 | render ⚠ +3 uncommitted |
| `c9ba4fb` | 2026-09-05 11:26 | **427** | 632 | 474 | 152 | 828 | 1725 | 25% | 51.3% | 1269 | 24 | render ⚠ +4 uncommitted |
| `dc38b73` | 2026-09-05 11:27 | **430** | 629 | 474 | 152 | 828 | 1725 | 25% | 51.3% | 1269 | 24 | render ⚠ +7 uncommitted |
| `f5155a3` | 2026-09-05 11:30 | **433** | 626 | 474 | 152 | 828 | 1725 | 25% | 51.09% | 1285 | 24 | render ⚠ +4 uncommitted |
| `aafb753` | 2026-09-05 11:30 | **433** | 626 | 474 | 152 | 828 | 1725 | 25% | 51.09% | 1285 | 24 | render ⚠ +6 uncommitted |
| `585ab4e` | 2026-09-05 11:37 | **437** | 622 | 474 | 152 | 828 | 1725 | 25% | 51.09% | 1305 | 24 | render ⚠ +4 uncommitted |
| `258be6b` | 2026-09-05 11:48 | **442** | 617 | 474 | 152 | 828 | 1725 | 26% | 51.09% | 1313 | 24 | render ⚠ +4 uncommitted |
| `b3e69ab` | 2026-09-05 11:55 | **445** | 614 | 474 | 152 | 828 | 1725 | 26% | 51.09% | 1324 | 24 | render ⚠ +5 uncommitted |
| `562cf71` | 2026-09-05 20:58 | **447** | 612 | 474 | 152 | 828 | 1725 | 26% | 51.09% | 1331 | 24 | render ⚠ +3 uncommitted |
| `0a181f1` | 2026-09-05 20:59 | **447** | 612 | 474 | 152 | 828 | 1725 | 26% | 51.06% | 1324 | 24 | render ⚠ +7 uncommitted |
| `9456580` | 2026-09-05 21:00 | **447** | 612 | 474 | 152 | 828 | 1725 | 26% | 51.06% | 1324 | 24 | render |
| `ea23d4a` | 2026-09-05 21:07 | **447** | 612 | 474 | 152 | 828 | 1725 | 26% | 51.06% | 1324 | 24 | render ⚠ +5 uncommitted |
| `e271740` | 2026-09-05 21:07 | **450** | 609 | 474 | 152 | 828 | 1725 | 26% | 51.09% | 1338 | 24 | render ⚠ +5 uncommitted |
| `49241d3` | 2026-09-05 21:07 | **450** | 609 | 474 | 152 | 828 | 1725 | 26% | 51.09% | 1338 | 24 | render ⚠ +5 uncommitted |
| `e5e3f85` | 2026-09-05 21:09 | **450** | 609 | 474 | 152 | 828 | 1725 | 26% | 51.06% | 1324 | 24 | render ⚠ +9 uncommitted |
| `9b92480` | 2026-09-05 22:22 | **453** | 606 | 474 | 152 | 828 | 1725 | 26% | 51.09% | 1354 | 24 | render ⚠ +3 uncommitted |
| `623a19a` | 2026-09-05 22:22 | **453** | 606 | 474 | 152 | 828 | 1725 | 26% | 51.09% | 1354 | 24 | render ⚠ +5 uncommitted |
| `d0ad669` | 2026-09-05 22:28 | **458** | 601 | 474 | 152 | 828 | 1725 | 27% | 51.09% | 1372 | 24 | render ⚠ +3 uncommitted |
| `8a13248` | 2026-09-05 22:35 | **458** | 601 | 474 | 152 | 828 | 1725 | 27% | 51.06% | 1354 | 24 | render ⚠ +8 uncommitted |
| `97e5976` | 2026-09-05 22:37 | **383** | 601 | 474 | 227 | 828 | 1725 | 22% | 51.06% | 1354 | 24 | render ⚠ +6 uncommitted |
| `d2bd704` | 2026-09-05 22:41 | **459** | 601 | 473 | 152 | 828 | 1725 | 27% | 51.09% | 1392 | 24 | render ⚠ +4 uncommitted |
| `8c97b09` | 2026-09-05 22:41 | **384** | 601 | 473 | 227 | 828 | 1725 | 22% | 51.09% | 1392 | 24 | render ⚠ +7 uncommitted |
| `febaa84` | 2026-09-05 22:47 | **384** | 601 | 473 | 227 | 828 | 1725 | 22% | 51.09% | 1392 | 24 | render ⚠ +3 uncommitted |
| `ca4a902` | 2026-09-05 22:49 | **384** | 601 | 473 | 227 | 828 | 1725 | 22% | 51.06% | 1392 | 24 | render ⚠ +7 uncommitted |
| `ad6f610` | 2026-09-05 22:51 | **388** | 597 | 473 | 227 | 828 | 1725 | 22% | 51.09% | 1396 | 24 | render ⚠ +3 uncommitted |
| `fdbe88e` | 2026-09-05 22:52 | **388** | 597 | 473 | 227 | 828 | 1725 | 22% | 51.09% | 1396 | 24 | render |
| `d86f180` | 2026-09-05 23:03 | **403** | 582 | 473 | 227 | 828 | 1725 | 23% | 51.09% | 1416 | 24 | render ⚠ +3 uncommitted |
| `db5aeec` | 2026-09-05 23:18 | **411** | 574 | 473 | 227 | 828 | 1725 | 24% | 51.09% | 1420 | 24 | render ⚠ +3 uncommitted |
| `c6837d6` | 2026-09-06 00:17 | **422** | 563 | 473 | 227 | 828 | 1725 | 24% | 51.09% | 1433 | 24 | render ⚠ +8 uncommitted |
| `93c168c` | 2026-09-06 00:18 | **422** | 563 | 473 | 227 | 828 | 1725 | 24% | 51.09% | 1433 | 24 | render ⚠ +9 uncommitted |
| `aa1cf44` | 2026-09-06 00:31 | **433** | 552 | 473 | 227 | 828 | 1725 | 25% | 51.09% | 1444 | 24 | render ⚠ +5 uncommitted |
| `e03fee2` | 2026-09-06 00:49 | **437** | 548 | 473 | 227 | 828 | 1725 | 25% | 51.09% | 1448 | 24 | render ⚠ +3 uncommitted |
| `b498268` | 2026-09-06 00:58 | **437** | 548 | 473 | 227 | 828 | 1725 | 25% | 51.06% | 1445 | 24 | render ⚠ +7 uncommitted |
| `e3b0f79` | 2026-09-06 01:00 | **443** | 542 | 473 | 227 | 828 | 1725 | 26% | 51.09% | 1457 | 24 | render ⚠ +3 uncommitted |
| `655a315` | 2026-09-06 01:01 | **443** | 542 | 473 | 227 | 828 | 1725 | 26% | 51.09% | 1457 | 24 | render ⚠ +4 uncommitted |
| `3db52ee` | 2026-09-06 01:07 | **456** | 529 | 473 | 227 | 828 | 1725 | 26% | 51.09% | 1466 | 24 | render ⚠ +3 uncommitted |
| `edf5241` | 2026-09-06 01:17 | **463** | 522 | 473 | 227 | 828 | 1725 | 27% | 51.09% | 1480 | 24 | render ⚠ +3 uncommitted |
| `689f751` | 2026-09-06 01:22 | **473** | 512 | 473 | 227 | 828 | 1725 | 27% | 51.09% | 1485 | 24 | render ⚠ +3 uncommitted |
| `4cfaa85` | 2026-09-06 01:22 | **473** | 512 | 473 | 227 | 828 | 1725 | 27% | 51.09% | 1485 | 24 | render |
| `f01e4e3` | 2026-09-06 02:29 | **481** | 504 | 473 | 227 | 828 | 1725 | 28% | 51.09% | 1502 | 24 | render ⚠ +4 uncommitted |
| `d8977cc` | 2026-09-06 02:32 | **487** | 498 | 473 | 227 | 828 | 1725 | 28% | 51.09% | 1514 | 24 | render ⚠ +4 uncommitted |
| `657430d` | 2026-09-06 08:45 | **512** | 473 | 473 | 227 | 828 | 1725 | 30% | 51.09% | 1514 | 24 | render ⚠ +4 uncommitted |
| `e12bd01` | 2026-09-06 20:09 | **542** | 443 | 473 | 227 | 828 | 1725 | 31% | 51.09% | 1514 | 24 | render ⚠ +3 uncommitted |
| `d466115` | 2026-09-06 20:12 | **542** | 443 | 473 | 227 | 828 | 1725 | 31% | 51.09% | 1594 | 24 | render ⚠ +4 uncommitted |
| `70b79e3` | 2026-09-06 22:29 | **614** | 371 | 473 | 227 | 828 | 1725 | 36% | 51.09% | 1741 | 24 | render ⚠ +10 uncommitted |
| `7ec2388` | 2026-09-06 22:33 | **614** | 371 | 473 | 227 | 828 | 1725 | 36% | 51.09% | 1742 | 24 | render |
| `74f4730` | 2026-09-07 02:46 | **633** | 352 | 473 | 227 | 828 | 1725 | 37% | 51.09% | 1792 | 24 | render ⚠ +4 uncommitted |
| `dde4781` | 2026-09-07 02:52 | **634** | 351 | 473 | 227 | 828 | 1725 | 37% | 51.09% | 1795 | 24 | render ⚠ +3 uncommitted |
| `983f3d8` | 2026-09-07 05:24 | **634** | 284 | 473 | 227 | 828 | 1657 | 38% | 51.09% | 1796 | 24 | render ⚠ +9 uncommitted |
| `1c47fe4` | 2026-09-07 05:40 | **659** | 259 | 473 | 227 | 828 | 1657 | 40% | 51.09% | 1826 | 24 | render ⚠ +2 uncommitted |
| `1d2105b` | 2026-09-07 05:42 | **659** | 259 | 473 | 227 | 828 | 1657 | 40% | 51.09% | 1827 | 24 | render |
| `4ffb14e` | 2026-09-07 06:06 | **674** | 244 | 473 | 227 | 828 | 1657 | 41% | 51.09% | 1858 | 24 | render ⚠ +2 uncommitted |
| `e96bf0e` | 2026-09-07 06:08 | **674** | 244 | 473 | 227 | 828 | 1657 | 41% | 51.09% | 1859 | 24 | render |
| `64d0dfe` | 2026-09-07 06:52 | **674** | 244 | 473 | 227 | 828 | 1657 | 41% | 50.89% | 1859 | 24 | render ⚠ +5 uncommitted |
| `5c3824e` | 2026-09-07 07:26 | **674** | 244 | 473 | 227 | 828 | 1657 | 41% | 63.23% | 1878 | 24 | render ⚠ +9 uncommitted |
| `4a63bcf` | 2026-09-07 07:53 | **692** | 225 | 473 | 227 | 828 | 1657 | 42% | 63.23% | 1967 | 24 | render ⚠ +12 uncommitted |
| `f1c99d2` | 2026-09-07 08:04 | **674** | 244 | 473 | 227 | 828 | 1657 | 41% | 50.89% | 1859 | 24 | render ⚠ +9 uncommitted |
| `535186f` | 2026-09-07 08:08 | **700** | 225 | 465 | 227 | 828 | 1657 | 42% | 63.23% | 1967 | 24 | render ⚠ +2 uncommitted |
| `39f145f` | 2026-09-07 08:15 | **713** | 212 | 465 | 227 | 828 | 1657 | 43% | 65.31% | 2078 | 24 | render ⚠ +9 uncommitted |
| `0b200d2` | 2026-09-07 08:18 | **713** | 212 | 465 | 227 | 828 | 1657 | 43% | 65.31% | 2079 | 24 | render |
| `06d8f6c` | 2026-09-07 08:21 | **705** | 258 | 480 | 251 | 828 | 1733 | 41% | 53.26% | 1994 | 31 | render ⚠ +12 uncommitted |
| `381f2a5` | 2026-09-07 08:23 | **744** | 226 | 472 | 251 | 828 | 1733 | 43% | 53.26% | 1994 | 31 | render ⚠ +59 uncommitted |
| `31a2d2b` | 2026-09-07 08:33 | **744** | 226 | 472 | 251 | 828 | 1733 | 43% | 69.84% | 2214 | 31 | render |
| `3479bf4` | 2026-09-07 09:01 | **720** | 205 | 465 | 227 | 828 | 1657 | 43% | 65.31% | 2093 | 24 | render ⚠ +8 uncommitted |
| `d8f32c3` | 2026-09-07 09:04 | **720** | 205 | 465 | 227 | 828 | 1657 | 43% | 65.31% | 2094 | 24 | render |
| `9479a60` | 2026-09-07 09:05 | **720** | 205 | 465 | 227 | 828 | 1657 | 43% | 65.31% | 2094 | 24 | render ⚠ +3 uncommitted |
| `cca8ef3` | 2026-09-07 09:26 | **744** | 235 | 473 | 239 | 828 | 1733 | 43% | 69.96% | 2222 | 32 | render ⚠ +26 uncommitted |
| `2fddc94` | 2026-09-07 10:26 | **744** | 235 | 473 | 239 | 828 | 1733 | 43% | 70.01% | 2226 | 32 | render ⚠ +13 uncommitted |
| `dac781d` | 2026-09-07 10:27 | **751** | 228 | 473 | 239 | 828 | 1733 | 43% | 70.01% | 2226 | 32 | render ⚠ +15 uncommitted |
| `08bdd93` | 2026-09-07 10:36 | **751** | 228 | 473 | 239 | 828 | 1733 | 43% | 69.99% | 2261 | 32 | render |
| `ccc42ce` | 2026-09-07 11:07 | **751** | 228 | 473 | 239 | 828 | 1733 | 43% | 70.41% | 2273 | 32 | render ⚠ +10 uncommitted |
| `267879e` | 2026-09-07 11:18 | **762** | 217 | 473 | 239 | 828 | 1733 | 44% | 65.31% | 2293 | 32 | render |
| `6b57540` | 2026-09-07 11:18 | **751** | 225 | 476 | 239 | 828 | 1733 | 43% | 70.41% | 2273 | 33 | render ⚠ +10 uncommitted |
| `dbb924b` | 2026-09-07 11:24 | **773** | 206 | 473 | 239 | 828 | 1733 | 45% | 65.31% | 2303 | 32 | render ⚠ +2 uncommitted |
| `4435c14` | 2026-09-07 11:31 | **751** | 225 | 476 | 239 | 828 | 1733 | 43% | 70.41% | 2273 | 33 | render ⚠ +5 uncommitted |
| `8949426` | 2026-09-07 11:33 | **773** | 203 | 476 | 239 | 828 | 1733 | 45% | 70.41% | 2273 | 33 | render ⚠ +5 uncommitted |
| `ed14762` | 2026-09-07 11:36 | **777** | 216 | 479 | 174 | 872 | 1689 | 46% | 65.31% | 2303 | 32 | render ⚠ +1 uncommitted |
| `54f62d8` | 2026-09-07 11:43 | **773** | 203 | 476 | 239 | 828 | 1733 | 45% | 70.5% | 2304 | 33 | render |
| `5724d49` | 2026-09-07 11:44 | **777** | 213 | 482 | 174 | 872 | 1689 | 46% | 70.5% | 2304 | 33 | render ⚠ +6 uncommitted |
| `0bba309` | 2026-09-07 11:53 | **777** | 213 | 482 | 174 | 872 | 1689 | 46% | 70.5% | 2304 | 33 | render |
| `ed18367` | 2026-09-07 12:02 | **779** | 221 | 482 | 147 | 888 | 1673 | 47% | 65.31% | 2326 | 32 | render ⚠ +13 uncommitted |
| `d42961f` | 2026-09-07 12:12 | **779** | 218 | 485 | 147 | 888 | 1673 | 47% | 65.31% | 2326 | 33 | render ⚠ +1 uncommitted |
| `a7c111d` | 2026-09-07 21:35 | **791** | 236 | 496 | 82 | 908 | 1651 | 48% | 65.31% | 2326 | 33 | render ⚠ +1 uncommitted |
| `82ade1f` | 2026-09-08 01:58 | **837** | 251 | 502 | 0 | 919 | 1639 | 51% | 70.13% | 2349 | 33 | render ⚠ +20 uncommitted |
| `2ec91fd` | 2026-09-09 05:26 | **837** | 251 | 502 | 0 | 919 | 1639 | 51% | 70.13% | 2361 | 33 | render ⚠ +7 uncommitted |
| `456db14` | 2026-09-09 06:18 | **837** | 251 | 502 | 0 | 919 | 1639 | 51% | 70.67% | 2469 | 33 | render ⚠ +5 uncommitted |
| `7000dd1` | 2026-09-09 11:59 | **837** | 251 | 502 | 0 | 919 | 1639 | 51% | 70.67% | 2491 | 33 | render ⚠ +4 uncommitted |
| `789079d` | 2026-09-09 21:00 | **837** | 251 | 502 | 0 | 919 | 1639 | 51% | 70.67% | 2491 | 33 | render ⚠ +5 uncommitted |
| `bee88fb` | 2026-09-09 21:07 | **837** | 251 | 502 | 0 | 919 | 1639 | 51% | 70.67% | 2491 | 33 | render ⚠ +16 uncommitted |
| `cedc121` | 2026-09-10 21:36 | **837** | 251 | 502 | 0 | 919 | 1639 | 51% | 70.57% | 2588 | 33 | render |
| `94d5782` | 2026-09-12 05:11 | **837** | 252 | 502 | 0 | 918 | 1640 | 51% | 70.79% | 2825 | 33 | render |
| `094b322` | 2026-09-15 08:43 | **600** | 495 | 499 | 0 | 916 | 1642 | 37% | 39.94% | 2288 | 33 | render ⚠ +4 uncommitted |
| `8ae0feb` | 2026-09-21 08:11 | **615** | 496 | 485 | 0 | 914 | 1644 | 37% | 63.74% | 2569 | 37 | render ⚠ +6 uncommitted |
| `2d9abc1` | 2026-09-25 08:23 | **620** | 496 | 483 | 0 | 912 | 1646 | 38% | 75.7% | 2733 | 35 | render ⚠ +9 uncommitted |
| `b9cac6c` | 2026-09-25 09:25 | **620** | 496 | 483 | 0 | 912 | 1646 | 38% | 75.7% | 2755 | 35 | render ⚠ +9 uncommitted |
| `e68f944` | 2026-09-26 03:55 | **620** | 496 | 483 | 0 | 912 | 1646 | 38% | 75.7% | 2755 | 35 | render ⚠ +7 uncommitted |
| `424dfc7` | 2026-09-27 08:22 | **620** | 496 | 483 | 0 | 912 | 1646 | 38% | 76.12% | 2984 | 38 | render ⚠ +5 uncommitted |
| `f9f8b1a` | 2026-09-27 08:51 | **629** | 495 | 479 | 0 | 908 | 1650 | 38% | — | 2984 | 39 | render |
| `7f04b0a` | 2026-09-27 09:14 | **629** | 495 | 479 | 0 | 908 | 1650 | 38% | 76.05% | 3115 | 39 | render ⚠ +4 uncommitted |
| `3fae6d2` | 2026-09-27 09:40 | **629** | 495 | 479 | 0 | 908 | 1650 | 38% | 76.33% | 3163 | 40 | render ⚠ +4 uncommitted |
| `99754dd` | 2026-09-27 11:03 | **650** | 496 | 457 | 0 | 908 | 1650 | 39% | 80.64% | 3339 | 31 | render ⚠ +5 uncommitted |
| `12038c7` | 2026-09-27 11:38 | **659** | 499 | 441 | 0 | 912 | 1646 | 40% | 81.01% | 3389 | 31 | render ⚠ +4 uncommitted |
| `b174c14` | 2026-09-27 12:08 | **670** | 500 | 429 | 0 | 912 | 1646 | 41% | 81.53% | 3462 | 29 | render ⚠ +4 uncommitted |
| `c560eed` | 2026-09-27 12:51 | **670** | 500 | 429 | 0 | 912 | 1646 | 41% | 81.53% | 3464 | 29 | render ⚠ +4 uncommitted |
| `33df66f` | 2026-09-28 23:47 | **673** | 500 | 426 | 0 | 912 | 1646 | 41% | 81.53% | 3464 | 28 | render |
| `0057768` | 2026-09-29 02:11 | **673** | 500 | 426 | 0 | 912 | 1646 | 41% | — | 3464 | 28 | render |
| `b13b0f7` | 2026-09-29 03:12 | **673** | 500 | 426 | 0 | 912 | 1646 | 41% | 81.86% | 3677 | 28 | render ⚠ +4 uncommitted |
| `727d013` | 2026-09-29 07:24 | **673** | 500 | 426 | 0 | 912 | 1646 | 41% | 81.87% | 3704 | 28 | render ⚠ +4 uncommitted |
| `807d466` | 2026-09-30 02:28 | **680** | 526 | 394 | 0 | 913 | 1645 | 41% | 81.87% | 3737 | 27 | render ⚠ +4 uncommitted |
| `ea2975b` | 2026-09-30 04:54 | **684** | 526 | 390 | 0 | 913 | 1645 | 42% | 88.85% | 3950 | 25 | render |
| `2e2f579` | 2026-09-30 08:10 | **695** | 526 | 380 | 0 | 912 | 1646 | 42% | 88.84% | 3983 | 23 | render |
| `ca2320e` | 2026-09-30 09:13 | **746** | 532 | 298 | 0 | 935 | 1623 | 46% | 88.78% | 4003 | 22 | render |
| `19a4814` | 2026-09-30 10:10 | **772** | 543 | 200 | 0 | 992 | 1566 | 49% | 88.82% | 4030 | 31 | render |
| `1083e12` | 2026-09-30 11:43 | **780** | 543 | 192 | 0 | 992 | 1566 | 50% | 90.99% | 4153 | 29 | render |
| `087783d` | 2026-09-30 13:17 | **782** | 543 | 190 | 0 | 992 | 1566 | 50% | 91.04% | 4173 | 29 | render |
| `27f3c4f` | 2026-10-01 01:05 | **787** | 544 | 186 | 0 | 990 | 1568 | 50% | 91.09% | 4193 | 29 | render |
| `bde9ff3` | 2026-10-01 01:54 | **790** | 545 | 182 | 0 | 990 | 1568 | 50% | 91.14% | 4206 | 28 | render |
| `268d1a2` | 2026-10-01 11:35 | **790** | 545 | 182 | 0 | 990 | 1568 | 50% | 91.14% | 4207 | 28 | render |
| `96ba3aa` | 2026-10-03 06:55 | **793** | 547 | 177 | 0 | 990 | 1568 | 51% | 91.14% | 4225 | 27 | render |
| `e8d82a8` | 2026-10-09 00:35 | **789** | 542 | 177 | 0 | 999 | 1559 | 51% | 92.6% | 4202 | 27 | render ⚠ +4 uncommitted |

Net movement across the series: **+425 covered**, -129 implemented, -293 gap, -208 UNREVIEWED, +199 n/a, -194 scored, +30 pp on Axis B.

## Two different questions

A good score on either one tells you nothing about the other, so they are never added together.

| The question | What it means | Now |
|---|---|---|
| **Does the test suite ever run this line of code?** (Axis A) | Of every line in the TypeScript packages and services, how many does at least one test actually execute? The rest are never visited — mostly error handling and edge branches — so nothing can be found wrong with them, because nothing goes there. | **92.6%** — 9021 of 9741 lines |
| **Is there a test proving we follow this rule?** (Axis B) | The standards contain 1559 sentences we hold ourselves to — things like *"the mdoc reader MUST verify the issuer's certificate chain"*. For how many is there a named test that would go red if we stopped doing it? | **51%** — 789 of 1559 rules |

**Why they cannot be one number.** You can run every line and prove nothing — the code executes, but no test checks it matches the spec. And you can score well on the rules while the error paths never execute at all. The CBOR bug is the clean case: nine bytes from any counterparty crashed the wallet, and no standard anywhere contains a sentence saying *do not crash on malformed input*, so the rules question could never have found it. Only "does anything run this code with hostile input" finds that.

**What counts as a test here.** It has to check against something **outside** our own code — the spec's own published example bytes, or a third-party library. If our Swift and our TypeScript are wrong in the same way, they agree with each other and a test comparing them passes. That is why a rule only counts once its evidence is external, and why running more lines does not, on its own, make the evidence better.

| Language | Is its code coverage measured? | How that was determined |
|---|---|---|
| typescript | measured over a PARTIAL set | packages/shared, services/portal, services/wallet, 115 of 116 node suites ran — over ALL shipped files, not only the ones something loaded; services handle SIGTERM (packages/shared/src/shutdown.ts) so spawned children flush their V8 profile; held by conformance/test-graceful-shutdown.mjs — 0 failed, 1 skipped, so the percentage is over less code than it appears |
| java | measured over a PARTIAL set | vc-core + pf-ext, 64 of 65 Java-running suites; 1 class(es) unmatched and counted as 0% — 316 classes, 64 of 65 Java-running suites — 0 failed, 1 skipped, so the percentage is over less code than it appears |

## The OpenID Foundation's own tests, against the deployed service

A third kind of evidence, kept apart from both axes above. Nobody in this repository wrote these tests: they are the OpenID Foundation's certification plans, run from the suite's published images against the **deployed** demo, not this checkout. Each result is the latest for its module across every run of the same plan and configuration. A local run is not a certification. Suite 5.3.1 (440eec8); ledger `conformance/oidf/ledger.jsonl`, 61 plan runs.

"Good" is the drivers' word: finished with no failures. It is split below, because only **passed** means the checks ran and passed - *review* is waiting on a person to look at the evidence, and *skipped* did not apply, so nothing was tested.

| What it tests | Plan | Configuration | Good (passed · review · skipped) | Failing | No verdict | Needs a person | Not run | Deployed commit | Last run |
|---|---|---|---|---|---|---|---|---|---|
| pf-oid4vp, the verifier | `oid4vp-1final-verifier-haip-test-plan` | iso_mdl · direct_post.jwt | **4** of 4 (1 · 3 · 0) | 0 | 0 | 0 | 0 | `4259381` ×4 | 2026-09-26 |
| pf-oid4vp, the verifier | `oid4vp-1final-verifier-haip-test-plan` | sd_jwt_vc · direct_post.jwt | **11** of 11 (7 · 4 · 0) | 0 | 0 | 0 | 0 | `4259381` ×11 | 2026-09-26 |
| pf-oid4vci + PingFederate, the issuer (HAIP) | `oid4vci-1_0-issuer-haip-test-plan` | mdoc | **62** of 63 (46 · 8 · 8) | 0 | 0 | 1 | 0 | `40f9f9f` ×62, not recorded ×1 | 2026-09-26 |
| pf-oid4vci + PingFederate, the issuer (HAIP) | `oid4vci-1_0-issuer-haip-test-plan` | sd_jwt_vc | **62** of 63 (46 · 8 · 8) | 0 | 0 | 1 | 0 | `40f9f9f` ×62 | 2026-09-26 |
| pf-oid4vci + PingFederate, the issuer (no profile) | `oid4vci-1_0-issuer-test-plan` | mdoc · client_attestation · dpop · plain_oauth | **21** of 21 (17 · 0 · 4) | 0 | 0 | 0 | 0 | `40f9f9f` ×21 | 2026-09-26 |
| pf-oid4vci + PingFederate, the issuer (no profile) | `oid4vci-1_0-issuer-test-plan` | sd_jwt_vc · client_attestation · dpop · plain_oauth | **21** of 21 (17 · 0 · 4) | 0 | 0 | 0 | 0 | `40f9f9f` ×21 | 2026-09-26 |
| PingFederate as a FAPI 2.0 authorization server | `fapi2-security-profile-final-test-plan` | private_key_jwt · dpop · plain_oauth | **49** of 50 (41 · 7 · 1) | 0 | 0 | 1 | 0 | `40f9f9f` ×49 | 2026-09-26 |

Deployed commits these results name, against `e8d82a8`: `40f9f9f` — 154 commits behind; `4259381` — 141 commits behind.

Earlier configurations, replaced by a newer run of the same plan and format: `oid4vci-1_0-issuer-test-plan` sd_jwt_vc · private_key_jwt · dpop · plain_oauth (last 2026-09-21).

## Which standards are proven, document by document

`covered` divided by everything scored, `n/a` excluded — the register's harsh metric: an `implemented` row with no assertion behind it scores zero.

| Document | In scope | covered | implemented | gap | deviation | UNREVIEWED | n/a | elsewhere | Conformance |
|---|---|---|---|---|---|---|---|---|---|
| ISO18013-5-DIS2026 | 557 | 229 | 62 | 7 | 6 | 0 | 201 | 52 | 75% |
| OID4VCI-1.0 | 308 | 59 | 68 | 26 | 10 | 0 | 144 | 1 | 36% |
| OID4VP-1.0 | 288 | 100 | 70 | 10 | 4 | 0 | 104 | 0 | 54% |
| OIDFED-1.0 | 260 | 57 | 5 | 58 | 1 | 0 | 139 | 0 | 47% |
| SD-JWT-VC-19 | 117 | 17 | 19 | 7 | 1 | 0 | 73 | 0 | 39% |
| RFC5280 | 115 | 60 | 6 | 1 | 0 | 0 | 48 | 0 | 90% |
| HAIP-1.0 | 109 | 42 | 27 | 20 | 1 | 0 | 19 | 0 | 47% |
| ISO18013-7-2025 | 97 | 9 | 43 | 18 | 3 | 0 | 6 | 18 | 12% |
| RFC9901 | 90 | 59 | 11 | 6 | 2 | 0 | 12 | 0 | 76% |
| TSL-21 | 90 | 44 | 39 | 1 | 0 | 0 | 6 | 0 | 52% |
| RFC9700 | 70 | 4 | 19 | 5 | 2 | 0 | 40 | 0 | 13% |
| RFC9101 | 51 | 14 | 18 | 4 | 3 | 0 | 12 | 0 | 36% |
| RFC9449 | 47 | 26 | 8 | 0 | 0 | 0 | 13 | 0 | 76% |
| RFC6749 | 41 | 2 | 21 | 3 | 3 | 0 | 12 | 0 | 7% |
| RFC8414 | 36 | 5 | 11 | 0 | 5 | 0 | 15 | 0 | 24% |
| RFC9068 | 35 | 5 | 11 | 1 | 4 | 0 | 14 | 0 | 24% |
| RFC7517 | 33 | 1 | 11 | 0 | 0 | 0 | 21 | 0 | 8% |
| RFC8725 | 32 | 3 | 19 | 3 | 2 | 0 | 5 | 0 | 11% |
| RFC7515 | 31 | 6 | 10 | 2 | 0 | 0 | 13 | 0 | 33% |
| RFC7519 | 30 | 8 | 12 | 2 | 2 | 0 | 6 | 0 | 33% |
| RFC9126 | 27 | 1 | 15 | 0 | 0 | 0 | 11 | 0 | 6% |
| RFC9053 | 24 | 6 | 1 | 1 | 0 | 0 | 16 | 0 | 75% |
| RFC9052 | 23 | 7 | 2 | 0 | 0 | 0 | 14 | 0 | 78% |
| RFC8949 | 22 | 7 | 5 | 0 | 1 | 0 | 9 | 0 | 54% |
| RFC7518 | 19 | 2 | 15 | 0 | 0 | 0 | 2 | 0 | 12% |
| RFC9396 | 18 | 2 | 6 | 1 | 1 | 0 | 8 | 0 | 20% |
| W3C-DC-API-WD | 16 | 0 | 0 | 0 | 0 | 0 | 16 | 0 | None% |
| RFC7636 | 12 | 2 | 1 | 0 | 0 | 0 | 9 | 0 | 67% |
| RFC7516 | 11 | 2 | 4 | 1 | 0 | 0 | 4 | 0 | 29% |
| RFC9360 | 11 | 6 | 1 | 0 | 0 | 0 | 4 | 0 | 86% |
| EUDI-PID-RULEBOOK | 9 | 4 | 2 | 0 | 0 | 0 | 3 | 0 | 67% |
| **All** | **2629** | **789** | 542 | 177 | 51 | 0 | 999 | 71 | **51%** |

## Suites, as run.sh reaches them

Assertion counts are from the recorded run at `e8d82a87`.

| Suite | Kind | run.sh | Reached | Cited by the matrix |
|---|---|---|---|---|
| `conformance/test-session-transcript.mjs` | node | :198 | yes | yes |
| `conformance/test-json-claims.mjs` | node | :203 | yes | — |
| `conformance/test-mdoc-iso-vectors.mjs` | node | :210 | yes | yes |
| `conformance/test-federation.mjs` | node | :214 | yes | yes |
| `conformance/test-mdoc-roundtrip.mjs` | node | :218 | yes | yes |
| `conformance/test-trusted-authorities.mjs` | node | :222 | yes | yes |
| `conformance/test-age.mjs` | node | :226 | yes | — |
| `conformance/test-statuslist.mjs` | node | :230 | yes | yes |
| `conformance/test-key-source.mjs` | node | :235 | yes | — |
| `conformance/test-aki-cache.mjs` | node | :236 | yes | — |
| `conformance/test-secure-url.mjs` | node | :237 | yes | yes |
| `conformance/test-5xx-discipline.mjs` | node | :241 | yes | — |
| `conformance/test-status-check-ordering.mjs` | node | :245 | yes | — |
| `conformance/test-status-fetch-ordering.mjs` | node | :246 | yes | yes |
| `conformance/test-accessibility.mjs` | node | :250 | yes | — |
| `conformance/test-jose-pkce-rfcs.mjs` | node | :254 | yes | yes |
| `conformance/test-harness-contract.mjs` | node | :258 | yes | — |
| `conformance/test-dashboard-current.mjs` | node | :262 | yes | — |
| `conformance/test-oidf-ledger.mjs` | node | :266 | yes | — |
| `conformance/test-standards-register.mjs` | node | :275 | yes | — |
| `conformance/test-secure-randomness-ts.mjs` | node | :279 | yes | — |
| `conformance/test-catalog-parity.mjs` | node | :283 | yes | — |
| `conformance/test-pid-rulebook.mjs` | node | :287 | yes | yes |
| `conformance/test-dcql-catalogue.mjs` | node | :291 | yes | yes |
| `conformance/test-mdl-elements.mjs` | node | :295 | yes | yes |
| `conformance/test-pf-dts.mjs` | node | :299 | yes | yes |
| `conformance/test-pf-dts-statuslists.mjs` | node | :303 | yes | yes |
| `conformance/test-vical-format.mjs` | node | :307 | yes | yes |
| `conformance/test-vical-validate.mjs` | node | :311 | yes | yes |
| `conformance/test-rical-format.mjs` | node | :315 | yes | yes |
| `conformance/test-trustlist-parity.mjs` | node | :319 | yes | yes |
| `conformance/test-vical-consumer.mjs` | node | :323 | yes | yes |
| `conformance/test-admin-token-auth.mjs` | node | :327 | yes | — |
| `conformance/test-trustlist-provider.mjs` | node | :331 | yes | yes |
| `conformance/test-vical-external.mjs` | node | :335 | yes | — |
| `conformance/test-pf-oid4vp.mjs` | node | :339 | yes | yes |
| `conformance/test-pf-oid4vp-response.mjs` | node | :343 | yes | yes |
| `conformance/test-pf-oid4vp-sessions.mjs` | node | :347 | yes | — |
| `conformance/test-sd-jwt-rfc9901.mjs` | node | :348 | yes | yes |
| `conformance/test-pf-oid4vp-mdoc.mjs` | node | :352 | yes | yes |
| `conformance/test-mdoc-certpath.mjs` | node | :356 | yes | yes |
| `conformance/test-mdoc-pki.mjs` | node | :357 | yes | yes |
| `conformance/test-pki-quickstart.mjs` | node | :361 | yes | — |
| `conformance/test-pki-bundle-env.mjs` | node | :365 | yes | — |
| `conformance/validate-vectors.mjs` | node | :369 | yes | yes |
| `conformance/test-cbor-hostile.mjs` | node | :373 | yes | yes |
| `conformance/test-portal-identity.mjs` | node | :380 | yes | — |
| `conformance/test-portal-proofing.mjs` | node | :381 | yes | — |
| `conformance/test-portal-pf-signin.mjs` | node | :382 | yes | — |
| `conformance/test-scim-go.mjs` | node | :386 | yes | — |
| `conformance/test-scim-g92.mjs` | node | :390 | yes | — |
| `conformance/test-pf-vc-issue.mjs` | node | :394 | yes | yes |
| `conformance/test-sdjwt-vc-crossport.mjs` | node | :404 | yes | yes |
| `conformance/test-oid4vci-offer-java.mjs` | node | :408 | yes | — |
| `conformance/test-oid4vci-txcode.mjs` | node | :412 | yes | — |
| `conformance/test-statuslist-java.mjs` | node | :416 | yes | — |
| `conformance/test-secure-url-java.mjs` | node | :420 | yes | — |
| `conformance/test-oid4vci-status-java.mjs` | node | :424 | yes | yes |
| `conformance/test-security-headers-java.mjs` | node | :428 | yes | yes |
| `conformance/test-issuer-keys-java.mjs` | node | :432 | yes | — |
| `conformance/test-oid4vci-scope-authz-java.mjs` | node | :436 | yes | yes |
| `conformance/test-oid4vci-metadata-java.mjs` | node | :442 | yes | yes |
| `conformance/test-oid4vci-dpop-java.mjs` | node | :449 | yes | yes |
| `conformance/test-oid4vci-batch-notify-java.mjs` | node | :453 | yes | yes |
| `conformance/test-oid4vci-token-attestation-java.mjs` | node | :457 | yes | — |
| `conformance/test-oid4vci-grant-lifecycle.mjs` | node | :461 | yes | yes |
| `conformance/test-trusted-issuers-java.mjs` | node | :465 | yes | yes |
| `conformance/test-sdjwt-x5c-haip.mjs` | node | :472 | yes | — |
| `conformance/test-wallet-endpoints-java.mjs` | node | :476 | yes | — |
| `conformance/test-issuer-key-publish-java.mjs` | node | :480 | yes | — |
| `conformance/test-dcapi-openid4vp-java.mjs` | node | :484 | yes | yes |
| `conformance/test-pf-oid4vp-catalogue.mjs` | node | :485 | yes | — |
| `conformance/test-pf-oid4vp-evidence.mjs` | node | :486 | yes | — |
| `conformance/test-issuance-policy.mjs` | node | :490 | yes | — |
| `conformance/test-pf-oid4vci.mjs` | node | :494 | yes | yes |
| `conformance/test-pf-oid4vci-scim.mjs` | node | :498 | yes | yes |
| `conformance/test-mdl-table20.mjs` | node | :502 | yes | yes |
| `conformance/test-wallet-attestation.mjs` | node | :506 | yes | yes |
| `conformance/test-wallet-attest-filter.mjs` | node | :510 | yes | yes |
| `conformance/test-wallet-attest-x5c.mjs` | node | :516 | yes | — |
| `conformance/test-wallet-provider-java.mjs` | node | :520 | yes | — |
| `conformance/test-wallet-provider-http.mjs` | node | :524 | yes | yes |
| `conformance/test-pf-vp-adapter.mjs` | node | :528 | yes | — |
| `conformance/test-hpke-rfc9180.mjs` | node | :532 | yes | — |
| `conformance/test-dcapi-java-annexc.mjs` | node | :536 | yes | — |
| `conformance/test-dcapi-verifier-flow.mjs` | node | :540 | yes | — |
| `conformance/test-proximity.mjs` | node | :544 | yes | yes |
| `conformance/test-proximity-curves.mjs` | node | :545 | yes | yes |
| `conformance/test-rfc5280-certificates.mjs` | node | :554 | yes | yes |
| `conformance/test-iso18013-5-profile.mjs` | node | :562 | yes | yes |
| `conformance/test-pf-client-posture.mjs` | node | :587 | yes | yes |
| `conformance/test-oid4vci-key-proof.mjs` | node | :596 | yes | yes |
| `conformance/test-readertrust.mjs` | node | :606 | yes | yes |
| `conformance/test-wallet-selection.mjs` | node | :615 | yes | yes |
| `conformance/test-oid4vp-wallet-response.mjs` | node | :627 | yes | yes |
| `conformance/test-secure-tokens.mjs` | node | :632 | yes | — |
| `conformance/test-build-context.mjs` | node | :636 | yes | — |
| `conformance/test-pin-tls.mjs` | node | :640 | yes | — |
| `conformance/test-issuer-metadata-java.mjs` | node | :644 | yes | — |
| `conformance/test-wallet-isolation.mjs` | node | :648 | yes | yes |
| `conformance/test-wellknown.mjs` | node | :657 | yes | yes |
| `conformance/test-wallet-dpop.mjs` | node | :664 | yes | yes |
| `conformance/test-wallet-consent.mjs` | node | :671 | yes | yes |
| `conformance/test-wallet-fetch-bounds.mjs` | node | :677 | yes | — |
| `conformance/test-mdoc-status-java.mjs` | node | :684 | yes | yes |
| `conformance/test-wallet-par.mjs` | node | :690 | yes | yes |
| `conformance/test-wallet-rical.mjs` | node | :696 | yes | yes |
| `conformance/test-dts-publish-routes-java.mjs` | node | :702 | yes | — |
| `conformance/test-status-list-cache-java.mjs` | node | :708 | yes | yes |
| `conformance/test-cert-revocation-java.mjs` | node | :715 | yes | yes |
| `conformance/test-cert-revocation-ts.mjs` | node | :716 | yes | — |
| `conformance/test-state-store-java.mjs` | node | :722 | yes | — |
| `conformance/test-pki-crls.mjs` | node | :729 | yes | yes |
| `conformance/test-gateway-upstream-tls.mjs` | node | :735 | yes | — |
| `conformance/test-admin-relay.mjs` | node | :736 | yes | — |
| `conformance/test-wallet-provider-mint-limit-java.mjs` | node | :737 | yes | — |

## In flight elsewhere

This repo is worked by several sessions in one checkout, so these figures are a snapshot. What could already have moved them:

- **`main` is level with origin at `9f97b7c`; `origin/main` at `e8d82a8`**
- Rendered from `/Users/davidhyland/Source/idp-pf-vcs/.claude/worktrees/v1-ci` at `v1-ci`. The working-tree state below is that tree's, not the shared checkout's.
- **4 uncommitted file(s)** in that working tree: `onformance/COVERAGE-DASHBOARD.md` (M), `conformance/standards/dashboard.html` (M), `conformance/standards/dashboard.json` (M), `conformance/standards/history.jsonl` (M)
- **0 commit(s)** on this branch not on `origin/main`
- **31 unmerged branch(es)**:
  - `v1-ci` — 136 commit(s) ahead, 441 file(s), 143 under `conformance/` — test-gateway-upstream-tls no longer hangs on Docker Desktop and leaks its containers
  - `prod-fixes-b28` — 116 commit(s) ahead, 410 file(s), 133 under `conformance/` — G-126 half closed and G-127 closed bar an owner step: RAR locations and claims are checked, status lists refuse what one bit cannot hold, and the DC API reader can send the 2nd edition request
  - `prod-fixes-b27` — 114 commit(s) ahead, 403 file(s), 128 under `conformance/` — Dashboard from a clean CI-mode run of batch twenty-seven: 4,225 passed, 0 failed, one declared skip
  - `release-split` — 112 commit(s) ahead, 400 file(s), 128 under `conformance/` — The public repo exists, empty: the hand-off writes its publish workflow first
  - `prod-fixes-b26` — 106 commit(s) ahead, 381 file(s), 128 under `conformance/` — Dashboard from a clean CI-mode run of batch twenty-six: 4,206 passed, 0 failed, one declared skip
  - `prod-fixes-b25` — 104 commit(s) ahead, 381 file(s), 128 under `conformance/` — Dashboard from a clean CI-mode run of batch twenty-five: 4,193 passed, 0 failed, one declared skip
  - `prod-fixes-b24` — 102 commit(s) ahead, 377 file(s), 128 under `conformance/` — Dashboard from a clean CI-mode run of batch twenty-four: 4,173 passed, 0 failed, one declared skip
  - `prod-fixes-b23` — 99 commit(s) ahead, 375 file(s), 128 under `conformance/` — Dashboard from a clean CI-mode run of batch twenty-three: 4,153 passed, 0 failed, one declared skip
  - `prod-fixes-b22` — 95 commit(s) ahead, 365 file(s), 126 under `conformance/` — Dashboard from a clean CI-mode run of batch twenty-two: 4,030 passed, 0 failed, one declared skip
  - `prod-fixes-b21` — 92 commit(s) ahead, 357 file(s), 123 under `conformance/` — Dashboard from a clean CI-mode run of batch twenty-one: 4,003 passed, 0 failed, one declared skip
  - `prod-fixes-b20` — 89 commit(s) ahead, 354 file(s), 122 under `conformance/` — Dashboard from a clean CI-mode run of batch twenty: 3,983 passed, 0 failed, one declared skip
  - `docker-compose` — 79 commit(s) ahead, 315 file(s), 111 under `conformance/` — The Railway deploy scripts are gone: the platform is built and tested with Docker now
  - `prod-fixes-b15` — 73 commit(s) ahead, 273 file(s), 105 under `conformance/` — Dashboard from a clean CI-mode run of batch fifteen: 3,704 passed, 0 failed, one declared skip
  - `prod-fixes-b14` — 70 commit(s) ahead, 261 file(s), 100 under `conformance/` — Dashboard from a clean CI-mode run of batches thirteen and fourteen: 3,677 passed, 0 failed, one declared skip
  - `prod-fixes-b13` — 65 commit(s) ahead, 242 file(s), 96 under `conformance/` — Four more suites list the attest and SD-JWT classes by name, and needed CertRevocation beside them
  - `prod-fixes-b12` — 62 commit(s) ahead, 225 file(s), 89 under `conformance/` — Dashboard from a clean CI-mode run of batch twelve: 3,464 passed, 0 failed, one declared skip
  - `prod-fixes-b11` — 59 commit(s) ahead, 223 file(s), 89 under `conformance/` — Dashboard from a clean CI-mode run of batch eleven: 3462 passed, 0 failed, one declared skip
  - `prod-fixes-b10` — 53 commit(s) ahead, 214 file(s), 82 under `conformance/` — Dashboard from a clean CI-mode run of batch ten: 3389 passed, 0 failed, one declared skip
  - `prod-fixes-b9` — 48 commit(s) ahead, 198 file(s), 76 under `conformance/` — Dashboard from a clean CI-mode run of batches six to nine: 0 failed, one declared skip
  - `prod-fixes-b8` — 45 commit(s) ahead, 196 file(s), 74 under `conformance/` — The verifier's issuer-key refusal names the iss again, and the secure-URL suite's stub names itself
  - `prod-fixes-b7` — 41 commit(s) ahead, 186 file(s), 70 under `conformance/` — The web wallet's Credential Request carries proofs, as 1.0 Final defines it (G-113); the issuer-metadata suite compiles again
  - `prod-fixes-b6` — 36 commit(s) ahead, 178 file(s), 68 under `conformance/` — Each web wallet gets its own holder key even with WALLET_HOLDER_JWK set
  - `prod-fixes-b5` — 26 commit(s) ahead, 163 file(s), 62 under `conformance/` — Dashboard from a clean CI-mode run of batch five: 3163 passed, 0 failed, one declared skip
  - `prod-fixes-b4` — 17 commit(s) ahead, 146 file(s), 57 under `conformance/` — Dashboard from a clean CI-mode run of batch four: 3115 passed, 0 failed, one declared skip
  - `prod-fixes` — 10 commit(s) ahead, 94 file(s), 37 under `conformance/` — Dashboard at 424dfc7 from a clean CI-mode run: 2984 passed, 0 failed, one declared skip
  - `conformance-audit-2026-09-04` — 2 commit(s) ahead, 9 file(s), 0 under `conformance/` — Solution site: one view of the platform, from architecture to conformance
  - `conformance/restore-oracle-deps` — 2 commit(s) ahead, 6 file(s), 4 under `conformance/` — Dashboard refresh at 1d287e9: every server is Java, and covered falls 837 → 599
  - `review/remove-demo-runtime` — 2 commit(s) ahead, 36 file(s), 4 under `conformance/` — Run runtime configuration checks in conformance
  - `review/security-defects` — 2 commit(s) ahead, 36 file(s), 4 under `conformance/` — Run runtime configuration checks in conformance
  - `merge-verification` — 1 commit(s) ahead, 3 file(s), 1 under `conformance/` — Merge remote-tracking branch 'origin/fix/cbor-decoder-traps' into merge-verification
  - `wallet-provider-attestation` — 1 commit(s) ahead, 4 file(s), 0 under `conformance/` — Docs: the wallet provider, the fourth extension shape, and one claim that stopped being true

## What the figures do not mean

Capabilities a percentage can be read as claiming, and does not. Carried in `scope.json`
beside the scope decision each one qualifies.

- **ISO18013-5-DIS2026** — RICAL is PUBLISHED, not CONSUMED. pf-dts signs and serves a RICAL, and both ports implement the F.3.2.5 and F.3.2.6 rules for reading one, with conformance behind them — but no running component here reads a RICAL. A RICAL is for a WALLET deciding whether to trust a reader, and this deployment is the reader. The only wallet in this repository is a demo and the verifier's test double. So the F.3.2.x rows are a tested library, not a behaviour anything here has (G-68).
- **ISO18013-5-DIS2026** — The VICAL/RICAL signer profile is checked and REPORTED, not enforced. C.1.8 defers to the certificate validation procedure, which requires RFC 5280 §6.1 path validation and not Table C.1/F.1 conformance — Table C.1 binds the CA issuing a signer certificate. Departures that do not change what a signer may sign are recorded and surfaced, not refused; keyCertSign and a missing mdlVICAL EKU stay fatal (G-67).
- **ISO18013-5-DIS2026** — No revocation is ever checked. CRLs are published for our own trust-list signers so a consumer that checks is not broken, but nothing here fetches one — for a trust-list signer, a Document Signer or a reader certificate (G-60).

## What this dashboard cannot see

Stated because a coverage report that does not bound itself is the defect it exists to catch (G-25).

- **Registration is not execution, and execution is not correctness.** A reachable suite with a recorded pass proves its own assertions ran and held. It says nothing about the assertions nobody wrote.
- **The suite inventory is static text.** `run.sh` is parsed, not traced. A suite guarded by a condition that is false on every machine would read as reachable here.
- **`implemented` rows are unfalsified claims**, and they are the largest single block in the register (542 of 1559 scored, 35%). They are counted as gaps on purpose.
- **UNREVIEWED is not zero** (0 statements). Nobody has looked at those, which is different from having looked and found them absent.
- **ISO rows are redacted** to clause and hash; the licensed text is not in the repo.

