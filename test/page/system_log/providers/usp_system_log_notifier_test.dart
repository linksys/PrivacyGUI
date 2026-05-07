import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/system_log/models/log_file_ui_model.dart';
import 'package:privacy_gui/page/system_log/providers/usp_system_log_notifier.dart';
import 'package:privacy_gui/page/system_log/services/usp_system_log_service.dart';

class MockUspSystemLogService extends Mock implements UspSystemLogService {}

void main() {
  late MockUspSystemLogService mockService;

  final log1 = LogFileUIModel(
    instancePath: 'Device.DeviceInfo.VendorLogFile.1.',
    name: 'syslog',
    maximumSize: 524288,
    persistent: true,
  );
  final log2 = LogFileUIModel(
    instancePath: 'Device.DeviceInfo.VendorLogFile.2.',
    name: 'kernel',
    maximumSize: 0,
    persistent: false,
  );

  setUp(() {
    mockService = MockUspSystemLogService();
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspSystemLogServiceProvider.overrideWithValue(mockService),
      ],
    );
    return container;
  }

  group('UspSystemLogNotifier', () {
    test('build returns loading then data', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => [log1, log2]);
      final container = createContainer();

      // Initially loading.
      final initial = container.read(uspSystemLogProvider);
      expect(initial.isLoading, isTrue);

      // After async completes.
      await container.read(uspSystemLogProvider.future);
      final state = container.read(uspSystemLogProvider);
      expect(state.valueOrNull, hasLength(2));
      expect(state.valueOrNull![0].name, 'syslog');
      expect(state.valueOrNull![1].name, 'kernel');
      container.dispose();
    });

    test('build error sets AsyncError', () async {
      when(() => mockService.fetch()).thenThrow(Exception('fetch failed'));
      final container = createContainer();

      try {
        await container.read(uspSystemLogProvider.future);
      } catch (_) {}

      final state = container.read(uspSystemLogProvider);
      expect(state.hasError, isTrue);
      expect(state.error.toString(), contains('fetch failed'));
      container.dispose();
    });

    test('build returns empty list when no logs', () async {
      when(() => mockService.fetch()).thenAnswer((_) async => []);
      final container = createContainer();

      await container.read(uspSystemLogProvider.future);
      final state = container.read(uspSystemLogProvider);
      expect(state.valueOrNull, isEmpty);
      container.dispose();
    });

    test('build sets AsyncError with ServiceError when service throws',
        () async {
      when(() => mockService.fetch())
          .thenThrow(const NetworkError(message: 'timeout'));
      final container = createContainer();

      try {
        await container.read(uspSystemLogProvider.future);
      } catch (_) {}

      final state = container.read(uspSystemLogProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<NetworkError>());
      expect(state.error.toString(), 'Network error: timeout');
      container.dispose();
    });
  });
}
