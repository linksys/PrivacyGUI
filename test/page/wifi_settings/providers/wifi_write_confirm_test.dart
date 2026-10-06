import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_write_confirm.dart';
import 'package:privacy_gui/page/wifi_settings/services/usp_wifi_settings_service.dart';

/// The provider-side half of #1499 / #1460: a WiFi write whose answer never
/// arrives is read back from the router before it is called a failure.
///
/// Driven through the REAL [UspMutationLock] with a short answer window, so the
/// lock's own `TimeoutException` — the exact thing #1460 tripped at 30 s — is
/// what the tests exercise. A stand-in lock would hide it.
void main() {
  const params = {'Device.WiFi.SSID.1.SSID': 'NewHome'};
  WifiWritePlan plan(Future<WifiWriteOutcome> Function() send,
          {Map<String, dynamic> p = params, int count = 1}) =>
      WifiWritePlan(params: p, send: send, count: count);

  late ProviderContainer container;
  setUp(() {
    container = ProviderContainer(overrides: [
      uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      wifiAnswerWindowProvider
          .overrideWithValue(const Duration(milliseconds: 50)),
      wifiReadBackIntervalProvider
          .overrideWithValue(const Duration(milliseconds: 10)),
      wifiSaveDeadlineProvider
          .overrideWithValue(const Duration(milliseconds: 200)),
    ]);
  });
  tearDown(() => container.dispose());

  Future<int> run(
    WifiWritePlan p, {
    required Future<bool> Function(Map<String, dynamic>) isApplied,
  }) =>
      container.read(wifiWriteConfirmProvider)(p, isApplied: isApplied);

  test('a confirmed write returns its count and never reads back', () async {
    var reads = 0;
    final count = await run(
      plan(() async => WifiWriteOutcome.confirmed, count: 2),
      isApplied: (_) async {
        reads++;
        return true;
      },
    );

    expect(count, 2);
    expect(reads, 0);
  });

  test('an unanswered write that reads back is confirmed', () async {
    final seen = <Map<String, dynamic>>[];
    await run(
      plan(() async => WifiWriteOutcome.unanswered),
      isApplied: (w) async {
        seen.add(w);
        return true;
      },
    );

    expect(seen.single, params, reason: 'reads back exactly what it planned');
  });

  test(
      'outlasting the lock window is read back WITH the planned params '
      '(#1460: the SET took 35.4 s, the lock gave up at 30, the setting had '
      'applied)', () async {
    final seen = <Map<String, dynamic>>[];
    await run(
      // Never answers inside the 50 ms window.
      plan(() => Completer<WifiWriteOutcome>().future),
      isApplied: (w) async {
        seen.add(w);
        return true;
      },
    );

    // The reply never came, so the params can only have come from the plan.
    // Reading back an empty map here would "confirm" without checking anything.
    expect(seen.single, params);
  });

  test('keeps reading while the router is not on the new values yet', () async {
    var reads = 0;
    await run(
      plan(() async => WifiWriteOutcome.unanswered),
      isApplied: (_) async => ++reads >= 3,
    );

    expect(reads, 3);
  });

  test('a failed read is "not yet", not an error', () async {
    var reads = 0;
    await run(
      plan(() async => WifiWriteOutcome.unanswered),
      isApplied: (_) async {
        if (++reads == 1) throw const NetworkError(detail: 'radios settling');
        return true;
      },
    );

    expect(reads, 2);
  });

  test(
      'never reading back by the deadline is a ServiceError — no false '
      'success', () async {
    await expectLater(
      run(
        plan(() async => WifiWriteOutcome.unanswered),
        isApplied: (_) async => false,
      ),
      throwsA(isA<ServiceError>()),
    );
  });

  test('a refusal from the write propagates unchanged', () async {
    await expectLater(
      run(
        plan(() async => throw const InvalidInputError(detail: 'rejected')),
        isApplied: (_) async => true,
      ),
      throwsA(isA<InvalidInputError>()),
    );
  });

  test('nothing to write sends nothing and reads nothing', () async {
    var sends = 0;
    var reads = 0;
    final count = await run(
      plan(() async {
        sends++;
        return WifiWriteOutcome.confirmed;
      }, p: const {}, count: 0),
      isApplied: (_) async {
        reads++;
        return true;
      },
    );

    expect((count, sends, reads), (0, 0, 0));
  });
}
