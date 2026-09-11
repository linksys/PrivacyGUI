import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart';
import 'package:privacy_gui/page/components/styled/remote_assistance/end_remote_assistance_and_logout.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

/// Records the order the teardown and the logout ran in, so a test can tell
/// them apart rather than only counting them.
final List<String> calls = [];

class FakeRemoteClientNotifier extends RemoteClientNotifier {
  FakeRemoteClientNotifier({this.onEnd});

  /// What [endRemoteAssistance] awaits. Defaults to a teardown that succeeds.
  final Future<void> Function()? onEnd;

  @override
  Future<void> endRemoteAssistance() async {
    calls.add('end');
    await (onEnd?.call() ?? Future.value());
  }
}

class FakeAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() async =>
      const AuthState(loginType: LoginType.remote);

  @override
  Future logout() async {
    calls.add('logout');
  }
}

void main() {
  late FakeAuthNotifier auth;

  /// Pumps a bare consumer and hands back its ref, which is how both production
  /// call sites reach [endRemoteAssistanceAndLogout].
  Future<WidgetRef> pumpConsumer(
    WidgetTester tester, {
    Future<void> Function()? onEnd,
  }) async {
    late WidgetRef capturedRef;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authProvider.overrideWith(() => auth),
          remoteClientProvider
              .overrideWith(() => FakeRemoteClientNotifier(onEnd: onEnd)),
        ],
        child: Consumer(builder: (context, ref, child) {
          capturedRef = ref;
          return const SizedBox.shrink();
        }),
      ),
    );
    return capturedRef;
  }

  setUp(() {
    calls.clear();
    auth = FakeAuthNotifier();
  });

  testWidgets('logs out after the session was ended', (tester) async {
    final ref = await pumpConsumer(tester);

    await endRemoteAssistanceAndLogout(ref);

    expect(calls, ['end', 'logout']);
  });

  testWidgets('logs out even when ending the session fails', (tester) async {
    // A failed teardown must not leave the user signed in with the device token
    // of the device they were assisting.
    final ref = await pumpConsumer(tester,
        onEnd: () => Future.error(Exception('cloud rejected the request')));

    await endRemoteAssistanceAndLogout(ref);

    expect(calls, ['end', 'logout']);
  });

  testWidgets('logs out when ending the session never completes',
      (tester) async {
    // The screen has no spinner on it, so the teardown is only given a bounded
    // amount of time before logging out carries on without it.
    final stuck = Completer<void>();
    final ref = await pumpConsumer(tester, onEnd: () => stuck.future);

    // Deliberately not awaited: without the timeout this never completes, and a
    // test that hangs is worse evidence than one that fails.
    unawaited(endRemoteAssistanceAndLogout(ref));
    expect(calls, ['end'], reason: 'logout must wait for the teardown first');

    await tester.pump(const Duration(seconds: 30));

    expect(calls, ['end', 'logout']);

    // Let the abandoned teardown finish so nothing is left pending.
    stuck.complete();
    await tester.pump();
  });
}
