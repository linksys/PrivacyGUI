# Instant-Test — Next Steps (as of 2026-06-10)

> Clear handoff of what's done, what's outstanding, and the test/validation state
> after the big 2026-06-09/10 session. Start here next session.

## Where things stand
Both lines are at **feature parity** for the customer Instant-Test tool and fully
pushed to `linksys/PrivacyGUI`:
- **JNAP** `feature/Instant-Troubleshooting` — improvement queue I-1…I-8 + all
  device-testing bug fixes. Deployed live to the M60 (bundle md5 matches HEAD).
- **USP** `feature/instant-test-usp` — 6-commit port to parity (speed-fail+cooldown,
  AppCard framing, router header, step/triangle/Gbps fixes, warning rows, +6 tests).

## Validation state (verified 2026-06-10)
| | JNAP | USP |
|---|---|---|
| `flutter analyze` | ✅ 0 errors | ✅ 0 errors |
| Full web build | ✅ compiles | ✅ compiles |
| Logic/model/provider tests | ✅ pass | ✅ 229 pass (incl. 6 new) |
| Deployed = HEAD | ✅ md5 match | n/a (needs USP fw) |

## Outstanding work (priority order)

### 1. Deferred USP transport actions (need investigation, NOT a JNAP copy)
USP uses TR-181/USP transport, so these can't be copied from JNAP:
- **`deauthClient`** (force-reconnect a device) — USP provider lacks it. Find the
  USP/TR-369 equivalent of JNAP `clientDeauth`.
- **`optimizeChannels`** (channel optimization, I-7) — find the USP equivalent of
  JNAP `StartAutoChannelSelection` + `GetSelectedChannels`. JNAP impl is in
  `instant_verify_pivot_provider.optimizeChannels()` as the reference.
Until done, USP's force-reconnect + channel-optimize buttons have no backing action.

### 2. Pre-existing test failures (NOT from this session — verified at base commits)
- **USP view tests (~11):** `Null check operator` building the tabs — fail
  identically at pre-session base `79f8fd3c`. Likely missing theme/CustomTheme/
  localization ancestor in the widget-test harness setup.
- **JNAP view tests (5):** loading-state copy ×3 ("Checking your connection",
  "Checking..." chip, check rows) + Flow-5 back-nav ×2 — fail at pre-session base
  `765fad17`. Same harness-setup class of issue.
- Both are one task: fix the view-test harness (provide the missing ancestors).
- NOTE: the "243 tests passing" claim in older notes was inaccurate for the VIEW
  layer; model/provider/system tests are genuinely green on both lines.

### 3. Shared diagnostic core extraction (the big strategic investment)
This session hand-ported ~6 changes twice (JNAP→USP) — that's the duplication tax
the [[concepts/two-line-strategy]] doc predicted. NOW is the right time to extract,
because both lines are at a clean parity baseline. Plan: a separate git repo
consumed as a versioned `git:` dependency (USP's native pattern). Sequence:
extract from this parity state → both lines pin a `ref:` → stop double-porting.
Make it its own focused project (new repo, NormalizedDiagnosticModel, adapters, CI).

### 4. USP device testing
USP GUI needs USP firmware; the M60 is on JNAP fw (1.0.18). Either flash a unit to
USP fw, or test on whatever hardware already runs it. All USP work is analyze-clean
+ unit-tested but not yet device-verified.

## Test cases written this session
- USP `verdict_test.dart`: speedTestFailed → "couldn't finish the speed test"
  warning (×3: fires when up, absent when false, suppressed when WAN down).
- USP `flow_step_transitions_test.dart`: round-trip + equality for speedTestFailed,
  routerModel, routerSerial (×3).
- JNAP view-test assertions updated to match new UX (restart/deauth/channel dialogs,
  test-scenarios gate).

## Key references
- Roadmap (done/bugs): [[roadmap]]
- Linkage map (shared-code seams): [[feature-linkage-map]]
- Two-line strategy: [[concepts/two-line-strategy]]
- USP port classification: [[usp-port-plan]]
