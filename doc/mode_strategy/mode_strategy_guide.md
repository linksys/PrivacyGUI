### **Developer Guide: How to Use the Mode Strategy Framework**

#### **1. What is it? Why use it?**

The app ships in more than one mode. A **local** build is served by the router it configures; a **Remote Assistance** build is a support agent, somewhere else, reaching that router through the Guardian proxy on a token minted for one session; a **cloud** build logs in through Linksys cloud; and `lib/demo/` is a fourth entry point with mock data.

Before phase 3, "which mode is this?" was asked **15 separate times** across `lib/`, all resolving to one mutable static, `BuildConfig.forceCommandType`. Each site answered the question for itself, and each had a perfectly sensible `else`. That has two consequences worth stating plainly, because they are what the framework buys back:

1. **A third mode is mis-answered silently.** A bool has two branches. Adding a mode means every one of those 15 sites now has an `else` that is wrong, and none of them fail — they take the local path and keep working, for the wrong mode.
2. **The two answers can disagree.** Phase 1 of the epic fixed a live instance: a `?session=` URL in a local build registered a Guardian-proxied `UspClient` while `BuildConfig.isRemote()` still read `false`, so `sse_providers.dart` built a bridge with **on-router endpoint paths and no bearer token, aimed at the Guardian host**. Every request was well formed and went nowhere useful. "Is this RA?" had two different answers inside one session.

**The ledger, measured at the phase-2 tip.** #1474's own published figure is 12; re-measured, that grep counted one comment line and none of the `isRemote()` sites. The live count is 15, and it is worth having the breakdown because it is also the remaining-work list:

| Where | Shape | Count | Owner |
| --- | --- | --- | --- |
| `lib/page/` + `lib/components/` | `GlobalConfig.remote.isActive` | 7 | #1497 (phase 7) |
| `lib/route/router_provider.dart` | 1 `isActive` + 3 `isRemote()` | 4 | phase 9 |
| `lib/core/usp/providers/sse_providers.dart` | `isActive` | 3 | **phase 3 — folded in, 2 removed, 1 left on purpose (§6)** |
| `lib/di.dart` | `isRemote()` | 1 | phase 9 |

Phase 3 therefore leaves **13**, and the 7 in the UI layer are the single largest remaining block. Do not quote 15 or 13 in a later phase without re-running the grep — that is the whole reason this table names its measurement point.

The framework replaces those questions with **five causes**, each a contract with exactly one Local and one Remote implementation, composed by **two exhaustive `switch`es** over `AppMode`.

| Cause | Contract | The question it answers |
| --- | --- | --- |
| 1 | `TransportStrategy` | How do bytes reach the router? |
| 2 | `CredentialStrategy` | Who holds the credential, and what does expiry mean? |
| 3 | `SessionStrategy` | What does "the session ended" mean? |
| 4 | `ProximityStrategy` | Is the operator standing next to the router? |
| 5 | `SurfaceStrategy` | Which surfaces does this mode have a concept for? |

The gain is not tidiness, it is that **a new `AppMode` becomes a compile error** in exactly two files instead of a silent behaviour change in every remaining site. And a remote-mode test becomes one line — `appModeProfileProvider.overrideWithValue(const RemoteModeProfile())` — with no static mutated and no `tearDown` to forget.

**Causes, not capabilities.** The framework deliberately has no per-mode flag table, and that is measured rather than stylistic. Phase 8 deleted three such flags from `GlobalConfig.remote` — `allowDashboardEdit`, `allowConfigChanges`, `showAdvancedSettings` — each well named, documented, centralised, and **read by nothing**. One duplicated a gate that was already live; one was the wrong shape (it said "no writes in RA", while reboot and cloud OTA must stay allowed); one hid a surface RA actually needs. An unread bool cannot be seen to be wrong. A cause can: "can the operator physically recover from this?" has one right answer per mode, derivable, and a strategy that gets it wrong fails a test.

#### **2. Where the pieces live**

