import 'dart:async';
import 'package:privacy_gui/page/_shared/mode/remote_surface.dart';
import 'package:privacy_gui/page/_shared/mode/surface_strategy_provider.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_snapshot.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/providers/auto_ipoe_data_provider.dart';
import 'package:privacy_gui/page/auto_ipoe/services/auto_ipoe_service.dart';

import '../../../mocks/test_data/auto_ipoe_test_data.dart';

class MockService extends Mock implements AutoIPoEService {}

void main() {
  late MockService service;
  late ProviderContainer container;
  setUpAll(
    () => registerFallbackValue(
      const AutoIPoESubmission(AutoIPoETestData.id, reset: false),
    ),
  );
  setUp(() {
    service = MockService();
    when(() => service.loadSubmission()).thenAnswer((_) async => null);
    when(() => service.storeSubmission(any())).thenAnswer((_) async {});
    when(() => service.clearSubmission()).thenAnswer((_) async {});
    when(() => service.fetch())
        .thenAnswer((_) async => AutoIPoETestData.snapshot());
    container = ProviderContainer(
      overrides: [autoIPoEServiceProvider.overrideWithValue(service)],
    );
  });
  tearDown(() => container.dispose());
  AutoIPoESnapshot resetResult(
    String id, {
    bool residual = false,
    int code = 0,
  }) {
    final result = AutoIPoETestData.snapshot(
      requestId: id,
      exitCode: code,
      reset: true,
    );
    return AutoIPoESnapshot(
      capabilities: result.capabilities,
      settings: residual ? result.settings : const AutoIPoESettings.init(),
      runtime: result.runtime.copyWith(
        isEnabled: residual,
        isCurrentWANType: residual,
        needsResetBeforeLeaving: residual,
      ),
      requestId: id,
      operationId: id,
      exitCode: code,
      accepted: true,
    );
  }

  testWidgets(
      'read-only sessions observe pending work without resolving or writing',
      (tester) async {
    container.dispose();
    container = ProviderContainer(overrides: [
      autoIPoEServiceProvider.overrideWithValue(service),
      surfaceStrategyProvider.overrideWithValue(const RemoteSurface()),
    ]);
    const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
    when(() => service.loadSubmission()).thenAnswer((_) async => submission);
    await container.read(autoIPoEDataProvider.future);
    final notifier = container.read(autoIPoEDataProvider.notifier);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(autoIPoESubmissionProvider), submission);
    for (final action in <Future<void> Function()>[
      () => notifier.apply(AutoIPoETestData.settings),
      notifier.reset,
      () => notifier.resolvePending(),
      () => notifier.leavePnp(),
    ]) {
      await expectLater(action(), throwsA(isA<UnauthorizedError>()));
    }
    verifyNever(() => service.resolvePending(any()));
    verifyNever(() => service.storeSubmission(any()));
    verifyNever(() => service.clearSubmission());
    verifyNever(() => service.submit(any(),
        settings: any(named: 'settings'),
        resetFirst: any(named: 'resetFirst')));
    container.dispose();
    container = ProviderContainer();
  });

  test('PnP clean Back before Execute does not reset WAN', () async {
    when(() => service.fetch())
        .thenAnswer((_) async => const AutoIPoESnapshot());
    await container.read(autoIPoEDataProvider.future);
    await container.read(autoIPoEDataProvider.notifier).leavePnp();
    verifyNever(
      () => service.submit(
        any(),
        settings: any(named: 'settings'),
        resetFirst: any(named: 'resetFirst'),
      ),
    );
    expect(container.read(autoIPoESubmissionProvider), isNull);
  });

  for (final failure in ['none', 'residual', 'failed', 'rejected', 'storage']) {
    test('PnP Back verifies canonical Reset: $failure', () async {
      var current = AutoIPoETestData.snapshot(
        requestId: AutoIPoETestData.id,
        exitCode: 1,
      );
      when(() => service.fetch()).thenAnswer((_) async => current);
      when(() => service.loadSubmission()).thenAnswer(
        (_) async =>
            const AutoIPoESubmission(AutoIPoETestData.id, reset: false),
      );
      when(
        () => service.submit(any(), settings: null, resetFirst: false),
      ).thenAnswer((call) async {
        final request = call.positionalArguments.single as AutoIPoESubmission;
        expect(request.reset, true);
        if (failure == 'rejected') {
          return const AutoIPoEReceipt(
            accepted: false,
            error: 'ErrorAlreadyRunning',
          );
        }
        current = resetResult(
          request.requestId,
          residual: failure == 'residual',
          code: failure == 'failed' ? 1 : 0,
        );
        return AutoIPoEReceipt(
          accepted: true,
          requestId: request.requestId,
          operationId: request.requestId,
        );
      });
      if (failure == 'storage') {
        when(() => service.clearSubmission()).thenThrow(const StorageError());
      }
      await container.read(autoIPoEDataProvider.future);
      final exit = container
          .read(autoIPoEDataProvider.notifier)
          .leavePnp(resetIfIdle: true);
      if (failure == 'none') {
        await exit;
        expect(container.read(autoIPoESubmissionProvider), isNull);
        expect(
          container.read(autoIPoEDataProvider).requireValue.settings.isEnabled,
          false,
        );
      } else {
        await expectLater(exit, throwsA(isA<ServiceError>()));
        expect(container.read(autoIPoESubmissionProvider), isNotNull);
      }
      verify(() => service.submit(any(), settings: null, resetFirst: false))
          .called(1);
    });
  }

  testWidgets(
    'PnP Back waits for worker and reset completion without duplicate dispatch',
    (tester) async {
      var current = AutoIPoETestData.snapshot(
        requestId: AutoIPoETestData.id,
        busy: true,
      );
      AutoIPoESubmission? resetting;
      when(() => service.fetch()).thenAnswer((_) async => current);
      when(() => service.loadSubmission()).thenAnswer(
        (_) async =>
            const AutoIPoESubmission(AutoIPoETestData.id, reset: false),
      );
      when(() => service.submit(any(), settings: null, resetFirst: false))
          .thenAnswer((call) async {
        resetting = call.positionalArguments.single as AutoIPoESubmission;
        current = AutoIPoETestData.snapshot(
          requestId: resetting!.requestId,
          busy: true,
        );
        return AutoIPoEReceipt(
          accepted: true,
          requestId: resetting!.requestId,
          operationId: resetting!.requestId,
        );
      });
      await container.read(autoIPoEDataProvider.future);
      final notifier = container.read(autoIPoEDataProvider.notifier);
      var completed = false;
      final exiting = notifier.leavePnp().then((_) => completed = true);
      await tester.pump();
      expect(resetting, isNull);
      await expectLater(notifier.leavePnp(), throwsA(isA<InvalidInputError>()));
      current = AutoIPoETestData.snapshot(
        requestId: AutoIPoETestData.id,
        exitCode: 1,
      );
      await tester.pump(const Duration(seconds: 3));
      expect(resetting, isNotNull);
      expect(completed, false);
      current = resetResult(resetting!.requestId);
      await tester.pump(const Duration(seconds: 3));
      await exiting;
      expect(completed, true);
      verify(() => service.submit(any(), settings: null, resetFirst: false))
          .called(1);
    },
  );

  test(
    'lost reply and reconnect poll only; no duplicate Apply is dispatched',
    () async {
      await container.read(autoIPoEDataProvider.future);
      when(
        () => service.submit(
          any(),
          settings: AutoIPoETestData.settings,
          resetFirst: false,
        ),
      ).thenThrow(const ConnectivityError());
      final notifier = container.read(autoIPoEDataProvider.notifier);
      await notifier.apply(AutoIPoETestData.settings);
      final id = container.read(autoIPoESubmissionProvider)!.requestId;
      expect(id, isNotEmpty);
      await notifier.refresh();
      await notifier.refresh();
      expect(container.read(autoIPoESubmissionProvider)!.requestId, id);
      await expectLater(
        notifier.apply(AutoIPoETestData.settings),
        throwsA(isA<InvalidInputError>()),
      );
      verify(
        () => service.submit(
          any(),
          settings: AutoIPoETestData.settings,
          resetFirst: false,
        ),
      ).called(1);
    },
  );
  test(
    'browser reload restores UUID and never submits the operation',
    () async {
      when(() => service.loadSubmission()).thenAnswer(
        (_) async =>
            const AutoIPoESubmission(AutoIPoETestData.id, reset: false),
      );
      await container.read(autoIPoEDataProvider.future);
      await container.read(autoIPoEDataProvider.notifier).refresh();
      expect(
        container.read(autoIPoESubmissionProvider)!.requestId,
        AutoIPoETestData.id,
      );
      verifyNever(
        () => service.submit(
          any(),
          settings: any(named: 'settings'),
          resetFirst: any(named: 'resetFirst'),
        ),
      );
    },
  );
  test('concurrent clicks do not queue a second submission', () async {
    await container.read(autoIPoEDataProvider.future);
    final stored = Completer<void>();
    when(() => service.storeSubmission(any())).thenAnswer((_) => stored.future);
    when(
      () => service.submit(
        any(),
        settings: AutoIPoETestData.settings,
        resetFirst: false,
      ),
    ).thenAnswer((_) async => const AutoIPoEReceipt(accepted: true));
    final notifier = container.read(autoIPoEDataProvider.notifier);
    final first = notifier.apply(AutoIPoETestData.settings);
    await expectLater(
      notifier.apply(AutoIPoETestData.settings),
      throwsA(isA<InvalidInputError>()),
    );
    stored.complete();
    await first;
    verify(
      () => service.submit(
        any(),
        settings: AutoIPoETestData.settings,
        resetFirst: false,
      ),
    ).called(1);
  });
  test(
      'storage failure prevents dispatch and server rejection permits explicit correction',
      () async {
    await container.read(autoIPoEDataProvider.future);
    when(() => service.storeSubmission(any())).thenThrow(const StorageError());
    final notifier = container.read(autoIPoEDataProvider.notifier);
    await expectLater(
      notifier.apply(AutoIPoETestData.settings),
      throwsA(isA<StorageError>()),
    );
    verifyNever(
      () => service.submit(
        any(),
        settings: AutoIPoETestData.settings,
        resetFirst: false,
      ),
    );
    when(() => service.storeSubmission(any())).thenAnswer((_) async {});
    when(
      () => service.submit(
        any(),
        settings: AutoIPoETestData.settings,
        resetFirst: false,
      ),
    ).thenAnswer((_) async => const AutoIPoEReceipt(accepted: false));
    await notifier.apply(AutoIPoETestData.settings);
    expect(container.read(autoIPoESubmissionProvider), isNotNull);
    expect(container.read(autoIPoERejectionProvider), 'ErrorRequestRejected');
    final id = container.read(autoIPoESubmissionProvider)!.requestId;
    when(() => service.resolvePending(any())).thenAnswer(
      (_) async => AutoIPoEReceipt(
        accepted: false,
        cancelled: true,
        requestId: id,
        operationId: id,
      ),
    );
    await notifier.resolvePending();
    expect(container.read(autoIPoESubmissionProvider), isNull);
    expect(container.read(autoIPoERejectionProvider), isNull);
  });
  test(
    'lost resolution response keeps UUID and existing job is only polled',
    () async {
      const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
      when(() => service.loadSubmission()).thenAnswer((_) async => submission);
      await container.read(autoIPoEDataProvider.future);
      final notifier = container.read(autoIPoEDataProvider.notifier);
      when(() => service.resolvePending(any()))
          .thenThrow(const ConnectivityError());
      await expectLater(
        notifier.resolvePending(),
        throwsA(isA<ConnectivityError>()),
      );
      expect(container.read(autoIPoESubmissionProvider), submission);
      when(() => service.resolvePending(any())).thenAnswer(
        (_) async => AutoIPoEReceipt(
          accepted: true,
          requestId: submission.requestId,
          operationId: submission.requestId,
          status: AutoIPoETestData.snapshot(
            requestId: submission.requestId,
            busy: true,
          ).runtime,
        ),
      );
      await notifier.resolvePending();
      expect(container.read(autoIPoESubmissionProvider), submission);
      verifyNever(() => service.clearSubmission());
      verifyNever(
        () => service.submit(
          any(),
          settings: any(named: 'settings'),
          resetFirst: any(named: 'resetFirst'),
        ),
      );
    },
  );

  test(
    'recovery never publishes a historical successful receipt as current',
    () async {
      const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
      when(() => service.loadSubmission()).thenAnswer((_) async => submission);
      await container.read(autoIPoEDataProvider.future);
      final historical = AutoIPoETestData.snapshot(
        requestId: submission.requestId,
        exitCode: 0,
        verified: true,
      );
      when(() => service.resolvePending(any())).thenAnswer(
        (_) async => AutoIPoEReceipt(
          accepted: true,
          requestId: submission.requestId,
          operationId: submission.requestId,
          exitCode: 0,
          status: historical.runtime,
        ),
      );
      final fresh = Completer<AutoIPoESnapshot>();
      when(() => service.fetch()).thenAnswer((_) => fresh.future);
      final seen = <AutoIPoEOutcome>[];
      final subscription = container.listen(autoIPoEDataProvider, (_, value) {
        final snapshot = value.valueOrNull;
        if (snapshot != null) seen.add(snapshot.outcomeFor(submission));
      });
      final resolving =
          container.read(autoIPoEDataProvider.notifier).resolvePending();
      await Future<void>.delayed(Duration.zero);
      expect(seen, isNot(contains(AutoIPoEOutcome.succeeded)));
      fresh.complete(
        AutoIPoETestData.snapshot(
          requestId: submission.requestId,
          exitCode: 1,
          phase: 'failed',
        ),
      );
      await resolving;
      expect(seen, isNot(contains(AutoIPoEOutcome.succeeded)));
      expect(
        container
            .read(autoIPoEDataProvider)
            .requireValue
            .outcomeFor(submission),
        AutoIPoEOutcome.failed,
      );
      expect(container.read(autoIPoESubmissionProvider), submission);
      subscription.close();
    },
  );
  test(
      'historical terminal recovery releases old UUID only after fresh newer Status',
      () async {
    const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
    when(() => service.loadSubmission()).thenAnswer((_) async => submission);
    await container.read(autoIPoEDataProvider.future);
    final historical = AutoIPoETestData.snapshot(
      requestId: submission.requestId,
      exitCode: 0,
      verified: true,
    );
    when(() => service.resolvePending(any())).thenAnswer(
      (_) async => AutoIPoEReceipt(
        accepted: true,
        requestId: submission.requestId,
        operationId: submission.requestId,
        exitCode: 0,
        status: historical.runtime,
      ),
    );
    when(() => service.fetch()).thenThrow(const ConnectivityError());
    await container.read(autoIPoEDataProvider.notifier).resolvePending();
    expect(container.read(autoIPoESubmissionProvider), submission);
    verifyNever(() => service.clearSubmission());
    final newer = AutoIPoETestData.snapshot(requestId: 'newer-job', busy: true);
    when(() => service.fetch()).thenAnswer((_) async => newer);
    await container.read(autoIPoEDataProvider.notifier).resolvePending();
    expect(container.read(autoIPoESubmissionProvider), isNull);
    expect(container.read(autoIPoEDataProvider).requireValue, newer);
    verify(() => service.clearSubmission()).called(1);
    verifyNever(
      () => service.submit(
        any(),
        settings: any(named: 'settings'),
        resetFirst: any(named: 'resetFirst'),
      ),
    );
  });
  test(
    'unreserved rejection retains current runtime and reports its own error',
    () async {
      final current = await container.read(autoIPoEDataProvider.future);
      final otherJob = AutoIPoETestData.snapshot(
        requestId: 'other',
        exitCode: 1,
        phase: 'failed',
      );
      when(
        () => service.submit(
          any(),
          settings: AutoIPoETestData.settings,
          resetFirst: false,
        ),
      ).thenAnswer(
        (_) async => AutoIPoEReceipt(
          accepted: false,
          error: 'ErrorMissingStandardIPIPSettings',
          status: otherJob.runtime,
        ),
      );
      await container
          .read(autoIPoEDataProvider.notifier)
          .apply(AutoIPoETestData.settings);
      expect(container.read(autoIPoEDataProvider).requireValue, current);
      expect(
        container.read(autoIPoERejectionProvider),
        'ErrorMissingStandardIPIPSettings',
      );
      expect(container.read(autoIPoESubmissionProvider), isNotNull);
    },
  );
  testWidgets(
    'reload automatically fences an unseen UUID without Apply or Reset',
    (tester) async {
      const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
      when(() => service.loadSubmission()).thenAnswer((_) async => submission);
      when(() => service.resolvePending(submission)).thenAnswer(
        (_) async => const AutoIPoEReceipt(
          accepted: false,
          cancelled: true,
          requestId: AutoIPoETestData.id,
          operationId: AutoIPoETestData.id,
        ),
      );
      await container.read(autoIPoEDataProvider.future);
      expect(container.read(autoIPoESubmissionProvider), submission);
      await tester.pump(const Duration(seconds: 3));
      expect(container.read(autoIPoESubmissionProvider), isNull);
      verify(() => service.clearSubmission()).called(1);
      verifyNever(
        () => service.submit(
          any(),
          settings: any(named: 'settings'),
          resetFirst: any(named: 'resetFirst'),
        ),
      );
    },
  );

  testWidgets('reload of a running matching job only polls', (tester) async {
    const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
    when(() => service.loadSubmission()).thenAnswer((_) async => submission);
    when(() => service.fetch()).thenAnswer(
      (_) async =>
          AutoIPoETestData.snapshot(requestId: AutoIPoETestData.id, busy: true),
    );
    await container.read(autoIPoEDataProvider.future);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(autoIPoESubmissionProvider), submission);
    verifyNever(() => service.resolvePending(any()));
    verifyNever(() => service.clearSubmission());
    verifyNever(
      () => service.submit(
        any(),
        settings: any(named: 'settings'),
        resetFirst: any(named: 'resetFirst'),
      ),
    );
    container.dispose();
    container = ProviderContainer();
  });

  testWidgets(
    'lost recovery replies retain UUID and stop after bounded checks',
    (tester) async {
      const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
      when(() => service.loadSubmission()).thenAnswer((_) async => submission);
      when(() => service.resolvePending(submission))
          .thenThrow(const ConnectivityError());
      await container.read(autoIPoEDataProvider.future);
      for (var i = 0; i < 121; i++) {
        await tester.pump(const Duration(seconds: 3));
      }
      expect(container.read(autoIPoESubmissionProvider), submission);
      expect(
        container.read(autoIPoEDataProvider).error,
        isA<ConnectivityError>(),
      );
      verify(() => service.resolvePending(submission)).called(3);
      verifyNever(() => service.clearSubmission());
      verifyNever(
        () => service.submit(
          any(),
          settings: any(named: 'settings'),
          resetFirst: any(named: 'resetFirst'),
        ),
      );
    },
  );

  testWidgets('automatic recovery cannot clear a different request ID', (
    tester,
  ) async {
    const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
    when(() => service.loadSubmission()).thenAnswer((_) async => submission);
    when(() => service.resolvePending(submission)).thenAnswer(
      (_) async => const AutoIPoEReceipt(
        accepted: false,
        cancelled: true,
        requestId: 'different',
        operationId: 'different',
      ),
    );
    await container.read(autoIPoEDataProvider.future);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(autoIPoESubmissionProvider), submission);
    verifyNever(() => service.clearSubmission());
    container.dispose();
    container = ProviderContainer();
  });

  test('a changed session service rebuilds an early failed read', () async {
    final ready = StateProvider<bool>((ref) => false);
    container.dispose();
    container = ProviderContainer(
      overrides: [
        autoIPoEServiceProvider.overrideWith((ref) {
          if (!ref.watch(ready)) throw const ServiceNotInitializedError();
          return service;
        }),
      ],
    );
    await expectLater(
      container.read(autoIPoEDataProvider.future),
      throwsA(isA<ServiceNotInitializedError>()),
    );
    container.read(ready.notifier).state = true;
    final snapshot = await container.read(autoIPoEDataProvider.future);
    expect(snapshot, AutoIPoETestData.snapshot());
    verifyNever(
      () => service.submit(
        any(),
        settings: any(named: 'settings'),
        resetFirst: any(named: 'resetFirst'),
      ),
    );
  });

  testWidgets('transient initial reads retry without a WAN command', (
    tester,
  ) async {
    var calls = 0;
    when(() => service.fetch()).thenAnswer((_) async {
      if (++calls < 2) throw const ConnectivityError();
      return AutoIPoETestData.snapshot();
    });
    final subscription = container.listen(autoIPoEDataProvider, (_, __) {});
    addTearDown(subscription.close);
    await expectLater(
      container.read(autoIPoEDataProvider.future),
      throwsA(isA<ConnectivityError>()),
    );
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(autoIPoEDataProvider).hasValue, true);
    verifyNever(
      () => service.submit(
        any(),
        settings: any(named: 'settings'),
        resetFirst: any(named: 'resetFirst'),
      ),
    );
  });
  testWidgets('automatic historical completion preserves a newer running job', (
    tester,
  ) async {
    const submission = AutoIPoESubmission(AutoIPoETestData.id, reset: false);
    final newer = AutoIPoETestData.snapshot(requestId: 'newer-job', busy: true);
    final historical = AutoIPoETestData.snapshot(
      requestId: submission.requestId,
      exitCode: 0,
      verified: true,
    );
    when(() => service.loadSubmission()).thenAnswer((_) async => submission);
    when(() => service.fetch()).thenAnswer((_) async => newer);
    when(() => service.resolvePending(submission)).thenAnswer(
      (_) async => AutoIPoEReceipt(
        accepted: true,
        requestId: submission.requestId,
        operationId: submission.requestId,
        exitCode: 0,
        status: historical.runtime,
      ),
    );
    await container.read(autoIPoEDataProvider.future);
    await tester.pump(const Duration(seconds: 3));
    expect(container.read(autoIPoESubmissionProvider), isNull);
    expect(container.read(autoIPoEDataProvider).requireValue, newer);
    verifyNever(
      () => service.submit(
        any(),
        settings: any(named: 'settings'),
        resetFirst: any(named: 'resetFirst'),
      ),
    );
  });

  test(
    'session change during storage never dispatches to the replacement client',
    () async {
      final version = StateProvider<int>((ref) => 0);
      final replacement = MockService();
      when(() => replacement.loadSubmission()).thenAnswer((_) async => null);
      when(() => replacement.fetch())
          .thenAnswer((_) async => AutoIPoETestData.snapshot());
      container.dispose();
      container = ProviderContainer(
        overrides: [
          autoIPoEServiceProvider.overrideWith((ref) {
            return ref.watch(version) == 0 ? service : replacement;
          }),
        ],
      );
      await container.read(autoIPoEDataProvider.future);
      final stored = Completer<void>();
      when(() => service.storeSubmission(any()))
          .thenAnswer((_) => stored.future);
      final submitting = container
          .read(autoIPoEDataProvider.notifier)
          .apply(AutoIPoETestData.settings);
      await Future<void>.delayed(Duration.zero);
      container.read(version.notifier).state++;
      await container.read(autoIPoEDataProvider.future);
      stored.complete();
      await submitting;
      verifyNever(
        () => service.submit(
          any(),
          settings: any(named: 'settings'),
          resetFirst: any(named: 'resetFirst'),
        ),
      );
    },
  );
}
