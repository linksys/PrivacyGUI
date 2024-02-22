import 'dart:html';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/constants/build_config.dart';
import 'package:linksys_app/providers/connectivity/connectivity_provider.dart';

String getLocalIp(Ref ref) => BuildConfig.forceCommandType == ForceCommand.local
        ? window.location.host
        : (ref.read(connectivityProvider).connectivityInfo.gatewayIp ?? '');
