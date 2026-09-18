import 'package:privacy_gui/providers/auth/auth_state.dart';
import 'package:privacy_gui/providers/auth/auth_types.dart';

/// Test data builder for [AuthState].
///
/// Constitution §1.6.2 states its purpose as USP codegen models for Service tests,
/// and [AuthState] is neither — but the naming table in Article III lists
/// `auth_test_data.dart` by name, and the rule that decided this file exists is the
/// one line of §1.6.2 that is not about codegen: "do not create mock data
/// temporarily when writing tests".
///
/// What was temporary, specifically. Three tests across two files needed a
/// logged-in [AuthState] that is **not equal** to the one before it, and each spelled
/// it out with its own ad-hoc `localPasswordHint` string. The requirement is subtle
/// enough to be worth stating once rather than three times — see [loggedInAgain] —
/// and it is the kind of thing a reader deletes as noise on the way past.
///
/// **Scope, stated so the next person is not misled.** Twelve test files construct
/// `AuthState` inline, thirty times. This file was added by #1513's review cycle and
/// covers only the states that cycle needed; migrating the rest is not this PR's
/// business, so a state missing here means "not needed yet", not "deliberately
/// inline".
class AuthTestData {
  const AuthTestData._();

  /// A local session, the ordinary logged-in state.
  static AuthState loggedIn({String? localPasswordHint}) => AuthState(
        loginType: LoginType.local,
        localPasswordHint: localPasswordHint,
      );

  /// A **second** logged-in state that is not equal to [loggedIn].
  ///
  /// The distinctness is the whole point and it is load-bearing, not cosmetic:
  /// [AuthState] is `Equatable` and Riverpod suppresses the notification for an
  /// equal value, so re-emitting [loggedIn] never reaches
  /// `ref.listen(authProvider)` and a test that drives auth that way asserts about a
  /// listener which did not run. A refreshed `localPasswordHint` is the real shape —
  /// `AuthNotifier` re-reads the hint without the session changing hands, which is
  /// why "any later auth emission" is not the same claim as "a re-login".
  ///
  /// [reason] names why the state changed, and it shows up in nothing but a failure
  /// message; give it the sentence the test is about.
  static AuthState loggedInAgain(String reason) => AuthState(
        loginType: LoginType.local,
        localPasswordHint: reason,
      );

  /// Signed out — what auth publishes after `logout()` completes.
  static AuthState loggedOut() =>
      const AuthState(loginType: LoginType.none, localPasswordHint: null);
}
