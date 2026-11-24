import 'package:flutter/widgets.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/validator_rules/lan_host_ipv4.dart';

/// The message for [problem], the same on every form that checks an address
/// as a LAN host's (#1838). It is the string [LanHostIpv4ProblemKey.messageKey]
/// names.
String lanHostIpv4Message(BuildContext context, LanHostIpv4Problem problem) =>
    switch (problem) {
      LanHostIpv4Problem.format => loc(context).invalidIpv4Format,
      LanHostIpv4Problem.reserved => loc(context).reservedIpNotAllowed,
      LanHostIpv4Problem.notLanHost => loc(context).invalidIpAddress,
    };
