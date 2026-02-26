# usp-ui-flutter Specification

## Document History

| Version | Date | Changes |
|---------|------|---------|
| v1 | - | Initial draft |

---

## Overview

`usp-ui-flutter` is the main user interface application for router configuration. It provides a cross-platform experience (iOS, Android, Web) using Flutter, with native USP protocol support via the `usp-client` library.

### Purpose

- Provide intuitive router configuration interface
- Support all platforms: iOS, Android, Web browser
- Integrate with usp-client for USP protocol communication
- Support AI-assisted configuration via dynamic calls
- Display real-time updates via subscriptions

### Language

Dart (Flutter framework)

### Dependencies

- Flutter SDK (3.x+)
- usp-client (native via FFI, web via WASM)
- Generated API code from usp-codegen

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            usp-ui-flutter                                    │
│                                                                              │
│  ┌─────────────────────────────────────────────────────────────────────────┐ │
│  │                         Presentation Layer                              │ │
│  │                                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │ │
│  │  │   Screens   │  │  Widgets    │  │   Themes    │  │   i18n      │    │ │
│  │  └──────┬──────┘  └──────┬──────┘  └─────────────┘  └─────────────┘    │ │
│  │         │                │                                              │ │
│  └─────────┼────────────────┼──────────────────────────────────────────────┘ │
│            │                │                                                │
│  ┌─────────▼────────────────▼──────────────────────────────────────────────┐ │
│  │                         State Management                                │ │
│  │                                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │ │
│  │  │  Providers  │  │  Notifiers  │  │   Events    │  │   State     │    │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────────────┘    │ │
│  │         │                │                │                             │ │
│  └─────────┼────────────────┼────────────────┼─────────────────────────────┘ │
│            │                │                │                               │
│  ┌─────────▼────────────────▼────────────────▼─────────────────────────────┐ │
│  │                         Service Layer                                   │ │
│  │                                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐    │ │
│  │  │  USP API    │  │  Auth       │  │  AI Chat    │  │  Storage    │    │ │
│  │  │  (generated)│  │  Service    │  │  Service    │  │  Service    │    │ │
│  │  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘  └─────────────┘    │ │
│  │         │                │                │                             │ │
│  └─────────┼────────────────┼────────────────┼─────────────────────────────┘ │
│            │                │                │                               │
│  ┌─────────▼────────────────▼────────────────▼─────────────────────────────┐ │
│  │                         Platform Layer                                  │ │
│  │                                                                         │ │
│  │  ┌─────────────────────────────────────────────────────────────────┐   │ │
│  │  │                      usp-client                                 │   │ │
│  │  │  ┌─────────────────┐        ┌─────────────────┐                 │   │ │
│  │  │  │ Native (FFI)    │        │ Web (WASM)      │                 │   │ │
│  │  │  │ iOS/Android     │        │ Browser         │                 │   │ │
│  │  │  └─────────────────┘        └─────────────────┘                 │   │ │
│  │  └─────────────────────────────────────────────────────────────────┘   │ │
│  │                                                                         │ │
│  └─────────────────────────────────────────────────────────────────────────┘ │
└──────────────────────────────────────────────────────────────────────────────┘
```

---

## Project Structure

```
usp-ui-flutter/
├── lib/
│   ├── main.dart                    # App entry point
│   ├── app.dart                     # App configuration
│   │
│   ├── core/                        # Core utilities
│   │   ├── constants.dart
│   │   ├── exceptions.dart
│   │   ├── extensions.dart
│   │   └── utils.dart
│   │
│   ├── generated/                   # Generated from usp-codegen
│   │   ├── models/                  # Data models
│   │   │   ├── hardware_info.dart
│   │   │   ├── wifi_settings.dart
│   │   │   ├── connected_devices.dart
│   │   │   └── ...
│   │   └── api/                     # API methods
│   │       ├── hardware_info_api.dart
│   │       ├── wifi_settings_api.dart
│   │       └── ...
│   │
│   ├── services/                    # Business logic
│   │   ├── usp_service.dart         # USP client wrapper
│   │   ├── auth_service.dart        # Authentication
│   │   ├── ai_chat_service.dart     # AI chat integration
│   │   ├── subscription_service.dart # Real-time updates
│   │   └── storage_service.dart     # Local persistence
│   │
│   ├── providers/                   # State management
│   │   ├── auth_provider.dart
│   │   ├── router_state_provider.dart
│   │   ├── wifi_provider.dart
│   │   ├── devices_provider.dart
│   │   └── ai_chat_provider.dart
│   │
│   ├── screens/                     # UI screens
│   │   ├── login/
│   │   ├── dashboard/
│   │   ├── wifi/
│   │   ├── devices/
│   │   ├── settings/
│   │   └── ai_chat/
│   │
│   ├── widgets/                     # Reusable widgets
│   │   ├── common/
│   │   ├── forms/
│   │   ├── cards/
│   │   └── dialogs/
│   │
│   └── theme/                       # Styling
│       ├── app_theme.dart
│       ├── colors.dart
│       └── typography.dart
│
├── assets/                          # Static assets
│   ├── images/
│   ├── icons/
│   └── fonts/
│
├── native/                          # Native bindings
│   ├── usp_client_ffi.dart          # FFI bindings (iOS/Android)
│   └── usp_client_wasm.dart         # WASM bindings (Web)
│
├── test/                            # Tests
│   ├── unit/
│   ├── widget/
│   └── integration/
│
├── ios/                             # iOS platform
├── android/                         # Android platform
├── web/                             # Web platform
│
├── pubspec.yaml                     # Dependencies
└── analysis_options.yaml            # Linting rules
```

---

## Platform Bindings

### Native Platforms (iOS/Android)

```dart
// native/usp_client_ffi.dart
import 'dart:ffi';
import 'dart:io';

