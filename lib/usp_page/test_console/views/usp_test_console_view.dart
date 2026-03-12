import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp/web/usp_wasm_init.dart';
import 'package:privacy_gui/generated/tr181_paths.g.dart';
import 'package:privacy_gui/usp_page/test_console/widgets/tr181_autocomplete_field.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Shell-compatible USP test console integrated into the USP menu.
///
/// Reuses the shared [UspService] session when available, with manual
/// override for connecting to a different endpoint.
class UspTestConsoleView extends ConsumerStatefulWidget {
  const UspTestConsoleView({super.key});

  @override
  ConsumerState<UspTestConsoleView> createState() => _UspTestConsoleViewState();
}

class _UspTestConsoleViewState extends ConsumerState<UspTestConsoleView> {
  final _urlController = TextEditingController();
  final _passwordController = TextEditingController(text: 'admin');
  final _getPathController =
      TextEditingController(text: 'Device.DeviceInfo.Manufacturer');
  final _setPathController = TextEditingController();
  final _setValueController = TextEditingController();
  final _addPathController = TextEditingController();
  final _addParamsController = TextEditingController(text: '{}');
  final _deletePathController = TextEditingController();
  final _operateCommandController = TextEditingController();
  final _operateArgsController = TextEditingController(text: '{}');
  final _subIdController = TextEditingController(text: 'test-sub-1');
  final _subPathController = TextEditingController(text: 'Device.Hosts.Host.');
  final _logScrollController = ScrollController();

  UspService? _service;
  UspBridgeClient? _bridgeClient;
  bool _isConnected = false;
  bool _usingSharedSession = false;
  bool _showManualOverride = false;
  final List<String> _logs = [];

  // SSE state
  StreamSubscription<SseEvent>? _sseSub;
  bool _sseConnected = false;

  // Subscription notif type
  int _notifType = 1;

