import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_state.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';

import '../../../mocks/test_data/channel_finder_test_data.dart';

void main() {
  final result = ChannelFinderTestData.result();

  test('isScanning only while scanning', () {
    for (final phase in ChannelFinderPhase.values) {
      expect(ChannelFinderState(phase: phase).isScanning,
          phase == ChannelFinderPhase.scanning);
    }
  });

  test('copyWith keeps what it is not given', () {
    final state = ChannelFinderState(
      phase: ChannelFinderPhase.failed,
      stage: ChannelFinderScanStage.channels,
      lastResult: result,
      error: const NetworkError(),
    );

    expect(state.copyWith(), state);
    expect(
        state.copyWith(phase: ChannelFinderPhase.scanning).lastResult, result);
  });

  test('copyWith clears the stage and the error on request', () {
    final state = ChannelFinderState(
      phase: ChannelFinderPhase.failed,
      stage: ChannelFinderScanStage.channels,
      lastResult: result,
      error: const NetworkError(),
    ).copyWith(clearStage: true, clearError: true);

    expect(state.stage, isNull);
    expect(state.error, isNull);
    expect(state.lastResult, result);
  });
}
