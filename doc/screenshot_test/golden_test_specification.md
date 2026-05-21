# USP Golden Test Framework Design

## Overview

A declarative, automated golden test framework for all USP views in the PrivacyGUI project. Replaces the old golden test infrastructure with a new system designed around the FeatureState architecture.

### Goals

- Every visual state of every USP view has a corresponding golden screenshot
- Developers only write a declarative config per view; the framework handles the rest
- Automated validation ensures no view or state is missed
- Naming convention and directory structure are consistent and enforceable

### Non-Goals

- Testing business logic (covered by notifier unit tests)
- Testing navigation/routing between views
- End-to-end integration tests
- Testing state transitions caused by user interaction (covered by states map — see Interaction Scope)

---

## Architecture

### Core Principle

USP views are pure functions of provider state (no local `setState()`). Therefore:

> Exhausting all meaningful `FeatureState` combinations = exhausting all possible UI outputs.

Every user interaction that changes state results in a new `FeatureState` value — which is represented as a separate entry in the `states` map. Interactions are reserved for UI-layer overlays that don't change provider state.

### Components

```
GoldenTestConfig  -->  runViewGoldenTests()  -->  golden PNGs
       |                      |
       v                      v
  ProviderOverrides      _buildGoldenWidget()
  (per-feature mocks)   (shell wrapping + locale + screen size + theme)
```

---

## Declarative Config API

### GoldenTestConfig

```dart
class GoldenTestConfig {
  /// Unique view identifier — snake_case, readable name (e.g. 'firewall', 'port_forwarding_detail').
  final String viewName;

  /// Builder that returns the widget under test.
  final Widget Function() view;

  /// Shell wrapper type.
  final ShellType shell;

  /// State-driven tests: key = state name (snake_case), value = provider overrides setup.
  final Map<String, MockSetup> states;

  /// Interaction-driven tests (optional): for UI overlays that don't change provider state.
  final Map<String, Interaction>? interactions;

  /// Locales to test. Default: [Locale('en')]
  final List<Locale> locales;

  /// Screen sizes to test. Default: [GoldenDevice.phone480, GoldenDevice.desktop1280]
  final List<GoldenDevice> devices;

  /// Theme brightness modes to test. Default: [Brightness.light]
  final List<Brightness> themes;

  /// Optional fixed height override. When set, all devices use this height
  /// instead of their default. Useful for views with tall scrollable content.
  final double? height;
}

enum ShellType { pageView, scaffold, custom }

typedef MockSetup = void Function(List<Override> overrides);

class Interaction {
  final MockSetup setup;
  final Future<void> Function(WidgetTester tester) steps;
}
```

### State Key Naming Rules

State keys become part of the output filename (`{viewName}-{stateKey}-{device}-{locale}.png`), so they must be **descriptive and self-explanatory**.

| Rule | Bad | Good | Why |
|------|-----|------|-----|
| No generic `data` prefix | `data`, `data_all_off` | `all_on`, `all_off` | `data` carries no semantic meaning in a filename |
| Describe the visual state | `data_enabled` | `dhcp_enabled` | Reader should understand the screenshot content from the filename alone |
| Use the distinguishing characteristic | `data_1`, `data_2` | `idle`, `running`, `ping_result` | Each key should identify what makes this state visually unique |

#### Examples by Feature Type

| Feature Type | State Keys |
|--------------|-----------|
| Toggle feature | `enabled`, `disabled` or `all_on`, `all_off` |
| Connection mode | `dhcp`, `static_ip`, `pppoe`, `bridge` |
| List-based | `rules_list`, `empty` |
| Diagnostic tool | `idle`, `running`, `ping_result`, `traceroute_result` |
| Form page | `dhcp_enabled`, `dhcp_disabled`, `edit_dirty`, `validation_error` |
| Navigation menu | `menu` |

### Complete Example (Firewall)

#### Test file: `test/usp_test/page/firewall/localizations/usp_firewall_view_test.dart`

