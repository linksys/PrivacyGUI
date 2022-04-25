import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:moab_poc/utils.dart';

import 'model/command_reply/authenticate_reply.dart';
import 'model/command_reply/base/command_reply_base.dart';
import 'model/command_reply/base/error_reply.dart';
import 'model/command_reply/base/reply_base.dart';
import 'model/device.dart';
import 'model/identity.dart';

class OpenWRTClient {
  Identity? _identity;
  late Device _device;

  static const int Timeout = 3;

  String get _baseURL {
    String url = "http://${_device.address}";

    if (_device.port.isNotEmpty) url += ":" + _device.port;
    return url;
  }

  OpenWRTClient(Device d) {
    _device = d;
  }

  HttpClient _getClient() {
    var cli = HttpClient();
    return cli;
  }

  Future<List<CommandReplyBase>> execute(
      String? auth, List<CommandReplyBase> commands) async {
    final http = _getClient();
    http.connectionTimeout = const Duration(seconds: Timeout);
    try {
      final request = await http.postUrl(Uri.parse(_baseURL + "/ubus"));
      request.headers.set('content-type', 'application/json');

      final body = _buildBodyPayload(auth, commands);

      request.contentLength = body.length;
      request.add(body);
      HttpClientResponse response =
          await request.close().timeout(const Duration(seconds: 10));
      http.close();
      print("response status code: ${response.statusCode}");
      if (response.statusCode == 200) {
        final result = _parseResponse(response, commands);
        return Future.value(result);
      }
      return Future.value([ErrorReply(ReplyStatus.forbidden)]);
    } on HandshakeException catch (ex) {
      if (Utils.ReleaseMode) debugPrint(ex.toString());
      return Future.value([ErrorReply(ReplyStatus.handshakeError)]);
    } on Exception catch (ex) {
      if (Utils.ReleaseMode) debugPrint(ex.toString());
      return Future.value([ErrorReply(ReplyStatus.timeout)]);
    }
  }

  Future<String> authenticate({Identity? input}) async {
    if (input == null && _identity == null) {
      throw Exception('Unauthorized');
    }
    final identity = input ?? _identity!;
    List<CommandReplyBase> commands = [
      AuthenticateReply.withIdentity(identity)
    ];
    final authObj = (await execute(null, commands)).first;
    if (authObj is AuthenticateReply && authObj.authCode != null) {
      _identity = identity;
      return Future.value(authObj.authCode);
    } else {
      throw Exception('Authorization fail');
    }
  }

  List<int> _buildBodyPayload(String? auth, List<CommandReplyBase> commands) {
    List<Map> data = [];
    var counter = 1;
    for (var cmd in commands) {
      var jsonRPC = cmd.createPayload(auth, '${counter++}');
      data.add(jsonRPC);
    }
    var jsonText = json.encode(data);
    var body = utf8.encode(jsonText);
    print('BodyPayload: ${String.fromCharCodes(body)}');
    return body;
  }

  Future<List<CommandReplyBase>> _parseResponse(
      HttpClientResponse response, List<CommandReplyBase> commands) async {
    final jsonText = await response.transform(utf8.decoder).join();
    print('response:: $jsonText');
    var jsonData = (json.decode(jsonText) as List<dynamic>)
        .map((x) => x as Map<String, dynamic>);

    List<CommandReplyBase> lstResponse = [];
    var idCounter = 1;
    for (final cmd in commands) {
      var cmdData = jsonData.firstWhere((x) => int.parse(x["id"]) == idCounter);
      lstResponse.add(cmd.createReply(ReplyStatus.ok, cmdData));
      idCounter++;
    }
    print('response:: lstResponse: $lstResponse');
    return lstResponse;
  }
}
