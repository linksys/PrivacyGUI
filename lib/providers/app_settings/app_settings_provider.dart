import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/providers/app_settings/app_settings.dart';

final appSettingsProvider = StateProvider((ref) => const AppSettings());
