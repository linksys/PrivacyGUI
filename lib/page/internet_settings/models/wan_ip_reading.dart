import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';

/// The WAN address as a *reading*, with "we could not read it" kept distinct from
/// "there is no address" — linksys/PrivacyGUI#1613.
///
/// WHY THIS TYPE EXISTS. `wanDataProvider.valueOrNull?.model.ipAddress` is `null` for
/// three different reasons, and every consumer that flattened it with `?? ''` then had to
/// decide what that meant. Two consumers on the same page decided differently, and one of
/// them decided wrongly: the status banner read the empty string as "disconnected" and
/// rendered an affirmative offline indicator for an `AsyncError` — a state reachable on an
/// ordinary path, because `uspWanDataServiceProvider` throws `ServiceNotInitializedError`
/// whenever `uspClientProvider` is null (session not yet established, re-auth, dropped
/// socket), and `wanDataProvider` is not autoDispose and has no retry, so the false
/// reading persisted until something else invalidated it.
///
/// Flattening early is what made that possible. Three device states collapsed into two
/// UI states one line after the read, and after that no consumer could tell them apart.
///
/// (That banner's indicator no longer reads the address at all — see the note below — but
/// the collapse it suffered from is why this type is shaped the way it is.)
///
/// The three cases, and what each means to a user:
///
///   [WanIpReading.address]  the device reported an address     -> show it
///   [WanIpReading.none]     the device reported no address     -> show '--'
///   [WanIpReading.unknown]  we could not read the device       -> say so; claim nothing
///
/// ⚠️ THIS TYPE NO LONGER ANSWERS "ARE WE ONLINE" (#1620). It used to carry `isOnline`
/// and `isOffline`, which made "has an address" a second definition of online competing
/// with `wanIsUpProvider`'s `Status == 'Up'` — and measured on real hardware the two
/// disagree for about 5 seconds after every link recovery. Those getters are gone; the
/// app's one definition is [wanIsUpProvider]. What stays here is the address, which
/// genuinely does have three states worth keeping apart.
sealed class WanIpReading {
  const WanIpReading();

  /// L1 reported an address.
  const factory WanIpReading.address(String value) = WanIpAddress;

  /// L1 reported that there is no address — the link is down or has not got one yet.
  const factory WanIpReading.none() = WanIpNone;

  /// L1 could not be read: first load, or a fetch error.
  const factory WanIpReading.unknown() = WanIpUnknown;

  /// The address, or `null` when there is not one to show.
  ///
  /// Both `none` and `unknown` return `null`, so this is only for a caller that has
  /// already decided those two are the same for its purpose. A caller deciding
  /// online/offline must switch on the variants instead — that conflation is the defect
  /// this type was introduced to prevent.
  String? get addressOrNull => switch (this) {
        WanIpAddress(:final value) => value,
        WanIpNone() => null,
        WanIpUnknown() => null,
      };
}

final class WanIpAddress extends WanIpReading {
  const WanIpAddress(this.value);
  final String value;
}

final class WanIpNone extends WanIpReading {
  const WanIpNone();
}

final class WanIpUnknown extends WanIpReading {
  const WanIpUnknown();
}

/// The WAN address reading for the Internet Settings page's read-only views.
///
/// `hasValue` is the discriminator rather than `!hasError`, and that is measured rather
/// than assumed: during a refresh riverpod carries the previous value forward, so an
/// external `ref.invalidate(wanDataProvider)` — which the save and DHCP-renew paths both
/// issue — yields `isLoading: true, hasValue: true` still holding the old address.
/// `hasValue` therefore covers "settled" and "refreshing with a value" and excludes only
/// the two states where nothing has been read. Pinned by
/// `wan_ip_reading_test.dart`, so a riverpod upgrade that changed retention
/// would fail a test rather than silently start blanking the address mid-renew.
final wanIpReadingProvider = Provider<WanIpReading>((ref) {
  final async = ref.watch(wanDataProvider);
  if (!async.hasValue) return const WanIpReading.unknown();
  final ip = async.requireValue.model.ipAddress;
  return ip.isEmpty ? const WanIpReading.none() : WanIpReading.address(ip);
});
