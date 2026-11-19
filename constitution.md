# The 1.x Constitution

**Version:** 1.5
**Last amended:** 2026-11-19 (#1864, scrolling pages without `IntrinsicHeight`)
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
| III | Tests run through `run_tests.sh`; changes ship tests; screenshot tests and mocks follow one pattern | Test for where screenshot checks live and for the layout gate's roster; CI for #1803's coverage floor and for the layout gate; review for the rest |
| IV | Feature state lives in `Notifier` / `AsyncNotifier`; `…State` classes extend `Equatable` | Review |
| V | File, class, provider and directory names | Review |
| VI | User-visible strings come from the ARB files | CI for missing keys; review for hard-coded strings |
| VII | Zero analyzer errors; no new warnings | CI for errors; review for warnings |
| VIII | Simplicity; no wrappers around the framework; stay in scope | Review |
| IX | Amendments state version, date and reason; the team approves them | Team approval |
| X | A scrolling page's content needs no bounded height | CI for flex children on pages with a case, through #1802's layout gate; review for the rest |

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

The gate's case is a `testLocalizations` case (3.5). A page has one when a `testLocalizations` suite constructs its class. A page that a case reaches only as a tab of its parent does not count: `TabBarView` lays out the selected tab only.

The table lists the pages that have no case. A row whose reason starts "No case yet" waits for #1802 P6 to give the page one; every other row says why the page needs none. Deleting a row because the page got a case, or was deleted, is not an amendment (9.1).

<!-- layout-gate-roster:begin -->
| Page | Class | Why |
|---|---|---|
| `lib/page/advanced_settings/apps_and_gaming/ddns/views/ddns_settings_view.dart` | `DDNSSettingsView` | No case yet (#1802 P6). |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/port_range_forwarding_list_view.dart` | `PortRangeForwardingListView` | No case yet (#1802 P6). |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/port_range_triggering_list_view.dart` | `PortRangeTriggeringListView` | No case yet (#1802 P6). |
| `lib/page/advanced_settings/apps_and_gaming/ports/views/single_port_forwarding_list_view.dart` | `SinglePortForwardingListView` | No case yet (#1802 P6). |
| `lib/page/advanced_settings/firewall/views/ipv6_port_service_list_view.dart` | `Ipv6PortServiceListView` | No case yet (#1802 P6). |
| `lib/page/advanced_settings/local_network_settings/views/dhcp_reservations_edit_view.dart` | `DHCPReservationsEditView` | No case yet (#1802 P6). |
| `lib/page/advanced_settings/local_network_settings/views/dhcp_server_view.dart` | `DHCPServerView` | No case yet (#1802 P6). |
| `lib/page/advanced_settings/static_routing/static_routing_list_view.dart` | `StaticRoutingListView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/customs/network_check_view.dart` | `NetworkCheckView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/picker/day_picker_view.dart` | `DayPickerView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/picker/number_picker_view.dart` | `NumberPickerView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/picker/region_picker_view.dart` | `RegionPickerView` | Kept until #1849 deletes it: only the OTP flow opens it. |
| `lib/page/components/picker/time_picker_view.dart` | `TimePickerView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/components/settings_view/editable_card_list_edit_view.dart` | `EditableCardListEditView` | No case yet (#1802 P6). |
| `lib/page/components/settings_view/editable_card_list_settings_view.dart` | `EditableCardListsettingsView` | Permanent: a component, not a page. The advanced settings lists (ports, IPv6 port service, static routing) build it, so their cases sweep it. |
| `lib/page/components/settings_view/editable_table_settings_view.dart` | `AppEditableTableSettingsView` | Permanent: a component, not a page. The advanced settings lists (ports, IPv6 port service, static routing) build it, so their cases sweep it. |
| `lib/page/components/styled/styled_tab_page_view.dart` | `StyledAppTabPageView` | Permanent: a layout that `StyledAppPageView` builds for tabbed pages, not a page. |
| `lib/page/components/views/arguments_view.dart` | `ArgumentsBaseConsumerStatefulView` | Permanent: a base class for views, not a page. |
| `lib/page/components/views/write_flow_blocked_view.dart` | `WriteFlowBlockedView` | No case yet (#1802 P6). |
| `lib/page/dashboard/views/dashboard_settings_view.dart` | `DashboardSettingsView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/dashboard/views/dashboard_support_view.dart` | `DashboardSupportView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/dashboard/views/prepare_dashboard_view.dart` | `PrepareDashboardView` | No case yet (#1802 P6). |
| `lib/page/firmware_update/views/firmware_update_process_view.dart` | `FirmwareUpdateProcessView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/health_check/views/speed_test_selection.dart` | `SpeedTestSelectionView` | No case yet (#1802 P6). |
| `lib/page/instant_setup/troubleshooter/views/call_support/call_support_main_region_view.dart` | `CallSupportMainRegionView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/instant_setup/troubleshooter/views/call_support/call_support_more_region_view.dart` | `CallSupportMoreRegionView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/instant_setup/troubleshooter/views/isp_settings/pnp_isp_auth_view.dart` | `PnpIspAuthView` | No case yet (#1802 P6). |
| `lib/page/landing/views/debug_device_info_view.dart` | `DebugDeviceInfoView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/landing/views/home_view.dart` | `HomeView` | Kept until #1849 deletes it: the home page, which never shows. |
| `lib/page/login/auto_parent/views/auto_parent_first_login_view.dart` | `AutoParentFirstLoginView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/login/views/login_cloud_auth_view.dart` | `LoginCloudAuthView` | No case yet (#1802 P6). |
| `lib/page/login/views/login_cloud_view.dart` | `LoginCloudView` | Kept until #1849 deletes it: the cloud account login and OTP, which 1.x does not use. |
| `lib/page/nodes/views/change_node_name_view.dart` | `ChangeNodeNameView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/nodes/views/node_light_guide_view.dart` | `NodeLightGuideView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/nodes/views/node_name_edit_view.dart` | `NodeNameEditView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/nodes/views/node_restart_view.dart` | `NodeRestartView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/otp_flow/views/otp_add_phone.dart` | `OtpAddPhoneView` | Kept until #1849 deletes it: the cloud account login and OTP, which 1.x does not use. |
| `lib/page/otp_flow/views/otp_code_input.dart` | `OtpCodeInputView` | Kept until #1849 deletes it: the cloud account login and OTP, which 1.x does not use. |
| `lib/page/otp_flow/views/otp_method_selector_view.dart` | `OTPMethodSelectorView` | Kept until #1849 deletes it: the cloud account login and OTP, which 1.x does not use. |
| `lib/page/otp_flow/views/otp_view.dart` | `OtpFlowView` | Kept until #1849 deletes it: the cloud account login and OTP, which 1.x does not use. |
| `lib/page/select_network/views/select_network_view.dart` | `SelectNetworkView` | Kept until #1849 deletes it: the cloud account login and OTP, which 1.x does not use. |
| `lib/page/troubleshooting/views/troubleshooting_ping_view.dart` | `TroubleshootingPingView` | No case yet (#1802 P6). |
| `lib/page/troubleshooting/views/troubleshooting_view.dart` | `TroubleshootingView` | No case yet (#1802 P6). |
| `lib/page/wifi_settings/views/mac_filtering_view.dart` | `MacFilteringView` | No case yet (#1802 P6). |
| `lib/page/wifi_settings/views/wifi_advanced_settings_view.dart` | `WifiAdvancedSettingsView` | No case yet (#1802 P6). |
| `lib/page/wifi_settings/views/wifi_list_advanced_mode_view.dart` | `AdvancedModeView` | No case yet (#1802 P6). |
| `lib/page/wifi_settings/views/wifi_list_simple_mode_view.dart` | `SimpleModeView` | No case yet (#1802 P6). |
| `lib/page/wifi_settings/views/wifi_list_view.dart` | `WiFiListView` | No case yet (#1802 P6). |
| `lib/page/wifi_settings/views/wifi_settings_channel_finder_view.dart` | `WifiSettingsChannelFinderView` | Permanent while unreachable: nothing in `lib/` builds it. Give it a case once something does. |
| `lib/page/wifi_settings/views/wifi_share_detail_view.dart` | `WiFiShareDetailView` | No case yet (#1802 P6). |
<!-- layout-gate-roster:end -->

**Enforced by**: Test. `test/constitution/layout_gate_roster_test.dart` fails when a page has no case and no row in the table above, and when a row's page has a case or is gone.

*Amended 2026-11-19 (#1802): the rule takes effect, with the roster test and a row for each page that has no case yet, so a page cannot be left out of the gate unnoticed. The version moves to 1.4, not 2.0, although 9.2 asks a major number for an added exception or a tightened rule. This section said the rule would take effect with #1802 P3, and the rows are the exceptions it starts with, not exceptions added to a rule already in force. Counting the five pages 5.1 names, and not counting a tab, follow what 5.1 and `TabBarView` already imply. The team decides whether that holds (9.3).*

### 3.4 A fix that ellipsizes ships a readability guard

A fix that makes text fit by ellipsizing it or capping `maxLines` ships a test at the width that forced the fix. The test asserts the text is still usable. For an IP, MAC, serial number, firmware version or SSID, that means `RenderParagraph.didExceedMaxLines` is false.

The overflow sweep cannot see this: adding `maxLines: 1` turns every overflowing row green and cuts `192.168.1.100` in the middle.

**Enforced by**: Review. #1802 P4 adds the first set of guards.

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

Exceptions: `PnpTroubleshooterState`, `SelectNetworkState`, `InstantTopologyState`.

**Enforced by**: Review.

---

## Article V: Naming

### 5.1 Files

- Dart files are `snake_case.dart`. The analyzer's `file_names` lint reports a breach as an info, which no check fails on.
- A page is `*_view.dart`. #1802's roster finds pages by this suffix, so a page named otherwise escapes the layout gate. Exceptions, each a page that `lib/route/` builds: `lib/page/vpn/views/vpn_settings_page.dart`, `lib/page/otp_flow/views/otp_add_phone.dart`, `lib/page/otp_flow/views/otp_code_input.dart`, `lib/page/health_check/views/speed_test_external.dart` and `lib/page/health_check/views/speed_test_selection.dart`.
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

**Enforced by**: CI, for keys: both checks run `flutter gen-l10n` during setup, before they analyze or test, so a key that is used but not defined fails `1.x / Analyze` with `undefined_getter`. A hard-coded string compiles, so that half is Review.

*Amended 2026-11-18 (#1802): names the check that fails, now that #1802 P1 has added it.*

---

## Article VII: Lint

### 7.1 Zero analyzer errors

`flutter analyze` reports no errors. Its rules come from `analysis_options.yaml`: `flutter_lints`, with `prefer_const_constructors` off. It leaves out `plugins/**`: `plugins/widgets` is a submodule from its own repository, `linksys/PrivacyGUI-Widgets`, and its diagnostics are fixed there.

*Amended 2026-11-18 (#1802): `analysis_options.yaml` excludes `plugins/**`, because `plugins/widgets` is fixed in its own repository (#1802, Decision 1). This adds no exception: rules for `plugins/widgets` were already deferred (Not Covered › Deferred), so the version moves to 1.1, not 2.0.*

### 7.2 Warnings are cleaned, not added

A change adds no analyzer warnings. The existing ones (246 when #1802 was filed, 221 once 7.1 left out `plugins/**`) are cleared in a dedicated PR (#1802, Decision 1), not mixed into feature changes, so that a feature's diff stays about the feature.

**Enforced by**: CI for errors: `1.x / Analyze` runs `flutter analyze --no-fatal-warnings --no-fatal-infos`, which fails on errors only. Review for warnings, until the backlog is cleared and the check can fail on them.

*Amended 2026-11-18 (#1802): names the check that runs the analyzer, now that #1802 P1 has added it, and gives the warning count once 7.1 left out `plugins/**`.*

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

## Not Covered

### Not carried over from 2.x

2.x's `constitution.md` was the reference, but these articles describe 2.x's architecture, not 1.x's:

- **IV** (USP provider architecture): 1.x talks JNAP.
- **VI** and **XIII** (service layer, `ServiceError`): 1.x notifiers call `RouterRepository` directly, and its errors are `JNAPError`, `JNAPSideEffectError` and the retry exceptions in `lib/core/`. Requiring a service layer would be a refactor, not a description of the code.
- **XIV** and **XV** (layout blocks, the UI kit principle): 1.x has no `ui_kit_library`.
- **XVI** and **XVII** (E2E semantics identifiers, app modes).

### Deferred

Rules for `plugins/widgets` components, for E2E identifiers in `integration_test/`, and for app modes such as remote assistance are to be evaluated after #1804 (Decision 3).
