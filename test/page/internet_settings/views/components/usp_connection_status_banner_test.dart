import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/preservable.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/page/_shared/components/usp_status_dot.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_feature_state.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_settings.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_status.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';
import 'package:privacy_gui/page/internet_settings/views/components/usp_connection_status_banner.dart';
import 'package:ui_kit_library/ui_kit.dart';

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

const _wanUp = WanStatusUIModel(
  isUp: true,
  ipAddress: '100.64.0.10',
  subnetMask: '255.255.255.0',
  addressingType: 'DHCP',
  mtu: 1500,
);

const _wanNoAddress = WanStatusUIModel(
  isUp: false,
  ipAddress: '',
  subnetMask: '',
  addressingType: '',
  mtu: 1500,
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

class _DataWan extends WanDataNotifier {
  _DataWan(this._model);
  final WanStatusUIModel _model;
  @override
  Future<WanData> build() async => WanData(model: _model);
}

class _ErrorWan extends WanDataNotifier {
  @override
  Future<WanData> build() async => throw const ServiceNotInitializedError(
      detail: 'USP service not available');
}

/// Never completes — the first-load state, before any value exists.
class _LoadingWan extends WanDataNotifier {
  @override
  Future<WanData> build() => Completer<WanData>().future;
}

Widget _host(WanDataNotifier Function() notifier) {
  return ProviderScope(
    overrides: [wanDataProvider.overrideWith(notifier)],
    child: MaterialApp(
      theme: _testTheme,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: UspConnectionStatusBanner(
          state: _state(),
          isEditing: false,
        ),
      ),
    ),
  );
}

void main() {
  group('UspConnectionStatusBanner — where the address comes from', () {
    testWidgets("renders L1's address, not the L2 snapshot's", (t) async {
      await t.pumpWidget(_host(() => _DataWan(_wanUp)));
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

    testWidgets('an L1 value of "no address" reads as offline, showing --',
        (t) async {
      await t.pumpWidget(_host(() => _DataWan(_wanNoAddress)));
      await t.pumpAndSettle();

      expect(find.text('--'), findsOneWidget);
      final dot = t.widget<UspStatusDot>(find.byType(UspStatusDot));
      expect(dot.isActive, isFalse,
          reason:
              'L1 said there is no address — offline is the correct reading here');
    });
  });

  group('UspConnectionStatusBanner — unknown is not offline (#1613 review C1)',
      () {
    testWidgets(
        'an L1 fetch ERROR is not rendered as a valid "no address" reading',
        (t) async {
      await t.pumpWidget(_host(() => _ErrorWan()));
      await t.pumpAndSettle();

      // The defect this pins: '--' is exactly what a real empty address looks like, so
      // showing it for a failed read made the two indistinguishable — and because this
      // provider is not autoDispose and has no retry, it stayed wrong until something
      // else happened to invalidate it.
      expect(find.text('--'), findsNothing,
          reason:
              'a failed read must not be displayed as a successful read of ""');
      expect(find.text('100.64.0.10'), findsNothing);
      expect(find.text(_absentAddress), findsNothing);
    });

    testWidgets('the first load, before any value, is also not offline',
        (t) async {
      await t.pumpWidget(_host(() => _LoadingWan()));
      await t.pump();

      expect(find.text('--'), findsNothing,
          reason:
              'nothing has been read yet; claiming "no address" would invent a reading');
    });

    testWidgets('the edit toggle survives both unknown states', (t) async {
      // THE REGRESSION THIS BLOCKS IS CROSS-REPO. `internet-settings-edit-toggle` is the
      // arrival hook `R01-boot-smoke` asserts the page by, and the readiness hook
      // `R20-sse-push` waits on. An earlier version of the C1 fix returned a
      // `CardSkeleton` for `!hasValue`, which takes this control off the page — and in
      // the AsyncError case takes it off permanently, since there is no retry. Both real
      // specs would have gone red over a change whose entire subject is a text field.
      for (final (label, notifier) in <(String, WanDataNotifier Function())>[
        ('AsyncError', () => _ErrorWan()),
        ('AsyncLoading', () => _LoadingWan()),
      ]) {
        await t.pumpWidget(_host(notifier));
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
