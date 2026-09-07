import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/instant_verify/prototypes/mock_pivot_notifier.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/services/browser_diagnostic_service.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_page.dart';

/// The selected single-page design, with simulated diagnostics and actions.
/// This prototype route never uses router data or executes router mutations.
class PrototypeRoot extends StatelessWidget {
  const PrototypeRoot({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
        overrides: [
          browserDiagnosticServiceProvider
              .overrideWithValue(MockBrowserDiagnosticService()),
          instantVerifyPivotProvider
              .overrideWith(MockInstantVerifyPivotNotifier.new),
        ],
        child: Scaffold(
          appBar: AppBar(title: const Text('Instant-Test preview')),
          body: const InstantTestPage(),
        ),
      );
}
