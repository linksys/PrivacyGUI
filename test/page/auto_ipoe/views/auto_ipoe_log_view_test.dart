import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/views/auto_ipoe_log_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

void main() {
  for (final compact in [false, true]) {
    for (final language in ['en', 'ja']) {
      testWidgets(
          'log opens, refreshes, and hides on $language phone compact=$compact',
          (tester) async {
        tester.view.physicalSize = const Size(360, 700);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        var reads = 0;
        var log = const AutoIPoELog.init();
        final pending = Completer<bool>();
        late StateSetter update;
        await tester.pumpWidget(MaterialApp(
          theme: AppTheme.create(brightness: Brightness.light),
          locale: Locale(language),
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
            update = setState;
            return Padding(
                padding: const EdgeInsets.all(16),
                child: AutoIPoELogView(
                  log: log,
                  compact: compact,
                  onRefresh: () {
                    reads++;
                    return reads == 1 ? pending.future : Future.value(false);
                  },
                ));
          })),
        ));
        Finder button(String id) => find.byKey(ValueKey(id));
        expect(reads, 0);
        final toggle =
            tester.widget<TextButton>(button('auto-ipoe-log-toggle'));
        final normalSize =
            Theme.of(tester.element(find.byType(AutoIPoELogView)))
                .textTheme
                .labelLarge!
                .fontSize!;
        expect(toggle.style!.textStyle!.resolve({})!.fontSize,
            compact ? normalSize * 0.7 : null);
        expect(find.byType(SelectableText), findsNothing);
        await tester.tap(button('auto-ipoe-log-toggle'));
        await tester.pump();
        expect(reads, 1);
        expect(find.byType(LinearProgressIndicator), findsOneWidget);
        expect(button('auto-ipoe-log-refresh'), findsNothing);
        update(() =>
            log = log.copyWith(content: 'MAP-E ready\n### end of logging'));
        pending.complete(true);
        await tester.pumpAndSettle();
        expect(find.text('MAP-E ready\n### end of logging'), findsOneWidget);
        expect(find.byType(LinearProgressIndicator), findsNothing);
        await tester.tap(button('auto-ipoe-log-toggle'));
        await tester.pumpAndSettle();
        await tester.tap(button('auto-ipoe-log-toggle'));
        await tester.pumpAndSettle();
        expect(button('auto-ipoe-log-refresh'), findsNothing);
        expect(reads, 2);
        expect(find.text('MAP-E ready\n### end of logging'), findsOneWidget);
        final l =
            AppLocalizations.of(tester.element(find.byType(AutoIPoELogView)))!;
        expect(find.text(l.failedToLoadSettings), findsOneWidget);
        await tester.tap(button('auto-ipoe-log-toggle'));
        await tester.pumpAndSettle();
        expect(find.byType(SelectableText), findsNothing);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
