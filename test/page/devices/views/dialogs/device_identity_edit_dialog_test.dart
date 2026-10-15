@Tags(['ui'])
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
/// it. [onPopped] receives what the dialog popped with.
Future<void> _pumpAndOpen(
  WidgetTester tester, {
  String initialName = '',
  DeviceCategory initialCategory = DeviceCategory.unknown,
  required void Function(_Result?) onPopped,
}) async {
  final router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () async {
                  onPopped(await showAppDialog<_Result>(
                    context: context,
                    builder: (_) => DeviceIdentityEditDialog(
                      initialName: initialName,
                      initialCategory: initialCategory,
                      detectedName: 'android-1a2b',
                    ),
                  ));
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
}
