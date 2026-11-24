import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/instant_verify/models/wan_ip_comparison.dart';
import 'package:privacy_gui/page/instant_verify/services/wan_ip_history.dart';

void main() {
  const mac = 'AA:BB:CC:DD:EE:01';
  late Map<String, String> storage;
  late WanIpHistory history;
  setUp(() {
    storage = {};
    history = WanIpHistory(
        read: (key) => storage[key],
        write: (key, value) => storage[key] = value);
  });
  WanIpComparison observe(String? address,
          {String? router = mac, bool connected = true}) =>
      history.observe(
          routerMac: router, currentAddress: address, connected: connected);

  test('first run saves a reference without claiming it compared history', () {
    expect(observe('198.51.100.10').status, WanIpStatus.firstObservation);
    expect(storage.values.single, '198.51.100.10');
    expect(observe('198.51.100.10').status, WanIpStatus.unchanged);
  });

  test('change stays visible on repeated runs and a new service instance', () {
    observe('198.51.100.10');
    expect(observe('198.51.100.20').status, WanIpStatus.changed);
    expect(observe('198.51.100.20').referenceAddress, '198.51.100.10');
    history = WanIpHistory(
        read: (key) => storage[key],
        write: (key, value) => storage[key] = value);
    expect(observe('198.51.100.20').status, WanIpStatus.changed);
    expect(storage.values.single, '198.51.100.10');
  });

  test('explicit acknowledgement updates only the reference', () {
    observe('198.51.100.10');
    expect(
        history.saveReference(
            routerMac: mac, currentAddress: '198.51.100.20', connected: true),
        isTrue);
    expect(observe('198.51.100.20').status, WanIpStatus.unchanged);
  });

  test('router identities are isolated and MAC formatting is normalized', () {
    observe('198.51.100.10');
    expect(observe('198.51.100.20', router: 'AA:BB:CC:DD:EE:02').status,
        WanIpStatus.firstObservation);
    expect(observe('198.51.100.10', router: 'aa-bb-cc-dd-ee-01').status,
        WanIpStatus.unchanged);
    expect(storage, hasLength(2));
  });

  test('disconnection cannot erase or replace the reference', () {
    observe('198.51.100.10');
    expect(observe('198.51.100.20', connected: false).status,
        WanIpStatus.unavailable);
    expect(
        history.saveReference(
            routerMac: mac, currentAddress: '198.51.100.20', connected: false),
        isFalse);
    expect(storage.values.single, '198.51.100.10');
  });

  test('missing or placeholder identity never shares a baseline', () {
    for (final identity in [
      null,
      '',
      'unknown',
      '00:00:00:00:00:00',
      'FF:FF:FF:FF:FF:FF'
    ]) {
      expect(observe('198.51.100.10', router: identity).status,
          WanIpStatus.unavailable);
    }
    expect(storage, isEmpty);
  });

  test('invalid and unavailable addresses never poison the reference', () {
    for (final ip in [
      null,
      '',
      '0.0.0.0',
      '169.254.1.2',
      '127.0.0.1',
      '224.0.0.1',
      '255.255.255.255',
      '999.1.1.1',
      '198.51.1',
      '198.51.100.10:80',
      '::1'
    ]) {
      expect(observe(ip).status, WanIpStatus.unavailable, reason: '$ip');
    }
    expect(storage, isEmpty);
  });

  test('clearing browser storage starts a new first observation', () {
    observe('198.51.100.10');
    storage.clear();
    expect(observe('198.51.100.20').status, WanIpStatus.firstObservation);
  });

  test('blocked storage is unavailable rather than a false unchanged result',
      () {
    history = WanIpHistory(read: (_) => null, write: (_, __) {});
    expect(observe('198.51.100.10').status, WanIpStatus.unavailable);
    expect(
        history.saveReference(
            routerMac: mac, currentAddress: '198.51.100.10', connected: true),
        isFalse);
  });

  test('throwing storage does not interrupt diagnostics', () {
    history = WanIpHistory(
        read: (_) => throw StateError('disabled'),
        write: (_, __) => throw StateError('disabled'));
    expect(observe('198.51.100.10').status, WanIpStatus.unavailable);
  });

  test(
      'private and shared WAN addresses can be compared without calling them public',
      () {
    expect(observe('100.64.1.10').status, WanIpStatus.firstObservation);
    expect(observe('192.168.0.10').status, WanIpStatus.changed);
  });
}
