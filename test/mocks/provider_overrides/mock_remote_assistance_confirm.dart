/// Provider overrides for `remote_assistance_confirm_view` (#1380, wave 4).
///
/// Named for the view rather than the feature because
/// `test/golden_test/golden_framework/mocks/mock_remote_assistance.dart` already
/// exists and overrides a *different* provider (`remoteClientProvider`, for the
/// banner and the dialog). Two files one directory apart with the same basename is
/// the hazard `_scene_data` vs `_test_data` was renamed to avoid: autocomplete
/// offers both, and the wrong one compiles and renders a page whose provider
/// overrides do not match it.
///
/// The one page in the wave whose fixture is a **service** rather than a notifier
/// state, because the view holds its own state in `setState` and the only thing that
/// moves it is one awaited call:
///
/// ```dart
/// final service = ref.read(remoteAssistanceServiceProvider);
/// final sessionInfo = await service.fetchSessionInfoForCA(...);
/// ```
///
/// Unoverridden that reaches `GuardianApiClient`, throws, and the view lands in its
/// `catch` with `'An unexpected error occurred.'` and a null `_sessionInfo` — so the
/// page renders one error box and **no** session status card. That card is the whole
/// layout story on this page (an 80px router image beside an `Expanded` column of
/// model, serial, status badge and countdown), so an unoverridden cell measures the
/// narrow half of the page and reports it green.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart' show Fake;
import 'package:privacy_gui/core/cloud/model/guardians_remote_assistance.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/device_credentials_provider.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/remote_client_provider.dart'
    show DeviceCredentials;
import 'package:privacy_gui/core/cloud/services/remote_assistance_service.dart';

/// A [RemoteAssistanceService] that answers exactly one method.
///
/// `extends Fake implements` rather than a subclass: the real constructor takes a
/// `GuardianApiClient`, which would mean building an HTTP client for a fixture that
/// never makes a request. Every other member throws [UnimplementedError] by
/// construction, which is the property that matters — if this page ever starts
/// calling a second service method, the cell fails loudly instead of measuring a
/// silently emptier page.
class FixedRemoteAssistanceService extends Fake
    implements RemoteAssistanceService {
  FixedRemoteAssistanceService(this._sessionInfo);

  final GRASessionInfo _sessionInfo;

  @override
  Future<GRASessionInfo> fetchSessionInfoForCA({
    required String sessionToken,
    required String sessionId,
  }) async =>
      _sessionInfo;
}

/// Overrides for `remote_assistance_confirm_view`.
///
/// One override, and the case that names it also owns which session it describes —
/// see [gateSessionPendingInfo] for why the wave pins `pending` rather than `active`.
List<Override> remoteAssistanceConfirmOverrides({
  required GRASessionInfo sessionInfo,
}) =>
    [
      remoteAssistanceServiceProvider
          .overrideWithValue(FixedRemoteAssistanceService(sessionInfo)),
    ];

/// Credentials for the pages that only need the remote-assistance entry point to be
/// *live*, which today is `usp_support_view`.
///
/// [deviceCredentialsProvider] is a plain `Provider` that composes `sessionProvider`
/// and `devicesDataProvider`, and its consumer on the support page reads it for one
/// thing: whether the remote-assistance row gets an `onTap`. The row's tree is
/// identical either way, so this override does not change what is measured — which
/// is exactly why it is worth writing down that it is here for two other reasons.
///
/// 1. **Cost.** Unoverridden, both of those providers reach a USP service and land in
///    `AsyncError`, and `valueOrNull` turns that into a silent null. §11.11's rule is
///    that an error path costs a throw, a stack capture and a log line *per cell* —
///    the reason `usp_menu_view` read 40.1ms/cell without a fixture and 23.0 with one.
/// 2. **Honesty about the state.** A null here is the state of a session that has not
///    bootstrapped; a support page a user actually reaches has credentials. Pinning
///    the null would be pinning the transient.
List<Override> deviceCredentialsOverrides() => [
      deviceCredentialsProvider.overrideWithValue(gateDeviceCredentials),
    ];

/// The credentials [deviceCredentialsOverrides] installs.
///
/// A real-shaped serial and MAC rather than placeholders, for the reason
/// [gateSessionPendingInfo] gives about its own strings: nothing on the support page
/// renders these today, but the next page that needs this override may render them,
/// and a fixture that has to be widened later is a fixture whose earlier verdicts
/// were narrower than they looked.
const gateDeviceCredentials = DeviceCredentials(
  serialNumber: '24J10K56789012',
  macAddress: 'AA:BB:CC:DD:EE:FF',
  deviceUUID: '8f14e45f-ceea-467a-9f0e-8b1c2d3e4f50',
);

/// A session the view will render its status card for, and **not** start a timer on.
///
/// `pending` is a deliberate choice over `active`, and the reason is a test-harness
/// one stated here rather than left as a gap:
///
/// - On `active`, `_validateToken` reaches `_startCountdown()`, a `Timer.periodic`
///   that lives until `dispose()`. A sweep pumps 26 locales inside one `testWidgets`
///   and never disposes the last of them, so the final cell would end with a pending
///   timer and the test would fail on the binding's own check rather than on a
///   layout verdict.
/// - On `pending`, the view returns *before* `_startCountdown()` while still
///   assigning `_sessionInfo`, so `_buildSessionStatusCard` renders — which is the
///   part of this page with a `Row`, an intrinsic-width image and a badge in it.
///
/// What that leaves unmeasured is the `_canConnect` block: a full-width `AppButton`
/// and a centred "Session validated" row, both of which need `active`. Recorded as a
/// gap in `page_surface_cases.dart` rather than papered over — it is two rows of
/// centred content in a `colWidth(4)` box, the narrowest thing on the page.
///
/// The strings are long on purpose. A model number and a serial sit side by side in
/// the card's `Expanded` column, and a fixture with `'X'` in both fields would
/// measure a card that cannot overflow in any locale.
const gateSessionPendingInfo = GRASessionInfo(
  id: 'gate-session-0001',
  serialNumber: '24J10K56789012',
  modelNumber: 'MX6200-EU-Gate',
  status: GRASessionStatus.pending,
  expiredIn: 1800,
  createdAt: 0,
  statusChangedAt: 0,
  currentTime: 0,
);
