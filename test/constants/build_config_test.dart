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

    // Rendered even when unknown: a build that skipped the pipeline showing
    // nothing would look exactly like a build made before any of this existed,
    // which is the ambiguity the stamp exists to remove.
    test('an unknown revision is still rendered beside the version', () {
      expect(BuildConfig.sourceRevisionSuffix, ' (unknown)');
    });
  });

  // The formatting is a pure function precisely so the populated branch is
  // reachable from a test; `sourceRevision` itself is fixed per compilation.
  group('BuildConfig.revisionSuffix', () {
    test('renders a revision in parentheses after a space', () {
      expect(BuildConfig.revisionSuffix('abc1234'), ' (abc1234)');
    });

    test('renders whatever the build supplied, unknown included', () {
      expect(BuildConfig.revisionSuffix(BuildConfig.unknownSourceRevision),
          ' (unknown)');
    });
  });
}
