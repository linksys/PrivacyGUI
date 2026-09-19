import 'dart:ui' show PointerDeviceKind;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart' show kSecondaryMouseButton;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/diagnostic_client.dart';
import 'package:privacy_gui/page/instant_verify/models/device_score.dart';
import 'package:privacy_gui/page/instant_verify/models/verdict.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_provider.dart';
import 'package:privacy_gui/page/instant_verify/providers/instant_verify_pivot_state.dart';
import 'package:privacy_gui/page/instant_verify/views/diagnostic_selection_area.dart';
import 'package:privacy_gui/page/instant_verify/views/instant_test_page.dart';
import '../../../common/di.dart';
import '../../../common/testable_widget.dart';

const devices = [
  DiagnosticClient(
      macAddress: 'AA:BB:CC:DD:EE:01',
      hostname: 'LB100',
      band: '2.4 GHz',
      isWireless: true,
      signalDecibels: -81),
  DiagnosticClient(
      macAddress: 'AA:BB:CC:DD:EE:02',
      hostname: 'LB100',
      band: '2.4 GHz',
      isWireless: true,
      signalDecibels: -89),
  DiagnosticClient(
      macAddress: 'AA:BB:CC:DD:EE:03',
      hostname: 'Healthy device',
      band: '5 GHz',
      isWireless: true,
      signalDecibels: -50),
];

class WarningNotifier extends InstantVerifyPivotNotifier {
  @override
  InstantVerifyPivotState build() => InstantVerifyPivotState(
        phase: PivotLoadPhase.complete,
        clients: devices,
        deviceScores: devices.map(DeviceScore.compute).toList(),
        verdict: const Verdict(findings: [
          VerdictFinding(
              priority: VerdictPriority.warning,
              headline: '2 devices with weak WiFi',
              explanation: 'LB100 and LB100 need help.')
        ]),
      );
  @override
  Future<void> fetch({bool forceSpeedTest = false}) async {}
}

Future<void> selectText(WidgetTester tester, String value) async {
  final box = tester.getRect(find.text(value));
  final mouse = await tester.startGesture(box.centerLeft + const Offset(1, 0),
      kind: PointerDeviceKind.mouse);
  await tester.pump();
  await mouse.moveTo(box.centerRight - const Offset(1, 0));
  await tester.pump();
  await mouse.up();
  await tester.pump();
}

Future<void> copy(WidgetTester tester) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
  await tester.sendKeyEvent(LogicalKeyboardKey.keyC);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
  await tester.pumpAndSettle();
}

void main() {
  mockDependencyRegister();
  for (final device in devices.take(2)) {
    testWidgets(
        'warning opens the exact duplicate-name device ${device.macAddress}',
        (tester) async {
      await tester.pumpWidget(testableWidget(overrides: [
        instantVerifyPivotProvider.overrideWith(WarningNotifier.new)
      ], child: const InstantTestPage()));
      await tester.pumpAndSettle();
      expect(
          find.text('Help Healthy device (AA:BB:CC:DD:EE:03)'), findsNothing);
      final action = find.text('Help LB100 (${device.macAddress})');
      await tester.ensureVisible(action);
      await tester.tap(action);
      await tester.pumpAndSettle();
      expect(find.text('Help for LB100'), findsOneWidget);
      expect(find.text('1. Choose a device'), findsNothing);
      await tester.ensureVisible(find.text('Connection details'));
      await tester.tap(find.text('Connection details'));
      await tester.pumpAndSettle();
      expect(
          find.textContaining('${device.signalDecibels} dBm'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
      'copying an editable field does not reuse the diagnostic selection',
      (tester) async {
    String? copied;
    final controller = TextEditingController(text: 'Device search');
    addTearDown(controller.dispose);
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = call.arguments['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: DiagnosticSelectionArea(
                child: Column(children: [
      const Text('Previous result'),
      TextField(controller: controller),
    ])))));
    await selectText(tester, 'Previous result');
    await tester.tap(find.byType(TextField));
    controller.selection = const TextSelection(baseOffset: 0, extentOffset: 13);
    await tester.pump();
    await copy(tester);
    expect(copied, 'Device search');
    expect(tester.takeException(), isNull);
  });
  testWidgets('context menu copies the selection captured before menu focus',
      (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    String? copied;
    tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copied = call.arguments['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));
    await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
            body: DiagnosticSelectionArea(
                child: Text('Diagnostic result to copy')))));
    await selectText(tester, 'Diagnostic result to copy');
    final mouse = await tester.startGesture(
        tester.getCenter(find.text('Diagnostic result to copy')),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton);
    await mouse.up();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copy'));
    await tester.pumpAndSettle();
    expect(copied, 'Diagnostic result to copy');
    expect(tester.takeException(), isNull);
    debugDefaultTargetPlatformOverride = null;
  });
  for (final denied in [false, true]) {
    testWidgets(
        'keyboard copy ${denied ? 'reports denial without throwing' : 'copies selected text'}',
        (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          if (denied) throw PlatformException(code: 'copy_fail');
          copied = call.arguments['text'] as String;
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await tester.pumpWidget(const MaterialApp(
          home: Scaffold(
              body: DiagnosticSelectionArea(
                  child: Text('Diagnostic result to copy')))));
      await selectText(tester, 'Diagnostic result to copy');
      await copy(tester);
      if (denied) {
        expect(find.textContaining('Copy was blocked'), findsOneWidget);
      } else {
        expect(copied, 'Diagnostic result to copy');
      }
      expect(tester.takeException(), isNull);
    });
  }
}
