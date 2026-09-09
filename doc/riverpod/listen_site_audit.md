# `ref.listen` site audit

Issue: [#1502](https://github.com/linksys/PrivacyGUI/issues/1502). Measured on `feat/1502-listen-audit`,
branched from `dev-2.7.1` at `d484a23a`. riverpod 2.6.1.

Every `ref.listen` / `ref.listenManual` call site in `lib/` gets exactly one verdict, with the line that
justifies it. The question this document answers is **"does this side effect care whether the provider
notifies on an unchanged value?"** — which is a property of the code we ship today, not of any upgrade.

## Two axes, deliberately separate

The ticket asks one question but the sites answer two, and conflating them produces wrong verdicts:

| Axis | Question | Column |
| --- | --- | --- |
| Behaviour today | Does the body do real work it did not need to do? | **Verdict** |
| Version sensitivity | Would an `==`-based `updateShouldNotify` change the outcome? | **`==`-safe** |

A site can be a live defect and still be `==`-safe (the extra run is pure waste, so dropping it is the fix),
and a site can be clean today and still be `==`-fragile. Only the second axis is about riverpod 3.

## Structural lemma — why the async half is mostly settled before we start

`AsyncValue.operator ==` includes `isLoading` (`riverpod-2.6.1/lib/src/common.dart:286-294`). Re-running an
async provider that already holds a value does **not** emit `AsyncLoading`; via `copyWithPrevious` it emits
`AsyncData(isLoading: true, value: prev)` and then the new `AsyncData`. Measured:

```
AsyncData(hasValue=true, isLoading=false, v=1)   <- first completion
--- invalidate ---
AsyncData(hasValue=true, isLoading=true,  v=1)   <- re-run frame
AsyncData(hasValue=true, isLoading=false, v=1)   <- second completion
```

Three consequences used throughout the table:

1. **A refresh frame is never `==` to a settled frame.** So an async provider that refetches via
   `invalidate` / `invalidateSelf` / `refresh` always has an unequal frame between two completions. Only
   two consecutive *settled* equal frames can collapse under `==`.
2. **A predicate on `next` alone is not an edge-trigger.** `if (next.hasValue)`, `next.valueOrNull != null`
   and `if (next is AsyncData)` all pass on the refresh frame *and* the completion, so such a body runs
   **twice per refetch** — regardless of whether the payload changed. This is the dominant live defect in
   the population below, and it has nothing to do with equality.
3. **`ref.invalidateSelf()` coalesces; a direct call does not.** Measured on a downstream provider whose
   listener fires twice: 2 × `invalidateSelf()` ⇒ **1** rebuild, but 2 × `unawaited(fetch(forceRemote: true))`
   ⇒ **2** real USP round-trips. So consequence 2's magnitude depends on which of the two the body uses.

A bare `state = const AsyncLoading()` (no carried value, `hasValue` false) breaks the chain differently: a
`hasValue`-gated listener filters it out, so that producer delivers once, not twice.

## Population (AC-1 re-measurement)

`ref.listen(` + `ref.listenManual(` under `lib/`: **45** sites.

| Watched provider | Sites | Kind | 2.6.1 predicate | In scope |
| --- | --: | --- | --- | :--: |
| `sseInvalidationProvider` | 13 | `StreamProvider<InvalidationDomain>` | always-notify | no — #1501 Task B |
| `authProvider` | 5 | `AsyncNotifierProvider` | always-notify | **yes** |
| `appConnectionStateProvider` | 5 | `NotifierProvider<_, enum>` | `!identical` | no — enum, provably zero delta |
| `pnpProvider` | 5 | `NotifierProvider` | `!identical` | **yes** |
| `devicesDataProvider` | 3 | `AsyncNotifierProvider` | always-notify | **yes** |
| `wifiDataProvider` | 3 | `AsyncNotifierProvider` | always-notify | **yes** |
| `dashboardDomainReadyProvider` | 3 | `FutureProvider<void>` | always-notify | **yes** |
| `remoteClientProvider` | 2 | `NotifierProvider` | `!identical` | **yes** |
| `sseConnectionStateProvider` | 2 | `StreamProvider` | always-notify | no — audited in #1501 |
| `firewallDataProvider` | 1 | `AsyncNotifierProvider` | always-notify | **yes** |
| `firmwareBanksDataProvider` | 1 | `AsyncNotifierProvider` | always-notify | **yes** |
| `remoteAccessProvider` | 1 | `NotifierProvider` | `!identical` | **yes** |
| `sessionProvider` | 1 | `NotifierProvider` | `!identical` | **yes** |

45 − 13 − 2 − 5 = **25 in scope**.

**Drift from the ticket body (measured at `949dd560`): 44 → 45, in-scope 24 → 25.** The extra site is
`page/dashboard/providers/dashboard_edit_mode_provider.dart:95` (`authProvider`), which the ticket already
listed in its cost table ("Exists": `dashboard_edit_mode_provider_test`) but omitted from its scope table —
an internal inconsistency in the ticket, not a change in the code.

## The 25 sites

### `authProvider` — 5

| # | Site | Guard | Verdict | `==`-safe | Evidence |
| --: | --- | --- | --- | :--: | --- |
| 1 | `core/connection/providers/app_connection_state_provider.dart:64` | `if (next.isLoading) return;` | `idempotent` | yes | Both branches are state-guarded assignments: `:72` sets `loggedOut` when already logged out is a no-op, and `:73` only restores `authenticated` `else if (state == loggedOut)`. Timer cancels at `:68-71` are null-safe. |
| 2 | `page/dashboard/orchestrator/dashboard_orchestrator.dart:94` | `if (next.isLoading) return;` | `edge-triggered` | yes | `:97-98` compares `prev?.value?.loginType` to `next`'s; an equal repeat fails `prevLoginType != local && loginType == local`. |
| 3 | `page/dashboard/providers/dashboard_edit_mode_provider.dart:95` | none on the frame | `edge-triggered` | yes | The shadow variable **is** the edge: `:99-100` computes `wasLoggedIn && !loggedIn` then reassigns `wasLoggedIn`. The refresh frame carries the previous value, so it updates the latch without firing; the completion fires exactly once. |
| 4 | `page/login/views/login_local_view.dart:105` | `previous.isLoading` | `edge-triggered` | yes | `:106-109` requires the *previous* frame to be loading. On the refresh frame `previous` is settled ⇒ no fire; on the completion `previous` is the refresh frame ⇒ one fire. |
| 5 | `route/router_provider.dart:180` | `if (next.isLoading) return;` | `edge-triggered` | yes | `:184` `if (prevType != nextType)`; an equal repeat cannot pass. |

Note on 1, 2 and 5: `if (next.isLoading) return;` is what makes the async refresh frame harmless here. It is
the correct spelling of the guard that consequence 2 above says `next.hasValue` is not.

### `devicesDataProvider` — 3

`devicesDataProvider` is the only in-scope async producer that **assigns state directly** rather than
invalidating (`:145`, `:235`, `:296`; the SSE path at `:119` debounces 500 ms at `:241-248` into
`_refetchPreservingMesh()` → `:296`). It emits **no** refresh frame, so its listeners get one delivery per
update — and two
consecutive settled deliveries can be `==`. These are the only genuinely equality-exposed sites in the
population.

| # | Site | Guard | Verdict | `==`-safe | Evidence |
| --: | --- | --- | --- | :--: | --- |
| 6 | `page/_shared/providers/usp_device_analytics_notifier.dart:33` | `next.valueOrNull == null` only | **`redundant-today`** | yes | On an unchanged device list within the same clock hour, `_onDashboardUpdated` rewrites the current hourly bucket with identical values and still persists at `:188`. **Cost: one redundant storage write, but only for two identical emissions inside the same hour.** Narrower than it looks, and **not fixable by a payload diff** — see the note below. |
| 7 | `page/local_network/providers/dhcp_data_provider.dart:58` | prev/next diff | `edge-triggered` | yes | `:60-67` builds `mac → isActive` maps for both frames and only calls `_debouncedInvalidate()` when `MapEquality` says they differ. **This is the in-repo template for fixing #6 and #8.** |
| 8 | `page/local_network/providers/ethernet_data_provider.dart:55` | `next.hasValue && state.hasValue` | **`redundant-today`** | yes | `ref.invalidateSelf()` on any devices emission, unchanged or not. `_fetch()` passes exactly `clientDevices` to the service, so an identical list cannot change the result *for that reason*, and other causes arrive via the SSE listener at `:47`. **Cost: one redundant Ethernet USP fetch per unrelated device update** — and `DevicesData` changes on any device field (RSSI, band, SSID), so unrelated updates are the common case. **Fixed here**, comparing against the input the last `_fetch()` consumed rather than against `prev`; the `state.hasValue` half of this guard was also dropping settles that raced the fetch — see "The one caveat on the zero" above. |

### `wifiDataProvider` — 3

`wifiDataProvider` refetches via a 500 ms debounced `ref.invalidateSelf()`
(`wifi_settings/providers/wifi_data_provider.dart:109-114`), so it **does** emit a refresh frame ⇒
consequence 2 applies to all three listeners: each runs twice per refetch.

| # | Site | Guard | Verdict | `==`-safe | Evidence |
| --: | --- | --- | --- | :--: | --- |
| 9 | `page/devices/providers/devices_data_provider.dart:124` | `next.valueOrNull == null` only | **`redundant-today`** | yes | `:125-127` gates on `next` alone, so the mesh rebuild at `:136-143` and the `state = AsyncData(...)` at `:145` run on **both** frames — twice per wifi refetch, and the extra emission is itself broadcast to devicesData's own 3 listeners (#6–#8). The amplifier of the population. |
| 10 | `page/wifi_settings/providers/usp_wifi_advanced_provider.dart:44` | `if (next.hasValue)` | **`redundant-today`** | yes | `:45 onSseInvalidation()` → `framework/preservable_notifier_mixin.dart:106-112` → `unawaited(fetch(forceRemote: true))`. A **direct call**, so consequence 3 gives no coalescing: **2 USP round-trips per wifi refetch**, while the page is open (L2 is autoDispose). |
| 11 | `page/wifi_settings/providers/usp_wifi_settings_provider.dart:50` | `if (next.hasValue)` | **`redundant-today`** | yes | Identical shape to #10, same cost. |

### `firewallDataProvider` — 1

| # | Site | Guard | Verdict | `==`-safe | Evidence |
| --: | --- | --- | --- | :--: | --- |
| 12 | `page/firewall/providers/usp_firewall_notifier.dart:44` | `if (next.hasValue)` | **`redundant-today`** | yes | Same shape as #10/#11; `firewall/providers/firewall_data_provider.dart:137-142` also refetches via a debounced `invalidateSelf()` ⇒ refresh frame present ⇒ **2 USP round-trips per firewall refetch** while the page is open. |

### `firmwareBanksDataProvider` — 1

| # | Site | Guard | Verdict | `==`-safe | Evidence |
| --: | --- | --- | --- | :--: | --- |
| 13 | `page/admin/providers/system_info_data_provider.dart:38` | `next.hasValue && state.hasValue` | **`redundant-today`** | yes | `:40 ref.invalidateSelf()`. No doubling here: `firmware_update/providers/firmware_banks_data_provider.dart:51` sets a **bare** `const AsyncLoading()` (`hasValue` false), which the guard filters ⇒ one delivery per refresh. The redundancy is reachability-driven: `firmware_update/providers/firmware_update_notifier.dart:332-356` calls `banks.refresh()` up to 3× (3 s apart), breaking only at `:341 if (banksData.banks.isNotEmpty)`, so a still-empty result triggers **up to 3 systemInfo USP fetches, 2 of them on unchanged banks**. **Not fixable by a payload diff** — see the note below. |

### `dashboardDomainReadyProvider` — 3

Pre-measured in #1503 and re-confirmed here.

| # | Site | Guard | Verdict | `==`-safe | Evidence |
| --: | --- | --- | --- | :--: | --- |
| 14 | `page/_shared/providers/usp_system_monitor_notifier.dart:43` | `if (next is AsyncData)` | **`redundant-today`** | yes | Passes on both frames ⇒ `_startTimerIfAuthenticated` → `setRefreshInterval` (`:78`) → `_fetchAndAppend()` unconditionally at `:87`. `isFetching` is written at `:102` but never read as a guard. **Cost: 1 redundant USP round-trip per invalidate.** Not a timer leak — `setRefreshInterval` cancels first at `:79-80`. |
| 15 | `page/_shared/providers/usp_traffic_analysis_notifier.dart:44` | `if (next is AsyncData)` | **`redundant-today`** | yes | Same shape: `setRefreshInterval` at `:72`, unconditional `_fetchAndAppend()` at `:81`. The rate maths cannot divide by zero (`elapsed <= 0` short-circuits at `:113`), but the extra sample is computed over the inter-frame gap rather than the 10 s cadence. |
| 16 | `page/remote_assistance/views/remote_assistance_session_guard.dart:42` | `prev?.isLoading == true && !_checkDone` | `edge-triggered` | yes | Reads `prev` **and** holds a one-shot latch set at `:44`, so the second delivery is a no-op even if the predicate matched. |

### `pnpProvider` — 5

All five listen from inside a view's `build()`. Every unguarded branch is `context.go(<fixed path>)` that
navigates **away from the page owning the listener**, so the widget unmounts and the listener is disposed
before a repeat can be observed; and a duplicate `go` to the location already current is a same-location
replace, not a push.

| # | Site | Verdict | `==`-safe | Evidence |
| --: | --- | --- | :--: | --- |
| 17 | `page/instant_setup/views/pnp_entry_view.dart:33` | `idempotent` | yes | `:39-41` is prev-guarded; the unguarded `:44` is `context.go(pnpNoInternetConnection)`, which unmounts this view. |
| 18 | `page/instant_setup/views/pnp_no_internet_view.dart:53` | `idempotent` | yes | Both branches (`:55`, `:60`) are `context.go(RoutePath.pnp)`. |
| 19 | `page/instant_setup/views/pnp_pppoe_view.dart:58` | `idempotent` | yes | `:60`/`:65` are `context.go(RoutePath.pnp)`; the snackbar branch at `:66-69` is prev-guarded on `IspSaving`. |
| 20 | `page/instant_setup/views/pnp_static_ip_view.dart:64` | `idempotent` | yes | Identical shape to #19 (`:66`, `:71`, `:72-75`). |
| 21 | `page/instant_setup/views/pnp_waiting_modem_view.dart:27` | `idempotent` | yes | `:29` is `context.go(RoutePath.pnp)`; `:30` is prev-guarded on `NoInternet`. |

Producer note, corrected during this audit: a consecutive-equal `PnpState` **is** reachable in production —
`retryInternetCheck()` (`pnp_notifier.dart:404`) assigns `const AdminCheckingInternet()`, so a double-tap on
"try again" can emit the same state twice. An earlier draft of this audit claimed only `setDemoPhase`
(`:530`, called solely from `lib/demo/pages/pnp_demo_launcher.dart`) could do it. The verdicts do not change
— the argument rests on the effect being a same-location `go` on an unmounted listener, not on the emission
being unreachable — but "unreachable" was the wrong reason and is not load-bearing.

### `remoteClientProvider` / `remoteAccessProvider` / `sessionProvider` — 4

| # | Site | Verdict | `==`-safe | Evidence |
| --: | --- | --- | :--: | --- |
| 22 | `page/remote_assistance/views/remote_assistance_dialog.dart:87` | `edge-triggered` | yes | `:92-93` requires `prevStatus == active && nextStatus == invalid`; an equal repeat has `prevStatus == nextStatus`, so the predicate is false by construction. |
| 23 | `page/remote_assistance/views/remote_assistance_dialog.dart:714` | `edge-triggered` | yes | `:719-721` requires `prevStatus != null && prevStatus != invalid && nextStatus == invalid`; same argument. Closes the dialog at `:723+`. |
| 24 | `page/_shared/components/remote_session_chip.dart:69` | `edge-triggered` | yes | `:74-76`, same transition shape. |
| 25 | `core/pwa/pwa_install_service.dart:111` | `edge-triggered` | yes | `:112 if (prev?.modelNumber == next.modelNumber) return;` — an explicit equal-value early return. |

## Verdict split

| Verdict | Count | Sites |
| --- | --: | --- |
| `edge-triggered` | 10 | 2, 3, 4, 5, 7, 16, 22, 23, 24, 25 |
| `redundant-today` | 9 | 6, 8, 9, 10, 11, 12, 13, 14, 15 |
| `idempotent` | 6 | 1, 17, 18, 19, 20, 21 |
| **`depends-on-re-notify`** | **0** | — (but see the caveat below: site 8 was 1, via a *recovery* path) |

**`==`-safe: 25 / 25.** No in-scope site loses required behaviour under an `==`-based
`updateShouldNotify`. Outside the 13 `sseInvalidationProvider` sites (#1501 Task B), the listener population
does not block the riverpod 3 `updateShouldNotify` unification.

### The one caveat on the zero, found by measurement after the first draft

The count above is for each listener's **normal** path: no body needs to run again for an unchanged payload to
produce its intended effect. That is the question the verdict axis asks, and it is the right question — but it
is not the only way a listener can depend on re-notification. A listener can also depend on it to **recover
from an event it dropped**, and site 8 did:

`ethernet_data_provider`'s listener guarded on `!state.hasValue`, so a `devicesDataProvider` settle arriving
while Ethernet's own `_fetch()` was still in flight was discarded — and the fetch it would have corrected had
already read devicesData as `AsyncLoading` and passed `deviceModels: []`. On 2.6.1 that healed itself: the
next redundant `devicesData` emission re-invalidated and the second fetch consumed the real list. Measured on
the base source with the settle deliberately raced against the fetch:

| source | after build | after one redundant same-payload repeat |
| --- | --- | --- |
| base `d484a23a` | `consumed=[0]` (stale) | `consumed=[0, 1]` — **rescued by the repeat** |
| first fix (`prev` diff + `?? const []`) | `consumed=[0]` | `consumed=[0]` — rescue suppressed |
| shipped fix (consumed-input diff) | `consumed=[0, 1]` | `consumed=[0, 1]` — corrected at once, then quiet |

So the recovery path was real, it was invisible to a verdict axis that only asks about the normal path, and
**riverpod 3 would have removed it** — the rescue rode on precisely the redundant `data → data` notification
the `==` unification deletes. The first fix deleted it early and locally, which is how it surfaced at all.
This is the one place where the audit's headline result needed a correction rather than a footnote, and it is
why site 8 compares against the input the last `_fetch()` actually consumed rather than against the previous
notification: a listener that never loses an event has no recovery path to depend on.

Two consequences for the ticket's own acceptance criteria:

- **AC-3 has no work.** It demands a characterization test per `depends-on-re-notify` site and there are
  none *as shipped*. The one recovery-path dependency found (site 8, above) is **removed** here rather than
  characterized, which satisfies AC-3's intent more directly than a test pinning it would. The ticket's cost
  estimate of 13 missing test files — 8 of them widget-test harnesses — is therefore **not incurred**,
  exactly as its own "conditional on the verdicts" note anticipated.
- **AC-4 has 9 sites**, all of which are live waste on 2.6.1 rather than migration risk.

## The 9 `redundant-today` sites share two root causes, not nine

**Cause A — a predicate on `next` alone (6 sites: 9, 10, 11, 12, 14, 15).** The body treats the refresh
frame as a completion and runs twice per upstream refetch. Fix is one line per site: filter the refresh
frame, the way sites 1/2/5 already do.

```dart
ref.listen(wifiDataProvider, (_, next) {
  if (next.isLoading) return;      // <- the refresh frame carries a value; hasValue does not exclude it
  if (next.hasValue) onSseInvalidation();
});
```

Measured cost removed: 2 USP round-trips → 1 at sites 10, 11, 12 (direct `fetch(forceRemote: true)`, no
coalescing), 1 redundant round-trip each at 14 and 15, and one duplicate mesh rebuild + state emission at 9
(which is also 3 duplicate downstream deliveries).

**Cause B — no payload comparison (3 sites: 6, 8, 13).** The effect fires on an unchanged payload because
nothing compares it. The projection to compare is **not a design choice** — it is the exact value the
consumer already reads:

| Site | What the consumer actually consumes | Projection |
| --- | --- | --- |
| 8 `ethernet_data_provider:55` | `:67` `devicesData?.clientDevices` → `svc.fetch(deviceModels:)` at `:76` | `clientDevices` |
| 6 `usp_device_analytics_notifier:33` | `:43` `_onDashboardUpdated(data.clientDevices)` | `clientDevices` |
| 13 `system_info_data_provider:38` | `:53` `svc.fetch(firmwareBanks: banksData?.banks)` | `banks` |

All three projection types have value equality (`ClientDevice extends NetworkEntity with EquatableMixin`
with `props` at `client_device.dart:334`; `FirmwareImageUIModel extends Equatable`), and
`dhcp_data_provider.dart:58-69` is the in-repo template.

**But a diff is only sound where skipping the refetch loses nothing, and measurement says that holds for
exactly one of the three.** Both of the following were prescribed in a draft of this document and are wrong:

- **Site 6 — `_onDashboardUpdated` is not a pure function of its argument.** It reads `DateTime.now()` at
  `:138` and *appends a new hourly bucket* when the hour has rolled over
  (`:151 if (history.isNotEmpty && history.last.hour == currentHour)`). An identical device list at a later
  time therefore produces a *different* result, and a `clientDevices` diff would leave gaps in the 24 h
  history — the provider is not autoDispose, so the gap persists for the session. The genuine waste is
  narrower than first measured: only two identical emissions **inside the same hour**, costing one
  storage write. **Filed as #1504, not fixed** — a sound guard has to compare the hour bucket as well as the
  list, which is a behaviour decision about the analytics history rather than a guard.
- **Site 13 — `systemInfoDataProvider` has exactly one refresh trigger in the entire app, and it is this
  listener.** Nothing else invalidates or refreshes it (`rg 'systemInfoDataProvider' lib/` returns no
  `invalidate`/`refresh`/`.notifier` call), and `firmwareBanksDataProvider` in turn has exactly one
  refresher (`firmware_update_notifier.dart:338`). Meanwhile `_fetch()` gets SystemInfo **live from USP**
  and merely passes `banks` through. So on a same-version reflash — banks identical, `softwareVersion`
  and `uptime` changed — a `banks` diff would suppress the app's only systemInfo refresh for the rest of
  the session. **Filed as #1505, not fixed**; decoupling systemInfo from banks is a design change, not a
  guard.

## AC-4 outcome

| | Sites | Action |
| --- | --- | --- |
| Cause A, `isLoading` guard | 9, 10, 11, 12, 14, 15 | **Fixed in this PR** — provably lossless: the dropped frame carries the *previous* value, so the body was acting on stale data. |
| Cause B, sound diff | 8 | **Fixed in this PR** — projection is `_fetch()`'s own input; other causes covered by the sibling SSE listener at `:47`, the same bet `dhcp_data_provider:58` already ships. The diff is against the *consumed* input, not `prev`, which also closes the dropped-settle half of the old guard. |
| Cause B, unsound diff | 6, 13 | **Filed** — #1504 (site 6), #1505 (site 13), each with the measured cost and the reason above. |

7 fixed, 2 filed. AC-4 requires every `redundant-today` site to be one or the other, and none left
undocumented.

## Test coverage for the 7 fixes

The 282-test affected set passed **identically before and after** the fixes, so it could not see the
behaviour change at all. Each fix therefore got a test, and each test was run against the pre-fix source to
confirm it is red there — a test that is green both ways is not coverage.

| Site | Test | Instrument | Pre-fix | Post-fix |
| --- | --- | --- | --- | --- |
| 8 ethernet | `ethernet_data_provider_test.dart` | `verifyNever(svc.fetch)` after an equal-valued emission | fetch runs | no fetch |
| 8 ethernet (boot) | `ethernet_data_provider_test.dart` | `svc.fetch` count when the device list settles empty after this provider already holds data | 2 | 1 |
| 8 ethernet (mid-fetch) | `ethernet_data_provider_test.dart` | consumed `deviceModels` lengths when the device list settles *during* this provider's own fetch | `[0]` | `[0, 1]` |
| 9 devices | `devices_data_provider_test.dart` | `svc.rebuildWithWifiData()` count | 2 | 1 |
| 10 wifi advanced | `usp_wifi_advanced_notifier_test.dart` | `svc.fetchIeee80211h()` count | 2 | 1 |
| 11 wifi settings | `usp_wifi_settings_notifier_test.dart` | `svc.buildWifiNetworks()` count | 2 | 1 |
| 12 firewall | `usp_firewall_notifier_test.dart` | `performFetch(forceRemote:)` count, counting subclass | 2 | 1 |
| 14 system monitor | `usp_system_monitor_notifier_test.dart` | `svc.fetchSnapshot()` count | 2 | 1 |
| 15 traffic analysis | `usp_traffic_analysis_notifier_test.dart` | `svc.fetchBaselines()` count | 2 | 1 |

The site numbers in this table were transposed in the first version (rows read 9 wifi advanced / 10 wifi
settings / 11 firewall / 12 devices, one off against the verdict table above); the test↔fix pairing was
always right. Two of the eleven new tests are deliberately **not** red pre-fix and are labelled as such below:
`re-fetches when clientDevices changes` and `a boot settle that adds clients does re-fetch` assert re-fetches
the unguarded version also performed. They are controls that keep the two guarded assertions from passing
vacuously, not coverage.

Five things this exercise established that the audit alone had not:

1. **The committed site-8 fix was inert.** It read
   `prev?.valueOrNull?.clientDevices == next.value!.clientDevices`. `clientDevices` is a plain `List` built
   fresh by `MeshNetwork.allClients`, so `==` is *reference* equality and never true — the guard always fell
   through. `DevicesData` itself is `Equatable` and compares deeply, which is what made the mistake easy to
   miss: the enclosing type has value semantics, the getter's return type does not. Now
   `ListEquality<ClientDevice>().equals(...)`, matching `dhcp_data_provider:58`'s `MapEquality`. Only the test
   caught this; the audit, the review checklist, `analyze` and 282 existing tests all passed it.
2. **`invalidateSelf()` is lazy without listeners.** A provider with no active subscription is only marked
   dirty; the rebuild waits for the next read. The first version of the site-8 test used `container.read(...
   .future)` alone and so passed against the *unguarded* source too. Every one of these tests needs a
   standing `container.listen(...)` to make invalidation eager. This is a trap for anyone writing a
   "should not re-fetch" test in this repo.
3. **Sites 9–11 already fetch twice at boot**, independently of this bug: the data provider's first
   `loading → data` settle is itself a listener firing, so `build()`'s own `fetch()` is followed by an
   `onSseInvalidation()` → `fetch(forceRemote: true)`. The `isLoading` guard does not address that (the first
   settle has no previous value to carry, so it is not a refresh frame) and it is out of scope here, but it
   is the reason these tests measure a *delta* rather than an absolute count.
4. **One existing test had already noticed the doubling and worked around it.**
   `usp_wifi_advanced_notifier_test.dart:70-73` reads
   `verify(...).called(greaterThanOrEqualTo(1))` under the comment "may be called again if SSE listener
   triggers". The loose matcher turned a defect into an accepted range.
5. **Diff against the input the effect consumed, not against `prev`.** `prev` is the listener's *notification*
   history, and the two are not the same thing whenever the effect can start before the input settles — which
   at site 8 is the normal dashboard boot, because the orchestrator reads `devicesDataProvider` and
   `ethernetDataProvider` back to back (`dashboard_orchestrator.dart:158-159`) and the two settle in a race.
   Comparing against `prev` was wrong in **both** branches of that race, and each way needed a different
   argument to see:
   - *Ethernet wins.* Its `_fetch()` read devices as `AsyncLoading` and passed `deviceModels: []`. At the
     settle `prev` carries no value, and `ListEquality.equals(null, [...])` is `false` (collection
     `equality.dart`: `if (list1 == null || list2 == null) return false`), so an **empty** device list looked
     like a change: one wasted Ethernet round-trip on every boot of a home with no wired clients. Measured
     `fetches=2 deviceModelCounts=[0, 0]` → `1`.
   - *Devices wins.* The settle lands while Ethernet's own `_fetch()` is still in flight, `!state.hasValue`
     discards it, and the fetch it would have corrected already consumed `[]`. Measured
     `consumed=[0]` — Ethernet serves port models built from an empty device list. On 2.6.1 this healed on
     the next redundant emission; a `prev`-based diff, and later riverpod 3, delete that rescue. See "The one
     caveat on the zero" above, which is the more important half of this finding.

   One field holding the consumed input answers both, and removes the need to decide what "no previous value"
   means: it *starts* as the empty list the first fetch really does consume, and it is written before the
   await, so a settle arriving mid-fetch compares against the right thing. Measured after the fix:
   `consumed=[0, 1]` for the mid-fetch race, `1` fetch for the empty settle, and the paired control (list
   settles non-empty, no race) still `[0], [1]` — so nothing needed is suppressed.

## Method

- Enumeration: `rg -n 'ref\.listen(Manual)?\('` under `lib/`, grouped by watched provider, then every body
  read in full. Counting `ref.listen(` alone misses the 4 `listenManual` sites.
- Every verdict cites a line that was re-read at `d484a23a` for this document; none is carried over from
  the ticket body unverified.
- The three riverpod mechanics in "Structural lemma" were measured with a throwaway probe against
  riverpod 2.6.1 (frame sequence, `hasValue`/`valueOrNull` double-fire counts, `invalidateSelf` coalescing
  vs. direct-call non-coalescing). The probe was deleted; the frame sequence itself is permanently pinned by
  `test/page/dashboard/providers/dashboard_domain_ready_provider_test.dart` (#1503).
- For every `redundant-today` candidate the **producer** was checked as well as the listener: whether it
  refetches via `invalidateSelf` (coalescing, refresh frame) or by direct assignment (no frame), and whether
  an equal emission is reachable at all.
- For every proposed *fix*, the consumer was checked for hidden inputs (a clock, accumulated state) and the
  provider for alternative refresh triggers. This is what killed two prescriptions that had already been
  written down (sites 6 and 13) and it is the step worth repeating: "the effect is a function of the
  payload" is an assumption, not an observation.

- Every fix was then given a test that was **run against the pre-fix source** and confirmed red there. This
  is what caught the inert site-8 guard, which every other check had passed.

Five draft claims were wrong and are recorded above rather than quietly corrected: the pnp reachability
argument, an "8 → 2 Ethernet fetches" figure that coalescing reduces to 1, the two payload-diff
prescriptions, and the first shipped version of the site-8 diff (`==` on a `List`). A sixth is a ticket-body
drift, not mine: the ticket lists
`usp_wifi_advanced_provider_test` / `usp_wifi_settings_provider_test` as missing, but both exist as
`test/page/wifi_settings/providers/usp_wifi_{advanced,settings}_notifier_test.dart`.

## Verification

- `./run_tests.sh` → **6524/6524 pass, exit 0** (6513 baseline + the 11 new tests)
- Affected set (23 files: direct tests for the 8 changed sources plus every `*_test.dart` importing them) →
  **293/293 pass** (282 before the new tests)
- Each new test also run against the pre-fix source: **9 of the 11 red there**; the other two are the labelled
  controls, listed in "Test coverage" above. The mid-fetch test was additionally run against the *first* fix
  (`prev` diff + `?? const []`) and is red there too — that is the regression it exists to prevent
- `fvm flutter analyze` → **480 issues, identical to the `d484a23a` baseline**; **0** attributable to any of
  the changed files. (Analyze reports 810 with 330 errors in a fresh worktree until `flutter pub get`
  generates `l10n/gen/app_localizations.dart` — that is an environment artefact, not a finding.)
- `fvm dart format --set-exit-if-changed` on all changed files → clean
- Flutter 3.47.2 per `.fvmrc`
