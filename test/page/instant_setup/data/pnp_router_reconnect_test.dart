import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';

void main() {
  test('post-save checks retry transient failures then stop on success',
      () async {
    var probes = 0;
    final delays = <Duration>[];
    final result = await waitForPnpPostSaveReconnect(
      probe: () async {
        if (++probes < 3) throw ExceptionNeedToReconnect();
      },
      delay: (duration) async => delays.add(duration),
    );
    expect(result, isTrue);
    expect(probes, 3);
    expect(delays, [
      pnpReconnectInitialDelay,
      pnpReconnectRetryDelay,
      pnpReconnectRetryDelay
    ]);
  });

  test('post-save retry count is bounded without a final extra delay',
      () async {
    var probes = 0;
    final delays = <Duration>[];
    final result = await waitForPnpPostSaveReconnect(
      probe: () async {
        probes++;
        throw ExceptionNeedToReconnect();
      },
      delay: (duration) async => delays.add(duration),
    );
    expect(result, isFalse);
    expect(probes, pnpReconnectMaxAttempts);
    expect(delays.length, pnpReconnectMaxAttempts);
  });

  test('explicit password rejection is not retried automatically', () async {
    var probes = 0;
    await expectLater(
        waitForPnpPostSaveReconnect(
          probe: () async {
            probes++;
            throw ExceptionInvalidAdminPassword();
          },
          shouldRetry: (error) => error is! ExceptionInvalidAdminPassword,
          delay: (_) async {},
        ),
        throwsA(isA<ExceptionInvalidAdminPassword>()));
    expect(probes, 1);
  });

  test('inactive page never starts a readiness request', () async {
    var probes = 0;
    expect(
        await waitForPnpPostSaveReconnect(
          probe: () async {
            probes++;
          },
          shouldContinue: () => false,
          delay: (_) async {},
        ),
        isFalse);
    expect(probes, 0);
  });

  test('same-router validation rejects missing or different serial numbers',
      () {
    expect(isExpectedPnpRouter('ABC123', 'ABC123'), isTrue);
    expect(isExpectedPnpRouter(' ABC123 ', 'ABC123'), isTrue);
    expect(isExpectedPnpRouter('ABC123', 'OTHER'), isFalse);
    expect(isExpectedPnpRouter(null, 'ABC123'), isFalse);
    expect(isExpectedPnpRouter('', 'ABC123'), isFalse);
  });

  test('configured and preserved-password saves never try the WiFi password',
      () {
    expect(
      pnpPostSaveAdminPasswordCandidates(
        currentPassword: 'imported-device-password',
        wifiPassword: 'wifi-password',
        didSetAdminPassword: false,
      ),
      ['imported-device-password'],
    );
    expect(
      pnpPostSaveAdminPasswordCandidates(
        currentPassword: null,
        wifiPassword: 'wifi-password',
        didSetAdminPassword: false,
      ),
      isEmpty,
    );
  });

  test('factory-default save can reconcile the new WiFi admin password', () {
    expect(
      pnpPostSaveAdminPasswordCandidates(
        currentPassword: 'old-password',
        wifiPassword: 'new-wifi-password',
        didSetAdminPassword: true,
      ),
      ['old-password', 'new-wifi-password'],
    );
  });
}
