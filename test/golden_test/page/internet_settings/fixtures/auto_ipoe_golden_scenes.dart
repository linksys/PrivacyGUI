import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_state.dart';

import '../../../../mocks/test_data/auto_ipoe_test_data.dart';
import '../../../../mocks/test_data/scenes/internet_settings_scene_data.dart';

final ipoeForm = dhcpForm.copyWith(connectionType: UspWanConnectionType.ipoe);

final ipoeReadySnapshot = AutoIPoETestData.snapshot();

// v6 Plus covers all five static-IP fields, including a stored password.
final ipoeStaticIpSnapshot = AutoIPoESnapshot(
  capabilities: ipoeReadySnapshot.capabilities.copyWith(
    supportedModes: [AutoIPoEMode.auto, AutoIPoEMode.v6PlusStaticIp],
  ),
  settings: AutoIPoETestData.settings.copyWith(
    selectedMode: AutoIPoEMode.v6PlusStaticIp,
    v6PlusStaticIpSettings: const V6PlusStaticIPSettings(
      ipv6Remote: '2001:db8:100::1',
      ipv6InterfaceId: '::1234:5678:9abc:def0',
      ipv4Address: '192.0.2.10',
      userId: 'user@example.com',
      userPassword: AutoIPoESecret(hasStoredValue: true),
    ),
  ),
  runtime: ipoeReadySnapshot.runtime.copyWith(
    selectedMode: AutoIPoEMode.v6PlusStaticIp,
  ),
);

const ipoeInProgressSubmission =
    AutoIPoESubmission(AutoIPoETestData.id, reset: false);

final ipoeInProgressSnapshot = AutoIPoESnapshot(
  capabilities: ipoeReadySnapshot.capabilities,
  settings: ipoeReadySnapshot.settings,
  runtime: ipoeReadySnapshot.runtime.copyWith(
    selectedMode: AutoIPoEMode.auto,
    applyState: AutoIPoEApplyState.applying,
    isBusy: true,
    progressPhase: AutoIPoEProgressPhase.checkingInternet,
    progressAttempt: 2,
    progressTotal: 5,
  ),
  log: const AutoIPoELog(
    content: 'Applying network settings...\nChecking Internet connectivity...',
    isComplete: false,
    rebootRecommended: false,
  ),
  requestId: AutoIPoETestData.id,
  operationId: AutoIPoETestData.id,
  accepted: true,
);

AutoIPoEPageState ipoeGoldenPageState(AutoIPoESnapshot snapshot) =>
    AutoIPoEPageState(
      settings: Preservable(
        original: snapshot.settings,
        current: snapshot.settings,
      ),
      status: AutoIPoEPageStatus(snapshot: snapshot),
    );
