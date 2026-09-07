import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/framework/mode/session_end.dart';
import 'package:privacy_gui/framework/mode/session_strategy.dart';

/// Local / cloud session ending: the user's own router session ended, so the
/// destination is the login screen and they can log straight back in.
class LocalSessionStrategy implements SessionStrategy {
  const LocalSessionStrategy();

  @override
  SessionOutcome get destination => SessionOutcome.loginPage;

  /// Nothing to tear down.
  ///
  /// **This emptiness is the content of acceptance 8, not a stub.** Local logout
  /// already did everything it needed inside `logout()` itself, and this member
  /// adding nothing is the literal sense in which "local behaviour unchanged"
  /// holds: same calls, same order, one extra completed future in front of them.
  ///
  /// Three things that look like they belong here and do not:
  ///
  ///   - **clearing app credentials** — mode-independent, and `logout()` still owns
  ///     it. See [SessionStrategy.end].
  ///   - **clearing the stored local password.** `logout()` already decides that,
  ///     and it decides it differently per build (a cloud build keeps the cloud
  ///     login). Re-deciding it here would change local behaviour, which
  ///     acceptance 8 forbids.
  ///   - **a route.** [SessionOutcome.loginPage] deliberately does not name one;
  ///     the route redirect already knows where a credential-less app goes, and it
  ///     knows about PnP and cloud-vs-local, which this class does not.
  ///
  /// [cause] is ignored, and that is the measured finding that keeps [EndCause] at
  /// two values: locally an idle timeout, a failed relogin and the user pressing
  /// Logout all end the same way. Only remote reads it.
  @override
  Future<void> end(Ref ref, EndCause cause) async {}
}
