import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/wan_external.dart';
import 'package:privacy_gui/page/instant_verify/models/instant_verify_ui_models.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/core/utils/logger.dart';

/// Riverpod provider for WanExternalService.
final wanExternalServiceProvider = Provider<WanExternalService>((ref) {
  return WanExternalService(ref.watch(routerRepositoryProvider));
});

/// Stateless service for WAN external data operations.
///
/// Handles JNAP communication for retrieving WAN external IP information.
/// Transforms JNAP data models to UI models for the presentation layer.
class WanExternalService {
  final RouterRepository _routerRepository;

  WanExternalService(this._routerRepository);

  /// Fetches WAN external IP information from router.
  ///
  /// [force] - If true, bypasses cache and fetches from device.
  ///           Default: false (may use cached data).
  ///
  /// Returns: [WanExternalUIModel] with public/private IPv4/IPv6 addresses.
  ///
  /// Throws:
  /// - [UnauthorizedError] if authentication fails
  /// - [UnexpectedError] for other JNAP errors
  Future<WanExternalUIModel> fetchWanExternal({bool force = false}) async {
    try {
      final result = await _routerRepository.send(
        JNAPAction.getWANExternal,
        fetchRemote: force,
        timeoutMs: 30000,
      );
      final wanExternal = WanExternal.fromMap(result.output);
      final uiModel = WanExternalUIModel.fromJnap(wanExternal);
      logger.d('[Service]:[WanExternal]: Fetched ${uiModel.toJson()}');
      return uiModel;
    } on JNAPError catch (e) {
      throw _mapJnapError(e);
    }
  }

  /// Maps JNAP errors to ServiceError types.
  ServiceError _mapJnapError(JNAPError error) {
    return switch (error.result) {
      '_ErrorUnauthorized' => const UnauthorizedError(),
      _ => UnexpectedError(originalError: error, message: error.result),
    };
  }
}
