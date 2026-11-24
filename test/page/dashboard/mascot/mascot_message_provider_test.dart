import 'dart:async';

import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/localization/supported_locales_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/mascot_message_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/dashboard_domain_ready_provider.dart';

/// #1312: the mascot's speech bubbles are in the language the app runs in.
///
/// What a template says in each language is pinned in
/// `mascot_message_templates_test.dart`; this pins that the provider hands the
/// templates the app's strings rather than some other locale's.
void main() {
  test('a bubble is in the language the app runs in', () {
    final container = ProviderContainer(overrides: [
      appLocalizationsProvider
          .overrideWithValue(lookupAppLocalizations(const Locale('ja'))),
      // Never ready, so the notifier says its line for a dashboard that has
      // not loaded and reads no router data.
      dashboardDomainReadyProvider
          .overrideWith((ref) => Completer<void>().future),
    ]);
    addTearDown(container.dispose);

    // `app_ja.arb`'s mascotTipHere.
    expect(container.read(mascotMessageProvider).getRandomMessage().text,
        '困ったときは、いつでもここにいますよ！');
  });
}
