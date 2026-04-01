import 'package:flutter_test/flutter_test.dart';
import 'package:ui_kit_library/ui_kit.dart';
import 'package:privacy_gui/page/dashboard/models/display_mode.dart';
import 'package:privacy_gui/page/dashboard/models/widget_spec.dart';

final _normalConstraints = WidgetGridConstraints(
  minColumns: 3,
  maxColumns: 8,
  preferredColumns: 6,
  heightStrategy: HeightStrategy.strict(3),
  minHeightRows: 2,
  maxHeightRows: 8,
);

final _compactConstraints = WidgetGridConstraints(
  minColumns: 2,
  maxColumns: 6,
  preferredColumns: 4,
  heightStrategy: HeightStrategy.strict(2),
  minHeightRows: 1,
  maxHeightRows: 4,
);

final _defaultConstraints = WidgetGridConstraints(
  minColumns: 4,
  maxColumns: 12,
  preferredColumns: 8,
  heightStrategy: HeightStrategy.strict(4),
  minHeightRows: 2,
  maxHeightRows: 10,
);

WidgetSpec _make({
  String id = 'test_widget',
  String displayName = 'Test Widget',
  Map<DisplayMode, WidgetGridConstraints>? constraints,
  WidgetGridConstraints? defaultConstraints,
  bool canHide = true,
  List<WidgetRequirement> requirements = const [],
}) {
  return WidgetSpec(
    id: id,
    displayName: displayName,
    constraints: constraints ?? {DisplayMode.normal: _normalConstraints},
    defaultConstraints: defaultConstraints,
    canHide: canHide,
    requirements: requirements,
  );
}

void main() {
  group('supportsDisplayModes', () {
    test('returns true when constraints has 2+ entries', () {
      final spec = _make(constraints: {
        DisplayMode.compact: _compactConstraints,
        DisplayMode.normal: _normalConstraints,
      });
      expect(spec.supportsDisplayModes, isTrue);
    });

    test('returns false when constraints has 1 entry', () {
      final spec = _make(constraints: {
        DisplayMode.normal: _normalConstraints,
      });
      expect(spec.supportsDisplayModes, isFalse);
    });

    test('returns false when constraints is empty', () {
      final spec = _make(
        constraints: {},
        defaultConstraints: _defaultConstraints,
      );
      expect(spec.supportsDisplayModes, isFalse);
    });
  });

  group('getConstraints fallback', () {
    test('returns exact mode from constraints', () {
      final spec = _make(constraints: {
        DisplayMode.normal: _normalConstraints,
        DisplayMode.compact: _compactConstraints,
      });
      expect(spec.getConstraints(DisplayMode.compact), _compactConstraints);
    });

    test('falls back to defaultConstraints when mode missing', () {
      final spec = _make(
        constraints: {DisplayMode.normal: _normalConstraints},
        defaultConstraints: _defaultConstraints,
      );
      expect(spec.getConstraints(DisplayMode.compact), _defaultConstraints);
    });

    test('falls back to normal mode when no defaultConstraints', () {
      final spec = _make(
        constraints: {DisplayMode.normal: _normalConstraints},
      );
      expect(spec.getConstraints(DisplayMode.compact), _normalConstraints);
    });

    test('defaultConstraints takes precedence over normal fallback', () {
      final spec = _make(
        constraints: {DisplayMode.normal: _normalConstraints},
        defaultConstraints: _defaultConstraints,
      );
      // Requesting compact: not in constraints → uses defaultConstraints
      final result = spec.getConstraints(DisplayMode.compact);
      expect(result, _defaultConstraints);
      expect(result, isNot(equals(_normalConstraints)));
    });
  });

  group('Equality', () {
    test('equal specs are equal', () {
      final a = _make();
      final b = _make();
      expect(a, equals(b));
    });

    test('different id not equal', () {
      final a = _make(id: 'card_a');
      final b = _make(id: 'card_b');
      expect(a, isNot(equals(b)));
    });

    test('different displayName not equal', () {
      final a = _make(displayName: 'Card A');
      final b = _make(displayName: 'Card B');
      expect(a, isNot(equals(b)));
    });

    test('different canHide not equal', () {
      final a = _make(canHide: true);
      final b = _make(canHide: false);
      expect(a, isNot(equals(b)));
    });

    test('different requirements not equal', () {
      final a = _make(requirements: [WidgetRequirement.none]);
      final b = _make(requirements: [WidgetRequirement.vpnSupported]);
      expect(a, isNot(equals(b)));
    });

    test('hashCode consistent with equality', () {
      final a = _make();
      final b = _make();
      expect(a.hashCode, equals(b.hashCode));
    });
  });

  group('_listEquals via requirements', () {
    test('both empty requirements are equal', () {
      final a = _make(requirements: []);
      final b = _make(requirements: []);
      expect(a, equals(b));
    });

    test('one empty one non-empty are not equal', () {
      final a = _make(requirements: []);
      final b = _make(requirements: [WidgetRequirement.none]);
      expect(a, isNot(equals(b)));
    });

    test('different lengths not equal', () {
      final a = _make(requirements: [WidgetRequirement.none]);
      final b = _make(requirements: [
        WidgetRequirement.none,
        WidgetRequirement.vpnSupported,
      ]);
      expect(a, isNot(equals(b)));
    });

    test('element mismatch not equal', () {
      final a = _make(requirements: [WidgetRequirement.none]);
      final b = _make(requirements: [WidgetRequirement.vpnSupported]);
      expect(a, isNot(equals(b)));
    });

    test('matching lists are equal', () {
      final a = _make(requirements: [
        WidgetRequirement.none,
        WidgetRequirement.vpnSupported,
      ]);
      final b = _make(requirements: [
        WidgetRequirement.none,
        WidgetRequirement.vpnSupported,
      ]);
      expect(a, equals(b));
    });
  });
}
