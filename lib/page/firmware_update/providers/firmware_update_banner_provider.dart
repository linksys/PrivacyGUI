import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';

/// The firmware version the router is offering to install, or null when there is
/// nothing to offer.
///
/// REQ-C3's conditions, and they are three rather than one on purpose:
///
/// * the ota row says an image is available;
/// * `autoupdate_flags > 0` says the router is still looking — announcing an
///   update to someone who turned checking off would be answering a question they
///   withdrew, and it is reachable, because the ota row outlives the flag change;
/// * the daemon is not already acting on it. A router at `autoupdate_flags = 2`
///   downloads and flashes unattended, and while it does the first two conditions
///   both still hold — so without this arm the dashboard would offer "Update Now"
///   as a second entry into a flash that is already running. `checking` counts as
///   acting: a check in flight is about to replace the reading the offer is made
///   from.
///
/// A version rather than a bool because the *dismissal* is keyed by it — see
/// [firmwareUpdateBannerDismissedVersionProvider]. Loading and error read as no
/// offer. Neither means "no update"; they mean nobody knows yet, and a banner is
/// a claim.
///
/// **`hasError` is checked separately from `valueOrNull`, and has to be.** Both
/// reads come from non-autoDispose `AsyncNotifier`s whose `refresh()` can fail
/// after a success, and riverpod attaches the previous reading to that error — so
/// the failure state here is `hasValue && hasError` with a stale value that
/// `valueOrNull` hands back looking exactly like fresh data. Without these two
/// lines a router that went unreachable an hour ago would keep offering the
/// version it was offering then, with an "Update Now" button that cannot work.
final firmwareUpdateOfferedVersionProvider = Provider<String?>((ref) {
  final asyncAutoUpdate = ref.watch(firmwareAutoUpdateDataProvider);
  if (asyncAutoUpdate.hasError) return null;
  final autoUpdate = asyncAutoUpdate.valueOrNull;
  if (autoUpdate == null || !autoUpdate.checksForUpdates) return null;
  if (autoUpdate.isBusy) return null;

  // `hasOtaOffer`, never `availableBank` and no longer `otaInstance.available`
  // either. The spare NAND bank is also available-and-not-active, so reading the
  // banks would raise this banner on every router with a free slot — and the `ota`
  // row alone would raise it on a router that has just finished installing, because
  // the row keeps the last offer until `fwupd` next checks. Both readings are on
  // the model so this banner and the OTA card cannot disagree; see
  // `FirmwareBanksData.hasOtaOffer` for the recording that found the second one.
  final asyncBanks = ref.watch(firmwareBanksDataProvider);
  if (asyncBanks.hasError) return null;
  final banks = asyncBanks.valueOrNull;
  if (banks == null || !banks.hasOtaOffer) return null;
  // The empty string rather than null for an unnamed offer: this provider's own
  // contract is "the version whose banner to show", and the dismissal key keys on
  // it — `firmwareUpdateBannerDismissedVersionProvider` documents the empty string
  // as the unknown build. Returning null here would read as "no offer".
  return banks.otaOfferedVersion ?? '';
});

/// The version whose banner the user waved away, or null for none.
///
/// In memory and session-scoped by decision (Austin, 2026-09-14): it lives as long
/// as the app is open and comes back on the next launch. Persisting it was the
/// alternative and is worse — the thing being dismissed stays true until someone
/// installs it, so a remembered dismissal would silence the only notice a
/// notify-only router ever gives, indefinitely.
///
/// **A version, not a bool.** A bool records "a banner was waved away", which is
/// not what the user did: they waved away *this* update. With a bool, a user who
/// dismisses 1.0.17 and then reaches 1.0.19 by any route never sees the second
/// notice either, and a tab that logs out of one router and into another carries
/// the first router's dismissal over. Keyed by version both cases answer
/// themselves, and the one case it deliberately keeps silent — two routers
/// offering the same version — is two identical notices about the same build,
/// which is one decision, not two.
///
/// A router that reports an available image with no version string keys on the
/// empty string, so dismissing it silences other version-less offers too. That is
/// the same unknown build as far as anything here can tell.
///
/// Not autoDispose. The dashboard is rebuilt on every tab change and every
/// orchestrator refresh, so a disposing flag would un-dismiss the banner within
/// seconds of the tap.
final firmwareUpdateBannerDismissedVersionProvider =
    StateProvider<String?>((ref) => null);

/// Whether the dashboard shows the "an update is waiting" banner.
final firmwareUpdateBannerVisibleProvider = Provider<bool>((ref) {
  final offered = ref.watch(firmwareUpdateOfferedVersionProvider);
  if (offered == null) return false;
  return ref.watch(firmwareUpdateBannerDismissedVersionProvider) != offered;
});
