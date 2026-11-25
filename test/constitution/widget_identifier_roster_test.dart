import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

import '../common/testable_widget.dart';
import 'semantics_identifier.dart';
import 'source_scan.dart';

/// The identifier each constructor is given. A part's identifier replaces
/// `{id}` in its pattern with it.
const _id = 'roster';

/// The roster (constitution 11.4): the components the pilot pages use
/// (issue #1935). Issue #1936 adds the rest of `plugins/widgets`.
///
/// A constructor that ignores `id` has no identifier parameter yet; its
/// component has a row in the constitution 11.4 table until it gets one.
final Map<String, _Component> _roster = {
  'AppTextField': (
    constructors: {
      'AppTextField': (id) =>
          AppTextField(identifier: id, onChanged: _noopValue),
      'AppTextField.outline': (id) =>
          AppTextField.outline(identifier: id, onChanged: _noopValue),
      'AppTextField.macAddress': (id) =>
          AppTextField.macAddress(identifier: id, onChanged: _noopValue),
      'AppTextField.minMaxNumber': (id) => AppTextField.minMaxNumber(
          identifier: id, max: 10, onChanged: _noopValue),
    },
    identifiers: ['{id}'],
  ),
  'AppPasswordField': (
    constructors: {
      'AppPasswordField': (id) =>
          AppPasswordField(identifier: id, onChanged: _noopValue),
      'AppPasswordField.withValidator': (id) => AppPasswordField.withValidator(
            identifier: id,
            onChanged: _noopValue,
            validations: [
              Validation(description: 'Long', validator: (_) => true),
            ],
          ),
    },
    identifiers: ['{id}', '{id}-visibility'],
  ),
  'AppIPFormField': (
    constructors: {
      'AppIPFormField': (id) => AppIPFormField(
            identifier: id,
            controller: TextEditingController(),
            onChanged: _noopValue,
          ),
    },
    identifiers: [for (var i = 0; i < 4; i++) '{id}-octet-$i'],
  ),
  'AppDropdownButton': (
    constructors: {
      'AppDropdownButton': (id) => AppDropdownButton<String>(
            items: const ['a', 'b'],
            label: (item) => item,
            onChanged: _noopValue,
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppSwitch': (
    constructors: {
      'AppSwitch': (id) => AppSwitch(value: true, onChanged: _noopValue),
      'AppSwitch.withIcon': (id) =>
          AppSwitch.withIcon(value: true, onChanged: _noopValue),
    },
    identifiers: ['{id}'],
  ),
  'AppIconButton': (
    constructors: {
      'AppIconButton': (id) =>
          AppIconButton(icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.noPadding': (id) => AppIconButton.noPadding(
          icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.filled': (id) =>
          AppIconButton.filled(icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.noPaddingFilled': (id) => AppIconButton.noPaddingFilled(
          icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.outlined': (id) =>
          AppIconButton.outlined(icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.noPaddingOutlined': (id) =>
          AppIconButton.noPaddingOutlined(
              icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.tonal': (id) =>
          AppIconButton.tonal(icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.noPaddingTonal': (id) => AppIconButton.noPaddingTonal(
          icon: Icons.add, identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppTextButton': (
    constructors: {
      'AppTextButton': (id) =>
          AppTextButton('Save', identifier: id, onTap: _noop),
      'AppTextButton.noPadding': (id) =>
          AppTextButton.noPadding('Save', identifier: id, onTap: _noop),
      'AppTextButton.fillWidth': (id) =>
          AppTextButton.fillWidth('Save', identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppFilledButton': (
    constructors: {
      'AppFilledButton': (id) =>
          AppFilledButton('Save', identifier: id, onTap: _noop),
      'AppFilledButton.fillWidth': (id) =>
          AppFilledButton.fillWidth('Save', identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppCard': (
    constructors: {
      'AppCard': (id) => AppCard(
            identifier: id,
            onTap: _noop,
            child: const AppText('Card'),
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppListCard': (
    constructors: {
      'AppListCard': (id) =>
          AppListCard(title: const AppText('Card'), onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppSettingCard': (
    constructors: {
      'AppSettingCard': (id) => AppSettingCard(title: 'Card', onTap: _noop),
      'AppSettingCard.noBorder': (id) =>
          AppSettingCard.noBorder(title: 'Card', onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppText': (
    constructors: {
      'AppText': (id) => const AppText('Text'),
      // A selectable text is a read-only text field to the engine.
      'AppText (selectable)': (id) => const AppText('Text', selectable: true),
      'AppText.displayLarge': (id) => const AppText.displayLarge('Text'),
      'AppText.displayMedium': (id) => const AppText.displayMedium('Text'),
      'AppText.displaySmall': (id) => const AppText.displaySmall('Text'),
      'AppText.headlineLarge': (id) => const AppText.headlineLarge('Text'),
      'AppText.headlineMedium': (id) => const AppText.headlineMedium('Text'),
      'AppText.headlineSmall': (id) => const AppText.headlineSmall('Text'),
      'AppText.titleLarge': (id) => const AppText.titleLarge('Text'),
      'AppText.titleMedium': (id) => const AppText.titleMedium('Text'),
      'AppText.titleSmall': (id) => const AppText.titleSmall('Text'),
      'AppText.labelLarge': (id) => const AppText.labelLarge('Text'),
      'AppText.labelMedium': (id) => const AppText.labelMedium('Text'),
      'AppText.labelSmall': (id) => const AppText.labelSmall('Text'),
      'AppText.bodyLarge': (id) => const AppText.bodyLarge('Text'),
      'AppText.bodyMedium': (id) => const AppText.bodyMedium('Text'),
      'AppText.bodySmall': (id) => const AppText.bodySmall('Text'),
      'AppText.bodyExtraSmall': (id) => const AppText.bodyExtraSmall('Text'),
    },
    identifiers: ['{id}'],
  ),
  'AppFullScreenSpinner': (
    constructors: {
      'AppFullScreenSpinner': (id) => const AppFullScreenSpinner(),
    },
    identifiers: ['{id}'],
  ),
};

/// A component of `plugins/widgets` that the roster pumps: each public
/// constructor, given an identifier, and the identifiers the component
/// exposes for it, as patterns over `{id}`.
typedef _Component = ({
  Map<String, Widget Function(String id)> constructors,
  List<String> identifiers,
});

void _noop() {}

void _noopValue(Object? _) {}

/// Holds `plugins/widgets` to `constitution.md` 11.4: every identifier of every
/// component in the roster reaches the DOM, from every constructor, except for
/// the rows of the table in 11.4.
void main() {
  final listed = readExceptionTable(
      File('constitution.md').readAsStringSync(), 'identifier-roster');

  for (final MapEntry(key: component, value: (:constructors, :identifiers))
      in _roster.entries) {
    for (final pattern in identifiers) {
      final row = '$component -> $pattern';
      testWidgets('$component exposes $pattern where the web engine writes it',
          (tester) async {
        final semantics = tester.ensureSemantics();
        final identifier = pattern.replaceAll('{id}', _id);
        final problems = <String>[];
        for (final MapEntry(key: constructor, value: build)
            in constructors.entries) {
          await tester.pumpWidget(testableWidget(child: build(_id)));
          await tester.pump();
          final problem = identifierProblem(tester, identifier);
          if (problem != null) problems.add('$constructor: $problem');
        }
        // Before any expect: flutter_test checks for a live handle before
        // tear-down runs.
        semantics.dispose();

        if (listed.contains(row)) {
          expect(problems, isNotEmpty,
              reason: 'The row `$row` of the constitution.md 11.4 table no '
                  'longer matches: every constructor of $component exposes '
                  '$pattern now. Delete the row.');
        } else {
          expect(problems, isEmpty,
              reason: '$component breaks constitution.md 11.4 and has no row '
                  'for $pattern in its table:\n'
                  '${problems.map((p) => '  - $p').join('\n')}\n'
                  'Put the identifier on a node of its own (11.4). Adding a '
                  'row instead is an amendment (Article IX).');
        }
      });
    }
  }

  test('every row of the constitution.md 11.4 table is in the roster', () {
    final rostered = {
      for (final MapEntry(
            key: component,
            value: (:identifiers, constructors: _)
          ) in _roster.entries)
        for (final pattern in identifiers) '$component -> $pattern',
    };
    final stale = listed.difference(rostered);

    expect(stale, isEmpty,
        reason: 'These rows of the constitution.md 11.4 table name no '
            'component and identifier in the roster. Delete them:\n'
            '${bulletList(stale)}');
  });
}
