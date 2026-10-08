import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_page_state.dart';

import '../test_data/scenes/auto_ipoe_scene_data.dart';

// Fixed builds keep the real view in its ready state without router reads or
// polling. The matching submission exercises the completed operation content.
class FixedAutoIPoEDataNotifier extends AutoIPoEDataNotifier {
  @override
  Future<AutoIPoESnapshot> build() async => gateAutoIPoESnapshot;
}

class FixedAutoIPoEPageNotifier extends AutoIPoEPageNotifier {
  @override
  AutoIPoEPageState build() => gateAutoIPoEPageState;
}

List<Override> autoIPoEOverrides() => [
      appModeProfileProvider.overrideWithValue(const LocalModeProfile()),
      autoIPoEDataProvider.overrideWith(FixedAutoIPoEDataNotifier.new),
      autoIPoEPageProvider.overrideWith(FixedAutoIPoEPageNotifier.new),
      autoIPoESubmissionProvider.overrideWith((ref) => gateAutoIPoESubmission),
      autoIPoERejectionProvider.overrideWith((ref) => null),
    ];
