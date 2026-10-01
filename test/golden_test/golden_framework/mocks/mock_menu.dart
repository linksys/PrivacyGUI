import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';
import 'package:privacy_gui/core/capability/capability_provider.dart';
import 'package:privacy_gui/core/capability/device_capability.dart';

class FixedLanDataNotifierForMenu extends LanDataNotifier {
  final LanData _fixedData;

  FixedLanDataNotifierForMenu(this._fixedData);

  @override
  Future<LanData> build() async => _fixedData;
}

class FixedInstantPrivacyNotifier extends UspInstantPrivacyNotifier {
  final UspInstantPrivacyState _fixedState;

  FixedInstantPrivacyNotifier(this._fixedState);

  @override
  UspInstantPrivacyState build() => _fixedState;
}

List<Override> menuOverrides({
  required LanData lanData,
  required UspInstantPrivacyState privacyState,
}) =>
    [
      lanDataProvider.overrideWith(
        () => FixedLanDataNotifierForMenu(lanData),
      ),
      uspInstantPrivacyProvider.overrideWith(
        () => FixedInstantPrivacyNotifier(privacyState),
      ),
      // The Instant Privacy card exists only on firmware that serves the MAC
      // filter (#1635); without this the card, and the badge row this fixture pins
      // a state for, would not render at all.
      deviceCapabilitiesProvider.overrideWithValue(
          DeviceCapabilities(const {DeviceCapability.wifiMacFilter})),
    ];
