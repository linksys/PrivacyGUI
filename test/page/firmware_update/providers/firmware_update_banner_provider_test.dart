import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_auto_update_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/models/firmware_image_ui_model.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_auto_update_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_banks_data_provider.dart';
import 'package:privacy_gui/page/firmware_update/providers/firmware_update_banner_provider.dart';

/// Publishes a fixed [AsyncValue] rather than a fixed value, so the matrix can
/// cover loading and error alongside the data cases — those are the states the
/// dashboard actually mounts in, and both must read as "do not show a banner"
/// rather than as "no update".
class _FixedAutoUpdate extends FirmwareAutoUpdateDataNotifier {
  _FixedAutoUpdate(this._value);
  final AsyncValue<FirmwareAutoUpdateUIModel> _value;

  @override
  Future<FirmwareAutoUpdateUIModel> build() async {
    state = _value;
    return _value.valueOrNull ?? _unreachable();
  }

  Never _unreachable() => throw const NetworkError(detail: 'fixture');
}

class _FixedBanks extends FirmwareBanksDataNotifier {
  _FixedBanks(this._value);
  final AsyncValue<FirmwareBanksData> _value;

  @override
  Future<FirmwareBanksData> build() async {
    state = _value;
    return _value.valueOrNull ?? const FirmwareBanksData(banks: []);
  }
}

/// A provider that succeeds and *then* fails, which is the shape the fixed
/// fixtures above cannot hold.
///
/// `_FixedAutoUpdate` cannot: hand it a value-carrying `AsyncError` and `build()`
/// returns that value, so riverpod publishes `AsyncData` over the top and the test
/// measures a success. These two settle first and are failed by hand afterwards,
/// through the same `state = AsyncError(...)` line `refresh()`'s catch uses — and
/// riverpod re-attaches the previous reading on the way, which is the whole point.
class _FailsAfterSuccessAutoUpdate extends FirmwareAutoUpdateDataNotifier {
  _FailsAfterSuccessAutoUpdate(this._value);
  final FirmwareAutoUpdateUIModel _value;

  @override
  Future<FirmwareAutoUpdateUIModel> build() async => _value;

  void fail() =>
      state = AsyncError(const NetworkError(detail: 'x'), StackTrace.empty);
}

class _FailsAfterSuccessBanks extends FirmwareBanksDataNotifier {
  _FailsAfterSuccessBanks(this._value);
  final FirmwareBanksData _value;

  @override
  Future<FirmwareBanksData> build() async => _value;

  void fail() =>
      state = AsyncError(const NetworkError(detail: 'x'), StackTrace.empty);
}

