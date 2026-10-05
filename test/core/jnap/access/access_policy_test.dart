import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/access/access_policy.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/providers/auth/auth_provider.dart';

class _FixedAuth extends AuthNotifier {
  _FixedAuth(this._loginType);
  final LoginType _loginType;

  @override
  Future<AuthState> build() async => AuthState(loginType: _loginType);
}

void main() {
  Future<AccessPolicy> policyFor(LoginType loginType,
      {required bool remoteReadOnly}) async {
    final container = ProviderContainer(overrides: [
      authProvider.overrideWith(() => _FixedAuth(loginType)),
      remoteReadOnlyEnabledProvider.overrideWithValue(remoteReadOnly),
    ]);
    addTearDown(container.dispose);
    await container.read(authProvider.future);
    return container.read(accessPolicyProvider);
  }

  group('accessPolicyProvider', () {
    test('a remote login is read-only when the build asks for it', () async {
      final policy = await policyFor(LoginType.remote, remoteReadOnly: true);
      expect(policy.canWrite, isFalse);
    });

    test('a remote login can write when the build does not ask', () async {
      final policy = await policyFor(LoginType.remote, remoteReadOnly: false);
      expect(policy.canWrite, isTrue);
    });

    // Keyed on how the user logged in, not on the `force` build flag: a
    // Guardian reaching a router through a normal build must still be held to
    // read-only.
    test('a local login can always write', () async {
      expect((await policyFor(LoginType.local, remoteReadOnly: true)).canWrite,
          isTrue);
      expect((await policyFor(LoginType.none, remoteReadOnly: true)).canWrite,
          isTrue);
    });
  });

  group('AccessPolicy.checkSend', () {
    const readOnly = AccessPolicy(canWrite: false);
    const full = AccessPolicy(canWrite: true);

    test('lets a read through in read-only mode', () {
      expect(
          () => readOnly.checkSend(JNAPAction.getDeviceInfo), returnsNormally);
    });

    test('refuses a write in read-only mode, naming the action', () {
      expect(
        () => readOnly.checkSend(JNAPAction.setWANSettings),
        throwsA(isA<ReadOnlyAccessException>()
            .having((e) => e.action, 'action', JNAPAction.setWANSettings)),
      );
    });

    test('a firmware check stays a read in read-only mode', () {
      expect(
          () => readOnly.checkSend(JNAPAction.updateFirmwareNow,
              data: {'onlyCheck': true}),
          returnsNormally);
      expect(() => readOnly.checkSend(JNAPAction.updateFirmwareNow),
          throwsA(isA<ReadOnlyAccessException>()));
    });

    test('lets everything through with full access', () {
      expect(() => full.checkSend(JNAPAction.setWANSettings), returnsNormally);
      expect(() => full.checkSend(JNAPAction.factoryReset), returnsNormally);
    });
  });

  group('AccessPolicy.checkTransaction', () {
    const readOnly = AccessPolicy(canWrite: false);

    test('refuses a transaction carrying a write, naming that write', () {
      expect(
        () => readOnly.checkTransaction([
          const MapEntry(JNAPAction.getWANSettings, <String, dynamic>{}),
          const MapEntry(JNAPAction.setWANSettings, <String, dynamic>{}),
        ]),
        throwsA(isA<ReadOnlyAccessException>()
            .having((e) => e.action, 'action', JNAPAction.setWANSettings)),
      );
    });

    test('lets an all-read transaction through', () {
      expect(
        () => readOnly.checkTransaction([
          const MapEntry(JNAPAction.getWANSettings, <String, dynamic>{}),
          const MapEntry(JNAPAction.getLANSettings, <String, dynamic>{}),
        ]),
        returnsNormally,
      );
    });
  });
}
