import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/components/settings_view/editable_card_list_settings_view.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_widget.dart';

// E2E tests locate a card list's controls by these (constitution 11.2, 11.3),
// the same as the table that the desktop layout shows instead.
void main() {
  testWidgets('a card\'s edit and delete are keyed by its data, add by none',
      (tester) async {
    final deleted = <String>[];
    final semantics = tester.ensureSemantics();
    await tester.setScreenSize(device480w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableWidget(
      locale: const Locale('en'),
      child: AppEditableCardListSettingsView<String>(
        identifier: 'pf',
        rowKey: (rule) => rule,
        // The add button is among the title's actions.
        title: 'Rules',
        addLabel: 'Add',
        dataList: const ['web', 'ftp'],
        itemCardBuilder: (context, rule) =>
            EditableListItem(title: rule, content: const SizedBox()),
        editRoute: 'unused',
        onDelete: (index, rule) => deleted.add(rule),
      ),
    ));
    await tester.pumpAndSettle();

    final found = {
      for (final id in [
        'pf-edit-web',
        'pf-delete-web',
        'pf-edit-ftp',
        'pf-delete-ftp',
        'pf-add',
      ])
        id: find.bySemanticsIdentifier(id).evaluate().length,
    };
    await tester.tap(find.bySemanticsIdentifier('pf-delete-ftp'));
    // Before any expect: flutter_test checks for a live handle before
    // tear-down runs.
    semantics.dispose();

    expect(found.values, everyElement(1), reason: '$found');
    expect(deleted, ['ftp']);
  });
}
