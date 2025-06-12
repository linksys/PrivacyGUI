import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:privacy_gui/constants/pref_key.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacy_gui/core/jnap/providers/ip_getter/get_local_ip.dart'
    if (dart.library.io) 'package:privacy_gui/core/jnap/providers/ip_getter/mobile_get_local_ip.dart'
    if (dart.library.html) 'package:privacy_gui/core/jnap/providers/ip_getter/web_get_local_ip.dart';

class ModularAppListView extends ArgumentsConsumerStatefulView {
  const ModularAppListView({super.key});

  @override
  ConsumerState<ModularAppListView> createState() => _ModularAppListViewState();
}

class _ModularAppListViewState extends ConsumerState<ModularAppListView> {
  @override
  void initState() {
    super.initState();
    doSomethingWithSpinner(
        context, ref.read(sseConnectionProvider.notifier).connect());
  }

  @override
  void dispose() {
    ref.read(sseConnectionProvider.notifier).disconnect();
    super.dispose();
  }

  Widget _buildAppCategory(String title, List<ModularAppData> apps) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall(title),
        SizedBox(height: 8),
        if (apps.isEmpty)
          AppText.labelMedium('No apps available')
        else
          SizedBox(
            height: 200,
            child: CarouselView(
              itemExtent: 200,
              children: apps.map((app) => _buildAppCard(app)).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildAppCard(ModularAppData app) {
    return AppCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.account_tree),
              SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppText.labelLarge(app.name),
                    AppText.labelSmall(app.description),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          AppText.labelSmall('Version: ${app.version}'),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modularAppListState = ref.watch(modularAppListProvider);
    final sseState = ref.watch(sseConnectionProvider);
    return StyledAppPageView(
      scrollable: true,
      title: 'Modular App List',
      child: (context, constraints) => AppBasicLayout(
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildAppCategory('Default Apps', modularAppListState.defaultApps),
            _buildAppCategory('User Apps', modularAppListState.userApps),
            _buildAppCategory('Premium Apps', modularAppListState.premiumApps),
          ],
        ),
        footer: Row(
          children: [
            AppText.labelLarge('Version: ${modularAppListState.version}'),
            AppGap.medium(),
            AppText.labelLarge(
                'Last Updated: ${DateTime.fromMillisecondsSinceEpoch((modularAppListState.lastUpdated ?? 0) * 1000).toIso8601String()}'),
            AppGap.medium(),
            AppText.labelLarge('Connected: ${sseState.isConnected}'),
          ],
        ),
      ),
    );
  }
}

// create a notifier provider for SSE connection
final sseConnectionProvider =
    NotifierProvider<SSEConnectionNotifier, SSEConnectionState>(
        () => SSEConnectionNotifier());

class SSEConnectionNotifier extends Notifier<SSEConnectionState> {
  http.Client? _httpClient;
  StreamSubscription<List<int>>? _subscription;

  // Manual buffering for partial lines
  List<int> _buffer = [];
  // Reconnection logic (simplified)
  Timer? _reconnectTimer;
  int _reconnectDelayMs = 1000; // Start with 1 second

  @override
  SSEConnectionState build() {
    return SSEConnectionState();
  }

  Future<void> disconnect() async {
    state = state.copyWith(isConnected: false);
    _httpClient?.close();
    _subscription?.cancel();
    _reconnectTimer?.cancel();
  }

