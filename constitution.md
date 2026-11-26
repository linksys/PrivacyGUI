# The 1.x Constitution

**Version:** 1.9
**Last amended:** 2026-11-25 (#1935, E2E identifiers)
**Applies to:** the 1.x line of PrivacyGUI: `dev-1.*`, `release-1.*`, and `main` while it ships 1.x. 2.x has its own `constitution.md`; nothing here binds 2.x, and nothing in 2.x's binds 1.x.

## Preamble

These are the rules that humans and AI agents follow when they change 1.x.

They describe the code as it is. Where today's code breaks a rule, the rule names the exception instead of leaving it to be discovered. Exception lists shrink. They do not grow, except by amendment (Article IX).

Every rule says how it is enforced:

- **Test**: a test in `./run_tests.sh` fails.
- **CI**: a PR check fails. `.github/workflows/ci-1x.yml` runs three checks on every PR into `main` or a `dev-1.*` branch that carries the file: `1.x / Analyze`, `1.x / Unit Tests` and `1.x / Layout Gate`. On the branches that ruleset `required checks (1.x)` lists, a red check blocks the merge. `1.x / Unit Tests` runs `./run_tests.sh`, so a rule enforced by Test fails a PR check too. It also fails when line coverage of `lib/` drops below the floor in `coverage_floor.txt` (3.2). It leaves out the `layout-gate` tests, which `1.x / Layout Gate` runs (3.5).
- **Review**: only a reviewer catches it. A rule enforced only by review says so.

Where this document and another document in the repository disagree, this one wins. It changes only through Article IX.

| Article | Rule | Enforced by |
|---|---|---|
| I | Presentation files don't use the data layer; `lib/core/` doesn't import `lib/page/` | Test |
| II | JNAP goes through `RouterRepository`; the HSL spec's `[noauth]` decides `auth:` | Review |
| III | Tests run through `run_tests.sh`; changes ship tests; screenshot tests and mocks follow one pattern | Test for where screenshot checks live, for the layout gate's roster and for the readability guards; CI for #1803's coverage floor and for the layout gate; review for the rest |
| IV | Feature state lives in `Notifier` / `AsyncNotifier`; `…State` classes extend `Equatable` | Review |
| V | File, class, provider and directory names | Review |
| VI | User-visible strings come from the ARB files | CI for missing keys; review for hard-coded strings |
| VII | Zero analyzer errors and warnings | CI |
| VIII | Simplicity; no wrappers around the framework; stay in scope | Review |
| IX | Amendments state version, date and reason; the team approves them | Team approval |
| X | A scrolling page's content needs no bounded height | CI for flex children on pages with a case, through #1802's layout gate; review for the rest |
| XI | A control a test drives carries a kebab-case `identifier`; `semanticLabel` is screen-reader text only | Test for the page, label and widget tables; review for the rest |

*Amended 2026-11-18 (#1802): **CI** names the two checks that #1802 P1 added, and VI and VII no longer wait on P1, because 1.x has PR checks now.*

*Amended 2026-11-18 (#1803): **CI** and III name the coverage floor that #1803 Q5 added, which III waited on.*

*Amended 2026-11-19 (#1802): **CI** names `1.x / Layout Gate`, which #1802 P3 added so that a PR whose page overflows fails, and the summary row for III says what the gate and its roster enforce.*

---

## Article I: Architecture Boundaries

### 1.1 Layers

Code sits in three layers. Article I checks two directions between them: a presentation file does not use the data layer (1.2), and `lib/core/` does not import `lib/page/` (1.3). Other dependencies are not rules. In particular, 11 files in `lib/core/` import `lib/providers/`, mostly for login and connectivity state; `RouterRepository` reads `authProvider`, for one.

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
                 lib/core/cloud/linksys_device_cloud_service.dart  deviceCloudServiceProvider
```

A **presentation file** is any Dart file under `lib/page/` that either:

- is not inside a directory named `providers`, `service`, `services`, `data`, `models` or `model`; or
- builds UI wherever it sits: it declares a class that extends `StatelessWidget`, `StatefulWidget`, `ConsumerWidget`, `ConsumerStatefulWidget`, `State` or `ConsumerState`, or it uses `WidgetRef`. The PnP steps in `lib/page/instant_setup/model/` and `lib/page/health_check/providers/speed_test_display.dart` are presentation files for this reason.

The rest of `lib/` is outside these layers, and the test in 1.5 does not check it: `lib/route/`, `lib/util/`, `lib/constants/`, `app.dart` and the other top-level files. For example, `RouterNotifier` in `lib/route/router_provider.dart` sends `getDeviceInfo` through `RouterRepository` in `_prepareLocal`.

### 1.2 Presentation files don't use the data layer

A presentation file does not:

- import `lib/core/jnap/router_repository.dart`, any file under `lib/core/jnap/command/`, any file under `lib/core/http/`, `lib/core/cloud/linksys_cloud_repository.dart` or `lib/core/cloud/linksys_device_cloud_service.dart`;
- read `routerRepositoryProvider`, `cloudRepositoryProvider` or `deviceCloudServiceProvider`.

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

The test parses each file with `package:analyzer`. It reads imports and exports, conditional URIs included, as Dart does, and a name in a string or a comment is not a read.

---

## Article II: JNAP Access

### 2.1 One way to the router

JNAP calls go through `RouterRepository`: `send`, `transaction` and `scheduledCommand`. Nothing else builds a JNAP request or posts to the router.

Exception: `manualFirmwareUpdate` in `lib/core/jnap/providers/firmware_update_provider.dart` uploads the firmware file itself. It posts `X-JNAP-Action: updatefirmware` with the admin credential to `https://<local IP>/jcgi/` through `LinksysHttpClient`, as a multipart upload. Since `RouterRepository`'s access check never sees that request, the method calls `enforceAccess` itself.

Exception: `HttpAiSessionService` in `lib/core/ai_session/ai_session_service.dart` posts JSON, including the admin password on login, to `/cgi-bin/ai-session.cgi` on the app's origin, which is the router when the router serves the app. It does this through its own `http.Client`, and it does not call `enforceAccess`.

**Enforced by**: Review. Article I keeps presentation files away from `RouterRepository`, but no test checks how application code reaches the router.

### 2.2 The HSL spec decides `auth:`

Whether an action needs the admin credential is decided by the `[noauth]` attribute in `linksys/JNAP`'s HSL specs, under `openwrt-jnap/src/spec/` (`core.hsl`, `router.hsl`, `nodes/setup.hsl`, `nodes/smartmode.hsl`, …):

- an action marked `[noauth]` may be sent without `auth: true`;
- every other action is sent with `auth: true`.

The `auth:` parameter of `send`, `scheduledCommand` and `JNAPTransactionBuilder` defaults to `false`. A call site with no `auth:` is therefore no evidence that the action needs no credential. Check the spec, not the neighbouring call sites:

```bash
gh api "repos/linksys/JNAP/contents/openwrt-jnap/src/spec/core.hsl?ref=<pinned commit>" --jq .content | base64 -d | grep -n noauth
```

Read the spec at the JNAP commit the firmware pins, not at `main`. An action can be `[noauth]` on the pinned commit and absent from `main`; `GetAutoMasterStatus` was, in 2026-08.

A missing `auth: true` is easy to miss when testing on a router. Only the `behindManaged` branch of `RouterRepository._buildCommandHeader` honours `auth:`; the `behind` and `others` branches attach the credential either way. So the omission only fails on a local login whose request goes out as `behindManaged`.

**Enforced by**: Review.

---

## Article III: Testing

### 3.1 Test runs leave out `golden` and `loc`

`golden` and `loc` tests compare each screen with a golden image, and the repository keeps none: `test/**/goldens/*` is gitignored. In a test run they can only fail. `run_generate_loc_snapshots.sh` runs them with `--update-goldens` to write the images (see `docs/screenshot_testing_guide.md`); that is screenshot generation, not a pass/fail run.

So every test run passes `--exclude-tags="golden||loc"`:

- `./run_tests.sh <reportDir>` runs the whole suite that way and writes `tests.json` into `<reportDir>`. Run it before you push. It also leaves out `layout-gate`, the layout gate's tests (3.5), which take long enough to run in CI jobs of their own.
- The layout gate runs before you push through `.githooks/pre-push`, once you install the hooks with `git config core.hooksPath .githooks`. The hook runs the suites a push can affect, in every gate locale (3.5). To run the gate by hand, use `flutter test <suite> --tags layout-gate --exclude-tags="golden||loc"`.
- While you work, `flutter test <file or directory> --exclude-tags="golden||loc"` is fine, with any `--dart-define` the file needs. On a screenshot suite this also runs its layout gate tests in every gate locale (3.5); `--exclude-tags="golden||loc||layout-gate"` leaves them out.

**Enforced by**: Test for `run_tests.sh`: `test/constitution/run_tests_script_test.dart` fails if the script stops excluding the tags, `layout-gate` included. Review for other runs. `1.x / Unit Tests` runs the script on the PRs that **CI** in the preamble covers.

*Amended 2026-11-18 (#1802): CI runs the script now. The report directory gets `tests.json` only: the script writes no HTML report, though this section said it did.*

*Amended 2026-11-19 (#1802): `run_tests.sh` also leaves out the layout gate's tests, so a local run stays short (#1802, Decision 11). `1.x / Layout Gate` and the pre-push hook run them instead (Decision 12).*

### 3.2 Provider and model changes ship unit tests

A change to a notifier, a service, a `…State` class or a model ships unit tests for the behaviour it changed. A test of one source file sits at the path that mirrors it: `lib/page/wifi_settings/providers/wifi_list_provider.dart` is tested in `test/page/wifi_settings/providers/wifi_list_provider_test.dart`.

**Enforced by**:
- CI, for the total. `1.x / Unit Tests` fails when line coverage of `lib/` drops below `coverage_floor.txt`, measured as `./run_coverage.sh` measures it. So a PR that deletes a tested provider's tests fails. The file says when to raise the floor and when it may go down.
- Review, for whether a change tests the behaviour it changed. A floor on the total cannot tell.

*Amended 2026-11-18 (#1803): the coverage floor enforces the total, which this section waited on.*

### 3.3 A new view ships a layout-gate case

A new `lib/page/**/*_view.dart`, or a new page 5.1 lets go without the suffix, ships a case in #1802's layout gate, so it is swept for overflow at the gate's sizes (3.5).

The gate's case is a `testLocalizations` case (3.5). A page has one when a `testLocalizations` suite constructs its class. A page that a case reaches only as a tab of its parent does not count: `TabBarView` lays out the selected tab only. A view that only another page builds, with no route of its own, is a component instead: it needs no case of its own when that page's cases open it, and its row names them.

The table lists the pages that have no case, and each row says why the page needs none. Deleting a row because the page got a case, or was deleted, is not an amendment (9.1). A row that says nothing in `lib/` builds the page fails the roster test once something does, and a row that says nothing navigates to its route fails once code outside `lib/route/` names that route.

<!-- layout-gate-roster:begin -->
| Page | Class | Why |
|---|---|---|
| `lib/page/advanced_settings/local_network_settings/views/dhcp_reservations_edit_view.dart` | `DHCPReservationsEditView` | Permanent while unreachable: nothing navigates to its route, `dhcpReservationEdit`, and opened without the route's arguments it throws. Give it a case once something does. |
| `lib/page/advanced_settings/local_network_settings/views/dhcp_server_view.dart` | `DHCPServerView` | Permanent: a component, not a page. `LocalNetworkSettingsView` lays it out in its DHCP server tab, and its cases open the tab, so they sweep it. |
| `lib/page/advanced_settings/static_routing/static_routing_list_view.dart` | `StaticRoutingListView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/customs/network_check_view.dart` | `NetworkCheckView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/picker/day_picker_view.dart` | `DayPickerView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/picker/number_picker_view.dart` | `NumberPickerView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/picker/time_picker_view.dart` | `TimePickerView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/settings_view/editable_card_list_edit_view.dart` | `EditableCardListEditView` | Permanent while unreachable: nothing navigates to its route, `cardListEdit`, and opened without the route's arguments it throws. Give it a case once something does. |
| `lib/page/components/settings_view/editable_card_list_settings_view.dart` | `AppEditableCardListSettingsView` | Permanent: a component, not a page. The advanced settings lists build it; the IPv6 port service and static routing cases sweep it. |
| `lib/page/components/settings_view/editable_table_settings_view.dart` | `AppEditableTableSettingsView` | Permanent: a component, not a page. The advanced settings lists build it; the IPv6 port service and static routing cases sweep it. |
| `lib/page/components/styled/styled_tab_page_view.dart` | `StyledAppTabPageView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/views/arguments_view.dart` | `ArgumentsBaseConsumerStatefulView` | Permanent: a base class for views, not a page. |
| `lib/page/firmware_update/views/firmware_update_process_view.dart` | `FirmwareUpdateProcessView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/instant_setup/troubleshooter/views/call_support/call_support_main_region_view.dart` | `CallSupportMainRegionView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/instant_setup/troubleshooter/views/call_support/call_support_more_region_view.dart` | `CallSupportMoreRegionView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/login/auto_parent/views/auto_parent_first_login_view.dart` | `AutoParentFirstLoginView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/nodes/views/change_node_name_view.dart` | `ChangeNodeNameView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/nodes/views/node_light_guide_view.dart` | `NodeLightGuideView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/nodes/views/node_name_edit_view.dart` | `NodeNameEditView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/nodes/views/node_restart_view.dart` | `NodeRestartView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/wifi_settings/views/mac_filtering_view.dart` | `MacFilteringView` | Permanent: a component, not a page: a tab of `WiFiMainView`, with no route of its own. `WiFiMainView`'s cases open the tab, so they sweep it. |
| `lib/page/wifi_settings/views/wifi_advanced_settings_view.dart` | `WifiAdvancedSettingsView` | Permanent: a component, not a page: a tab of `WiFiMainView`, with no route of its own. `WiFiMainView`'s cases open the tab, so they sweep it. |
| `lib/page/wifi_settings/views/wifi_list_advanced_mode_view.dart` | `AdvancedModeView` | Permanent: a component, not a page. `WiFiListView` lays it out in the advanced mode, and the Wi-Fi settings cases in that mode sweep it. |
| `lib/page/wifi_settings/views/wifi_list_simple_mode_view.dart` | `SimpleModeView` | Permanent: a component, not a page. `WiFiListView` lays it out in the simple mode, and the Wi-Fi settings cases in that mode sweep it. |
| `lib/page/wifi_settings/views/wifi_list_view.dart` | `WiFiListView` | Permanent: a component, not a page: a tab of `WiFiMainView`, with no route of its own. `WiFiMainView`'s cases open the tab, so they sweep it. |
| `lib/page/wifi_settings/views/wifi_share_detail_view.dart` | `WiFiShareDetailView` | Permanent: a component, not a page: the content of the dashboard Wi-Fi card's share dialog. The dashboard's Share WiFi modal cases open the dialog, so they sweep it. |
<!-- layout-gate-roster:end -->

**Enforced by**: Test. `test/constitution/layout_gate_roster_test.dart` fails when a page has no case and no row in the table above, and when a row's page has a case or is gone.

*Amended 2026-11-19 (#1802): the rule takes effect, with the roster test and a row for each page that has no case yet, so a page cannot be left out of the gate unnoticed. The version moves to 1.4, not 2.0, although 9.2 asks a major number for an added exception or a tightened rule. This section said the rule would take effect with #1802 P3, and the rows are the exceptions it starts with, not exceptions added to a rule already in force. Counting the five pages 5.1 names, and not counting a tab, follow what 5.1 and `TabBarView` already imply. The team decides whether that holds (9.3).*

*Amended 2026-11-19 (#1802): the table may keep a page for good, with the reason it needs no case, where it said #1802 P6 would empty it. #1802 P6 had planned these exemptions, and 38 rows take one: 10 that are not pages, 19 that nothing lets a user open, and 9 that #1849 deletes. A component that a page lays out needs no case of its own when that page's cases open it. A page counts as unreachable when nothing in `lib/` builds it, or its route throws when opened, as a typed URL would open it. The rows of two deleted files go. The version moves to 1.6, not 2.0, although 9.2 asks a major number for an added exception, as #1802's other amendments kept the major number. The team approved it in a meeting on 2026-11-20 (9.3).*

### 3.4 A fix that ellipsizes ships a readability guard

A fix that makes text fit by ellipsizing it or capping `maxLines` ships a test at the width that forced the fix. The test asserts the text is still usable. For an IP, MAC, serial number, firmware version or SSID, that means the text is fully shown: `expect(finder, isFullyShown)` passes, from `test/layout_gate/fully_shown.dart`. No `maxLines` or ellipsis cuts the text, it fits its box, and no ancestor clips it, a scroll view included. It does not check the size the text is drawn at, so a value that a `FittedBox` shrinks passes.

The overflow sweep cannot see this: adding `maxLines: 1` turns every overflowing row green and cuts `192.168.1.100` in the middle.

These guards hold the values that are useless when cut, each as long as it gets. `testFullyShown`, in the same file, runs a guard in every locale at the narrowest mobile and desktop pages, 360 and 1240:

| Guard | Values |
|---|---|
| `test/page/instant_device/views/device_detail_readability_test.dart` | Device detail: the IPv4 and IPv6 addresses, the MAC address and the SSID |
| `test/page/nodes/views/node_detail_readability_test.dart` | Node detail: the WAN and LAN IP addresses, the firmware version, the serial number and the MAC address |
| `test/page/dashboard/views/internet_status_readability_test.dart` | The dashboard's internet status: the router's serial number and firmware version |
| `test/page/dashboard/views/wifi_grid_readability_test.dart` | The dashboard's Wi-Fi card: the SSID, at 1240 only, where the card is narrowest. The file also holds the guard for the card's device count, which #1802 fixed. |
| `test/page/wifi_settings/views/wifi_list_readability_test.dart` | Wi-Fi settings: the main and guest SSIDs, in the advanced and the simple mode |

A guard is proven by a mutation that cuts its value: the guard goes red, and the layout gate stays green. Where the value has room to spare on one line, the mutation caps it at one line in a box narrower than the value.

**Enforced by**: Test for the values above; review for a new fix.

*Amended 2026-11-19 (#1802): #1802 P4 adds the guards above. "Usable" becomes `isFullyShown`, which also fails a `SelectableText` that scrolls its value out of its box and a value an ancestor clips; `didExceedMaxLines` sees neither. The version moves to 1.8, not 2.0, although 9.2 asks a major number for a tightened rule, as #1802's other amendments kept the major number. The team approved it in a meeting on 2026-11-20 (9.3).*

### 3.5 Screenshot tests

A page's screenshot test is a `testLocalizations` case, from `test/common/test_responsive_widget.dart`. These rules cover `test/`, the directory `flutter test` runs:

- `testLocalizations` tags the case `loc`, so test runs leave it out (3.1). No code outside the body of `testLocalizations` makes a golden check, with `matchesGoldenFile` or with `golden_toolkit`'s `screenMatchesGolden` and `multiScreenGolden`. A golden check in a plain `testWidgets` would run in the unit suite.
- The case lives in a `localizations/` directory beside the feature's other tests, such as `test/page/dashboard/localizations/dashboard_home_view_test.dart`.
- The case replaces the page's providers with `overrideWith`, using the mocks in `test/mocks/` (3.6) and the data in `test/test_data/`.

#1802's layout gate reuses these cases, so the case 3.3 asks for is a `testLocalizations` case. How to write, run and debug one is in `docs/screenshot_testing_guide.md`.

`testLocalizations` also hands each case to `declareLayoutCases` in `test/layout_gate/layout_cases.dart`, which declares more tests from the same case. None of them makes a golden check, and none is tagged `loc`:

- **The layout gate** (#1802 P3), always: one test per size and locale in `test/layout_gate/gate.dart`, tagged `layout-gate`. It fails when the case overflows by more than 2.0px. `./run_tests.sh` leaves these tests out (3.1). `1.x / Layout Gate` runs them in `en` on a PR into a `dev-1.*` branch, and in every gate locale on a PR into `main`. The pre-push hook runs them in every gate locale, for the suites a push can affect.
- **The measurement** (#1802 P2), only with `--dart-define=layoutMeasure=true`: tests tagged `layout-measure`, which collect overflow reports instead of failing on them.

<!-- screenshot-exceptions:begin -->
| File | Calls |
|---|---|
| `test/page/components/pwa/install_prompt_banner_test.dart` | `testLocalizations` |
<!-- screenshot-exceptions:end -->

**Enforced by**: Test, for the first point and for the `localizations/` directory in the second. `test/constitution/screenshot_placement_test.dart` fails when code outside the body of `testLocalizations` makes a golden check, or when a file outside a `localizations/` directory calls `testLocalizations`, and the table above has no row for it. It also fails when a row no longer matches. Review for where the `localizations/` directory sits, and for the third point. CI for the layout gate: `1.x / Layout Gate` fails when a case overflows by more than 2.0px at a gate size. `test/layout_gate/layout_gate_ci_test.dart` fails when its locales or the suites it picks drift from the gate's.

*Amended 2026-11-18 (#1802): `testLocalizations` also declares #1802 P2's measuring tests, so that P2 measures overflow from the existing cases instead of new ones (#1802, Decision 6).*

*Amended 2026-11-19 (#1802): `testLocalizations` also declares #1802 P3's gate tests, tagged `layout-gate`, from the same cases, so that the gate sweeps the existing cases instead of new ones (#1802, Decision 6). Which locales run where follows Decisions 4, 7 and 12.*

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

Exceptions:

- These five extend the real notifier and mix in `Mock`, so that a test can fix part of its behaviour: `MockSimpleAuthNotifier` in `test/mocks/mock_auth_notifier.dart`; `SearchingMockAddNodesNotifier` and `OnboardingMockAddNodesNotifier` in `test/page/nodes/views/localizations/add_nodes_view_test.dart`; `SimpleAddWiredNodesNotifier` in `test/page/instant_topology/localizations/add_wired_node_view_test.dart`; and `MockHealthCheckSuccessProvider` in `test/page/health_check/views/localizations/speed_test_view_test.dart`. None of the five is named `Mock[ClassName]`.
- `test/mocks/mockito_specs/vpn_notifier_spec.dart` uses `@GenerateMocks`, not `@GenerateNiceMocks`.

A `Fake`, a hand-written stand-in that extends `Fake` (11 in `test/`), is not a mock under this section.

**Enforced by**: Review.

---

## Article IV: State Management

### 4.1 Riverpod

Feature state lives in a `Notifier` exposed through a `NotifierProvider`, or in an `AsyncNotifier` exposed through an `AsyncNotifierProvider` when the state loads asynchronously. A plain `Provider` holds a dependency or a derived value. A `StateProvider` holds a single value that no logic acts on. Don't add a `StateNotifier` or a `ChangeNotifier`.

Exception: `RouterNotifier` in `lib/route/router_provider.dart` extends `ChangeNotifier`, because `go_router`'s `refreshListenable` takes a `Listenable`.

### 4.2 `…State` classes extend `Equatable`

A `…State` class that a notifier holds extends `Equatable` and lists every field in `props`. States then compare by value, which tests and `ref.listen` callbacks rely on.

Exceptions: `PnpTroubleshooterState`, `InstantTopologyState`.

**Enforced by**: Review.

---

## Article V: Naming

### 5.1 Files

- Dart files are `snake_case.dart`. The analyzer's `file_names` lint reports a breach as an info, which no check fails on.
- A page is `*_view.dart`. #1802's roster finds pages by this suffix, so a page named otherwise escapes the layout gate. Exceptions, each a page that `lib/route/` builds: `lib/page/vpn/views/vpn_settings_page.dart`, `lib/page/health_check/views/speed_test_external.dart` and `lib/page/health_check/views/speed_test_selection.dart`.
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
- `components` and `firmware_update` have no `providers/`, and `login` has one only under `auto_parent/`.

When a feature has a barrel, it is `_<feature>.dart` in the feature's directory, as in `lib/page/nodes/_nodes.dart` and `lib/page/advanced_settings/dmz/_dmz.dart`. Eight directories under `lib/page/` have none: `auto_ipoe`, `components`, `instant_privacy`, `instant_setup`, `instant_verify`, `login`, `support` and `vpn`.

**Enforced by**: Review.

---

## Article VI: Localization

### 6.1 User-visible strings come from the ARB files

Every string a user can see is a key in `lib/l10n/app_en.arb`, the template, read through `loc(context)` from `lib/localization/localization_hook.dart`. `flutter gen-l10n` writes the keys the other locales are missing to `untranslated.txt`. Log messages, JNAP action names and storage keys are not user-visible.

### 6.2 Regenerate after pulling

`lib/l10n/gen/` is generated by `flutter gen-l10n` and is gitignored. Run it after pulling and after editing an ARB file. A stale `gen/` fails to compile wherever a new key is used.

**Enforced by**: CI, for keys: both checks run `flutter gen-l10n` during setup, before they analyze or test, so a key that is used but not defined fails `1.x / Analyze` with `undefined_getter`. A hard-coded string compiles, so that half is Review.

*Amended 2026-11-18 (#1802): names the check that fails, now that #1802 P1 has added it.*

---

## Article VII: Lint

### 7.1 Zero analyzer errors

`flutter analyze` reports no errors. Its rules come from `analysis_options.yaml`: `flutter_lints`, with `prefer_const_constructors` off. It leaves out `plugins/**`: `plugins/widgets` is a submodule from its own repository, `linksys/PrivacyGUI-Widgets`, and its diagnostics are fixed there.

*Amended 2026-11-18 (#1802): `analysis_options.yaml` excludes `plugins/**`, because `plugins/widgets` is fixed in its own repository (#1802, Decision 1). This adds no exception: rules for `plugins/widgets` were already deferred (Not Covered › Deferred), so the version moves to 1.1, not 2.0.*

### 7.2 Zero analyzer warnings

`flutter analyze` reports no warnings either. #1802 cleared the 219 there were (246 when #1802 was filed, 221 once 7.1 left out `plugins/**`) in a PR of their own, so that no feature's diff carried them (#1802, Decision 1). Infos are not counted.

**Enforced by**: CI. `1.x / Analyze` runs `flutter analyze --no-fatal-infos`, which fails on an error or a warning.

*Amended 2026-11-18 (#1802): names the check that runs the analyzer, now that #1802 P1 has added it, and gives the warning count once 7.1 left out `plugins/**`.*

*Amended 2026-11-20 (#1802): the backlog is cleared, so `1.x / Analyze` fails on warnings too, and 7.2 asks for none rather than no new ones. The version moves to 1.7, not 2.0, although 9.2 asks a major number for a tightened rule, as #1802's other amendments kept the major number. The team approved it in a meeting on 2026-11-20 (9.3).*

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

## Article X: Page Layout

### 10.1 A scrolling page's content needs no bounded height

A scrolling page is a `StyledAppPageView` with `scrollable: true`, or a `StyledAppPageView.innerPage`, which scrolls unless it is given `scrollable: false`. It is laid out with no height limit, so it is as tall as its content. Its content is laid out with no height limit as well and, when it comes out shorter than the rest of the window, laid out again with the rest of the window as its maximum (`FitOrGrow`, in `plugins/widgets/lib/widgets/page/layout/`). Nothing above it asks for an intrinsic height: PrivacyGUI-Widgets v1.2.11 removed the `IntrinsicHeight` that did, because a child can report a smaller intrinsic height than it lays out to, and the page then came out too short (#1864).

So in a scrolling page's content, unless a widget in between bounds the height:

- No `Expanded`, `Spacer` or `Flexible` in a `Column` or another vertical `Flex`. Without a height limit they throw in debug. To keep something at the bottom of a short page, give it a `FillColumn` slot, as the mobile layout of `lib/page/health_check/views/speed_test_view.dart` does, and space the `FillColumn`'s own children with `SizedBox`: a `Gap` needs a `Flex`, and `FillColumn` is not one. A list or a grid takes its real height, with `shrinkWrap: true`, instead of a fixed height that only an `Expanded` made work.
- No `LayoutBuilder` whose tree depends on the height. A short page's content is laid out twice, with two different height limits, so such a builder builds a different tree each time, and the state in it is lost.

A `SizedBox` or a `Container` with a `height`, or a `ConstrainedBox` with a `maxHeight`, bounds what is under it. A dialog or a bottom sheet is not part of the page. A page that does not scroll is not covered: its content has the window's height, and an `Expanded` in it works.

This article has no exceptions. When it was added, the code of every scrolling page under `lib/page/` was read, and the pages with a `testLocalizations` case were also measured by #1802's layout measurement. The seven pages that broke it were fixed in the same change (#1864).

**Enforced by**: CI for the first point, on a page with a case: `1.x / Layout Gate` runs the `testLocalizations` cases (#1802 P3, 3.5), and a breach there throws, so the case fails. Review for the first point elsewhere, and for the second point, which throws nothing.

*Amended 2026-11-19 (#1864): new article. Scrolling pages no longer size their content by `IntrinsicHeight`, and these are the two rules that change brings (#1864, Decision 4). A rule is added, for which 9.2 asks a major number. The version moves to 1.5 instead, as #1802's amendments kept the major number, so that the 1.x constitution does not read as 2.x. The team approved it in a meeting on 2026-11-19 (9.3).*

---

## Article XI: E2E Test Hooks (Semantics Identifiers)

1.x is tested end to end with Playwright against a release web build. The build draws on a canvas, so a test reaches a widget only through the semantics tree, which the web engine mirrors in the DOM. A control that a test drives needs a hook there that is stable, silent to screen readers, and the same in every locale.

This article follows 2.x's Article XVI, and each section names the 2.x section it matches. 2.x's E2E repository and its selector generator have no counterpart in 1.x.

### 11.1 `identifier`, not `semanticLabel` (2.x 16.1)

The hook is an `identifier`: the `identifier` parameter of a component that forwards it, or a raw `Semantics(identifier:)`. The web engine writes it as the DOM attribute `flt-semantics-identifier`, which Playwright locates.

| Property | In the DOM | Screen reader | Changes with |
|---|---|---|---|
| `identifier` | `flt-semantics-identifier` | Silent | Nothing |
| `semanticLabel` | `aria-label` | Read aloud | The locale and the copy |

`semanticLabel` holds only screen-reader text from the ARB files, read through `loc(context)` (6.1). It never holds a test string (issue #1935, Decision 1).

```dart
// Right: silent, and the same in every locale.
AppIconButton(
  icon: Icons.add,
  identifier: 'pf-add',
  onTap: _add,
)

// Wrong: read aloud, in English in every locale.
AppIconButton(
  icon: Icons.add,
  semanticLabel: 'add rule',
  onTap: _add,
)
```

#### 11.1.1 A component that forwards `identifier` (2.x 16.1.1)

The hook is `identifier`. A test string goes in no `semanticLabel`, and a control does not carry both an `identifier` and a `semanticLabel` that repeats it for tests: remove the `semanticLabel`.

#### 11.1.2 A component that does not forward it (replaces 2.x 16.1.2)

2.x tolerates a kebab-case `semanticLabel` as the hook of a component without `identifier` passthrough. 1.x does not: a `semanticLabel` is never the fallback.

The component gets passthrough in `plugins/widgets` instead (11.4), and until it does, a page's call of it keeps its row in the 11.2 table. A raw `Semantics(identifier:)` around the call does not take the call out of the table: the identifier belongs on the component, and the page scanner counts an `identifier:` on the call only.

A raw `Semantics(container: true, identifier:)` is the hook where no component is involved, such as a raw `InkWell` or `GestureDetector`, and it is how a component puts its identifier on a node of its own (11.4). It takes `identifier:`, never `label:`: a `label` is read aloud.

#### 11.1.3 Literal `semanticLabel` strings (no 2.x counterpart)

Before this article, 1.x located controls by `semanticLabel`. Flutter has `identifier` since 3.19, but the web engine writes it to the DOM only from 3.24 (flutter/engine PR #53278), and 1.x moved to 3.19.2 in 2024-08. Those labels are hard-coded English: a screen reader reads them in English in every locale, and on a control with visible text the string replaces the translated text.

They are converted page by page into an `identifier` (issue #1935, Decision 7):

- on a control with visible text, the `semanticLabel` is removed;
- on a control without, such as an icon button or a switch whose label is a separate text, it stays for later accessibility work.

The table lists, as a file and a count, every string literal in `lib/` that a `semanticLabel:` can hold: the argument itself, either branch of a conditional, or either side of `??`. Each literal counted is an exception. Lowering a count or deleting a row deletes exceptions because the code was fixed, which is not an amendment (9.1); raising a count or adding a row adds one, which is.

<!-- semantic-label-literals:begin -->
| File | Literals |
|---|---|
| `lib/page/advanced_settings/administration/views/administration_settings_view.dart` | `6` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/port_range_forwarding_rule_view.dart` | `2` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/port_range_triggering_rule_view.dart` | `1` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/single_port_forwarding_rule_view.dart` | `2` |
| `lib/page/advanced_settings/dmz/views/dmz_settings_view.dart` | `4` |
| `lib/page/advanced_settings/firewall/views/firewall_view.dart` | `9` |
| `lib/page/advanced_settings/firewall/views/ipv6_port_service_rule_view.dart` | `2` |
| `lib/page/advanced_settings/internet_settings/views/internet_settings_view.dart` | `13` |
| `lib/page/advanced_settings/local_network_settings/views/dhcp_reservations_edit_view.dart` | `2` |
| `lib/page/advanced_settings/local_network_settings/views/dhcp_reservations_view.dart` | `2` |
| `lib/page/advanced_settings/local_network_settings/views/dhcp_server_view.dart` | `6` |
| `lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart` | `2` |
| `lib/page/advanced_settings/static_routing/static_routing_list_view.dart` | `2` |
| `lib/page/advanced_settings/static_routing/static_routing_rule_view.dart` | `3` |
| `lib/page/components/base_components/option_card.dart` | `1` |
| `lib/page/components/shared_widgets.dart` | `2` |
| `lib/page/components/styled/menus/widgets/bottom_navigation_menu.dart` | `1` |
| `lib/page/components/widgets/wifi_qr/wifi_qr_cards.dart` | `2` |
| `lib/page/components/widgets/wifi_qr/wifi_qr_warning_card.dart` | `2` |
| `lib/page/dashboard/views/components/networks.dart` | `3` |
| `lib/page/dashboard/views/components/port_and_speed.dart` | `3` |
| `lib/page/dashboard/views/components/quick_panel.dart` | `1` |
| `lib/page/dashboard/views/components/wifi_grid.dart` | `3` |
| `lib/page/firmware_update/views/firmware_update_process_view.dart` | `1` |
| `lib/page/firmware_update/views/firmware_update_table.dart` | `1` |
| `lib/page/instant_admin/views/instant_admin_view.dart` | `3` |
| `lib/page/instant_admin/views/timezone_view.dart` | `2` |
| `lib/page/instant_device/views/device_detail_view.dart` | `1` |
| `lib/page/instant_device/views/device_list_widget.dart` | `2` |
| `lib/page/instant_privacy/views/instant_privacy_view.dart` | `4` |
| `lib/page/instant_safety/views/instant_safety_view.dart` | `1` |
| `lib/page/instant_setup/model/impl/guest_wifi_step.dart` | `1` |
| `lib/page/instant_setup/model/impl/night_mode_step.dart` | `1` |
| `lib/page/instant_setup/model/impl/personal_wifi_step.dart` | `1` |
| `lib/page/instant_setup/pnp_admin_view.dart` | `3` |
| `lib/page/instant_setup/pnp_setup_view.dart` | `3` |
| `lib/page/instant_setup/troubleshooter/views/call_support/call_support_main_region_view.dart` | `1` |
| `lib/page/instant_setup/troubleshooter/views/call_support/call_support_more_region_view.dart` | `1` |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_static_ip_view.dart` | `5` |
| `lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart` | `1` |
| `lib/page/instant_setup/troubleshooter/views/pnp_waiting_modem_view.dart` | `1` |
| `lib/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart` | `3` |
| `lib/page/instant_topology/views/widgets/tree_node_item.dart` | `1` |
| `lib/page/instant_verify/views/components/ping_network_modal.dart` | `1` |
| `lib/page/instant_verify/views/components/speed_test_widget.dart` | `2` |
| `lib/page/instant_verify/views/instant_verify_view.dart` | `7` |
| `lib/page/login/views/local_router_recovery_view.dart` | `1` |
| `lib/page/nodes/views/node_detail_view.dart` | `3` |
| `lib/page/troubleshooting/views/troubleshooting_view.dart` | `2` |
| `lib/page/wifi_settings/views/mac_filtered_devices_view.dart` | `1` |
| `lib/page/wifi_settings/views/mac_filtering_view.dart` | `1` |
| `lib/page/wifi_settings/views/widgets/guest_wifi_card.dart` | `3` |
| `lib/page/wifi_settings/views/widgets/main_wifi_card.dart` | `6` |
| `lib/page/wifi_settings/views/widgets/wifi_name_field.dart` | `2` |
| `lib/page/wifi_settings/views/widgets/wifi_password_field.dart` | `2` |
| `lib/page/wifi_settings/views/wifi_advanced_settings_view.dart` | `5` |
| `lib/page/wifi_settings/views/wifi_list_simple_mode_view.dart` | `2` |
| `lib/page/wifi_settings/views/wifi_list_view.dart` | `2` |
| `lib/page/wifi_settings/views/wifi_share_detail_view.dart` | `1` |
<!-- semantic-label-literals:end -->

### 11.2 When an identifier is required (2.x 16.2)

Every `App*` call under `lib/page/` that gets an interaction callback passes an `identifier` (issue #1935, Decision 3):

- An `App*` call is a call of any constructor of a class whose name is `App` and a capital: `AppCard` and `AppTextButton.noPadding`, not `AppsGamingSettingsView`.
- An interaction callback is any named argument `on…` (`onTap`, `onChanged`, `onFocusChanged`, `onSubmitted`, …) that is not the literal `null`.

A labelled button needs one too. Its text is ARB copy, so a test that finds it by its text fails in other locales and on the next copy change.

Something a test only reads or waits for, such as a status, an error, a snackbar or a dialog, gets an identifier when a test needs it, as in 2.x 16.2. Content that no test touches gets none: static text, headings, decorative icons, layout containers.

**The page bottom bar** (issue #1935, Decision 6). The buttons of `PageBottomBar` are `page-save` and `page-cancel`, as in 2.x. Those stand for their default labels, `loc(context).save` and `loc(context).cancel`. A bottom bar that passes another label, as `positiveLabel` or `negitiveLable`, passes its own identifier with it, as `positiveIdentifier` or `negativeIdentifier`, such as `speed-test-again`.

Unlike 2.x 16.2, the rule applies to the calls that predate it. Those are rows in the table: one per file under `lib/page/`, with the count of its findings. A finding is an `App*` call that breaks the rule above, an identifier literal that breaks 11.3, or a bottom bar that breaks its rule. Each finding counted is an exception. Lowering a count or deleting a row deletes exceptions because the code was fixed, which is not an amendment (9.1); raising a count or adding a row adds one, which is.

<!-- identifier-pages:begin -->
| File | Findings |
|---|---|
| `lib/page/advanced_settings/administration/views/administration_settings_view.dart` | `6` |
| `lib/page/advanced_settings/advanced_settings_view.dart` | `8` |
| `lib/page/advanced_settings/apps_and_gaming/ddns/views/ddns_settings_view.dart` | `2` |
| `lib/page/advanced_settings/apps_and_gaming/ddns/views/dyn_ddns_form.dart` | `7` |
| `lib/page/advanced_settings/apps_and_gaming/ddns/views/no_ip_ddns_form.dart` | `3` |
| `lib/page/advanced_settings/apps_and_gaming/ddns/views/tzo_ddns_form.dart` | `3` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/port_range_forwarding_list_view.dart` | `7` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/port_range_forwarding_rule_view.dart` | `7` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/port_range_triggering_list_view.dart` | `7` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/port_range_triggering_rule_view.dart` | `6` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/single_port_forwarding_list_view.dart` | `7` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/single_port_forwarding_rule_view.dart` | `8` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/widgets/add_rule_card.dart` | `1` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/widgets/protocol_utils.dart` | `3` |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/widgets/rule_item_card.dart` | `1` |
| `lib/page/advanced_settings/dmz/views/dmz_settings_view.dart` | `8` |
| `lib/page/advanced_settings/firewall/views/firewall_view.dart` | `9` |
| `lib/page/advanced_settings/firewall/views/ipv6_port_service_list_view.dart` | `8` |
| `lib/page/advanced_settings/firewall/views/ipv6_port_service_rule_view.dart` | `7` |
| `lib/page/advanced_settings/internet_settings/views/auto_ipoe_section.dart` | `4` |
| `lib/page/advanced_settings/internet_settings/views/internet_settings_view.dart` | `40` |
| `lib/page/advanced_settings/local_network_settings/views/dhcp_reservations_edit_view.dart` | `6` |
| `lib/page/advanced_settings/local_network_settings/views/dhcp_reservations_view.dart` | `7` |
| `lib/page/advanced_settings/local_network_settings/views/dhcp_server_view.dart` | `11` |
| `lib/page/advanced_settings/local_network_settings/views/local_network_settings_view.dart` | `3` |
| `lib/page/advanced_settings/static_routing/static_routing_list_view.dart` | `2` |
| `lib/page/advanced_settings/static_routing/static_routing_rule_view.dart` | `5` |
| `lib/page/advanced_settings/static_routing/static_routing_view.dart` | `8` |
| `lib/page/advanced_settings/widgets/internet_setting_card.dart` | `1` |
| `lib/page/auto_ipoe/views/auto_ipoe_optional_pane.dart` | `1` |
| `lib/page/auto_ipoe/views/auto_ipoe_recovery_ui.dart` | `6` |
| `lib/page/components/customs/hidden_password_widget.dart` | `1` |
| `lib/page/components/pwa/install_prompt_banner.dart` | `2` |
| `lib/page/components/pwa/ios_install_instruction_sheet.dart` | `1` |
| `lib/page/components/pwa/mac_safari_install_instruction_sheet.dart` | `1` |
| `lib/page/components/shortcuts/dialogs.dart` | `16` |
| `lib/page/components/styled/general_settings_widget/general_settings_widget.dart` | `6` |
| `lib/page/components/styled/remote_assistance/remote_assistance_dialog.dart` | `1` |
| `lib/page/components/styled/styled_page_view.dart` | `3` |
| `lib/page/components/styled/styled_tab_page_view.dart` | `2` |
| `lib/page/components/styled/top_bar.dart` | `2` |
| `lib/page/components/widgets/wifi_qr/wifi_qr_cards.dart` | `6` |
| `lib/page/components/widgets/wifi_qr/wifi_qr_warning_card.dart` | `2` |
| `lib/page/dashboard/views/components/home_title.dart` | `1` |
| `lib/page/dashboard/views/components/internet_status.dart` | `1` |
| `lib/page/dashboard/views/components/networks.dart` | `1` |
| `lib/page/dashboard/views/components/port_and_speed.dart` | `5` |
| `lib/page/dashboard/views/components/quick_panel.dart` | `1` |
| `lib/page/dashboard/views/components/wifi_grid.dart` | `7` |
| `lib/page/dashboard/views/dashboard_menu_view.dart` | `2` |
| `lib/page/firmware_update/views/firmware_update_detail_view.dart` | `1` |
| `lib/page/health_check/views/speed_test_external.dart` | `4` |
| `lib/page/health_check/views/speed_test_view.dart` | `2` |
| `lib/page/instant_admin/views/instant_admin_view.dart` | `10` |
| `lib/page/instant_admin/views/manual_firmware_update_view.dart` | `2` |
| `lib/page/instant_admin/views/timezone_view.dart` | `4` |
| `lib/page/instant_device/views/device_detail_view.dart` | `6` |
| `lib/page/instant_device/views/device_list_widget.dart` | `3` |
| `lib/page/instant_device/views/devices_filter_widget.dart` | `1` |
| `lib/page/instant_device/views/instant_device_view.dart` | `8` |
| `lib/page/instant_device/views/select_device_view.dart` | `3` |
| `lib/page/instant_privacy/views/instant_privacy_view.dart` | `6` |
| `lib/page/instant_safety/views/instant_safety_view.dart` | `4` |
| `lib/page/instant_setup/model/impl/guest_wifi_step.dart` | `1` |
| `lib/page/instant_setup/model/impl/night_mode_step.dart` | `1` |
| `lib/page/instant_setup/model/impl/personal_wifi_step.dart` | `2` |
| `lib/page/instant_setup/model/impl/safe_browsing_step.dart` | `2` |
| `lib/page/instant_setup/model/impl/your_network_step.dart` | `1` |
| `lib/page/instant_setup/model/pnp_step.dart` | `2` |
| `lib/page/instant_setup/pnp_admin_view.dart` | `6` |
| `lib/page/instant_setup/pnp_setup_view.dart` | `3` |
| `lib/page/instant_setup/troubleshooter/views/call_support/call_support_main_region_view.dart` | `1` |
| `lib/page/instant_setup/troubleshooter/views/call_support/call_support_more_region_view.dart` | `1` |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_ipoe_view.dart` | `1` |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_auth_view.dart` | `4` |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_type_selection_view.dart` | `3` |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_pppoe_view.dart` | `3` |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_static_ip_view.dart` | `7` |
| `lib/page/instant_setup/troubleshooter/views/pnp_modem_lights_off_view.dart` | `2` |
| `lib/page/instant_setup/troubleshooter/views/pnp_no_internet_connection_view.dart` | `4` |
| `lib/page/instant_setup/troubleshooter/views/pnp_unplug_modem_view.dart` | `2` |
| `lib/page/instant_setup/troubleshooter/views/pnp_waiting_modem_view.dart` | `1` |
| `lib/page/instant_setup/widgets/pnp_auto_master_waiting_view.dart` | `1` |
| `lib/page/instant_setup/widgets/pnp_stepper.dart` | `1` |
| `lib/page/instant_setup/widgets/wifi_password_widget.dart` | `1` |
| `lib/page/instant_setup/widgets/wifi_ssid_widget.dart` | `1` |
| `lib/page/instant_topology/views/instant_topology_view.dart` | `7` |
| `lib/page/instant_topology/views/widgets/tree_node_item.dart` | `2` |
| `lib/page/instant_verify/views/components/ping_network_modal.dart` | `3` |
| `lib/page/instant_verify/views/components/speed_test_external_widget.dart` | `4` |
| `lib/page/instant_verify/views/components/speed_test_widget.dart` | `3` |
| `lib/page/instant_verify/views/components/traceroute_modal.dart` | `3` |
| `lib/page/instant_verify/views/instant_verify_view.dart` | `4` |
| `lib/page/login/views/local_reset_router_password_view.dart` | `5` |
| `lib/page/login/views/local_router_recovery_view.dart` | `2` |
| `lib/page/login/views/login_cloud_auth_view.dart` | `3` |
| `lib/page/login/views/login_local_view.dart` | `3` |
| `lib/page/nodes/views/add_nodes_view.dart` | `7` |
| `lib/page/nodes/views/blink_node_light_widget.dart` | `1` |
| `lib/page/nodes/views/change_node_name_view.dart` | `2` |
| `lib/page/nodes/views/node_detail_view.dart` | `13` |
| `lib/page/nodes/views/node_name_edit_view.dart` | `1` |
| `lib/page/nodes/views/node_restart_view.dart` | `2` |
| `lib/page/troubleshooting/views/troubleshooting_ping_view.dart` | `2` |
| `lib/page/troubleshooting/views/troubleshooting_view.dart` | `12` |
| `lib/page/vpn/views/vpn_settings_page.dart` | `17` |
| `lib/page/vpn/views/vpn_status_tile.dart` | `2` |
| `lib/page/wifi_settings/views/mac_filtered_devices_view.dart` | `8` |
| `lib/page/wifi_settings/views/mac_filtering_view.dart` | `2` |
| `lib/page/wifi_settings/views/widgets/guest_wifi_card.dart` | `3` |
| `lib/page/wifi_settings/views/widgets/main_wifi_card.dart` | `8` |
| `lib/page/wifi_settings/views/widgets/wifi_name_field.dart` | `1` |
| `lib/page/wifi_settings/views/widgets/wifi_password_field.dart` | `1` |
| `lib/page/wifi_settings/views/widgets/wifi_qr_dialog.dart` | `1` |
| `lib/page/wifi_settings/views/widgets/wifi_setting_modal_mixin.dart` | `12` |
| `lib/page/wifi_settings/views/wifi_advanced_settings_view.dart` | `7` |
| `lib/page/wifi_settings/views/wifi_list_simple_mode_view.dart` | `3` |
| `lib/page/wifi_settings/views/wifi_list_view.dart` | `3` |
| `lib/page/wifi_settings/views/wifi_share_detail_view.dart` | `1` |
<!-- identifier-pages:end -->

### 11.3 Naming (2.x 16.3)

An identifier is kebab-case `{page-or-feature}-{control}[-{instance-key}]`, with no `now-` prefix: `login-password`, `pf-add`, `pf-edit-web-server` (issue #1935, Decision 4).

- A feature that 2.x also has uses 2.x's prefix, such as `pf-` for port forwarding.
- An instance key comes from the item's data, through a pure function with unit tests (3.2), and never from a row index or translated text. `pf-edit-0` is a position wearing an identifier's name, and `'menu-${title.kebab()}'`, with `title` from `loc(context)`, is a different identifier in every locale.
- A part of a composite component is `{parent identifier}-{part}`, such as `login-password-visibility` (issue #1935, Decision 5). An identifier does not change with state: the password field's toggle is `-visibility` whether it shows or hides the password. An index is allowed only in a fixed structure, such as the four octets of an IP address field, `{id}-octet-0` to `{id}-octet-3`.

The page scanner checks every string literal under `lib/page/` passed as `identifier:`, or as an argument whose name ends in `Identifier`, such as `positiveIdentifier:`: one that is not kebab-case, or starts with `now-`, is a finding in the 11.2 table. An interpolated expression counts as a word. Where a key comes from is review.

### 11.4 Layers (2.x 16.4)

- **`plugins/widgets`** owns passthrough (issue #1935, Decision 2). Every component accepts `identifier` and makes it reach the DOM, except pure layout, spacing and animation helpers. A change goes on a new PrivacyGUI-Widgets branch cut from the version that `plugins/widgets` pins, as `v1.2.11` to `v1.2.13` were, and the app's PR moves the submodule (issue #1935, Decision 9).
- **`lib/`** owns the identifier values, including those on raw `Semantics(identifier:)` nodes.

An identifier is a contract with the tests that locate it: a change that renames one changes those tests too. So does a change that moves a hook from `semanticLabel` to `identifier`, even with the same string: a test that found the control by its label, as `find.bySemanticsLabel` or by accessible name, has to find it by `find.bySemanticsIdentifier` or by `flt-semantics-identifier` instead (2.x 16.4).

**The 3.27.2 web engine drops the identifier of a text field node.** `SemanticRole.update()` returns before it writes `flt-semantics-identifier` when the role has no behaviours, and among the engine's roles only the text field role has none (`flutter_web_sdk/lib/_engine/engine/semantics/semantics.dart` and `text_field.dart` in the SDK cache). The heading, image, slider and route roles add behaviours, so they keep the attribute. The engine picks the role from the node's flags and actions: a node with `isTextField` is a text field unless it is a platform view or a heading, which it checks first. Later engines fixed this. A component therefore puts the identifier on a node of its own:

- Around a text field, `Semantics(container: true, explicitChildNodes: true, identifier:)`. With `container: true` alone, the wrapper merges into the text field node, and the attribute is dropped again. `explicitChildNodes: true` keeps the text field a child node.
- Around any other control, `Semantics(container: true, identifier:)` is enough.
- Each octet of `AppIPFormField` is a text field of its own, so each one needs the text field wrapper.

A widget test does not see this by itself: `find.bySemanticsIdentifier` finds an identifier on a text field node, which the browser drops.

**The roster.** `test/constitution/widget_identifier_roster_test.dart` pumps every public constructor of each component in its roster with an identifier, and checks each identifier the component exposes: `find.bySemanticsIdentifier` finds one node, and the node the engine receives, which is that node or the parent it merges into, carries the identifier and is not a text field. PrivacyGUI-Widgets has no CI of its own, and 7.1 leaves `plugins/**` out of analysis, so this test in this repository is what holds a component to passthrough.

The roster holds the components the pilot pages use (issue #1935); issue #1936 adds the rest. An identifier that a component does not expose yet, from every constructor, is a row of the table: the component, the identifier as a pattern over `{id}`, and why. Deleting a row because the component was fixed is not an amendment (9.1). Adding one is.

<!-- identifier-roster:begin -->
| Component | Identifier | Why |
|---|---|---|
<!-- identifier-roster:end -->

### 11.5 Code review checklist (2.x 16.5)

Review checks that:

- every control a test drives has an `identifier`, labelled buttons included, and also where the page scanner cannot see it: a raw `InkWell` or `GestureDetector`, or a text field with a controller and no callback (11.2);
- no `semanticLabel` holds a test string, and no control carries both an `identifier` and a `semanticLabel` that repeats it (11.1.1);
- a raw `Semantics` hook takes `identifier:`, not `label:` (11.1.2);
- a change that renames an identifier, or moves a hook from `semanticLabel` to `identifier`, changes the tests that locate it in the same change (11.4);
- identifiers follow 11.3, and an instance key comes from the item's data through a pure, unit-tested function, never from a row index or translated text;
- content that no test touches has no identifier (11.2);
- a new or changed component in `plugins/widgets` passes the roster, or has its row (11.4).

**Enforced by**: Test, for the three tables; review for the rest (11.5).

- `test/constitution/e2e_identifier_test.dart` compares what its scanners find in `lib/` with the tables in 11.1.3 and 11.2. It fails when a file's findings have no row, or a different count, and when a row no longer matches. It lists each finding of a file whose count is wrong, by line.
- `test/constitution/widget_identifier_roster_test.dart` compares the roster with the table in 11.4. It fails when a component has no row for an identifier it does not expose, when a row's identifier is exposed now, and when a row names no component and identifier in the roster.
- `test/constitution/identifier_scanner_test.dart` and `semantics_identifier_test.dart` test the scanners and the check on the node the engine receives. The latter also holds that check to what a browser showed: the wrappers above.

As in 1.5, the tests cannot tell a new row from an old one. That the tables only shrink is enforced by Article IX.

*Amended 2026-11-25 (#1935): new article. E2E tests locate 1.x controls by `identifier` instead of `semanticLabel`, now that Flutter 3.27.2 writes it to the DOM (issue #1935, Decisions 1 to 8). It follows 2.x Article XVI, without 16.1.2's `semanticLabel` fallback and without 2.x's E2E repository. A rule is added, for which 9.2 asks a major number. The version moves to 1.9 instead, as Articles VII and X kept the major number (issue #1935, Decision 10). The team decides whether that holds (9.3).*

---

## Not Covered

### Not carried over from 2.x

2.x's `constitution.md` was the reference, but these articles describe 2.x's architecture, not 1.x's:

- **IV** (USP provider architecture): 1.x talks JNAP.
- **VI** and **XIII** (service layer, `ServiceError`): 1.x notifiers call `RouterRepository` directly, and its errors are `JNAPError`, `JNAPSideEffectError` and the retry exceptions in `lib/core/`. Requiring a service layer would be a refactor, not a description of the code.
- **XIV** and **XV** (layout blocks, the UI kit principle): 1.x has no `ui_kit_library`.
- **XVII** (app modes).

Article XVI (E2E semantics identifiers) is carried over as Article XI.

### Deferred

Rules for `plugins/widgets` components other than Article XI's, and for app modes such as remote assistance, are to be evaluated after issue #1804 (Decision 3).
