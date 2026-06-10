# USP Port Plan — 2026-06-09 session work

> Porting this session's JNAP-branch work (`feature/Instant-Troubleshooting`,
> 24 commits) to the USP branch (`feature/instant-test-usp`).
> USP uses `lib/page/instant_test/` with `DeviceUIModel`/`NodeUIModel` (not
> `instant_verify/` + `DiagnosticClient`). Per [[concepts/two-line-strategy]],
> these are UI-layer ports done deliberately — NOT a blind file copy.

## What USP ALREADY has (skip)
- ✅ SelectionArea (text selectable) — instant_test_page + my_devices_tab
- ✅ Own route + card — `route_usp_dashboard.dart` → `InstantTestPage`. The I-6
  card-split is essentially native on USP (it was never co-opted there). Just
  verify the card label/icon and that Instant-Verify is separate.
- ✅ `fetch(forceSpeedTest)` and `restartRouter()` on the provider
- ✅ verdict.dart takes downloadMbps/latencyMs

## Classification of the 24 commits

### A. Pure UI/UX — port with light adaptation (file layout differs)
| Change | USP target | Notes |
|--------|-----------|-------|
| Rebrand "Instant Help"→"Instant-Test" | instant_test_page | USP likely already uses loc(instantTest); verify title |
| Remove copy icon + selectable text | my_devices_tab | SelectionArea already there; check for copy icons |
| AppCard framing (all tabs) | overview/my_devices/my_network/help_me_fix_it | USP has 0 AppCard — port the Card→AppCard swaps |
| Router info top-right (stacked Model/Ver/Serial) | instant_test_page AppBar | adapt to USP state field names |
| Refresh surfaces + pull-to-refresh | my_devices/my_network | wire to USP fetch() |
| Triangle-icon scrub (dot/lightbulb) | help_me_fix_it (_checklistItem, fix rows) | mechanical |
| Step-counter "Step N" (drop /4) | help_me_fix_it | if USP has the same _syncStepBackNotifier |
| Scrollable scenario picker + grid .ceil() | overview + dashboard_menu | dashboard grid fix is SHARED (already on USP? verify) |
| "Switch Device" label | help_me_fix_it | mechanical |

### B. Shared helpers — create USP copies (different imports/types)
| Helper | Action |
|--------|--------|
| `restart_helper.dart` (confirmAndRestart) | Create in instant_test/views/; wire USP restart surfaces through it |
| `device_actions.dart` (confirmAndDeauth) | USP provider LACKS deauthClient — add it first, then the helper |

### C. Provider logic — add to USP instant_test_provider
| Logic | Notes |
|-------|-------|
| `speedTestFailed` flag + state field | add to instant_test_state |
| 15s anti-hammer cooldown (`_lastSpeedTestAttempt`, `speedTestCooldownRemaining`) | port verbatim |
| force-speed-test on explicit re-runs | wire USP re-run/refresh buttons with forceSpeedTest:true |
| `deauthClient(mac)` | USP uses TR-181/USP transport — NEEDS USP-specific impl, NOT JNAP copy |
| `optimizeChannels()` | **OPEN: does USP firmware expose StartAutoChannelSelection?** Likely a USP/TR-181 equivalent. Investigate before porting — may defer. |
| Link-rate Kbps→Mbps + Gbps format | USP DeviceUIModel.downlinkRate is bits/sec — different unit! Adapt the conversion. |

### D. Verdict logic — port to USP verdict.dart
| Change | Notes |
|--------|-------|
| speedTestFailed → warning finding | add param + finding (USP verdict has different structure) |
| Latency → Speed-check row warning | port to USP overview Test-details |
| Warning rows reflect findings | port to USP overview |
| Labeled device meta (Band/Signal/Link rate/Connected to) | adapt to DeviceUIModel fields |

### E. Branch-specific — DO NOT port / handle separately
| Change | Why |
|--------|-----|
| Delete dead instant_verify_view subtree | JNAP-only; USP never had it |
| I-6 card split + restore InstantVerifyView | JNAP-only; USP already separate |
| BUG-9 gateway http:// fix | USP browser_diagnostic_service may differ — verify if applicable |
| Wiki docs | shared doc, already current |

## Open questions before/within execution
1. **Does USP firmware expose `StartAutoChannelSelection`?** If not, channel
   optimization (I-7) needs a USP/TR-181 equivalent or defers. INVESTIGATE.
2. **`deauthClient` on USP** — different transport; needs USP-native impl.
3. **Link-rate units** — USP `downlinkRate` is bits/sec (JNAP txRate was Kbps).
   Conversion differs.
4. USP earlier session may have already done some UI bits — verify per-file
   before porting to avoid dupes.

## Suggested execution order (each step: edit → analyze → keep going; deploy needs USP firmware)
1. Provider/state: speedTestFailed + cooldown + force-on-rerun (self-contained)
2. Shared helpers: restart_helper, device_actions (+ deauthClient impl)
3. AppCard framing across tabs
4. Router header, refresh surfaces, labeled meta, triangle scrub, step counter
5. Verdict: speed-fail finding + warning rows
6. Channel optimization — only after Q1 resolved
7. Build against USP firmware to verify (router currently on JNAP fw)

## Deploy caveat
USP GUI needs USP firmware on the router. The M60 is currently on JNAP fw
(1.0.18). Porting + `flutter analyze` can be done now; live verification needs
a USP-firmware flash (or defer device-test to when USP fw is loaded).
