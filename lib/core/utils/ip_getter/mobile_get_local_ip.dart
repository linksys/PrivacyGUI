import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';

import 'get_local_ip.dart';

String getLocalIp(ProviderReader read) =>
    read(connectivityProvider).connectivityInfo.gatewayIp ?? '';

String getFullLocation(ProviderReader read) =>
    throw UnsupportedError('[Platform ERROR] Get Full Location');