final DynamicLibrary _lib = Platform.isAndroid
    ? DynamicLibrary.open('libusp_client.so')
    : DynamicLibrary.open('usp_client.framework/usp_client');

// FFI function signatures
typedef UspClientCreateNative = Pointer<Void> Function(Pointer<Utf8>);
typedef UspClientCreate = Pointer<Void> Function(Pointer<Utf8>);

typedef UspClientSendRequestNative = Int32 Function(
    Pointer<Void>, Pointer<Uint8>, Uint32, Pointer<Pointer<Uint8>>, Pointer<Uint32>);
typedef UspClientSendRequest = int Function(
    Pointer<Void>, Pointer<Uint8>, int, Pointer<Pointer<Uint8>>, Pointer<Uint32>);

class UspClientNative {
  late final Pointer<Void> _client;

  UspClientNative(String baseUrl) {
    final create = _lib.lookupFunction<UspClientCreateNative, UspClientCreate>(
        'usp_client_create');
    _client = create(baseUrl.toNativeUtf8());
  }

  Uint8List sendRequest(Uint8List request) {
    final sendRequest = _lib
        .lookupFunction<UspClientSendRequestNative, UspClientSendRequest>(
            'usp_client_send_request');

    final requestPtr = malloc<Uint8>(request.length);
    requestPtr.asTypedList(request.length).setAll(0, request);

    final responsePtrPtr = malloc<Pointer<Uint8>>();
    final responseLenPtr = malloc<Uint32>();

    final result = sendRequest(
        _client, requestPtr, request.length, responsePtrPtr, responseLenPtr);

    if (result != 0) {
      throw UspClientException('Request failed with code: $result');
    }

    final responseLen = responseLenPtr.value;
    final responseBytes =
        responsePtrPtr.value.asTypedList(responseLen).toList();

    // Free native memory
    _lib.lookupFunction<Void Function(Pointer<Uint8>), void Function(Pointer<Uint8>)>(
        'usp_client_free_response')(responsePtrPtr.value);

    malloc.free(requestPtr);
    malloc.free(responsePtrPtr);
    malloc.free(responseLenPtr);

    return Uint8List.fromList(responseBytes);
  }

