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
        errorMessage: 'Connection failed',
      ),
    );
