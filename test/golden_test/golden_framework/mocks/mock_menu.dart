import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_data.dart';
import 'package:privacy_gui/page/mac_filter/providers/mac_filter_data_provider.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';

import '../../../mocks/provider_overrides/mock_mac_filter.dart'
    show FixedMacFilterDataNotifier;

class FixedLanDataNotifierForMenu extends LanDataNotifier {
  final LanData _fixedData;

  FixedLanDataNotifierForMenu(this._fixedData);

  @override
  Future<LanData> build() async => _fixedData;
}

List<Override> menuOverrides({
  required LanData lanData,
  required MacFilterData privacy,
}) =>
    [
      lanDataProvider.overrideWith(
        () => FixedLanDataNotifierForMenu(lanData),
      ),
      // The Instant Privacy badge reads the session-wide MAC filter (#1755).
      macFilterDataProvider.overrideWith(
        () => FixedMacFilterDataNotifier(privacy),
      ),
      // The Instant Privacy card exists only on firmware that serves the MAC
      // filter (#1635); without this the card, and the badge row this fixture pins
      // a state for, would not render at all.
      deviceCapabilitiesProvider.overrideWithValue(
          DeviceCapabilities(const {DeviceCapability.wifiMacFilter})),
    ];
