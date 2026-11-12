import 'package:test/test.dart';

import 'boundary_scanner.dart';

void main() {
  group('presentation files', () {
    test('a view that imports router_repository.dart is a violation', () {
      final violations = findBoundaryViolations({
        'lib/page/foo/views/foo_view.dart':
            "import 'package:privacy_gui/core/jnap/router_repository.dart';\n",
      });

      expect(violations, {
        'lib/page/foo/views/foo_view.dart -> lib/core/jnap/router_repository.dart',
      });
    });

    test('a relative import is resolved against the importing file', () {
      final violations = findBoundaryViolations({
        'lib/page/health_check/views/speed_test_view.dart':
            "import '../../../core/jnap/router_repository.dart';\n",
      });

      expect(violations, {
        'lib/page/health_check/views/speed_test_view.dart -> lib/core/jnap/router_repository.dart',
      });
    });

    test('a conditional import is checked on every URI it names', () {
      final violations = findBoundaryViolations({
        'lib/page/foo/views/foo_view.dart':
            "import 'package:privacy_gui/core/utils/stub.dart'\n"
                "    if (dart.library.html) 'package:privacy_gui/core/jnap/router_repository.dart';\n",
      });

      expect(violations, {
        'lib/page/foo/views/foo_view.dart -> lib/core/jnap/router_repository.dart',
      });
    });

    test('commented-out code is not a violation', () {
      final violations = findBoundaryViolations({
        'lib/page/foo/views/foo_view.dart': '/*\n'
            "import 'package:privacy_gui/core/jnap/router_repository.dart';\n"
            '*/\n'
            '  // final repository = ref.read(routerRepositoryProvider);\n'
            '/// Reads [cloudRepositoryProvider] through FooNotifier.\n',
      });

      expect(violations, isEmpty);
    });

    for (final target in [
      'lib/core/jnap/command/base_command.dart',
      'lib/core/jnap/command/http/any_command.dart',
      'lib/core/http/linksys_http_client.dart',
      'lib/core/http/client/any_client.dart',
      'lib/core/cloud/linksys_cloud_repository.dart',
    ]) {
      test('a view that imports $target is a violation', () {
        final violations = findBoundaryViolations({
          'lib/page/foo/views/foo_view.dart':
              "import 'package:privacy_gui/${target.substring(4)}';\n",
        });

        expect(violations, {'lib/page/foo/views/foo_view.dart -> $target'});
      });
    }

    test('a view that imports the rest of lib/core/ is not a violation', () {
      final violations = findBoundaryViolations({
        'lib/page/foo/views/foo_view.dart':
            "import 'package:privacy_gui/core/jnap/actions/better_action.dart';\n"
                "import 'package:privacy_gui/core/cloud/model/cloud_session_model.dart';\n"
                "import 'package:privacy_gui/core/utils/logger.dart';\n",
      });

      expect(violations, isEmpty);
    });

    for (final provider in [
      'routerRepositoryProvider',
      'cloudRepositoryProvider',
    ]) {
      test('a view that reads $provider is a violation', () {
        final violations = findBoundaryViolations({
          'lib/page/foo/views/foo_view.dart':
              "import 'package:privacy_gui/page/foo/_foo.dart';\n"
                  '\n'
                  'final repository = ref.read($provider);\n',
        });

        expect(violations, {'lib/page/foo/views/foo_view.dart -> $provider'});
      });
    }
  });

  group('application files', () {
    for (final directory in [
      'providers',
      'service',
      'services',
      'data',
      'models',
      'model',
    ]) {
      test('a file under $directory/ may import router_repository.dart', () {
        final violations = findBoundaryViolations({
          'lib/page/foo/$directory/foo.dart':
              "import 'package:privacy_gui/core/jnap/router_repository.dart';\n",
        });

        expect(violations, isEmpty);
      });
    }
  });

  group('core files', () {
    test('a core file that imports a page file is a violation', () {
      final violations = findBoundaryViolations({
        'lib/core/jnap/providers/foo_provider.dart':
            "import 'package:privacy_gui/core/jnap/router_repository.dart';\n"
                "import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';\n",
      });

      expect(violations, {
        'lib/core/jnap/providers/foo_provider.dart -> lib/page/vpn/providers/vpn_notifier.dart',
      });
    });

    test('a core file that exports a page file is a violation', () {
      final violations = findBoundaryViolations({
        'lib/core/jnap/models/foo.dart':
            "export '../../../page/nodes/_nodes.dart';\n",
      });

      expect(violations, {
        'lib/core/jnap/models/foo.dart -> lib/page/nodes/_nodes.dart',
      });
    });
  });

  group('other files', () {
    test('a file outside lib/page/ and lib/core/ is not checked', () {
      final violations = findBoundaryViolations({
        'lib/providers/foo/foo_provider.dart':
            "import 'package:privacy_gui/core/jnap/router_repository.dart';\n"
                "import 'package:privacy_gui/page/vpn/providers/vpn_notifier.dart';\n",
      });

      expect(violations, isEmpty);
    });
  });
}
