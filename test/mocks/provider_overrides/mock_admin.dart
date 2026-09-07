/// Provider overrides for `usp_admin_view`.
///
/// Moved here from `test/golden_test/golden_framework/mocks/` by #1380, the way
/// #1361 moved the DHCP fixture: the layout gate needs it, the golden suite already
/// had it, and two copies of a fixture are two answers to "what does this page
/// render". The golden test now imports this file; [adminOverrides]'s signature is
/// unchanged so that move was two import lines.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_state.dart';

import '../test_data/scenes/admin_scene_data.dart';

class FixedAdminNotifier extends UspAdminNotifier {
  final UspAdminState _fixedState;

  FixedAdminNotifier(this._fixedState);

  @override
  Future<UspAdminState> build() async => _fixedState;

  @override
  Future<void> setAdminPassword(String newPassword) async {}

  @override
  Future<void> updateTimeSettings({
    bool? enable,
    String? ntpServer1,
    String? ntpServer2,
  }) async {}

  @override
  Future<void> updateTimezone({
    required String localTimeZone,
    String? ntpServer1,
  }) async {}

  @override
  Future<void> reboot() async {}

  @override
  Future<void> factoryReset() async {}
}

class FixedSystemInfoDataNotifierForAdmin extends SystemInfoDataNotifier {
  FixedSystemInfoDataNotifierForAdmin(this._fixedData);

  final SystemInfoData _fixedData;

  @override
  Future<SystemInfoData> build() async => _fixedData;
}

List<Override> adminOverrides(UspAdminState state) => [
      uspAdminProvider.overrideWith(() => FixedAdminNotifier(state)),
    ];

/// Overrides for the whole page, which is one provider more than [adminOverrides].
///
/// The fourth card is `FirmwareUpdateCard`, and it watches `systemInfoDataProvider`
/// rather than taking its data from `UspAdminState`. Unoverridden that lands in
/// `AsyncError`, whose `valueOrNull` is null, so the card takes its
/// `activeVersion == null` branch and renders the two-word `notAvailable` where the
/// app renders a version string (`firmware_update_card.dart:50`) — a narrower `Row`
/// than the page has, measured in all 234 cells with nothing failing. Same class of
/// under-measurement `mock_menu.dart` documents for its two badges.
///
/// Kept separate from [adminOverrides] rather than folded into it because the golden
/// suite's four dialog interactions do not need it and pinning a provider they do not
/// read would change what those goldens are of.
List<Override> adminPageOverrides({
  UspAdminState? state,
  SystemInfoData systemInfo = gateAdminSystemInfo,
}) =>
    [
      ...adminOverrides(state ?? testAdminState),
      systemInfoDataProvider
          .overrideWith(() => FixedSystemInfoDataNotifierForAdmin(systemInfo)),
    ];

/// A `systemInfoDataProvider` whose fetch never returns.
///
/// The one state [FixedSystemInfoDataNotifierForAdmin] cannot hold still: an
/// `AsyncNotifier`'s `build` is declared `Future`, so even a fixture that resolves
/// immediately is `AsyncLoading` for exactly one frame and `AsyncData` from the next
/// — long enough for the sweep's collector to measure `FirmwareUpdateCard`'s
/// skeleton and far too short for a guard to read it. A `Completer` that is never
/// completed pins the frame instead of racing it.
class LoadingSystemInfoDataNotifier extends SystemInfoDataNotifier {
  @override
  Future<SystemInfoData> build() => Completer<SystemInfoData>().future;
}

/// [adminPageOverrides] with the firmware card held in its loading state.
///
/// For the readability guard beside the #1380 fix at `firmware_update_card.dart:77`
/// only. The card's skeleton row is the thing being measured, so it has to still be
/// on screen when the pumps settle — which is the opposite of what every other
/// fixture in this directory is for, and the reason this is a second function rather
/// than a flag on the first.
List<Override> adminPageLoadingFirmwareOverrides({UspAdminState? state}) => [
      ...adminOverrides(state ?? testAdminState),
      systemInfoDataProvider
          .overrideWith(() => LoadingSystemInfoDataNotifier()),
    ];
