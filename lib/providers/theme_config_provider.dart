import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/data/providers/session_provider.dart';
import 'package:privacy_gui/theme/theme_config_loader.dart';
import 'package:privacy_gui/theme/theme_json_config.dart';

/// Provides the active [ThemeJsonConfig] for the application.
///
/// Automatically resolves the correct theme based on:
/// 1. **Environment overrides** (CI/CD, network, assets, default)
/// 2. **Device model number** from [sessionProvider]
///
/// Reactively updates when the connected router model changes.
final themeConfigProvider = FutureProvider<ThemeJsonConfig>((ref) async {
  final modelNumber = ref.watch(
    sessionProvider.select((state) => state.modelNumber),
  );
  return ThemeConfigLoader().load(modelNumber: modelNumber);
});
