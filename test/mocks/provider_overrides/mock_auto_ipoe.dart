import 'package:privacy_gui/core/capability/device_capability.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/mode/app_mode_profile.dart';
import 'package:privacy_gui/core/mode/local_mode_profile.dart';
import 'package:privacy_gui/page/internet_settings/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_provider.dart';
import 'package:privacy_gui/page/internet_settings/providers/auto_ipoe_page_state.dart';

import '../test_data/scenes/auto_ipoe_scene_data.dart';

// Fixed builds keep the real view in its ready state without router reads or
// polling. The matching submission exercises the completed operation content.
class FixedAutoIPoEDataNotifier extends AutoIPoEDataNotifier {
  FixedAutoIPoEDataNotifier(this.snapshot);
  final AutoIPoESnapshot snapshot;
  @override
  Future<AutoIPoESnapshot> build() async => snapshot;
}

class FixedAutoIPoEPageNotifier extends AutoIPoEPageNotifier {
  FixedAutoIPoEPageNotifier(this.pageState);
  final AutoIPoEPageState pageState;
  @override
  AutoIPoEPageState build() => pageState;
}

List<Override> autoIPoEOverrides({
  AutoIPoESnapshot? snapshot,
  AutoIPoEPageState? pageState,
  AutoIPoESubmission? submission = gateAutoIPoESubmission,
}) =>
    [
      deviceCapabilitiesProvider
          .overrideWithValue(DeviceCapabilities({DeviceCapability.autoIPoE})),
      appModeProfileProvider.overrideWithValue(const LocalModeProfile()),
      autoIPoEDataProvider.overrideWith(
          () => FixedAutoIPoEDataNotifier(snapshot ?? gateAutoIPoESnapshot)),
      autoIPoEPageProvider.overrideWith(
          () => FixedAutoIPoEPageNotifier(pageState ?? gateAutoIPoEPageState)),
      autoIPoESubmissionProvider.overrideWith((ref) => submission),
      autoIPoERejectionProvider.overrideWith((ref) => null),
    ];
