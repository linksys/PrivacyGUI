import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/framework/diagnostic_loggable.dart';

// --- Test Models ---

/// Simple model with primitive types
class SimpleModel extends Equatable with DiagnosticLoggable {
  final String name;
  final int count;
  final bool active;

  const SimpleModel({
    required this.name,
    required this.count,
    required this.active,
  });

  @override
  Map<String, Object?> get namedProps => {
        'name': name,
        'count': count,
        'active': active,
      };
}

/// Model with nullable fields
class NullableModel extends Equatable with DiagnosticLoggable {
  final String? label;
  final int? value;

  const NullableModel({this.label, this.value});

  @override
  Map<String, Object?> get namedProps => {
        'label': label,
        'value': value,
      };
}

/// Model with nested DiagnosticLoggable
class NestedModel extends Equatable with DiagnosticLoggable {
  final SimpleModel child;

  const NestedModel({required this.child});

  @override
  Map<String, Object?> get namedProps => {'child': child};
}

/// Model with list of DiagnosticLoggable
class ListModel extends Equatable with DiagnosticLoggable {
  final List<SimpleModel> items;

  const ListModel({required this.items});

  @override
  Map<String, Object?> get namedProps => {'items': items};
}

/// Model with map values
class MapModel extends Equatable with DiagnosticLoggable {
  final Map<String, SimpleModel> itemMap;

  const MapModel({required this.itemMap});

  @override
  Map<String, Object?> get namedProps => {'itemMap': itemMap};
}

/// Model with DateTime
class DateTimeModel extends Equatable with DiagnosticLoggable {
  final DateTime timestamp;

  const DateTimeModel({required this.timestamp});

  @override
  Map<String, Object?> get namedProps => {'timestamp': timestamp};
}

/// Model with Duration
class DurationModel extends Equatable with DiagnosticLoggable {
  final Duration duration;

  const DurationModel({required this.duration});

  @override
  Map<String, Object?> get namedProps => {'duration': duration};
}

/// Test enum
enum TestStatus { active, inactive, pending }

/// Model with enum
class EnumModel extends Equatable with DiagnosticLoggable {
  final TestStatus status;

  const EnumModel({required this.status});

  @override
  Map<String, Object?> get namedProps => {'status': status};
}

/// Model with Map<int, String> (non-string keys)
class NonStringKeyMapModel extends Equatable with DiagnosticLoggable {
  final Map<int, String> data;

  const NonStringKeyMapModel({required this.data});

  @override
  Map<String, Object?> get namedProps => {'data': data};
}

/// Model with loggable = false
class NonLoggableModel extends Equatable with DiagnosticLoggable {
  final String data;

  const NonLoggableModel({required this.data});

  @override
  Map<String, Object?> get namedProps => {'data': data};

  @override
  bool get loggable => false;
}

/// Model simulating Data provider pattern (wraps UIModel)
class TestUIModel extends Equatable with DiagnosticLoggable {
  final String field1;
  final int field2;

  const TestUIModel({required this.field1, required this.field2});

  @override
  Map<String, Object?> get namedProps => {
        'field1': field1,
        'field2': field2,
      };
}

class TestData extends Equatable with DiagnosticLoggable {
  final TestUIModel model;

  const TestData({required this.model});

  @override
  Map<String, Object?> get namedProps => {'model': model};
}

/// Model built with `with EquatableMixin` (not `extends Equatable`) — mirrors
/// the MeshNetwork entities. Uses [DiagnosticNamed] since it cannot mix in
/// [DiagnosticLoggable] (constrained `on Equatable`). Keeps its own [props].
class MixinModel with EquatableMixin, DiagnosticNamed {
  final String id;
  final int level;

  const MixinModel({required this.id, required this.level});

  @override
  List<Object?> get props => [id, level];

  @override
  Map<String, Object?> get namedProps => {'id': id, 'level': level};
}

/// DiagnosticLoggable that nests a DiagnosticNamed (EquatableMixin) child.
class LoggableWrappingMixin extends Equatable with DiagnosticLoggable {
  final MixinModel child;

  const LoggableWrappingMixin({required this.child});

  @override
  Map<String, Object?> get namedProps => {'child': child};
}

