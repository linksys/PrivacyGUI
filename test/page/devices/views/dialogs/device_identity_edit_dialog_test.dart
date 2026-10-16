@Tags(['ui'])
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/utils/device_classifier.dart';
import 'package:privacy_gui/page/devices/views/dialogs/device_identity_edit_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// Widget tests for [DeviceIdentityEditDialog] (#1691): what it pops with,
/// and that a name the firmware would refuse cannot be saved.
final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

typedef _Result = ({String name, DeviceCategory category});

/// Pumps the dialog inside a GoRouter (the dialog calls context.pop) and opens
/// it. [onPopped] receives what the dialog saved, once the dialog has closed
/// after saving; it is never called on cancel. [onSave] replaces the default
/// save, which completes at once.
Future<void> _pumpAndOpen(
  WidgetTester tester, {
  String initialName = '',
  DeviceCategory initialCategory = DeviceCategory.unknown,
  bool showIcon = true,
  required void Function(_Result?) onPopped,
  Future<void> Function(String name, DeviceCategory category)? onSave,
}) async {
  _Result? saved;
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  final closedAfterSave = await showAppDialog<bool>(
                    context: context,
                    builder: (_) => DeviceIdentityEditDialog(
                      initialName: initialName,
                      initialCategory: initialCategory,
                      detectedName: 'android-1a2b',
                      showIcon: showIcon,
                      onSave: (name, category) async {
                        saved = (name: name, category: category);
                        await onSave?.call(name, category);
                      },
                    ),
                  );
                  if (closedAfterSave == true) onPopped(saved);
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    ],
  );

  await tester.pumpWidget(MaterialApp.router(
    theme: _testTheme,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: router,
  ));
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
}

void main() {
  late AppLocalizations l;

  setUp(() async {
    l = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Finder save() => find.widgetWithText(AppButton, l.save);

  testWidgets('saves the trimmed name and the picked icon', (tester) async {
    _Result? popped;
    await _pumpAndOpen(tester, onPopped: (r) => popped = r);

    await tester.enterText(find.byType(TextField), '  Living room TV  ');
    // The chips scroll inside the dialog on the 800×600 test surface.
    await tester.ensureVisible(find.text(DeviceCategory.tv.displayName));
    await tester.pumpAndSettle();
    await tester.tap(find.text(DeviceCategory.tv.displayName));
    await tester.pumpAndSettle();
    await tester.tap(save());
    await tester.pumpAndSettle();

    expect(popped?.name, 'Living room TV');
    expect(popped?.category, DeviceCategory.tv);
  });

  testWidgets('Auto pops unknown, which clears the user icon', (tester) async {
    _Result? popped;
    await _pumpAndOpen(
      tester,
      initialName: 'Kitchen',
      initialCategory: DeviceCategory.camera,
      onPopped: (r) => popped = r,
    );

    await tester.tap(find.text(l.auto));
    await tester.pumpAndSettle();
    await tester.tap(save());
    await tester.pumpAndSettle();

    expect(popped?.name, 'Kitchen');
    expect(popped?.category, DeviceCategory.unknown);
  });

  testWidgets('the empty-name hint shows even with a name filled in',
      (tester) async {
    await _pumpAndOpen(tester, initialName: 'Kitchen', onPopped: (_) {});

    expect(find.text(l.deviceNameHint), findsOneWidget);
  });

  testWidgets('Reset pops a cleared name and Auto, whatever was edited',
      (tester) async {
    _Result? popped;
    await _pumpAndOpen(
      tester,
      initialName: 'Kitchen',
      initialCategory: DeviceCategory.camera,
      onPopped: (r) => popped = r,
    );

    await tester.enterText(find.byType(TextField), 'Something else');
    await tester.tap(find.widgetWithText(AppButton, l.reset));
    await tester.pumpAndSettle();

    expect(popped?.name, '');
    expect(popped?.category, DeviceCategory.unknown);
  });

  testWidgets('Reset does nothing for a device with nothing set',
      (tester) async {
    var poppedCalled = false;
    await _pumpAndOpen(tester, onPopped: (_) => poppedCalled = true);

    await tester.tap(find.widgetWithText(AppButton, l.reset));
    await tester.pumpAndSettle();

    expect(poppedCalled, isFalse);
    expect(find.byType(DeviceIdentityEditDialog), findsOneWidget);
  });

  testWidgets('a name over 64 bytes shows the error and cannot be saved',
      (tester) async {
    var poppedCalled = false;
    await _pumpAndOpen(tester, onPopped: (_) => poppedCalled = true);

    await tester.enterText(find.byType(TextField), '客' * 22); // 66 bytes
    await tester.pumpAndSettle();

    final field = tester.widget<AppTextField>(find.byType(AppTextField));
    expect(field.errorText, l.deviceNameTooLong);
    await tester.tap(save());
    await tester.pumpAndSettle();
    expect(poppedCalled, isFalse);
    expect(find.byType(DeviceIdentityEditDialog), findsOneWidget);
  });

  // The router is named, not typed: the node page reuses the dialog without
  // the icon choice (#1691).
  testWidgets('without the icon choice, only the name is edited',
      (tester) async {
    _Result? popped;
    await _pumpAndOpen(
      tester,
      initialName: 'Office',
      showIcon: false,
      onPopped: (r) => popped = r,
    );

    expect(find.text(l.deviceIcon), findsNothing);
    expect(find.text(l.auto), findsNothing);
    await tester.enterText(find.byType(TextField), 'Study');
    await tester.tap(save());
    await tester.pumpAndSettle();
    expect(popped?.name, 'Study');
  });

  // Saving takes a Set and two reads. The dialog stays up with a busy Save
  // until it finishes, so the user sees it working (#1691).
  testWidgets('while saving, the dialog stays open and Save is busy',
      (tester) async {
    final gate = Completer<void>();
    _Result? popped;
    await _pumpAndOpen(
      tester,
      onPopped: (r) => popped = r,
      onSave: (_, __) => gate.future,
    );

    await tester.enterText(find.byType(TextField), 'Office');
    await tester.tap(save());
    await tester.pump();

    expect(find.byType(DeviceIdentityEditDialog), findsOneWidget);
    expect(tester.widget<AppButton>(save()).isLoading, isTrue);
    expect(popped, isNull);

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.byType(DeviceIdentityEditDialog), findsNothing);
    expect(popped?.name, 'Office');
  });

  testWidgets('a failed save keeps the dialog open and shows why',
      (tester) async {
    var poppedCalled = false;
    await _pumpAndOpen(
      tester,
      onPopped: (_) => poppedCalled = true,
      onSave: (_, __) async => throw Exception('refused'),
    );

    await tester.enterText(find.byType(TextField), 'Office');
    await tester.tap(save());
    await tester.pumpAndSettle();

    expect(find.byType(DeviceIdentityEditDialog), findsOneWidget);
    expect(find.text(l.errorUnexpected), findsOneWidget);
    expect(tester.widget<AppButton>(save()).isLoading, isFalse);
    expect(poppedCalled, isFalse);
  });
}
