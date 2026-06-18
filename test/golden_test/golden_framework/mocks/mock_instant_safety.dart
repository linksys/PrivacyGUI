import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_feature_state.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_settings.dart';
import 'package:privacy_gui/page/instant_safety/models/instant_safety_status.dart';
import 'package:privacy_gui/page/instant_safety/providers/instant_safety_provider.dart';

class FixedInstantSafetyNotifier extends UspInstantSafetyNotifier {
  final InstantSafetyFeatureState _fixedState;

  FixedInstantSafetyNotifier(this._fixedState);

  @override
  InstantSafetyFeatureState build() => _fixedState;

  @override
  Future<(InstantSafetySettings?, InstantSafetyStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  }) async =>
      (null, null);

  @override
  Future<void> performSave() async {}

  @override
  void setEnabled(bool enabled) {}
}

List<Override> instantSafetyOverrides(InstantSafetyFeatureState state) => [
      uspInstantSafetyProvider
          .overrideWith(() => FixedInstantSafetyNotifier(state)),
    ];
