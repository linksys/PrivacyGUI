import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';

import '../../../mocks/device_manager_notifier_mocks.dart';
import '../../../mocks/router_repository_mocks.dart';

const _target = '02:AA:BB:CC:DD:01';
const _other = '02:AA:BB:CC:DD:02';

class _Privacy extends InstantPrivacyNotifier {
  _Privacy(this.initial);
  final InstantPrivacyState initial;

  @override
  InstantPrivacyState build() => initial;

  @override
  Future<InstantPrivacyState> fetch(
          {bool fetchRemote = false, bool statusOnly = false}) async =>
      state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockRouterRepository repository;
  late ProviderContainer container;
  late _Privacy privacy;

  void create(MacFilterMode mode, List<String> addresses) {
    repository = MockRouterRepository();
    when(repository.send(JNAPAction.setMACFilterSettings,
            data: anyNamed('data'),
            auth: true,
            fetchRemote: true,
            cacheLevel: CacheLevel.noCache))
        .thenAnswer((_) async => const JNAPSuccess(result: 'OK', output: {}));
    privacy = _Privacy(InstantPrivacyState(
      status: InstantPrivacyStatus(mode: mode),
      settings: InstantPrivacySettings(
        mode: mode,
        macAddresses: mode == MacFilterMode.allow ? addresses : const [],
        denyMacAddresses: mode == MacFilterMode.deny ? addresses : const [],
        maxMacAddresses: 32,
      ),
    ));
    final manager = MockDeviceManagerNotifier();
    when(manager.build()).thenReturn(const DeviceManagerState());
    container = ProviderContainer(overrides: [
      instantPrivacyProvider.overrideWith(() => privacy),
      routerRepositoryProvider.overrideWithValue(repository),
      deviceManagerProvider.overrideWith(() => manager),
    ]);
    container.read(instantPrivacyProvider);
    addTearDown(container.dispose);
  }

  Map<String, dynamic> saved() => verify(repository.send(
        JNAPAction.setMACFilterSettings,
        data: captureAnyNamed('data'),
        auth: true,
        fetchRemote: true,
        cacheLevel: CacheLevel.noCache,
      )).captured.single as Map<String, dynamic>;

  Future<void> saveDenyThroughUi() async {
    // MacFilteringView copies its displayed deny list into the save field
    // immediately before calling save(). Removing entries alone is staged.
    privacy.setMacAddressList(privacy.state.settings.denyMacAddresses);
    await privacy.save();
  }

  test('unblocking one denied client preserves every other block', () async {
    create(MacFilterMode.deny, [_target, _other]);
    // FilteredDevicesView's Remove action, followed by the parent page's Save.
    privacy.removeSelection([_target], true);
    await saveDenyThroughUi();
    expect(saved(), {
      'macFilterMode': 'Deny',
      'macAddresses': [_other]
    });
  });

  test('unblocking the last denied client saves an empty deny list', () async {
    create(MacFilterMode.deny, [_target]);
    privacy.removeSelection([_target], true);
    await saveDenyThroughUi();
    expect(saved(), {'macFilterMode': 'Deny', 'macAddresses': <String>[]});
  });

  test('saving a deny list preserves blocks without any edits', () async {
    create(MacFilterMode.deny, [_target, _other]);
    await saveDenyThroughUi();
    expect(saved(), {
      'macFilterMode': 'Deny',
      'macAddresses': [_target, _other]
    });
  });

  test('restoring an allowed client leaves the allow policy in place',
      () async {
    create(MacFilterMode.allow, [_other]);
    privacy.setSelection([_target]);
    await privacy.save();
    expect(saved(), {
      'macFilterMode': 'Allow',
      'macAddresses': [_other, _target]
    });
  });
}
