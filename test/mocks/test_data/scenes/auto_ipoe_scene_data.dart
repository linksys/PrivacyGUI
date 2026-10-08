import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_state.dart';

import '../auto_ipoe_test_data.dart';

const gateAutoIPoESubmission =
    AutoIPoESubmission(AutoIPoETestData.id, reset: false);

final gateAutoIPoESnapshot = AutoIPoETestData.snapshot(
  requestId: AutoIPoETestData.id,
  exitCode: 0,
  verified: true,
);

final gateAutoIPoEPageState = AutoIPoEPageState(
  settings: const Preservable(
    original: AutoIPoETestData.settings,
    current: AutoIPoETestData.settings,
  ),
  status: AutoIPoEPageStatus(snapshot: gateAutoIPoESnapshot),
);
