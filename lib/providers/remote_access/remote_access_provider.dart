import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_state.dart';

/// Provider that determines if the application is in remote read-only mode.
///
/// Remote read-only mode is activated when any of these conditions are met:
/// 1. User logged in remotely via Cloud (loginType == LoginType.remote)
/// 2. Compile-time forced remote mode (BuildConfig.forceCommandType == ForceCommand.remote)
///
/// When in remote read-only mode, all router configuration changes (JNAP SET operations)
/// are disabled for security reasons.
final remoteAccessProvider = Provider<RemoteAccessState>((ref) {
  // Watch auth state for loginType changes
  final authAsync = ref.watch(authProvider);

  // Extract loginType, default to LoginType.none if not available
  final loginType = authAsync.when(
    data: (authState) => authState.loginType,
    loading: () => LoginType.none,
    error: (_, __) => LoginType.none,
  );

  // Determine if remote read-only mode should be active
  final isRemoteReadOnly = loginType == LoginType.remote ||
      BuildConfig.forceCommandType == ForceCommand.remote;

  return RemoteAccessState(isRemoteReadOnly: isRemoteReadOnly);
});
