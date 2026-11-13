import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/page/instant_setup/models/troubleshooting_phase.dart';
import 'package:privacy_gui/page/instant_setup/models/pnp_isp_config.dart';
import 'package:privacy_gui/page/instant_setup/providers/internet_troubleshooting_provider.dart';
import 'package:privacy_gui/page/instant_setup/services/internet_troubleshooting_service.dart';

class MockInternetTroubleshootingService extends Mock
    implements InternetTroubleshootingService {}

class FakePnpIspConfig extends Fake implements PnpIspConfig {}

/// The no-internet troubleshooting flow's state (#1511 P1).
///
/// The retry, modem-restart and ISP-save cases moved here from
/// `pnp_notifier_test.dart` with the code. Each keeps its scenario and its
/// verdict; what changed is that the verdict is troubleshooting's own phase
/// instead of a PnP one — "recovered" where PnP's notifier went on into the
/// wizard (`WizardConfiguring`), "read failure" where it landed on
/// `AdminReadFailure`, and "no internet" where it landed on `NoInternet`. Where
/// the user goes after a recovery or a read failure is the caller's ending, not
/// this state's, so these cases stop at the phase that hands over.
void main() {
  setUpAll(() {
    registerFallbackValue(FakePnpIspConfig());
  });

  late MockInternetTroubleshootingService mockService;

  setUp(() {
    mockService = MockInternetTroubleshootingService();
  });

  /// A container holding the flow open, the way the hub page does: the state is
  /// `autoDispose`, and nothing but a listener keeps it for the length of a run.
  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        internetTroubleshootingServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    container.listen(internetTroubleshootingProvider, (_, __) {});
    return container;
  }

  test('a run starts on the hub, with no error to show', () {
    final container = createContainer();

    expect(container.read(internetTroubleshootingProvider),
        const TroubleshootingNoInternet());
    container.dispose();
  });

  group('retryInternetCheck', () {
    test('retryInternetCheck re-checks internet and transitions accordingly',
        () async {
      when(() => mockService.checkInternetConnected())
          .thenAnswer((_) async => true);

      final container = createContainer();
      final notifier = container.read(internetTroubleshootingProvider.notifier);

      await notifier.retryInternetCheck();

      final phase = container.read(internetTroubleshootingProvider);
      expect(phase, isA<TroubleshootingRecovered>());
      container.dispose();
    });
  });

  // #1098, the same split on the modem-restart path. The poll used to swallow
  // every failed read and end on "no internet", so a router that could not be
  // read for all 30 attempts was shown as "no internet". Only the LAST attempt
  // decides: earlier failures are expected while the router comes back.
  group('modem restart poll (#1098)', () {
    /// Runs the 150 s countdown and the 30 × 5 s poll to the end.
    TroubleshootingPhase runModemRestart(ProviderContainer container) {
      late TroubleshootingPhase phase;
      fakeAsync((async) {
        container
            .read(internetTroubleshootingProvider.notifier)
            .startModemRestartCountdown();
        async.elapse(const Duration(seconds: 150 + 30 * 5 + 1));
        phase = container.read(internetTroubleshootingProvider);
      });
      return phase;
    }

    test('every attempt failing to read ends on a read failure', () {
      when(() => mockService.checkInternetConnected())
          .thenThrow(const InvalidInputError(code: 9998, detail: 'missing'));
      final container = createContainer();

      final phase = runModemRestart(container);

      expect(phase, isA<TroubleshootingReadFailure>(),
          reason:
              'a router that never answered is not a confirmed no-internet');
      expect((phase as TroubleshootingReadFailure).code, 9998);
      verify(() => mockService.checkInternetConnected()).called(30);
      container.dispose();
    });

    test('a router that answers "no internet" ends on no internet', () {
      when(() => mockService.checkInternetConnected())
          .thenAnswer((_) async => false);
      final container = createContainer();

      expect(runModemRestart(container), isA<TroubleshootingNoInternet>());
      container.dispose();
    });

    test('"no internet" followed by failed reads ends on a read failure', () {
      // The router answered, then stopped answering. The last attempt is what
      // the user is left with, so an earlier "no internet" does not stand.
      var calls = 0;
      when(() => mockService.checkInternetConnected()).thenAnswer((_) async {
        calls++;
        if (calls <= 20) return false;
        throw const InvalidInputError(code: 9998, detail: 'missing');
      });
      final container = createContainer();

      expect(runModemRestart(container), isA<TroubleshootingReadFailure>());
      container.dispose();
    });

    test('failed reads followed by "no internet" end on no internet', () {
      // The router is unreadable while it reboots, then answers.
      var calls = 0;
      when(() => mockService.checkInternetConnected()).thenAnswer((_) async {
        calls++;
        if (calls <= 10) {
          throw const InvalidInputError(code: 9998, detail: 'missing');
        }
        return false;
      });
      final container = createContainer();

      expect(runModemRestart(container), isA<TroubleshootingNoInternet>());
      container.dispose();
    });

    test('a run that is left stops counting down', () {
      // New with the move: the state is `autoDispose` now, so leaving the flow
      // mid-countdown disposes it. The loop must stop at its next tick rather
      // than count on — and then poll — for a page nobody is on.
      when(() => mockService.checkInternetConnected())
          .thenAnswer((_) async => false);
      final container = createContainer();

      fakeAsync((async) {
        container
            .read(internetTroubleshootingProvider.notifier)
            .startModemRestartCountdown();
        async.elapse(const Duration(seconds: 10));
        container.dispose();
        async.elapse(const Duration(seconds: 2));

        expect(async.pendingTimers, isEmpty,
            reason: 'a countdown still ticking after the run was left');
      });

      verifyNever(() => mockService.checkInternetConnected());
    });
  });

  group('saveIspWithProgress', () {
    test(
        'successful ISP save transitions through IspSaving then checks internet',
        () async {
      when(() => mockService.saveIspSettings(any())).thenAnswer((_) async {});
      when(() => mockService.checkInternetConnected())
          .thenAnswer((_) async => true);

      final container = createContainer();
      final notifier = container.read(internetTroubleshootingProvider.notifier);

      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '192.168.1.50',
        subnetMask: '255.255.255.0',
        defaultGateway: '192.168.1.1',
        dnsServer1: '8.8.8.8',
        dnsServer2: '8.8.4.4',
      );

      await notifier.saveIspWithProgress(config);

      verify(() => mockService.saveIspSettings(any())).called(1);
      final phase = container.read(internetTroubleshootingProvider);
      expect(phase, isA<TroubleshootingRecovered>());
      container.dispose();
    });

    // The error is carried typed since the move — `PnpState.errorMessage` held
    // `'$e'`, which the forms showed verbatim — so the form can localize it
    // (constitution §13.4).
    test('ISP save failure transitions back to no internet with error',
        () async {
      const failure = ConnectivityError(detail: 'WAN save failed');
      when(() => mockService.saveIspSettings(any())).thenThrow(failure);

      final container = createContainer();
      final notifier = container.read(internetTroubleshootingProvider.notifier);

      const config = PnpIspConfig(
        type: IspConnectionType.pppoe,
        pppUsername: 'user',
        pppPassword: 'pass',
      );

      await notifier.saveIspWithProgress(config);

      final phase = container.read(internetTroubleshootingProvider);
      expect(phase, isA<TroubleshootingNoInternet>());
      expect((phase as TroubleshootingNoInternet).saveError, same(failure));
      container.dispose();
    });

    test('a save that fails outside the service is still typed, not stranded',
        () async {
      // The mutation lock times out with a bare TimeoutException; the form must
      // leave its progress screen with something it can localize.
      final failure = Exception('lock timed out');
      when(() => mockService.saveIspSettings(any())).thenThrow(failure);

      final container = createContainer();
      await container
          .read(internetTroubleshootingProvider.notifier)
          .saveIspWithProgress(
              const PnpIspConfig(type: IspConnectionType.dhcp));

      final phase = container.read(internetTroubleshootingProvider)
          as TroubleshootingNoInternet;
      expect(phase.saveError, isA<UnexpectedError>());
      expect(
          (phase.saveError! as UnexpectedError).originalError, same(failure));
      container.dispose();
    });

    test('the WAN the forms prefill from is read again after a save', () async {
      // The router's WAN is not what the hub read once a save has been sent.
      when(() => mockService.fetchCurrentWanSettings())
          .thenAnswer((_) async => null);
      when(() => mockService.saveIspSettings(any())).thenAnswer((_) async {});
      when(() => mockService.checkInternetConnected())
          .thenAnswer((_) async => false);

      final container = createContainer();
      container.listen(troubleshootingWanPrefillProvider, (_, __) {});
      await container.read(troubleshootingWanPrefillProvider.future);
      verify(() => mockService.fetchCurrentWanSettings()).called(1);

      await container
          .read(internetTroubleshootingProvider.notifier)
          .saveIspWithProgress(
              const PnpIspConfig(type: IspConnectionType.dhcp));
      await container.read(troubleshootingWanPrefillProvider.future);

      verify(() => mockService.fetchCurrentWanSettings()).called(1);
      container.dispose();
    });

    test('DHCP ISP save calls saveIspSettings with dhcp type', () async {
      when(() => mockService.saveIspSettings(any())).thenAnswer((_) async {});
      when(() => mockService.checkInternetConnected())
          .thenAnswer((_) async => true);

      final container = createContainer();
      final notifier = container.read(internetTroubleshootingProvider.notifier);

      const config = PnpIspConfig(type: IspConnectionType.dhcp);

      await notifier.saveIspWithProgress(config);

      verify(() => mockService.saveIspSettings(any())).called(1);
      final phase = container.read(internetTroubleshootingProvider);
      expect(phase, isA<TroubleshootingRecovered>());
      container.dispose();
    });

    test('ISP save success but no internet transitions to no internet',
        () async {
      when(() => mockService.saveIspSettings(any())).thenAnswer((_) async {});
      when(() => mockService.checkInternetConnected())
          .thenAnswer((_) async => false);

      final container = createContainer();
      final notifier = container.read(internetTroubleshootingProvider.notifier);

      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '10.0.0.5',
        subnetMask: '255.255.255.0',
        defaultGateway: '10.0.0.1',
      );

      await notifier.saveIspWithProgress(config);

      verify(() => mockService.saveIspSettings(any())).called(1);
      final phase = container.read(internetTroubleshootingProvider);
      expect(phase, isA<TroubleshootingNoInternet>());
      container.dispose();
    });

    // Regression for #1098: the ISP save WRITE succeeds, but the trailing
    // internet check READ fails (USP GET returned empty). This must land on a
    // read failure, NOT no internet — distinct from a genuine no-internet
    // (checkInternetConnected returns false) and from a save write failure
    // (which stays on no internet + saveError, tested above).
    test('ISP save success but check read failure → read failure', () async {
      when(() => mockService.saveIspSettings(any())).thenAnswer((_) async {});
      when(() => mockService.checkInternetConnected())
          .thenThrow(const InvalidInputError(code: 9998, detail: 'missing'));

      final container = createContainer();
      final notifier = container.read(internetTroubleshootingProvider.notifier);

      const config = PnpIspConfig(
        type: IspConnectionType.staticIp,
        staticIpAddress: '10.0.0.5',
        subnetMask: '255.255.255.0',
        defaultGateway: '10.0.0.1',
      );

      await notifier.saveIspWithProgress(config);

      verify(() => mockService.saveIspSettings(any())).called(1);
      final phase = container.read(internetTroubleshootingProvider);
      expect(phase, isA<TroubleshootingReadFailure>());
      expect((phase as TroubleshootingReadFailure).code, 9998);
      container.dispose();
    });
  });
}
