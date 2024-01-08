import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/provider/app_settings/app_settings.dart';

final appSettingsProvider = StateProvider((ref) => const AppSettings());