```dart
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/views/usp_firewall_view.dart';

import '../../../golden_framework/golden_runner.dart';
import '../../../golden_framework/golden_test_config.dart';
import '../../../golden_framework/mocks/mock_firewall.dart';
import '../fixtures/firewall_test_data.dart';

void main() {
  runViewGoldenTests(
    GoldenTestConfig(
      viewName: 'firewall',
      view: () => const UspFirewallView(),
      shell: ShellType.custom,
      states: {
        'all_on': (overrides) => overrides.addAll(
          firewallOverrides(dataState(allOnModel)),
        ),
        'all_off': (overrides) => overrides.addAll(
          firewallOverrides(dataState(allOffModel)),
        ),
        'edit_dirty': (overrides) => overrides.addAll(
          firewallOverrides(dirtyState()),
        ),
      },
    ),
  );
}
```

#### Fixtures: `test/usp_test/page/firewall/fixtures/firewall_test_data.dart`

```dart
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/services/usp_firewall_service.dart';

const allOnModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: true,
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

const allOffModel = FirewallUIModel(
  isIPv4FirewallEnabled: false,
  isIPv6FirewallEnabled: false,
  blockIPSec: true,
  blockPPTP: true,
  blockL2TP: true,
  blockAnonymousRequests: false,
  blockMulticast: false,
  blockIDENT: false,
);

const dirtyCurrentModel = FirewallUIModel(
  isIPv4FirewallEnabled: true,
  isIPv6FirewallEnabled: false,
  blockIPSec: false,
  blockPPTP: false,
  blockL2TP: false,
  blockAnonymousRequests: true,
  blockMulticast: true,
  blockIDENT: false,
);

FirewallFeatureState dataState(FirewallUIModel model) {
  final settings = FirewallSettings(
    model: model,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: const FirewallStatus(isLoading: false),
  );
}

FirewallFeatureState dirtyState({bool isSaving = false}) {
  final original = FirewallSettings(
    model: allOnModel,
    ruleContext: FirewallRuleContext.empty,
  );
  final current = FirewallSettings(
    model: dirtyCurrentModel,
    ruleContext: FirewallRuleContext.empty,
  );
  return FirewallFeatureState(
    settings: Preservable(original: original, current: current),
    status: FirewallStatus(isLoading: false, isSaving: isSaving),
  );
}

FirewallFeatureState get errorState => FirewallFeatureState(
  settings: Preservable(
    original: FirewallSettings.empty(),
    current: FirewallSettings.empty(),
  ),
  status: const FirewallStatus(
    isLoading: false,
    errorMessage: 'Connection failed',
  ),
);
```

#### Mock: `test/usp_test/golden_framework/mocks/mock_firewall.dart`

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/firewall/models/firewall_feature_state.dart';
import 'package:privacy_gui/page/firewall/models/firewall_settings.dart';
import 'package:privacy_gui/page/firewall/models/firewall_status.dart';
import 'package:privacy_gui/page/firewall/models/firewall_ui_model.dart';
import 'package:privacy_gui/page/firewall/providers/usp_firewall_notifier.dart';

class FixedFirewallNotifier extends UspFirewallNotifier {
  final FirewallFeatureState _fixedState;

  FixedFirewallNotifier(this._fixedState);

  @override
  FirewallFeatureState build() => _fixedState;

