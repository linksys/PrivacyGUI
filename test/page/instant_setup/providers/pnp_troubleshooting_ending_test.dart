import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/models/device_info.dart';
import 'package:privacy_gui/core/session/providers/session_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_troubleshooting_ending.dart';
import 'package:privacy_gui/page/instant_setup/services/pnp_status_service.dart';
import 'package:privacy_gui/route/constants.dart';

class MockPnpStatusService extends Mock implements PnpStatusService {}

/// Mountable session notifier that records [saveSelectedNetwork] calls.
///
/// A plain mocktail mock cannot be mounted by Riverpod (it lacks the internal
/// `_setElement` hook), so the session is this spy instead.
class SpySessionNotifier extends Notifier<SessionState>
    implements SessionNotifier {
  SpySessionNotifier({this.serialNumber});

  final String? serialNumber;
  final List<({String sn, String networkId})> savedNetworks = [];

  @override
  SessionState build() => SessionState(
        deviceInfo: serialNumber == null
            ? null
            : NodeDeviceInfo(
                modelNumber: 'M60TB',
                firmwareVersion: '2.0.4',
                description: '',
                firmwareDate: '',
                manufacturer: 'Linksys',
                serialNumber: serialNumber!,
                hardwareVersion: '1',
              ),
      );

  @override
  Future<void> saveSelectedNetwork(String sn, String networkId) async {
    savedNetworks.add((sn: sn, networkId: networkId));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// PnP's ending for the no-internet troubleshooting flow (#1511 P1).
///
/// The "continue without internet" cases moved here from `pnp_notifier_test.dart`
/// (`bypassToDashboard`) with their assertions; what changed is where the serial
/// number comes from. It was PnP's flow state, which a caller-supplied ending
/// must not depend on — after #1511 P3 that state is gone once the user has left
/// PnP for troubleshooting — so it is now the session's, which is the same
/// router's serial and the one `_prepare` checked PnP against.
void main() {
  late MockPnpStatusService mockPnpStatusService;

  setUp(() {
    mockPnpStatusService = MockPnpStatusService();
  });

  ProviderContainer createContainer(SpySessionNotifier session) {
    return ProviderContainer(
      overrides: [
        pnpStatusServiceProvider.overrideWithValue(mockPnpStatusService),
        sessionProvider.overrideWith(() => session),
      ],
    );
  }

  test('a recovered run goes back to PnP\'s entry, which re-runs its check',
      () {
    final container =
        createContainer(SpySessionNotifier(serialNumber: 'SN123'));

    expect(container.read(pnpTroubleshootingEndingProvider).exitLocation,
        RoutePath.pnp);
    container.dispose();
  });

  group('continue without internet', () {
    test('acknowledges PnP and saves selected network when SN is present',
        () async {
      when(() => mockPnpStatusService.acknowledge(any()))
          .thenAnswer((_) async {});
      final spySession = SpySessionNotifier(serialNumber: 'SN123');
      final container = createContainer(spySession);

      final destination = await container
          .read(pnpTroubleshootingEndingProvider)
          .continueWithoutInternet!();

      verify(() => mockPnpStatusService.acknowledge('SN123')).called(1);
      expect(spySession.savedNetworks, [(sn: 'SN123', networkId: '')]);
      expect(destination, RoutePath.uspDashboard);
      container.dispose();
    });

    test('skips acknowledge when serial number is missing', () async {
      final container = createContainer(SpySessionNotifier());

      final destination = await container
          .read(pnpTroubleshootingEndingProvider)
          .continueWithoutInternet!();

      verifyNever(() => mockPnpStatusService.acknowledge(any()));
      expect(destination, RoutePath.uspDashboard,
          reason: 'an escape hatch lets the user through either way');
      container.dispose();
    });

    // The escape hatch must never throw — a failed acknowledge/save must not
    // trap the user on the no-internet page. The view navigates regardless.
    test('does not throw when acknowledge fails', () async {
      when(() => mockPnpStatusService.acknowledge(any()))
          .thenThrow(Exception('TR-181 write failed'));
      final container =
          createContainer(SpySessionNotifier(serialNumber: 'SN123'));

      // Must complete normally (no throw) despite acknowledge failing.
      await expectLater(
        container
            .read(pnpTroubleshootingEndingProvider)
            .continueWithoutInternet!(),
        completion(RoutePath.uspDashboard),
      );
      container.dispose();
    });
  });
}
