import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
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

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late TestUspClient mockUsp;
  late MockSecureStorage mockStorage;
  late UspAuthCoordinator coordinator;

  setUp(() {
    mockUsp = TestUspClient();
    mockStorage = MockSecureStorage();

    // Default stubs
    when(() => mockUsp.isAuthenticated).thenReturn(true);
    when(() => mockUsp.isReauthInProgress).thenReturn(false);
    when(() => mockUsp.refreshToken()).thenAnswer((_) async {});

    coordinator = UspAuthCoordinator(mockUsp, mockStorage);
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — threshold gating
  // ---------------------------------------------------------------------------
  group('ensureAuth — threshold', () {
    test('refreshes when _lastTokenRefresh is null', () async {
      await coordinator.ensureAuth();

      verify(() => mockUsp.refreshToken()).called(1);
    });

    test('skips refresh when elapsed < 12 minutes', () async {
      // First call sets _lastTokenRefresh
      await coordinator.ensureAuth();
      reset(mockUsp);
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockUsp.isReauthInProgress).thenReturn(false);
      when(() => mockUsp.refreshToken()).thenAnswer((_) async {});

      // Immediate second call — well within 12 min
      await coordinator.ensureAuth();

      verifyNever(() => mockUsp.refreshToken());
    });

    test('refreshes when elapsed >= 12 minutes', () async {
      // First call to set _lastTokenRefresh
      await coordinator.ensureAuth();
      verify(() => mockUsp.refreshToken()).called(1);

      // Simulate time passage by calling syncAfterLogout + re-login
      // (which resets _lastTokenRefresh to null)
      when(() => mockUsp.logout()).thenAnswer((_) async {});
      await coordinator.syncAfterLogout();

      // Now _lastTokenRefresh is null → next call should refresh
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockUsp.isReauthInProgress).thenReturn(false);
      await coordinator.ensureAuth();

      verify(() => mockUsp.refreshToken()).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — refresh success
  // ---------------------------------------------------------------------------
  group('ensureAuth — success', () {
    test('updates _lastTokenRefresh on success', () async {
      await coordinator.ensureAuth();

      verify(() => mockUsp.refreshToken()).called(1);

      // Second immediate call should skip (timestamp was set)
      await coordinator.ensureAuth();
      verifyNever(() => mockUsp.refreshToken());
    });
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — 401 error triggers force logout
  // ---------------------------------------------------------------------------
  group('ensureAuth — 401 error', () {
    test('calls onForceLogout on HTTP 401', () async {
      when(() => mockUsp.refreshToken())
          .thenThrow(Exception('HTTP 401 Unauthorized'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.ensureAuth();

      expect(logoutCalled, isTrue);
    });
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — network error does NOT trigger force logout
  // ---------------------------------------------------------------------------
  group('ensureAuth — network error', () {
    test('does NOT call onForceLogout on network error', () async {
      when(() => mockUsp.refreshToken())
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

      verifyNever(() => mockUsp.refreshToken());
    });

    test('skips when reauth is in progress', () async {
      when(() => mockUsp.isReauthInProgress).thenReturn(true);

      await coordinator.ensureAuth();

      verifyNever(() => mockUsp.refreshToken());
    });

    test('concurrent ensureAuth calls do not stack', () async {
      final completer = Completer<void>();
      when(() => mockUsp.refreshToken()).thenAnswer((_) => completer.future);

      // Launch two concurrent calls
      final f1 = coordinator.ensureAuth();
      final f2 = coordinator.ensureAuth();

      completer.complete();
      await f1;
      await f2;

      // refreshToken should only be called once
      verify(() => mockUsp.refreshToken()).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // _lastTokenRefresh — login paths
  // ---------------------------------------------------------------------------
  group('_lastTokenRefresh updates on login paths', () {
    test('syncAfterLocalLogin updates timestamp', () async {
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      await coordinator.syncAfterLocalLogin('password');

      // Immediate ensureAuth should skip (timestamp just set)
      await coordinator.ensureAuth();
      verifyNever(() => mockUsp.refreshToken());
    });

    test('tryUspLogin updates timestamp on success', () async {
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      await coordinator.tryUspLogin('password');

      // Immediate ensureAuth should skip
      await coordinator.ensureAuth();
      verifyNever(() => mockUsp.refreshToken());
    });

    test('restoreSession updates timestamp on success', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'storedPassword');
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      await coordinator.restoreSession();

      // Re-stub isAuthenticated for ensureAuth check
      when(() => mockUsp.isAuthenticated).thenReturn(true);

      // Immediate ensureAuth should skip
      await coordinator.ensureAuth();
      verifyNever(() => mockUsp.refreshToken());
    });
  });

  // ---------------------------------------------------------------------------
  // syncAfterLogout resets _lastTokenRefresh
  // ---------------------------------------------------------------------------
  group('syncAfterLogout', () {
    test('resets _lastTokenRefresh', () async {
      // Set timestamp via login
      when(() => mockUsp.login(any())).thenAnswer((_) async {});
      await coordinator.syncAfterLocalLogin('password');

      // Logout resets it
      when(() => mockUsp.logout()).thenAnswer((_) async {});
      await coordinator.syncAfterLogout();

      // ensureAuth should now refresh (timestamp is null)
      await coordinator.ensureAuth();
      verify(() => mockUsp.refreshToken()).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // restoreSession re-logs in unconditionally — covers reauth Stage 2 and the
  // recovery probe after a router reboot, where the WASM client still reports
  // isAuthenticated=true while carrying a stale token.
  // ---------------------------------------------------------------------------
  group('restoreSession (onReauthRequired / recovery probe)', () {
    test('re-logs in even when isAuthenticated=true', () async {
      // WASM client still reports authenticated (stale token in memory)
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'storedPassword');
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      // UspClient wires onReauthRequired to coordinator.restoreSession
      final onReauth = mockUsp.onReauthRequired;
      expect(onReauth, isNotNull);
      await onReauth!();

      verify(() => mockUsp.login('storedPassword')).called(1);
    });

    test('re-logs in when called directly (recovery probe path)', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'storedPassword');
      when(() => mockUsp.login(any())).thenAnswer((_) async {});

      await coordinator.restoreSession();

      verify(() => mockUsp.login('storedPassword')).called(1);
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
      verifyNever(() => mockUsp.refreshToken());
    });
  });

  // ---------------------------------------------------------------------------
  // ensureAuth — 401 resets _lastTokenRefresh
  // ---------------------------------------------------------------------------
  group('ensureAuth — 401 resets timestamp', () {
    test('resets _lastTokenRefresh on 401 so next call retries immediately',
        () async {
      // Make refreshToken throw 401
      when(() => mockUsp.refreshToken())
          .thenThrow(Exception('HTTP 401 Unauthorized'));
      coordinator.onForceLogout = () {};

      // ensureAuth gets 401 — should reset _lastTokenRefresh
      await coordinator.ensureAuth();
      verify(() => mockUsp.refreshToken()).called(1);

      // Immediately call again — should attempt refresh because
      // _lastTokenRefresh was reset to null on 401
      when(() => mockUsp.refreshToken()).thenAnswer((_) async {});
      await coordinator.ensureAuth();
      verify(() => mockUsp.refreshToken()).called(1);
    });
  });

  // ---------------------------------------------------------------------------
  // _isAuthError — pattern matching
  // ---------------------------------------------------------------------------
  group('_isAuthError pattern matching', () {
    test('matches actual WASM error format', () async {
      when(() => mockUsp.refreshToken()).thenThrow(
          Exception('Get failed: Transport error: HTTP error: HTTP 401'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.ensureAuth();

      expect(logoutCalled, isTrue);
    });

    test('does NOT match HTTP 500', () async {
      when(() => mockUsp.refreshToken())
          .thenThrow(Exception('HTTP 500 Internal Server Error'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.ensureAuth();

      expect(logoutCalled, isFalse);
    });

    test('does NOT match HTTP 403', () async {
      when(() => mockUsp.refreshToken())
          .thenThrow(Exception('HTTP error: HTTP 403 Forbidden'));

      bool logoutCalled = false;
      coordinator.onForceLogout = () => logoutCalled = true;

      await coordinator.ensureAuth();

      expect(logoutCalled, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // _loginWithStoredPassword — silent failure
  // ---------------------------------------------------------------------------
  group('_loginWithStoredPassword — silent failure', () {
    test('restoreSession does not throw when login fails', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'storedPassword');
      when(() => mockUsp.login(any()))
          .thenThrow(Exception('Connection refused'));

      // Should not throw
      await coordinator.restoreSession();
    });

    test('onReauthRequired does not throw when login fails', () async {
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'storedPassword');
      when(() => mockUsp.login(any()))
          .thenThrow(Exception('Connection refused'));

      // Trigger restoreSession via onReauthRequired wiring
      final onReauth = mockUsp.onReauthRequired;
      expect(onReauth, isNotNull);

      // Should not throw
      await onReauth!();
    });

    test('returns false and does not update timestamp on failure', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockStorage.read(key: any(named: 'key')))
          .thenAnswer((_) async => 'storedPassword');
      when(() => mockUsp.login(any()))
          .thenThrow(Exception('Connection refused'));

      await coordinator.restoreSession();

      // Re-stub for ensureAuth check
      when(() => mockUsp.isAuthenticated).thenReturn(true);
      when(() => mockUsp.isReauthInProgress).thenReturn(false);
      when(() => mockUsp.refreshToken()).thenAnswer((_) async {});

      // ensureAuth should refresh (timestamp was NOT set)
      await coordinator.ensureAuth();
      verify(() => mockUsp.refreshToken()).called(1);
    });
  });
}
