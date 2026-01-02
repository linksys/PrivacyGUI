import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channelfinder_info.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channelfinder_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channelfinder_state.dart';
import 'package:privacy_gui/page/wifi_settings/services/channel_finder_service.dart';

class MockChannelFinderService extends Mock implements ChannelFinderService {}

void main() {
  late ProviderContainer container;
  late MockChannelFinderService mockService;

  setUpAll(() {
    registerFallbackValue(<SelectedChannels>[]);
  });

  setUp(() {
    mockService = MockChannelFinderService();
    container = ProviderContainer(
      overrides: [
        channelFinderServiceProvider.overrideWithValue(mockService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('ChannelFinderNotifier', () {
    group('build', () {
      test('returns initial state with empty result', () {
        final state = container.read(channelFinderProvider);

        expect(state.result, isEmpty);
      });

      test('initial state is ChannelFinderState', () {
        final state = container.read(channelFinderProvider);

        expect(state, isA<ChannelFinderState>());
      });
    });

    group('optimizeChannels', () {
      test('does nothing when getSelectedChannels returns empty list',
          () async {
        when(() => mockService.getSelectedChannels())
            .thenAnswer((_) async => []);

        final notifier = container.read(channelFinderProvider.notifier);
        await notifier.optimizeChannels();
        final state = container.read(channelFinderProvider);

        expect(state.result, isEmpty);
        verify(() => mockService.getSelectedChannels()).called(1);
      });

      test('getSelectedChannels is called when optimizeChannels is invoked',
          () async {
        when(() => mockService.getSelectedChannels())
            .thenAnswer((_) async => []);

        final notifier = container.read(channelFinderProvider.notifier);
        await notifier.optimizeChannels();

        verify(() => mockService.getSelectedChannels()).called(1);
      });
    });

    group('state management', () {
      test('state can be accessed from container', () {
        final state = container.read(channelFinderProvider);

        expect(state, isA<ChannelFinderState>());
      });

      test('notifier can be accessed from container', () {
        final notifier = container.read(channelFinderProvider.notifier);

        expect(notifier, isA<ChannelFinderNotifier>());
      });

      test('state has correct default values', () {
        final state = container.read(channelFinderProvider);

        expect(state.result, isA<List<OptimizedSelectedChannel>>());
        expect(state.result, isEmpty);
      });
    });

    group('channelFinderServiceProvider', () {
      test('service provider can be overridden', () {
        final service = container.read(channelFinderServiceProvider);

        expect(service, mockService);
      });
    });
  });
}
