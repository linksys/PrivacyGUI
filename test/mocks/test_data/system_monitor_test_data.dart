import 'package:privacy_gui/page/_shared/models/system_monitor_state.dart';

/// Test data builder for the system monitor's snapshots and state.
class SystemMonitorTestData {
  SystemMonitorTestData._();

  static const _sensor =
      'Device.DeviceInfo.TemperatureStatus.TemperatureSensor.';

  /// The five `TemperatureSensor` rows of the 2026-11-24 bench (M60,
  /// 2.0.4.26112201), as a Get of DeviceInfo returns them (#1926). The two
  /// Wi-Fi chip rows come first and share one Name, so the CPU (50 °C) is not
  /// the first row. Pass [cpuValue] to change the CPU row's value only.
  static Map<String, String> benchTemperatureSensors(
          {String cpuValue = '50'}) =>
      {
        '${_sensor}1.Name': 'hwmon_ath12k_hwmon_temp_1',
        '${_sensor}1.Value': '52',
        '${_sensor}2.Name': 'hwmon_ath12k_hwmon_temp_1',
        '${_sensor}2.Value': '51',
        '${_sensor}3.Name': 'cpu-top-thermal',
        '${_sensor}3.Value': cpuValue,
        '${_sensor}4.Name': 'top-glue-thermal',
        '${_sensor}4.Value': '51',
        '${_sensor}5.Name': 'misc-thermal',
        '${_sensor}5.Value': '51',
      };

  /// A sensor table with no `cpu-top-thermal` row: one Wi-Fi chip only.
  static Map<String, String> wifiChipSensorOnly() => {
        '${_sensor}1.Name': 'hwmon_ath12k_hwmon_temp_1',
        '${_sensor}1.Value': '52',
      };

  /// One poll of the system monitor, with an M60's memory and a CPU
  /// temperature of 50 °C by default (the 2026-11-24 bench, #1926).
  static SystemSnapshot snapshot({
    DateTime? timestamp,
    int cpuPercent = 25,
    int memoryPercent = 55,
    int totalMemoryKb = 412176,
    int freeMemoryKb = 193164,
    int uptimeSeconds = 86400,
    int? cpuTemperatureCelsius = 50,
  }) =>
      SystemSnapshot(
        timestamp: timestamp ?? DateTime(2026, 11, 24, 12),
        cpuPercent: cpuPercent,
        memoryPercent: memoryPercent,
        totalMemoryKb: totalMemoryKb,
        freeMemoryKb: freeMemoryKb,
        uptimeSeconds: uptimeSeconds,
        cpuTemperatureCelsius: cpuTemperatureCelsius,
      );

  /// A monitor holding [history], oldest first.
  static SystemMonitorState state(List<SystemSnapshot> history) =>
      SystemMonitorState(
        history: history,
        refreshInterval: const Duration(seconds: 30),
      );
}
