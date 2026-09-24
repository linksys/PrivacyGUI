import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/views/sections/usp_renew_section.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/provider_overrides/mock_wan_data.dart';

/// Widget tests for the Release & Renew section's WAN address — #1587 Phase 2 and the
/// #1613 review.
///
/// WHY THESE EXIST, and why the first attempt at this fix needed them. Round 1 of the
/// review found that an L1 fetch error rendered as a valid "no address" reading. I fixed
/// the banner and "fixed" this widget by passing `null` instead of `''` — but
/// `UspRenewActionCard` rendered both as '--', so **the change altered no pixel and no
/// behaviour**. Round 2 caught that: a comment asserted a distinction the widget tree
/// erased. With no test for this file, nothing else could have caught it.
///
/// So these assert rendered output and interactivity, never the local variable.

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

InternetSettingsFeatureState _state({
  UspWanConnectionType type = UspWanConnectionType.dhcp,
}) {
  final form = UspInternetSettingsForm(connectionType: type);
  return InternetSettingsFeatureState(
    settings: Preservable(
      original: InternetSettingsSettings(form: form),
      current: InternetSettingsSettings(form: form),
    ),
    status: const InternetSettingsStatus(isLoading: false, isEditing: false),
  );
}

Widget _host(
  Override wanOverride, {
  UspWanConnectionType type = UspWanConnectionType.dhcp,
}) {
  return ProviderScope(
    overrides: [wanOverride],
    child: MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: UspRenewSection(state: _state(type: type)),
        ),
      ),
    ),
  );
}

/// The IPv4 renew button. The IPv6 card has one too, so this is scoped by looking for the
/// first — the IPv4 card is rendered first in the column.
Finder _renewButtons() =>
    find.byWidgetPredicate((w) => w is AppButton && w.onTap != null,
        description: 'enabled renew buttons');

void main() {
  group('UspRenewSection — the address comes from L1', () {
    testWidgets('renders the address L1 reported', (t) async {
      await t.pumpWidget(_host(wanDataOverride()));
      await t.pumpAndSettle();

      expect(find.text('100.64.0.10'), findsOneWidget);
    });

    testWidgets('a device-reported empty address renders --', (t) async {
      await t.pumpWidget(_host(wanDataOverride(wanNoAddressModel)));
      await t.pumpAndSettle();

      // Two cards, and IPv6 never gets an address, so '--' appears twice here.
      expect(find.text('--'), findsNWidgets(2));
    });
  });

  group('UspRenewSection — unknown is not "no address" (#1613 round 2)', () {
    testWidgets('a fetch error renders "unknown", not --', (t) async {
      await t.pumpWidget(_host(wanDataErrorOverride()));
      await t.pumpAndSettle();

      // THE REGRESSION THIS BLOCKS: passing `null` here instead of `''` rendered '--'
      // either way, so the previous round's "fix" to this file was a no-op. If someone
      // reverts `addressLabel`, IPv4 goes back to '--' and this fails.
      expect(find.text('Unknown'), findsOneWidget,
          reason: 'IPv4 must say so when L1 could not be read');
      // IPv6 still shows '--' — it is passed no address at all, which is a separate
      // pre-existing gap and deliberately not changed here.
      expect(find.text('--'), findsOneWidget);
    });

    testWidgets('the first load also renders "unknown"', (t) async {
      await t.pumpWidget(_host(wanDataLoadingOverride()));
      await t.pump();

      expect(find.text('Unknown'), findsOneWidget);
    });

    testWidgets('the IPv4 renew is disabled while its address is unreadable',
        (t) async {
      // Offering a renew of a lease whose current state could not be read is a worse
      // offer than no offer: the user cannot tell whether it did anything.
      //
      // SCOPED TO IPv4 ON PURPOSE. The IPv6 card stays enabled, because
      // `wanIpReadingProvider` is the IPv4 address and an unreadable IPv4 says nothing
      // about the IPv6 lease. Disabling both would have been a wider behaviour change
      // than the finding called for — so the count here is 1, not 0, and that 1 is the
      // IPv6 button.
      await t.pumpWidget(_host(wanDataErrorOverride()));
      await t.pumpAndSettle();
      expect(_renewButtons(), findsOneWidget,
          reason:
              'IPv4 must be disabled and IPv6 must not — exactly one enabled button');
    });

    // Separate tests rather than more pumps in the one above: re-pumping a new
    // `ProviderScope` into the same tester reuses the element and the override does not
    // take effect, which showed up as a confusing "found 1, expected 2".
    testWidgets('a readable address allows both renews', (t) async {
      await t.pumpWidget(_host(wanDataOverride()));
      await t.pumpAndSettle();
      expect(_renewButtons(), findsNWidgets(2));
    });

    testWidgets('a device-reported empty address still allows renew',
        (t) async {
      // This is precisely when a user reaches for Renew, so the unknown-state guard must
      // not catch this case too.
      await t.pumpWidget(_host(wanDataOverride(wanNoAddressModel)));
      await t.pumpAndSettle();
      expect(_renewButtons(), findsNWidgets(2));
    });
  });

  group('UspRenewSection — bridge mode still wins', () {
    testWidgets('bridge disables renew even with a readable address',
        (t) async {
      await t.pumpWidget(
          _host(wanDataOverride(), type: UspWanConnectionType.bridge));
      await t.pumpAndSettle();

      expect(_renewButtons(), findsNothing);
    });
  });
}
