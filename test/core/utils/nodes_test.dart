import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/utils/nodes.dart';

void main() {
  group('Node Model Tests', () {
    test('WHW03B (Velop - Black)', () {
      expect(isNodeModel(modelNumber: 'WHW03B', hardwareVersion: '1'), true);
    });

    test('WHW03 (Velop)', () {
      expect(isNodeModel(modelNumber: 'WHW03', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'ND0001', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'NODES', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'WHW0301', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'A03', hardwareVersion: '1'), true);
    });

    test('WHW01P (Velop Plugin)', () {
      expect(isNodeModel(modelNumber: 'WHW01P', hardwareVersion: '1'), true);
    });

    test('WHW01B (Velop Jr - Black)', () {
      expect(isNodeModel(modelNumber: 'WHW01B', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'VLP01B', hardwareVersion: '1'), true);
    });

    test('WHW01 (Velop Jr)', () {
      expect(isNodeModel(modelNumber: 'WHW01', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'VLP01', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'A01', hardwareVersion: '1'), true);
    });

    test('MX5300 (Bronx)', () {
      expect(isNodeModel(modelNumber: 'MX5300', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX5400', hardwareVersion: '1'), true);
    });

    test('MX6200 (Maple)', () {
      expect(isNodeModel(modelNumber: 'MX6200', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX6201', hardwareVersion: '1'),
          true); // Example variant
    });

    test('MBE7000 (Oak)', () {
      expect(isNodeModel(modelNumber: 'MBE7000', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MBE7001', hardwareVersion: '1'),
          true); // Example variant
    });

    test('MBE7100 (Oak SP1)', () {
      expect(isNodeModel(modelNumber: 'MBE7100', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MBE7101', hardwareVersion: '1'),
          true); // Example variant
    });

    test('LN11 (Elm)', () {
      expect(isNodeModel(modelNumber: 'LN11', hardwareVersion: '1'), true);
    });

    test('LN12 (Cherry)', () {
      expect(isNodeModel(modelNumber: 'LN12', hardwareVersion: '1'), true);
    });

    test('SPNM60 (Pinnacle 2.0)', () {
      expect(isNodeModel(modelNumber: 'SPNM60', hardwareVersion: '1'), true);
    });
    test('SPNM61 (Pinnacle 2.1)', () {
      expect(isNodeModel(modelNumber: 'SPNM61', hardwareVersion: '1'), true);
    });
    test('SPNM62 (Pinnacle 2.2)', () {
      expect(isNodeModel(modelNumber: 'SPNM62', hardwareVersion: '1'), true);
    });
    test('Random Model (Should be false)', () {
      expect(isNodeModel(modelNumber: 'XYZ123', hardwareVersion: '1'), false);
    });

    test('MR9600 (Bobcat)', () {
      expect(isNodeModel(modelNumber: 'MR9600', hardwareVersion: '1'), true);
    });
  });

  group("treatAsMode Tests", () {
    test("Verify WHW03B returns WHW03B", () {
      String? result =
          treatAsModes(modelNumber: "WHW03B", hardwareVersion: "1");
      expect(result, "WHW03B");
    });
    test("Verify WHW03B with hardwareVersion 2 returns WHW03B", () {
      String? result =
          treatAsModes(modelNumber: "WHW03B", hardwareVersion: "2");
      expect(result, 'WHW03B');
    });

    test("Verify EA9350 returns EA9350 with hardwareVersion 1 returns null",
        () {
      String? result =
          treatAsModes(modelNumber: "EA9350", hardwareVersion: "1");
      expect(result, null);
    });

    test("Verify EA9350 returns EA9350 with hardwareVersion 1 returns EA9350",
        () {
      String? result =
          treatAsModes(modelNumber: "EA9350", hardwareVersion: "3");
      expect(result, 'EA9350');
    });
  });
}
