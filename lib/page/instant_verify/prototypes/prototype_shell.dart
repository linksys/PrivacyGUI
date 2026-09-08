import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_page.dart';

/// The selected single-page design, with simulated diagnostics and actions.
/// This prototype route never uses router data or executes router mutations.
class PrototypeRoot extends StatefulWidget {
  const PrototypeRoot({super.key});

  @override
  State<PrototypeRoot> createState() => _PrototypeRootState();
}

class _PrototypeRootState extends State<PrototypeRoot> {
  MockBrowserDiagnosticService? _service;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A workflow route change must not reset a fixture's probe history.
    // Select a new fixture by loading a fresh preview document.
    _service ??= MockBrowserDiagnosticService(
      scenario: PreviewProbeScenario.values.firstWhere(
        (value) => value.name == GoRouterState.of(context).uri.queryParameters['probe'],
        orElse: () => PreviewProbeScenario.healthy));
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: [
          browserDiagnosticServiceProvider.overrideWithValue(_service!),
          instantVerifyPivotProvider
              .overrideWith(MockInstantVerifyPivotNotifier.new),
        ],
        child: Scaffold(
          appBar: AppBar(title: const Text('Instant-Test preview')),
          body: const InstantTestPage(),
        ),
      );
}