  void dispose() {
    final destroy = _lib.lookupFunction<Void Function(Pointer<Void>),
        void Function(Pointer<Void>)>('usp_client_destroy');
    destroy(_client);
  }
}
```

### Web Platform (WASM)

```dart
// native/usp_client_wasm.dart
import 'dart:js_interop';
import 'dart:typed_data';

@JS('UspClient')
extension type UspClientJS._(JSObject _) implements JSObject {
  external factory UspClientJS(String baseUrl);
  external JSPromise<JSUint8Array> sendRequest(JSUint8Array request);
  external void setAuthToken(String token);
  external void dispose();
}

class UspClientWasm {
  late final UspClientJS _client;

  UspClientWasm(String baseUrl) {
    _client = UspClientJS(baseUrl);
  }

  Future<Uint8List> sendRequest(Uint8List request) async {
    final jsRequest = request.toJS;
    final jsResponse = await _client.sendRequest(jsRequest).toDart;
    return jsResponse.toDart;
  }

  void setAuthToken(String token) {
    _client.setAuthToken(token);
  }

  void dispose() {
    _client.dispose();
  }
}
```

### Platform-Agnostic Interface

```dart
// services/usp_service.dart
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

abstract class UspClient {
  Future<Uint8List> sendRequest(Uint8List request);
  void setAuthToken(String token);
  void dispose();

  factory UspClient(String baseUrl) {
    if (kIsWeb) {
      return UspClientWasmImpl(baseUrl);
    } else {
      return UspClientNativeImpl(baseUrl);
    }
  }
}

class UspService {
  late final UspClient _client;

  UspService(String baseUrl) {
    _client = UspClient(baseUrl);
  }

  Future<T> execute<T>(UspRequest request, T Function(Uint8List) decoder) async {
    final encoded = request.encode();
    final response = await _client.sendRequest(encoded);
    return decoder(response);
  }

  void setAuthToken(String token) {
    _client.setAuthToken(token);
  }

  void dispose() {
    _client.dispose();
  }
}
```

---

## Generated Code Integration

### Using Generated Models

```dart
// Example: Using generated HardwareInfo model
import 'package:usp_ui/generated/models/hardware_info.dart';
import 'package:usp_ui/generated/api/hardware_info_api.dart';

class DashboardProvider extends ChangeNotifier {
  final UspService _uspService;
  HardwareInfo? _hardwareInfo;

  HardwareInfo? get hardwareInfo => _hardwareInfo;

  Future<void> loadHardwareInfo() async {
    try {
      _hardwareInfo = await HardwareInfoApi(_uspService).get();
      notifyListeners();
    } catch (e) {
      // Handle error
    }
  }
}
```

### Using Generated WiFi Settings

```dart
// Example: Using generated WiFiSettings model
import 'package:usp_ui/generated/models/wifi_settings.dart';
import 'package:usp_ui/generated/api/wifi_settings_api.dart';

class WifiProvider extends ChangeNotifier {
  final UspService _uspService;
  WifiSettings? _settings;
  bool _loading = false;

  WifiSettings? get settings => _settings;
  bool get loading => _loading;

