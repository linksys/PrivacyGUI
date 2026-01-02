import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channelfinder_info.dart';
import 'package:privacy_gui/page/wifi_settings/services/channel_finder_service.dart';

class MockRouterRepository extends Mock implements RouterRepository {}

void main() {
  late MockRouterRepository mockRepo;
  late ChannelFinderService service;

  setUpAll(() {
    registerFallbackValue(JNAPAction.getSelectedChannels);
  });

  setUp(() {
    mockRepo = MockRouterRepository();
    service = ChannelFinderService(mockRepo);
  });

  group('ChannelFinderService', () {
    group('getSelectedChannels', () {
      test('returns empty list when no channels', () async {
        when(() => mockRepo.send(any(), cacheLevel: any(named: 'cacheLevel')))
            .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: {
                  'isRunning': false,
                  'selectedChannels': [],
                }));

        final result = await service.getSelectedChannels();

        expect(result, isEmpty);
      });

      test('returns selected channels when available', () async {
        when(() => mockRepo.send(any(), cacheLevel: any(named: 'cacheLevel')))
            .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: {
                  'isRunning': false,
                  'selectedChannels': [
                    {
                      'deviceID': 'device1',
                      'channels': [
                        {'radioID': 'R1', 'band': '5GHz', 'channel': 36}
                      ]
                    }
                  ],
                }));

        final result = await service.getSelectedChannels();

        expect(result, hasLength(1));
        expect(result.first.deviceID, 'device1');
        expect(result.first.channels.first.channel, 36);
      });

      test('throws error when already running', () async {
        when(() => mockRepo.send(any(), cacheLevel: any(named: 'cacheLevel')))
            .thenAnswer((_) async => JNAPSuccess(result: 'OK', output: {
                  'isRunning': true,
                }));

        expect(() => service.getSelectedChannels(), throwsA(isA<JNAPError>()));
      });
    });

    group('pollingInterval and maxPollingCount', () {
      test('has correct default values', () {
        expect(service.pollingInterval, 5000);
        expect(service.maxPollingCount, 30);
      });
    });
  });
}
