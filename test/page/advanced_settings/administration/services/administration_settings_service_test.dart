import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/administration/services/administration_settings_service.dart';

import '../../../../common/unit_test_helper.dart';
import 'administration_settings_service_test_data.dart';

// Mock classes using mocktail
class MockRouterRepository extends Mock implements RouterRepository {}

class _FakeJNAPTransactionBuilder extends Fake
    implements JNAPTransactionBuilder {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeJNAPTransactionBuilder());
  });

  group('AdministrationSettingsService', () {
    late MockRouterRepository mockRepository;

    setUp(() {
      mockRepository = MockRouterRepository();
    });

    /// Helper to create mock ref
    createMockRef() => UnitTestHelper.createMockRef(
          routerRepository: mockRepository,
        );

    /// T008: Test successful fetch of all four settings
    test('fetches all four settings successfully', () async {
      final mockRef = createMockRef();

      // Arrange
      final mockResponse =
          AdministrationSettingsTestData.createSuccessfulTransaction(
        managementSettings: {
          'canManageUsingHTTP': true,
          'canManageUsingHTTPS': true,
          'isManageWirelesslySupported': true,
          'canManageRemotely': true,
        },
        upnpSettings: {
          'isUPnPEnabled': true,
          'canUsersConfigure': true,
          'canUsersDisableWANAccess': true,
        },
        expressForwardingSettings: {
          'isExpressForwardingSupported': true,
        },
      );

      when(() => mockRepository.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
          )).thenAnswer((_) async => mockResponse);

      final service = AdministrationSettingsService();

      // Act
      final result = await service.fetchAdministrationSettings(
        mockRef,
        forceRemote: false,
        updateStatusOnly: false,
      );

      // Assert
      expect(result, isNotNull);
      expect(result.managementSettings.canManageUsingHTTP, true);
      expect(result.isUPnPEnabled, true);
      expect(result.enabledALG, false);
      expect(result.isExpressForwardingSupported, true);
    });

    /// T009: Test ManagementSettings parsing
    test('parses ManagementSettings correctly', () async {
      final mockRef = createMockRef();

      final mockResponse =
          AdministrationSettingsTestData.createSuccessfulTransaction(
        managementSettings: {
          'canManageUsingHTTP': true,
          'canManageUsingHTTPS': false,
          'isManageWirelesslySupported': true,
          'canManageRemotely': false,
        },
      );

      when(() => mockRepository.transaction(any()))
          .thenAnswer((_) async => mockResponse);

      final service = AdministrationSettingsService();
      final result = await service.fetchAdministrationSettings(mockRef);

      expect(result.managementSettings.canManageUsingHTTP, true);
      expect(result.managementSettings.canManageUsingHTTPS, false);
      expect(result.managementSettings.isManageWirelesslySupported, true);
    });

    /// T010: Test UPnPSettings parsing
    test('parses UPnPSettings correctly', () async {
      final mockRef = createMockRef();

      final mockResponse =
          AdministrationSettingsTestData.createSuccessfulTransaction(
        upnpSettings: {
          'isUPnPEnabled': true,
          'canUsersConfigure': false,
          'canUsersDisableWANAccess': true,
        },
      );

      when(() => mockRepository.transaction(any()))
          .thenAnswer((_) async => mockResponse);

      final service = AdministrationSettingsService();
      final result = await service.fetchAdministrationSettings(mockRef);

      expect(result.isUPnPEnabled, true);
      expect(result.canUsersConfigure, false);
      expect(result.canUsersDisableWANAccess, true);
    });

    /// T011: Test ALGSettings parsing
    test('parses ALGSettings correctly', () async {
      final mockRef = createMockRef();

      final mockResponse =
          AdministrationSettingsTestData.createSuccessfulTransaction(
        algSettings: {
          'isSIPEnabled': true,
        },
      );

      when(() => mockRepository.transaction(any()))
          .thenAnswer((_) async => mockResponse);

      final service = AdministrationSettingsService();
      final result = await service.fetchAdministrationSettings(mockRef);

      expect(result.enabledALG, true);
    });

    /// T012: Test ExpressForwardingSettings parsing
    test('parses ExpressForwardingSettings correctly', () async {
      final mockRef = createMockRef();

      final mockResponse =
          AdministrationSettingsTestData.createSuccessfulTransaction(
        expressForwardingSettings: {
          'isExpressForwardingSupported': true,
          'isExpressForwardingEnabled': true,
        },
      );

      when(() => mockRepository.transaction(any()))
          .thenAnswer((_) async => mockResponse);

      final service = AdministrationSettingsService();
      final result = await service.fetchAdministrationSettings(mockRef);

      expect(result.isExpressForwardingSupported, true);
      expect(result.enabledExpressForwarfing, true);
    });

    /// T013: Test partial failure handling
    test('throws error if any JNAP action fails', () async {
      final mockRef = createMockRef();

      final mockResponse =
          AdministrationSettingsTestData.createPartialErrorTransaction(
        errorAction: JNAPAction.getUPnPSettings,
        errorMessage: 'Failed to fetch UPnP settings',
      );

      when(() => mockRepository.transaction(any()))
          .thenAnswer((_) async => mockResponse);

      final service = AdministrationSettingsService();

      // Assert: Expect exception with action context
      expect(
        () => service.fetchAdministrationSettings(mockRef),
        throwsA(isA<Exception>()),
      );
    });

    /// T014: Test error context in error message
    test('includes action context in error message', () async {
      final mockRef = createMockRef();

      final mockResponse =
          AdministrationSettingsTestData.createPartialErrorTransaction(
        errorAction: JNAPAction.getManagementSettings,
        errorMessage: 'Device unreachable',
      );

      when(() => mockRepository.transaction(any()))
          .thenAnswer((_) async => mockResponse);

      final service = AdministrationSettingsService();

      try {
        await service.fetchAdministrationSettings(mockRef);
        fail('Should throw exception');
      } catch (e) {
        expect(
          e.toString(),
          containsAny([
            'getManagementSettings',
            'Device unreachable',
          ]),
        );
      }
    });
  });
}

/// Matcher helper for checking multiple string patterns
Matcher containsAny(List<String> patterns) => _ContainsAnyMatcher(patterns);

class _ContainsAnyMatcher extends Matcher {
  final List<String> patterns;

  _ContainsAnyMatcher(this.patterns);

  @override
  bool matches(dynamic item, Map matchState) {
    if (item is! String) return false;
    return patterns.any((pattern) => item.contains(pattern));
  }

  @override
  Description describe(Description description) {
    return description.add('contains any of ${patterns.join(", ")}');
  }
}
