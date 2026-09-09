import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';
import 'package:privacy_gui/page/firewall/providers/firewall_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_data_provider.dart';

/// Test data builder for the mascot health system.
///
/// Owns the single [WanData] factory in `test/mocks/test_data/` — WAN status is
/// an input to [HealthEvaluationContext], and the mascot trigger tests reuse it
/// from here rather than defining a second one (constitution Article I §1.6.2).
class SystemHealthTestData {
  // ---------------------------------------------------------------------------
  // WAN (health input)
  // ---------------------------------------------------------------------------

  static WanData createWanData({
    bool isUp = true,
    String ipAddress = '100.64.1.100',
    String subnetMask = '255.255.255.0',
    String addressingType = 'DHCP',
    int mtu = 1500,
    String gateway = '100.64.1.1',
  }) =>
      WanData(
        model: WanStatusUIModel(
          isUp: isUp,
          ipAddress: ipAddress,
          subnetMask: subnetMask,
          addressingType: addressingType,
          mtu: mtu,
          gateway: gateway,
        ),
      );

  // ---------------------------------------------------------------------------
  // Evaluation context
  // ---------------------------------------------------------------------------

  /// Every field is nullable and every dimension scores 100 on a `null` input
  /// ("no data = assume healthy"), so pass only the domain a test is about.
  static HealthEvaluationContext createContext({
    WanData? wan,
    WifiData? wifi,
    DevicesData? devices,
    FirewallData? firewall,
    SystemInfoData? systemInfo,
    FirmwareBanksData? firmware,
  }) =>
      HealthEvaluationContext(
        wan: wan,
        wifi: wifi,
        devices: devices,
        firewall: firewall,
        systemInfo: systemInfo,
        firmware: firmware,
      );

  /// WAN up, everything else absent — internet dimension scores 100.
  static HealthEvaluationContext createHealthyContext() =>
      createContext(wan: createWanData(isUp: true));

  /// WAN down — internet dimension scores 0. The cheapest observable change
  /// between two evaluations, which is what the SSE re-evaluation tests assert.
  static HealthEvaluationContext createWanDownContext() =>
      createContext(wan: createWanData(isUp: false));
}
