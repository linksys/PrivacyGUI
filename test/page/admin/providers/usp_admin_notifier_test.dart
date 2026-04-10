import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/_shared/models/time_settings_ui_model.dart';
import 'package:privacy_gui/page/admin/models/admin_ui_models.dart';
import 'package:privacy_gui/page/admin/providers/time_data_provider.dart';
import 'package:privacy_gui/page/admin/providers/usp_admin_notifier.dart';
import 'package:privacy_gui/page/admin/services/usp_admin_service.dart';

class MockUspClient extends Mock implements UspClient {}

class MockUspAdminService extends Mock implements UspAdminService {}

/// Test-only time data notifier returning canned data.
class _TestTimeDataNotifier extends TimeDataNotifier {
  final TimeData _data;
  _TestTimeDataNotifier(this._data);

  @override
  Future<TimeData> build() async => _data;

  bool updateTimezoneCalled = false;

  @override
  Future<void> updateTimezone({
    String? localTimeZone,
    String? ntpServer1,
    String? ntpServer2,
    bool? enable,
  }) async {
    updateTimezoneCalled = true;
  }
}

void main() {
  late MockUspClient mockUsp;
  late MockUspAdminService mockAdminService;
  late _TestTimeDataNotifier testTimeNotifier;

  const testAdmin = AdminUserUIModel(
    instancePath: 'Device.Users.User.1.',
    username: 'admin',
    enable: true,
  );

  const testTimeSettings = TimeSettingsUIModel(
    enable: true,
    status: 'Synchronized',
    currentLocalTime: '2026-01-01T00:00:00',
    localTimeZone: 'US/Pacific',
    ntpServer1: 'pool.ntp.org',
    ntpServer2: '',
  );

  final testTimeData = TimeData(model: testTimeSettings);

  setUp(() {
    mockUsp = MockUspClient();
    mockAdminService = MockUspAdminService();
    testTimeNotifier = _TestTimeDataNotifier(testTimeData);

    when(() => mockUsp.isAuthenticated).thenReturn(true);
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        uspAdminServiceProvider.overrideWithValue(mockAdminService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        timeDataProvider.overrideWith(() => testTimeNotifier),
      ],
    );
    return container;
  }

  group('UspAdminNotifier', () {
    test('build fetches admin user and time settings', () async {
      when(() => mockAdminService.fetchAdmin())
          .thenAnswer((_) async => testAdmin);
      final container = createContainer();

      final state = await container.read(uspAdminProvider.future);
      expect(state.adminUser.username, 'admin');
      expect(state.adminUser.instancePath, 'Device.Users.User.1.');
      expect(state.timeSettings.localTimeZone, 'US/Pacific');
      container.dispose();
    });

    test('build error sets AsyncError', () async {
      when(() => mockAdminService.fetchAdmin())
          .thenThrow(Exception('admin fetch failed'));
      final container = createContainer();

      try {
        await container.read(uspAdminProvider.future);
      } catch (_) {}

      final state = container.read(uspAdminProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('admin fetch failed'));
      container.dispose();
    });

    test('setAdminPassword calls service with correct path', () async {
      when(() => mockAdminService.fetchAdmin())
          .thenAnswer((_) async => testAdmin);
      when(() => mockAdminService.updatePassword(
            instancePath: any(named: 'instancePath'),
            newPassword: any(named: 'newPassword'),
          )).thenAnswer((_) async {});

      final container = createContainer();
      await container.read(uspAdminProvider.future);

      await container
          .read(uspAdminProvider.notifier)
          .setAdminPassword('new123');

      verify(() => mockAdminService.updatePassword(
            instancePath: 'Device.Users.User.1.',
            newPassword: 'new123',
          )).called(1);
      container.dispose();
    });

    test('updateTimezone delegates to timeDataProvider notifier', () async {
      when(() => mockAdminService.fetchAdmin())
          .thenAnswer((_) async => testAdmin);
      final container = createContainer();
      await container.read(uspAdminProvider.future);

      await container.read(uspAdminProvider.notifier).updateTimezone(
            localTimeZone: 'Asia/Tokyo',
          );

      expect(testTimeNotifier.updateTimezoneCalled, isTrue);
      container.dispose();
    });

    test('reboot calls USP operate Device.Reboot()', () async {
      when(() => mockAdminService.fetchAdmin())
          .thenAnswer((_) async => testAdmin);
      when(() => mockUsp.operate(any())).thenAnswer((_) async => {});

      final container = createContainer();
      await container.read(uspAdminProvider.future);

      await container.read(uspAdminProvider.notifier).reboot();

      verify(() => mockUsp.operate('Device.Reboot()')).called(1);
      container.dispose();
    });

    test('factoryReset calls USP operate Device.FactoryReset()', () async {
      when(() => mockAdminService.fetchAdmin())
          .thenAnswer((_) async => testAdmin);
      when(() => mockUsp.operate(any())).thenAnswer((_) async => {});

      final container = createContainer();
      await container.read(uspAdminProvider.future);

      await container.read(uspAdminProvider.notifier).factoryReset();

      verify(() => mockUsp.operate('Device.FactoryReset()')).called(1);
      container.dispose();
    });
  });
}
