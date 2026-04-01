import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/utils.dart';

enum DiagnosticAuthStatus { unauthenticated, authenticating, authenticated, error }

class DiagnosticAuthState {
  final DiagnosticAuthStatus status;
  final String? password;
  final String? errorMessage;

  const DiagnosticAuthState({
    this.status = DiagnosticAuthStatus.unauthenticated,
    this.password,
    this.errorMessage,
  });

  DiagnosticAuthState copyWith({
    DiagnosticAuthStatus? status,
    String? password,
    String? errorMessage,
  }) => DiagnosticAuthState(
    status: status ?? this.status,
    password: password ?? this.password,
    errorMessage: errorMessage,
  );

  bool get isAuthenticated => status == DiagnosticAuthStatus.authenticated;

  /// Auth headers for RouterRepository extraHeaders parameter.
  Map<String, String> get authHeaders => password != null
      ? {kJNAPAuthorization: 'Basic ${Utils.stringBase64Encode('admin:$password')}'}
      : const {};
}

final diagnosticAuthProvider = NotifierProvider<DiagnosticAuthNotifier, DiagnosticAuthState>(
  DiagnosticAuthNotifier.new,
);

class DiagnosticAuthNotifier extends Notifier<DiagnosticAuthState> {
  bool mockMode = false;

  @override
  DiagnosticAuthState build() => const DiagnosticAuthState();

  Future<bool> login(String password) async {
    state = state.copyWith(status: DiagnosticAuthStatus.authenticating);

    // In mock mode, accept any non-empty password
    if (mockMode) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      state = state.copyWith(status: DiagnosticAuthStatus.authenticated, password: password);
      return true;
    }

    try {
      final authHeaders = {
        kJNAPAuthorization: 'Basic ${Utils.stringBase64Encode('admin:$password')}',
      };

      // Validate credentials via RouterRepository
      final repo = ref.read(routerRepositoryProvider);
      await repo.send(
        JNAPAction.getDeviceInfo,
        extraHeaders: authHeaders,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      );

      // If send() succeeds (no exception), credentials are valid
      state = state.copyWith(status: DiagnosticAuthStatus.authenticated, password: password);
      return true;
    } on JNAPError catch (_) {
      state = state.copyWith(
        status: DiagnosticAuthStatus.error,
        errorMessage: 'Incorrect password. Check your router admin password.',
      );
      return false;
    } catch (e) {
      state = state.copyWith(
        status: DiagnosticAuthStatus.error,
        errorMessage: 'Could not reach the router. Make sure you are connected to the network.',
      );
      return false;
    }
  }

  void logout() {
    state = const DiagnosticAuthState();
  }
}
