import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/apps/services/usp_apps_service.dart';

/// Whether the router supports the modular apps feature.
///
/// Performs a one-shot GET to `/api/apps.json` via [UspAppsService] on first watch.
/// Returns `true` if the endpoint responds 200, `false` otherwise (404, timeout, etc.).
///
/// NOT autoDispose — result is cached for the session lifetime.
/// A page reload re-evaluates.
final appsCapabilityProvider = FutureProvider<bool>((ref) async {
  try {
    final svc = ref.read(uspAppsServiceProvider);
    await svc.fetchApps().timeout(const Duration(seconds: 5));
    logger.d('[Apps] capability check: supported');
    return true;
  } catch (e) {
    logger.d('[Apps] capability check failed: $e');
    return false;
  }
});
