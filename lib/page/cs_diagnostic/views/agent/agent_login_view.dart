import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/cs_diagnostic/providers/cs_diagnostic_auth_provider.dart';

class AgentLoginView extends ConsumerStatefulWidget {
  const AgentLoginView({super.key});

  @override
  ConsumerState<AgentLoginView> createState() => _AgentLoginViewState();
}

class _AgentLoginViewState extends ConsumerState<AgentLoginView> {
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(diagnosticAuthProvider);
    final isLoading = authState.status == DiagnosticAuthStatus.authenticating;

    return Padding(
      padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Support Login', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the router admin password to enable advanced diagnostics.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6)),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            obscureText: _obscureText,
            enabled: !isLoading,
            decoration: InputDecoration(
              labelText: 'Router Admin Password',
              border: const OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(_obscureText ? Icons.visibility : Icons.visibility_off),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              ),
              errorText: authState.status == DiagnosticAuthStatus.error ? authState.errorMessage : null,
            ),
            onSubmitted: (_) => _attemptLogin(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isLoading ? null : _attemptLogin,
              child: isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Log In'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _attemptLogin() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) return;
    final success = await ref.read(diagnosticAuthProvider.notifier).login(password);
    if (success && mounted) {
      Navigator.pop(context);
    }
  }
}
