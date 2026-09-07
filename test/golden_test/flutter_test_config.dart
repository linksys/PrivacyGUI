import 'dart:async';
import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

import '../util/app_test_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  // Shared with the layout-gate overflow sweeps (test/util/app_test_fonts.dart)
  // so both real-font loaders stay identical — see loadAppFonts() for why.
  //
  // dev-2.7.0 extracted the same inline block to `test/helpers/
  // load_app_test_fonts.dart` in parallel; that copy is gone. Two font loaders
  // means two answers to "how wide is this text", and the overflow gate's
  // measurements are only meaningful if the goldens measure the same font.
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
