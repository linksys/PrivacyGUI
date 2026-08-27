import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// Ends the remote assistance session and then logs out.
///
/// The order matters: ending the session fetches (and stores) the device token,
/// so logout has to be the last thing that touches the stored credentials.
/// Logout also has to happen even when the teardown fails - otherwise a failed
/// teardown would leave the user signed in with the device token of the device
/// they were assisting.
/// How long logging out is willing to wait for the teardown. Ending the session
/// can hit the cloud, and that request retries with a backoff - the user is
/// looking at a screen with no spinner on it, so the wait has to be bounded.
const _kTeardownTimeout = Duration(seconds: 5);

Future<void> endRemoteAssistanceAndLogout(WidgetRef ref) async {
  // Resolve both notifiers before the first await: the widget that owns [ref]
  // may be disposed while the teardown is in flight.
  final remoteClient = ref.read(remoteClientProvider.notifier);
  final auth = ref.read(authProvider.notifier);
  try {
    await remoteClient.endRemoteAssistance().timeout(_kTeardownTimeout);
  } catch (error, stackTrace) {
    logger.e('[Auth]: Failed to end the remote assistance session',
        error: error, stackTrace: stackTrace);
  }
  await auth.logout();
}
