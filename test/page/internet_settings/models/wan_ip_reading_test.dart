import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/_shared/models/wan_status_ui_model.dart';
import 'package:privacy_gui/page/internet_settings/models/wan_ip_reading.dart';
import 'package:privacy_gui/page/internet_settings/providers/wan_data_provider.dart';

/// The three-state WAN address reading — linksys/PrivacyGUI#1613.
///
/// These tests exist because the previous shape (`valueOrNull?...ipAddress ?? ''`) was not
/// wrong in an obvious way: it was wrong in a way that rendered a confident, sticky,
/// FALSE reading for one of the three states it collapsed. The provider below keeps them
/// apart, and the case that matters most is the one no other test covered: a refresh
/// in flight, which must keep reporting the last known address rather than "unknown".

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

class _FixedWan extends WanDataNotifier {
  _FixedWan(this._model);
  final WanStatusUIModel _model;
  @override
  Future<WanData> build() async => WanData(model: _model);
}

class _ErrorWan extends WanDataNotifier {
  @override
  Future<WanData> build() async => throw const ServiceNotInitializedError(
      detail: 'USP service not available');
}

/// Completes only when told to — lets a refresh be observed mid-flight.
class _SlowWan extends WanDataNotifier {
  static var builds = 0;
  @override
  Future<WanData> build() async {
    final n = ++builds;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    return WanData(
      model: WanStatusUIModel(
        isUp: true,
        ipAddress: '100.64.0.$n',
        subnetMask: '255.255.255.0',
        addressingType: 'DHCP',
        mtu: 1500,
      ),
    );
  }
}

ProviderContainer _container(WanDataNotifier Function() notifier) =>
    ProviderContainer(overrides: [wanDataProvider.overrideWith(notifier)]);

void main() {
  group('wanIpReadingProvider', () {
    test('an address the device reported is online', () async {
      final c = _container(() => _FixedWan(_wanUp));
      addTearDown(c.dispose);
      await c.read(wanDataProvider.future);

      final r = c.read(wanIpReadingProvider);
      expect(r, isA<WanIpAddress>());
      expect(r.addressOrNull, '100.64.0.10');
      expect(r.isOnline, isTrue);
      expect(r.isOffline, isFalse);
    });

    test('an empty address the device reported is offline, not unknown',
        () async {
      final c = _container(() => _FixedWan(_wanNoAddress));
      addTearDown(c.dispose);
      await c.read(wanDataProvider.future);

      final r = c.read(wanIpReadingProvider);
      expect(r, isA<WanIpNone>());
      expect(r.addressOrNull, isNull);
      expect(r.isOffline, isTrue,
          reason: 'the device answered; "no address" is a real reading');
      expect(r.isOnline, isFalse);
    });

    test('a fetch error is unknown, and is NOT offline', () async {
      final c = _container(() => _ErrorWan());
      addTearDown(c.dispose);
      try {
        await c.read(wanDataProvider.future);
      } catch (_) {
        // Expected — the point is what the reading says afterwards.
      }

      final r = c.read(wanIpReadingProvider);
      expect(r, isA<WanIpUnknown>());
      // Both halves matter. `isOnline` false alone was the old behaviour; what was wrong
      // was that the same state also read as offline, so a caller inverting one flag
      // produced a false claim either way.
      expect(r.isOnline, isFalse);
      expect(r.isOffline, isFalse,
          reason:
              'we could not read the device — claiming it is disconnected invents a fact');
    });

    test('the first load, before any value, is unknown', () {
      final c = _container(() => _ErrorWan());
      addTearDown(c.dispose);
      // Read without awaiting: build() has not completed.
      expect(c.read(wanIpReadingProvider), isA<WanIpUnknown>());
    });

    // ---------------------------------------------------------------------------
    // The load-bearing riverpod behaviour, pinned rather than asserted in prose.
    //
    // `hasValue` is the discriminator instead of `!hasError` because riverpod carries the
    // previous value through a refresh. If that ever stopped being true — a riverpod
    // upgrade, and `pubspec.yaml` pins a caret range — the address would blank to
    // "unknown" in the middle of every save and DHCP renew, which both issue an external
    // `ref.invalidate(wanDataProvider)`. That is a user-visible regression with no
    // compile error, so it gets a test.
    // ---------------------------------------------------------------------------
    test('a refresh in flight keeps reporting the last known address',
        () async {
      _SlowWan.builds = 0;
      final c = _container(() => _SlowWan());
      addTearDown(c.dispose);
      // A standing subscription, so the invalidate below rebuilds eagerly.
      c.listen(wanIpReadingProvider, (_, __) {});
      await c.read(wanDataProvider.future);
      expect(c.read(wanIpReadingProvider).addressOrNull, '100.64.0.1');

      // Exactly what usp_internet_settings_notifier does after a save / renew.
      c.invalidate(wanDataProvider);
      await Future<void>.delayed(Duration.zero);

      final mid = c.read(wanDataProvider);
      expect(mid.isLoading, isTrue,
          reason: 'the refetch must still be in flight');
      expect(
        c.read(wanIpReadingProvider),
        isA<WanIpAddress>(),
        reason:
            'a refresh must not blank the address — riverpod carries the previous value, '
            'and this provider depends on that. If this fails, the banner and the renew '
            'card now flash "unknown" mid-renew.',
      );
      expect(c.read(wanIpReadingProvider).addressOrNull, '100.64.0.1');

      await c.read(wanDataProvider.future);
      expect(c.read(wanIpReadingProvider).addressOrNull, '100.64.0.2',
          reason: 'and the completion does swap in the new address');
    });
  });
}
