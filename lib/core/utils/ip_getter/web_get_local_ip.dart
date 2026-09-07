import 'package:web/web.dart';

import 'get_local_ip.dart';

String getLocalIp(ProviderReader read) => window.location.host;

String getFullLocation(ProviderReader read) => window.location.toString();

String getCloudOrigin() => window.location.origin;
