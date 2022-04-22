import 'package:moab_poc/packages/openwrt/model/command_reply/base/reply_base.dart';

import 'base/command_reply_base.dart';

class WirelessStateReply extends CommandReplyBase {
  WirelessStateReply(ReplyStatus status) : super(status);

  @override
  List get commandParameters => ['uci', 'state'];

  @override
  Map getParameter() {
    return {'config': 'wireless'};
  }

  @override
  createReply(ReplyStatus status, Map<String, dynamic> data) {
    return WirelessStateReply(status)..data = data;
  }
}
