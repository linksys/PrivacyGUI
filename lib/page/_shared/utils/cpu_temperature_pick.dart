/// The `Name` of the `Device.DeviceInfo.TemperatureStatus.TemperatureSensor`
/// row that reads the router's CPU on FL-WRT 2.0 (#1926).
///
/// The table also lists two Wi-Fi chip rows, which share one Name and come
/// first, and two board rows. Only the CPU row is shown.
const cpuTemperatureSensorName = 'cpu-top-thermal';

/// The `Value` TR-181 uses for a sensor with no reading: -274 °C, below
/// absolute zero.
const noTemperatureReading = -274;

/// The CPU's temperature in whole °C among [sensors], or null when no row is
/// named [cpuTemperatureSensorName] or that row has no reading.
///
/// The row is picked by name, never by index. Both reads of DeviceInfo go
/// through this: the system monitor's poll and the session's system info, which
/// the dashboard pushes as its first snapshot.
int? cpuTemperatureOf<T>(
  Iterable<T> sensors, {
  required String? Function(T sensor) nameOf,
  required int? Function(T sensor) valueOf,
}) {
  for (final sensor in sensors) {
    if (nameOf(sensor) != cpuTemperatureSensorName) continue;
    final value = valueOf(sensor);
    return value == null || value <= noTemperatureReading ? null : value;
  }
  return null;
}
