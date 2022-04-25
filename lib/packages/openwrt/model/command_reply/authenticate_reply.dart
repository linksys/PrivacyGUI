import 'package:moab_poc/packages/openwrt/model/identity.dart';

import 'base/command_reply_base.dart';
import 'base/reply_base.dart';

class AuthenticateReply extends CommandReplyBase {
  AuthenticateReply(ReplyStatus status,
      {this.authCode, this.username, this.password})
      : super(status);

  factory AuthenticateReply.withIdentity(Identity identity) {
    return AuthenticateReply(ReplyStatus.unknown,
        username: identity.username, password: identity.password);
  }

  final String? authCode;
  final String? username;
  final String? password;

  @override
  List get commandParameters => ['session', 'login'];

  @override
  Map getParameter() {
    return {"username": username, "password": password};
  }

  @override
  CommandReplyBase createReply(ReplyStatus status, Map<String, dynamic> data) {
    final result = data['result'] as List;
    if (result.length > 1) {
      final authCode = data['result'][1]['ubus_rpc_session'];
      return AuthenticateReply(status, authCode: authCode);
    } else {
      // unauthorized
      return AuthenticateReply(status, authCode: '');
    }
  }
}
