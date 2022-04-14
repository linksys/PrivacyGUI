import 'package:moab_poc/packages/openwrt/model/command_reply/base/reply_base.dart';

import '../../json_rpc_payload.dart';

abstract class CommandReplyBase extends ReplyBase {
  late int _replyTimeStamp;
  int get replyTimeStamp {
    return _replyTimeStamp;
  }

  CommandReplyBase(ReplyStatus status) : super(status) {
    _replyTimeStamp = DateTime.now().millisecondsSinceEpoch;
  }

  List<dynamic> get commandParameters;
  late Map<String, dynamic> data;

  dynamic createReply(
    ReplyStatus status,
    Map<String, dynamic> data,
  );

  Map getParameter() {
    return {};
  }

  Map createPayload(String? auth, String id) {
    final authCode = auth ?? '00000000000000000000000000000000';
    final params = commandParameters;
    if (params.length < 4) params.add(getParameter());
    return JsonRpcPayload(id: id, method: 'call', params: [authCode, ...params])
        .toJson();
  }
}
