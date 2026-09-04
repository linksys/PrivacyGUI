import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/layouts/idle_checker.dart';

void main() {
  testWidgets('idle checker fires once after the configured inactivity window',
      (tester) async {
    var idleCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: IdleChecker(
            idleTime: const Duration(seconds: 1),
            onIdle: () => idleCalls++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 999));
    expect(idleCalls, 0);
    await tester.pump(const Duration(milliseconds: 1));
    expect(idleCalls, 1);
  });

  testWidgets('user interaction restarts the inactivity window',
      (tester) async {
    var idleCalls = 0;
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: IdleChecker(
            idleTime: const Duration(seconds: 1),
            onIdle: () => idleCalls++,
            child: const SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.pump(const Duration(milliseconds: 750));
    await tester.tapAt(const Offset(400, 300));
    await tester.pump(const Duration(milliseconds: 750));
    expect(idleCalls, 0);
    await tester.pump(const Duration(milliseconds: 250));
    expect(idleCalls, 1);
  });
}
