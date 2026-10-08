import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/components/widgets/read_only_banner.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../common/testable_widget.dart';

const _message = 'Read-only mode. Settings can be viewed but not changed.';
const _readOnly = AccessPolicy(canWrite: false);

// #1637: a login that may not write is told so on every dashboard page, so it
// knows why nothing on them can be saved.
void main() {
  mockDependencyRegister();

  Future<void> pumpBanner(WidgetTester tester, AccessPolicy policy,
      {Locale locale = const Locale('en')}) async {
    await tester.pumpWidget(testableWidget(
      locale: locale,
      overrides: [accessPolicyProvider.overrideWithValue(policy)],
      child: const ReadOnlyBanner(),
    ));
    await tester.pumpAndSettle();
  }

  testWidgets('renders nothing for a login that may write', (tester) async {
    await pumpBanner(tester, AccessPolicy.full);

    expect(find.text(_message), findsNothing);
    expect(find.byIcon(Icons.visibility_outlined), findsNothing);
  });

  testWidgets('tells a read-only login that nothing can be saved',
      (tester) async {
    await pumpBanner(tester, _readOnly);

    expect(find.text(_message), findsOneWidget);
  });

  // Every locale carries its own wording, not the English fallback.
  test('every locale translates the message', () {
    final arbs = Directory('lib/l10n')
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.arb'));
    expect(arbs, hasLength(AppLocalizations.supportedLocales.length));
    for (final arb in arbs) {
      final text = (jsonDecode(arb.readAsStringSync())
          as Map<String, dynamic>)['readOnlyModeBanner'];
      expect(text, isA<String>(), reason: arb.path);
      if (!arb.path.endsWith('app_en.arb')) {
        expect(text, isNot(_message), reason: '${arb.path} is not translated');
      }
    }
  });

  testWidgets('shows the translation for the current locale', (tester) async {
    await pumpBanner(tester, _readOnly, locale: const Locale('zh', 'TW'));

    expect(find.text('唯讀模式。可以檢視設定，但無法變更。'), findsOneWidget);
  });

  // The shell wraps every dashboard page, so the banner is on all of them.
  testWidgets('sits at the top of the dashboard shell', (tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableRouteShellWidget(
      locale: const Locale('en'),
      overrides: [accessPolicyProvider.overrideWithValue(_readOnly)],
      child: const Text('a dashboard page'),
    ));
    await tester.pumpAndSettle();

    final banner = tester.getRect(find.byType(ReadOnlyBanner));
    final page = tester.getRect(find.text('a dashboard page'));
    expect(banner.top, lessThan(page.top),
        reason: 'the banner is above the page it explains');
  });
}
