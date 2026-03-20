import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/ai/_ai.dart';

/// Provider for the command provider.
///
/// TODO: Replace stub with USP-based IRouterCommandProvider implementation.
final routerCommandProviderProvider = Provider<IRouterCommandProvider>((ref) {
  return _StubCommandProvider();
});

/// Stub implementation that returns empty results.
/// Replace with USP-based implementation when ready.
class _StubCommandProvider implements IRouterCommandProvider {
  @override
  Future<List<RouterCommand>> listCommands() async => [];

  @override
  Future<RouterCommandResult> execute(
    String commandName,
    Map<String, dynamic> params,
  ) async {
    throw CommandExecutionException(
      commandName,
      'USP command provider not yet implemented',
    );
  }

  @override
  List<RouterResourceDescriptor> listResources() => [];

  @override
  Future<RouterResource> readResource(String resourceUri) async {
    throw ResourceNotFoundException(resourceUri);
  }
}
