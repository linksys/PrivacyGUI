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
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';

import '../test_data/scenes/admin_scene_data.dart';
import 'mock_firmware_update.dart';

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
    String? zoneName,
    String? localTimeZone,
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
/// The card that needs it is `FirmwareOtaCard`, and it watches
/// `systemInfoDataProvider` rather than taking its data from `UspAdminState`.
/// Unoverridden that lands in `AsyncError`, whose `valueOrNull` is null, so the card
/// takes its `activeVersion == null` branch and renders the two-word `notAvailable`
/// where the app renders a version string (`firmware_ota_card.dart:60`) — a narrower
/// `Row` than the page has, measured in all 234 cells with nothing failing. Same
/// class of under-measurement `mock_menu.dart` documents for its two badges.
///
/// It was `FirmwareUpdateCard` that read this provider until #1549 split the entry
/// point in two and gave "current version" one owner. The manual card is a
/// `StatelessWidget` now and reads nothing, so this override is what the OTA card
/// needs and the manual card no longer cares about — which is also why the page has
/// four cards in RA and five in local, and why `requires:` on the layout-gate case
/// names both.
///
/// Kept separate from [adminOverrides] rather than folded into it because the golden
/// suite's four dialog *interactions* do not need it and pinning a provider they do not
/// read would change what those goldens are of. That reason covers exactly those four:
/// the golden suite's full-page `data` state renders the card and therefore calls this
/// function, not [adminOverrides] — it did not, until #1552's review found that every
/// admin golden in all 26 locales was rendering the page without the switch row.
///
/// #1552 added the second one, `firmwareAutoUpdateDataProvider`, for the same reason
/// as the first and with a sharper failure: the OTA card's switch row *hides itself*
/// on `AsyncError`, so an unoverridden provider would delete the row from all 234
/// cells and the sweep would report a clean page it never measured.
/// [autoUpdateNotifier] is an escape hatch for the two states a fixed reading
/// cannot express — a fetch that failed and one that has not answered — which are
/// exactly the two the switch row treats specially (it hides on the first and locks
/// on the second). Taking a factory rather than adding a second `AsyncValue`-shaped
/// parameter keeps the common call site a model, and keeps the *test* from having to
/// append a duplicate override for a provider this list already pins: riverpod's
/// last-writer-wins on duplicates is real but undocumented, and #1512 is a pending
/// riverpod 3 upgrade.
///
/// The third, `firmwareBanksDataProvider`, arrived with the card's offer line
/// (2026-09-15) and repeats the pattern a third time: the line is *absent* unless
/// the router reports an `ota` row offering an image, so an unoverridden provider —
/// which reaches a real `UspClient` and errors — would delete two localized strings
/// from all 234 cells while the sweep reported a clean page. It defaults to
/// [gateFirmwareBanksWithOta], the *wider* of the two shapes, for the same reason
/// [gateFirmwareNoUpdateFoundState] picks the wider verdict; pass
/// [gateFirmwareBanks] for the no-offer rendering, or [banksNotifier] for the
/// reading that failed after answering once — the state a fixed value cannot hold,
/// and the one the offer line treats specially.
List<Override> adminPageOverrides({
  UspAdminState? state,
  SystemInfoData systemInfo = gateAdminSystemInfo,
  FirmwareAutoUpdateUIModel autoUpdate = gateFirmwareAutoUpdateOn,
  FirmwareAutoUpdateDataNotifier Function()? autoUpdateNotifier,
  FirmwareBanksData banks = gateFirmwareBanksWithOta,
  FirmwareBanksDataNotifier Function()? banksNotifier,
}) =>
    [
      ...adminOverrides(state ?? testAdminState),
      systemInfoDataProvider
          .overrideWith(() => FixedSystemInfoDataNotifierForAdmin(systemInfo)),
      firmwareAutoUpdateDataProvider.overrideWith(autoUpdateNotifier ??
          () => FixedFirmwareAutoUpdateNotifier(autoUpdate)),
      firmwareBanksDataProvider.overrideWith(
          banksNotifier ?? () => FixedFirmwareBanksDataNotifier(banks)),
    ];

/// A `systemInfoDataProvider` whose fetch never returns.
///
/// The one state [FixedSystemInfoDataNotifierForAdmin] cannot hold still: an
/// `AsyncNotifier`'s `build` is declared `Future`, so even a fixture that resolves
/// immediately is `AsyncLoading` for exactly one frame and `AsyncData` from the next
/// — long enough for the sweep's collector to measure `FirmwareOtaCard`'s
/// skeleton and far too short for a guard to read it. A `Completer` that is never
/// completed pins the frame instead of racing it.
class LoadingSystemInfoDataNotifier extends SystemInfoDataNotifier {
  @override
  Future<SystemInfoData> build() => Completer<SystemInfoData>().future;
}

/// [adminPageOverrides] with the firmware card held in its loading state.
///
/// For the readability guard beside the #1380 fix at `firmware_ota_card.dart:79`
/// only — the `if (!isLoading)` that keeps the check button out of the skeleton's
/// row. The card's skeleton row is the thing being measured, so it has to still be
/// on screen when the pumps settle — which is the opposite of what every other
/// fixture in this directory is for, and the reason this is a second function rather
/// than a flag on the first.
///
/// The skeleton moved from the manual card to the OTA card in #1549, along with the
/// version block it stands in for. The fix it guards moved with it unchanged, so the
/// guard's coordinates are the only thing this rename touches.
/// The auto-update provider is pinned here too, and to a *loaded* reading: the two
/// are independent reads, so a router whose `FirmwareImage` fetch is slow still has an
/// answered `autoupdate_flags`. Pinning it also keeps the switch row on screen, which
/// is what the app renders beside that skeleton.
///
/// The banks provider is pinned to [gateFirmwareBanks] — the shape with **no** `ota`
/// row — and that is the one departure from "same reading, independent read". The
/// offer line sits below the skeleton in the same column, so it takes no width from
/// the caption being measured; what it would take is the guard's subject. Leaving the
/// no-offer shape here keeps this fixture about the one row it exists for, and pays
/// for it with a gap named rather than discovered: "loading a version while an update
/// is offered" is measured nowhere. A pin of some kind is not optional, though —
/// unoverridden, this provider reaches a real `UspClient` from every skeleton cell.
List<Override> adminPageLoadingFirmwareOverrides({UspAdminState? state}) => [
      ...adminOverrides(state ?? testAdminState),
      systemInfoDataProvider
          .overrideWith(() => LoadingSystemInfoDataNotifier()),
      firmwareAutoUpdateDataProvider.overrideWith(
          () => FixedFirmwareAutoUpdateNotifier(gateFirmwareAutoUpdateOn)),
      firmwareBanksDataProvider.overrideWith(
          () => FixedFirmwareBanksDataNotifier(gateFirmwareBanks)),
    ];
