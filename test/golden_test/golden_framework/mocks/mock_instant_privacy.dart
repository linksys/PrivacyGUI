import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_notifier.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

class FixedInstantPrivacyNotifier extends UspInstantPrivacyNotifier {
  final UspInstantPrivacyState _fixedState;

  FixedInstantPrivacyNotifier(this._fixedState);

  @override
  Future<UspInstantPrivacyState> build() async => _fixedState;

  @override
  Future<void> enable() async {}

  @override
  Future<void> disable() async {}

  @override
  Future<void> addMac(String mac) async {}
}

List<Override> instantPrivacyOverrides(UspInstantPrivacyState state) => [
      uspInstantPrivacyProvider
          .overrideWith(() => FixedInstantPrivacyNotifier(state)),
    ];
