import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/ai/_ai.dart';

/// Provider for the USP-based router command provider.
///
/// Reads from existing dashboard providers (L1 cache) to avoid duplicate fetches.
final routerCommandProviderProvider = Provider<IRouterCommandProvider>((ref) {
  return UspCommandProvider(ref);
});

/// Builds the router state summary on demand, for the chat's system prompt.
///
/// Exists so the summary can be rebuilt per request without the caller holding a
/// `WidgetRef`. The chat controller assembles its system prompt inside a loop
/// that spans `await`s, and the view that started the exchange can be gone by a
/// later round — `WidgetRef.read` throws once its widget is disposed, whereas
/// this closure captures a ref owned by the container and stays callable.
///
/// Must not be `autoDispose`: a disposed provider's ref throws in the same way,
/// which would reintroduce exactly the failure this avoids.
final routerContextBuilderProvider = Provider<String Function()>((ref) {
  return () => buildRouterContext(ref.read);
});