```
lib/framework/mode/          # contracts ONLY — no if, no impl
  transport_strategy.dart
  credential_strategy.dart
  session_strategy.dart
  proximity_strategy.dart
  surface_strategy.dart
  bridge_config.dart         # a contract's return type, not an implementation

lib/core/mode/
  app_mode.dart              # enum AppMode + resolve() + appModeProvider
  app_mode_profile.dart      # abstract AppModeProfile + THE core composition root
  local_mode_profile.dart    # + .aliasedAs() for cloud and demo
  remote_mode_profile.dart
  impl/
    {local,remote}_transport_strategy.dart
    {local,remote}_credential_strategy.dart
    {local,remote}_session_strategy.dart
    {local,remote}_proximity_strategy.dart

lib/page/_shared/mode/
  surface_strategy_provider.dart   # THE page composition root
  {local,remote}_surface.dart
```

**Rule 3 in one sentence: the contract lives in `lib/framework/mode/`, the implementation lives at the layer it talks to.** Transport, credentials, session and proximity talk to `lib/core/` things, so they live in `lib/core/mode/impl/`. `SurfaceStrategy`'s implementations talk to page state, so they live under `lib/page/`.

Rule 3 has a second half that is easy to drop: **the framework imports neither implementation directory.** `BridgeConfig` is why this needs saying. It is a value type, not a strategy, and it was first filed under `impl/` next to the two classes that build it — which made `transport_strategy.dart` import `lib/core/mode/impl/`, i.e. made the contract depend on the directory the rule exists to keep it independent of. It is a *return type of the contract*, so it belongs with the contract. The test for the next one like it: if the framework has to import it to state a signature, it cannot live in `impl/`.

The `SurfaceStrategy` placement has a consequence: **`AppModeProfile` has no `surface` member.** CLAUDE.md forbids `lib/core/` → `lib/page/`, and a `surface` getter on a core profile would be exactly that dependency. So cause 5 gets its own composition root — a second exhaustive `switch` over the same `AppMode`. Two roots is the intended shape; constitution Article XVII Rule 2 names both, and `test/core/mode/composition_root_test.dart` guards both so a third cannot appear unnoticed.

**The page root reads `appModeProfileProvider.mode`, not `appModeProvider`,** and the difference is not cosmetic. Reading the raw provider in both roots is the obvious symmetry and it quietly costs you acceptance 3: one `appModeProfileProvider.overrideWithValue(const RemoteModeProfile())` is supposed to put the *whole* stack in remote, and a page root on `appModeProvider` opts cause 5 out — the four core causes move, the surfaces stay local, and every transport assertion still passes. Phase 3 shipped it the wrong way round first; nothing caught it until a test read `surfaceStrategyProvider` under a profile-only override. Going through the profile keeps both levers live, since the profile is itself derived from `appModeProvider`.

**A note on the design doc.** #1474's §5 file tree puts the `SessionStrategy` implementations under `lib/page/_shared/mode/`, annotated "(they navigate — cause 3)". That contradicts its own §4.2, which gives the signature `Future<SessionOutcome> end(Ref, EndCause)` and says explicitly that it does *not* navigate. Phase 3 resolved it in favour of §4.2: the implementations live in `lib/core/mode/impl/` with the other core causes, and returning an outcome rather than navigating is precisely what makes that placement legal. Phase 5 (#1323) fills the member in; if it decides the strategy must navigate after all, the class moves to `lib/page/` **and** cause 3 needs its own root like cause 5.

#### **3. How to use it: adding mode-dependent behaviour**

**Step 0 — check that it is actually mode-dependent.** Most things are not. If both modes do the same thing, no strategy is involved.

**Step 1 — name the cause, not the mode.** Ask *why* the two modes differ. "Remote can't do a factory reset" is a mode fact; "the operator is not in the building, so an operation that destroys the credential ends the session with no way back" is a cause, and it is cause 4. If you cannot state the why, you are about to write a capability flag.

**Step 2 — add a member to that cause's contract in `lib/framework/mode/`.** One member, with a doc comment saying what differs and why. Do not add a new contract unless the cause is genuinely new — `test/core/mode/mode_contract_roster_test.dart` counts the roster at six for that reason.

**The six are the five causes plus `SseOperationStrategy`**, the one mode contract that shipped before this epic. That matters when you edit the roster: substituting `AppModeProfile` for the sixth slot leaves the census reading 12 — the profile also has two implementations — while quietly un-guarding the pre-existing contract. Phase 3 shipped it that way and a third `implements SseOperationStrategy` went undetected by the whole suite. The profile is checked separately, and deliberately without an exact count, because #1474 §9.1 expects a real `CloudModeProfile` eventually.

