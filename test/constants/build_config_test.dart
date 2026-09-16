import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/constants/build_config.dart';

void main() {
  // These lock the behaviour of a build that passes no --dart-define, which is
  // what every existing caller of build_web.sh produces today. Changing any of
  // them changes what ships, so they are worth failing loudly on.
  group('BuildConfig build-time defaults', () {
    test('remote assistance stays off unless the build asks for it', () {
      expect(BuildConfig.enableRemoteAssistance, isFalse);
    });

    test('source revision is unknown when the build supplies none', () {
      expect(BuildConfig.sourceRevision, BuildConfig.unknownSourceRevision);
    });

    // A plain `flutter run` has no revision, and rendering "(unknown)" beside
    // the version in that case is noise rather than information.
    test('an unknown revision renders no suffix beside the version', () {
      expect(BuildConfig.sourceRevisionSuffix, isEmpty);
    });
  });
}
