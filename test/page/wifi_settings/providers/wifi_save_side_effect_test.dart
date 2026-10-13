// #1683: what a Wi-Fi save reports when the router it has just changed drops
// the operator off the network - see [refreshAfterWrite] and
// [PollingNotifier.holdWhile] for why the drop comes after the save's own boot
// check.
//
// Two things are pinned. A refresh that gets no answer is reported as a
// JNAPSideEffectError, which the pages meet with their router-not-found alert,
// not as the save failing ("Unknown error", "Oops, something wrong here!"). And
// the background poll, hosted here for real, raises no alert of its own while
// the save stands in that silence.

import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_transaction.dart';
import 'package:privacy_gui/core/jnap/providers/polling_provider.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_advanced_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_list_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_state.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';

import '../../../common/di.dart';
import '../../../mocks/instant_privacy_provider_mocks.dart';
import '../../../mocks/jnap_service_supported_mocks.dart';
import '../../../mocks/router_repository_mocks.dart';
import '../../../test_data/wifi_list_test_state.dart';

/// Reports a local login and nothing else: the poll's start-up checks it, and
/// the real one reaches into shared preferences and secure storage.
class _LocalAuthNotifier extends AuthNotifier {
  @override
  Future<AuthState> build() =>
      Future.value(const AuthState(loginType: LoginType.local));
}

/// The real notifier, starting from settings the page has already loaded.
///
/// Its build reads the dashboard, the device list and the home page, none of
/// which the save touches.
class _LoadedWifiListNotifier extends WifiListNotifier {
  @override
  WiFiState build() => WiFiState.fromMap(wifiListTestState);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  mockDependencyRegister();