  Future<void> connect() async {
    _httpClient = http.Client();
    final sseUrl = 'https://${getLocalIp(ref)}/cgi-bin/sse_push.cgi';
    final localPwd = ref.read(authProvider).value?.localPassword ??
        await const FlutterSecureStorage().read(key: pLocalPassword) ??
        '';
    try {
      final request = http.Request('GET', Uri.parse(sseUrl));
      request.headers['Accept'] = 'text/event-stream';
      request.headers['Cache-Control'] = 'no-cache';
      request.headers['Connection'] = 'keep-alive';
      request.headers['Authorization'] =
          'Basic ${Utils.stringBase64Encode('admin:$localPwd')}';
      if (state.lastEventId?.isNotEmpty ?? false) {
        request.headers['Last-Event-ID'] = state.lastEventId!;
      }

      final response = await _httpClient!.send(request);

      if (response.statusCode == 200) {
        logger.d('HTTP Stream connected.');
        // state = state.copyWith(isConnected: true);
        _reconnectDelayMs = 1000; // Reset delay on successful connection

        _subscription = response.stream.listen(
          (List<int> chunk) {
            // Ensure buffer is always a growable list
            _buffer = List<int>.from(_buffer);
            _buffer.addAll(chunk);
            _processBuffer(); // Process the buffer to find events
          },
          onError: (dynamic error) {
            logger.e('Stream Error: $error');
            _scheduleReconnect();
          },
          onDone: () {
            logger.d('Stream disconnected.');
            _scheduleReconnect();
          },
        );
      } else {
        logger.e('Failed to connect HTTP Stream: ${response.statusCode}');
        _scheduleReconnect();
      }
    } catch (e) {
      logger.e('HTTP Stream Connection Failed: $e');
      _scheduleReconnect();
    }
  }

  void _processBuffer() {
    String currentData = utf8.decode(_buffer);
    int eventEndIndex;

    while ((eventEndIndex = currentData.indexOf('\n\n')) != -1 ||
        (eventEndIndex = currentData.indexOf('\r\n\r\n')) != -1) {
      String eventBlock = currentData.substring(0, eventEndIndex);

      String id = '';
      String data = '';
      String eventType = '';
      int retry = 0;
      int timestamp = 0;
      String message = '';

      List<String> lines = eventBlock.split(RegExp(r'\r?\n'));
      for (String line in lines) {
        if (line.startsWith('id:')) {
          id = line.substring(3).trim();
        } else if (line.startsWith('data:')) {
          data += line.substring(5).trim();
        } else if (line.startsWith('event:')) {
          eventType = line.substring(6).trim();
        } else if (line.startsWith('retry:')) {
          retry = int.tryParse(line.substring(6).trim()) ?? 0;
        } else if (line.startsWith('timestamp:')) {
          timestamp = int.tryParse(line.substring(10).trim()) ?? 0;
        } else if (line.startsWith('message:')) {
          message = line.substring(8).trim();
        }
        // Handle other fields like "field: value" if necessary
      }
      final packet = SSEPacket(
        id: id,
        data: data,
        eventType: eventType,
        retry: retry,
        timestamp: timestamp,
        message: message,
      );
      logger.d('Receive Packet: $packet');
      // set connected when receive initial event
      if (eventType == 'initial') {
        state = state.copyWith(isConnected: true);
      }
      // Process the parsed event
      if (eventType.isNotEmpty && message.isNotEmpty) {
        // keep last 20 messages
        state = state.copyWith(
          packets: state.packets.length > 20
              ? [...state.packets.sublist(state.packets.length - 20), packet]
              : [...state.packets, packet],
          lastEventId: id, // Update last received ID in state
        );
      }

      // Consume the processed part of the buffer
      _buffer = utf8.encode(currentData.substring(
          eventEndIndex + (currentData.contains('\r\n\r\n') ? 4 : 2)));
      currentData = utf8.decode(_buffer);
    }
  }

  void _scheduleReconnect() {
    _subscription?.cancel(); // Cancel any ongoing subscription
    _reconnectTimer?.cancel(); // Cancel previous timer if any

    _reconnectTimer = Timer(Duration(milliseconds: _reconnectDelayMs), () {
      logger.d(
          'Attempting to reconnect in ${_reconnectDelayMs / 1000} seconds...');
      _reconnectDelayMs = (_reconnectDelayMs * 2)
          .clamp(1000, 30000)
          .toInt(); // Exponential backoff, max 30s
      connect();
    });
  }
}

