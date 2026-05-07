import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/dashboard/providers/package_widget_data_provider.dart';
import 'package:test/test.dart';

void main() {
  // -----------------------------------------------------------------------
  // PackageWidgetDataNotifier
  // -----------------------------------------------------------------------
  group('PackageWidgetDataNotifier', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is empty map', () {
      final data = container.read(packageWidgetDataProvider('w1'));
      expect(data, isEmpty);
    });

    test('setAll replaces entire state', () {
      final notifier = container.read(packageWidgetDataProvider('w1').notifier);

      notifier.setAll({'a': 1, 'b': 'hello'});

      final data = container.read(packageWidgetDataProvider('w1'));
      expect(data, {'a': 1, 'b': 'hello'});
    });

    test('setAll overwrites previous data', () {
      final notifier = container.read(packageWidgetDataProvider('w1').notifier);

      notifier.setAll({'old': true});
      notifier.setAll({'new': false});

      final data = container.read(packageWidgetDataProvider('w1'));
      expect(data, {'new': false});
      expect(data.containsKey('old'), false);
    });

    test('updatePath patches a single key', () {
      final notifier = container.read(packageWidgetDataProvider('w1').notifier);

      notifier.setAll({'a': 1, 'b': 2, 'c': 3});
      notifier.updatePath('b', 99);

      final data = container.read(packageWidgetDataProvider('w1'));
      expect(data, {'a': 1, 'b': 99, 'c': 3});
    });

    test('updatePath adds a new key', () {
      final notifier = container.read(packageWidgetDataProvider('w1').notifier);

      notifier.setAll({'a': 1});
      notifier.updatePath('new_key', 'value');

      final data = container.read(packageWidgetDataProvider('w1'));
      expect(data, {'a': 1, 'new_key': 'value'});
    });

    test('clear resets to empty', () {
      final notifier = container.read(packageWidgetDataProvider('w1').notifier);

      notifier.setAll({'a': 1, 'b': 2});
      notifier.clear();

      final data = container.read(packageWidgetDataProvider('w1'));
      expect(data, isEmpty);
    });

    test('family isolation: different widgetIds are independent', () {
      final n1 = container.read(packageWidgetDataProvider('w1').notifier);
      final n2 = container.read(packageWidgetDataProvider('w2').notifier);

      n1.setAll({'x': 1});
      n2.setAll({'y': 2});

      expect(container.read(packageWidgetDataProvider('w1')), {'x': 1});
      expect(container.read(packageWidgetDataProvider('w2')), {'y': 2});

      n1.clear();
      expect(container.read(packageWidgetDataProvider('w1')), isEmpty);
      expect(container.read(packageWidgetDataProvider('w2')), {'y': 2});
    });
  });
}
