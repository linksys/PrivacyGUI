import 'package:moab_poc/packages/openwrt/model/command_reply/base/base.dart';

class WanStatusReply extends CommandReplyBase {
  WanStatusReply(ReplyStatus status) : super(status);

  @override
  List get commandParameters => ['network.interface.wan', 'status'];

  @override
  createReply(ReplyStatus status, Map<String, dynamic> data) {
    return WanStatusReply(status)..data = data;
  }
}
