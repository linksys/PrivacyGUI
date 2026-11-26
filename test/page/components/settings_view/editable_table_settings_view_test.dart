import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/settings_view/editable_table_settings_view.dart';
import 'package:privacygui_widgets/widgets/text/app_text.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_widget.dart';

/// The identifiers that [ids] name, each with the number of nodes that have
/// it. Semantics must be on.
Map<String, int> _found(List<String> ids) => {
      for (final id in ids) id: find.bySemanticsIdentifier(id).evaluate().length
    };

// E2E tests locate a table's controls by these (constitution 11.2, 11.3): a
// row's key comes from its data, never from its position.
void main() {
  final deleted = <String>[];

  Future<void> pumpTable(WidgetTester tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableWidget(
      locale: const Locale('en'),
      child: AppEditableTableSettingsView<String>(
        identifier: 'pf',
        rowKey: (rule) => rule,
        headers: const ['Name'],
        dataList: const ['web', 'ftp'],
        cellBuilder: (context, ref, index, rule) => AppText.bodySmall(rule),
        editCellBuilder: (context, index, controller) => const SizedBox(),
        createNewItem: () => '',
        addLabel: 'Add',
        onDeleted: (index, rule) => deleted.add(rule),
      ),
    ));
    await tester.pumpAndSettle();
  }

  setUp(deleted.clear);

  testWidgets('a row\'s edit and delete are keyed by its data, add by none',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTable(tester);

    final found = _found([
      'pf-edit-web',
      'pf-delete-web',
      'pf-edit-ftp',
      'pf-delete-ftp',
      'pf-add',
    ]);
    await tester.tap(find.bySemanticsIdentifier('pf-delete-ftp'));
    // Before any expect: flutter_test checks for a live handle before
    // tear-down runs.
    semantics.dispose();

    expect(found.values, everyElement(1), reason: '$found');
    expect(deleted, ['ftp']);
  });

  testWidgets('the row being edited has save and cancel with its key',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTable(tester);

    await tester.tap(find.bySemanticsIdentifier('pf-edit-web'));
    await tester.pumpAndSettle();
    final found = _found(['pf-save-web', 'pf-cancel-web', 'pf-edit-web']);
    semantics.dispose();

    expect(found, {'pf-save-web': 1, 'pf-cancel-web': 1, 'pf-edit-web': 0});
  });

  testWidgets('the row being added has no data yet, so its key is new',
      (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpTable(tester);

    await tester.tap(find.bySemanticsIdentifier('pf-add'));
    await tester.pumpAndSettle();
    final found = _found(['pf-save-new', 'pf-cancel-new']);
    semantics.dispose();

    expect(found, {'pf-save-new': 1, 'pf-cancel-new': 1});
  });
}
