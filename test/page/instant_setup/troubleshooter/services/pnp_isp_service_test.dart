import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/models/internet_settings_enums.dart';
import 'package:privacy_gui/page/instant_setup/troubleshooter/services/pnp_isp_service.dart';

import '../../../../mocks/router_repository_mocks.dart';

void main() {
  group('PnpIspService', () {
    late MockRouterRepository mockRouterRepository;
    late PnpIspService pnpIspService;

    // Helper for common mock output
    Map<String, dynamic> baseWanStatusOutput({
      String wanStatus = 'Connecting',
      String ipAddress = '0.0.0.0',
      bool includeWanConnection = false,
    }) {
      final Map<String, dynamic> output = {
        'macAddress': '00:11:22:33:44:55',
        'detectedWANType': 'DHCP',
        'wanStatus': wanStatus,
        'wanIPv6Status': 'Disconnected',
        'supportedWANTypes': ['DHCP', 'Static', 'PPPoE'],
        'supportedIPv6WANTypes': ['DHCP', 'Static'],
        'supportedWANCombinations': [],
      };

      if (includeWanConnection) {
        output['wanConnection'] = {
          // Corrected key from 'wanConnections' to 'wanConnection'
          'wanType': 'DHCP',
          'ipAddress': ipAddress,
          'networkPrefixLength': 24,
          'gateway': '192.168.1.1',
          'mtu': 1500,
          'dnsServer1': '8.8.8.8',
        };
      }
      return output;
    }

    setUp(() {
      mockRouterRepository = MockRouterRepository();
      pnpIspService = PnpIspService(mockRouterRepository);
    });

    test(
        'verifyNewSettings should return true for DHCP when wanStatus is Connected',
        () async {
      // ARRANGE
      final successResult = JNAPSuccess(
        result: jnapResultOk,
        output: baseWanStatusOutput(wanStatus: 'Connected'),
      );

      when(mockRouterRepository.scheduledCommand(
        action: anyNamed('action'),
        maxRetry: anyNamed('maxRetry'),
        retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
        condition: anyNamed('condition'),
        onCompleted: anyNamed('onCompleted'),
        auth: anyNamed('auth'),
      )).thenAnswer((_) => Stream.value(successResult));

      // ACT
      final future = pnpIspService.verifyNewSettings(WanType.dhcp);

      // ASSERT
      await expectLater(future, completion(isTrue));
    });

    test(
        'verifyNewSettings should return true for PPPoE when a valid IP is assigned',
        () async {
      // ARRANGE
      final successResult = JNAPSuccess(
        result: jnapResultOk,
        output: baseWanStatusOutput(
          wanStatus: 'Connected', // PPPoE also needs to be 'Connected'
          ipAddress: '123.45.67.89',
          includeWanConnection: true,
        ),
      );

      when(mockRouterRepository.scheduledCommand(
        action: anyNamed('action'),
        maxRetry: anyNamed('maxRetry'),
        retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
        condition: anyNamed('condition'),
        onCompleted: anyNamed('onCompleted'),
        auth: anyNamed('auth'),
      )).thenAnswer((_) => Stream.value(successResult));

      // ACT
      final future = pnpIspService.verifyNewSettings(WanType.pppoe);

      // ASSERT
      await expectLater(future, completion(isTrue));
    });

    test(
        'verifyNewSettings should return false when max retries are exceeded (DHCP)',
        () async {
      // ARRANGE
      final nonMatchingResult = JNAPSuccess(
        result: jnapResultOk,
        output:
            baseWanStatusOutput(wanStatus: 'Connecting'), // Not 'Connected'
      );

      when(mockRouterRepository.scheduledCommand(
        action: anyNamed('action'),
        maxRetry: anyNamed('maxRetry'),
        retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
        condition: anyNamed('condition'),
        onCompleted: anyNamed('onCompleted'),
        auth: anyNamed('auth'),
      )).thenAnswer((invocation) {
        // Simulate the onCompleted callback being called with exceedMaxRetry = true
        final onCompleted = invocation
            .namedArguments[const Symbol('onCompleted')] as Function(bool);

        // This needs to be async to allow the stream to be listened to first
        Future(() => onCompleted(true));

        // Return a stream that emits a non-matching result
        return Stream.value(nonMatchingResult);
      });

      // ACT
      final future = pnpIspService.verifyNewSettings(WanType.dhcp);

      // ASSERT
      await expectLater(future, completion(isFalse));
    });

    test(
        'verifyNewSettings should return false when max retries are exceeded (PPPoE - invalid IP)',
        () async {
      // ARRANGE
      final nonMatchingResult = JNAPSuccess(
        result: jnapResultOk,
        output: baseWanStatusOutput(
          wanStatus: 'Connected', // Status is connected, but IP is invalid
          ipAddress: '0.0.0.0',
          includeWanConnection: true,
        ),
      );

      when(mockRouterRepository.scheduledCommand(
        action: anyNamed('action'),
        maxRetry: anyNamed('maxRetry'),
        retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
        condition: anyNamed('condition'),
        onCompleted: anyNamed('onCompleted'),
        auth: anyNamed('auth'),
      )).thenAnswer((invocation) {
        final onCompleted = invocation
            .namedArguments[const Symbol('onCompleted')] as Function(bool);
        Future(() => onCompleted(true));
        return Stream.value(nonMatchingResult);
      });

      // ACT
      final future = pnpIspService.verifyNewSettings(WanType.pppoe);

      // ASSERT
      await expectLater(future, completion(isFalse));
    });

    test('verifyNewSettings should throw an exception when the stream fails',
        () async {
      // ARRANGE
      final testException = Exception('Stream failed');
      when(mockRouterRepository.scheduledCommand(
        action: anyNamed('action'),
        maxRetry: anyNamed('maxRetry'),
        retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
        condition: anyNamed('condition'),
        onCompleted: anyNamed('onCompleted'),
        auth: anyNamed('auth'),
      )).thenAnswer((_) => Stream.error(testException));

      // ACT
      final future = pnpIspService.verifyNewSettings(WanType.dhcp);

      // ASSERT
      await expectLater(future, throwsA(isA<Exception>()));
    });
  });
}
