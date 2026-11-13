# The 1.x Constitution

**Version:** 1.0
**Last amended:** 2026-11-12 (#1804, first version)
**Applies to:** the 1.x line of PrivacyGUI: `dev-1.*`, `release-1.*`, and `main` while it ships 1.x. 2.x has its own `constitution.md`; nothing here binds 2.x, and nothing in 2.x's binds 1.x.

## Preamble

These are the rules that humans and AI agents follow when they change 1.x.

They describe the code as it is. Where today's code breaks a rule, the rule names the exception instead of leaving it to be discovered. Exception lists shrink. They do not grow, except by amendment (Article IX).

Every rule says how it is enforced:

- **Test**: a test in `./run_tests.sh` fails.
- **CI**: a PR check fails. 1.x has no PR checks until #1802 P1 lands. Until then, run the same command locally; the reviewer checks that you did.
- **Review**: only a reviewer catches it. A rule enforced only by review says so.

Where this document and another document in the repository disagree, this one wins. It changes only through Article IX.

| Article | Rule | Enforced by |
|---|---|---|
| I | Presentation files don't use the data layer; `lib/core/` doesn't import `lib/page/` | Test |
| II | JNAP goes through `RouterRepository`; the HSL spec's `[noauth]` decides `auth:` | Review |
| III | Tests run through `run_tests.sh`; changes ship tests; screenshot tests and mocks follow one pattern | Test for where screenshot checks live; review for the rest, until #1802's gate and roster and #1803's floor land |
| IV | Feature state lives in `Notifier` / `AsyncNotifier`; `…State` classes extend `Equatable` | Review |
| V | File, class, provider and directory names | Review |
| VI | User-visible strings come from the ARB files | CI (#1802 P1) for missing keys; review for hard-coded strings |
| VII | Zero analyzer errors; no new warnings | CI (#1802 P1) for errors; review for warnings |
| VIII | Simplicity; no wrappers around the framework; stay in scope | Review |
| IX | Amendments state version, date and reason; the team approves them | Team approval |

---

## Article I: Architecture Boundaries

### 1.1 Layers

Dependencies point down.

```
Presentation   lib/page/**, outside the directories named below
               views, widgets, components
     │  watches and reads providers
Application    lib/page/**/{providers,service,services,data,models,model}/
               lib/providers/
     │  calls RouterRepository
Core           lib/core/
               the data layer is part of it:
                 lib/core/jnap/router_repository.dart          RouterRepository, routerRepositoryProvider
                 lib/core/jnap/command/                        JNAP commands
                 lib/core/http/                                HTTP clients
                 lib/core/cloud/linksys_cloud_repository.dart  cloudRepositoryProvider
```

A **presentation file** is any Dart file under `lib/page/` that is not inside a directory named `providers`, `service`, `services`, `data`, `models` or `model`.

The rest of `lib/` is outside these layers, and the test in 1.5 does not check it: `lib/route/`, `lib/util/`, `lib/constants/`, `app.dart` and the other top-level files. For example, `RouterNotifier` in `lib/route/router_provider.dart` sends `getDeviceInfo` through `RouterRepository` in `_prepareLocal`.

### 1.2 Presentation files don't use the data layer

A presentation file does not:

- import `lib/core/jnap/router_repository.dart`, any file under `lib/core/jnap/command/`, any file under `lib/core/http/`, or `lib/core/cloud/linksys_cloud_repository.dart`;
- read `routerRepositoryProvider` or `cloudRepositoryProvider`.

A view that needs the router calls a method on its feature's notifier, and the notifier calls `RouterRepository`. Relative imports count the same as `package:` imports.

Why: a router call made from a view can only be tested by pumping the page. It is also not where the next reader looks for what the page sends.

### 1.3 `lib/core/` doesn't import `lib/page/`

No file under `lib/core/` imports or exports a file under `lib/page/`. Every feature uses `lib/core/`. An import from a feature ties all of them to that feature.

### 1.4 Exceptions

These dependencies predate this constitution. They are listed, not fixed (#1804, Decision 2). The test in 1.5 reads the first two columns of this table and fails on a row it cannot read, so keep the file and the dependency of each row in backticks. A dependency is a file or a provider name.

<!-- boundary-exceptions:begin -->
| File | Depends on | What it uses |
|---|---|---|
| `lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart` | `lib/core/jnap/router_repository.dart` | |
| `lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart` | `routerRepositoryProvider` | `getLocalIP()`, twice |
| `lib/page/dashboard/views/prepare_dashboard_view.dart` | `lib/core/jnap/router_repository.dart` | |
| `lib/page/dashboard/views/prepare_dashboard_view.dart` | `routerRepositoryProvider` | `send(getDeviceInfo)` |
| `lib/page/instant_setup/pnp_admin_view.dart` | `lib/core/jnap/router_repository.dart` | |
| `lib/page/instant_setup/pnp_admin_view.dart` | `routerRepositoryProvider` | `isLoggedIn()` |
| `lib/page/instant_setup/pnp_setup_view.dart` | `lib/core/jnap/command/base_command.dart` | `CacheLevel` |
| `lib/page/instant_setup/pnp_setup_view.dart` | `lib/core/jnap/router_repository.dart` | |
| `lib/page/instant_setup/pnp_setup_view.dart` | `routerRepositoryProvider` | `send(getRadioInfo)` |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_pppoe_view.dart` | `lib/core/jnap/router_repository.dart` | nothing: the import is unused |
| `lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart` | `lib/core/jnap/router_repository.dart` | |
| `lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart` | `routerRepositoryProvider` | `isLoggedIn()` |
| `lib/core/jnap/models/node_light_settings.dart` | `lib/page/nodes/_nodes.dart` | `NodeLightStatus` |
| `lib/core/jnap/providers/polling_provider.dart` | `lib/page/instant_privacy/providers/instant_privacy_provider.dart` | `instantPrivacyProvider` |
| `lib/core/jnap/providers/polling_provider.dart` | `lib/page/vpn/providers/vpn_notifier.dart` | `vpnProvider` |
<!-- boundary-exceptions:end -->

To retire a row, move the call into the feature's notifier (or the type out of `lib/page/`), then delete the row. Deleting a row is not an amendment. Adding one is.

### 1.5 Enforcement

**Test**: `test/constitution/architecture_boundary_test.dart` scans `lib/` and compares what it finds with the table in 1.4. It fails when:

- a dependency breaks 1.2 or 1.3 and has no row. This is a new violation, or a row deleted without fixing the code;
- a row no longer matches the code. The code was fixed and the row has to go.

The test cannot tell a new row from an old one: a PR that adds a violation and its row together passes it. That the table only shrinks is enforced by Article IX, because adding a row amends this constitution.

A row covers a dependency, not each use of it. A listed file can add more calls through a provider it already reads, and the test stays green; review catches that.

The test reads source text; it does not parse Dart. A provider name in a string, or in a comment that follows code on the same line, counts as a read. Reword or remove it rather than adding a row.

---

## Article II: JNAP Access

### 2.1 One way to the router

JNAP calls go through `RouterRepository`: `send`, `transaction` and `scheduledCommand`. Nothing else builds a JNAP request or posts to the router.

Exception: `manualFirmwareUpdate` in `lib/core/jnap/providers/firmware_update_provider.dart` uploads the firmware file itself. It posts `X-JNAP-Action: updatefirmware` with the admin credential to `https://<local IP>/jcgi/` through `LinksysHttpClient`, as a multipart upload. Since `RouterRepository`'s access check never sees that request, the method calls `enforceAccess` itself.

**Enforced by**: Review. Article I keeps presentation files away from `RouterRepository`, but no test checks how application code reaches the router.

### 2.2 The HSL spec decides `auth:`

Whether an action needs the admin credential is decided by the `[noauth]` attribute in `linksys/JNAP`'s HSL specs, under `openwrt-jnap/src/spec/` (`core.hsl`, `router.hsl`, `nodes/setup.hsl`, `nodes/smartmode.hsl`, …):

- an action marked `[noauth]` may be sent without `auth: true`;
- every other action is sent with `auth: true`.

The `auth:` parameter of `send`, `scheduledCommand` and `JNAPTransactionBuilder` defaults to `false`. A call site with no `auth:` is therefore no evidence that the action needs no credential. Check the spec, not the neighbouring call sites:

```bash
gh api repos/linksys/JNAP/contents/openwrt-jnap/src/spec/core.hsl --jq .content | base64 -d | grep -n noauth
```

Read the spec at the JNAP commit the firmware pins, not at `main`. An action can be `[noauth]` on the pinned commit and absent from `main`; `GetAutoMasterStatus` was, in 2026-08.

A missing `auth: true` is easy to miss when testing on a router. Only the `behindManaged` branch of `RouterRepository._buildCommandHeader` honours `auth:`; the `behind` and `others` branches attach the credential either way. So the omission only fails on a local login whose request goes out as `behindManaged`.

**Enforced by**: Review.

---

## Article III: Testing

### 3.1 Tests run through `run_tests.sh`

`./run_tests.sh <reportDir>` runs the suite with `--exclude-tags="golden||loc"` and writes `tests.json` and an HTML report into `<reportDir>`. Run tests only this way, also when you are checking a single file: read that file's results from `tests.json` instead of running `flutter test <file>`.

`golden` and `loc` tests compare pixels, and pixels depend on the machine's fonts and renderer, so they never run as part of a test run on a dev machine. `run_generate_loc_snapshots.sh` produces screenshots with `--update-goldens` (see `docs/screenshot_testing_guide.md`). That is screenshot generation, not a pass/fail run.

**Enforced by**: Review. CI runs the same script once #1802 P1 lands.

### 3.2 Provider and model changes ship unit tests

A change to a notifier, a service, a `…State` class or a model ships unit tests for the behaviour it changed. A test of one source file sits at the path that mirrors it: `lib/page/wifi_settings/providers/wifi_list_provider.dart` is tested in `test/page/wifi_settings/providers/wifi_list_provider_test.dart`.

**Enforced by**: Review, until #1803's coverage floor lands.

### 3.3 A new view ships a layout-gate case

A new `lib/page/**/*_view.dart` ships a case in #1802's layout gate, so it is swept for overflow at every layout breakpoint.

**Enforced by**: #1802's roster test, once #1802 P3 lands. The rule takes effect then.

### 3.4 A fix that ellipsizes ships a readability guard

A fix that makes text fit by ellipsizing it or capping `maxLines` ships a test at the width that forced the fix. The test asserts the text is still usable. For an IP, MAC, serial number, firmware version or SSID, that means `RenderParagraph.didExceedMaxLines` is false.

The overflow sweep cannot see this: adding `maxLines: 1` turns every overflowing row green and cuts `192.168.1.100` in the middle.

**Enforced by**: Review. #1802 P4 adds the first set of guards.

### 3.5 Screenshot tests

A page's screenshot test is a `testLocalizations` case, from `test/common/test_responsive_widget.dart`:

- `testLocalizations` tags the case `loc`, so `run_tests.sh` skips it (3.1). No other file makes a golden check, with `matchesGoldenFile` or with `golden_toolkit`'s `screenMatchesGolden` and `multiScreenGolden`. A golden check in a plain `testWidgets` would run in the unit suite.
- The case lives in a `localizations/` directory beside the feature's other tests, such as `test/page/dashboard/localizations/dashboard_home_view_test.dart`.
- The case replaces the page's providers with `overrideWith`, using the mocks in `test/mocks/` (3.6) and the data in `test/test_data/`.

#1802's layout gate reuses these cases, so the case 3.3 asks for is a `testLocalizations` case. How to write, run and debug one is in `docs/screenshot_testing_guide.md`.

<!-- screenshot-exceptions:begin -->
| File | Calls |
|---|---|
| `test/page/components/pwa/install_prompt_banner_test.dart` | `testLocalizations` |
<!-- screenshot-exceptions:end -->

**Enforced by**: Test, for the first point and for the `localizations/` directory in the second. `test/constitution/screenshot_placement_test.dart` fails when a file other than the helper makes a golden check, or when a file outside a `localizations/` directory calls `testLocalizations`, and the table above has no row for it. It also fails when a row no longer matches. Review for where the `localizations/` directory sits, and for the third point.

### 3.6 Mocks

1.x mocks with mockito; it has no mocktail.

- A mock is generated. Its spec is `test/mocks/mockito_specs/<name>_spec.dart`, holding `@GenerateNiceMocks([MockSpec<ClassName>()])`. `dart run build_runner build` writes `<name>_spec.mocks.dart` beside it, and those generated files are gitignored.
- A mock that tests share is copied into `test/mocks/` and committed. A new one is named `test/mocks/<name>_mocks.dart`.
- When a notifier mock is copied into `test/mocks/`, its class signature must be changed. The generated `extends Mock` becomes `extends` the notifier's base class, with `Mock` mixed in, because Riverpod's notifiers need that inheritance chain in tests (`docs/screenshot_testing_guide.md` 2.3):

  ```dart
  // Generated, in test/mocks/mockito_specs/
  class MockWifiListNotifier extends Mock implements WifiListNotifier {

  // Copied, in test/mocks/
  class MockWifiListNotifier extends Notifier<WiFiState>
      with Mock
      implements WifiListNotifier {
  ```

  The same applies to `AsyncNotifier` and `AutoDisposeNotifier`. Any other mock keeps the generated class line.
- When a mocked class gains or changes a method, rerun `build_runner` and copy the mock again. A copy that predates the method returns null from it.
- A mock is `Mock[ClassName]`.

**Enforced by**: Review.

---

## Article IV: State Management

### 4.1 Riverpod

Feature state lives in a `Notifier` exposed through a `NotifierProvider`, or in an `AsyncNotifier` exposed through an `AsyncNotifierProvider` when the state loads asynchronously. A plain `Provider` holds a dependency or a derived value. A `StateProvider` holds a single value that no logic acts on. Don't add a `StateNotifier` or a `ChangeNotifier`.

Exception: `RouterNotifier` in `lib/route/router_provider.dart` extends `ChangeNotifier`, because `go_router`'s `refreshListenable` takes a `Listenable`.

### 4.2 `…State` classes extend `Equatable`

A `…State` class that a notifier holds extends `Equatable` and lists every field in `props`. States then compare by value, which tests and `ref.listen` callbacks rely on.

Exceptions: `PnpTroubleshooterState`, `SelectNetworkState`, `InstantTopologyState`.

**Enforced by**: Review.

---

## Article V: Naming

### 5.1 Files

- Dart files are `snake_case.dart`. The analyzer's `file_names` lint reports a breach as an info, which no check fails on.
- A page is `*_view.dart`. #1802's roster finds pages by this suffix, so a page named otherwise escapes the layout gate.
- A file that defines a notifier provider is `*_provider.dart`. Exceptions: `lib/page/vpn/providers/vpn_notifier.dart`, `lib/page/auto_ipoe/providers/auto_ipoe_notifier.dart`, `lib/core/pwa/pwa_install_service.dart`.
- A test of one source file is `<source>_test.dart`. A test that splits one source's tests by scenario is `<source>_<scenario>_test.dart`. A test that covers no single source file is named after what it checks, like `architecture_boundary_test.dart`.

### 5.2 Classes and providers

- A notifier class ends in `Notifier`. Exceptions: `HealthCheckProvider` and `PwaInstallService`.
- A notifier's provider ends in `Provider` and has no `Notifier` in its name: `WifiListNotifier` is read through `wifiListProvider`.
- A class written to be a notifier's state ends in `State`, like `WiFiState` or `PnpState`. Its prefix need not repeat the notifier's: `WifiListNotifier` holds a `WiFiState`. A notifier may also hold a model as its state, like `AppSettings` or `JNAPSideEffect`.
- Mocks are named in 3.6.

### 5.3 Feature directories

A new feature lives in `lib/page/<feature>/`, with `views/` and `providers/`, and `models/` when it has models.

The existing directories vary:

- `advanced_settings` holds one directory per settings page, plus a shared `widgets/`. Every page has `providers/`, and all but `static_routing` have `views/`.
- `instant_setup` keeps its two main views at the top level, its notifier in `data/` and its troubleshooter in its own directory.
- `support` is two files with no sub-directories.
- `components`, `firmware_update` and `landing` have no `providers/`, and `login` has one only under `auto_parent/`.

When a feature has a barrel, it is `_<feature>.dart` in the feature's directory, as in `lib/page/nodes/_nodes.dart` and `lib/page/advanced_settings/dmz/_dmz.dart`. Eight directories under `lib/page/` have none: `auto_ipoe`, `components`, `instant_privacy`, `instant_setup`, `instant_verify`, `login`, `support` and `vpn`.

**Enforced by**: Review.

---

## Article VI: Localization

### 6.1 User-visible strings come from the ARB files

Every string a user can see is a key in `lib/l10n/app_en.arb`, the template, read through `loc(context)` from `lib/localization/localization_hook.dart`. `flutter gen-l10n` writes the keys the other locales are missing to `untranslated.txt`. Log messages, JNAP action names and storage keys are not user-visible.

### 6.2 Regenerate after pulling

`lib/l10n/gen/` is generated by `flutter gen-l10n` and is gitignored. Run it after pulling and after editing an ARB file. A stale `gen/` fails to compile wherever a new key is used.

**Enforced by**: CI, for keys: #1802 P1 runs `gen-l10n`, so a key that is used but not defined fails the build. A hard-coded string compiles, so that half is Review.

---

## Article VII: Lint

### 7.1 Zero analyzer errors

`flutter analyze` reports no errors. Its rules come from `analysis_options.yaml`: `flutter_lints`, with `prefer_const_constructors` off.

### 7.2 Warnings are cleaned, not added

A change adds no analyzer warnings. The existing ones (246 when #1802 was filed) are cleared in a dedicated PR (#1802, Decision 1), not mixed into feature changes, so that a feature's diff stays about the feature.

**Enforced by**: CI for errors: #1802 P1 runs `flutter analyze --no-fatal-warnings --no-fatal-infos`. Review for warnings, until the backlog is cleared and the check can fail on them.

---

## Article VIII: Simplicity

### 8.1 Justify complexity

Build what the issue needs. Don't add layers, interfaces or options for requirements nobody has stated. A second concrete use justifies an abstraction; the first does not.

### 8.2 Use the framework directly

Use Riverpod, `go_router` and `http` directly; don't wrap them. The abstractions 1.x relies on are legitimate: `RouterRepository` as the one way to the router (Article II), the feature notifiers, and the components in `plugins/widgets`.

### 8.3 No service layer is required

1.x notifiers call `RouterRepository` directly. A service class, like those in `lib/page/vpn/service/` and `lib/page/auto_ipoe/service/`, is allowed where it removes duplication or isolates logic for testing. It is not required.

### 8.4 Stay in scope

A change does what its issue asks. A refactor, a rename or a lint cleanup that the issue does not need goes in its own PR.

**Enforced by**: Review.

---

## Article IX: Amendments

### 9.1 What counts as an amendment

These are amendments:

- adding, removing or changing a rule;
- adding an exception, or changing the file or the dependency an exception names, even when a file only moved.

These are not:

- deleting an exception because the code was fixed;
- correcting the prose, including a typo or a path outside an exception.

### 9.2 What the PR contains

A PR that amends this constitution:

- bumps **Version**: the major number when a rule is added, removed or tightened, or an exception is added; the minor number otherwise;
- sets **Last amended** to the date and the issue;
- adds a note under the section it changes: *Amended YYYY-MM-DD (#issue): what changed, and why.*

### 9.3 The team approves

The team approves an amendment, not a single reviewer. The PR says where the team approved it.

**Enforced by**: Team approval. The repository's rules let any PR merge with one approval; for an amendment, one approval is not enough.

---

## Not Covered

### Not carried over from 2.x

2.x's `constitution.md` was the reference, but these articles describe 2.x's architecture, not 1.x's:

- **IV** (USP provider architecture): 1.x talks JNAP.
- **VI** and **XIII** (service layer, `ServiceError`): 1.x notifiers call `RouterRepository` directly, and its errors are `JNAPError`, `JNAPSideEffectError` and the retry exceptions in `lib/core/`. Requiring a service layer would be a refactor, not a description of the code.
- **XIV** and **XV** (layout blocks, the UI kit principle): 1.x has no `ui_kit_library`.
- **XVI** and **XVII** (E2E semantics identifiers, app modes).

### Deferred

Rules for `plugins/widgets` components, for E2E identifiers in `integration_test/`, and for app modes such as remote assistance are to be evaluated after #1804 (Decision 3).
