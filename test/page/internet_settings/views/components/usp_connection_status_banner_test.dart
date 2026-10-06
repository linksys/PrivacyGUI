import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_connection_status_banner.dart';
import 'package:ui_kit_library/ui_kit.dart';

import '../../../../mocks/provider_overrides/mock_wan_data.dart';

/// Widget tests for the banner's WAN-address reading — #1587 Phase 2, plus the review
/// remediation on PR #1613.
///
/// WHY THESE EXIST. The Phase 2 change swapped the address source from the page's L2
/// snapshot to L1 `wanDataProvider` and shipped with no test, so reverting the line would
/// have failed nothing. And the first version of it read `valueOrNull?...ipAddress ?? ''`,
/// which made an L1 **fetch error** render exactly like a successful read of "no address"
/// — a confident, sticky, false "offline", on a provider with no retry.
///
/// The cases below keep apart the three states `valueOrNull` collapses into one.

final _testTheme = AppTheme.create(
  brightness: Brightness.light,
  seedColor: Colors.blue,
  designThemeBuilder: (c) => CustomDesignTheme.fromJson({'style': 'flat'}),
);

/// The address this banner used to read — `readOnlyInfo.staticIpAddress` — no longer
/// exists: it was deleted once nothing read it (#1613 review). So the "did it really stop
/// reading L2?" assertion can no longer be written as "L2 holds a different address and it
/// must not appear"; the compiler now enforces it outright, which is stronger.
///
/// This value is kept as a NEGATIVE control anyway: it is an address that appears nowhere
/// in this test's providers, so if it ever shows up on screen something is fabricating a
/// reading.
const _absentAddress = '10.9.9.9';

InternetSettingsFeatureState _state() {
  const form =
      UspInternetSettingsForm(connectionType: UspWanConnectionType.dhcp);
  return InternetSettingsFeatureState(
    settings: Preservable(
      original: const InternetSettingsSettings(form: form),
      current: const InternetSettingsSettings(form: form),
    ),
    status: const InternetSettingsStatus(
      isLoading: false,
      isEditing: false,
      readOnlyInfo: InternetSettingsReadOnlyInfo(),
    ),
  );
}

Widget _host(Override wanOverride) {
  return ProviderScope(
    overrides: [wanOverride],
    child: MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: UspConnectionStatusBanner(
          state: _state(),
          isEditing: false,
          // The local page's shape: `LocalSurface.internetSettingsEditor` always
          // hands the banner a callback. Since #1626 a `null` here is the remote
          // surface's "read only", which draws no toggle at all — so omitting it
          // would make 'the edit toggle survives both unknown states' fail for a
          // reason that has nothing to do with the reading it is about.
          onEditToggle: () {},
        ),
      ),
    ),
  );
}