  Future<void> loadSettings() async {
    _loading = true;
    notifyListeners();

    try {
      _settings = await WifiSettingsApi(_uspService).get();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateSsid(String newSsid) async {
    if (_settings == null) return;

    _loading = true;
    notifyListeners();

    try {
      await WifiSettingsApi(_uspService).set(
        _settings!.copyWith(ssid: newSsid),
      );
      await loadSettings(); // Refresh
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
```

---

## Authentication Flow

### Auth Service

```dart
// services/auth_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
  final String _baseUrl;
  String? _accessToken;
  DateTime? _tokenExpiry;

  AuthService(this._baseUrl);

  bool get isAuthenticated =>
      _accessToken != null &&
      _tokenExpiry != null &&
      DateTime.now().isBefore(_tokenExpiry!);

  Future<bool> login(String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
      return true;
    }
    return false;
  }

  Future<bool> refreshToken() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/auth/refresh'),
      headers: {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      _accessToken = data['access_token'];
      _tokenExpiry = DateTime.now().add(Duration(seconds: data['expires_in']));
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await http.post(
      Uri.parse('$_baseUrl/api/auth/logout'),
      headers: {
        'Content-Type': 'application/json',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      },
    );
    _accessToken = null;
    _tokenExpiry = null;
  }

  String? get accessToken => _accessToken;
}
```

### Auth Provider

```dart
// providers/auth_provider.dart
import 'package:flutter/material.dart';

enum AuthState { initial, authenticated, unauthenticated, loading }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  final UspService _uspService;

  AuthState _state = AuthState.initial;
  String? _error;

  AuthProvider(this._authService, this._uspService);

  AuthState get state => _state;
  String? get error => _error;

  Future<void> login(String password) async {
    _state = AuthState.loading;
    _error = null;
    notifyListeners();

    try {
      final success = await _authService.login(password);
      if (success) {
        _uspService.setAuthToken(_authService.accessToken!);
        _state = AuthState.authenticated;
      } else {
        _state = AuthState.unauthenticated;
        _error = 'Invalid password';
      }
    } catch (e) {
      _state = AuthState.unauthenticated;
      _error = 'Connection failed';
    }
    notifyListeners();
  }

  Future<void> logout() async {
    await _authService.logout();
    _state = AuthState.unauthenticated;
    notifyListeners();
  }

  Future<void> checkAuth() async {
    if (_authService.isAuthenticated) {
      _uspService.setAuthToken(_authService.accessToken!);
      _state = AuthState.authenticated;
    } else if (await _authService.refreshToken()) {
      _uspService.setAuthToken(_authService.accessToken!);
      _state = AuthState.authenticated;
    } else {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }
}
```

---

## AI Chat Integration

### AI Chat Service

```dart
// services/ai_chat_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AiChatService {
  final String _baseUrl;
  final String Function() _getToken;
  final UspService _uspService;

  AiChatService(this._baseUrl, this._getToken, this._uspService);

  /// Phase 1: Generate dynamic call from user message
  Future<AiChatResponse> sendMessage(String message, String sessionId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/ai/chat'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_getToken()}',
      },
      body: jsonEncode({
        'session_id': sessionId,
        'message': message,
      }),
    );

    if (response.statusCode != 200) {
      throw AiChatException('Chat request failed: ${response.statusCode}');
    }

    return AiChatResponse.fromJson(jsonDecode(response.body));
  }

  /// Execute dynamic call via USP
  Future<DynamicCallResult> executeDynamicCall(
      Map<String, dynamic> dynamicCall) async {
    // Convert dynamic call JSON to USP operations
    final operations = dynamicCall['operations'] as List;
    final results = <OperationResult>[];

    for (int i = 0; i < operations.length; i++) {
      final op = operations[i];
      final result = await _executeOperation(op);
      results.add(OperationResult(
        operationIndex: i,
        type: op['type'],
        data: result,
      ));
    }

    return DynamicCallResult(success: true, results: results);
  }

  Future<Map<String, dynamic>> _executeOperation(
      Map<String, dynamic> operation) async {
    final type = operation['type'] as String;

    switch (type) {
      case 'Get':
        final paths = (operation['paths'] as List).cast<String>();
        return await _uspService.get(paths);
      case 'Set':
        final params = operation['params'] as Map<String, dynamic>;
        await _uspService.set(params);
        return {'success': true};
      case 'Add':
        final path = operation['path'] as String;
        final params = operation['params'] as Map<String, dynamic>?;
        final instancePath = await _uspService.add(path, params ?? {});
        return {'instancePath': instancePath};
      case 'Delete':
        final paths = (operation['paths'] as List).cast<String>();
        await _uspService.delete(paths);
        return {'success': true};
      default:
        throw AiChatException('Unsupported operation: $type');
    }
  }