  // LinksysCacheManager.init() reaches for the temp directory on its way to the
  // on-disk cache, and a poll start-up gets there.
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'),
    (_) async => Directory.systemTemp.path,
  );

  late MockRouterRepository mockRepo;
  late ProviderContainer container;

  /// How the router answers the write itself: the one transaction here that
  /// sets anything.
  late Future<JNAPTransactionSuccessWrap> Function() answerWrite;

  /// How it answers everything after the write: the save's own refresh and any
  /// poll that runs beside it.
  late Future<JNAPTransactionSuccessWrap> Function() answerRead;

  /// How many reads the router got, so a test can tell a poll ran.
  late int reads;

  setUp(() {
    initBetterActions();
    // The Advanced save writes only what the router supports and the page set,
    // and with nothing supported it would send an empty write. One setting is
    // enough.
    when((serviceHelper as MockServiceHelper).isSupportDFS()).thenReturn(true);
    reads = 0;
    answerWrite =
        () async => JNAPTransactionSuccessWrap(result: 'OK', data: const []);
    answerRead =
        () async => JNAPTransactionSuccessWrap(result: 'OK', data: const []);
    mockRepo = MockRouterRepository();
    when(mockRepo.send(
      any,
      data: anyNamed('data'),
      extraHeaders: anyNamed('extraHeaders'),
      auth: anyNamed('auth'),
      type: anyNamed('type'),
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((_) async =>
        JNAPSuccess(result: 'OK', output: const {'mode': 'Master'}));
    when(mockRepo.transaction(
      any,
      fetchRemote: anyNamed('fetchRemote'),
      cacheLevel: anyNamed('cacheLevel'),
      timeoutMs: anyNamed('timeoutMs'),
      retries: anyNamed('retries'),
      sideEffectOverrides: anyNamed('sideEffectOverrides'),
    )).thenAnswer((invocation) {
      final builder =
          invocation.positionalArguments.first as JNAPTransactionBuilder;
      final isWrite =
          builder.commands.any((command) => command.key.name.startsWith('set'));
      if (isWrite) {
        return answerWrite();
      }
      reads++;
      return answerRead();
    });
    container = ProviderContainer(overrides: [
      routerRepositoryProvider.overrideWithValue(mockRepo),
      authProvider.overrideWith(() => _LocalAuthNotifier()),
      wifiListProvider.overrideWith(() => _LoadedWifiListNotifier()),
      // A successful poll fans out to this one, through the same mock.
      instantPrivacyProvider.overrideWith(() => MockInstantPrivacyNotifier()),
    ]);
  });

  tearDown(() {
    // PollingNotifier's timers are static; one left running would keep polling
    // into the next test.
    container.read(pollingProvider.notifier).stopPolling();
    container.read(pollingProvider.notifier).init();
    container.dispose();
    reset(serviceHelper as MockServiceHelper);
  });

  /// The answer a router gives once the operator's machine is off its network.
  Future<JNAPTransactionSuccessWrap> noAnswer() =>
      Future.error(ClientException('Failed to fetch'));

  group('a Wi-Fi save', () {
    test('reports a refresh that gets no answer as the router having gone',
        () async {
      answerRead = noAnswer;

      await expectLater(
        container.read(wifiListProvider.notifier).save(),
        throwsA(isA<JNAPSideEffectError>()),
      );
    });

    test('reports a refresh that times out as the router having gone',
        () async {
      answerRead = () => Future.error(TimeoutException('no answer'));

      await expectLater(
        container.read(wifiListProvider.notifier).save(),
        throwsA(isA<JNAPSideEffectError>()),
      );
    });

    test('still reports an error the router answered with', () async {
      // The router is there and talking; this is not the operator being cut
      // off, and calling it 'Router Not Found' would be a plain untruth. Not a
      // refused credential: the poll logs out on one of those, which is its
      // own story.
      answerRead =
          () => Future.error(const JNAPError(result: '_ErrorInvalidInput'));

      await expectLater(
        container.read(wifiListProvider.notifier).save(),
        throwsA(isA<JNAPError>()
            .having((e) => e.result, 'result', '_ErrorInvalidInput')),
      );
    });

    test('still reports a write that got no answer as it was', () async {
      // Without a reply to the write there is nothing to say the change was
      // made, so this is not a save that only lost its refresh.
      answerWrite = noAnswer;

      await expectLater(
        container.read(wifiListProvider.notifier).save(),
        throwsA(isA<ClientException>()),
      );
    });
  });

  group('background polling during a Wi-Fi save', () {
    // Under testWidgets for its fake clock: the background poll reports a router
    // unreachable only after [pollUnreachableAfterInSec] of silence, and the
    // save has to be standing in that silence for that long.

    /// Polling up and answered once, the way a page that saves finds it.
    Future<void> startPolling(WidgetTester tester) async {
      container.read(pollingProvider.notifier).startPolling();
      await tester.pump(const Duration(seconds: pollFirstDelayInSec + 1));
      await tester.pump();
      expect(reads, greaterThan(0), reason: 'polling is up');
    }

    /// A write the router does not answer until the test says so, so the save
    /// can be held open across the silence.
    Completer<JNAPTransactionSuccessWrap> holdTheWrite() {
      final write = Completer<JNAPTransactionSuccessWrap>();
      answerWrite = () => write.future;
      return write;
    }

    /// The poll timer is periodic, and the fake clock fails a test that ends
    /// with one still pending.
    Future<void> stopPolling(WidgetTester tester) async {
      container.read(pollingProvider.notifier).stopPolling();
      await tester.pump();
    }

    /// Takes the router away from every read, then stands past both the next
    /// poll tick and the silence window it would be reported on.
    Future<void> standInTheSilence(WidgetTester tester) async {
      answerRead = noAnswer;
      await tester
          .pump(const Duration(seconds: BuildConfig.refreshTimeInterval));
      await tester.pump(const Duration(seconds: pollUnreachableAfterInSec));
      await tester.pump();
    }

    testWidgets('raises no alert while the router is silent', (tester) async {
      await startPolling(tester);
      final write = holdTheWrite();

      final saving = container.read(wifiListProvider.notifier).save();
      await standInTheSilence(tester);

      expect(container.read(routerUnreachableProvider), 0,
          reason: 'the save reports the router itself');

      write.complete(JNAPTransactionSuccessWrap(result: 'OK', data: const []));
      await expectLater(saving, throwsA(isA<JNAPSideEffectError>()));
      await stopPolling(tester);
    });

    testWidgets('resumes once the save is over', (tester) async {
      await startPolling(tester);
      final write = holdTheWrite();

      final saving = container.read(wifiListProvider.notifier).save();
      write.complete(JNAPTransactionSuccessWrap(result: 'OK', data: const []));
      await saving;

      expect(container.read(pollingProvider.notifier).paused, isFalse);
      await stopPolling(tester);
    });

    testWidgets('raises no alert during the Advanced save either',
        (tester) async {
      await startPolling(tester);
      final write = holdTheWrite();

      final advanced = container.read(wifiAdvancedProvider.notifier);
      advanced.setDFSEnabled(true);
      final saving = advanced.save();
      await standInTheSilence(tester);

      expect(container.read(routerUnreachableProvider), 0);

      write.complete(JNAPTransactionSuccessWrap(result: 'OK', data: const []));
      await expectLater(saving, throwsA(isA<JNAPSideEffectError>()));
      expect(container.read(pollingProvider.notifier).paused, isFalse);
      await stopPolling(tester);
    });
  });

  group('the Wi-Fi Advanced save', () {
    /// Saves a change the page made, so that the save has something to write.
    Future<void> saveAChange() {
      final advanced = container.read(wifiAdvancedProvider.notifier);
      advanced.setDFSEnabled(true);
      return advanced.save();
    }

    test('reports a refresh that gets no answer as the router having gone',
        () async {
      answerRead = noAnswer;

      await expectLater(
        saveAChange(),
        throwsA(isA<JNAPSideEffectError>()),
      );
    });

    test('still reports an error the router answered with', () async {
      answerRead =
          () => Future.error(const JNAPError(result: '_ErrorInvalidInput'));

      await expectLater(
        saveAChange(),
        throwsA(isA<JNAPError>()
            .having((e) => e.result, 'result', '_ErrorInvalidInput')),
      );
    });
  });
}
