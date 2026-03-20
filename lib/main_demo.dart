import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:privacy_gui/di.dart';

import 'demo/data/demo_cache_data.dart';
import 'demo/demo_app.dart';
import 'demo/providers/demo_overrides.dart';
import 'demo/usp/demo_usp_data_loader.dart';

/// Demo mode entry point.
///
/// This entry point creates a fully functional demo version of the app
/// that uses mock data instead of real network connections.
///
/// ## Build Commands
///
/// ```bash
/// # Run locally
/// flutter run -d chrome --target=lib/main_demo.dart
///
/// # Build for web deployment
/// flutter build web --target=lib/main_demo.dart --base-href /PrivacyGUI-Demo/
/// ```
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables (for AWS credentials)
  try {
    await dotenv.load(fileName: 'assets/agents/.env');
  } catch (e) {
    debugPrint('No .env file found, using defaults');
  }

  // Load demo cache data (JNAP + USP)
  await DemoCacheDataLoader.instance.load();
  await DemoUspDataLoader.instance.load();

  // Setup dependencies
  dependencySetup();

  runApp(
    ProviderScope(
      overrides: DemoProviders.allOverrides,
      child: const DemoLinksysApp(),
    ),
  );
}