  @override
  void initState() {
    super.initState();
    // Try to inject shared UspService from the app's provider tree.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryInjectSharedService();
    });
  }

  void _tryInjectSharedService() {
    final shared = ref.read(uspServiceProvider);
    if (shared != null && shared.isAuthenticated) {
      _service = shared;
      _bridgeClient = UspBridgeClient(shared);
      _urlController.text = shared.baseUrl;
      setState(() {
        _isConnected = true;
        _usingSharedSession = true;
      });
      _log('Using shared session (${shared.baseUrl})');
    } else {
      setState(() => _showManualOverride = true);
      _log('No shared session — use manual connection');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Logging
  // ════════════════════════════════════════════════════════════════════════════

  void _log(String message) {
    final timestamp = DateTime.now().toIso8601String().substring(11, 23);
    setState(() {
      _logs.add('[$timestamp] $message');
    });
    Future.microtask(() {
      if (_logScrollController.hasClients) {
        _logScrollController
            .jumpTo(_logScrollController.position.maxScrollExtent);
      }
    });
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Connection (manual override)
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _connect() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    try {
      _log('Waiting for WASM client initialization...');
      final ready = await ensureUspWasmInitialized();
      if (!ready) {
        _log('ERROR: WASM client failed to initialize');
        return;
      }
      _log('WASM client ready');
      final svc = UspService(url);
      _service = svc;
      _bridgeClient = UspBridgeClient(svc);
      _log('Client created for $url');
      setState(() {
        _isConnected = false;
        _usingSharedSession = false;
      });
    } catch (e) {
      _log('ERROR creating client: $e');
    }
  }

  Future<void> _login() async {
    if (_service == null) await _connect();
    final password = _passwordController.text;
    _log('Login with password: ${'*' * password.length}');
    try {
      await _service!.login(password);
      setState(() {
        _isConnected = _service!.isAuthenticated;
        _usingSharedSession = false;
      });
      _log('Login result: isAuthenticated=${_service!.isAuthenticated}');
      final token = _service!.sessionToken;
      if (token != null) {
        _log('Token available (${token.length} chars)');
      } else {
        _log('WARNING: sessionToken is null');
      }
    } catch (e) {
      _log('ERROR login: $e');
    }
  }

  Future<void> _logout() async {
    if (_service == null) return;
    if (_usingSharedSession) {
      _log('Cannot logout shared session from console');
      return;
    }
    _log('Logout...');
    try {
      await _sseSub?.cancel();
      _sseSub = null;
      setState(() => _sseConnected = false);
      await _service!.logout();
      setState(() => _isConnected = false);
      _log('Logged out');
    } catch (e) {
      _log('ERROR logout: $e');
    }
  }

  Future<void> _refreshToken() async {
    if (_service == null) return;
    _log('Refreshing token...');
    try {
      await _service!.refreshToken();
      _log('Token refreshed, isAuthenticated=${_service!.isAuthenticated}');
    } catch (e) {
      _log('ERROR refreshToken: $e');
    }
  }

  /// Switch back to shared session (if available)
  void _useSharedSession() {
    final shared = ref.read(uspServiceProvider);
    if (shared != null && shared.isAuthenticated) {
      _service = shared;
      _bridgeClient = UspBridgeClient(shared);
      _urlController.text = shared.baseUrl;
      setState(() {
        _isConnected = true;
        _usingSharedSession = true;
        _showManualOverride = false;
      });
      _log('Switched to shared session (${shared.baseUrl})');
    } else {
      _log('No shared session available');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // USP CRUD operations
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _doGet() async {
    if (_service == null) return;
    final path = _getPathController.text.trim();
    if (path.isEmpty) return;
    final paths = path.split(',').map((p) => p.trim()).toList();
    _log('GET ${paths.length == 1 ? paths.first : paths.toString()}');
    try {
      final result = await _service!.get(paths);
      for (final entry in result.entries) {
        _log('  ${entry.key} = ${entry.value} (${entry.value.runtimeType})');
      }
    } catch (e) {
      _log('ERROR get: $e');
    }
  }

  Future<void> _doSet() async {
    if (_service == null) return;
    final path = _setPathController.text.trim();
    final value = _setValueController.text;
    if (path.isEmpty) return;
    _log('SET $path = $value');
    try {
      await _service!.set({path: value});
      _log('SET OK');
    } catch (e) {
      _log('ERROR set: $e');
    }
  }

  Future<void> _doAdd() async {
    if (_service == null) return;
    final path = _addPathController.text.trim();
    final paramsJson = _addParamsController.text.trim();
    if (path.isEmpty) return;
    _log('ADD $path params=$paramsJson');
    try {
      final params =
          Map<String, String>.from(jsonDecode(paramsJson) as Map? ?? {});
      final created = await _service!.add(path, params);
      _log('ADD OK -> created: $created');
    } catch (e) {
      _log('ERROR add: $e');
    }
  }

  Future<void> _doDelete() async {
    if (_service == null) return;
    final path = _deletePathController.text.trim();
    if (path.isEmpty) return;
    _log('DELETE $path');
    try {
      await _service!.delete(path);
      _log('DELETE OK');
    } catch (e) {
      _log('ERROR delete: $e');
    }
  }

  Future<void> _doOperate() async {
    if (_service == null) return;
    final command = _operateCommandController.text.trim();
    final argsJson = _operateArgsController.text.trim();
    if (command.isEmpty) return;
    _log('OPERATE $command args=$argsJson');
    try {
      final args = Map<String, String>.from(jsonDecode(argsJson) as Map? ?? {});
      final result = await _service!.operate(command, args: args);
      if (result.isEmpty) {
        _log('OPERATE OK (no output)');
      } else {
        for (final entry in result.entries) {
          _log('  ${entry.key} = ${entry.value}');
        }
      }
    } catch (e) {
      _log('ERROR operate: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Bridge: Health
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _doHealth() async {
    if (_bridgeClient == null) return;
    _log('HEALTH check...');
    try {
      final result = await _bridgeClient!.health();
      _log('HEALTH: ${jsonEncode(result)}');
    } catch (e) {
      _log('ERROR health: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Bridge: SSE Notifications
  // ════════════════════════════════════════════════════════════════════════════

  void _sseConnect() {
    if (_bridgeClient == null) return;
    if (_sseConnected) {
      _log('SSE already connected');
      return;
    }
    _log('SSE connecting...');
    try {
      final stream = _bridgeClient!.notifications();
      _sseSub = stream.listen(
        (event) {
          if (event.event == '_debug') {
            _log('SSE [debug] ${event.data}');
          } else {
            _log('SSE [${event.event}] ${event.data}');
          }
        },
        onError: (e) {
          _log('SSE ERROR: $e');
          setState(() => _sseConnected = false);
        },
        onDone: () {
          _log('SSE stream closed');
          setState(() => _sseConnected = false);
        },
      );
      setState(() => _sseConnected = true);
      _log('SSE listener attached');
    } catch (e) {
      _log('ERROR SSE connect: $e');
    }
  }

  Future<void> _sseDisconnect() async {
    if (!_sseConnected) return;
    _log('SSE disconnecting...');
    await _sseSub?.cancel();
    _sseSub = null;
    setState(() => _sseConnected = false);
    _log('SSE disconnected');
  }

  Future<void> _sseProbe() async {
    if (_bridgeClient == null) return;
    _log('SSE PROBE: testing /api/v1/notifications via http.get...');
    try {
      final result = await _bridgeClient!.notificationsProbe();
      _log('SSE PROBE: status=${result['status']} '
          'contentType=${result['contentType']} '
          'bodyLength=${result['bodyLength']}');
      _log('SSE PROBE body (first 500): ${result['bodyPreview']}');
    } catch (e) {
      _log('SSE PROBE ERROR: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Bridge: Subscription
  // ════════════════════════════════════════════════════════════════════════════

  /// Creates an OBUSPA subscription via USP Add + Set (through WASM client).
  /// This ensures Recipient auto-points to Controller.2 (usp-bridge / UDS),
  /// which is required for OperationComplete notifications to reach SSE.
  Future<void> _doCreateUspSubscription() async {
    if (_service == null) return;
    final refList = _subPathController.text.trim();
    if (refList.isEmpty) return;
    final typeNames = {
      1: 'ValueChange',
      2: 'ObjectCreation',
      3: 'ObjectDeletion',
      4: 'OperationComplete',
      5: 'Event',
    };
    final typeName = typeNames[_notifType] ?? 'Unknown';
    _log('CREATE USP Subscription: refList=$refList type=$typeName');
    try {
      final result = await _service!.createNotifySubscription(
        notifType: typeName,
        referenceList: refList,
      );
      for (final e in result.entries) {
        final key = e.key.contains('.') ? e.key.split('.').last : e.key;
        _log('  $key = ${e.value}');
      }
      final recipient = result.values
          .firstWhere((v) => v.contains('Controller.'), orElse: () => '');
      if (recipient.isNotEmpty) {
        _log('CREATE USP Subscription OK');
      } else {
        _log('WARNING: Recipient not found — SSE delivery may not work');
      }
    } catch (e) {
      _log('ERROR createUspSubscription: $e');
    }
  }

  Future<void> _doSubscribe() async {
    if (_bridgeClient == null) return;
    final subId = _subIdController.text.trim();
    final path = _subPathController.text.trim();
    if (subId.isEmpty || path.isEmpty) return;
    final typeNames = {
      1: 'ValueChange',
      2: 'ObjectCreation',
      3: 'ObjectDeletion',
      4: 'OperationComplete',
      5: 'Event',
    };
    _log('SUBSCRIBE id=$subId path=$path type=${typeNames[_notifType]}');
    try {
      final result = await _bridgeClient!.subscribe(
        subscriptionId: subId,
        path: path,
        notifType: _notifType,
      );
      _log('SUBSCRIBE result: ${jsonEncode(result)}');
    } catch (e) {
      _log('ERROR subscribe: $e');
    }
  }

  Future<void> _doUnsubscribe() async {
    if (_bridgeClient == null) return;
    final subId = _subIdController.text.trim();
    if (subId.isEmpty) return;
    _log('UNSUBSCRIBE id=$subId');
    try {
      final result = await _bridgeClient!.unsubscribe(subscriptionId: subId);
      _log('UNSUBSCRIBE result: ${jsonEncode(result)}');
    } catch (e) {
      _log('ERROR unsubscribe: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Bridge: Turbo Channel
  // ════════════════════════════════════════════════════════════════════════════

  Future<void> _doTurbo(String action) async {
    if (_bridgeClient == null) return;
    _log('TURBO $action...');
    try {
      final Map<String, dynamic> result;
      switch (action) {
        case 'start':
          result = await _bridgeClient!.turboStart();
        case 'heartbeat':
          result = await _bridgeClient!.turboHeartbeat();
        case 'status':
          result = await _bridgeClient!.turboStatus();
        case 'release':
          result = await _bridgeClient!.turboRelease();
        default:
          _log('ERROR: unknown turbo action: $action');
          return;
      }
      _log('TURBO $action: ${jsonEncode(result)}');
    } catch (e) {
      _log('ERROR turbo $action: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _sseSub?.cancel();
    // Only dispose self-created services, NOT the shared singleton.
    if (!_usingSharedSession) {
      _service?.dispose();
    }
    _urlController.dispose();
    _passwordController.dispose();
    _getPathController.dispose();
    _setPathController.dispose();
    _setValueController.dispose();
    _addPathController.dispose();
    _addParamsController.dispose();
    _deletePathController.dispose();
    _operateCommandController.dispose();
    _operateArgsController.dispose();
    _subIdController.dispose();
    _subPathController.dispose();
    _logScrollController.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Build
  // ════════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      hideTopbar: true,
      backState: UiKitBackState.none,
      scrollable: false,
      padding: EdgeInsets.zero,
      child: (childContext, constraints) {
        return Column(
          children: [
            _buildHeader(childContext),
            Expanded(
              child: Row(
                children: [
                  // Left: Controls
                  Expanded(
                    flex: 1,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildConnectionSection(),
                          const Divider(height: 32),
                          _buildGetSection(),
                          const Divider(height: 32),
                          _buildSetSection(),
                          const Divider(height: 32),
                          _buildAddSection(),
                          const Divider(height: 32),
                          _buildDeleteSection(),
                          const Divider(height: 32),
                          _buildOperateSection(),
                          const Divider(height: 32),
                          _buildHealthSection(),
                          const Divider(height: 32),
                          _buildSseSection(),
                          const Divider(height: 32),
                          _buildSubscriptionSection(),
                          const Divider(height: 32),
                          _buildTurboSection(),
                        ],
                      ),
                    ),
                  ),
                  const VerticalDivider(width: 1),
                  // Right: Log panel
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              AppText.titleSmall('Log'),
                              const Spacer(),
                              AppIconButton(
                                icon: AppIcon.font(Icons.copy, size: 18),
                                onTap: () {
                                  Clipboard.setData(
                                      ClipboardData(text: _logs.join('\n')));
                                },
                              ),
                              AppIconButton(
                                icon: AppIcon.font(Icons.delete_outline,
                                    size: 18),
                                onTap: () => setState(() => _logs.clear()),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        Expanded(
                          child: SelectionArea(
                            child: ListView.builder(
                              controller: _logScrollController,
                              padding: const EdgeInsets.all(8),
                              itemCount: _logs.length,
                              itemBuilder: (context, index) {
                                final log = _logs[index];
                                final isError = log.contains('ERROR');
                                final isSse = log.contains('SSE');
                                final colorScheme =
                                    Theme.of(context).colorScheme;
                                return Text(
                                  log,
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: isError
                                        ? colorScheme.error
                                        : isSse
                                            ? colorScheme.primary
                                            : colorScheme.onSurface,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Header
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.md),
      child: Row(
        children: [
          AppIconButton(
            icon: AppIcon.font(Icons.arrow_back),
            onTap: () => context.canPop()
                ? context.pop()
                : context.goNamed(RouteNamed.uspMenu),
          ),
          AppGap.md(),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppText.headlineSmall('USP Console'),
                AppText.bodySmall(
                  'Raw USP CRUD, SSE, subscription & turbo debug tool',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
          // Status badges
          if (_sseConnected)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _buildStatusBadge(
                context,
                label: 'SSE',
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          _buildStatusBadge(
            context,
            label: _usingSharedSession
                ? 'Shared Session'
                : _isConnected
                    ? 'Authenticated'
                    : 'Not Connected',
            color: _isConnected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(
    BuildContext context, {
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: AppText.labelSmall(label, color: color),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // Section builders
  // ════════════════════════════════════════════════════════════════════════════

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppText.titleSmall(title),
    );
  }

  Widget _buildConnectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            _buildSectionTitle('Connection'),
            const Spacer(),
            if (_usingSharedSession && !_showManualOverride)
              AppButton.text(
                label: 'Override',
                onTap: () => setState(() => _showManualOverride = true),
              ),
            if (_showManualOverride && _usingSharedSession)
              AppButton.text(
                label: 'Use Shared',
                onTap: _useSharedSession,
              ),
          ],
        ),
        if (_showManualOverride || !_usingSharedSession) ...[
          AppTextField(
            controller: _urlController,
            hintText: 'Base URL',
          ),
          const SizedBox(height: 8),
          AppTextField(
            controller: _passwordController,
            obscureText: true,
            hintText: 'Password',
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              AppButton.primary(label: 'Login', onTap: _login),
              AppButton.primaryOutline(label: 'Logout', onTap: _logout),
              AppButton.primaryOutline(
                  label: 'Refresh Token', onTap: _refreshToken),
            ],
          ),
        ],
        if (!_showManualOverride && _usingSharedSession)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: AppText.bodySmall(
              'Connected via shared app session (${_urlController.text})',
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
      ],
    );
  }

  Widget _buildGetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Get'),
        Tr181AutocompleteField(
          controller: _getPathController,
          labelText: 'Path(s) — comma separated for multiple',
          supportsMultiple: true,
        ),
        const SizedBox(height: 8),
        AppButton.primary(label: 'Get', onTap: _doGet),
      ],
    );
  }

  Widget _buildSetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Set'),
        Tr181AutocompleteField(
          controller: _setPathController,
          labelText: 'Path',
          pathTypeFilter: const {Tr181PathType.parameter},
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _setValueController,
          hintText: 'Value',
        ),
        const SizedBox(height: 8),
        AppButton.primary(label: 'Set', onTap: _doSet),
      ],
    );
  }

  Widget _buildAddSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Add'),
        Tr181AutocompleteField(
          controller: _addPathController,
          labelText: 'Object Path (e.g., Device.NAT.PortMapping.)',
          pathTypeFilter: const {Tr181PathType.object},
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _addParamsController,
          maxLines: 2,
          hintText: 'Parameters (JSON)',
        ),
        const SizedBox(height: 8),
        AppButton.primary(label: 'Add', onTap: _doAdd),
      ],
    );
  }

  Widget _buildDeleteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Delete'),
        Tr181AutocompleteField(
          controller: _deletePathController,
          labelText: 'Instance Path (e.g., Device.NAT.PortMapping.3.)',
          pathTypeFilter: const {Tr181PathType.object},
        ),
        const SizedBox(height: 8),
        AppButton.danger(label: 'Delete', onTap: _doDelete),
      ],
    );
  }

  Widget _buildOperateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Operate'),
        Tr181AutocompleteField(
          controller: _operateCommandController,
          labelText: 'Command (e.g., Device.Reboot())',
          pathTypeFilter: const {Tr181PathType.command},
        ),
        const SizedBox(height: 8),
        AppTextField(
          controller: _operateArgsController,
          maxLines: 2,
          hintText: 'Arguments (JSON)',
        ),
        const SizedBox(height: 8),
        AppButton.primary(label: 'Execute', onTap: _doOperate),
      ],
    );
  }

  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Bridge Health'),
        AppButton.primary(label: 'Health Check', onTap: _doHealth),
      ],
    );
  }

  Widget _buildSseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('SSE Notifications'),
        Wrap(
          spacing: 8,
          children: [
            AppButton.primary(
              label: 'Connect',
              onTap: _sseConnected ? null : _sseConnect,
            ),
            AppButton.primaryOutline(
              label: 'Disconnect',
              onTap: _sseConnected ? _sseDisconnect : null,
            ),
            AppButton.primaryOutline(
              label: 'Probe',
              onTap: _sseProbe,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSubscriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Subscription'),
        AppTextField(
          controller: _subIdController,
          hintText: 'Subscription ID',
        ),
        const SizedBox(height: 8),
        Tr181AutocompleteField(
          controller: _subPathController,
          labelText: 'Path (e.g., Device.Hosts.Host.)',
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          initialValue: _notifType,
          decoration: const InputDecoration(
            labelText: 'Notification Type',
            border: OutlineInputBorder(),
            isDense: true,
          ),
          items: const [
            DropdownMenuItem(value: 1, child: Text('1 - ValueChange')),
            DropdownMenuItem(value: 2, child: Text('2 - ObjectCreation')),
            DropdownMenuItem(value: 3, child: Text('3 - ObjectDeletion')),
            DropdownMenuItem(value: 4, child: Text('4 - OperationComplete')),
            DropdownMenuItem(value: 5, child: Text('5 - Event')),
          ],
          onChanged: (v) => setState(() => _notifType = v ?? 1),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton.primary(
                label: 'Create USP Subscription',
                onTap: _doCreateUspSubscription),
            AppButton.primaryOutline(
                label: 'Bridge Subscribe', onTap: _doSubscribe),
            AppButton.primaryOutline(
                label: 'Bridge Unsubscribe', onTap: _doUnsubscribe),
          ],
        ),
      ],
    );
  }

  Widget _buildTurboSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Turbo Channel'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            AppButton.primary(label: 'Start', onTap: () => _doTurbo('start')),
            AppButton.primaryOutline(
                label: 'Heartbeat', onTap: () => _doTurbo('heartbeat')),
            AppButton.primaryOutline(
                label: 'Status', onTap: () => _doTurbo('status')),
            AppButton.dangerOutline(
                label: 'Release', onTap: () => _doTurbo('release')),
          ],
        ),
      ],
    );
  }
}
