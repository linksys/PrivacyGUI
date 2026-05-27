import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/local_network/providers/lan_data_provider.dart';

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
  Future<UspInstantPrivacyState> build() async => _fixedState;

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}
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
    ];