enum ModularAppType {
  app,
  user,
  premium,
  ;

  String toValue() {
    switch (this) {
      case ModularAppType.app:
        return 'app';
      case ModularAppType.user:
        return 'user';
      case ModularAppType.premium:
        return 'premium';
    }
  }
}

///        {
///            "description": "The 1st App",
///            "name": "Test App 1",
///            "version": "0.0.2",
///            "color": "cyanAccent",
///            "link": "10.0.0.103/test-app/",
///            "icon": "account-tree"
///        }
class ModularAppData extends Equatable {
  final String description;
  final String name;
  final String version;
  final String color;
  final String link;
  final String icon;
  final ModularAppType type;

  const ModularAppData({
    required this.description,
    required this.name,
    required this.version,
    required this.color,
    required this.link,
    required this.icon,
    required this.type,
  });

  ModularAppData copyWith({
    String? description,
    String? name,
    String? version,
    String? color,
    String? link,
    String? icon,
    ModularAppType? type,
  }) {
    return ModularAppData(
      description: description ?? this.description,
      name: name ?? this.name,
      version: version ?? this.version,
      color: color ?? this.color,
      link: link ?? this.link,
      icon: icon ?? this.icon,
      type: type ?? this.type,
    );
  }

  factory ModularAppData.fromMap(Map<String, dynamic> map) {
    return ModularAppData(
      description: map['description'],
      name: map['name'],
      version: map['version'],
      color: map['color'],
      link: map['link'],
      icon: map['icon'],
      type: ModularAppType.values
              .firstWhereOrNull((e) => e.toValue() == map['type']) ??
          ModularAppType.app,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'name': name,
      'version': version,
      'color': color,
      'link': link,
      'icon': icon,
      'type': type.toValue(),
    };
  }

  factory ModularAppData.fromJson(String source) =>
      ModularAppData.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ModularAppData(description: $description, name: $name, version: $version, color: $color, link: $link, icon: $icon)';

  @override
  List<Object?> get props => [
        description,
        name,
        version,
        color,
        link,
        icon,
        type,
      ];
}

class SSEPacket extends Equatable {
  final String id;
  final String data;
  final String eventType;
  final int retry;
  final int timestamp;
  final String message;
  const SSEPacket({
    required this.id,
    required this.data,
    required this.eventType,
    required this.retry,
    required this.timestamp,
    required this.message,
  });

  SSEPacket copyWith({
    String? id,
    String? data,
    String? eventType,
    int? retry,
    int? timestamp,
    String? message,
  }) {
    return SSEPacket(
      id: id ?? this.id,
      data: data ?? this.data,
      eventType: eventType ?? this.eventType,
      retry: retry ?? this.retry,
      timestamp: timestamp ?? this.timestamp,
      message: message ?? this.message,
    );
  }

  factory SSEPacket.fromMap(Map<String, dynamic> map) {
    return SSEPacket(
      id: map['id'],
      data: map['data'],
      eventType: map['eventType'],
      retry: map['retry'],
      timestamp: map['timestamp'],
      message: map['message'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'data': data,
      'eventType': eventType,
      'retry': retry,
      'timestamp': timestamp,
      'message': message,
    };
  }

  factory SSEPacket.fromJson(String source) =>
      SSEPacket.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());
  @override
  String toString() =>
      'SSEPacket(id: $id, data: $data, eventType: $eventType, retry: $retry, timestamp: $timestamp, message: $message)';

  @override
  List<Object?> get props => [
        id,
        data,
        eventType,
        retry,
        timestamp,
        message,
      ];
}

// create a state class for SSE connection
class SSEConnectionState extends Equatable {
  final bool isConnected;
  final List<SSEPacket> packets;
  final String? lastEventId;
  const SSEConnectionState({
    this.isConnected = false,
    this.packets = const [],
    this.lastEventId,
  });

