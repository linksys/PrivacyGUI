import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:mockito/mockito.dart';

class MockSimpleAuthNotifier extends AuthNotifier with Mock {
  @override
  AsyncValue<AuthState> get state =>
      const AsyncData(AuthState(loginType: LoginType.local));

  @override
  set state(AsyncValue<AuthState> newState) {
    super.state = newState;
  }
}
