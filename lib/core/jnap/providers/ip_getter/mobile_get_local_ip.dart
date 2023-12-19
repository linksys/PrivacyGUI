import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/connectivity/connectivity_provider.dart';

String getLocalIp(Ref ref) => ref.read(connectivityProvider).connectivityInfo.gatewayIp ?? '';