  SSEConnectionState copyWith(
      {bool? isConnected, List<SSEPacket>? packets, String? lastEventId}) {
    return SSEConnectionState(
        isConnected: isConnected ?? this.isConnected,
        packets: packets ?? this.packets,
        lastEventId: lastEventId ?? this.lastEventId);
  }

  factory SSEConnectionState.fromMap(Map<String, dynamic> map) {
    return SSEConnectionState(
      isConnected: map['isConnected'],
      packets: map['packets'].map((x) => SSEPacket.fromMap(x)).toList(),
      lastEventId: map['lastEventId'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isConnected': isConnected,
      'packets': packets,
      'lastEventId': lastEventId,
    };
  }

  factory SSEConnectionState.fromJson(String source) =>
      SSEConnectionState.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  @override
  List<Object?> get props => [isConnected, packets, lastEventId];
}

// create a state class for modular app list
class ModularAppListState extends Equatable {
  final List<ModularAppData> apps;
  final String version;
  final int? lastUpdated;
  const ModularAppListState(
      {this.apps = const [], this.version = '', this.lastUpdated});

  List<ModularAppData> get defaultApps =>
      apps.where((app) => app.type == ModularAppType.app).toList();

  List<ModularAppData> get userApps =>
      apps.where((app) => app.type == ModularAppType.user).toList();

  List<ModularAppData> get premiumApps =>
      apps.where((app) => app.type == ModularAppType.premium).toList();

  ModularAppListState copyWith({
    List<ModularAppData>? apps,
    String? version,
    int? lastUpdated,
  }) {
    return ModularAppListState(
      apps: apps ?? this.apps,
      version: version ?? this.version,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  factory ModularAppListState.fromMap(Map<String, dynamic> map) {
    return ModularAppListState(
      apps: map['apps'].map((x) => ModularAppData.fromMap(x)).toList(),
      version: map['version'],
      lastUpdated: map['lastUpdated'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'apps': apps,
      'version': version,
      'lastUpdated': lastUpdated,
    };
  }

  factory ModularAppListState.fromJson(String source) =>
      ModularAppListState.fromMap(json.decode(source));

  String toJson() => json.encode(toMap());

  @override
  List<Object?> get props => [apps, version, lastUpdated];
}

final modularAppListProvider =
    NotifierProvider<ModularAppListNotifier, ModularAppListState>(
  () => ModularAppListNotifier(),
);

class ModularAppListNotifier extends Notifier<ModularAppListState> {
  @override
  ModularAppListState build() {
    final sseState = ref.watch(sseConnectionProvider);
    // if not connected, return empty state
    if (!sseState.isConnected) {
      return ModularAppListState();
    }
    // parse the initial or last file_changed event packet
    final packets = sseState.packets;
    final lastPacket = packets.lastWhereOrNull(
        (p) => p.eventType == 'initial' || p.eventType == 'file_changed');
    // if no initial or file_changed event, return empty state
    if (lastPacket == null) {
      return ModularAppListState();
    }
    // parse the json from data
    // need to remove --- BEGIN FILE CONTENT --- and --- END FILE CONTENT ---
    final data = json.decode(lastPacket.data
        .replaceAll('--- BEGIN FILE CONTENT ---', '')
        .replaceAll('--- END FILE CONTENT ---', ''));

    final version = data['api']['version'];
    final lastUpdated = lastPacket.timestamp;
    final defaultApps = List.from(data['apps'])
        .map(
            (e) => ModularAppData.fromMap(e).copyWith(type: ModularAppType.app))
        .toList();
    final userApps = List.from(data['userApps'])
        .map((e) =>
            ModularAppData.fromMap(e).copyWith(type: ModularAppType.user))
        .toList();
    final premiumApps = List.from(data['premiumApps'])
        .map((e) =>
            ModularAppData.fromMap(e).copyWith(type: ModularAppType.premium))
        .toList();

    return ModularAppListState(
        version: version,
        lastUpdated: lastUpdated,
        apps: [...defaultApps, ...userApps, ...premiumApps]);
  }
}
