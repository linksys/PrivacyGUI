import 'package:fake_async/fake_async.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/page/apps/providers/apps_capability_provider.dart';
import 'package:privacy_gui/page/dashboard/models/package_widget_template.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_data_provider.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_loader.dart';
import 'package:privacy_gui/page/dashboard/providers/usp_layout_controller.dart';
import 'package:privacy_gui/page/dashboard/services/package_widget_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPackageWidgetService extends Mock implements PackageWidgetService {}

/// The real layout notifier, recording which cards the loader takes off the
/// dashboard instead of rewriting the stored layout.
class _RecordingLayout extends UspSliverDashboardControllerNotifier {
  _RecordingLayout(super.ref);

  final removed = <String>[];

  @override
  Future<void> removeWidget(String id) async => removed.add(id);
}

/// The template the router serves at [url]: `/a/widget.json` is `pkg_a`, any
/// other is `pkg_b`.
PackageWidgetTemplate _templateAt(String url) {
  final id = url == '/a/widget.json' ? 'pkg_a' : 'pkg_b';
  return PackageWidgetTemplate.fromJson({'widgetId': id, 'displayName': id});
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(<String>[]);
    registerFallbackValue(
        const WidgetSubscriptionConfig(paths: [], notifType: 'ValueChange'));
    registerFallbackValue(const HttpDataSourceConfig(url: '', mapping: {}));
    void onValueChange(String path, Object? value) {}
    registerFallbackValue(onValueChange);
  });

  test(
      'a package that leaves apps.json takes its card and its data with it, '
      'and nothing is fetched or subscribed for it', () {
    fakeAsync((async) {
      SharedPreferences.setMockInitialValues({});
      final service = MockPackageWidgetService();
      var appsJsonReads = 0;
      when(() => service.fetchWidgetEntries()).thenAnswer((_) async =>
          ++appsJsonReads == 1
              ? {'pkg_a': '/a/widget.json', 'pkg_b': '/b/widget.json'}
              : {'pkg_a': '/a/widget.json'});
      when(() => service.fetchTemplate(any())).thenAnswer((invocation) async {
        final id = (invocation.positionalArguments.single as String) ==
                '/a/widget.json'
            ? 'pkg_a'
            : 'pkg_b';
        return PackageWidgetTemplate.fromJson(
            {'widgetId': id, 'displayName': id});
      });
      late _RecordingLayout layout;
      final container = ProviderContainer(overrides: [
        appsCapabilityProvider.overrideWith((ref) async => true),
        packageWidgetServiceProvider.overrideWithValue(service),
        uspSliverDashboardControllerProvider
            .overrideWith((ref) => layout = _RecordingLayout(ref)),
      ]);
      addTearDown(container.dispose);

      container.listen(packageWidgetLoaderProvider, (_, __) {});
      async.flushMicrotasks();
      expect(container.read(packageWidgetLoaderProvider).valueOrNull?.keys,
          unorderedEquals(['pkg_a', 'pkg_b']),
          reason: 'the premise: both packages were loaded');
      container
          .read(packageWidgetDataProvider('pkg_b').notifier)
          .setAll({'Device.X': 1});

      // The 30-second apps.json poll sees pkg_b gone.
      async.elapse(const Duration(seconds: 30));

      expect(container.read(packageWidgetLoaderProvider).valueOrNull?.keys,
          ['pkg_a']);
      expect(layout.removed, ['pkg_b']);
      expect(container.read(packageWidgetDataProvider('pkg_b')), isEmpty);
      verifyNever(() => service.fetchUspPaths(any()));
      verifyNever(() => service.subscribeValueChanges(
            widgetId: any(named: 'widgetId'),
            subscription: any(named: 'subscription'),
            onValueChange: any(named: 'onValueChange'),
          ));
      verifyNever(() => service.fetchHttpData(any()));
    });
  });

  test('a failed apps.json poll takes no card off the dashboard', () {
    // The loader's rule, moved here from its own http.get: a poll that could not
    // read apps.json cannot tell "removed" from "unavailable", so it removes
    // nothing. Two failures: an answer that is not 200 (the service returns
    // null), and a request that failed (it throws a ServiceError).
    fakeAsync((async) {
      SharedPreferences.setMockInitialValues({});
      final service = MockPackageWidgetService();
      var appsJsonReads = 0;
      when(() => service.fetchWidgetEntries()).thenAnswer((_) async {
        switch (++appsJsonReads) {
          case 1:
            return {'pkg_a': '/a/widget.json', 'pkg_b': '/b/widget.json'};
          case 2:
            return null;
          default:
            throw const NetworkError();
        }
      });
      when(() => service.fetchTemplate(any())).thenAnswer((invocation) async =>
          _templateAt(invocation.positionalArguments.single as String));
      _RecordingLayout? layout;
      final container = ProviderContainer(overrides: [
        appsCapabilityProvider.overrideWith((ref) async => true),
        packageWidgetServiceProvider.overrideWithValue(service),
        uspSliverDashboardControllerProvider
            .overrideWith((ref) => layout = _RecordingLayout(ref)),
      ]);
      addTearDown(container.dispose);

      container.listen(packageWidgetLoaderProvider, (_, __) {});
      async.flushMicrotasks();
      async.elapse(const Duration(seconds: 60));

      expect(appsJsonReads, 3,
          reason: 'the premise: two polls ran, both failed');
      expect(container.read(packageWidgetLoaderProvider).valueOrNull?.keys,
          unorderedEquals(['pkg_a', 'pkg_b']));
      expect(layout?.removed ?? const <String>[], isEmpty);
    });
  });

  test('a router without apps loads nothing and sends nothing', () async {
    final service = MockPackageWidgetService();
    final container = ProviderContainer(overrides: [
      appsCapabilityProvider.overrideWith((ref) async => false),
      packageWidgetServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);

    expect(await container.read(packageWidgetLoaderProvider.future), isEmpty);
    verifyZeroInteractions(service);
  });

  test('the first load leaves out a template that does not load', () async {
    final service = MockPackageWidgetService();
    when(() => service.fetchWidgetEntries()).thenAnswer(
        (_) async => {'pkg_a': '/a/widget.json', 'pkg_b': '/b/widget.json'});
    when(() => service.fetchTemplate('/a/widget.json'))
        .thenAnswer((_) async => _templateAt('/a/widget.json'));
    when(() => service.fetchTemplate('/b/widget.json'))
        .thenAnswer((_) async => null);
    final container = ProviderContainer(overrides: [
      appsCapabilityProvider.overrideWith((ref) async => true),
      packageWidgetServiceProvider.overrideWithValue(service),
    ]);
    addTearDown(container.dispose);

    final templates = await container.read(packageWidgetLoaderProvider.future);

    expect(templates.keys, ['pkg_a']);
  });
}
