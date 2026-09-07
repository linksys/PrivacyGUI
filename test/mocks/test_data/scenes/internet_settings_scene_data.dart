/// Composed scenes for `usp_internet_settings_view` — the golden suite's eight states
/// and the gate's one.
///
/// Moved here from
/// `test/golden_test/page/internet_settings/fixtures/internet_settings_test_data.dart`
/// by #1380 (wave 4), for the reason `dmz_scene_data.dart` records: the layout gate may
/// not import from `test/golden_test/` (#1361), and one fixture read by both suites
/// beats two that can disagree.
library;

import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';

// =============================================================================
// Forms — one per connection type
// =============================================================================

const dhcpForm = UspInternetSettingsForm(
  connectionType: UspWanConnectionType.dhcp,
  mtu: 1500,
  wanMacAddress: 'AA:BB:CC:DD:EE:FF',
  ipv6Enabled: false,
  dhcpv6Enabled: false,
  vlanEnabled: false,
  vlanId: 0,
);

const staticIpForm = UspInternetSettingsForm(
  connectionType: UspWanConnectionType.staticIp,
  staticIpAddress: '192.168.1.100',
  subnetMask: '255.255.255.0',
  defaultGateway: '192.168.1.1',
  dnsServer1: '8.8.8.8',
  dnsServer2: '8.8.4.4',
  dnsServer3: '',
  mtu: 1500,
  wanMacAddress: 'AA:BB:CC:DD:EE:FF',
  ipv6Enabled: false,
  dhcpv6Enabled: false,
  vlanEnabled: false,
  vlanId: 0,
);

const pppoeForm = UspInternetSettingsForm(
  connectionType: UspWanConnectionType.pppoe,
  pppUsername: 'user@isp.com',
  pppPassword: 'secret123',
  pppoeServiceName: 'ISP_PPPoE',
  connectionTrigger: 'AlwaysOn',
  idleDisconnectTime: 300,
  lcpEchoInterval: 30,
  mtu: 1492,
  wanMacAddress: 'AA:BB:CC:DD:EE:FF',
  ipv6Enabled: false,
  dhcpv6Enabled: false,
  vlanEnabled: false,
  vlanId: 0,
);

const bridgeForm = UspInternetSettingsForm(
  connectionType: UspWanConnectionType.bridge,
  mtu: 0,
  wanMacAddress: '',
  ipv6Enabled: false,
  dhcpv6Enabled: false,
  vlanEnabled: false,
  vlanId: 0,
);

const ipv6EnabledForm = UspInternetSettingsForm(
  connectionType: UspWanConnectionType.dhcp,
  mtu: 1500,
  wanMacAddress: 'AA:BB:CC:DD:EE:FF',
  ipv6Enabled: true,
  dhcpv6Enabled: true,
  ipv6rdEnabled: true,
  ipv6rdPrefix: '2001:db8::/32',
  ipv6rdIpv4MaskLength: 8,
  ipv6rdBorderRelay: '192.0.2.1',
  vlanEnabled: false,
  vlanId: 0,
);

// =============================================================================
// Read-only info for display
// =============================================================================

const defaultReadOnlyInfo = InternetSettingsReadOnlyInfo(
  currentMacAddress: '11:22:33:44:55:66',
  pppConnectionStatus: '',
  dhcpv6Duid: '',
  staticIpAddress: '192.168.1.100',
);

const bridgeReadOnlyInfo = InternetSettingsReadOnlyInfo(
  currentMacAddress: '11:22:33:44:55:66',
  pppConnectionStatus: '',
  dhcpv6Duid: '',
  staticIpAddress: '',
  hostName: 'Community00080',
);

const pppoeReadOnlyInfo = InternetSettingsReadOnlyInfo(
  currentMacAddress: '11:22:33:44:55:66',
  pppConnectionStatus: 'Connected',
  dhcpv6Duid: '',
  staticIpAddress: '',
);

const ipv6ReadOnlyInfo = InternetSettingsReadOnlyInfo(
  currentMacAddress: '11:22:33:44:55:66',
  pppConnectionStatus: '',
  dhcpv6Duid: '00:01:00:01:2a:3b:4c:5d:aa:bb:cc:dd:ee:ff',
  staticIpAddress: '192.168.1.100',
);

// =============================================================================
// State builders
// =============================================================================

InternetSettingsFeatureState dataState(
  UspInternetSettingsForm form, {
  InternetSettingsReadOnlyInfo readOnlyInfo =
      const InternetSettingsReadOnlyInfo(),
  bool isEditing = false,
  String? pppInstancePath,
  String? vlanInstancePath,
}) {
  final settings = InternetSettingsSettings(form: form);
  return InternetSettingsFeatureState(
    settings: Preservable(original: settings, current: settings),
    status: InternetSettingsStatus(
      isLoading: false,
      isEditing: isEditing,
      readOnlyInfo: readOnlyInfo,
      pppInstancePath: pppInstancePath,
      vlanInstancePath: vlanInstancePath,
    ),
  );
}

