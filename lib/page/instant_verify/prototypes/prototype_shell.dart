import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_page.dart';
import 'demo_controls.dart';

/// The selected single-page design, with simulated diagnostics and actions.
/// This prototype route never uses router data or executes router mutations.
class PrototypeRoot extends StatefulWidget {
  const PrototypeRoot({super.key});

  @override
  State<PrototypeRoot> createState() => _PrototypeRootState();
}

class _PrototypeRootState extends State<PrototypeRoot> {
  MockBrowserDiagnosticService? _service;
  String? _configuration;
  int _overview = 3;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A workflow route change must not reset a fixture's probe history.
    // A changed demo configuration (or a new run key) starts fresh state.
    final query = GoRouterState.of(context).uri.queryParameters;
    final scenario = PreviewProbeScenario.values.firstWhere(
        (value) => value.name == query['probe'],
        orElse: () => PreviewProbeScenario.healthy);
    final overview = int.tryParse(query['overview'] ?? '') ?? 3;
    _overview = overview >= 0 && overview < 5 ? overview : 3;
    final configuration = '${scenario.name}:$_overview:${query['run'] ?? ''}';
    if (_configuration != configuration) {
      _configuration = configuration;
      _service = MockBrowserDiagnosticService(scenario: scenario);
    }
  }

  @override
  Widget build(BuildContext context) => ProviderScope(
        key: ValueKey(_configuration),
        overrides: [
          browserDiagnosticServiceProvider.overrideWithValue(_service!),
          instantVerifyPivotProvider
              .overrideWith(() => MockInstantVerifyPivotNotifier(overviewScenario: _overview, actionScenario: _service!.scenario)),
        ],
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Instant-Test preview'),
            actions: [DemoControls(overview: _overview, probe: _service!.scenario)],
          ),
          body: const InstantTestPage(),
        ),
      );
}
