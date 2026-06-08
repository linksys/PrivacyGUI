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
| I-6 | **Instant-Test own card on dashboardMenu** | Move out of the Instant-Verify box. Touches shared `dashboard_menu_view.dart` + route registration — OUTSIDE the feature dir, affects the app's front door. Needs care. |
| I-7 | **Channel recommendation: scan vs hardcoded (B-18)** | Today always recommends ch 6 / 36 (hardcoded, no scan). Decide: (a) run a real JNAP site-survey? (b) expose channel numbers to customers at all? (c) surface on landing page? Needs product decision + JNAP capability investigation. |
| PORT | **Port all completed JNAP changes to USP branch** | Best as one batch after JNAP set approved on-device. USP file layout differs (`instant_test/`). Per [[processes/branch-strategy]]. |

## Known Bugs (from testing)
| ID | Bug | Location | Status |
|----|-----|----------|--------|
| BUG-1 | **Device connectivity → "Check your WiFi details": check items render as triangles** (`Icons.arrow_right`), making them look expandable, but they don't expand. Should be dots or checkmarks (non-interactive markers). | `help_me_fix_it_tab.dart` (arrow_right icons ~L407/1494/2061) | Open (reported 2026-06-08) |
| BUG-2 | **Same screen shows "Step 2 of 4" but there's no further step reachable** — step counter overcounts or the flow dead-ends before step 4. | `help_me_fix_it_tab.dart` `_stepIndicatorNotifier` (~L48) | Open (reported 2026-06-08) |

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
