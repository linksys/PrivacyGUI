import 'base/command_reply_base.dart';
import 'base/reply_base.dart';

class SystemInfoReply extends CommandReplyBase {
  SystemInfoReply(ReplyStatus status) : super(status);

  @override
  List get commandParameters => ['system', 'info'];

  @override
  createReply(ReplyStatus status, Map<String, dynamic> data) {
    return SystemInfoReply(status)..data = data;
  }
}
