import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/core/usp/providers/usp_client_provider.dart';
import 'package:privacy_gui/core/usp/services/usp_client.dart';
import 'package:privacy_gui/page/channel_finder/models/channel_finder_ui_model.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_provider.dart';
import 'package:privacy_gui/page/channel_finder/providers/channel_finder_state.dart';
import 'package:privacy_gui/page/channel_finder/services/channel_finder_service.dart';

import '../../../mocks/test_data/channel_finder_test_data.dart';

class MockChannelFinderService extends Mock implements ChannelFinderService {}

class MockUspClient extends Mock implements UspClient {}

void main() {
  late MockChannelFinderService service;
  late ProviderContainer container;
  late Completer<ChannelFinderResultUIModel> pending;
  late void Function(ChannelFinderScanStage)? onStage;

  setUp(() {
    service = MockChannelFinderService();
    pending = Completer();
    onStage = null;
    when(() => service.scan(onStage: any(named: 'onStage')))
        .thenAnswer((invocation) {
      onStage = invocation.namedArguments[#onStage] as void Function(
          ChannelFinderScanStage)?;
      return pending.future;
    });
    container = ProviderContainer(overrides: [
      channelFinderServiceProvider.overrideWithValue(service),
      uspClientProvider.overrideWith((ref) => MockUspClient()),
    ]);
    addTearDown(container.dispose);
  });

  ChannelFinderState read() => container.read(channelFinderProvider);
  ChannelFinderNotifier notifier() =>
      container.read(channelFinderProvider.notifier);

  test('starts idle with no result', () {
    expect(read(), const ChannelFinderState());
  });

  test('scan shows each stage, then the result', () async {
    final scan = notifier().scan();
    expect(read().phase, ChannelFinderPhase.scanning);
    expect(read().stage, isNull);

    onStage!(ChannelFinderScanStage.neighbors);
    expect(read().stage, ChannelFinderScanStage.neighbors);
    onStage!(ChannelFinderScanStage.channels);
    expect(read().stage, ChannelFinderScanStage.channels);

    final result = ChannelFinderTestData.result();
    pending.complete(result);
    await scan;
    expect(read(),
        ChannelFinderState(phase: ChannelFinderPhase.done, lastResult: result));
  });

  test('a failed scan keeps the last result and says why', () async {
    final first = ChannelFinderTestData.result();
    pending.complete(first);
    await notifier().scan();

    pending = Completer();
    final second = notifier().scan();
    expect(read().lastResult, first, reason: 'shown while the rescan runs');
    pending.completeError(const TimeoutError(detail: 'no OperationComplete'));
    await second;

    expect(read().phase, ChannelFinderPhase.failed);
    expect(read().error, isA<TimeoutError>());
    expect(read().lastResult, first);
    expect(read().stage, isNull);
  });

  test('a rescan clears the previous error', () async {
    pending.completeError(const NetworkError());
    await notifier().scan();
    expect(read().error, isA<NetworkError>());

    pending = Completer();
    unawaited(notifier().scan());
    expect(read().phase, ChannelFinderPhase.scanning);
    expect(read().error, isNull);
  });

  test('a second scan while one runs is ignored', () async {
    final first = notifier().scan();
    await notifier().scan();

    verify(() => service.scan(onStage: any(named: 'onStage'))).called(1);
    pending.complete(ChannelFinderTestData.result());
    await first;
  });

  test('an error that is not a ServiceError still ends the scan', () async {
    pending.completeError(StateError('bug'));
    await notifier().scan();

    expect(read().phase, ChannelFinderPhase.failed);
    expect(read().error, isA<UnexpectedError>());
  });

  test('a new session starts over, and the earlier scan does not publish',
      () async {
    final scan = notifier().scan();
    container.invalidate(uspClientProvider);
    expect(read(), const ChannelFinderState());

    onStage!(ChannelFinderScanStage.channels);
    pending.complete(ChannelFinderTestData.result());
    await scan;
    expect(read(), const ChannelFinderState());
  });
}
