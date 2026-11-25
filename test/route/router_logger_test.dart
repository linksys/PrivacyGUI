// RouterLogger: the app router's observer writes each navigation to the log
// (router_provider.dart), so an exported log shows how the user moved.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/route/router_logger.dart';
import 'package:privacy_gui/route/router_provider.dart';

/// The lines [body] logs, as the console shows them in a debug build.
List<String> _logged(void Function() body) {
  final lines = <String>[];
  runZoned(body,
      zoneSpecification:
          ZoneSpecification(print: (_, __, ___, line) => lines.add(line)));
  return lines;
}

void main() {
  final dashboard = MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'dashboardHome'),
      builder: (_) => const SizedBox());
  final devices = MaterialPageRoute<void>(
      settings: const RouteSettings(name: 'menuInstantDevices'),
      builder: (_) => const SizedBox());

  test('is the observer the app router is given', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final router = container.read(routerProvider);

    expect(router.routerDelegate.builder.observers,
        [same(container.read(routerLoggerProvider))]);
    expect(container.read(routerLoggerProvider), isA<RouterLogger>());
  });

  test('logs the name of each page pushed', () {
    final lines = _logged(() => RouterLogger().didPush(devices, dashboard));

    expect(lines.single, endsWith('did push the page - menuInstantDevices'));
  });

  test('logs each page popped, removed or replaced', () {
    final observer = RouterLogger();

    final lines = _logged(() {
      observer.didPop(devices, dashboard);
      observer.didRemove(devices, dashboard);
      observer.didReplace(newRoute: devices, oldRoute: dashboard);
    });

    expect(lines, [
      allOf(contains('did pop the page - '), contains('menuInstantDevices')),
      allOf(contains('did remove the page - '), contains('menuInstantDevices')),
      allOf(
          contains('did replace the page - '), contains('menuInstantDevices')),
    ]);
  });
}
