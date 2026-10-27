/// Builders for `Device.X_LINKSYS_BLEOnboarding.` (constitution Article I
/// §1.6.2): the raw Get response the generated `BleOnboarding` parses, and the
/// Operate outputs of `Start()` / `Stop()`.
///
/// Raw maps rather than `BleOnboarding` instances because the service under test
/// calls the generated `fetch` itself, and its parser is private: a test can only
/// reach it through `UspClient.get`. The values are strings, the way obuspa and
/// the bridge return them.
///
/// The shapes follow the firmware's own records: an idle router that never ran a
/// session (2.0.3.26101482, bench 2026-10-22), and the second-M60 onboard of
/// `ble_onboarding.yaml`'s header (2.0.3.26100921, 2026-10-14). MAC addresses are
/// made up.
class BleOnboardingTestData {
  BleOnboardingTestData._();

  static const _root = 'Device.X_LINKSYS_BLEOnboarding.';

  /// A made-up node: its BLE address and the AL MAC it reports once connected.
  static const nodeBleMac = 'AA:BB:CC:00:00:01';
  static const nodeAlMac = 'aa:bb:cc:00:00:02';

  /// One `Device.{index}.` row of the session's node table.
  static Map<String, dynamic> nodeRow({
    int index = 1,
    String bleMacAddress = nodeBleMac,
    String status = 'Pending',
    String modelNumber = '',
    String rssi = '-40',
    String alMacAddress = '',
  }) =>
      {
        '${_root}Device.$index.BLEMACAddress': bleMacAddress,
        '${_root}Device.$index.ModelNumber': modelNumber,
        '${_root}Device.$index.Status': status,
        '${_root}Device.$index.RSSI': rssi,
        '${_root}Device.$index.ALMACAddress': alMacAddress,
      };

  /// The Get response for the session, with [nodes] merged in.
  ///
  /// The defaults are an idle router that has never run a session since boot.
  static Map<String, dynamic> sessionResponse({
    String status = 'Idle',
    String result = 'None',
    String session = '0',
    String devicesFound = '0',
    String devicesOnboarded = '0',
    String devicesFailed = '0',
    List<Map<String, dynamic>> nodes = const [],
  }) =>
      {
        '${_root}Status': status,
        '${_root}Result': result,
        '${_root}Session': session,
        '${_root}DevicesFound': devicesFound,
        '${_root}DevicesOnboarded': devicesOnboarded,
        '${_root}DevicesFailed': devicesFailed,
        for (final row in nodes) ...row,
      };

  /// A session that onboarded one node: the row reads `Onboarded`, with the
  /// model and AL MAC the controller read over BLE.
  static Map<String, dynamic> onboardedSessionResponse({
    String session = '1450',
    String result = 'Success',
  }) =>
      sessionResponse(
        status: 'Complete',
        result: result,
        session: session,
        devicesFound: '1',
        devicesOnboarded: '1',
        nodes: [
          nodeRow(
            status: 'Onboarded',
            modelNumber: 'M60',
            alMacAddress: nodeAlMac,
          ),
        ],
      );

  /// The flattened Operate output `UspClient.operate` returns for a command
  /// whose `Result` is [result], or for one with no `Result` when it is null.
  static Map<String, dynamic> operateOutput(String? result) => {
        if (result != null) 'Result': result,
      };
}
