import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:web/web.dart';

void config() {
  usePathUrlStrategy();
}

void platformPrint() => window.print();
