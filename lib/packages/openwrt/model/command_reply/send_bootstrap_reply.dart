import '../model.dart';
import 'base/command_reply_base.dart';
import 'base/reply_base.dart';

class SendBootstrapReply extends CommandReplyBase {
  SendBootstrapReply(ReplyStatus status, {required bootstrap})
      : _bootstrap = bootstrap,
        super(status);

  final String _bootstrap;

  @override
  List get commandParameters => ['send_map_dpp_event'];

  @override
  Map getParameter() {
    return {'peer_bs_info': _bootstrap};
  }

  @override
  createReply(ReplyStatus status, Map<String, dynamic> data) {
    return SendBootstrapReply(status, bootstrap: _bootstrap)..data = data;
  }

  @override
  Map createPayload(String? auth, String id) {
    final authCode = auth ?? '00000000000000000000000000000000';
    final params = commandParameters;
    if (params.length < 4) params.add(getParameter());
    return JsonRpcPayload(id: id, method: 'send', params: [authCode, ...params])
        .toJson();
  }
}
