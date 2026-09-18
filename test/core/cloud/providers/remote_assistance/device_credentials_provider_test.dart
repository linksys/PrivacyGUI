import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/cloud/providers/remote_assistance/device_credentials_provider.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';

// =============================================================================
// deviceCredentialsProvider — the three values Guardian validates (#1582).
//
// It used to compose the serial from the session and the MAC + UUID from the
// **master node**, i.e. from `Device.Hosts.Host.{i}`. FL-WRT 2.0 deleted both
// `DeviceID` and `DeviceRole`, so on that firmware the master could not even be
// found, credentials were always null, and the support page's Remote Assistance
// row was permanently un-tappable with no way to tell.
//
// Now all three come from `session.deviceInfo`, and the point of that shape is
// what it deletes: **no dependency on `devicesDataProvider` or the master node
// at all**. The `'GATEWAY'` string that `MasterNode.deviceId` falls back to
// therefore cannot reach Guardian by construction rather than by a guard —
// measured, the token endpoint answers 403 to a wrong MAC.
//
// The shape checks are defence in depth for the caller: a malformed value fails
// as a 403 from the cloud, which surfaces as "Remote Assistance does nothing" —
// the exact symptom this ticket exists to remove.
// =============================================================================

void main() {
  const mac = '74:12:13:21:55:02';
  const uuid = '3E68DD2F-CF4F-4E47-A99B-741213215502';

  NodeDeviceInfo deviceInfo({
    String serialNumber = '67A10M24F00066',
    String? baseMacAddress = mac,
    String? deviceUuid = uuid,
  }) =>
      NodeDeviceInfo(
        modelNumber: 'M60TB',
        firmwareVersion: '2.0.1',
        description: '',
        firmwareDate: '',
        manufacturer: 'Linksys',
        serialNumber: serialNumber,
        hardwareVersion: '1',
        baseMacAddress: baseMacAddress,
        deviceUuid: deviceUuid,
      );

  /// Overrides **only** the session. Nothing else is provided on purpose: if this
  /// provider ever reads `devicesDataProvider` again, that provider builds for
  /// real here, resolves to null, and every test in this group fails.
  ProviderContainer containerWith(NodeDeviceInfo? info) {
    final container = ProviderContainer(
      overrides: [
        sessionProvider.overrideWith(() => _FakeSessionNotifier(info)),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('deviceCredentialsProvider', () {
    test('composes all three values from the session alone', () {
      final creds = containerWith(deviceInfo()).read(deviceCredentialsProvider);

      expect(creds, isNotNull);
      expect(creds!.serialNumber, '67A10M24F00066');
      expect(creds.macAddress, mac);
      expect(creds.deviceUUID, uuid);
    });

    test('null when there is no session device info', () {
      expect(containerWith(null).read(deviceCredentialsProvider), isNull);
    });

    test('null when the UUID is missing or empty', () {
      expect(
        containerWith(deviceInfo(deviceUuid: null))
            .read(deviceCredentialsProvider),
        isNull,
      );
      expect(
        containerWith(deviceInfo(deviceUuid: ''))
            .read(deviceCredentialsProvider),
        isNull,
      );
    });

    test('null when the MAC is missing or empty', () {
      expect(
        containerWith(deviceInfo(baseMacAddress: null))
            .read(deviceCredentialsProvider),
        isNull,
      );
      expect(
        containerWith(deviceInfo(baseMacAddress: ''))
            .read(deviceCredentialsProvider),
        isNull,
      );
    });

    test("null for the literal 'GATEWAY' the old MAC chain fell back to", () {
      expect(
        containerWith(deviceInfo(baseMacAddress: 'GATEWAY'))
            .read(deviceCredentialsProvider),
        isNull,
      );
    });

    test('null when the UUID still carries its uuid:: prefix', () {
      // The prefix is stripped where the value is read. If that ever stops
      // happening, Guardian answers 403 and the failure looks like this bug
      // all over again — so refuse it here too.
      expect(
        containerWith(deviceInfo(deviceUuid: 'uuid::$uuid'))
            .read(deviceCredentialsProvider),
        isNull,
      );
    });

    test('null when the serial number is empty', () {
      expect(
        containerWith(deviceInfo(serialNumber: ''))
            .read(deviceCredentialsProvider),
        isNull,
      );
    });
  });

  // The behavioural test above catches a re-added `devicesDataProvider` watch,
  // but only while these overrides stay as they are. This names the rule itself:
  // the whole point of #1582's shape is that Remote Assistance no longer depends
  // on the `Hosts` table that FL-WRT 2.0 deleted.
  test('the provider does not reach for the devices table or the master node',
      () {
    final source = File(
      'lib/core/cloud/providers/remote_assistance/device_credentials_provider.dart',
    ).readAsStringSync();
    final code = source
        .split('\n')
        .where((l) => !l.trimLeft().startsWith('//'))
        .join('\n');

    expect(code, isNot(contains('devicesDataProvider')));
    expect(code, isNot(contains('hostsDeviceId')));
    expect(code, isNot(contains('.master')));
  });
}

// =============================================================================
// Fakes
// =============================================================================

class _FakeSessionNotifier extends Notifier<SessionState>
    implements SessionNotifier {
  final NodeDeviceInfo? _deviceInfo;
  _FakeSessionNotifier(this._deviceInfo);

  @override
  SessionState build() => SessionState(deviceInfo: _deviceInfo);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
