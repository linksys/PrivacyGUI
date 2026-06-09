import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/ai/_ai.dart';

/// Provider for the USP-based router command provider.
///
/// Reads from existing dashboard providers (L1 cache) to avoid duplicate fetches.
final routerCommandProviderProvider = Provider<IRouterCommandProvider>((ref) {
  return UspCommandProvider(ref);
});