  /// Phase 2: Interpret execution results
  Future<String> interpretResults({
    required String sessionId,
    required String requestId,
    required String originalMessage,
    required Map<String, dynamic> dynamicCall,
    required DynamicCallResult results,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/ai/interpret'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_getToken()}',
      },
      body: jsonEncode({
        'session_id': sessionId,
        'request_id': requestId,
        'original_message': originalMessage,
        'dynamic_call': dynamicCall,
        'results': results.toJson(),
      }),
    );

    if (response.statusCode != 200) {
      throw AiChatException('Interpret request failed: ${response.statusCode}');
    }

    final data = jsonDecode(response.body);
    return data['message'] as String;
  }
}

class AiChatResponse {
  final bool success;
  final String requestId;
  final String? message;
  final Map<String, dynamic>? dynamicCall;
  final AiValidation? validation;

  AiChatResponse({
    required this.success,
    required this.requestId,
    this.message,
    this.dynamicCall,
    this.validation,
  });

  factory AiChatResponse.fromJson(Map<String, dynamic> json) {
    return AiChatResponse(
      success: json['success'] as bool,
      requestId: json['request_id'] as String,
      message: json['message'] as String?,
      dynamicCall: json['dynamic_call'] as Map<String, dynamic>?,
      validation: json['validation'] != null
          ? AiValidation.fromJson(json['validation'])
          : null,
    );
  }

  bool get hasDynamicCall => dynamicCall != null;
  bool get isConversational => dynamicCall == null && message != null;
}
```

### AI Chat Provider

```dart
// providers/ai_chat_provider.dart
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ChatMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final ChatMessageState state;
  final Map<String, dynamic>? dynamicCall;
  final DynamicCallResult? executionResult;

  ChatMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.state = ChatMessageState.complete,
    this.dynamicCall,
    this.executionResult,
  });
}

enum ChatMessageState { pending, executing, interpreting, complete, error }

class AiChatProvider extends ChangeNotifier {
  final AiChatService _chatService;
  final String _sessionId = const Uuid().v4();

  final List<ChatMessage> _messages = [];
  bool _isProcessing = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isProcessing => _isProcessing;

  AiChatProvider(this._chatService);

  Future<void> sendMessage(String content) async {
    // Add user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      content: content,
      isUser: true,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    notifyListeners();

    // Add pending assistant message
    final assistantId = const Uuid().v4();
    var assistantMessage = ChatMessage(
      id: assistantId,
      content: '',
      isUser: false,
      timestamp: DateTime.now(),
      state: ChatMessageState.pending,
    );
    _messages.add(assistantMessage);
    _isProcessing = true;
    notifyListeners();

    try {
      // Phase 1: Get dynamic call from LLM
      final chatResponse = await _chatService.sendMessage(content, _sessionId);

      if (chatResponse.isConversational) {
        // No USP operation needed - just conversational response
        _updateAssistantMessage(assistantId, (m) => ChatMessage(
          id: m.id,
          content: chatResponse.message!,
          isUser: false,
          timestamp: m.timestamp,
          state: ChatMessageState.complete,
        ));
      } else if (chatResponse.hasDynamicCall) {
        // Update state to executing
        _updateAssistantMessage(assistantId, (m) => ChatMessage(
          id: m.id,
          content: 'Executing request...',
          isUser: false,
          timestamp: m.timestamp,
          state: ChatMessageState.executing,
          dynamicCall: chatResponse.dynamicCall,
        ));
        notifyListeners();

        // Execute dynamic call
        final result = await _chatService.executeDynamicCall(
            chatResponse.dynamicCall!);

        // Update state to interpreting
        _updateAssistantMessage(assistantId, (m) => ChatMessage(
          id: m.id,
          content: 'Analyzing results...',
          isUser: false,
          timestamp: m.timestamp,
          state: ChatMessageState.interpreting,
          dynamicCall: m.dynamicCall,
          executionResult: result,
        ));
        notifyListeners();

        // Phase 2: Interpret results
        final interpretation = await _chatService.interpretResults(
          sessionId: _sessionId,
          requestId: chatResponse.requestId,
          originalMessage: content,
          dynamicCall: chatResponse.dynamicCall!,
          results: result,
        );

        // Final update with interpreted message
        _updateAssistantMessage(assistantId, (m) => ChatMessage(
          id: m.id,
          content: interpretation,
          isUser: false,
          timestamp: m.timestamp,
          state: ChatMessageState.complete,
          dynamicCall: m.dynamicCall,
          executionResult: m.executionResult,
        ));
      }
    } catch (e) {
      _updateAssistantMessage(assistantId, (m) => ChatMessage(
        id: m.id,
        content: 'Sorry, something went wrong. Please try again.',
        isUser: false,
        timestamp: m.timestamp,
        state: ChatMessageState.error,
      ));
    } finally {
      _isProcessing = false;
      notifyListeners();
    }
  }

