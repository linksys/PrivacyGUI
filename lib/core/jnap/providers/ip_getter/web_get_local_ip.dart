import 'dart:html';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';

String getLocalIp(Ref ref) => BuildConfig.forceCommandType == ForceCommand.local
    ? window.location.host
    : (ref.read(connectivityProvider).connectivityInfo.gatewayIp ?? '');

String getFullLocation(Ref ref) =>
    BuildConfig.forceCommandType == ForceCommand.local
        ? window.location.toString()
        : '';
