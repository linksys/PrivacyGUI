import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/route/constants.dart';

/// A PnP failure screen's second way out (#1816 review): sign out, to the
/// login page.
///
/// Retry is the first, but a failure that happens every time fails again on
/// it, and before the wizard there is nowhere else in the setup to go. To the
/// local login page directly, as leaving the wizard by logging out does
/// (`route_pnp.dart`): the setup runs on a local session. Neither failure
/// screen is under the wizard's exit guard — both come before its first step.
void logOutOfSetup(BuildContext context, WidgetRef ref) {
  ref.read(authProvider.notifier).logout(cause: EndCause.userRequested);
  context.go(RoutePath.localLoginPassword);
}