InternetSettingsFeatureState dirtyState({
  UspInternetSettingsForm originalForm = dhcpForm,
  UspInternetSettingsForm editedForm = const UspInternetSettingsForm(
    connectionType: UspWanConnectionType.dhcp,
    mtu: 1400,
    wanMacAddress: 'FF:EE:DD:CC:BB:AA',
    ipv6Enabled: false,
    dhcpv6Enabled: false,
    vlanEnabled: true,
    vlanId: 100,
  ),
  bool isSaving = false,
}) {
  final original = InternetSettingsSettings(form: originalForm);
  final current = InternetSettingsSettings(form: editedForm);
  return InternetSettingsFeatureState(
    settings: Preservable(original: original, current: current),
    status: InternetSettingsStatus(
      isLoading: false,
      isSaving: isSaving,
      isEditing: true,
      activeMutation: isSaving ? 'save' : null,
      readOnlyInfo: defaultReadOnlyInfo,
    ),
  );
}

InternetSettingsFeatureState get errorState => InternetSettingsFeatureState(
      settings: Preservable(
        original: InternetSettingsSettings.empty(),
        current: InternetSettingsSettings.empty(),
      ),
      status: const InternetSettingsStatus(
        isLoading: false,
        error: ConnectivityError(detail: 'Connection failed'),
      ),
    );

// =============================================================================
// The gate scene
// =============================================================================

/// The WAN form every `page.internet_settings` cell is measured against.
///
/// PPPoE with IPv6, a 6rd tunnel and a VLAN all on, which is not a router anybody
/// ships — it is the union of every conditional row this page can draw:
///
/// - **PPPoE** is the connection type with the most read-only rows: username, service
///   name, connection mode and PPP status, against `dhcp`'s zero and `staticIp`'s four.
///   `bridge` is the opposite extreme and would also flip the optional section to a
///   one-row `auto` and disable both renew buttons.
/// - **`vlanEnabled`** adds the fifth PPPoE row, which renders only under it.
/// - **`ipv6rdEnabled`** adds the three 6rd rows — prefix, prefix length, border relay
///   — which render only under it, and the prefix is the page's longest value string.
/// - The two IPv6 switches and the DUID row render unconditionally; setting both
///   switches on is cosmetic here, and said so rather than left to look load-bearing.
const gateInternetSettingsForm = UspInternetSettingsForm(
  connectionType: UspWanConnectionType.pppoe,
  pppUsername: 'user@isp.com',
  pppPassword: 'secret123',
  pppoeServiceName: 'ISP_PPPoE',
  connectionTrigger: 'AlwaysOn',
  idleDisconnectTime: 300,
  lcpEchoInterval: 30,
  mtu: 1492,
  wanMacAddress: 'AA:BB:CC:DD:EE:FF',
  ipv6Enabled: true,
  dhcpv6Enabled: true,
  ipv6rdEnabled: true,
  ipv6rdPrefix: '2001:db8::/32',
  ipv6rdIpv4MaskLength: 8,
  ipv6rdBorderRelay: '192.0.2.1',
  vlanEnabled: true,
  vlanId: 100,
);

/// Every read-only string the page can paint, all non-empty.
///
/// Each one is a branch: `staticIpAddress` is what makes the banner's status dot
/// active and the IPv4 renew card show an address instead of `--`,
/// `pppConnectionStatus` fills the PPP status row, and `dhcpv6Duid` fills the DUID
/// row — a 39-character value, the longest the page renders, and the reason this
/// scene does not reuse `defaultReadOnlyInfo`, which leaves two of the three empty.
const gateInternetSettingsReadOnlyInfo = InternetSettingsReadOnlyInfo(
  currentMacAddress: '11:22:33:44:55:66',
  pppConnectionStatus: 'Connected',
  dhcpv6Duid: '00:01:00:01:2a:3b:4c:5d:aa:bb:cc:dd:ee:ff',
  staticIpAddress: '192.168.1.100',
);

/// The router shape every `page.internet_settings` cell is measured against.
///
/// **Not editing, and that is the load-bearing half of this scene.** Every section
/// swaps `UspInfoRow` for `AppTextFormField` under `isEditing`, and a stack of
/// full-width form fields is the *easier* layout: a field owns its whole row, so the
/// only thing that can overflow is its label. `UspInfoRow` is a fixed-width label box
/// beside an `Expanded` value on one line, which is the shape this wave has already
/// found twice. Read-only also keeps `UspRenewSection` — it renders only
/// `if (!isEditing)` — and its two renew cards are label-column-plus-button rows, the
/// same shape again.
///
/// The second consequence is the bottom bar: `_buildBottomBar` returns null unless
/// `isEditing`, so a read-only scene has none, which is what `dmz_scene_data.dart`
/// argues for — `UiKitBottomBarConfig` is ui_kit's own widget and out of scope
/// per #1380.
final gateInternetSettingsState = dataState(
  gateInternetSettingsForm,
  readOnlyInfo: gateInternetSettingsReadOnlyInfo,
  pppInstancePath: 'Device.PPP.Interface.1.',
);
