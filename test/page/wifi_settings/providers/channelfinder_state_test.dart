import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channelfinder_state.dart';
import 'package:privacy_gui/page/wifi_settings/providers/channelfinder_info.dart';

void main() {
  group('ChannelFinderState', () {
    test('creates instance with empty result list', () {
      const state = ChannelFinderState(result: []);
      expect(state.result, isEmpty);
    });

    test('creates instance with result list', () {
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const optimized = OptimizedSelectedChannel(
        deviceID: 'device1',
        channels: [channel],
        deviceName: 'Router',
        deviceIcon: 'icon',
      );
      const state = ChannelFinderState(result: [optimized]);
      expect(state.result, hasLength(1));
      expect(state.result.first.deviceID, 'device1');
    });

    test('copyWith updates result list', () {
      const state = ChannelFinderState(result: []);
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const optimized = OptimizedSelectedChannel(
        deviceID: 'device1',
        channels: [channel],
      );
      final updated = state.copyWith([optimized]);
      expect(updated.result, hasLength(1));
    });

    test('equality comparison works', () {
      const state1 = ChannelFinderState(result: []);
      const state2 = ChannelFinderState(result: []);
      expect(state1, state2);
    });

    test('distinguishes different states', () {
      const channel = Channel(radioID: 'RADIO_5GHz', band: '5GHz', channel: 36);
      const optimized = OptimizedSelectedChannel(
        deviceID: 'device1',
        channels: [channel],
      );
      const state1 = ChannelFinderState(result: []);
      const state2 = ChannelFinderState(result: [optimized]);
      expect(state1, isNot(state2));
    });

    test('props returns correct list', () {
      const state = ChannelFinderState(result: []);
      expect(state.props, [state.result]);
    });
  });
}
