import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:privacy_gui/page/apps/models/app_info_ui_model.dart';
import 'package:privacy_gui/page/apps/providers/apps_capability_provider.dart';
import 'package:privacy_gui/page/apps/services/usp_apps_service.dart';
import 'package:test/test.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

class _MockAppsService extends Mock implements UspAppsService {}

AppInfoUIModel _app(String name) => AppInfoUIModel(
      name: name,
      description: '',
      link: '',
      version: '1.0',
      iconData: Icons.apps,
      color: Colors.blueAccent,
      category: AppCategory.system,
    );

void main() {
  late _MockAppsService mock;

  setUp(() {
    mock = _MockAppsService();
  });

  group('appsCapabilityProvider', () {
    test('returns true when fetchApps succeeds', () async {
      when(() => mock.fetchApps()).thenAnswer((_) async => [_app('a')]);

      final container = ProviderContainer(overrides: [
        uspAppsServiceProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(appsCapabilityProvider.future);
      expect(result, isTrue);
    });

    test('returns false when fetchApps throws', () async {
      when(() => mock.fetchApps()).thenThrow(Exception('404'));

      final container = ProviderContainer(overrides: [
        uspAppsServiceProvider.overrideWithValue(mock),
      ]);
      addTearDown(container.dispose);

      final result = await container.read(appsCapabilityProvider.future);
      expect(result, isFalse);
    });

    test('type is FutureProvider<bool>', () {
      final FutureProvider<bool> provider = appsCapabilityProvider;
      expect(provider, isNotNull);
    });
  });
}
