import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/connectivity/connectivity_provider.dart';

String getLocalIp(Ref ref) =>
    ref.read(connectivityProvider).connectivityInfo.gatewayIp ?? '';


String getFullLocation(Ref ref) =>
    throw UnsupportedError('[Platform ERROR] Get Full Location');