import 'dart:async';
import 'package:alchemist/alchemist.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/load_app_test_fonts.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  TestWidgetsFlutterBinding.ensureInitialized();
  await loadAppTestFonts();

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