  void _updateAssistantMessage(
      String id, ChatMessage Function(ChatMessage) update) {
    final index = _messages.indexWhere((m) => m.id == id);
    if (index >= 0) {
      _messages[index] = update(_messages[index]);
    }
  }

  void clearHistory() {
    _messages.clear();
    notifyListeners();
  }
}
```

---

## Real-Time Updates (Subscriptions)

### Subscription Service

```dart
// services/subscription_service.dart
import 'dart:async';
import 'dart:convert';

class SubscriptionService {
  final String _baseUrl;
  final String Function() _getToken;

  EventSource? _eventSource;
  final _controllers = <String, StreamController<dynamic>>{};

  SubscriptionService(this._baseUrl, this._getToken);

  Stream<T> subscribe<T>(String subscriptionId, T Function(Map<String, dynamic>) decoder) {
    if (!_controllers.containsKey(subscriptionId)) {
      _controllers[subscriptionId] = StreamController<dynamic>.broadcast();
      _registerSubscription(subscriptionId);
    }

    return _controllers[subscriptionId]!.stream.map((data) => decoder(data));
  }

  void _registerSubscription(String subscriptionId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/subscribe'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_getToken()}',
      },
      body: jsonEncode({'subscription_id': subscriptionId}),
    );

    if (response.statusCode != 200) {
      _controllers[subscriptionId]?.addError('Failed to subscribe');
    }
  }

  void startEventStream() {
    _eventSource = EventSource('$_baseUrl/api/events',
      headers: {'Authorization': 'Bearer ${_getToken()}'});

    _eventSource!.onMessage.listen((event) {
      final data = jsonDecode(event.data);
      final subscriptionId = data['subscription_id'] as String;

      if (_controllers.containsKey(subscriptionId)) {
        _controllers[subscriptionId]!.add(data['value']);
      }
    });
  }

  Future<void> unsubscribe(String subscriptionId) async {
    await http.post(
      Uri.parse('$_baseUrl/api/unsubscribe'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${_getToken()}',
      },
      body: jsonEncode({'subscription_id': subscriptionId}),
    );

    await _controllers[subscriptionId]?.close();
    _controllers.remove(subscriptionId);
  }

  void dispose() {
    _eventSource?.close();
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
```

### Using Subscriptions in Providers

```dart
// providers/devices_provider.dart
class DevicesProvider extends ChangeNotifier {
  final UspService _uspService;
  final SubscriptionService _subscriptionService;

  List<ConnectedDevice> _devices = [];
  StreamSubscription? _subscription;

  DevicesProvider(this._uspService, this._subscriptionService);

  List<ConnectedDevice> get devices => List.unmodifiable(_devices);

  Future<void> initialize() async {
    // Initial load
    await refresh();

    // Subscribe to changes
    _subscription = _subscriptionService
        .subscribe<HostChangeEvent>('host-changes-01', HostChangeEvent.fromJson)
        .listen(_onHostChange);
  }

  Future<void> refresh() async {
    _devices = await ConnectedDevicesApi(_uspService).getAll();
    notifyListeners();
  }

  void _onHostChange(HostChangeEvent event) {
    switch (event.type) {
      case 'ObjectCreation':
        _devices.add(event.device);
        break;
      case 'ObjectDeletion':
        _devices.removeWhere((d) => d.instancePath == event.instancePath);
        break;
      case 'ValueChange':
        final index = _devices.indexWhere((d) => d.instancePath == event.instancePath);
        if (index >= 0) {
          _devices[index] = event.device;
        }
        break;
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
```

---

## UI Screens

### Login Screen

```dart
// screens/login/login_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Image.asset('assets/images/router_logo.png', height: 80),
              const SizedBox(height: 48),

              // Title
              Text(
                'Router Login',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 32),

              // Password field
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility : Icons.visibility_off,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
                onSubmitted: (_) => _login(),
              ),
              const SizedBox(height: 16),

              // Error message
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  if (auth.error != null) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        auth.error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),

              // Login button
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: auth.state == AuthState.loading ? null : _login,
                      child: auth.state == AuthState.loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Login'),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _login() {
    final password = _passwordController.text.trim();
    if (password.isNotEmpty) {
      context.read<AuthProvider>().login(password);
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
```

### AI Chat Screen

```dart
// screens/ai_chat/ai_chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Assistant'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              context.read<AiChatProvider>().clearHistory();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: Consumer<AiChatProvider>(
              builder: (context, chat, _) {
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chat.messages.length,
                  itemBuilder: (context, index) {
                    final message = chat.messages[index];
                    return ChatBubble(message: message);
                  },
                );
              },
            ),
          ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Ask about your router...',
                      border: OutlineInputBorder(),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                Consumer<AiChatProvider>(
                  builder: (context, chat, _) {
                    return IconButton.filled(
                      onPressed: chat.isProcessing ? null : _sendMessage,
                      icon: chat.isProcessing
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.send),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isNotEmpty) {
      context.read<AiChatProvider>().sendMessage(text);
      _messageController.clear();

      // Scroll to bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isUser
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.state == ChatMessageState.executing)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Executing...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else if (message.state == ChatMessageState.interpreting)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    height: 14,
                    width: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Analyzing...',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              )
            else
              Text(
                message.content,
                style: TextStyle(
                  color: isUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
```

---

## Configuration

### pubspec.yaml

```yaml
name: usp_ui
description: USP-driven router configuration UI
publish_to: 'none'
version: 1.0.0

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter

  # State management
  provider: ^6.0.0

  # HTTP client
  http: ^1.0.0

  # Native bindings
  ffi: ^2.0.0

  # Utilities
  uuid: ^4.0.0
  intl: ^0.18.0

  # Storage
  shared_preferences: ^2.0.0

  # UI components
  cupertino_icons: ^1.0.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  mockito: ^5.4.0
  build_runner: ^2.4.0

flutter:
  uses-material-design: true

  assets:
    - assets/images/
    - assets/icons/

# Platform-specific builds
# iOS: Uses .framework for usp_client
# Android: Uses .so for usp_client
# Web: Uses .wasm for usp_client
```

### App Initialization

```dart
// main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const UspUiApp());
}

class UspUiApp extends StatelessWidget {
  const UspUiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Services
        Provider<AuthService>(
          create: (_) => AuthService(AppConfig.baseUrl),
        ),
        Provider<UspService>(
          create: (_) => UspService(AppConfig.baseUrl),
        ),
        ProxyProvider<AuthService, AiChatService>(
          update: (_, auth, __) => AiChatService(
            AppConfig.baseUrl,
            () => auth.accessToken ?? '',
            context.read<UspService>(),
          ),
        ),

        // Providers
        ChangeNotifierProxyProvider2<AuthService, UspService, AuthProvider>(
          create: (context) => AuthProvider(
            context.read<AuthService>(),
            context.read<UspService>(),
          ),
          update: (_, auth, usp, previous) => previous!,
        ),
        ChangeNotifierProxyProvider<AiChatService, AiChatProvider>(
          create: (context) => AiChatProvider(context.read<AiChatService>()),
          update: (_, service, previous) => previous!,
        ),
      ],
      child: MaterialApp(
        title: 'Router Settings',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const AuthGate(),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        switch (auth.state) {
          case AuthState.initial:
            auth.checkAuth();
            return const SplashScreen();
          case AuthState.loading:
            return const SplashScreen();
          case AuthState.authenticated:
            return const DashboardScreen();
          case AuthState.unauthenticated:
            return const LoginScreen();
        }
      },
    );
  }
}
```

---

## Build & Deployment

### Build Commands

```bash
# Development
flutter run -d chrome              # Web
flutter run -d ios                 # iOS Simulator
flutter run -d android             # Android Emulator

