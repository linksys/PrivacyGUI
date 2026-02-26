import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:privacy_gui/usp/services/usp_service.dart';
import 'package:privacy_gui/usp/web/usp_wasm_init.dart';

class UspTestPage extends StatefulWidget {
  const UspTestPage({super.key});

  @override
  State<UspTestPage> createState() => _UspTestPageState();
}

class _UspTestPageState extends State<UspTestPage> {
  final _urlController = TextEditingController(text: 'http://localhost:8081');
  final _passwordController = TextEditingController(text: 'admin');
  final _getPathController = TextEditingController(
      text: 'Device.DeviceInfo.Manufacturer');
  final _setPathController = TextEditingController();
  final _setValueController = TextEditingController();
  final _addPathController = TextEditingController();
  final _addParamsController = TextEditingController(text: '{}');
  final _deletePathController = TextEditingController();
  final _operateCommandController = TextEditingController();
  final _operateArgsController = TextEditingController(text: '{}');
  final _logScrollController = ScrollController();

  UspService? _service;
  bool _isConnected = false;
  final List<String> _logs = [];

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
    } catch (e) {
      _log('ERROR login: $e');
    }
  }

  Future<void> _logout() async {
    if (_service == null) return;
    _log('Logout...');
    try {
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
      final params = Map<String, String>.from(
          jsonDecode(paramsJson) as Map? ?? {});
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
      final args = Map<String, String>.from(
          jsonDecode(argsJson) as Map? ?? {});
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

  @override
  void dispose() {
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
    _logScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('USP Client Test'),
        actions: [
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
                        return Text(
                          log,
                          style: TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: isError ? Colors.red : null,
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
                onPressed: _refreshToken,
                child: const Text('Refresh Token')),
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
}
