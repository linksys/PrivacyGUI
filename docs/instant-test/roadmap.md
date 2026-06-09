# Instant-Test — Roadmap & Open Items

> What's done, what's queued, and known bugs. Source of truth for "what's next."

Last updated: 2026-06-08

---

## Done (this session — JNAP line, pushed + deployed)
| ID | Item | Commit |
|----|------|--------|
| I-8 | Delete dead `instant_verify_view` subtree (1,997 LOC, 7 files) | `985f95de` |
| I-1 | Unify 3 restart-confirm dialogs → `restart_helper.dart` (+ fixed my_network missing-confirmation bug) | `72a54a4e` |
| I-2 | Unify 2 force-reconnect dialogs → `device_actions.dart` | `84be8954` |
| I-3 | AppCard framing across all 4 tabs | `3fe06ab3`, `1398947f` |
| I-5 | Router info (model·fw·serial) top-right, replacing ⓘ icon | `efc5d14b` |
| I-4 | Refresh button on My Network + pull-to-refresh on device tabs | `baa5cffb` |
| — | Earlier: rebrand → Instant-Test, Switch Device, framed cards, selectable text, copy-icon removal | (prior commits) |

## Queued (improvement items)
| ID | Item | Notes |
|----|------|-------|
| ~~I-6~~ | ~~Instant-Test own card on dashboardMenu~~ | ✅ Done 2026-06-09. Restored the original Instant-Verify technician tool (`InstantVerifyView`, recovered from git, identical to dev-1.2.9) to its own card/route; gave Instant-Test its own `menuInstantTest` route + dashboardMenu card (networkCheck icon) → `InstantVerifyPivotView`. The two tools are now cleanly separate. New l10n: instantTest/instantTestDesc. |
| ~~I-7~~ | ~~Channel recommendation: scan vs hardcoded (B-18)~~ | ✅ **Done 2026-06-09.** Discovered the firmware already does REAL channel optimization (`StartAutoChannelSelection` + poll `GetSelectedChannels`, used by WiFi-settings' channelFinder). Replaced the hardcoded 6/36 picker with a real `optimizeChannels()` on the pivot provider: snapshots channels → triggers the firmware RF scan → polls until settled → returns a before→after diff. UI: "Optimize my WiFi channels" button (Help Me Fix It flow + device-detail "cleaner channel") → ~1-min progress dialog → result ("tuned" with subtle "2.4GHz: 6 → 11" / "already optimal" / "couldn't optimize"). Channel numbers shown subtly per decision. The old hardcoded `changeRadioChannel` is now unused (kept as provider API). |
| PORT | **Port all completed JNAP changes to USP branch** | Best as one batch after JNAP set approved on-device. USP file layout differs (`instant_test/`). Per [[processes/branch-strategy]]. |

## Known Bugs (from testing)
| ID | Bug | Location | Status |
|----|-----|----------|--------|
| BUG-1 | Device connectivity check items rendered as triangles (looked expandable). | `_checklistItem` help_me_fix_it_tab.dart | ✅ Fixed 2026-06-08 — now a small dot marker |
| BUG-2 | "Step 2 of 4" shown but no step 4 reachable (hardcoded denominator on branching flows). | `_syncStepBackNotifier` x3 | ✅ Fixed 2026-06-08 — show "Step N", no fixed total |
| BUG-3 | Link rate showed "1297100 Mbps" (Kbps stored as Mbps). | provider txRate parse | ✅ Fixed 2026-06-08 — ÷1000 + Gbps promotion |
| BUG-4 | Failed/incomplete speed test was silently discarded → false green "We didn't detect any issues". | provider speed block + overview all-clear | ✅ Fixed 2026-06-09. v1 used an overview-only card gated on isAllClear — too narrow (didn't fire if any other finding existed, and the card showed nothing at top). v2 (robust): `speedTestFailed` flows into VerdictEngine.compute → emits a real warning finding "We couldn't finish the speed test", so it shows at the top alongside any findings, the Speed-check row flags amber, and it can't be missed. |
| BUG-5 | Single-line fix-suggestion + speed-tier pointer still used triangle icons (arrow_right) → looked like hidden/expandable text. | help_me_fix_it_tab.dart | ✅ Fixed 2026-06-09 — fix suggestions use a lightbulb; tier pointer uses a dot. (play_arrow on action buttons kept — it's a real action.) |
| BUG-6 | Finding/check mismatch: "High lag detected (103ms)" warning shown, but the Speed check row in Test details rendered green/pass — user couldn't see where the issue was. | overview_tab.dart Speed check row | ✅ Fixed 2026-06-09 — added a `warning` (amber) check state; Speed check row flags >100ms latency as warning with "— high lag" so it matches the finding. |
| BUG-7 | Test-details rows didn't consistently reflect top-level warnings — a warning finding could appear with all rows looking green. | overview_tab.dart Test details rows | ✅ Fixed 2026-06-09 — map findings to their detail row where one exists: latency→Speed check (amber), weak devices→Devices checked (amber); WAN/DNS already→fail; firmware→info-blue. Findings with no row (CPU/memory/schedule/privacy/paused/interference) stay top-only by design. |

## Follow-ups
- **Surface WHY a check failed** (not just that it did): timeout vs CDN-block vs DNS. Currently only `dev.log`'d (invisible on deployed router). Consider capturing a failure reason string in state for the retry card / support handoff.
- Extend the incomplete-check → surface+retry pattern to gateway ping, DNS, connectivity (currently speed test only).
- ~~INVESTIGATE: speed test fails recurringly~~ → **ROOT CAUSE FOUND & FIXED 2026-06-09.** NOT a network failure — raw `fetch` from the device gave 221 Mbps fine. The real cause: the speed test has a **3-minute throttle** (`skipSpeedTest` when `!forceSpeedTest` && last run <3min ago). "Works first time, fails on re-run" was the giveaway — the first run set `_lastSpeedTestTime`, and the "Run Again"/refresh buttons called `fetch()` WITHOUT `forceSpeedTest: true`, so subsequent runs skipped the speed test (showing as not-completed). Fix: all explicit user re-run/refresh actions (overview "Run Again", My Devices/My Network refresh + pull-to-refresh) now pass `forceSpeedTest: true`. The throttle now only applies to passive auto-reloads. (BUG-8)
- ~~Mixed-content bug~~ → **BUG-9 fixed 2026-06-09.** `_gatewayUrl` hardcoded `http://${Uri.base.host}` → on the HTTPS page that fired a blocked `http://192.168.1.1` request (mixed-content/CORS console error). Now uses `Uri.base.origin` on web (matches the page scheme), keeping the explicit `http://192.168.1.1` only on native. Clears the console error.
- **BUG-10 (fixed 2026-06-09): speed-test anti-hammer protection.** The throttle fix (BUG-8) removed all rate-limiting on explicit re-runs — only the in-flight guard remained, so a user could fire a new full speed test the instant each finished. Added a **15s hard cooldown** in the provider (`_lastSpeedTestAttempt` + `speedTestCooldownRemaining`) that even a forced/explicit re-run cannot bypass — protects ALL surfaces (buttons + pull-to-refresh). The overview "Run Again" button shows a live "Run Again (12s)" countdown and is disabled during cooldown. Passive 3-min throttle and in-flight guard still apply on top.

## Larger Initiatives (plans live in PRODUCT_MANAGEMENT docs)
| Item | Plan |
|------|------|
| Two-line shared diagnostics core | `Plans/two-line-strategy.md` — see [[concepts/two-line-strategy]] |
| V2.0 Guardians cloud handoff | `Plans/v2-guardians-handoff.md` |
| V2.1 mesh + wired diagnostics (RM-3…RM-14) | `Plans/v2.1-mesh-wired.md` |
| V3.0 hardware button | `Plans/v3-hardware-button.md` |

## Backlog
Full triaged backlog (B-1…B-18) lives in PRODUCT_MANAGEMENT `Context/backlog-post-triage.md`
and customer signal in `Context/feedback-log.md`.

## Related
- [[feature-linkage-map]] — where shared code lives (informs how to apply changes everywhere)
- [[index]]

## Last Verified
2026-06-08