# Production builds
flutter build web --release        # Web
flutter build ios --release        # iOS
flutter build apk --release        # Android APK
flutter build appbundle --release  # Android App Bundle
```

### Web Deployment

```bash
# Build for web
flutter build web --release

# Copy to router
scp -r build/web/* router:/www/usp-ui/
```

### Platform Requirements

| Platform | Requirements |
|----------|--------------|
| Web | Modern browser with WASM support |
| iOS | iOS 12.0+ |
| Android | Android 5.0+ (API 21+) |

---

## Testing

### Unit Tests

```dart
// test/unit/ai_chat_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

void main() {
  group('AiChatService', () {
    late MockHttpClient mockHttp;
    late MockUspService mockUsp;
    late AiChatService service;

    setUp(() {
      mockHttp = MockHttpClient();
      mockUsp = MockUspService();
      service = AiChatService('https://router.local', () => 'token', mockUsp);
    });

    test('sendMessage returns conversational response', () async {
      when(mockHttp.post(any, body: anyNamed('body'), headers: anyNamed('headers')))
          .thenAnswer((_) async => http.Response(
            '{"success": true, "request_id": "123", "message": "Hello!", "dynamic_call": null}',
            200,
          ));

      final response = await service.sendMessage('Hi', 'session-1');

      expect(response.success, true);
      expect(response.isConversational, true);
      expect(response.message, 'Hello!');
    });

    test('executeDynamicCall processes Get operation', () async {
      when(mockUsp.get(any)).thenAnswer((_) async => {
        'Device.WiFi.Radio.1.Channel': '6',
      });

      final result = await service.executeDynamicCall({
        'version': '1.0',
        'operations': [
          {'type': 'Get', 'paths': ['Device.WiFi.Radio.1.Channel']}
        ],
      });

      expect(result.success, true);
      expect(result.results.length, 1);
    });
  });
}
```

### Widget Tests

```dart
// test/widget/login_screen_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

void main() {
  group('LoginScreen', () {
    testWidgets('shows password field and login button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>(
            create: (_) => MockAuthProvider(),
            child: const LoginScreen(),
          ),
        ),
      );

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
    });

    testWidgets('calls login on button press', (tester) async {
      final mockAuth = MockAuthProvider();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AuthProvider>.value(
            value: mockAuth,
            child: const LoginScreen(),
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'password123');
      await tester.tap(find.text('Login'));
      await tester.pump();

      verify(mockAuth.login('password123')).called(1);
    });
  });
}
```

### Integration Tests

```dart
// test/integration/auth_flow_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Authentication Flow', () {
    testWidgets('login and view dashboard', (tester) async {
      await tester.pumpWidget(const UspUiApp());
      await tester.pumpAndSettle();

      // Should show login screen
      expect(find.text('Router Login'), findsOneWidget);

      // Enter password
      await tester.enterText(find.byType(TextField), 'admin');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      // Should show dashboard
      expect(find.text('Dashboard'), findsOneWidget);
    });
  });
}
```
