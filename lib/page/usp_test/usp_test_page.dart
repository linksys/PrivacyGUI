import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:privacy_gui/core/usp/services/usp_bridge_client.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/core/usp/web/usp_wasm_init.dart';

class UspTestPage extends StatefulWidget {
  const UspTestPage({super.key});

  @override
  State<UspTestPage> createState() => _UspTestPageState();
}

class _UspTestPageState extends State<UspTestPage> {
  final _urlController = TextEditingController(text: 'http://localhost:8081');
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
  final List<String> _logs = [];

  // SSE state
  StreamSubscription<SseEvent>? _sseSub;
  bool _sseConnected = false;

  // Subscription notif type
  int _notifType = 1; // 1=ValueChange, 2=ObjectCreation, 3=ObjectDeletion

  void _log(String message) {
    final timestamp =
        DateTime.now().toIso8601String().substring(11, 23); // HH:mm:ss.SSS
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
      _service = UspService(url);
      _bridgeClient = UspBridgeClient(_service!);
      _log('Client created for $url');
      setState(() => _isConnected = false);
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
      setState(() => _isConnected = _service!.isAuthenticated);
      _log('Login result: isAuthenticated=${_service!.isAuthenticated}');
      final token = _service!.sessionToken;
      if (token != null) {
        _log('Token available (${token.length} chars)');
      } else {
        _log(
            'WARNING: sessionToken is null — WASM client may not export getToken() yet');
      }
    } catch (e) {
      _log('ERROR login: $e');
    }
  }

  Future<void> _logout() async {
    if (_service == null) return;
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

  // ════════════════════════════════════════════════════════════════════════
  // USP CRUD operations
  // ════════════════════════════════════════════════════════════════════════

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
      final response = await _service!.operate(command, args: args);
      _log('  commandKey = ${response['commandKey']}');
      if (response.isEmpty) {
        _log('OPERATE OK (no output)');
      } else {
        for (final entry in response.entries) {
          _log('  ${entry.key} = ${entry.value}');
        }
      }
    } catch (e) {
      _log('ERROR operate: $e');
    }
  }

  // ════════════════════════════════════════════════════════════════════════
  // Bridge: Health
  // ════════════════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════════════════
  // Bridge: SSE Notifications
  // ════════════════════════════════════════════════════════════════════════

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
      _log('SSE listener attached (waiting for fetch response...)');
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

  // ════════════════════════════════════════════════════════════════════════
  // Bridge: Subscription
  // ════════════════════════════════════════════════════════════════════════

  Future<void> _doSubscribe() async {
    if (_bridgeClient == null) return;
    final subId = _subIdController.text.trim();
    final path = _subPathController.text.trim();
    if (subId.isEmpty || path.isEmpty) return;
    final typeNames = {
      1: 'ValueChange',
      2: 'ObjectCreation',
      3: 'ObjectDeletion'
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

  // ════════════════════════════════════════════════════════════════════════
  // Bridge: Turbo Channel
  // ════════════════════════════════════════════════════════════════════════

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

  // ════════════════════════════════════════════════════════════════════════

  @override
  void dispose() {
    _sseSub?.cancel();
    _service?.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USP Client Test'),
        actions: [
          if (_sseConnected)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'SSE Connected',
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: _isConnected ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _isConnected ? 'Authenticated' : 'Not Authenticated',
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Row(
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
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text('Log',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const Spacer(),
                      TextButton(
                        onPressed: () => setState(() => _logs.clear()),
                        child: const Text('Clear'),
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
                        return Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isError
                                ? Colors.red
                                : isSse
                                    ? Colors.blue
                                    : null,
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
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildConnectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Connection'),
        TextField(
          controller: _urlController,
          decoration: const InputDecoration(
            labelText: 'Base URL',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(
            labelText: 'Password',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(onPressed: _login, child: const Text('Login')),
            OutlinedButton(onPressed: _logout, child: const Text('Logout')),
            OutlinedButton(
                onPressed: _refreshToken, child: const Text('Refresh Token')),
          ],
        ),
      ],
    );
  }

  Widget _buildGetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Get'),
        TextField(
          controller: _getPathController,
          decoration: const InputDecoration(
            labelText: 'Path(s) — comma separated for multiple',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _doGet, child: const Text('Get')),
      ],
    );
  }

  Widget _buildSetSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Set'),
        TextField(
          controller: _setPathController,
          decoration: const InputDecoration(
            labelText: 'Path',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _setValueController,
          decoration: const InputDecoration(
            labelText: 'Value',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _doSet, child: const Text('Set')),
      ],
    );
  }

  Widget _buildAddSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Add'),
        TextField(
          controller: _addPathController,
          decoration: const InputDecoration(
            labelText: 'Object Path (e.g., Device.NAT.PortMapping.)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _addParamsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Parameters (JSON)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _doAdd, child: const Text('Add')),
      ],
    );
  }

  Widget _buildDeleteSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Delete'),
        TextField(
          controller: _deletePathController,
          decoration: const InputDecoration(
            labelText: 'Instance Path (e.g., Device.NAT.PortMapping.3.)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _doDelete, child: const Text('Delete')),
      ],
    );
  }

  Widget _buildOperateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('USP Operate'),
        TextField(
          controller: _operateCommandController,
          decoration: const InputDecoration(
            labelText: 'Command (e.g., Device.Reboot())',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _operateArgsController,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Arguments (JSON)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton(onPressed: _doOperate, child: const Text('Execute')),
      ],
    );
  }

  // ════════════════════════════════════════════════════════════════════════
  // Bridge sections
  // ════════════════════════════════════════════════════════════════════════

  Widget _buildHealthSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('Bridge Health'),
        ElevatedButton(onPressed: _doHealth, child: const Text('Health Check')),
      ],
    );
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

  Widget _buildSseSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSectionTitle('SSE Notifications'),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
              onPressed: _sseConnected ? null : _sseConnect,
              child: const Text('Connect'),
            ),
            OutlinedButton(
              onPressed: _sseConnected ? _sseDisconnect : null,
              child: const Text('Disconnect'),
            ),
            OutlinedButton(
              onPressed: _sseProbe,
              child: const Text('Probe'),
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
        TextField(
          controller: _subIdController,
          decoration: const InputDecoration(
            labelText: 'Subscription ID',
            border: OutlineInputBorder(),
            isDense: true,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _subPathController,
          decoration: const InputDecoration(
            labelText: 'Path (e.g., Device.Hosts.Host.)',
            border: OutlineInputBorder(),
            isDense: true,
          ),
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
          ],
          onChanged: (v) => setState(() => _notifType = v ?? 1),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ElevatedButton(
                onPressed: _doSubscribe, child: const Text('Subscribe')),
            OutlinedButton(
                onPressed: _doUnsubscribe, child: const Text('Unsubscribe')),
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
            ElevatedButton(
                onPressed: () => _doTurbo('start'), child: const Text('Start')),
            OutlinedButton(
                onPressed: () => _doTurbo('heartbeat'),
                child: const Text('Heartbeat')),
            OutlinedButton(
                onPressed: () => _doTurbo('status'),
                child: const Text('Status')),
            OutlinedButton(
                onPressed: () => _doTurbo('release'),
                style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Release')),
          ],
        ),
      ],
    );
  }
}
