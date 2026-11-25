import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/command/base_command.dart';
import 'package:privacy_gui/core/jnap/jnap_command_executor_mixin.dart';

class _Executor with JNAPCommandExecutor<Object> {
  @override
  Future<Object> execute(BaseCommand command) => throw UnimplementedError();

  @override
  void dropCommand(String id) {}
}

void main() {
  test('an executor waits 10 s and retries once unless told otherwise', () {
    final executor = _Executor();

    expect(executor.timeoutMs, 10000);
    expect(executor.retries, 1);
  });

  test('keeps the timeout and retries the repository sets for a command', () {
    // The firmware update's long wait, as firmware_update_provider sets it.
    final executor = _Executor()
      ..timeoutMs = 300000
      ..retries = 0;

    expect(executor.timeoutMs, 300000);
    expect(executor.retries, 0);
  });
}