**Step 3 — implement it in both `impl/` classes.** The compiler makes this unskippable; that is the point.

**Step 4 — consume it through the profile, never through the mode.**

```dart
// ✅ ask the cause
final behavior = ref.watch(appModeProfileProvider).credential.authBehavior;

// ❌ ask the mode — this is the 14th `if`, and it is correct until it isn't
if (ref.watch(appModeProvider) == AppMode.remote) { ... }

// ❌❌ ask the global — invisible to every provider override, so untestable
if (GlobalConfig.remote.isActive) { ... }
```

`test/core/mode/composition_root_test.dart` enforces the middle line: `appModeProvider` may be *named* in exactly three files — its own declaration, `app_mode_profile.dart`, and the demo build's `overrideWithValue`. The scan counts every mention rather than just `ref.watch(...)`, on purpose: the narrower spelling let `ref.read`, `container.read`, a `.select` and a bare `AppMode.resolve()` straight through, so it enforced a spelling instead of the rule.

**Step 5 — test it by overriding a provider.** Two levers:

```dart
// coarse: re-derives the whole profile AND the surface root
ProviderContainer(overrides: [appModeProvider.overrideWithValue(AppMode.remote)]);

// fine: one strategy swapped, the rest real
ProviderContainer(overrides: [
  appModeProfileProvider.overrideWithValue(const RemoteModeProfile()),
]);
```

Do **not** assign `BuildConfig.forceCommandType`. `test/di_test.dart` is the one place in the repo that pays that price, for a pure function; everything else overrides a provider and needs no `tearDown`. `test/core/mode/app_mode_profile_test.dart` asserts this literally — it drives the whole stack in remote and then checks that the build flag still reads `none`.

#### **4. The member ledger — what is filled in, and by whom**

Phase 3 shipped **3 of the design's 20 members**; phase 4 adds **4 more**. Partially filled contracts are easier to misread than empty ones: `TransportStrategy`, `CredentialStrategy` and now `ProximityStrategy` have members, so they look done. They are not.

| Contract | Filled in | Outstanding | Owner |
| --- | --- | --- | --- |
| `TransportStrategy` | `bridgeConfig`, `sseStrategy` (p3); `isRouterReachable` (p4) | upload URL — `firmware_local_upload_service.dart` builds its WebSocket URL from `window.location`, which is phase 6's `transportLoss` case | #1496 (phase 6) |
| `CredentialStrategy` | `authBehavior` (p3); `reestablishAfterOutage`, `onCredentialRebound` (p4) | — | — |
| `SessionStrategy` | — | `end()` / `start()` | #1323 (phase 5) / phase 9 |
| `ProximityStrategy` | `planFor` (p4) | `canRecoverFrom()`, `disruptionOf()` | #1496 (phase 6) |
| `SurfaceStrategy` | — | 9 members | #1497 (phase 7) |

**Phase 4 landed three fewer members than the design prescribed, and each narrowing is a measurement.** The ledger above is the record; the reasoning, so the next phase does not "restore" them:

- **`probeEndpoint` became `isRouterReachable`.** A URL is not what the two modes disagree about. Locally reachability is `bridge.health()` plus two fields of its JSON body (`agent_connected`, `agent_state == 'ready'`); remotely it is a USP `Get` on `Device.DeviceInfo.SerialNumber` through the Guardian proxy, because `BridgeEndpoints.remote()`'s `health` path is a fabrication Guardian does not serve. Those are different *requests with different success criteria*, not one request against two URLs, and a `probeEndpoint` getter would have forced the caller to know which shape it got back. The member is therefore a question, and the answer is a `bool` that **never throws** — `RecoveryProbeService` has no try/catch around it, on purpose, because a throw out of `Timer.periodic`'s callback is an unhandled async error that leaves the loop spinning with no result recorded.
- **`restore()` and `verifyIdentity()` became one `reestablishAfterOutage()`.** No mode does one without the other: locally both, remotely neither. Two members would hand remote two no-ops and invite a future caller to do half the sequence — and the ordering matters (a serial read over a session that has not been restored reads the *old* connection, which after a factory reset is the one whose credentials no longer exist). One member cannot be half-called.
- **`canRefreshCredential` and `expiresAt` did not land, and `AuthBehavior` was not folded.** No acceptance in #1323 needs either. `authBehavior` already carries the same fact, which is exactly why #1474 §3 wants the fold — but the fold's trigger is *`CredentialStrategy` answering the same question twice*, and after phase 4 it still answers it once. Adding `canRefreshCredential` in order to then delete `authBehavior` is two edits to reach the state we are already in. The trigger stands: whichever change needs a second consumer of "can this credential be refreshed" lands the bool and deletes `AuthBehavior`, changing `UspBridgeClient`'s constructor signature in the same commit.
- **`RecoveryOutcome` was not introduced.** The design doc gives the probe a new return taxonomy; `ProbeResult`'s existing three values already carry it, and a fourth parallel taxonomy alongside `AppConnectionState` and phase 5's `EndCause` costs more than it explains. Keeping `ProbeResult` and `probe({bool healthOnly})` byte-identical is also what let `app_connection_state_provider_test.dart` — 745 lines mocking at the service seam — pass **unedited**, which is falsification criterion 2 of the design doc §10.5. Had any assertion there needed changing, the seam would have been wrong.

One new value type came with `planFor`: **`RecoveryPlan`** (`needsRecovery` + `probeInterval`), in `lib/framework/mode/` and not in `impl/`, for the reason Rule 3's second half records about `BridgeConfig` — it is a contract's return type, so the framework has to name it.

`RecoveryPlan.needsRecovery: false` is what a missing concept looks like when it is not a capability flag. Remote Assistance plus `operationalWifiChange` is the one cell that measures that way: the Guardian path runs browser → cloud → WAN uplink → agent, and the radios a Wi-Fi change restarts are not on it, so there is nothing to wait for. Note the shape — the strategy declines to use the recovery *surface*, rather than a `showsRecoveryDialog` bool being threaded to the widget. `enterWaiting` therefore returns `bool`, and `showRecoveryDialog` skips the dialog on `false`; opening it anyway would hang, since it pops on a transition *into* `authenticated` and the app never left it.

#### **5. Why three contracts ship empty**

`SessionStrategy`, `ProximityStrategy` and `SurfaceStrategy` are declared with **no members**. This is deliberate and each has a *measured* blocker, not a vague one:

| Contract | Filled by | Why it cannot move in phase 3 |
| --- | --- | --- |
| `SessionStrategy` | #1323 (phase 5) | The two endings differ by navigation target today, and the agreed signature returns an outcome instead — so the caller side must be rewritten in the same change. |
| `ProximityStrategy` | ~~#1496 (phase 6)~~ — **`planFor` landed in phase 4**; `canRecoverFrom` still outstanding, #1496 | The blocker below applied to `canRecoverFrom` specifically, and still does: the member is `bool canRecoverFrom(DisruptionClass)`, and `DisruptionClass` does not exist — enumerating it *is* phase 6's analysis, so declaring the member against a placeholder would freeze that analysis before it happens. `planFor` was never blocked by it: `RecoveryTrigger` already existed, with five values and a real consumer. |
| `SurfaceStrategy` | #1497 (phase 7) | The first member is `forcedPreset()`, and `lib/page/dashboard/providers/usp_layout_controller.dart` constructs its notifier **without a `Ref`**, so the read cannot reach a provider until that constructor changes — a behavioural edit, which phase 3 excludes. |

The alternative was to declare each contract in the phase that fills it. That is worse arithmetic: adding a member to an existing contract later touches 3 files, whereas creating the contract plus two implementations plus both profile wirings plus the roster test touches 6. More importantly, the exhaustive `switch` in each composition root can only be written once against a **complete** set of causes — and that switch is the guard the entire epic rests on.

An empty contract is a promise with a deadline, so each one's doc comment names the phase that fills it and the blocker that stops it now. If a phase slips, the doc comment is where you find out.

#### **6. What phase 3 folded in, and what it deliberately did not**

Two migrations, chosen so the contracts arrive with real consumers rather than as an unused abstraction:

**Fold-in 1 — `uspBridgeClientProvider`'s inline `if`.** It chose **5** differing constructor arguments: endpoint table, host, bearer token, client-type id, auth behaviour. Every one of them is wrong-in-the-other-mode. It is now `TransportStrategy.bridgeConfig(ref)`, surfaced through a new `bridgeConfigProvider`, and `uspBridgeClientProvider` became a pure assembler.

Why a named `BridgeConfig` and not just a moved `if`: the VM stub `usp_bridge_client_base.dart` accepts all five arguments and **discards every one**, exposing no getter. So a unit test could not observe what a bridge had been built with — the difference between talking to the router and talking to Guardian was unobservable by construction. Naming the arguments moves the decision one step earlier, to somewhere a test can read it. `test/core/usp/services/bridge_endpoints_test.dart` is the other half of that, and it is the first test the endpoint table has ever had.

Two behaviour-preserving details worth knowing before you edit that provider:

- The local case now passes `endpoints: BridgeEndpoints.local, baseUrl: null` **explicitly**. That is exactly what omitting them meant — `_endpoints = endpoints ?? BridgeEndpoints.local` and `_baseUrl => _overrideBaseUrl ?? _usp.baseUrl` — so nothing changed except that the local case is now as inspectable as the remote one.
- `RemoteTransportStrategy.bridgeConfig` keeps a `.select((s) => s.config)`. **The select is load-bearing.** `RemoteAssistanceState` also carries `isActive`, and a bare `watch` rebuilt — hence re-created — the bridge and its SSE manager on an `isActive` flip that changed nothing about the transport.
- `BridgeConfig` deliberately has **no `operator ==`**. Adding one would coalesce bridge rebuilds, because `RemoteAssistanceConfig` has no `==` either and an equal-but-new session config currently rebuilds. That is very likely an improvement, and it belongs in the change that gives `RemoteAssistanceConfig` an `==`, where the rebuild count can be measured — not as a side effect of a file move.

**Fold-in 2 — the SSE strategy ternary.** `SseOperationStrategy` predates #1474 and is **not rewritten**; only who picks it moved. It is now reached *through* `TransportStrategy.sseStrategy(bridge)`, because "which subscription dance" is a consequence of "which path": the Guardian proxy rejects duplicate subscription IDs and scopes them to the stream, while the on-router bridge is idempotent. Asking the transport keeps the consequence expressed as one, so a third transport cannot arrive with a matching SSE discipline nobody wired up.

**What was left alone.** `sse_providers.dart` had three mode reads; it now has one. The survivor is `if (!GlobalConfig.remote.isActive)` around the `bridge.health()` call, and it stays on purpose. It is not a cause: it exists because `BridgeEndpoints.remote()`'s `health` path is a **fabrication** — Guardian has no such endpoint — so the `if` is compensating for a wrong entry in the endpoint table. The fix is to delete the path, which is transport-layer cleanup outside this epic (#1474 §11). Wrapping a fabricated endpoint in a strategy member first would freeze the fabrication into a contract. Same reasoning applies to `turboPrefix`.

#### **7. `AppMode` has four values and only three come from the build flag**

`ForceCommand` has three values (`local`, `remote`, `none`), so `AppMode.resolve()` can only ever produce `local`, `remote` and `cloud`. `AppMode.demo` is reachable only through `demo_overrides.dart`, which adds `appModeProvider.overrideWithValue(AppMode.demo)` — because `lib/demo/` is a separate **entry point** with provider overrides, not a build flavour.

That override is behaviour-neutral: demo composes the local strategies and already nulls `uspBridgeClientProvider` and `sseManagerProvider`, so it never reaches a transport. It exists so that the `demo` arm of the exhaustive switch is **reachable**. Without it the epic's central guard would carry an arm nothing could produce, which is a guard over a fiction.

`cloud` and `demo` both compose `LocalModeProfile.aliasedAs(...)` — **one implementation, three labels**. They share the strategy *instances* (asserted by `identical()` in the profile test) so no copy can drift, but they report their own `mode`, because `mode` is what a diagnostic log shows and a profile claiming `local` would send a reader hunting a local bug in a cloud session. The constructor asserts that `remote` can never be aliased this way: that pairing is precisely the phase-1 defect.

#### **8. Multi-step USP sequences across a transport rebind — the verdict**

#1322's review raised this and #1493 was asked to answer it, so the answer is recorded here rather than implemented as a member.

