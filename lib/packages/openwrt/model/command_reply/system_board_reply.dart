import 'package:moab_poc/packages/openwrt/model/command_reply/base/command_reply_base.dart';
import 'package:moab_poc/packages/openwrt/model/command_reply/base/reply_base.dart';

class SystemBoardReply extends CommandReplyBase {
  SystemBoardReply(ReplyStatus status) : super(status);

  @override
  List get commandParameters => ['system', 'board'];

  @override
  createReply(ReplyStatus status, Map<String, dynamic> data) {
    return SystemBoardReply(status)..data = data;
  }
}
