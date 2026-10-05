import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

/// Wraps a control that changes the router, and blocks it - dimmed, not
/// tappable, with a tooltip saying why - when the current login may not write.
///
/// The JNAP layer refuses such a write regardless (see [AccessPolicy]); this is
/// so the user is not led as far as a refused request. With full access it adds
/// nothing to the tree.
class WriteGuard extends ConsumerWidget {
  const WriteGuard({super.key, required this.child, this.localOnly = false});

  final Widget child;

  /// Also block on any remote login, read-only or not, for a control that
  /// cannot work over a remote session at all - one that talks to the router's
  /// local address directly, for instance.
  final bool localOnly;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocked = !ref.watch(accessPolicyProvider).canWrite ||
        (localOnly && ref.watch(isRemoteLoginProvider));
    if (!blocked) {
      return child;
    }
    return Tooltip(
      message: loc(context).featureUnavailableInRemoteMode,
      child: Opacity(
        opacity: 0.5,
        child: AbsorbPointer(child: child),
      ),
    );
  }
}
