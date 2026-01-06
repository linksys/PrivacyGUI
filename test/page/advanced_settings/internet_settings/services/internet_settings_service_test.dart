import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/data/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/_models.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/services/internet_settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../test_data/internet_settings_test_data_builder.dart';

// Mocks
class MockRouterRepository extends Mock implements RouterRepository {}

class MockRef extends Mock implements Ref {}

class MockPollingNotifier extends Mock implements PollingNotifier {}

// Fake class for mocktail
class FakeJNAPTransactionBuilder extends Fake
    implements JNAPTransactionBuilder {}

void main() {
  late InternetSettingsService service;
  late MockRouterRepository mockRepo;
  late MockRef mockRef;
  late MockPollingNotifier mockPollingNotifier;

  setUpAll(() {
    // Register fallback value for mocktail
    registerFallbackValue(FakeJNAPTransactionBuilder());
    registerFallbackValue(CacheLevel.noCache);
    registerFallbackValue(JNAPAction.transaction);
  });

  setUp(() {
    mockRepo = MockRouterRepository();
    mockRef = MockRef();
    mockPollingNotifier = MockPollingNotifier();
    service = InternetSettingsService(mockRepo, mockRef);

    // Setup shared preferences for tests
    SharedPreferences.setMockInitialValues({});

    // Setup Ref mocks
    when(() => mockRef.read(pollingProvider.notifier))
        .thenReturn(mockPollingNotifier);
    when(() => mockPollingNotifier.forcePolling()).thenAnswer((_) async => {});
  });

  group('InternetSettingsService - fetchSettings', () {
    test('successfully fetches and converts DHCP settings', () async {
      // Arrange
      final mockTransaction = JNAPTransactionSuccessWrap(
        result: 'OK',
        data: [
          MapEntry(
            JNAPAction.getWANSettings,
            JNAPSuccess(
              result: 'OK',
              output:
                  InternetSettingsTestDataBuilder.dhcpWanSettings().toJson(),
            ),
          ),
          MapEntry(
            JNAPAction.getIPv6Settings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.automaticIPv6Settings()
                  .toJson(),
            ),
          ),
          MapEntry(
            JNAPAction.getWANStatus,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.wanStatus().toMap(),
            ),
          ),
          MapEntry(
            JNAPAction.getMACAddressCloneSettings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.macAddressCloneSettings()
                  .toMap(),
            ),
          ),
          MapEntry(
            JNAPAction.getLANSettings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.lanSettings().toMap(),
            ),
          ),
        ],
      );

      when(() => mockRepo.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => mockTransaction);

      // Act
      final (settings, status) = await service.fetchSettings();

      // Assert
      expect(settings.ipv4Setting.ipv4ConnectionType, 'DHCP');
      expect(settings.ipv6Setting.ipv6ConnectionType, 'Automatic');
      expect(settings.macClone, false);
      expect(status.supportedIPv4ConnectionType, isNotEmpty);
      expect(status.duid, '00:02:03:09:05:05:80:69:1A:13:16:0E');
      expect(status.hostname, 'myrouter');
    });

    test('successfully fetches and converts Static settings', () async {
      // Arrange
      final staticWan = InternetSettingsTestDataBuilder.staticWanSettings();

      // Manually serialize to fix nested objects
      final staticWanOutput = {
        'wanType': staticWan.wanType,
        'mtu': staticWan.mtu,
        'staticSettings': staticWan.staticSettings?.toJson(),
        'wanTaggingSettings': staticWan.wanTaggingSettings?.toJson(),
      }..removeWhere((key, value) => value == null);

      final mockTransaction = JNAPTransactionSuccessWrap(
        result: 'OK',
        data: [
          MapEntry(
            JNAPAction.getWANSettings,
            JNAPSuccess(
              result: 'OK',
              output: staticWanOutput,
            ),
          ),
          MapEntry(
            JNAPAction.getIPv6Settings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.automaticIPv6Settings()
                  .toJson(),
            ),
          ),
          MapEntry(
            JNAPAction.getWANStatus,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.wanStatus().toMap(),
            ),
          ),
          MapEntry(
            JNAPAction.getMACAddressCloneSettings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.macAddressCloneSettings()
                  .toMap(),
            ),
          ),
          MapEntry(
            JNAPAction.getLANSettings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.lanSettings().toMap(),
            ),
          ),
        ],
      );

      when(() => mockRepo.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => mockTransaction);

      // Act
      final (settings, status) = await service.fetchSettings();

      // Assert
      expect(settings.ipv4Setting.ipv4ConnectionType, 'Static');
      expect(settings.ipv4Setting.staticIpAddress, '111.222.111.123');
      expect(settings.ipv4Setting.staticGateway, '111.222.111.1');
      expect(settings.ipv4Setting.staticDns1, '8.8.8.8');
    });

    test('successfully fetches and converts PPPoE settings', () async {
      // Arrange
      final pppoeWan = InternetSettingsTestDataBuilder.pppoeWanSettings();

      // Manually serialize to fix nested objects
      final pppoeWanOutput = {
        'wanType': pppoeWan.wanType,
        'mtu': pppoeWan.mtu,
        'pppoeSettings': pppoeWan.pppoeSettings?.toJson(),
        'wanTaggingSettings': pppoeWan.wanTaggingSettings?.toJson(),
      }..removeWhere((key, value) => value == null);

      final mockTransaction = JNAPTransactionSuccessWrap(
        result: 'OK',
        data: [
          MapEntry(
            JNAPAction.getWANSettings,
            JNAPSuccess(
              result: 'OK',
              output: pppoeWanOutput,
            ),
          ),
          MapEntry(
            JNAPAction.getIPv6Settings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.automaticIPv6Settings()
                  .toJson(),
            ),
          ),
          MapEntry(
            JNAPAction.getWANStatus,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.wanStatus().toMap(),
            ),
          ),
          MapEntry(
            JNAPAction.getMACAddressCloneSettings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.macAddressCloneSettings()
                  .toMap(),
            ),
          ),
          MapEntry(
            JNAPAction.getLANSettings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.lanSettings().toMap(),
            ),
          ),
        ],
      );

      when(() => mockRepo.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => mockTransaction);

      // Act
      final (settings, status) = await service.fetchSettings();

      // Assert
      expect(settings.ipv4Setting.ipv4ConnectionType, 'PPPoE');
      expect(settings.ipv4Setting.username, 'testuser');
      expect(settings.ipv4Setting.password, 'testpass');
      expect(settings.ipv4Setting.behavior, PPPConnectionBehavior.keepAlive);
    });

    test('successfully fetches settings with MAC clone enabled', () async {
      // Arrange
      final mockTransaction = JNAPTransactionSuccessWrap(
        result: 'OK',
        data: [
          MapEntry(
            JNAPAction.getWANSettings,
            JNAPSuccess(
              result: 'OK',
              output:
                  InternetSettingsTestDataBuilder.dhcpWanSettings().toJson(),
            ),
          ),
          MapEntry(
            JNAPAction.getIPv6Settings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.automaticIPv6Settings()
                  .toJson(),
            ),
          ),
          MapEntry(
            JNAPAction.getWANStatus,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.wanStatus().toMap(),
            ),
          ),
          MapEntry(
            JNAPAction.getMACAddressCloneSettings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.macAddressCloneSettings(
                enabled: true,
                macAddress: 'AA:BB:CC:DD:EE:FF',
              ).toMap(),
            ),
          ),
          MapEntry(
            JNAPAction.getLANSettings,
            JNAPSuccess(
              result: 'OK',
              output: InternetSettingsTestDataBuilder.lanSettings().toMap(),
            ),
          ),
        ],
      );

      when(() => mockRepo.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenAnswer((_) async => mockTransaction);

      // Act
      final (settings, status) = await service.fetchSettings();

      // Assert
      expect(settings.macClone, true);
      expect(settings.macCloneAddress, 'AA:BB:CC:DD:EE:FF');
    });

    test('throws UnexpectedError when JNAP transaction fails', () async {
      // Arrange
      when(() => mockRepo.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenThrow(JNAPError(result: 'ErrorUnknown', error: 'Test error'));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('throws UnexpectedError when unknown error occurs', () async {
      // Arrange
      when(() => mockRepo.transaction(any(),
              fetchRemote: any(named: 'fetchRemote')))
          .thenThrow(Exception('Unknown error'));

      // Act & Assert
      expect(
        () => service.fetchSettings(),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });

  group('InternetSettingsService - saveSettings', () {
    test('successfully saves DHCP settings', () async {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel(),
        ipv6Setting: InternetSettingsTestDataBuilder.automaticIPv6UIModel(),
      );

      final mockTransaction = JNAPTransactionSuccessWrap(
        result: 'OK',
        data: const [
          MapEntry(
            JNAPAction.setMACAddressCloneSettings,
            JNAPSuccess(result: 'OK', output: {}),
          ),
          MapEntry(
            JNAPAction.setWANSettings,
            JNAPSuccess(result: 'OK', output: {}),
          ),
          MapEntry(
            JNAPAction.setIPv6Settings,
            JNAPSuccess(result: 'OK', output: {}),
          ),
        ],
      );

      when(() => mockRepo.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenAnswer((_) async => mockTransaction);

      // Act
      final result = await service.saveSettings(settings);

      // Assert
      expect(result, isNull);
      verify(() => mockRepo.transaction(
            any(),
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });

    test('successfully saves PPPoE settings', () async {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.pppoeUIModel(),
        ipv6Setting: InternetSettingsTestDataBuilder.automaticIPv6UIModel(),
      );

      final mockTransaction = JNAPTransactionSuccessWrap(
        result: 'OK',
        data: const [
          MapEntry(
            JNAPAction.setMACAddressCloneSettings,
            JNAPSuccess(result: 'OK', output: {}),
          ),
          MapEntry(
            JNAPAction.setWANSettings,
            JNAPSuccess(result: 'OK', output: {}),
          ),
          MapEntry(
            JNAPAction.setIPv6Settings,
            JNAPSuccess(result: 'OK', output: {}),
          ),
        ],
      );

      when(() => mockRepo.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenAnswer((_) async => mockTransaction);

      // Act
      await service.saveSettings(settings);

      // Assert
      verify(() => mockRepo.transaction(
            any(),
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
    });

    test('returns redirection map for bridge mode', () async {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: const Ipv4SettingsUIModel(
          ipv4ConnectionType: 'Bridge',
          mtu: 0,
        ),
        ipv6Setting: InternetSettingsTestDataBuilder.automaticIPv6UIModel(),
      );

      final mockTransaction = JNAPTransactionSuccessWrap(
        result: 'OK',
        data: const [
          MapEntry(
            JNAPAction.setMACAddressCloneSettings,
            JNAPSuccess(result: 'OK', output: {}),
          ),
          MapEntry(
            JNAPAction.setWANSettings,
            JNAPSuccess(
              result: 'OK',
              output: {
                'redirection': {'url': 'http://192.168.1.1'}
              },
            ),
          ),
          MapEntry(
            JNAPAction.setIPv6Settings,
            JNAPSuccess(result: 'OK', output: {}),
          ),
        ],
      );

      when(() => mockRepo.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenAnswer((_) async => mockTransaction);

      // Act
      final result = await service.saveSettings(settings);

      // Assert
      expect(result, isNotNull);
      expect(result?['url'], 'http://192.168.1.1');
    });

    test('throws UnexpectedError when save fails', () async {
      // Arrange
      final settings =
          InternetSettingsTestDataBuilder.internetSettingsUIModel();

      when(() => mockRepo.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(JNAPError(result: 'ErrorUnknown', error: 'Test error'));

      // Act & Assert
      expect(
        () => service.saveSettings(settings),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('throws UnexpectedError with empty ipv4ConnectionType', () async {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: const Ipv4SettingsUIModel(
          ipv4ConnectionType: '',
          mtu: 0,
        ),
      );

      // Act & Assert
      expect(
        () => service.saveSettings(settings),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test('throws UnexpectedError with empty ipv6ConnectionType', () async {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv6Setting: const Ipv6SettingsUIModel(
          ipv6ConnectionType: '',
          isIPv6AutomaticEnabled: true,
        ),
      );

      when(() => mockRepo.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenAnswer((_) async => JNAPTransactionSuccessWrap(
            result: 'OK',
            data: const [
              MapEntry(
                JNAPAction.setMACAddressCloneSettings,
                JNAPSuccess(result: 'OK', output: {}),
              ),
              MapEntry(
                JNAPAction.setWANSettings,
                JNAPSuccess(result: 'OK', output: {}),
              ),
            ],
          ));

      // Act & Assert
      expect(
        () => service.saveSettings(settings),
        throwsA(isA<UnexpectedError>()),
      );
    });

    test(
        'extracts redirection from ServiceSideEffectError when originalResult is present',
        () async {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel(),
        ipv6Setting: InternetSettingsTestDataBuilder.automaticIPv6UIModel(),
      );

      // Create mock transaction data with redirection
      final mockTransactionData = [
        MapEntry(
          JNAPAction.setMACAddressCloneSettings,
          const JNAPSuccess(result: 'OK', output: {}),
        ),
        MapEntry(
          JNAPAction.setWANSettings,
          const JNAPSuccess(
            result: 'OK',
            output: {
              'redirection': {'hostName': 'www.myrouter', 'domain': 'local'}
            },
          ),
        ),
        MapEntry(
          JNAPAction.setIPv6Settings,
          const JNAPSuccess(result: 'OK', output: {}),
        ),
      ];

      final mockSuccessWrap = JNAPTransactionSuccessWrap(
        result: 'OK',
        data: mockTransactionData,
      );

      // Create ServiceSideEffectError with originalResult
      final sideEffectError = ServiceSideEffectError(mockSuccessWrap);

      when(() => mockRepo.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(sideEffectError);

      // Act
      final result = await service.saveSettings(settings);

      // Assert
      expect(result, isNotNull);
      expect(result?['hostName'], 'www.myrouter');
      expect(result?['domain'], 'local');
    });

    test('rethrows ServiceSideEffectError when originalResult is null',
        () async {
      // Arrange
      final settings = InternetSettingsTestDataBuilder.internetSettingsUIModel(
        ipv4Setting: InternetSettingsTestDataBuilder.dhcpUIModel(),
        ipv6Setting: InternetSettingsTestDataBuilder.automaticIPv6UIModel(),
      );

      // Create ServiceSideEffectError without originalResult
      const sideEffectError = ServiceSideEffectError(null);

      when(() => mockRepo.transaction(
            any(),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(sideEffectError);

      // Act & Assert
      expect(
        () => service.saveSettings(settings),
        throwsA(isA<ServiceSideEffectError>()),
      );
    });
  });

  group('InternetSettingsService - renewDHCPWANLease', () {
    test('successfully renews DHCP WAN lease', () async {
      // Arrange
      when(() => mockRepo.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async => const JNAPSuccess(result: 'OK', output: {}));

      // Act
      await service.renewDHCPWANLease();

      // Assert
      verify(() => mockRepo.send(
            JNAPAction.renewDHCPWANLease,
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
      verify(() => mockPollingNotifier.forcePolling()).called(1);
    });

    test('throws UnexpectedError when renew fails', () async {
      // Arrange
      when(() => mockRepo.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(JNAPError(result: 'ErrorUnknown', error: 'Test error'));

      // Act & Assert
      expect(
        () => service.renewDHCPWANLease(),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });

  group('InternetSettingsService - renewDHCPIPv6WANLease', () {
    test('successfully renews DHCP IPv6 WAN lease', () async {
      // Arrange
      when(() => mockRepo.send(
                any(),
                auth: any(named: 'auth'),
                fetchRemote: any(named: 'fetchRemote'),
                cacheLevel: any(named: 'cacheLevel'),
              ))
          .thenAnswer((_) async => const JNAPSuccess(result: 'OK', output: {}));

      // Act
      await service.renewDHCPIPv6WANLease();

      // Assert
      verify(() => mockRepo.send(
            JNAPAction.renewDHCPIPv6WANLease,
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache,
          )).called(1);
      verify(() => mockPollingNotifier.forcePolling()).called(1);
    });

    test('throws UnexpectedError when renew fails', () async {
      // Arrange
      when(() => mockRepo.send(
            any(),
            auth: any(named: 'auth'),
            fetchRemote: any(named: 'fetchRemote'),
            cacheLevel: any(named: 'cacheLevel'),
          )).thenThrow(JNAPError(result: 'ErrorUnknown', error: 'Test error'));

      // Act & Assert
      expect(
        () => service.renewDHCPIPv6WANLease(),
        throwsA(isA<UnexpectedError>()),
      );
    });
  });
}
