import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/remote_assistance/models/remote_assistance_confirm_state.dart';

final remoteAssistanceConfirmProvider = NotifierProvider.autoDispose<
    RemoteAssistanceConfirmNotifier, RemoteAssistanceConfirmState>(
  RemoteAssistanceConfirmNotifier.new,
);

/// The support agent's confirm page: validate the session Guardian issued,
/// count down to its expiry, and track the Connect attempt around it.
///
/// Opening the session is not here: the view calls `AuthNotifier.openSession`
/// inside its spinner, then reports back with [connectFailed].
class RemoteAssistanceConfirmNotifier
    extends AutoDisposeNotifier<RemoteAssistanceConfirmState> {
  /// How long Guardian gets to answer before the page gives up.
  static const validationTimeout = Duration(seconds: 15);

  Timer? _countdown;

  /// Set once the page is gone. [validate] awaits Guardian, and an answer that
  /// lands after that must not start a countdown nothing can cancel; the view
  /// this came from checked `mounted` for the same reason.
  bool _disposed = false;

  @override
  RemoteAssistanceConfirmState build() {
    ref.onDispose(() {
      _disposed = true;
      _countdown?.cancel();
    });
    return const RemoteAssistanceConfirmState();
  }

  /// Ask Guardian whether the session can be joined.
  Future<void> validate({
    required String sessionId,
    required String token,
  }) async {
    // A retry must not leave the previous session's countdown running.
    _countdown?.cancel();
    state = state.copyWith(
      phase: RemoteAssistanceConfirmPhase.validating,
      clearError: true,
    );
    try {
      final info = await ref
          .read(remoteAssistanceServiceProvider)
          .fetchSessionInfoForCA(sessionToken: token, sessionId: sessionId)
          .timeout(validationTimeout,
              onTimeout: () => throw const TimeoutError());
      if (_disposed) return;

      if (info.status == GRASessionStatus.invalid) {
        _fail('Session is invalid or expired', sessionInfo: info);
        return;
      }
      if (info.status != GRASessionStatus.active) {
        _fail('Session is not active (${statusText(info.status)})',
            sessionInfo: info);
        return;
      }

      state = state.copyWith(
        phase: RemoteAssistanceConfirmPhase.validated,
        sessionInfo: info,
        remainingSeconds: info.expiredIn.abs(),
      );
      _startCountdown();
      logger.d('[RA] Session validated: ${info.status}, '
          'expires in ${state.remainingSeconds}s');
    } on ServiceError catch (e) {
      if (_disposed) return;
      logger.e('[RA] Validate failed: $e');
      _fail(_messageFor(e));
    } catch (e, st) {
      // Not a data-layer error to handle (the service maps those): a throw
      // after the await, reading the answer. Without this arm the page would
      // stay on `validating` with no retry, which the view it came from
      // avoided the same way.
      if (_disposed) return;
      logger.e('[RA] Validate failed unexpectedly', error: e, stackTrace: st);
      _fail('An unexpected error occurred. Please try again.');
    }
  }

  /// The view is opening the session.
  void beginConnect() {
    state = state.copyWith(
      phase: RemoteAssistanceConfirmPhase.connecting,
      clearError: true,
    );
  }

  /// Opening the session failed: back to a joinable session, with the reason.
  void connectFailed(String message) {
    state = state.copyWith(
      phase: RemoteAssistanceConfirmPhase.validated,
      errorMessage: message,
    );
  }

  void _fail(String message, {GRASessionInfo? sessionInfo}) {
    state = state.copyWith(
      phase: RemoteAssistanceConfirmPhase.error,
      errorMessage: message,
      sessionInfo: sessionInfo,
    );
  }

  void _startCountdown() {
    _countdown?.cancel();
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.remainingSeconds;
      if (remaining == null || remaining <= 0) {
        timer.cancel();
        state = state.copyWith(
          phase: RemoteAssistanceConfirmPhase.error,
          remainingSeconds: 0,
          errorMessage: 'Session has expired',
        );
        return;
      }
      state = state.copyWith(remainingSeconds: remaining - 1);
    });
  }

  static String _messageFor(ServiceError error) => switch (error) {
        TimeoutError() => 'Connection timed out. Please try again.',
        SessionTokenExpiredError() => 'Token expired or invalid',
        UnauthorizedError() => 'Unauthorized - invalid token',
        ResourceNotFoundError() => 'Session not found',
        NetworkError(:final detail) =>
          'Network error${detail != null ? ': $detail' : ' - please try again'}',
        InvalidInputError(:final detail) =>
          'Invalid input${detail != null ? ': $detail' : ''}',
        UnexpectedError(:final detail) =>
          'Validation failed${detail != null ? ': $detail' : ''}',
        _ => 'Validation failed: ${error.toString()}',
      };

  /// The status badge's label.
  static String statusText(GRASessionStatus status) => switch (status) {
        GRASessionStatus.active => 'Active',
        GRASessionStatus.pending => 'Pending',
        GRASessionStatus.initiate => 'Initiating',
        GRASessionStatus.invalid => 'Invalid',
      };
}
