import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/providers/side_effect_provider.dart';
import 'package:privacy_gui/core/jnap/result/jnap_result.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/auto_ipoe/models/auto_ipoe_models.dart';
import 'package:privacy_gui/page/auto_ipoe/service/auto_ipoe_service.dart';

class _RecordedCall {
  const _RecordedCall(this.action, this.data);

  final JNAPAction action;
  final Map<String, dynamic> data;
}

class _RecordingRouterRepository extends Fake implements RouterRepository {
  final calls = <_RecordedCall>[];

  @override
  Future<JNAPSuccess> send(
    JNAPAction action, {
    Map<String, dynamic> data = const {},
    Map<String, String> extraHeaders = const {},
    bool auth = false,
    CommandType? type,
    bool fetchRemote = false,
    CacheLevel? cacheLevel,
    int timeoutMs = 10000,
    int retries = 1,
    JNAPSideEffectOverrides? sideEffectOverrides,
  }) async {
    calls.add(_RecordedCall(action, data));
    return const JNAPSuccess(
      result: 'OK',
      output: {'status': <String, dynamic>{}},
    );
  }
}

void main() {
  test('BIGLOBE Set and Apply use the exact shared settings payload', () async {
    final repository = _RecordingRouterRepository();
    final service = AutoIPoEService(repository);
    final settings = const AutoIPoESettings.init().copyWith(
      isEnabled: true,
      selectedMode: AutoIPoEMode.biglobeStaticIp,
      biglobeStaticIpSettings: const BiglobeStaticIPSettings(
        userId: AutoIPoESecret(value: 'biglobe_id'),
        userPassword: AutoIPoESecret(value: 'pw-123'),
      ),
    );

    await service.configureAndApply(settings);

    expect(repository.calls.map((call) => call.action), [
      JNAPAction.setAutoIPoESettings,
      JNAPAction.applyAutoIPoE,
    ]);
    final expectedSettings = {
      'isEnabled': true,
      'selectedMode': 'BIGLOBEStaticIP',
      'biglobeStaticIpSettings': {
        'userId': {'value': 'biglobe_id', 'hasStoredValue': false},
        'userPassword': {'value': 'pw-123', 'hasStoredValue': false},
      },
    };
    expect(repository.calls[0].data, {'settings': expectedSettings});
    expect(repository.calls[1].data, {
      'resetFirst': false,
      'settings': expectedSettings,
    });
  });
}
