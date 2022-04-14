import 'package:moab_poc/packages/openwrt/model/command_reply/base/reply_base.dart';

import 'command_reply_base.dart';

class ErrorReply extends CommandReplyBase {
  ErrorReply(ReplyStatus status) : super(status);

  @override
  List get commandParameters => [];

  @override
  createReply(ReplyStatus status, Map<String, dynamic> data) {
    return ErrorReply(status);
  }
}