The concern: `UspClient.rebindTransport()` re-points the live client mid-flight, and a multi-step USP sequence straddling that rebind would send its first request to one transport and its second to another. Two such sequences exist: `createNotifySubscription` (Add → Set) and `purgeAllSubscriptions` (GET → Delete).

**Verdict: no strategy member.** Both sequences have exactly one caller each, and it is `lib/page/test_console/views/usp_test_console_view.dart` — the debug console, which is itself gated behind `BuildConfig.enableTestConsole`. There is no production path in which either sequence can straddle a rebind. The framework's own discipline is that a member needs a **measured** difference between the modes; here there is no measured occurrence at all. Adding `TransportStrategy.beginAtomicSequence()` would be an abstraction whose only justification is a scenario nobody can reach, and it would then have to be honoured by every future transport.

What to do instead, if a production caller ever appears: the existing `usp_mutation_lock.dart` is the right seam — `activate()` already takes that lock to swap the connection atomically, so a sequence that needs to exclude a rebind should take the same lock rather than teach the mode about sequences. Revisit this section, not the contract, when that caller lands.

#### **9. The six rules, and how each fails**

These are constitution **Article XVII**; repeated here with their failure modes because a rule whose violation is invisible is a convention, not a rule. Rules 3, 4, 5 and 6 are #1474 §3.1's own four; rules 1 and 2 were added by phase 3, because writing the composition roots is what made the exhaustiveness guarantee something a `default:` could quietly remove.

1. **Exhaustive switch, no `default:`.** *Fails as:* a developer adds an `AppMode`, gets two compile errors, and silences them with a catch-all. Compiles, works for the three old modes, silently gives the new one the wrong profile. The compiler pointed at the right place and offered the wrong fix. *Guarded by* `composition_root_test.dart`, because a switch **with** a catch-all is valid Dart and no runtime observation can tell the two apart.
2. **Two composition roots, and only they read the mode — the page root through the profile.** *Fails as:* two ways. A new feature reads `appModeProvider` and writes its own `if` — the pre-#1474 shape returning one site at a time, correct today and wrong the day a mode is added. And the page root reading `appModeProvider` instead of `appModeProfileProvider.mode`, which looks equivalent and quietly excludes cause 5 from the profile override the acceptance criterion is written around. *Guarded by* the census in the same file, plus a scan for the page root's own `ref.watch`.
3. **Contract in `lib/framework/mode/`, implementation at the layer it talks to — and the framework imports neither implementation directory.** *Fails as:* two ways. A `surface` member on the core profile, i.e. a `lib/core/` → `lib/page/` import that nothing rejects at build time. And the reverse crossing, which arrives through a *value type* rather than a strategy and so does not look like a layering violation while you are making it: `BridgeConfig` was first filed under `core/mode/impl/` because the two transport strategies build it, and `transport_strategy.dart` then imported the implementation directory to name its own return type. *Guarded by* the `lib/framework/mode/` import scan in `mode_contract_roster_test.dart`; nothing else can see it, since it compiles, passes every behavioural test, and `dart analyze` has no opinion on import direction.
4. **One definition per contract, and none of them `sealed`.** *Fails as:* two ways. A duplicated contract compiles and then splits the app in two, because `AppModeProfile` composes by type and the copy nothing wires up is simply never selected — the same silent failure Article IV Rule 4 records for `PreservableContract`. And `sealed` is what the IDE *suggests* for a closed two-implementation hierarchy; it breaks `test/core/usp/mocks.dart`-style fakes from another library, and the failure surfaces in the mock file, so the natural fix looks like "delete that stale mock". *Guarded by* `mode_contract_roster_test.dart`.
5. **One contract per cause; a multi-cause divergence is a *consumer*, never a new contract.** *Fails as:* the messiest modules are the ones drawing on several causes at once, and the reflex is a `Local`/`Remote` pair for each. Recovery draws on causes 1, 2 and 4; the operation guard on cause 4 — so `RecoveryProbeService` and `OperationGuard` take strategies as **parameters** and keep one implementation each. A pair duplicates everything the two modes do identically, and the copies drift on all of it except the one line that differed, while both keep passing their own tests. *Guarded by* the `_notPaired` half of `mode_contract_roster_test.dart`. This is the rule phases 4 and 6 are judged against.
6. **Shape follows use, not subject matter.** Called polymorphically → `abstract class`; switched on → `enum` when no case carries data, `sealed class` when a case does. `AppMode` is an enum; the contracts are abstract classes — which rule 4 independently requires. Stated so the two are known to *agree* rather than to coincide: if a mode value ever needs to carry data, `AppMode` becomes a `sealed class` and the roots stay exhaustive, while the contracts must **not** follow it.

