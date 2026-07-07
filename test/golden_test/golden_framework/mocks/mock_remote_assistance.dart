import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_state.dart';

class FixedRemoteClientNotifier extends RemoteClientNotifier {
  final RemoteClientState _fixedState;

  FixedRemoteClientNotifier(this._fixedState);

  @override
  RemoteClientState build() => _fixedState;

  @override
  void setCredentials(DeviceCredentials credentials) {}

  @override
  Future<void> initiateRemoteAssistance() async {}

  @override
  Future<void> endRemoteAssistance() async {}
}

/// Returns provider overrides for remote assistance golden tests.
List<Override> remoteAssistanceOverrides(RemoteClientState state) => [
      remoteClientProvider.overrideWith(() => FixedRemoteClientNotifier(state)),
    ];
