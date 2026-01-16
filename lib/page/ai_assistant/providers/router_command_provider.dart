import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/ai/_ai.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';

/// Provider for the command provider.
final routerCommandProviderProvider = Provider<IRouterCommandProvider>((ref) {
  final router = ref.watch(routerRepositoryProvider);
  return JnapCommandProvider(router);
});
