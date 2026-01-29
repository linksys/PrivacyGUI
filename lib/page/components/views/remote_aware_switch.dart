import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/remote_access/remote_access_provider.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A switch widget that automatically disables in remote read-only mode.
///
/// This widget wraps AppSwitch and monitors the remote access state.
/// When the application is in remote read-only mode (user logged in remotely
/// or forced remote mode), the switch's onChanged callback is set to null,
/// effectively disabling user interaction.
///
/// Use this for switches that directly trigger JNAP SET operations.
/// For switches that only modify local UI state, use regular AppSwitch.
class RemoteAwareSwitch extends ConsumerWidget {
  const RemoteAwareSwitch({
    super.key,
    required this.value,
    required this.onChanged,
  });

  /// The current value of the switch
  final bool value;

  /// Callback when switch is toggled (disabled in remote mode)
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isReadOnly = ref.watch(
      remoteAccessProvider.select((state) => state.isRemoteReadOnly),
    );

    return AppSwitch(
      value: value,
      onChanged: isReadOnly ? null : onChanged,
    );
  }
}
