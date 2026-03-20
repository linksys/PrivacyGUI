import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Stub router password provider.
///
/// TODO: Re-implement using USP when router password recovery is available.
/// Previously dependent on JNAP instant_admin providers.
final routerPasswordProvider =
    NotifierProvider.autoDispose<RouterPasswordNotifier, RouterPasswordState>(
        () => RouterPasswordNotifier());

class RouterPasswordState {
  final int? remainingErrorAttempts;
  final bool isValid;

  const RouterPasswordState({
    this.remainingErrorAttempts,
    this.isValid = false,
  });

  RouterPasswordState copyWith({
    int? remainingErrorAttempts,
    bool? isValid,
  }) {
    return RouterPasswordState(
      remainingErrorAttempts:
          remainingErrorAttempts ?? this.remainingErrorAttempts,
      isValid: isValid ?? this.isValid,
    );
  }
}

class RouterPasswordNotifier extends AutoDisposeNotifier<RouterPasswordState> {
  @override
  RouterPasswordState build() => const RouterPasswordState();

  Future<bool> checkRecoveryCode(String code) async {
    logger.i('[RouterPassword]: checkRecoveryCode — stubbed (USP mode)');
    return false;
  }

  void setValidate(bool isValid) {
    state = state.copyWith(isValid: isValid);
  }

  Future<void> setAdminPasswordWithResetCode(
      String password, String hint, String code) async {
    logger.i(
        '[RouterPassword]: setAdminPasswordWithResetCode — stubbed (USP mode)');
    throw UnimplementedError(
        'Router password reset not yet available in USP mode');
  }
}
