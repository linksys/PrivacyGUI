import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/mac_filter/models/mac_filter_device_ui_model.dart';
import 'package:privacy_gui/page/mac_filter/views/mac_filter_add_device_dialog.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../layout_gate/families/page_surface_family.dart';
import '../../../util/app_test_fonts.dart';

/// #1736: in the shared "Add device manually" dialog — opened by both Instant
/// Privacy and MAC Filtering — the MAC field lost focus after the first one or
/// two characters on Flutter web.
///
/// Measured on a web-server build (Chrome, CDP key events): with a connected
/// device whose name matches the query (so the autocomplete overlay is up), the
/// `<input>` blurred on the 2nd keystroke — `document.activeElement` went to
/// `BODY` and every later character was dropped. The blur coincided with the
/// semantics subtree that holds the `<input>` being removed and re-inserted in
/// the DOM. Toggling one thing at a time:
///
/// | variant                                   | focus after `aa:b` |
/// |-------------------------------------------|--------------------|
/// | as shipped (error as tooltip icon)        | lost at char 2     |
/// | no matching device (no autocomplete)      | kept               |
/// | no `setState` in `onChanged`              | kept               |
/// | `errorText: null`                         | kept               |
/// | `errorDisplayMode: AppErrorDisplayMode.text` | kept            |
///
/// The trigger is the error *tooltip icon* — an `AppTooltip` / overlay-backed
/// follower that mounts the moment the first character makes the value invalid.
/// Mounting it re-parents the text field's semantics node, and on web that is
/// the DOM move that drops focus. The web blur itself cannot be reproduced in a
/// widget test, so this file asserts the measurable precondition the web engine
/// acts on: the field's semantics node keeps the same ancestor chain while the
/// user types, alongside focus and text.
void main() {
  setUpAll(() async {
    await loadAppFonts();
  });

  const devices = [
    // `a` matches this label, so the autocomplete overlay is shown while
    // typing — part of the measured repro.
    MacFilterDeviceUIModel(
      mac: 'E8:D5:2B:77:AE:C5',
      displayName: 'Pixel-7a',
      ipAddress: '192.168.1.160',
    ),
  ];

  Widget host() => pageSurfaceHost(
        locale: const Locale('en'),
        overrides: const [],
        view: Builder(
          builder: (context) => Center(
            child: AppButton.primary(
              label: 'open',
              onTap: () => showMacFilterAddDeviceDialog(
                context: context,
                existingMacs: const [],
                connectedDevices: devices,
                onAdd: (_) {},
              ),
            ),
          ),
        ),
      );

  Future<void> settle(WidgetTester tester) async {
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
  }

  SemanticsNode fieldNode(WidgetTester tester) {
    // `getSemantics` returns the node that owns the EditableText's semantics:
    // the `identifier: mac-filter-add-mac-input` node AppTextField merges in.
    final node = tester.getSemantics(find.byType(EditableText));
    expect(node.getSemanticsData().identifier, 'mac-filter-add-mac-input',
        reason: 'the MAC field has its own semantics node');
    return node;
  }

  List<int> ancestorIds(SemanticsNode node) {
    final ids = <int>[];
    SemanticsNode? p = node.parent;
    while (p != null) {
      ids.add(p.id);
      p = p.parent;
    }
    return ids;
  }

  testWidgets(
      'typing three or more characters keeps focus, the text, and the '
      "field's place in the semantics tree", (tester) async {
    final semantics = tester.ensureSemantics();
    tester.view.physicalSize = const Size(1200, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(host());
    await settle(tester);
    await tester.tap(find.text('open'));
    await settle(tester);

    final field = find.byType(AppTextField);
    expect(field, findsOneWidget, reason: 'the add-device dialog is open');

    await tester.tap(find.byType(EditableText));
    await settle(tester);
    final focusNode = tester.widget<AppTextField>(field).focusNode!;
    expect(focusNode.hasFocus, isTrue, reason: 'the field took focus');

    final nodeBefore = fieldNode(tester);
    final chainBefore = ancestorIds(nodeBefore);

    var typed = '';
    for (final ch in 'aa:b'.split('')) {
      typed += ch;
      tester.testTextInput.updateEditingValue(TextEditingValue(
        text: typed,
        selection: TextSelection.collapsed(offset: typed.length),
      ));
      await settle(tester);

      final node = fieldNode(tester);
      expect(focusNode.hasFocus, isTrue,
          reason: 'still focused after "$typed"');
      expect(tester.widget<AppTextField>(field).controller!.text, typed,
          reason: 'every character landed');
      expect(node.id, nodeBefore.id,
          reason: 'the field keeps its semantics node after "$typed"');
      expect(ancestorIds(node), chainBefore,
          reason: 'the field is not re-parented in the semantics tree after '
              '"$typed" — on web that move is what blurs the <input> (#1736)');
    }

    // The value is invalid the whole way, so the error is actually on screen —
    // otherwise the checks above would pass for want of an error to show.
    expect(find.text('Invalid MAC address format (e.g. AA:BB:CC:DD:EE:FF)'),
        findsWidgets,
        reason: 'the invalid-format error is shown while typing');

    semantics.dispose();
  });
}
