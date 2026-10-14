import 'dart:async';

import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/remote_assistance/models/remote_assistance_confirm_state.dart';
import 'package:privacy_gui/page/remote_assistance/providers/remote_assistance_confirm_notifier.dart';

import '../../../mocks/test_data/remote_assistance_test_data.dart';

/// Answers session validation with [_answer], or never when it is null.
class _Service extends Fake implements RemoteAssistanceService {
  _Service(this._answer);
  final FutureOr<GRASessionInfo> Function()? _answer;

  @override
  Future<GRASessionInfo> fetchSessionInfoForCA({
    required String sessionToken,
    required String sessionId,
  }) async =>
      _answer == null ? Completer<GRASessionInfo>().future : _answer();
}

void main() {
  ProviderContainer containerWith(FutureOr<GRASessionInfo> Function()? answer) {
    final c = ProviderContainer(overrides: [
      remoteAssistanceServiceProvider.overrideWithValue(_Service(answer)),
    ]);
    c.listen(remoteAssistanceConfirmProvider, (_, __) {});
    return c;
  }

  Future<RemoteAssistanceConfirmState> validate(ProviderContainer c) async {
    await c.read(remoteAssistanceConfirmProvider.notifier).validate(
          sessionId: RemoteAssistanceTestData.testSessionId,
          token: RemoteAssistanceTestData.testSessionToken,
        );
    return c.read(remoteAssistanceConfirmProvider);
  }

  group('RemoteAssistanceConfirmNotifier.validate', () {
    test('an ACTIVE session is validated and can connect', () async {
      final c = containerWith(RemoteAssistanceTestData.activeSession);
      addTearDown(c.dispose);

      final s = await validate(c);

      expect(s.phase, RemoteAssistanceConfirmPhase.validated);
      expect(s.canConnect, isTrue);
      expect(s.errorMessage, isNull);
      expect(s.remainingSeconds, 600);
    });

    test('a session that is not ACTIVE is an error naming its status',
        () async {
      final c = containerWith(RemoteAssistanceTestData.pendingSession);
      addTearDown(c.dispose);

      final s = await validate(c);

      expect(s.phase, RemoteAssistanceConfirmPhase.error);
      expect(s.canConnect, isFalse);
      expect(s.errorMessage, 'Session is not active (Pending)');
      expect(s.sessionInfo, isNotNull, reason: 'the status card still shows');
    });

    test('an INVALID session is an error', () async {
      final c = containerWith(RemoteAssistanceTestData.invalidSession);
      addTearDown(c.dispose);

      final s = await validate(c);

      expect(s.phase, RemoteAssistanceConfirmPhase.error);
      expect(s.errorMessage, 'Session is invalid or expired');
    });

    test('a refused token is an error with its own message', () async {
      final c = containerWith(() => throw const SessionTokenExpiredError());
      addTearDown(c.dispose);

      final s = await validate(c);

      expect(s.phase, RemoteAssistanceConfirmPhase.error);
      expect(s.errorMessage, 'Token expired or invalid');
    });

    test('a throw that is not a ServiceError still ends validation', () async {
      final c = containerWith(() => throw StateError('malformed answer'));
      addTearDown(c.dispose);

      final s = await validate(c);

      expect(s.phase, RemoteAssistanceConfirmPhase.error,
          reason: 'not stuck on validating, so Retry is offered');
      expect(s.errorMessage, 'An unexpected error occurred. Please try again.');
    });

    test('a retry stops the previous countdown', () {
      fakeAsync((async) {
        final c = containerWith(RemoteAssistanceTestData.activeSession);
        final n = c.read(remoteAssistanceConfirmProvider.notifier);
        n.validate(
          sessionId: RemoteAssistanceTestData.testSessionId,
          token: RemoteAssistanceTestData.testSessionToken,
        );
        async.flushMicrotasks();
        n.validate(
          sessionId: RemoteAssistanceTestData.testSessionId,
          token: RemoteAssistanceTestData.testSessionToken,
        );
        async.flushMicrotasks();

        expect(async.periodicTimerCount, 1);
        c.dispose();
      });
    });

    test('no answer within 15 s is a timeout error', () {
      fakeAsync((async) {
        final c = containerWith(null);
        final n = c.read(remoteAssistanceConfirmProvider.notifier);
        n.validate(
          sessionId: RemoteAssistanceTestData.testSessionId,
          token: RemoteAssistanceTestData.testSessionToken,
        );
        async.flushMicrotasks();
        expect(c.read(remoteAssistanceConfirmProvider).phase,
            RemoteAssistanceConfirmPhase.validating);

        async.elapse(const Duration(seconds: 15));

        final s = c.read(remoteAssistanceConfirmProvider);
        expect(s.phase, RemoteAssistanceConfirmPhase.error);
        expect(s.errorMessage, 'Connection timed out. Please try again.');
        c.dispose();
      });
    });
  });

  group('RemoteAssistanceConfirmNotifier countdown', () {
    test('counts down, and a session that runs out is an error', () {
      fakeAsync((async) {
        final c = containerWith(() =>
            RemoteAssistanceTestData.sessionWithStatus(GRASessionStatus.active,
                expiredIn: 2));
        c.read(remoteAssistanceConfirmProvider.notifier).validate(
              sessionId: RemoteAssistanceTestData.testSessionId,
              token: RemoteAssistanceTestData.testSessionToken,
            );
        async.flushMicrotasks();

        async.elapse(const Duration(seconds: 1));
        expect(c.read(remoteAssistanceConfirmProvider).remainingSeconds, 1);

        async.elapse(const Duration(seconds: 2));
        final s = c.read(remoteAssistanceConfirmProvider);
        expect(s.phase, RemoteAssistanceConfirmPhase.error);
        expect(s.remainingSeconds, 0);
        expect(s.errorMessage, 'Session has expired');
        c.dispose();
      });
    });

    test('leaving the page stops the countdown', () {
      fakeAsync((async) {
        final c = containerWith(RemoteAssistanceTestData.activeSession);
        c.read(remoteAssistanceConfirmProvider.notifier).validate(
              sessionId: RemoteAssistanceTestData.testSessionId,
              token: RemoteAssistanceTestData.testSessionToken,
            );
        async.flushMicrotasks();
        expect(async.periodicTimerCount, 1);

        c.dispose();

        expect(async.periodicTimerCount, 0);
      });
    });

    // The old view checked `mounted` after the await; leaving mid-validation
    // must not start a countdown nobody can cancel.
    test('leaving the page while Guardian is answering starts no countdown',
        () {
      fakeAsync((async) {
        final answer = Completer<GRASessionInfo>();
        final c = containerWith(() => answer.future);
        c.read(remoteAssistanceConfirmProvider.notifier).validate(
              sessionId: RemoteAssistanceTestData.testSessionId,
              token: RemoteAssistanceTestData.testSessionToken,
            );
        async.flushMicrotasks();

        c.dispose();
        answer.complete(RemoteAssistanceTestData.activeSession());
        async.flushMicrotasks();

        expect(async.periodicTimerCount, 0);
      });
    });
  });

  group('RemoteAssistanceConfirmNotifier connect', () {
    test('a failed connect returns to validated with the message', () async {
      final c = containerWith(RemoteAssistanceTestData.activeSession);
      addTearDown(c.dispose);
      await validate(c);
      final n = c.read(remoteAssistanceConfirmProvider.notifier);

      n.beginConnect();
      expect(c.read(remoteAssistanceConfirmProvider).phase,
          RemoteAssistanceConfirmPhase.connecting);
      expect(c.read(remoteAssistanceConfirmProvider).canConnect, isFalse,
          reason: 'Connect is not offered twice');

      n.connectFailed('Connection failed: boom');
      final s = c.read(remoteAssistanceConfirmProvider);
      expect(s.phase, RemoteAssistanceConfirmPhase.validated);
      expect(s.errorMessage, 'Connection failed: boom');
    });
  });
}
