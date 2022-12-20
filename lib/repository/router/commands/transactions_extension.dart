import 'package:linksys_moab/network/jnap/jnap_command_queue.dart';
import 'package:linksys_moab/network/jnap/jnap_transaction.dart';
import 'package:linksys_moab/network/jnap/result/jnap_result.dart';
import 'package:linksys_moab/repository/router/router_repository.dart';

extension TransactionCommands on RouterRepository {
  Future<JNAPSuccess> transaction(JNAPTransactionBuilder builder) async {
    final payload = builder.commands.entries
        .map((entry) =>
            {'action': entry.key.actionValue, 'request': entry.value})
        .toList();
    final command = createTransaction(payload, needAuth: builder.auth);

    final result = await CommandQueue().enqueue(command);
    return handleJNAPResult(result);
  }
}
