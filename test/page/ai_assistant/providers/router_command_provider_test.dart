import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/ai/_ai.dart';
import 'package:privacy_gui/page/ai_assistant/providers/router_command_provider.dart';

/// Hands the builder it obtained during `initState` back to the test, so the
/// test can keep calling it after this widget is gone.
class _BuilderCaptor extends ConsumerStatefulWidget {
  const _BuilderCaptor({required this.onBuilder});

  final void Function(String Function()) onBuilder;

  @override
  ConsumerState<_BuilderCaptor> createState() => _BuilderCaptorState();
}

class _BuilderCaptorState extends ConsumerState<_BuilderCaptor> {
  @override
  void initState() {
    super.initState();
    widget.onBuilder(ref.read(routerContextBuilderProvider));
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  group('routerCommandProviderProvider', () {
    test('provides UspCommandProvider instance', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(routerCommandProviderProvider);

      expect(provider, isA<IRouterCommandProvider>());
      expect(provider, isA<UspCommandProvider>());
    });

    test('returns same instance on multiple reads', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider1 = container.read(routerCommandProviderProvider);
      final provider2 = container.read(routerCommandProviderProvider);

      expect(identical(provider1, provider2), isTrue);
    });

    test('provides access to available commands', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(routerCommandProviderProvider);
      final commands = await provider.listCommands();

      expect(commands, isNotEmpty);
      expect(commands.any((c) => c.name == 'getSystemInfo'), isTrue);
      expect(commands.any((c) => c.name == 'getConnectedDevices'), isTrue);
      expect(commands.any((c) => c.name == 'getWifiSettings'), isTrue);
    });

    test('provides access to available resources', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final provider = container.read(routerCommandProviderProvider);
      final resources = provider.listResources();

      expect(resources, isNotEmpty);
      expect(resources.any((r) => r.uri == 'router://system'), isTrue);
      expect(resources.any((r) => r.uri == 'router://devices'), isTrue);
    });
  });

  group('routerContextBuilderProvider', () {
    test('builds a summary on each call', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final build = container.read(routerContextBuilderProvider);

      expect(build(), contains('Current Router State'));
      expect(build(), contains('Current Router State'));
    });

    // The class comment forbids `autoDispose`: a disposed provider's ref throws
    // exactly like a disposed widget's, which is the failure this provider
    // exists to avoid. Nothing enforced that, and the widget test below does
    // NOT catch it — with `autoDispose` the captured closure still answers
    // there, so the regression would land silently.
    test('is not autoDispose', () {
      expect(
        routerContextBuilderProvider,
        isNot(isA<AutoDisposeProvider<String Function()>>()),
        reason: 'autoDispose would let the provider be disposed while the chat '
            'controller still holds its builder',
      );
    });

    // The chat controller assembles its system prompt inside a loop that spans
    // `await`s, so a later round can run after the user has navigated away. A
    // builder closing over `WidgetRef` throws there — "Cannot use ref after the
    // widget was disposed" — and takes the exchange down with it.
    testWidgets('stays callable after the widget that obtained it is disposed',
        (tester) async {
      String Function()? build;

      await tester.pumpWidget(ProviderScope(
        child: _BuilderCaptor(onBuilder: (b) => build = b),
      ));
      expect(build, isNotNull);
      expect(build!(), contains('Current Router State'));

      // The user leaves the chat while an exchange is still in flight.
      await tester.pumpWidget(const ProviderScope(child: SizedBox()));

      expect(build!, returnsNormally);
      expect(build!(), contains('Current Router State'));
    });
  });
}
