import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_auth_provider.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/customer/customer_home_view.dart';
import 'package:privacy_gui/page/cs_diagnostic/views/agent/agent_dashboard_view.dart';

class DiagnosticEntryView extends ConsumerWidget {
  const DiagnosticEntryView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(diagnosticAuthProvider);
    return authState.isAuthenticated
        ? const AgentDashboardView()
        : const CustomerHomeView();
  }
}
