/// Minimal USP service stub for codegen examples.
/// This file provides the types that generated Dart code depends on,
/// without requiring the full Flutter usp-test project.

import 'dart:async';

// ===========================================================================
// USP Notification types
// ===========================================================================

enum NotifType {
  valueChange,
  objectCreation,
  objectDeletion,
  operationComplete,
  onBoardRequest,
  event,
}

// ===========================================================================
// Subscription
// ===========================================================================

class Subscription<T> {
  final String id;
  final NotifType notifType;
  final Stream<T> stream;
  final Future<void> Function() _cancel;

  Subscription({
    required this.id,
    required this.notifType,
    required this.stream,
    required Future<void> Function() cancel,
  }) : _cancel = cancel;

  Future<void> cancel() => _cancel();
}

// ===========================================================================
// UspService
// ===========================================================================

class UspService {
  UspService(String baseUrl);

  Future<Map<String, dynamic>> get(List<String> paths) async => {};

  Future<void> set(Map<String, dynamic> parameters,
      {bool allowPartial = false}) async {}

  Future<String> add(String objectPath, Map<String, dynamic> parameters) async =>
      '';

  Future<void> delete(String path) async {}

  Future<Map<String, String>> operate(String command,
      {Map<String, String> args = const {}}) async => {};

  Future<Subscription<T>> subscribe<T>({
    required String id,
    required NotifType notifType,
    required List<String> paths,
    required T Function(Map<String, dynamic>) parser,
  }) async {
    final controller = StreamController<T>();
    return Subscription<T>(
      id: id,
      notifType: notifType,
      stream: controller.stream,
      cancel: () async => controller.close(),
    );
  }
}
