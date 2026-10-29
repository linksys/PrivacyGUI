import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/views/mac_filter_add_device_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../util/app_test_fonts.dart';

/// #1737: a MAC typed into the shared "Add device manually" dialog (Instant
/// Privacy and MAC Filtering) no longer needs its separators.
///
/// The field is also the name / MAC / IP search box, so per the spec comment on
/// the issue nothing is formatted while typing: a bare or dotted MAC is
/// accepted as is, a helper line shows the canonical form it will be added as,
/// and the text is rewritten to that form only when the field loses focus.
///
/// Untagged on purpose, like the other view tests in this directory.
void main() {
  const confirmId = 'mac-filter-add-mac-confirm';
  const invalidFormat = 'Invalid MAC address format (e.g. AA:BB:CC:DD:EE:FF)';
  const canonical = 'AA:BB:CC:DD:EE:FF';
  const previewLine = 'Will be added as $canonical';

  const devices = [
    MacFilterDeviceUIModel(
      mac: 'E8:D5:2B:77:AE:C5',
      displayName: 'Pixel-7a',
      ipAddress: '192.168.1.160',
    ),
    // A name made only of hex letters: must be searchable, never reformatted.
    MacFilterDeviceUIModel(
      mac: '02:11:22:33:44:55',
      displayName: 'Cafe',
      ipAddress: '192.168.1.161',
    ),
  ];

  late List<String> added;

  setUpAll(() async {
    await loadAppFonts();
  });

  setUp(() => added = []);

  Widget host({List<String> existingMacs = const []}) => pageSurfaceHost(
        locale: const Locale('en'),
        overrides: const [],
        view: Builder(
          builder: (context) => Center(
            child: AppButton.primary(
              label: 'open',
              onTap: () => showMacFilterAddDeviceDialog(
                context: context,
                existingMacs: existingMacs,
                connectedDevices: devices,
                onAdd: added.add,
              ),
            ),
          ),
        ),
      );

  Future<void> settle(WidgetTester tester, [int frames = 5]) async {
    for (var i = 0; i < frames; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  Future<void> openDialog(WidgetTester tester,
      {List<String> existingMacs = const []}) async {
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host(existingMacs: existingMacs));
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester);
    expect(find.byType(AppTextField), findsOneWidget,
        reason: 'the add-device dialog is open');
  }

  AppTextField field(WidgetTester tester) =>
      tester.widget<AppTextField>(find.byType(AppTextField));

  /// Types [text] one character at a time, as a keyboard would, so a per-
  /// keystroke rewrite would show up on the way.
  Future<void> type(WidgetTester tester, String text) async {
    await tester.tap(find.byType(EditableText));
    await settle(tester);
    var typed = '';
    for (final ch in text.split('')) {
      typed += ch;
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: typed,
        selection: TextSelection.collapsed(offset: typed.length),
      ));
      await settle(tester, 1);
      expect(field(tester).controller!.text, typed,
          reason: 'not rewritten while typing ("$typed")');
    }
    await settle(tester);
  }

  /// Replaces the whole value in one edit, as a paste does.
  Future<void> paste(WidgetTester tester, String text) async {
    await tester.tap(find.byType(EditableText));
    await settle(tester);
    tester.testTextInput.updateEditingValue(TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    ));
    await settle(tester);
  }

  Future<void> blur(WidgetTester tester) async {
    field(tester).focusNode!.unfocus();
    await settle(tester);
  }

  VoidCallback? addTap(WidgetTester tester) => tester
      .widget<AppButton>(find.byWidgetPredicate(
          (w) => w is AppButton && w.identifier == confirmId))
      .onTap;

  group('accepted spellings (AC1, AC3)', () {
    for (final form in [
      'aabbccddeeff',
      'AABBCCDDEEFF',
      'aabb.ccdd.eeff',
      'aa-bb-cc-dd-ee-ff',
      'aa:bb:cc:dd:ee:ff',
    ]) {
      testWidgets('"$form" typed: kept as typed, previewed, addable',
          (tester) async {
        await openDialog(tester);
        await type(tester, form);

        expect(field(tester).controller!.text, form,
            reason: 'the field text is not changed while typing (AC3)');
        expect(find.text(previewLine), findsOneWidget,
            reason: 'the canonical form is shown under the field (AC3)');
        expect(find.text(invalidFormat), findsNothing);
        expect(addTap(tester), isNotNull, reason: 'Add is enabled (AC1)');
      });
    }
  });

  group('no preview, no rewrite (AC3, AC6)', () {
    for (final text in ['aabb', 'aabbccddeef', '192.168', 'Pixel', 'Cafe']) {
      testWidgets('"$text" shows no preview and is never reformatted',
          (tester) async {
        await openDialog(tester);
        await type(tester, text);

        expect(find.textContaining('Will be added as'), findsNothing,
            reason: 'partial input, an IP or a name is not a MAC');

        await blur(tester);
        expect(field(tester).controller!.text, text,
            reason: 'blur leaves anything but a complete MAC alone');
      });
    }
  });

  testWidgets('submitting a bare MAC adds the canonical form (AC2)',
      (tester) async {
    await openDialog(tester);
    await type(tester, 'aabbccddeeff');

    await tester.tap(find
        .byWidgetPredicate((w) => w is AppButton && w.identifier == confirmId));
    await settle(tester, 20);

    expect(added, [canonical]);
    expect(find.text('Add device manually'), findsNothing,
        reason: 'the dialog accepted the value and popped');
  });

  testWidgets('on blur a complete MAC is rewritten to the canonical form (AC4)',
      (tester) async {
    await openDialog(tester);
    await type(tester, 'aabb.ccdd.eeff');

    await blur(tester);

    expect(field(tester).controller!.text, canonical);
    expect(find.text(previewLine), findsOneWidget);
    expect(addTap(tester), isNotNull);
  });

  group('paste (AC5)', () {
    testWidgets('a pasted bare MAC behaves as typed', (tester) async {
      await openDialog(tester);
      await paste(tester, 'aabbccddeeff');

      expect(field(tester).controller!.text, 'aabbccddeeff');
      expect(find.text(previewLine), findsOneWidget);
      expect(addTap(tester), isNotNull);
    });

    testWidgets('longer input is not truncated and stays invalid',
        (tester) async {
      await openDialog(tester);
      await paste(tester, 'AABBCCDDEEFF0');

      expect(field(tester).controller!.text, 'AABBCCDDEEFF0',
          reason: 'no auto-truncation');
      expect(find.text(invalidFormat), findsWidgets);
      expect(find.textContaining('Will be added as'), findsNothing);
      expect(addTap(tester), isNull);
    });
  });

  testWidgets('a bare MAC already on the list is reported as a duplicate',
      (tester) async {
    await openDialog(tester, existingMacs: const [canonical]);
    await type(tester, 'aabbccddeeff');

    expect(
        find.text('This device is already in the allowed list'), findsWidgets);
    expect(find.textContaining('Will be added as'), findsNothing,
        reason: 'no "will be added" line for a value that cannot be added');
    expect(addTap(tester), isNull);
  });

  group('search by name and IP is unchanged (AC6)', () {
    for (final (query, label) in [
      ('Pixel', 'Pixel-7a'),
      ('192.168.1.16', 'Pixel-7a'),
      ('Cafe', 'Cafe'),
      ('E8:D5', 'Pixel-7a'),
    ]) {
      testWidgets('"$query" suggests $label', (tester) async {
        await openDialog(tester);
        await type(tester, query);

        expect(
            find.descendant(
                of: find.byType(ListView), matching: find.text(label)),
            findsOneWidget,
            reason: 'the autocomplete overlay offers the device');
      });
    }
  });
}
