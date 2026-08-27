/// Composed scenes for `instant_privacy_view` — the golden suite's three states
/// plus the one dialog interaction, and the gate's one.
///
/// Moved here from
/// `test/golden_test/page/instant_privacy/fixtures/instant_privacy_test_data.dart`
/// by #1380 (wave 4), for the reason `dmz_scene_data.dart` records: the layout gate
/// may not import from `test/golden_test/` (#1361), and one fixture read by both
/// suites beats two that can disagree.
library;

import 'package:privacy_gui/page/instant_privacy/models/instant_privacy_device_ui_model.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/services/instant_privacy_service.dart';

const _testDevices = [
  InstantPrivacyDeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:01',
    displayName: 'iPhone',
  ),
  InstantPrivacyDeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:02',
    displayName: 'MacBook Pro',
  ),
  InstantPrivacyDeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    displayName: 'iPad',
  ),
];

const disabledWithDevicesState = UspInstantPrivacyState(
  isEnabled: false,
  connectedDevices: _testDevices,
  allowedDevices: [],
  macFilterContext: MacFilterContext.empty,
);

const disabledEmptyState = UspInstantPrivacyState(
  isEnabled: false,
  connectedDevices: [],
  allowedDevices: [],
  macFilterContext: MacFilterContext.empty,
);

const enabledWithDevicesState = UspInstantPrivacyState(
  isEnabled: true,
  connectedDevices: [],
  allowedDevices: _testDevices,
  macFilterContext: MacFilterContext.empty,
);

// ---------------------------------------------------------------------------
// The gate scene
// ---------------------------------------------------------------------------

/// The three allowed devices the gate sweeps, one of them on a private MAC.
///
/// A private MAC is not a longer string — every MAC here is the same 17
/// characters — it is a **third widget in the device row**: an [AppBadge] carrying
/// `privateMacLabel`, laid out before the icon and the `Expanded` name column with
/// no wrap of its own. Whether the badge and the name fit side by side at 320px is
/// the question this list exists to ask, and `_testDevices` cannot ask it: every
/// entry there defaults `isPrivateMac` to false.
const _gateDevices = [
  InstantPrivacyDeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:01',
    displayName: 'iPhone',
  ),
  InstantPrivacyDeviceUIModel(
    mac: '7A:BB:CC:DD:EE:02',
    displayName: 'MacBook Pro',
    isPrivateMac: true,
  ),
  InstantPrivacyDeviceUIModel(
    mac: 'AA:BB:CC:DD:EE:03',
    displayName: 'iPad',
  ),
];

/// The router shape every `page.instant_privacy` cell is measured against.
///
/// Enabled, with three allowed devices and a private MAC among them — the one
/// state in which all four of this page's conditional regions render at once, and
/// the fixture choice *is* the coverage:
///
/// - `isEnabled` picks `_buildAllowedDevicesList` over `_buildConnectedDevicesList`,
///   and only the allowed list carries the `spaceBetween` header row — a count
///   label beside an `AppButton.text`, neither of them `Expanded`, which is the
///   page's tightest horizontal pair. The connected list's header is a plain label
///   that can wrap, so sweeping the OFF state would sweep the easier one.
/// - a non-empty list renders device rows at all; empty renders one line of prose.
/// - `isPrivateMac` on one device renders both the page banner
///   (`hasPrivateMacInList`) and that row's [AppBadge] — two widgets that exist in
///   no golden state, and the badge is the one that competes for row width.
///
/// What it deliberately does not cover: the two confirmation dialogs and the add-MAC
/// dialog, which are out of scope for this family by the issue's own exclusion of
/// dialogs and bottom sheets. The golden suite's `dialog_add_device` interaction is
/// where those are seen.
const gateInstantPrivacyState = UspInstantPrivacyState(
  isEnabled: true,
  connectedDevices: _gateDevices,
  allowedDevices: _gateDevices,
  macFilterContext: MacFilterContext.empty,
);