void main() {
  group('UspConnectionStatusBanner — where the address comes from', () {
    testWidgets("renders L1's address, not the L2 snapshot's", (t) async {
      await t.pumpWidget(_host(wanDataOverride()));
      // NOT pumpAndSettle: an active `UspStatusDot` animates with
      // `BreathDotAnimation.pulse`, which never settles, so pumpAndSettle times out.
      // Two pumps are enough — one to run build(), one for the provider's future.
      await t.pump();
      await t.pump();

      expect(find.text('100.64.0.10'), findsOneWidget,
          reason: 'the address must come from wanDataProvider (#1587 Phase 2)');
      expect(find.text(_absentAddress), findsNothing,
          reason: 'no address that is not in a provider may appear on screen');
    });

    testWidgets('a link that is down shows -- and a dim dot', (t) async {
      await t.pumpWidget(_host(wanDataOverride(wanNoAddressModel)));
      await t.pumpAndSettle();

      expect(find.text('--'), findsOneWidget);
      final dot = t.widget<UspStatusDot>(find.byType(UspStatusDot));
      // `wanNoAddressModel` is `isUp: false` AND has no address, so both the old
      // address-based reading and the current `isUp` one give a dim dot. The test below
      // is the one that can tell them apart.
      expect(dot.isActive, isFalse);
    });

    testWidgets('link up with no address yet: dot ON, address --', (t) async {
      // THE 5-SECOND WINDOW (#1620). Measured on real hardware: after `ifup`, `Status`
      // reads `Up` for about 5 seconds before an address arrives. This banner used to
      // infer online from the address, so it showed a dim dot here while the dashboard
      // showed Online — the same router, one click apart.
      //
      // The dot and the address line now answer different questions, and this is the only
      // state where that difference is visible.
      await t.pumpWidget(_host(wanDataOverride(wanUpNoAddressModel)));
      await t.pump();
      await t.pump();

      final dot = t.widget<UspStatusDot>(find.byType(UspStatusDot));
      expect(dot.isActive, isTrue,
          reason:
              'the link is up; an address still arriving is not a disconnection');
      expect(find.text('--'), findsOneWidget,
          reason:
              'and the address line still says honestly that there is none yet');
    });
  });

  group('UspConnectionStatusBanner — unknown is not offline (#1613 review C1)',
      () {
    testWidgets(
        'an L1 fetch ERROR is not rendered as a valid "no address" reading',
        (t) async {
      await t.pumpWidget(_host(wanDataErrorOverride()));
      // NOT pumpAndSettle: since #1620 the dot defaults to ON for an unread L1, and an
      // active dot pulses forever — pumpAndSettle times out on it. Same reason as the
      // first test in this file.
      await t.pump();
      await t.pump();

      // The defect this pins: '--' is exactly what a real empty address looks like, so
      // showing it for a failed read made the two indistinguishable — and because this
      // provider is not autoDispose and has no retry, it stayed wrong until something
      // else happened to invalidate it.
      expect(find.text('--'), findsNothing,
          reason:
              'a failed read must not be displayed as a successful read of ""');
      expect(find.text('100.64.0.10'), findsNothing);
      expect(find.text(_absentAddress), findsNothing);

      // AND THE DOT IS ON, which is #1620's choice and not an oversight. An unread L1 is
      // not a disconnection, so the dashboard and this screen both stay optimistic; the
      // address line is what says "unknown", in words. Asserting it here means a future
      // change back to a dim dot has to come past this test.
      final dot = t.widget<UspStatusDot>(find.byType(UspStatusDot));
      expect(dot.isActive, isTrue,
          reason:
              'unread is not offline — the same default the dashboard uses (#1143)');
    });

    testWidgets('the first load, before any value, is also not offline',
        (t) async {
      await t.pumpWidget(_host(wanDataLoadingOverride()));
      await t.pump();

      expect(find.text('--'), findsNothing,
          reason:
              'nothing has been read yet; claiming "no address" would invent a reading');
      final dot = t.widget<UspStatusDot>(find.byType(UspStatusDot));
      expect(dot.isActive, isTrue,
          reason:
              'and the dot stays on — launching is not disconnecting (#1143/#1620)');
    });

    testWidgets('the edit toggle survives both unknown states', (t) async {
      // THE REGRESSION THIS BLOCKS IS CROSS-REPO. `internet-settings-edit-toggle` is the
      // arrival hook `R01-boot-smoke` asserts the page by, and the readiness hook
      // `R20-sse-push` waits on. An earlier version of the C1 fix returned a
      // `CardSkeleton` for `!hasValue`, which takes this control off the page — and in
      // the AsyncError case takes it off permanently, since there is no retry. Both real
      // specs would have gone red over a change whose entire subject is a text field.
      for (final (label, override) in <(String, Override)>[
        ('AsyncError', wanDataErrorOverride()),
        ('AsyncLoading', wanDataLoadingOverride()),
      ]) {
        await t.pumpWidget(_host(override));
        await t.pump();
        expect(
          find.byWidgetPredicate((w) =>
              w is AppIconButton &&
              w.identifier == 'internet-settings-edit-toggle'),
          findsOneWidget,
          reason: '$label must keep the edit toggle on the page',
        );
      }
    });
  });
}
