import 'package:moab_poc/packages/openwrt/model/command_reply/base/base.dart';

class NetworkStatusReply extends CommandReplyBase {
  NetworkStatusReply(ReplyStatus status) : super(status);

  @override
  List get commandParameters => ['network.device', 'status'];

  @override
  Map getParameter() {
    return {'name': 'eth1'};
  }

  @override
  createReply(ReplyStatus status, Map<String, dynamic> data) {
    return NetworkStatusReply(status)..data = data;
  }
}
