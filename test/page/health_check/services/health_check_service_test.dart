import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/models/health_check_result.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/page/health_check/models/speed_test_event.dart';
import 'package:privacy_gui/page/health_check/providers/health_check_provider.dart';
import 'package:privacy_gui/page/health_check/services/health_check_service.dart';

import '../../../mocks/router_repository_mocks.dart';

void main() {
  late MockRouterRepository mockRouterRepository;
  late SpeedTestService speedTestService;

  setUp(() {
    mockRouterRepository = MockRouterRepository();
    speedTestService = SpeedTestService(mockRouterRepository);
  });

  group('SpeedTestService', () {
    group('getInitialSpeedTestState', () {
      test('should return a list of SpeedTestUIModel on success', () async {
        // Arrange
        final successResponse = JNAPSuccess(
          result: 'OK',
          output: const {
            'healthCheckResults': [
              {
                'resultID': 1,
                'timestamp': '2023-01-01T12:00:00Z',
                'healthCheckModulesRequested': ['SpeedTest'],
                'speedTestResult': {
                  'resultID': 1,
                  'exitCode': 'Success',
                  'latency': 10,
                  'downloadBandwidth': 100000,
                  'uploadBandwidth': 20000,
                  'serverID': '1234'
                }
              },
              {
                'resultID': 2,
                'timestamp': '2023-01-02T12:00:00Z',
                'healthCheckModulesRequested': ['SpeedTest'],
                'speedTestResult': {
                  'resultID': 2,
                  'exitCode': 'Failed', // This one should be filtered out
                  'latency': 10,
                  'downloadBandwidth': 100000,
                  'uploadBandwidth': 20000,
                  'serverID': '1234'
                }
              }
            ]
          },
        );
        when(mockRouterRepository.send(
          JNAPAction.getHealthCheckResults,
          data: anyNamed('data'),
          auth: anyNamed('auth'),
          fetchRemote: anyNamed('fetchRemote'),
        )).thenAnswer((_) async => successResponse);

        // Act
        final result = await speedTestService.getInitialSpeedTestState();

        // Assert
        expect(result, isNotEmpty);
        expect(result.length, 1);
        expect(result.first.latency, '10');
        expect(result.first.serverId, '1234');
      });

      test('should return an empty list when healthCheckResults is empty',
          () async {
        // Arrange
        final successResponse = JNAPSuccess(
          result: 'OK',
          output: const {'healthCheckResults': []},
        );
        when(mockRouterRepository.send(
          JNAPAction.getHealthCheckResults,
          data: anyNamed('data'),
          auth: anyNamed('auth'),
          fetchRemote: anyNamed('fetchRemote'),
        )).thenAnswer((_) async => successResponse);

        // Act
        final result = await speedTestService.getInitialSpeedTestState();

        // Assert
        expect(result, isEmpty);
      });

      test('should return an empty list on JNAPError', () async {
        // Arrange
        when(mockRouterRepository.send(
          any,
          data: anyNamed('data'),
          auth: anyNamed('auth'),
          fetchRemote: anyNamed('fetchRemote'),
        )).thenThrow(JNAPError(result: 'ERROR'));

        // Act
        final result = await speedTestService.getInitialSpeedTestState();

        // Assert
        expect(result, isEmpty);
      });
    });

    group('runHealthCheck', () {
      test('should yield progress and success events on happy path', () async {
        // Arrange
        when(mockRouterRepository.send(
          JNAPAction.runHealthCheck,
          data: anyNamed('data'),
          auth: anyNamed('auth'),
          fetchRemote: anyNamed('fetchRemote'),
          cacheLevel: anyNamed('cacheLevel'),
        )).thenAnswer((_) async =>
            JNAPSuccess(result: 'OK', output: const {'resultID': 123}));

        when(mockRouterRepository.scheduledCommand(
          action: JNAPAction.getHealthCheckStatus,
          auth: anyNamed('auth'),
          firstDelayInMilliSec: anyNamed('firstDelayInMilliSec'),
          retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
          maxRetry: anyNamed('maxRetry'),
          condition: anyNamed('condition'),
        )).thenAnswer((_) => Stream.fromIterable([
              JNAPSuccess(result: 'OK', output: const {
                'speedTestResult': {
                  'resultID': 123,
                  'exitCode': 'Unavailable',
                  'latency': 5
                }
              }),
              JNAPSuccess(result: 'OK', output: const {
                'speedTestResult': {
                  'resultID': 123,
                  'exitCode': 'Success',
                  'latency': 10
                }
              }),
            ]));

        when(mockRouterRepository.send(
          JNAPAction.getHealthCheckResults,
          data: anyNamed('data'),
          auth: anyNamed('auth'),
          fetchRemote: anyNamed('fetchRemote'),
        )).thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {
              'healthCheckResults': [
                {
                  'resultID': 123,
                  'timestamp': '2023-01-01T12:00:00Z',
                  'healthCheckModulesRequested': ['SpeedTest'],
                  'speedTestResult': {
                    'resultID': 123,
                    'exitCode': 'Success',
                    'latency': 10,
                    'downloadBandwidth': 100000,
                    'uploadBandwidth': 20000,
                    'serverID': '1234'
                  }
                }
              ]
            }));

        // Act & Assert
        final stream = speedTestService.runHealthCheck(Module.speedtest);
        expect(
            stream,
            emitsInOrder([
              isA<SpeedTestProgress>(),
              isA<SpeedTestProgress>(),
              isA<SpeedTestSuccess>(),
              emitsDone,
            ]));
      });

      test('should yield SpeedTestFailure if initiation fails', () async {
        // Arrange
        when(mockRouterRepository.send(
          JNAPAction.runHealthCheck,
          data: anyNamed('data'),
          auth: anyNamed('auth'),
          fetchRemote: anyNamed('fetchRemote'),
          cacheLevel: anyNamed('cacheLevel'),
        )).thenThrow(JNAPError(result: 'INIT_ERROR'));

        // Act & Assert
        final stream = speedTestService.runHealthCheck(Module.speedtest);
        expect(
            stream,
            emitsInOrder([
              isA<SpeedTestFailure>()
                  .having((f) => f.error, 'error', 'INIT_ERROR'),
              emitsDone,
            ]));
      });

      test(
          'should yield SpeedTestFailure if polling returns an error exit code',
          () async {
        // Arrange
        when(mockRouterRepository.send(
          JNAPAction.runHealthCheck,
          data: anyNamed('data'),
          auth: anyNamed('auth'),
          fetchRemote: anyNamed('fetchRemote'),
          cacheLevel: anyNamed('cacheLevel'),
        )).thenAnswer((_) async =>
            JNAPSuccess(result: 'OK', output: const {'resultID': 123}));

        when(mockRouterRepository.scheduledCommand(
          action: JNAPAction.getHealthCheckStatus,
          auth: anyNamed('auth'),
          firstDelayInMilliSec: anyNamed('firstDelayInMilliSec'),
          retryDelayInMilliSec: anyNamed('retryDelayInMilliSec'),
          maxRetry: anyNamed('maxRetry'),
          condition: anyNamed('condition'),
        )).thenAnswer((_) => Stream.fromIterable([
              JNAPSuccess(result: 'OK', output: const {
                'speedTestResult': {
                  'resultID': 123,
                  'exitCode': 'SpeedTestExecutionError'
                }
              }),
            ]));

        // Act & Assert
        final stream = speedTestService.runHealthCheck(Module.speedtest);
        expect(
            stream,
            emitsInOrder([
              isA<SpeedTestFailure>()
                  .having((f) => f.error, 'error', 'SpeedTestExecutionError'),
              emitsDone,
            ]));
      });
    });

    group('getSupportedHealthCheckModules', () {
      test('should return a list of modules on success', () async {
        // Arrange
        when(mockRouterRepository.send(
          JNAPAction.getSupportedHealthCheckModules,
          auth: anyNamed('auth'),
        )).thenAnswer((_) async => JNAPSuccess(result: 'OK', output: const {
              'supportedHealthCheckModules': ['SpeedTest', 'ChannelAnalyzer']
            }));

        // Act
        final modules = await speedTestService.getSupportedHealthCheckModules();

        // Assert
        expect(modules, ['SpeedTest', 'ChannelAnalyzer']);
      });

      test('should return an empty list on failure', () async {
        // Arrange
        when(mockRouterRepository.send(
          JNAPAction.getSupportedHealthCheckModules,
          auth: anyNamed('auth'),
        )).thenThrow(Exception('Network error'));

        // Act
        final modules = await speedTestService.getSupportedHealthCheckModules();

        // Assert
        expect(modules, isEmpty);
      });
    });

    group('stopHealthCheck', () {
      test('should call send with stopHealthCheck action', () async {
        // Arrange
        when(mockRouterRepository.send(
          JNAPAction.stopHealthCheck,
          auth: anyNamed('auth'),
          fetchRemote: anyNamed('fetchRemote'),
          cacheLevel: anyNamed('cacheLevel'),
        )).thenAnswer((_) async => JNAPSuccess(result: 'OK'));

        // Act
        await speedTestService.stopHealthCheck();

        // Assert
        verify(mockRouterRepository.send(
          JNAPAction.stopHealthCheck,
          auth: true,
          fetchRemote: true,
          cacheLevel: CacheLevel.noCache,
        )).called(1);
      });
    });

    group('mapResultToUIModel', () {
      test('should map SpeedTestResult to SpeedTestUIModel correctly', () {
        // Arrange
        final speedTestResult = SpeedTestResult(
          resultID: 123,
          exitCode: 'Success',
          latency: 15,
          downloadBandwidth: 123456,
          uploadBandwidth: 7890,
          serverID: '5678',
        );

        // Act
        final uiModel = speedTestService.mapResultToUIModel(speedTestResult,
            timestamp: '2023-01-02T10:30:00Z');

        // Assert
        expect(uiModel.latency, '15');
        expect(uiModel.serverId, '5678');
        expect(uiModel.downloadSpeed, isNot('0'));
        expect(uiModel.uploadSpeed, isNot('0'));
      });

      test('should return placeholder values for null result', () {
        // Act
        final uiModel = speedTestService.mapResultToUIModel(null);

        // Assert
        expect(uiModel.latency, '--');
        expect(uiModel.serverId, '--');
        expect(uiModel.downloadSpeed, '--');
        expect(uiModel.uploadSpeed, '--');
      });

      test('should return -- for speed when isProgress is true and value is 0',
          () {
        // Arrange
        final speedTestResult = SpeedTestResult(
          resultID: 1,
          exitCode: 'Unavailable',
          downloadBandwidth: 0,
          uploadBandwidth: 0,
        );

        // Act
        final uiModel = speedTestService.mapResultToUIModel(speedTestResult,
            isProgress: true);

        // Assert
        expect(uiModel.downloadSpeed, '--');
        expect(uiModel.uploadSpeed, '--');
      });

      test('should return -- for timestamp with invalid format', () {
        // Arrange
        final speedTestResult = SpeedTestResult(
          resultID: 1,
          exitCode: 'Success',
        );

        // Act
        final uiModel = speedTestService.mapResultToUIModel(speedTestResult,
            timestamp: 'invalid-date');

        // Assert
        expect(uiModel.timestamp, '--');
      });
    });
  });
}
