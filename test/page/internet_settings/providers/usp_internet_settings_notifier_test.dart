import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_auth_coordinator.dart';
import 'package:privacy_gui/core/usp/providers/usp_mutation_lock.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/providers/sse_providers.dart';
import 'package:privacy_gui/core/usp/services/sse_manager.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/internet_settings/models/internet_settings_read_only_info.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_internet_settings_form.dart';
import 'package:privacy_gui/page/internet_settings/models/usp_wan_connection_type.dart';
import 'package:privacy_gui/page/internet_settings/providers/usp_internet_settings_notifier.dart';
import 'package:privacy_gui/page/internet_settings/services/usp_internet_settings_service.dart';

class MockUspClient extends Mock implements UspClient {}

class MockUspInternetSettingsService extends Mock
    implements UspInternetSettingsService {}

class MockUspAuthCoordinator extends Mock implements UspAuthCoordinator {}

class MockSseManager extends Mock implements SseManager {}

void main() {
  late MockUspClient mockUsp;
  late MockUspInternetSettingsService mockService;
  late MockUspAuthCoordinator mockAuthCoordinator;
  late MockSseManager mockSseManager;

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
    mockUsp = MockUspClient();
    mockService = MockUspInternetSettingsService();
    mockAuthCoordinator = MockUspAuthCoordinator();
    mockSseManager = MockSseManager();
    when(() => mockUsp.isAuthenticated).thenReturn(true);
    when(() => mockSseManager.disconnect()).thenAnswer((_) async {});
  });

  ProviderContainer createContainer() {
    final container = ProviderContainer(
      overrides: [
        uspClientProvider.overrideWithValue(mockUsp),
        uspInternetSettingsServiceProvider.overrideWithValue(mockService),
        uspMutationLockProvider.overrideWithValue(UspMutationLock()),
        uspAuthCoordinatorProvider.overrideWithValue(mockAuthCoordinator),
        sseManagerProvider.overrideWithValue(mockSseManager),
      ],
    );
    container.listen(uspInternetSettingsProvider, (_, __) {});
    return container;
  }

  group('UspInternetSettingsNotifier', () {
    test('build returns initial loading state', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();

      final state = container.read(uspInternetSettingsProvider);
      expect(state.status.isLoading, isTrue);
      await Future.delayed(Duration.zero);
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
          .thenThrow(const NetworkError(detail: 'bridge unreachable'));
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspInternetSettingsProvider);
      expect(state.status.error, isA<NetworkError>());
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

    test('updateConnectionType to PPPoE clamps over-limit MTU to 1492',
        () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      // Initial MTU is 1500 (DHCP), which exceeds PPPoE's 1492 max.
      container
          .read(uspInternetSettingsProvider.notifier)
          .updateConnectionType(UspWanConnectionType.pppoe);

      final form =
          container.read(uspInternetSettingsProvider).settings.current.form;
      expect(form.connectionType, UspWanConnectionType.pppoe);
      expect(form.mtu, 1492);
      container.dispose();
    });

    test('updateConnectionType from bridge auto-fills MTU with type max',
        () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      // Bridge sets mtu = 0 (auto)...
      notifier.updateConnectionType(UspWanConnectionType.bridge);
      expect(
          container.read(uspInternetSettingsProvider).settings.current.form.mtu,
          0);

      // ...switching back to DHCP must not leave MTU empty; 0 is out of range
      // so it falls back to the type max (1500).
      notifier.updateConnectionType(UspWanConnectionType.dhcp);
      final form =
          container.read(uspInternetSettingsProvider).settings.current.form;
      expect(form.connectionType, UspWanConnectionType.dhcp);
      expect(form.mtu, 1500);
      container.dispose();
    });

    test('updateConnectionType keeps an in-range MTU unchanged', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      // 789 is valid for both DHCP and PPPoE (issue #1083 "last changed value").
      notifier.updateField((f) => f.copyWith(mtu: 789));
      notifier.updateConnectionType(UspWanConnectionType.pppoe);

      final form =
          container.read(uspInternetSettingsProvider).settings.current.form;
      expect(form.connectionType, UspWanConnectionType.pppoe);
      expect(form.mtu, 789);
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

    test(
        'save entering bridge disconnects SSE and skips the post-save re-fetch',
        () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      when(() => mockService.saveAll(any(), any())).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      notifier.enterEditMode();
      // Baseline is DHCP; switching to bridge is an entering-bridge transition.
      notifier.updateConnectionType(UspWanConnectionType.bridge);
      await notifier.save();

      // SSE is dropped so the recovery flow never fires on top of the dialog.
      verify(() => mockSseManager.disconnect()).called(1);
      // Only the initial build() fetch — save() must NOT re-fetch, because the
      // router is now unreachable on this origin (a re-fetch would time out and
      // surface a spurious error for a save that actually succeeded).
      verify(() => mockService.fetchSettings()).called(1);
      // Form still reflects the edited bridge value; state stays clean.
      final state = container.read(uspInternetSettingsProvider);
      expect(state.settings.current.form.connectionType,
          UspWanConnectionType.bridge);
      expect(state.status.isEditing, isFalse);
      expect(notifier.isDirty(), isFalse);
      container.dispose();
    });

    test('save for a non-bridge change re-fetches and does not disconnect SSE',
        () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      when(() => mockService.saveAll(any(), any())).thenAnswer((_) async {});

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      notifier.enterEditMode();
      // Stays DHCP — only an unrelated field changes.
      notifier.updateField((f) => f.copyWith(mtu: 9000));
      await notifier.save();

      verifyNever(() => mockSseManager.disconnect());
      // build() fetch + post-save re-fetch = 2 fetchSettings calls.
      verify(() => mockService.fetchSettings()).called(2);
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

    test('performSave rethrows ServiceError and clears isSaving', () async {
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);
      when(() => mockService.saveAll(any(), any()))
          .thenThrow(const NetworkError(detail: 'save failed'));

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final notifier = container.read(uspInternetSettingsProvider.notifier);
      notifier.updateField((f) => f.copyWith(mtu: 9000));

      await expectLater(notifier.save(), throwsA(isA<ServiceError>()));

      expect(
          container.read(uspInternetSettingsProvider).status.isSaving, isFalse);
      container.dispose();
    });

    // Regression: issue #1119. The provider must NOT gate its fetch on the raw
    // usp.isAuthenticated flag — in Remote Assistance that flag stays false by
    // design (authToken bypass), yet the data layer serves fine. Auth is
    // enforced by the router, not here.
    test('fetch proceeds when usp.isAuthenticated is false (RA bypass)',
        () async {
      when(() => mockUsp.isAuthenticated).thenReturn(false);
      when(() => mockService.fetchSettings())
          .thenAnswer((_) async => testFetchResult);

      final container = createContainer();
      await Future.delayed(Duration.zero);

      final state = container.read(uspInternetSettingsProvider);
      expect(state.status.error, isNull);
      expect(state.status.isLoading, isFalse);
      expect(state.settings.current.form.connectionType,
          UspWanConnectionType.dhcp);
      verify(() => mockService.fetchSettings()).called(1);
      container.dispose();
    });

    test('fetch throws ServiceNotInitializedError when usp is null', () async {
      final container = ProviderContainer(
        overrides: [
          uspClientProvider.overrideWithValue(null),
          uspInternetSettingsServiceProvider.overrideWithValue(mockService),
          uspMutationLockProvider.overrideWithValue(UspMutationLock()),
          uspAuthCoordinatorProvider.overrideWithValue(mockAuthCoordinator),
          sseManagerProvider.overrideWithValue(mockSseManager),
        ],
      );
      container.listen(uspInternetSettingsProvider, (_, __) {});
      await Future.delayed(Duration.zero);

      final state = container.read(uspInternetSettingsProvider);
      expect(state.status.error, isA<ServiceNotInitializedError>());
      container.dispose();
    });
  });
}