  @override
  Future<(FirewallSettings?, FirewallStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async => (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void updateSetting(FirewallUIModel Function(FirewallUIModel) updater) {}
}

/// Returns provider overrides for firewall golden tests.
List<Override> firewallOverrides(FirewallFeatureState state) => [
  uspFirewallProvider.overrideWith(() => FixedFirewallNotifier(state)),
];
```

### Tab Page Example (Wi-Fi Settings)

```dart
GoldenTestConfig(
  viewName: 'wifi_settings',
  view: () => const UspWifiSettingsView(),
  shell: ShellType.scaffold,
  states: {
    'loading': (overrides) => overrides.addAll(wifiOverrides(initialState)),
    'error': (overrides) => overrides.addAll(wifiOverrides(errorState)),
    'data': (overrides) => overrides.addAll(wifiOverrides(testWifiState)),
  },
  interactions: {
    'tab_guest': Interaction(
      setup: (overrides) => overrides.addAll(wifiOverrides(testWifiState)),
      steps: (tester) async {
        await tester.tap(find.text('Guest'));
        await tester.pumpAndSettle();
      },
    ),
  },
)
```

### Multi-locale Example

```dart
GoldenTestConfig(
  viewName: 'firewall',
  view: () => const UspFirewallView(),
  shell: ShellType.custom,
  locales: [Locale('en'), Locale('es'), Locale('ja')],
  devices: [GoldenDevice.phone480],
  states: { /* ... */ },
)
```

---

## Interaction Scope

Interactions are **strictly** for UI-layer overlays that do not mutate provider state:

- Opening a dialog or bottom sheet (e.g., `saving_spinner` via `showAppSpinnerDialog`)
- Switching tabs (tab bar visual state)
- Expanding/collapsing a dropdown or accordion
- Scrolling to reveal off-screen content
- Tapping error icons to reveal validation tooltips (e.g., `validation_error_tooltip`)

State changes caused by user actions (toggle, save, input) are represented as **separate entries in the `states` map**, because the view is a pure function of provider state.

### Interaction Naming

Interaction keys follow the same snake_case rule as state keys. Name them by what becomes visible:

| Interaction Key | Purpose |
|----------------|---------|
| `validation_error_tooltip` | Tap all error icons to show tooltip messages simultaneously |
| `saving_spinner` | Trigger the shared spinner dialog overlay |
| `tab_guest` | Switch to the guest tab |
| `dialog_add` | Open the "add item" dialog |

### Shared Interactions

UI components that are shared across multiple pages (e.g., the saving spinner dialog triggered by `doSomethingWithSpinner`) should be tested once in a shared test file (`test/usp_test/page/shared/shared_states_test.dart`) rather than duplicated in every feature test. Individual feature tests should NOT include a `saving` state — since the spinner is an imperative overlay (not provider-state-driven), it requires an interaction to capture, and testing it once is sufficient.

---

## Shell Type Selection

| ShellType | When to use | Background |
|-----------|-------------|------------|
| `scaffold` | Most pages — ensures white background matching production app | Wraps widget in `Scaffold`, inheriting theme's `scaffoldBackgroundColor` |
| `custom` | Pages that already have their own shell/scaffold structure (e.g., pages with custom app bars or nested scaffolds) | No additional wrapping — the widget must provide its own background |
| `pageView` | Tab-based page views | Wraps in page view container |

**Important**: Using `custom` on a page without its own `Scaffold` will expose the raw `Material 3` theme background (typically dark blue from the color seed), not the white background users see in production. When in doubt, use `scaffold`.

---

## Mock Strategy (Per-Feature FixedNotifier + Split Files)

Each feature provides a `FixedXxxNotifier` that subclasses the real Notifier, returns a fixed state from `build()`, and explicitly no-ops all mutation methods. This ensures full Riverpod lifecycle compatibility.

### File Structure

```
test/usp_test/golden_framework/
  mocks/
    mock_firewall.dart      // FixedFirewallNotifier + firewallOverrides()
    mock_wifi_settings.dart // FixedWifiSettingsNotifier + wifiOverrides()
    mock_common.dart        // commonOverrides() — shared across all views
  golden_test_config.dart
  golden_runner.dart
```

### Per-Feature Mock Example

See the complete Firewall example above for `mock_firewall.dart` implementation.

### Common Overrides

```dart
// test/usp_test/golden_framework/mocks/mock_common.dart

List<Override> commonOverrides() => [
  authProvider.overrideWith(() => FixedAuthNotifier()),
  appsCapabilityProvider.overrideWith((ref) => false),
];
```

### Why Not mockito/mocktail?

Golden tests only need to **feed a fixed state to the view for rendering**. They never need to verify that a method was called or assert on interaction counts — which is the core value proposition of mock libraries. Given this narrow requirement, using a third-party mock library introduces risk without providing meaningful benefit:

1. **Riverpod lifecycle compatibility** — Riverpod Notifiers depend on container-injected `ref` and internal `state` setters. A `Mock implements XxxNotifier` is not a real subclass; it bypasses the Notifier lifecycle. While this *usually* works for read-only scenarios, Riverpod version upgrades can silently break mock-based tests when internal type checks or lifecycle hooks change.

2. **Golden tests don't verify behavior** — mockito/mocktail shine at `verify(notifier.save()).called(1)`. Golden tests never call `verify` — they pump a widget and compare pixels. The library adds dependency weight for zero functional gain in this context.

3. **Stability over convenience** — A real subclass with explicit no-op methods will never break due to a third-party version bump. The 10-20 lines of boilerplate per feature is written once and doesn't change unless the Notifier's public API changes (which should be rare and intentional).

4. **Explicit is safer than implicit** — `noSuchMethod`-based mocks or auto-generated stubs silently return `null` for unimplemented methods. If a Notifier adds a new method that returns a non-nullable type, a mock will crash at runtime with an unhelpful error. An explicit subclass forces the developer to consciously handle each method.

### Design Summary

| Concern | Decision |
|---------|----------|
| Riverpod compatibility | Real subclass — no lifecycle issues with `ref`, `state` setter |
| Safety | Explicit no-op methods — no silent `null` returns from noSuchMethod |
| Scalability | Split files — minimal git conflicts, easy to find |
| Boilerplate | Acceptable: 10-20 lines per feature, written once |
| Mock library dependency | None — no risk from mocktail/mockito version changes |

---

## Test Fixtures

Shared test data (states, models) should be defined once and reused across unit tests and golden tests.

### Fixture Location

```
test/usp_test/page/firewall/
  fixtures/
    firewall_test_data.dart    // shared FeatureState instances, model constants
  localizations/
    usp_firewall_view_test.dart  // golden test — imports from fixtures/
```

### Principles

- Define meaningful state combinations in `fixtures/` once
- Golden tests and unit tests both import from the same fixtures
- Fixtures should only contain data construction, no test logic

---

## Auto Runner

### runViewGoldenTests()

Uses the `alchemist` package (`goldenTest` API) for golden rendering and comparison.

```dart
void runViewGoldenTests(GoldenTestConfig config) {
  _validateConfig(config);

  group('${config.viewName} golden tests', () {
    for (final stateEntry in config.states.entries) {
      for (final device in config.devices) {
        for (final locale in config.locales) {
          for (final theme in config.themes) {
            final effectiveHeight = config.height ?? device.size.height;
            final effectiveSize = Size(device.size.width, effectiveHeight);
            final name = _goldenFileName(
              config.viewName, stateEntry.key, device, locale, theme,
            );

            goldenTest(
              '${config.viewName} - ${stateEntry.key} - ${device.name} - ...',
              fileName: name,
              constraints: BoxConstraints.expand(
                width: effectiveSize.width,
                height: effectiveSize.height,
              ),
              pumpBeforeTest: (tester) async {
                // Multiple pumps for async provider initialization
                for (int i = 0; i < 5; i++) {
                  await tester.pump(const Duration(milliseconds: 50));
                }
              },
              pumpWidget: (tester, widget) async {
                _suppressOverflowErrors();
                await tester.binding.setSurfaceSize(effectiveSize);
                tester.view.physicalSize = effectiveSize;
                tester.view.devicePixelRatio = 1.0;
                await tester.pumpWidget(widget);
              },
              builder: () => _buildGoldenWidget(
                config.view(),
                config.shell,
                stateEntry.value,
                effectiveSize,
                locale,
                theme,
              ),
            );
          }
        }
      }
    }

    // Interactions follow the same loop pattern with additional steps
    if (config.interactions != null) {
      for (final interactionEntry in config.interactions!.entries) {
        // ... same device/locale/theme loops ...
        goldenTest(
          '...',
          fileName: name,
          constraints: BoxConstraints.expand(...),
          pumpBeforeTest: (tester) async {
            for (int i = 0; i < 5; i++) {
              await tester.pump(const Duration(milliseconds: 50));
            }
            await interactionEntry.value.steps(tester);
            await tester.pump(const Duration(milliseconds: 100));
          },
          pumpWidget: (tester, widget) async {
            _suppressOverflowErrors();
            await tester.binding.setSurfaceSize(effectiveSize);
            tester.view.physicalSize = effectiveSize;
            tester.view.devicePixelRatio = 1.0;
            await tester.pumpWidget(widget);
          },
          builder: () => _buildGoldenWidget(...),
        );
      }
    }
  });
}
```

### Key Implementation Details

- **`physicalSize` + `devicePixelRatio`**: Both must be set for `MediaQuery.sizeOf` to report the correct viewport width. `setSurfaceSize` alone only controls the screenshot capture surface, not the logical size seen by widgets.
- **Multiple pump cycles**: Async providers (especially those that read from SharedPreferences or perform post-frame callbacks) need multiple frames to initialize. 5×50ms pumps covers typical async initialization.
- **Interaction post-pump**: After executing interaction steps, `pump(Duration(milliseconds: 100))` fires any pending delayed timers (e.g., animation callbacks).
- **Overflow suppression**: `_suppressOverflowErrors()` prevents golden tests from failing due to cosmetic overflow — the overflow is visible in the golden image itself.

---

## Test Infrastructure

### flutter_test_config.dart

Located at `test/usp_test/flutter_test_config.dart`, this file is automatically loaded by the Flutter test runner for all tests under `test/usp_test/`. It configures:

1. **Alchemist config** — Disables CI goldens, enables platform goldens with `diffThreshold: 0.025`
2. **Font loading** — Loads real fonts so text renders readably (not Ahem blocks)

### Alchemist Configuration

```dart
AlchemistConfig(
  ciGoldensConfig: CiGoldensConfig(enabled: false),
  platformGoldensConfig: PlatformGoldensConfig(
    enabled: true,
    renderShadows: false,
    filePathResolver: (fileName, _) => 'goldens/$fileName.png',
    diffThreshold: 0.025,
  ),
)
```

- **`diffThreshold: 0.025`** — Allows up to 2.5% pixel difference. Required for tests involving non-deterministic animations (e.g., `JiggleShake` uses `Random()` without a seed for delay/direction). Without this tolerance, edit-mode tests would produce flaky failures.
- **`renderShadows: false`** — Shadows are platform-dependent; disabling them prevents cross-machine diffs.

### Font Loading

Flutter tests use the `Ahem` font by default, which renders all glyphs as black rectangles. To produce human-readable golden images:

```dart
// Load from ui_kit_library package (resolved via .dart_tool/package_config.json)
final mainFont = FontLoader('packages/ui_kit_library/NeueHaasGrotTextRound');
// Load .otf files from the resolved package path
```

The `packages/` prefix is required because the app references the font via the `ui_kit_library` package. `AppText` widgets inherit the theme's font correctly; raw `Text()` widgets do not unless explicitly styled.

### Portal Wrapper

`flutter_portal` (`Portal` widget) wraps the `MaterialApp.router` in `_buildGoldenWidget()`. This is required by UI Kit overlay components (tooltips, dropdowns) that use `PortalTarget`/`PortalFollower` instead of Flutter's built-in overlay.

### Dependencies

```yaml
dev_dependencies:
  alchemist: ^0.14.0        # Golden test framework (replaces golden_toolkit)
  flutter_portal: ^1.1.4    # Required by UI Kit overlay widgets
```

---

## Naming Convention

### Format

```
{view_name}-{state_key}-{device}-{locale}.png
```

When dark mode is included:
```
{view_name}-{state_key}-{device}-{locale}-dark.png
```

- **view_name**: snake_case, full readable name (e.g., `firewall`, `port_forwarding_detail`)
- **state_key**: snake_case, descriptive of the UI state
- **device**: Device name (e.g., `phone480`, `desktop1280`)
- **locale**: Language code (e.g., `en`, `ja`)
- **dark**: Suffix only present for dark mode screenshots (light is the default, no suffix)

### Examples

```
firewall-all_on-phone480-en.png
firewall-all_off-desktop1280-en.png
firewall-edit_dirty-phone480-en.png
local_network-dhcp_enabled-phone480-en.png
local_network-validation_error-desktop1280-en.png
local_network-validation_error_tooltip-phone480-en.png
internet_settings-pppoe-phone480-en.png
port_forwarding_detail-rules_list-desktop1280-en.png
static_routing-empty-phone480-en.png
wifi_settings-tab_guest-desktop1280-en.png
firewall-all_on-phone480-en-dark.png
```

---

## Validation

### Config Validation (runtime)

Built into `runViewGoldenTests()`:

```dart
void _validateConfig(GoldenTestConfig config) {
  // viewName: snake_case, non-empty
  assert(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(config.viewName));

  // At least one state must be defined
  assert(config.states.isNotEmpty, 'states must contain at least one entry (e.g., "data").');

  // All state/interaction keys: snake_case
  final allKeys = {...config.states.keys, ...?config.interactions?.keys};
  for (final key in allKeys) {
    assert(RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(key));
  }
}
```

### CI Script — Coverage Verification

```bash
#!/bin/bash
# ci/verify_golden_coverage.sh
# Verifies every USP view file has a corresponding golden test.

for view_file in lib/page/*/views/usp_*_view.dart; do
  feature=$(echo "$view_file" | sed 's|lib/page/\(.*\)/views/.*|\1|')
  test_pattern="test/usp_test/page/$feature/localizations/*_test.dart"
  if ! ls $test_pattern &>/dev/null 2>&1; then
    echo "FAIL $view_file: no golden test found"
    FAIL=1
  fi
done
```

### Validation Summary

| Layer | When | Catches |
|-------|------|---------|
| Config validation | Test execution | Wrong viewName format, empty states map, bad key naming |
| CI script | PR merge gate | Missing golden test files for USP views |

---

## Directory Structure

### Framework Code

```
test/usp_test/
  flutter_test_config.dart        # Alchemist config + font loading (auto-loaded by test runner)
  golden_framework/
    golden_test_config.dart       # GoldenTestConfig, Interaction, ShellType
    golden_runner.dart            # runViewGoldenTests(), _buildGoldenWidget()
    devices.dart                  # GoldenDevice definitions
    mocks/
      mock_common.dart            # commonOverrides()
      mock_firewall.dart          # FixedFirewallNotifier + firewallOverrides()
      mock_dashboard.dart         # Dashboard-specific mocks + stub widget factory
      ...                         # one file per feature
```

### Per-Feature Tests

```
test/usp_test/
  page/
    firewall/
      fixtures/
        firewall_test_data.dart
      localizations/
        usp_firewall_view_test.dart
        goldens/
          firewall-loading-phone480-en.png
          firewall-error-phone480-en.png
          firewall-data-phone480-en.png
          firewall-data-desktop1280-en.png
          ...
    wifi_settings/
      fixtures/
        wifi_settings_test_data.dart
      localizations/
        usp_wifi_settings_view_test.dart
        goldens/
          wifi_settings-loading-phone480-en.png
          ...
```

### CI

```
ci/
  verify_golden_coverage.sh
```

---

## State Coverage Requirements

### Guiding Principle

> **If the user sees something different, it needs a golden screenshot. NO EXCEPTIONS.**

This is the **non-negotiable, absolute rule** of this framework. It applies to ANY visual difference:

- Same component at a different Y position = different screenshot
- Same dialog with different field values = different screenshot
- Same page with a different tab selected = different screenshot
- Same list with data vs empty = different screenshot per tab
- A dialog open vs closed = different screenshot
- Validation errors visible vs not = different screenshot

Do NOT consolidate "similar" states. Do NOT skip a state because "it looks almost the same." If a human user would see a different screen, capture it. Every tab, every dialog, every error state, every empty state — individually.

Any FeatureState value that causes the view to render differently — whether through conditional branches, visibility toggles, data variations, or positional changes — must be represented as a separate entry in the `states` map.

### Minimum Requirement

Every view config MUST include at least one state entry with a descriptive name (NOT generic `data`).

### Recommended States for Stateful Views

Views that have provider-driven async state (loading, error, data) SHOULD include all three. However, static pages (e.g., navigation menus) that render identically regardless of state only need their descriptive state (e.g., `menu`). Loading and error UI is shared across all pages — a single shared golden test covers those components.

### Additional States

Beyond the basics, enumerate every state that produces a distinct visual output:

- **Edit dirty** (`settings.isDirty == true`) if the view has edit mode
- **Field validation errors** (`status.validationErrors` non-empty) if the view validates input — **ALL fields must show errors simultaneously**
- **Data variants** (e.g., feature enabled vs disabled) for every conditional rendering branch
- **Empty states** (e.g., empty list) for list-based views

States that should NOT be in individual feature tests:
- **Saving spinner** — this is a shared UI overlay (`doSomethingWithSpinner`), not provider-state-driven. Tested once in `shared_states_test.dart` via interaction.

### Validation Error Coverage

For views with field validation, the `validation_error` state must trigger errors on **ALL validatable fields simultaneously**, not just a subset. This ensures every error indicator is visible in the screenshot.

If the view uses tooltip-style errors (e.g., `AppIpv4TextField` with error icons), add a corresponding `validation_error_tooltip` interaction that taps every error icon to show all tooltip messages at once:

```dart
'validation_error_tooltip': Interaction(
  setup: (overrides) => overrides.addAll(
    featureOverrides(validationErrorAllState()),
  ),
  steps: (tester) async {
    final errorIcons = find.byIcon(Icons.error_outline);
    for (int i = 0; i < errorIcons.evaluate().length; i++) {
      await tester.tap(errorIcons.at(i));
      await tester.pump();
    }
    await tester.pump(const Duration(milliseconds: 100));
  },
),
```

### How to Identify States

Review the view's `build()` method. Every `if`, `switch`, or ternary that changes what is rendered corresponds to a state that needs coverage. For example:

```dart
// This conditional means TWO states are needed: ipv6_enabled and ipv6_disabled
if (state.isIPv6Enabled)
  Ipv6SettingsSection(...)
else
  Ipv6DisabledBanner(...)
```

---

## Test Matrix

### Screen Sizes (defaults)

| Name | Width | Height |
|------|-------|--------|
| phone480 | 480 | 800 |
| desktop1280 | 1280 | 800 |

### Locales (default)

| Locale |
|--------|
| en |

Additional locales and screen sizes can be specified per-config.

### Themes (default)

| Theme |
|-------|
| light |

Dark mode can be added per-config via the `themes` parameter.

### Total per view

Each state/interaction generates: `states × devices × locales × themes` golden files.

A typical view with 6 states, default config: `6 × 2 × 1 × 1 = 12 golden files`.

---

## Test Execution

### Run all golden tests

```bash
flutter test test/usp_test/
```

### Run a specific feature

```bash
flutter test test/usp_test/page/firewall/
```

### Update golden files (regenerate baselines)

```bash
flutter test --update-goldens test/usp_test/
flutter test --update-goldens test/usp_test/page/firewall/  # single feature
```

---

## Workflow: Adding Golden Tests for a New View

1. Create mock file at `test/usp_test/golden_framework/mocks/mock_{feature}.dart`
   - Implement `FixedXxxNotifier` subclass
   - Export `xxxOverrides(state)` helper function
2. Create fixtures at `test/usp_test/page/{feature}/fixtures/{feature}_test_data.dart`
3. Create test file at `test/usp_test/page/{feature}/localizations/usp_{feature}_view_test.dart`
4. Write `GoldenTestConfig` with all required + feature-specific states
5. Run `flutter test --update-goldens test/usp_test/page/{feature}/` to generate baselines
6. Review generated images visually
7. Commit golden files
8. CI will validate coverage on merge

---

## Future Considerations

- **CI environment standardization**: Golden images are generated on macOS with specific font rendering. CI runners on Linux may produce different pixel results. Consider a Docker image with fixed font rendering if cross-platform diffs become an issue.
- **Animation determinism**: `JiggleShake` uses unseeded `Random()`, requiring `diffThreshold` tolerance. If more animations are added, consider seeding random sources or disabling animations during golden capture.
- **Shared golden baselines for loading/error**: Loading and error UI is shared across all views. A single shared golden test could cover those components, reducing per-feature state requirements.
