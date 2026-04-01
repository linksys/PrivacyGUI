import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

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
  String get authHeader => 'Basic ${base64Encode(utf8.encode('admin:${password ?? ''}'))}';
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
      final authHeader = 'Basic ${base64Encode(utf8.encode('admin:$password'))}';
      final response = await http.post(
        Uri.parse('http://192.168.1.1/JNAP/'),
        headers: {
          'Content-Type': 'application/json',
          'X-JNAP-Action': 'http://linksys.com/jnap/core/GetDeviceInfo',
          'X-JNAP-Authorization': authHeader,
        },
        body: '{}',
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body) as Map<String, dynamic>;
        if (body['result'] == 'OK') {
          state = state.copyWith(status: DiagnosticAuthStatus.authenticated, password: password);
          return true;
        }
      }
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
