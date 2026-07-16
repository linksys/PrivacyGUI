import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/constants/error_code.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_token_storage.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';

/// Mock that stores callback fields (mocktail Mock swallows setter calls).
class TestUspClient extends Mock implements UspClient {
  @override
  Future<void> Function()? onReauthRequired;

  @override
  VoidCallback? onRefreshTokenSuccess;

  @override
  VoidCallback? onForceLogout;
}

class MockTokenStorage extends Mock implements UspTokenStorage {}

void main() {
  late TestUspClient mockUsp;
  late MockTokenStorage mockStorage;
  late UspAuthCoordinator coordinator;

  setUp(() {
    mockUsp = TestUspClient();
    mockStorage = MockTokenStorage();

    // Default stubs
    when(() => mockUsp.isAuthenticated).thenReturn(true);
    when(() => mockUsp.isReauthInProgress).thenReturn(false);
    when(() => mockUsp.refreshToken(token: any(named: 'token')))
        .thenAnswer((_) async {});
    when(() => mockUsp.sessionToken).thenReturn('test-token');
    when(() => mockStorage.save(any())).thenReturn(null);
    when(() => mockStorage.clear()).thenReturn(null);
    when(() => mockStorage.load()).thenReturn(null);

    coordinator = UspAuthCoordinator(mockUsp, mockStorage);
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — threshold gating
  // ---------------------------------------------------------------------------
  group('ensureAuth — threshold', () {
    test('refreshes when _lastTokenRefresh is null', () async {
      await coordinator.ensureAuth();

      verify(() => mockUsp.refreshToken(token: null)).called(1);
    });

    test('skips refresh when elapsed < 12 minutes', () async {
      // First call sets _lastTokenRefresh
      await coordinator.ensureAuth();
      reset(mockUsp);
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockUsp.isReauthInProgress).thenReturn(false);
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenAnswer((_) async {});
      when(() => mockUsp.sessionToken).thenReturn('test-token');

      // Immediate second call — well within 12 min
      await coordinator.ensureAuth();

      verifyNever(() => mockUsp.refreshToken(token: any(named: 'token')));
    });

    test('refreshes when elapsed >= 12 minutes', () async {
      // First call to set _lastTokenRefresh
      await coordinator.ensureAuth();
      verify(() => mockUsp.refreshToken(token: null)).called(1);

      // Simulate time passage by calling syncAfterLogout
      // (which resets _lastTokenRefresh to null)
      when(() => mockUsp.logout()).thenAnswer((_) async {});
      await coordinator.syncAfterLogout();

      // Now _lastTokenRefresh is null → next call should refresh
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockUsp.isReauthInProgress).thenReturn(false);
      await coordinator.ensureAuth();

      verify(() => mockUsp.refreshToken(token: null)).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — refresh success
  // ---------------------------------------------------------------------------
  group('ensureAuth — success', () {
    test('updates _lastTokenRefresh on success', () async {
      await coordinator.ensureAuth();

      verify(() => mockUsp.refreshToken(token: null)).called(1);

      // Second immediate call should skip (timestamp was set)
      await coordinator.ensureAuth();
      verifyNever(() => mockUsp.refreshToken(token: any(named: 'token')));
    });

    test('persists token on refresh success', () async {
      await coordinator.ensureAuth();

      verify(() => mockStorage.save('test-token')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — 401 error triggers force logout
  // ---------------------------------------------------------------------------
  group('ensureAuth — 401 error', () {
    test('calls onForceLogout on HTTP 401', () async {
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenThrow(Exception('HTTP 401 Unauthorized'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.ensureAuth();

      expect(logoutCalled, isTrue);
    });

    test('clears token storage on 401', () async {
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenThrow(Exception('HTTP 401 Unauthorized'));
      coordinator.onForceLogout = () {};

      await coordinator.ensureAuth();

      verify(() => mockStorage.clear()).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — network error does NOT trigger force logout
  // ---------------------------------------------------------------------------
  group('ensureAuth — network error', () {
    test('does NOT call onForceLogout on network error', () async {
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenThrow(Exception('SocketException: Connection refused'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.ensureAuth();

      expect(logoutCalled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — guards
  // ---------------------------------------------------------------------------
  group('ensureAuth — guards', () {
    test('skips when usp is not authenticated', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);

      await coordinator.ensureAuth();

      verifyNever(() => mockUsp.refreshToken(token: any(named: 'token')));
    });

    test('skips when reauth is in progress', () async {
      when(() => mockUsp.isReauthInProgress).thenReturn(true);

      await coordinator.ensureAuth();

      verifyNever(() => mockUsp.refreshToken(token: any(named: 'token')));
    });

    test('concurrent ensureAuth calls do not stack', () async {
      final completer = Completer<void>();
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenAnswer((_) => completer.future);

      // Launch two concurrent calls
      final f1 = coordinator.ensureAuth();
      final f2 = coordinator.ensureAuth();

      completer.complete();
      await f1;
      await f2;

      // refreshToken should only be called once
      verify(() => mockUsp.refreshToken(token: null)).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // _lastTokenRefresh — login paths
  // ---------------------------------------------------------------------------
  group('_lastTokenRefresh updates on login paths', () {
    test('syncAfterLocalLogin updates timestamp and persists token', () async {
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      await coordinator.syncAfterLocalLogin('password');

      // Token should be persisted
      verify(() => mockStorage.save('test-token')).called(1);

      // Immediate ensureAuth should skip (timestamp just set)
      await coordinator.ensureAuth();
      verifyNever(() => mockUsp.refreshToken(token: any(named: 'token')));
    });

    test('tryUspLogin updates timestamp and persists token on success',
        () async {
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      await coordinator.tryUspLogin('password');

      // Token should be persisted
      verify(() => mockStorage.save('test-token')).called(1);

      // Immediate ensureAuth should skip
      await coordinator.ensureAuth();
      verifyNever(() => mockUsp.refreshToken(token: any(named: 'token')));
    });
  });

  // ---------------------------------------------------------------------------
  // tryUspLogin error mapping — WASM errors → typed ServiceError for the UI
  // ---------------------------------------------------------------------------
  group('tryUspLogin error mapping', () {
    test(
        'account-locked WASM error → UnexpectedError carrying '
        'errorAdminAccountLocked (so the login view shows the lockout message)',
        () async {
      when(() => mockUsp.login(any()))
          .thenThrow(Exception('Account is locked'));

      await expectLater(
        coordinator.tryUspLogin('password'),
        throwsA(isA<UnexpectedError>()
            .having((e) => e.detail, 'detail', errorAdminAccountLocked)),
      );
    });

    test('invalid-credentials WASM error → InvalidCredentialsError', () async {
      when(() => mockUsp.login(any())).thenThrow(
          Exception('Login failed: Authentication error: Invalid credentials'));

      await expectLater(
        coordinator.tryUspLogin('password'),
        throwsA(isA<InvalidCredentialsError>()),
      );
    });

    test('authenticated=false after login → InvalidCredentialsError', () async {
      when(() => mockUsp.login(any())).thenAnswer((_) async {});
      when(() => mockUsp.isAuthenticated).thenReturn(false);

      await expectLater(
        coordinator.tryUspLogin('password'),
        throwsA(isA<InvalidCredentialsError>()),
      );
    });
  });

  // ---------------------------------------------------------------------------
  // syncAfterLogout resets _lastTokenRefresh and clears token
  // ---------------------------------------------------------------------------
  group('syncAfterLogout', () {
    test('resets _lastTokenRefresh and clears token storage', () async {
      // Set timestamp via login
      when(() => mockUsp.login(any())).thenAnswer((_) async {});
      await coordinator.syncAfterLocalLogin('password');

      // Logout resets it
      when(() => mockUsp.logout()).thenAnswer((_) async {});
      await coordinator.syncAfterLogout();

      // Token storage should be cleared
      verify(() => mockStorage.clear()).called(1);

      // ensureAuth should now refresh (timestamp is null)
      await coordinator.ensureAuth();
      verify(() => mockUsp.refreshToken(token: null)).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // restoreSession — token-based strategy
  // ---------------------------------------------------------------------------
  group('restoreSession (token-based)', () {
    test('uses refreshToken when isAuthenticated=true and token is valid',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(true);

      await coordinator.restoreSession();

      // Should use in-memory token refresh (no external token)
      verify(() => mockUsp.refreshToken(token: null)).called(1);
      verifyNever(() => mockUsp.login(any()));
    });

    test('falls back to stored token when in-memory refresh fails with 401',
        () async {
      // First call with in-memory token fails
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      var callCount = 0;
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenAnswer((invocation) async {
        callCount++;
        if (callCount == 1) {
          throw Exception('HTTP 401 Unauthorized');
        }
        // Second call with stored token succeeds
      });
      when(() => mockStorage.load()).thenReturn('stored-token');

      await coordinator.restoreSession();

      // Should try in-memory first, then stored token
      verify(() => mockUsp.refreshToken(token: null)).called(1);
      verify(() => mockUsp.refreshToken(token: 'stored-token')).called(1);
    });

    test('uses stored token directly when isAuthenticated=false (page reload)',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn('stored-token');

      await coordinator.restoreSession();

      verifyNever(() => mockUsp.refreshToken(token: null));
      verify(() => mockUsp.refreshToken(token: 'stored-token')).called(1);
    });

    test('returns early when no stored token available', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn(null);

      await coordinator.restoreSession();

      verifyNever(() => mockUsp.refreshToken(token: any(named: 'token')));
    });

    test('clears stored token when it is expired/invalid', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn('expired-token');
      when(() => mockUsp.refreshToken(token: 'expired-token'))
          .thenThrow(Exception('HTTP 401 Unauthorized'));

      await coordinator.restoreSession();

      verify(() => mockStorage.clear()).called(1);
    });

    test('concurrent calls are coalesced — only one restore attempt', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn('stored-token');
      // Slow refresh to ensure concurrent calls overlap
      when(() => mockUsp.refreshToken(token: 'stored-token'))
          .thenAnswer((_) => Future.delayed(const Duration(milliseconds: 50)));

      // Launch multiple concurrent calls
      final futures = [
        coordinator.restoreSession(),
        coordinator.restoreSession(),
        coordinator.restoreSession(),
      ];
      await Future.wait(futures);

      // refreshToken should only be called once despite 3 concurrent calls
      verify(() => mockUsp.refreshToken(token: 'stored-token')).called(1);
    });

    test('cooldown skips restore within 1 second after failure', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn('stored-token');
      when(() => mockUsp.refreshToken(token: 'stored-token'))
          .thenThrow(Exception('Connection refused'));

      // First call — fails
      await coordinator.restoreSession();
      verify(() => mockUsp.refreshToken(token: 'stored-token')).called(1);

      // Second call within cooldown — should be skipped
      await coordinator.restoreSession();
      verifyNever(
          () => mockUsp.refreshToken(token: any(named: 'token'))); // No extra
    });

    test('triggers force logout when no stored token and not recovering',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn(null);

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.restoreSession(isRecovering: false);

      expect(logoutCalled, isTrue);
    });

    test('suppresses force logout when no stored token but is recovering',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn(null);

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.restoreSession(isRecovering: true);

      expect(logoutCalled, isFalse);
    });

    test('triggers force logout when token expired and not recovering',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn('expired-token');
      when(() => mockUsp.refreshToken(token: 'expired-token'))
          .thenThrow(Exception('HTTP 401 Unauthorized'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.restoreSession(isRecovering: false);

      expect(logoutCalled, isTrue);
      verify(() => mockStorage.clear()).called(1);
    });

    test('suppresses force logout when token expired but is recovering',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn('expired-token');
      when(() => mockUsp.refreshToken(token: 'expired-token'))
          .thenThrow(Exception('HTTP 401 Unauthorized'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.restoreSession(isRecovering: true);

      expect(logoutCalled, isFalse);
      // Token should still be cleared even in recovery mode
      verify(() => mockStorage.clear()).called(1);
    });

    test('does not trigger force logout on network error (might recover)',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.load()).thenReturn('stored-token');
      when(() => mockUsp.refreshToken(token: 'stored-token'))
          .thenThrow(Exception('Connection refused'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.restoreSession(isRecovering: false);

      // Network error — don't force logout, might recover
      expect(logoutCalled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // onRefreshTokenSuccess callback
  // ---------------------------------------------------------------------------
  group('onRefreshTokenSuccess wiring', () {
    test('constructor wires onRefreshTokenSuccess to update timestamp',
        () async {
      // Verify callback was set
      expect(mockUsp.onRefreshTokenSuccess, isNotNull);

      // Simulate Stage 1 refresh success in reauth
      mockUsp.onRefreshTokenSuccess!();

      // ensureAuth should now skip (timestamp was just set)
      await coordinator.ensureAuth();
      verifyNever(() => mockUsp.refreshToken(token: any(named: 'token')));
    });

    test('onRefreshTokenSuccess persists token', () async {
      mockUsp.onRefreshTokenSuccess!();

      verify(() => mockStorage.save('test-token')).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — 401 resets _lastTokenRefresh
  // ---------------------------------------------------------------------------
  group('ensureAuth — 401 resets timestamp', () {
    test('resets _lastTokenRefresh on 401 so next call retries immediately',
        () async {
      // Make refreshToken throw 401
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenThrow(Exception('HTTP 401 Unauthorized'));
      coordinator.onForceLogout = () {};

      // ensureAuth gets 401 — should reset _lastTokenRefresh
      await coordinator.ensureAuth();
      verify(() => mockUsp.refreshToken(token: null)).called(1);

      // Immediately call again — should attempt refresh because
      // _lastTokenRefresh was reset to null on 401
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenAnswer((_) async {});
      await coordinator.ensureAuth();
      verify(() => mockUsp.refreshToken(token: null)).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // reloginWithNewPassword
  // ---------------------------------------------------------------------------
  group('reloginWithNewPassword', () {
    test(
        'clears old token, logs out, logs in with new password, persists token',
        () async {
      when(() => mockUsp.logout()).thenAnswer((_) async {});
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      await coordinator.reloginWithNewPassword('newPassword123');

      // Verify sequence: clear → logout → login → persist
      verifyInOrder([
        () => mockStorage.clear(),
        () => mockUsp.logout(),
        () => mockUsp.login('newPassword123'),
        () => mockStorage.save('test-token'),
      ]);
    });

    test('continues even if logout fails (best-effort)', () async {
      when(() => mockUsp.logout()).thenThrow(Exception('Session expired'));
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      // Should not throw despite logout failure
      await coordinator.reloginWithNewPassword('newPassword123');

      verify(() => mockUsp.login('newPassword123')).called(1);
      verify(() => mockStorage.save('test-token')).called(1);
    });

    test(
        'throws InvalidCredentialsError when login succeeds but isAuthenticated=false',
        () async {
      when(() => mockUsp.logout()).thenAnswer((_) async {});
      when(() => mockUsp.login(any())).thenAnswer((_) async {});
      when(() => mockUsp.isAuthenticated).thenReturn(false);

      await expectLater(
        coordinator.reloginWithNewPassword('newPassword123'),
        throwsA(isA<InvalidCredentialsError>()),
      );
    });

    test('throws UnexpectedError when login throws non-ServiceError', () async {
      when(() => mockUsp.logout()).thenAnswer((_) async {});
      when(() => mockUsp.login(any())).thenThrow(Exception('Network failure'));

      await expectLater(
        coordinator.reloginWithNewPassword('newPassword123'),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('rethrows ServiceError from login', () async {
      when(() => mockUsp.logout()).thenAnswer((_) async {});
      when(() => mockUsp.login(any()))
          .thenThrow(const NetworkError(detail: 'timeout'));

      await expectLater(
        coordinator.reloginWithNewPassword('newPassword123'),
        throwsA(isA<NetworkError>()),
      );
    });

    test('updates _lastTokenRefresh on success', () async {
      when(() => mockUsp.logout()).thenAnswer((_) async {});
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      await coordinator.reloginWithNewPassword('newPassword123');

      // Immediate ensureAuth should skip (timestamp just set)
      await coordinator.ensureAuth();
      verifyNever(() => mockUsp.refreshToken(token: any(named: 'token')));
    });
  });

  // ---------------------------------------------------------------------------
  // Null UspClient guards
  // ---------------------------------------------------------------------------
  group('null UspClient guards', () {
    late UspAuthCoordinator nullCoordinator;

    setUp(() {
      nullCoordinator = UspAuthCoordinator(null, mockStorage);
    });

    test('reloginWithNewPassword throws ServiceNotInitializedError', () async {
      await expectLater(
        nullCoordinator.reloginWithNewPassword('password'),
        throwsA(isA<ServiceNotInitializedError>()),
      );
    });

    test('tryUspLogin throws ServiceNotInitializedError', () async {
      await expectLater(
        nullCoordinator.tryUspLogin('password'),
        throwsA(isA<ServiceNotInitializedError>()),
      );
    });

    test('restoreSession returns early without error', () async {
      // Should not throw, just log warning
      await nullCoordinator.restoreSession();
      verifyNever(() => mockStorage.load());
    });

    test('syncAfterLocalLogin returns early without error', () async {
      await nullCoordinator.syncAfterLocalLogin('password');
      verifyNever(() => mockStorage.save(any()));
    });

    test('syncAfterLogout clears storage even with null client', () async {
      await nullCoordinator.syncAfterLogout();
      verify(() => mockStorage.clear()).called(1);
    });

    test('ensureAuth returns early without error', () async {
      await nullCoordinator.ensureAuth();
      // No assertions needed — just verify no exception
    });
  });

  // ---------------------------------------------------------------------------
  // _isAuthError — pattern matching
  // ---------------------------------------------------------------------------
  group('_isAuthError pattern matching', () {
    test('matches actual WASM error format', () async {
      when(() => mockUsp.refreshToken(token: any(named: 'token'))).thenThrow(
          Exception('Get failed: Transport error: HTTP error: HTTP 401'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.ensureAuth();

      expect(logoutCalled, isTrue);
    });

    test('does NOT match HTTP 500', () async {
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenThrow(Exception('HTTP 500 Internal Server Error'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.ensureAuth();

      expect(logoutCalled, isFalse);
    });

    test('does NOT match HTTP 403', () async {
      when(() => mockUsp.refreshToken(token: any(named: 'token')))
          .thenThrow(Exception('HTTP error: HTTP 403 Forbidden'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.ensureAuth();

      expect(logoutCalled, isFalse);
    });
  });
}
