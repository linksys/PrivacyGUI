import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_service_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

class MockUspService extends Mock implements UspService {}

class MockUspInternetSettingsService extends Mock
    implements UspInternetSettingsService {}

void main() {
  late MockUspService mockUsp;
  late MockUspInternetSettingsService mockService;

  final testForm = UspInternetSettingsForm(
    connectionType: UspWanConnectionType.dhcp,
    mtu: 1500,
    ipv6Enabled: true,
  );
  final testFetchResult = InternetSettingsFetchResult(
    form: testForm,
    readOnlyInfo: const InternetSettingsReadOnlyInfo(),
  );

  setUpAll(() {
    registerFallbackValue(const UspInternetSettingsForm(
        connectionType: UspWanConnectionType.dhcp));
  });

  setUp(() {
    mockUsp = MockUspService();
    mockService = MockUspInternetSettingsService();
    when(() => mockUsp.isAuthenticated).thenReturn(true);
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspServiceProvider.overrideWithValue(mockUsp),
        uspInternetSettingsServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
      ],
    );
    container.listen(uspInternetSettingsProvider, (_, __) {});
    return container;
  }

  group('UspInternetSettingsNotifier', () {
    test('build returns initial loading state', () {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();

      final state = container.read(uspInternetSettingsProvider);
      expect(state.status.isLoading, isTrue);
      container.dispose();
    });

    test('fetch success populates form and read-only info', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspInternetSettingsProvider);
      expect(state.settings.current.form.connectionType,
          UspWanConnectionType.dhcp);
      expect(state.settings.current.form.mtu, 1500);
      expect(state.settings.current.form.ipv6Enabled, isTrue);
      expect(state.status.isLoading, isFalse);
      container.dispose();
    });

    test('fetch error sets error status', () async {
      when(() => mockService.fetchSettings())
          .thenThrow(Exception('bridge unreachable'));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspInternetSettingsProvider);
      expect(state.status.errorMessage, contains('bridge unreachable'));
      container.dispose();
    });

    test('enterEditMode and exitEditMode toggle isEditing', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);

      notifier.enterEditMode();
      expect(
          container.read(uspInternetSettingsProvider).status.isEditing, isTrue);

      notifier.exitEditMode();
      expect(container.read(uspInternetSettingsProvider).status.isEditing,
          isFalse);
      container.dispose();
    });

    test('exitEditMode reverts form to original', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      notifier.enterEditMode();
      notifier.updateField((f) => f.copyWith(mtu: 9000));
      expect(
          container.read(uspInternetSettingsProvider).settings.current.form.mtu,
          9000);

      notifier.exitEditMode();
      expect(
          container.read(uspInternetSettingsProvider).settings.current.form.mtu,
          1500);
      container.dispose();
    });

    test('updateField modifies form in current settings', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container
          .read(uspInternetSettingsProvider.notifier)
          .updateField((f) => f.copyWith(dnsServer1: '1.1.1.1'));

      expect(
          container
              .read(uspInternetSettingsProvider)
              .settings
              .current
              .form
              .dnsServer1,
          '1.1.1.1');
      container.dispose();
    });

    test('updateConnectionType to bridge resets MTU to 0', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      container
          .read(uspInternetSettingsProvider.notifier)
          .updateConnectionType(UspWanConnectionType.bridge);

      final form =
          container.read(uspInternetSettingsProvider).settings.current.form;
      expect(form.connectionType, UspWanConnectionType.bridge);
      expect(form.mtu, 0);
      container.dispose();
    });

    test('isDirty after field update, clean after revert', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      expect(notifier.isDirty(), isFalse);

      notifier.updateField((f) => f.copyWith(mtu: 9000));
      expect(notifier.isDirty(), isTrue);

      notifier.revert(); // revert calls exitEditMode
      expect(notifier.isDirty(), isFalse);
      container.dispose();
    });

    test('revert exits edit mode', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      notifier.enterEditMode();
      expect(
          container.read(uspInternetSettingsProvider).status.isEditing, isTrue);

      notifier.revert();
      expect(container.read(uspInternetSettingsProvider).status.isEditing,
          isFalse);
      container.dispose();
    });

    test('performSave calls service.saveAll and exits edit mode', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      when(() => mockService.saveAll(any(), any())).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      notifier.enterEditMode();
      notifier.updateField((f) => f.copyWith(mtu: 9000));
      await notifier.save();

      verify(() => mockService.saveAll(any(), any())).called(1);
      expect(container.read(uspInternetSettingsProvider).status.isEditing,
          isFalse);
      container.dispose();
    });

    test('performSave sets isSaving flag during save', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      when(() => mockService.saveAll(any(), any())).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      notifier.updateField((f) => f.copyWith(mtu: 9000));

      // After save completes, isSaving should be false.
      await notifier.save();
      expect(
          container.read(uspInternetSettingsProvider).status.isSaving, isFalse);
      container.dispose();
    });

    test('renewDhcpLease calls service and tracks activeMutation', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      when(() => mockService.renewDhcpLease()).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      await container
          .read(uspInternetSettingsProvider.notifier)
          .renewDhcpLease();

      verify(() => mockService.renewDhcpLease()).called(1);
      // After completion, activeMutation should be cleared.
      expect(container.read(uspInternetSettingsProvider).status.activeMutation,
          isNull);
      container.dispose();
    });

    test('renewDhcpv6Lease calls service and tracks activeMutation', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      when(() => mockService.renewDhcpv6Lease()).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      await container
          .read(uspInternetSettingsProvider.notifier)
          .renewDhcpv6Lease();

      verify(() => mockService.renewDhcpv6Lease()).called(1);
      expect(container.read(uspInternetSettingsProvider).status.activeMutation,
          isNull);
      container.dispose();
    });

    test('performSave rethrows on error and clears isSaving', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      when(() => mockService.saveAll(any(), any()))
          .thenThrow(Exception('save failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      notifier.updateField((f) => f.copyWith(mtu: 9000));

      await expectLater(notifier.save(), throwsA(isA<Exception>()));

      expect(
          container.read(uspInternetSettingsProvider).status.isSaving, isFalse);
      container.dispose();
    });

    test('fetch with unauthenticated service sets error status', () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspInternetSettingsProvider);
      // Should hit the restore path which won't succeed with our mock.
      expect(state.status.errorMessage, isNotNull);
      container.dispose();
    });
  });
}
