import 'package:web/web.dart';

import 'package:privacy_gui/constants/build_config.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';

import 'get_local_ip.dart';

String getLocalIp(ProviderReader read) =>
    BuildConfig.forceCommandType == ForceCommand.local
        ? window.location.host
        : (read(connectivityProvider).connectivityInfo.gatewayIp ?? '');

String getFullLocation(ProviderReader read) =>
    BuildConfig.forceCommandType == ForceCommand.local
        ? window.location.toString()
        : '';