void main() {
  const offeredVersion = '1.0.17.0';

  FirmwareAutoUpdateUIModel autoUpdate(
    String rawFlags, {
    FirmwareAutoUpdateStatus status = FirmwareAutoUpdateStatus.idle,
  }) =>
      FirmwareAutoUpdateUIModel(
        status: status,
        progress: 0,
        rawState: '0',
        policy: FirmwareAutoUpdatePolicy.fromRaw(rawFlags),
        rawFlags: rawFlags,
      );

  FirmwareBanksData banks({bool? otaAvailable, String? version}) =>
      FirmwareBanksData(banks: [
        const FirmwareImageUIModel(
          instance: 1,
          instancePath: 'Device.DeviceInfo.FirmwareImage.1.',
          alias: 'fw1',
          name: '',
          version: '1.0.16.0',
          status: 'Active',
          available: true,
        ),
        // `otaAvailable == null` is a router that reports no ota row at all — an
        // OEM build without the fwup stack. Distinct from `false`, and the two
        // must not be told apart by the banner.
        if (otaAvailable != null)
          FirmwareImageUIModel(
            instance: 3,
            instancePath: 'Device.DeviceInfo.FirmwareImage.3.',
            alias: 'ota',
            name: '',
            version: otaAvailable ? (version ?? offeredVersion) : '',
            status: otaAvailable ? 'Available' : 'NoImage',
            available: otaAvailable,
          ),
      ]);

  ProviderContainer createContainer({
    required AsyncValue<FirmwareAutoUpdateUIModel> auto,
    required AsyncValue<FirmwareBanksData> banksValue,
  }) {
    final container = ProviderContainer(overrides: [
      firmwareAutoUpdateDataProvider.overrideWith(() => _FixedAutoUpdate(auto)),
      firmwareBanksDataProvider.overrideWith(() => _FixedBanks(banksValue)),
    ]);
    addTearDown(container.dispose);
    return container;
  }

  bool visible({
    String rawFlags = '2',
    FirmwareAutoUpdateStatus status = FirmwareAutoUpdateStatus.idle,
    bool? otaAvailable = true,
    String? dismissedVersion,
  }) {
    final container = createContainer(
      auto: AsyncData(autoUpdate(rawFlags, status: status)),
      banksValue: AsyncData(banks(otaAvailable: otaAvailable)),
    );
    if (dismissedVersion != null) {
      container
          .read(firmwareUpdateBannerDismissedVersionProvider.notifier)
          .state = dismissedVersion;
    }
    return container.read(firmwareUpdateBannerVisibleProvider);
  }

  group('firmwareUpdateOfferedVersionProvider — the conditions', () {
    test('offers the ota row\'s version when the router checks', () {
      final container = createContainer(
        auto: AsyncData(autoUpdate('2')),
        banksValue: AsyncData(banks(otaAvailable: true)),
      );
      expect(
          container.read(firmwareUpdateOfferedVersionProvider), offeredVersion);
      expect(container.read(firmwareUpdateBannerVisibleProvider), isTrue);
    });

    test('shows in notify-only, which is the mode it exists to serve', () {
      // A router set to 1 finds updates and installs nothing, so the banner is
      // the only thing that will ever tell the user.
      expect(visible(rawFlags: '1', otaAvailable: true), isTrue);
    });

    test('hidden when the router does not check, even with an image waiting',
        () {
      // flags == 0 is a user who asked not to be involved. A stale ota row from
      // before they turned checking off must not resurrect the banner.
      expect(visible(rawFlags: '0', otaAvailable: true), isFalse);
    });

    test('hidden when the router checks but nothing is waiting', () {
      expect(visible(rawFlags: '2', otaAvailable: false), isFalse);
    });

    test('hidden when the router reports no ota row at all', () {
      // Null means *no update information*, which is not the same as "up to
      // date" and must never read as "an update is available".
      expect(visible(rawFlags: '2', otaAvailable: null), isFalse);
    });

    test('an unrecognised positive flag still counts as checking', () {
      // The condition is `flags > 0`, not `policy != off`. A firmware that adds a
      // `3` is a router that is checking, and it has already found the image the
      // banner would be announcing — withholding it would hide real information
      // behind a gap in this app's enum.
      expect(visible(rawFlags: '3', otaAvailable: true), isTrue);
    });

    test('a non-numeric flag reads as not checking', () {
      expect(visible(rawFlags: '', otaAvailable: true), isFalse);
    });
  });

  group('firmwareUpdateOfferedVersionProvider — the daemon is already at work',
      () {
    // The reachable case, and it is the default one: a router at
    // `autoupdate_flags = 2` downloads and flashes on its own, and while it does
    // both other conditions still hold. Offering "Update Now" then is a second
    // entry into a download against a bank that is mid-write.
    for (final status in [
      FirmwareAutoUpdateStatus.checking,
      FirmwareAutoUpdateStatus.downloading,
      FirmwareAutoUpdateStatus.installing,
    ]) {
      test('hidden while the router is ${status.name}', () {
        expect(visible(status: status), isFalse,
            reason: 'the progress view on the OTA page owns this state, not a '
                'dashboard offer');
      });
    }

    // The two arms that are *not* work in progress. `idle` especially: it is where
    // a failed update lands, because `fwup_state` has no failure value at all — see
    // `FirmwareAutoUpdateStatus` — and a failed update is exactly when a user should
    // be able to retry by hand, so hiding the banner there would remove the only way
    // out.
    for (final status in [
      FirmwareAutoUpdateStatus.idle,
      FirmwareAutoUpdateStatus.unknown,
    ]) {
      test('still shown when the daemon is ${status.name}', () {
        expect(visible(status: status), isTrue);
      });
    }
  });

  group('firmwareUpdateBannerVisibleProvider — unknown state', () {
    test('hidden while either provider is still loading', () {
      final loadingAuto = createContainer(
        auto: const AsyncLoading(),
        banksValue: AsyncData(banks(otaAvailable: true)),
      );
      expect(loadingAuto.read(firmwareUpdateBannerVisibleProvider), isFalse);

      final loadingBanks = createContainer(
        auto: AsyncData(autoUpdate('2')),
        banksValue: const AsyncLoading(),
      );
      expect(loadingBanks.read(firmwareUpdateBannerVisibleProvider), isFalse);
    });

    test('hidden when either read failed', () {
      final autoFailed = createContainer(
        auto: AsyncError(const NetworkError(detail: 'x'), StackTrace.empty),
        banksValue: AsyncData(banks(otaAvailable: true)),
      );
      expect(autoFailed.read(firmwareUpdateBannerVisibleProvider), isFalse);

      final banksFailed = createContainer(
        auto: AsyncData(autoUpdate('2')),
        banksValue:
            AsyncError(const NetworkError(detail: 'x'), StackTrace.empty),
      );
      expect(banksFailed.read(firmwareUpdateBannerVisibleProvider), isFalse);
    });

    test('hidden when a read fails *after* it had already succeeded', () async {
      // The reachable version of the test above, and the one that actually
      // constrains the code. A first read that fails has no previous value, so
      // `valueOrNull` is null and any spelling of the predicate hides the banner —
      // that test would pass on a provider that never looks at `hasError`. A
      // refresh that fails an hour later arrives as `hasValue && hasError` with
      // the stale reading attached, and `valueOrNull` hands it back looking like
      // fresh data: the banner would go on offering a version from a router that
      // is no longer answering, with an Update Now button that cannot work.
      final auto = _FailsAfterSuccessAutoUpdate(autoUpdate('2'));
      final container = ProviderContainer(overrides: [
        firmwareAutoUpdateDataProvider.overrideWith(() => auto),
        firmwareBanksDataProvider.overrideWith(
            () => _FixedBanks(AsyncData(banks(otaAvailable: true)))),
      ]);
      addTearDown(container.dispose);

      await container.read(firmwareAutoUpdateDataProvider.future);
      expect(container.read(firmwareUpdateBannerVisibleProvider), isTrue);

      auto.fail();
      expect(container.read(firmwareAutoUpdateDataProvider).hasValue, isTrue,
          reason:
              'the stale reading is still attached — riverpod does that, and '
              'it is what makes this case different from a first read that failed');
      expect(container.read(firmwareUpdateBannerVisibleProvider), isFalse);
    });

    test('hidden when the banks read fails after it had already succeeded',
        () async {
      final banksNotifier = _FailsAfterSuccessBanks(banks(otaAvailable: true));
      final container = ProviderContainer(overrides: [
        firmwareAutoUpdateDataProvider
            .overrideWith(() => _FixedAutoUpdate(AsyncData(autoUpdate('2')))),
        firmwareBanksDataProvider.overrideWith(() => banksNotifier),
      ]);
      addTearDown(container.dispose);

      await container.read(firmwareBanksDataProvider.future);
      expect(container.read(firmwareUpdateBannerVisibleProvider), isTrue);

      banksNotifier.fail();
      expect(container.read(firmwareUpdateBannerVisibleProvider), isFalse);
    });
  });

  group('firmwareUpdateBannerDismissedVersionProvider', () {
    test('starts with nothing dismissed', () {
      final container = createContainer(
        auto: AsyncData(autoUpdate('2')),
        banksValue: AsyncData(banks(otaAvailable: true)),
      );
      expect(
          container.read(firmwareUpdateBannerDismissedVersionProvider), isNull);
    });

    test('dismissing the offered version hides the banner', () {
      expect(visible(dismissedVersion: offeredVersion), isFalse);
    });

    test('a dismissal is a live signal, not a one-shot read', () async {
      final container = createContainer(
        auto: AsyncData(autoUpdate('2')),
        banksValue: AsyncData(banks(otaAvailable: true)),
      );
      // Subscribe so the derived provider is watching rather than recomputed on
      // each read — otherwise this test would pass on a provider that ignores
      // the dismissal entirely.
      final seen = <bool>[];
      container.listen(
        firmwareUpdateBannerVisibleProvider,
        (_, next) => seen.add(next),
        fireImmediately: true,
      );

      container
          .read(firmwareUpdateBannerDismissedVersionProvider.notifier)
          .state = offeredVersion;
      await Future<void>.delayed(Duration.zero);

      expect(seen, [true, false]);
    });

    test('a dismissal silences one update, not the next one', () {
      // What a bool got wrong. Dismiss 1.0.17, install it by some other route or
      // let the router find 1.0.19 later, and the second notice is a different
      // notice about a different build — it has to arrive.
      final container = createContainer(
        auto: AsyncData(autoUpdate('2')),
        banksValue: AsyncData(banks(otaAvailable: true, version: '1.0.19.0')),
      );
      container
          .read(firmwareUpdateBannerDismissedVersionProvider.notifier)
          .state = offeredVersion;

      expect(container.read(firmwareUpdateBannerVisibleProvider), isTrue);
    });

    test('a version-less offer keys on the empty string', () {
      // A router that says an image is available without naming it. The banner is
      // still shown, and dismissing it still works — it just cannot tell one
      // unnamed build from another, which nothing here can.
      final container = createContainer(
        auto: AsyncData(autoUpdate('2')),
        banksValue: AsyncData(banks(otaAvailable: true, version: '')),
      );
      expect(container.read(firmwareUpdateOfferedVersionProvider), '');
      expect(container.read(firmwareUpdateBannerVisibleProvider), isTrue);

      container
          .read(firmwareUpdateBannerDismissedVersionProvider.notifier)
          .state = '';
      expect(container.read(firmwareUpdateBannerVisibleProvider), isFalse);
    });
  });
}
