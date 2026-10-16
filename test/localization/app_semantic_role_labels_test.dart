import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show SemanticsData;
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/app_semantic_role_labels.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// The role word ui_kit announces for a control nobody named (#1315).
///
/// ui_kit ends every component's label chain in `SemanticRoleLabels.of`, which
/// returns English unless the host installs a resolver. Before this file the app
/// installed none, so a zh_TW screen reader heard "Switch" and "Icon button" in
/// an otherwise Chinese UI.
void main() {
  setUpAll(AppSemanticRoleLabels.install);
  tearDownAll(() => SemanticRoleLabels.resolver = null);

  group('the kit reads its role words from the app', () {
    Future<SemanticsData> pumpInLocale(
      WidgetTester tester,
      Locale locale,
      Widget control,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          locale: locale,
          // `AppSwitch` reads `Theme.of(context).extension<AppDesignTheme>()!`,
          // so a bare `ThemeData` throws.
          theme: AppTheme.create(
            brightness: Brightness.light,
            seedColor: Colors.blue,
            designThemeBuilder: (c) =>
                CustomDesignTheme.fromJson({'style': 'flat'}),
          ),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: Center(child: control)),
        ),
      );
      // Bounded, not `pumpAndSettle`: the busy figure animates forever.
      await tester.pump();
      return tester.getSemantics(find.byWidget(control)).getSemanticsData();
    }

    testWidgets('an unnamed switch announces the zh_TW role word',
        (tester) async {
      final handle = tester.ensureSemantics();
      final zhTw = lookupAppLocalizations(const Locale('zh', 'TW'));

      final data = await pumpInLocale(
        tester,
        const Locale('zh', 'TW'),
        AppSwitch(value: true, onChanged: (_) {}),
      );

      expect(data.label, zhTw.semanticRoleSwitch);
      expect(data.label,
          isNot(SemanticRoleLabels.english(SemanticRoleLabel.toggle)));
      handle.dispose();
    });

    testWidgets(
        'a busy icon button announces both its role and busy in the locale',
        (tester) async {
      final handle = tester.ensureSemantics();
      final ja = lookupAppLocalizations(const Locale('ja'));

      final data = await pumpInLocale(
        tester,
        const Locale('ja'),
        AppIconButton(
          icon: AppIcon.font(Icons.refresh),
          onTap: () {},
          isLoading: true,
        ),
      );

      expect(data.label, ja.semanticRoleIconButton);
      // Busy reads the same `processing` string the app already hands
      // `AppSwitch.busySemanticLabel`, so a button and a switch saving side by
      // side are not announced in two different words.
      expect(data.hint, ja.processing);
      handle.dispose();
    });
  });

  group('resolve', () {
    test('every role this app reaches resolves in every shipped locale', () {
      // Unreachable from `lib/`: `GlobalMaterialLocalizations` names every
      // dismiss barrier first, and nothing mounts a slider or a side sheet, or
      // sets `onDeleted:` on a tag or badge.
      const deferred = {
        SemanticRoleLabel.deleteTarget,
        SemanticRoleLabel.dismissBarrier,
        SemanticRoleLabel.sideSheet,
        SemanticRoleLabel.slider,
      };
      for (final locale in AppLocalizations.supportedLocales) {
        for (final role in SemanticRoleLabel.values) {
          final label = AppSemanticRoleLabels.resolve(locale, role, null);
          if (deferred.contains(role)) {
            expect(label, isNull,
                reason: '$role has no app string; null defers it to English');
          } else {
            expect(label, isNotNull, reason: '$role in $locale');
            expect(label, isNotEmpty, reason: '$role in $locale');
          }
        }
      }
    });

    test('no locale defers to English', () {
      // The kit passes null where no `Localizations` ancestor is mounted.
      expect(
        AppSemanticRoleLabels.resolve(null, SemanticRoleLabel.toggle, null),
        isNull,
      );
    });

    test('a locale this app does not ship defers to English, not a throw', () {
      // `lookupAppLocalizations` throws a `FlutterError` for an unsupported
      // locale, and the resolver runs during `build`.
      expect(
        AppSemanticRoleLabels.resolve(
            const Locale('xx'), SemanticRoleLabel.toggle, null),
        isNull,
      );
    });
  });

  test('every key the resolver reads is translated in every ARB file', () {
    // gen-l10n silently falls back to the template for a key a locale lacks, so
    // a role word added to `app_en.arb` alone still compiles and still reads
    // English — the exact defect this file exists for. The resolve test above
    // cannot see that: the back-filled getter is never null.
    final template =
        jsonDecode(File('lib/l10n/app_en.arb').readAsStringSync()) as Map;
    final roleKeys = [
      ...template.keys
          .cast<String>()
          .where((k) => k.startsWith('semanticRole')),
      // Shared with on-screen copy rather than owned by a role.
      'processing', 'ipAddress', 'menu',
    ];
    expect(roleKeys, hasLength(greaterThan(3)),
        reason: 'no `semanticRole*` key in app_en.arb; this check would pass '
            'vacuously');

    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => RegExp(r'app_\w+\.arb$').hasMatch(f.path))
        .toList();
    expect(arbs, hasLength(AppLocalizations.supportedLocales.length));
    for (final arb in arbs) {
      final entries = jsonDecode(arb.readAsStringSync()) as Map;
      for (final key in roleKeys) {
        expect(entries[key], isA<String>(), reason: '$key in ${arb.path}');
      }
    }
  });
}