/// DiagnosticLoggable that nests a list of DiagnosticNamed children.
class LoggableWrappingList extends Equatable with DiagnosticLoggable {
  final List<MixinModel> items;

  const LoggableWrappingList({required this.items});

  @override
  Map<String, Object?> get namedProps => {'items': items};
}

// --- Tests ---

void main() {
  group('DiagnosticLoggable', () {
    group('namedProps and props', () {
      test('props derived from namedProps values', () {
        const model = SimpleModel(name: 'test', count: 42, active: true);

        expect(model.props, equals(['test', 42, true]));
      });

      test('Equatable equality uses namedProps', () {
        const model1 = SimpleModel(name: 'test', count: 42, active: true);
        const model2 = SimpleModel(name: 'test', count: 42, active: true);
        const model3 = SimpleModel(name: 'other', count: 42, active: true);

        expect(model1, equals(model2));
        expect(model1, isNot(equals(model3)));
      });

      test('Map props equality - same content different instances', () {
        // Two MapModel instances with identical Map content but different
        // Map instances should be equal (Equatable uses deep comparison)
        final map1 = MapModel(itemMap: {
          'a': const SimpleModel(name: 'first', count: 1, active: true),
          'b': const SimpleModel(name: 'second', count: 2, active: false),
        });
        final map2 = MapModel(itemMap: {
          'a': const SimpleModel(name: 'first', count: 1, active: true),
          'b': const SimpleModel(name: 'second', count: 2, active: false),
        });

        // Verify maps are different instances
        expect(identical(map1.itemMap, map2.itemMap), isFalse);

        // But models should be equal (Equatable deep comparison)
        expect(map1, equals(map2));
        expect(map1.hashCode, equals(map2.hashCode));
      });

      test('Map props equality - different content', () {
        final map1 = MapModel(itemMap: {
          'a': const SimpleModel(name: 'first', count: 1, active: true),
        });
        final map2 = MapModel(itemMap: {
          'a': const SimpleModel(name: 'different', count: 1, active: true),
        });

        expect(map1, isNot(equals(map2)));
      });

      test('Map props equality - different keys', () {
        final map1 = MapModel(itemMap: {
          'a': const SimpleModel(name: 'first', count: 1, active: true),
        });
        final map2 = MapModel(itemMap: {
          'b': const SimpleModel(name: 'first', count: 1, active: true),
        });

        expect(map1, isNot(equals(map2)));
      });

      test('Map props equality - empty maps', () {
        final map1 = MapModel(itemMap: {});
        final map2 = MapModel(itemMap: {});

        expect(map1, equals(map2));
      });
    });

    group('toString JSON output', () {
      test('simple model outputs valid JSON', () {
        const model = SimpleModel(name: 'test', count: 42, active: true);

        final json = model.toString();

        expect(json, equals('{"name":"test","count":42,"active":true}'));
      });

      test('nullable fields with null values', () {
        const model = NullableModel();

        final json = model.toString();

        expect(json, equals('{"label":null,"value":null}'));
      });

      test('nullable fields with values', () {
        const model = NullableModel(label: 'test', value: 123);

        final json = model.toString();

        expect(json, equals('{"label":"test","value":123}'));
      });

      test('nested DiagnosticLoggable outputs nested JSON', () {
        const model = NestedModel(
          child: SimpleModel(name: 'inner', count: 1, active: false),
        );

        final json = model.toString();

        expect(
          json,
          equals('{"child":{"name":"inner","count":1,"active":false}}'),
        );
      });

      test('list of DiagnosticLoggable outputs array', () {
        const model = ListModel(items: [
          SimpleModel(name: 'a', count: 1, active: true),
          SimpleModel(name: 'b', count: 2, active: false),
        ]);

        final json = model.toString();

        expect(
          json,
          equals(
            '{"items":[{"name":"a","count":1,"active":true},{"name":"b","count":2,"active":false}]}',
          ),
        );
      });

      test('empty list outputs empty array', () {
        const model = ListModel(items: []);

        final json = model.toString();

        expect(json, equals('{"items":[]}'));
      });

      test('map with DiagnosticLoggable values', () {
        const model = MapModel(itemMap: {
          'first': SimpleModel(name: 'a', count: 1, active: true),
        });

        final json = model.toString();

        expect(
          json,
          equals('{"itemMap":{"first":{"name":"a","count":1,"active":true}}}'),
        );
      });

      test('DateTime outputs ISO8601 string', () {
        final model = DateTimeModel(
          timestamp: DateTime.utc(2026, 7, 3, 12, 30, 45),
        );

        final json = model.toString();

        expect(json, equals('{"timestamp":"2026-07-03T12:30:45.000Z"}'));
      });

      test('Duration outputs milliseconds', () {
        const model = DurationModel(duration: Duration(seconds: 30));

        final json = model.toString();

        expect(json, equals('{"duration":30000}'));
      });

      test('enum outputs name string', () {
        const model = EnumModel(status: TestStatus.active);

        final json = model.toString();

        expect(json, equals('{"status":"active"}'));
      });

      test('non-string map keys convert to string', () {
        const model = NonStringKeyMapModel(data: {1: 'one', 2: 'two'});

        final json = model.toString();

        expect(json, equals('{"data":{"1":"one","2":"two"}}'));
      });

      test('Data wrapping UIModel pattern', () {
        const data = TestData(
          model: TestUIModel(field1: 'value', field2: 99),
        );

        final json = data.toString();

        expect(
          json,
          equals('{"model":{"field1":"value","field2":99}}'),
        );
      });
    });

    group('loggable flag', () {
      test('default loggable is true', () {
        const model = SimpleModel(name: 'test', count: 0, active: false);

        expect(model.loggable, isTrue);
      });

      test('can override loggable to false', () {
        const model = NonLoggableModel(data: 'secret');

        expect(model.loggable, isFalse);
      });

      test('toString still works when loggable is false', () {
        const model = NonLoggableModel(data: 'secret');

        expect(model.toString(), equals('{"data":"secret"}'));
      });
    });

    group('DiagnosticNamed (EquatableMixin models)', () {
      test('EquatableMixin model with DiagnosticNamed outputs keyed JSON', () {
        const model = MixinModel(id: 'x1', level: 3);

        expect(model.toString(), equals('{"id":"x1","level":3}'));
      });

      test('DiagnosticNamed keeps its own props for equality', () {
        // namedProps and props are independent — props still drives equality.
        const a = MixinModel(id: 'x1', level: 3);
        const b = MixinModel(id: 'x1', level: 3);
        const c = MixinModel(id: 'x1', level: 9);

        expect(a, equals(b));
        expect(a, isNot(equals(c)));
        expect(a.props, equals(['x1', 3]));
      });

      test(
          'DiagnosticNamed nested inside DiagnosticLoggable serializes with keys '
          '(not a props array or "Instance of")', () {
        const outer = LoggableWrappingMixin(
          child: MixinModel(id: 'inner', level: 1),
        );

        final json = outer.toString();

        expect(json, equals('{"child":{"id":"inner","level":1}}'));
        expect(json, isNot(contains('Instance of')));
      });

      test('list of DiagnosticNamed nested in DiagnosticLoggable', () {
        const outer = LoggableWrappingList(items: [
          MixinModel(id: 'a', level: 1),
          MixinModel(id: 'b', level: 2),
        ]);

        expect(
          outer.toString(),
          equals('{"items":[{"id":"a","level":1},{"id":"b","level":2}]}'),
        );
      });
    });

    group('edge cases', () {
      test('special characters in string values', () {
        const model = SimpleModel(
          name: 'test "quoted" value',
          count: 0,
          active: false,
        );

        final json = model.toString();

        expect(json, contains(r'\"quoted\"'));
      });

      test('unicode characters in string values', () {
        const model = SimpleModel(name: '測試', count: 0, active: false);

        final json = model.toString();

        expect(json, contains('測試'));
      });

      test('deeply nested structure', () {
        const model = NestedModel(
          child: SimpleModel(name: 'level1', count: 1, active: true),
        );
        final outer = ListModel(items: [model.child]);

        final json = outer.toString();

        expect(json, isNotEmpty);
        expect(json, startsWith('{'));
        expect(json, endsWith('}'));
      });
    });
  });
}
