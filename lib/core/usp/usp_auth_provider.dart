import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:usp_ui_flutter/core/usp/environment.dart';
import 'package:usp_ui_flutter/core/usp/usp_auth.dart';

final secureStorageProvider = Provider<FlutterSecureStorage>((ref) {
  return const FlutterSecureStorage();
});

final uspAuthProvider = Provider<UspAuth>((ref) {
  // Use UspEnvironment.baseUrl which returns empty string on web (relative URL)
  // and full URL on native platforms.
  // Auth endpoint: /api/auth/login
  final authEndpoint = '${UspEnvironment.baseUrl}/api/auth/login';
  final storage = ref.watch(secureStorageProvider);
  final auth = UspAuth(
    authEndpoint: authEndpoint,
    storage: storage,
  );
  auth.initialize();
  return auth;
});

final authStateProvider = StreamProvider<bool>((ref) async* {
  final auth = ref.watch(uspAuthProvider);
  await auth.initialize();
  yield auth.isAuthenticated;
  while (true) {
    await Future.delayed(const Duration(seconds: 30));
    yield auth.isAuthenticated;
  }
});
