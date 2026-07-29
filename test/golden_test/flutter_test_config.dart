import 'dart:async';
import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/app_test_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Shared with the dashboard-card overflow gate (test/util/app_test_fonts.dart)
  // so both real-font loaders stay identical — see loadAppFonts() for why.
  await loadAppFonts();

  return AlchemistConfig.runWithConfig(
    config: AlchemistConfig(
      ciGoldensConfig: CiGoldensConfig(enabled: false),
      platformGoldensConfig: PlatformGoldensConfig(
        enabled: true,
        renderShadows: false,
        filePathResolver: (fileName, _) => 'goldens/$fileName.png',
        diffThreshold: 0.025,
      ),
    ),
    run: testMain,
  );
}