Three disciplines that are not rules because they need judgement:

- **A member needs a measured difference.** Not an anticipated one. §8 above is this discipline applied and answering "no".
- **The two implementations are peers — no `RemoteX extends LocalX`.** Inheritance here re-creates the exact defect the epic removes: local as the silent default. It fails silently because the subclass is correct the day it is written — every member it does not override *is* the local answer, so a member added to the parent later is inherited by remote without anyone deciding it should be.
- **A mode expresses a missing concept by its strategy not using a surface** — never by a bool that hides UI. See the three deleted flags in §1.

#### **10. Tests that guard this framework**

| File | Guards |
| --- | --- |
| `test/core/mode/app_mode_profile_test.dart` | One override moves the whole stack; the build flag stays untouched; cloud/demo share instances but keep their label |
| `test/core/mode/composition_root_test.dart` | Rules 1 and 2 — no `default:`/`_ =>`, every `AppMode` named, `appModeProvider` mentioned in exactly three files, and the page root taking its mode from the *profile* |
| `test/core/mode/mode_contract_roster_test.dart` | Rules 3 and 4 — six contracts, one definition each, none `sealed`, exactly two implementations each, no Local/Remote pair for *services*, and no framework file importing either implementation directory |
| `test/core/usp/services/bridge_endpoints_test.dart` | The endpoint tables are disjoint, session-scoped and absolute |
| CI step `🏗️ Smoke Build (Web, force=remote)` | The RA flavour still compiles — a compile-time partition nothing else in the pipeline sees |

**One test outside this framework will fail when you add a strategy, and it is not broken.** `test/page/remote_assistance/remote_assistance_side_split_test.dart` (phase 8's D5 guard) globs `lib/` for files whose *name* contains "remote" and demands each one be classified. Every `remote_*_strategy.dart` you add trips it. Phase 3 answered it with a fourth bucket, `_modeFramework`, rather than by filing the files as the RA agent side: the framework's whole job is to name both modes in one file, so classifying either half as a side makes `app_mode_profile.dart` — which imports the local and the remote profile by design — look like an undeclared crossing. Add your new file to `_modeFramework`; the bucket is inventory and carries no import constraint, because a mode strategy legitimately reaching into one side is plausible (phase 5's `end()` may need `remoteAccessProvider`).

The three source scans all strip `//` lines before matching, and that is load-bearing rather than tidy: these files' own doc comments quote the very tokens they search for, so a scan that kept comments would be satisfied by prose and could never fail. Every one of them was mutation-tested — a real `_ =>` arm, a third `implements TransportStrategy`, and a direct `ref.watch(appModeProvider)` outside the roots each turned the suite red before being reverted.

#### **11. Phase map**

| Phase | Issue | What it adds |
| --- | --- | --- |
| 3 | #1493 | This framework; transport + credential filled in |
| 4 | #1323 | Recovery — `RecoveryProbeService` takes strategies, it does **not** become a pair |
| 5 | #1323 | `SessionStrategy.end()` |
| 6 | #1496 | `ProximityStrategy.canRecoverFrom()` + `DisruptionClass` + `OperationGuard` |
| 7 | #1497 | `SurfaceStrategy` members — the 7 remaining bare UI reads |
| 8 | #1494 | Config deletion + naming the two RA sides apart |
| 9 | — | Session entry / `SessionStrategy.start()` |

**Phases 4 and 5 are one issue, and it is #1323.** Worth stating because the phase numbers and the issue numbers run in step everywhere else, which makes `#1494` look like phase 4's ticket — it is phase 8's, and `#1495` is an unrelated PNP band bug with no connection to this epic at all. Earlier drafts of this guide and of `mode_contract_roster_test.dart` cited both wrongly; a doc comment that sends you to the wrong ticket costs more than a missing one, because it reads as researched.
