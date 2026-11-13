import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_flow_plan.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_state.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_band.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_wifi_settings.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_providers.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_setting_steps.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_wifi_drafts.dart';

import '../../../mocks/provider_overrides/mock_pnp.dart';

/// The setting steps' drafts and the flow-level guard over them (#1511 P4).
///
/// `PnpWifiConfig` used to be one object on the flow's phase, with nine
/// hand-written dirty getters and no revert. It is now one `Preservable` draft
/// per step, and the guard on `/pnp/pnpConfig` is those drafts taken together.
void main() {
  const main = PnpMainWifiSettings(
    ssid: 'Home',
    password: 'home-pass',
    ssidInstancePaths: ['Device.WiFi.SSID.1.'],
    accessPointInstancePaths: ['Device.WiFi.AccessPoint.1.'],
  );
  const guest = PnpGuestWifiSettings(
    enabled: false,
    ssid: 'Home-guest',
    password: 'guest-pass',
    ssidInstancePaths: ['Device.WiFi.SSID.3.'],
    accessPointInstancePaths: ['Device.WiFi.AccessPoint.3.'],
  );

  /// A flow on the steps of [state]'s plan, read from [router]: the drafts held
  /// and begun the way `PnpNotifier` does when it enters the steps.
  ProviderContainer flowAt(
    PnpState state, [
    PnpWizardData router = const PnpWizardData(main: main, guest: guest),
  ]) {
    final container = ProviderContainer(overrides: pnpOverrides(state));
    addTearDown(container.dispose);
    container.listen(pnpProvider, (_, __) {});
    for (final id in state.plan!.settingStepIds) {
      final draft = pnpSettingStep(id).draft;
      container.listen(draft, (_, __) {});
      container.read(draft).begin(router);
    }
    return container;
  }

  const withGuest = PnpState(
    phase: WizardConfiguring(),
    plan: PnpFlowPlan(settingStepIds: ['wifi', 'guest']),
  );

  test('a draft begins at what the wizard read, and is not dirty', () {
    final c = flowAt(withGuest);

    expect(c.read(pnpMainWifiDraftProvider).current, main);
    expect(c.read(pnpGuestWifiDraftProvider).current, guest);
    expect(c.read(pnpWizardDraftsProvider).isDirty(), isFalse);
  });

  test('an edit to either step makes the wizard dirty', () {
    final c = flowAt(withGuest);

    c.read(pnpGuestWifiDraftProvider.notifier).setEnabled(true);

    expect(c.read(pnpGuestWifiDraftProvider.notifier).isDirty(), isTrue);
    expect(c.read(pnpMainWifiDraftProvider.notifier).isDirty(), isFalse);
    expect(c.read(pnpWizardDraftsProvider).isDirty(), isTrue);
  });

  test('revert restores what every step had before the edits', () {
    final c = flowAt(withGuest);
    c.read(pnpMainWifiDraftProvider.notifier)
      ..setSsid('Renamed')
      ..setPassword('new-pass-123');
    c.read(pnpGuestWifiDraftProvider.notifier).setPassword('guest-new-1');

    c.read(pnpWizardDraftsProvider).revert();

    expect(c.read(pnpMainWifiDraftProvider).current, main);
    expect(c.read(pnpGuestWifiDraftProvider).current, guest);
    expect(c.read(pnpWizardDraftsProvider).isDirty(), isFalse);
  });

  test('a split band is edited by its SSID path, and only that band', () {
    PnpWifiBand band(int n, String ssid) => PnpWifiBand(
          bandName: '$n',
          frequency: '$n',
          ssid: ssid,
          password: 'pass-$n',
          ssidInstancePath: 'Device.WiFi.SSID.$n.',
          accessPointInstancePath: 'Device.WiFi.AccessPoint.$n.',
          radioPath: 'Device.WiFi.Radio.$n.',
        );
    final split = PnpMainWifiSettings(
      ssid: 'A',
      password: 'pass-1',
      bands: [band(1, 'A'), band(2, 'B')],
      splitMode: true,
    );
    final c = flowAt(
      withGuest.copyWith(plan: const PnpFlowPlan(settingStepIds: ['wifi'])),
      PnpWizardData(main: split),
    );

    c
        .read(pnpMainWifiDraftProvider.notifier)
        .setBandSsid('Device.WiFi.SSID.2.', 'B-renamed');

    expect(c.read(pnpMainWifiDraftProvider).current.bands.map((b) => b.ssid),
        ['A', 'B-renamed']);
    expect(c.read(pnpWizardDraftsProvider).isDirty(), isTrue);
  });

  test('a step the plan left out is not part of the guard', () {
    // No guest SSID on this router, so no guest step: its draft is never
    // built, and nothing in it can make the wizard ask before leaving.
    final c = flowAt(
      const PnpState(
        phase: WizardConfiguring(),
        plan: PnpFlowPlan(settingStepIds: ['wifi']),
      ),
      const PnpWizardData(main: main),
    );

    expect(c.read(pnpWizardDraftsProvider).drafts, hasLength(1));
  });

  test('a draft nobody began is empty and clean', () {
    // What the guard reads before the wizard has a plan.
    final c = ProviderContainer(
        overrides: pnpOverrides(const PnpState(phase: WizardInitializing())));
    addTearDown(c.dispose);

    expect(c.read(pnpWizardDraftsProvider).drafts, isEmpty);
    expect(c.read(pnpWizardDraftsProvider).isDirty(), isFalse);
  });
}
