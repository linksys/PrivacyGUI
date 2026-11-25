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

    test('M60-EUCF (Pinnacle EU variant)', () {
      expect(isNodeModel(modelNumber: 'M60-EUCF', hardwareVersion: '1'), true);
    });

    test('M63TS-EU (Pinnacle 2.3)', () {
      expect(isNodeModel(modelNumber: 'M63TS-EU', hardwareVersion: '1'), true);
    });
  });

  group('isCognitiveMeshRouter', () {
    test('is true for the Pinnacle M series, M63 included', () {
      for (final model in ['M60', 'M61', 'M62', 'M63', 'M63TS-EU']) {
        expect(isCognitiveMeshRouter(modelNumber: model, hardwareVersion: '1'),
            true,
            reason: model);
      }
    });

    test('is false for a mesh router', () {
      expect(isCognitiveMeshRouter(modelNumber: 'MR9600', hardwareVersion: '1'),
          false);
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

  group('isNodeModel', () {
    test('should return true for valid node models', () {
      // Test Velop nodes
      expect(isNodeModel(modelNumber: 'WHW03', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'WHW03B', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'WHW01', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'WHW01B', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'WHW01P', hardwareVersion: '1'), true);

      // Test MX series nodes
      expect(isNodeModel(modelNumber: 'MX5300', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX5400', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX4200', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX8500', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX5500', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX2000', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX5600', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX5700', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MX6200', hardwareVersion: '1'), true);

      // Test Cognitive Mesh nodes
      expect(isNodeModel(modelNumber: 'MBE7000', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'MBE7100', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'LN11', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'LN12', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'LN14', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'LN15', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'LN16', hardwareVersion: '1'), true);

      // Test Pinnacle nodes
      expect(isNodeModel(modelNumber: 'SPNM60', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'SPNM61', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'SPNM62', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'M60', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'M61', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'M62', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'M63', hardwareVersion: '1'), true);
    });

    test('should handle case-insensitive model numbers', () {
      expect(isNodeModel(modelNumber: 'whw03', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'mx5300', hardwareVersion: '1'), true);
      expect(isNodeModel(modelNumber: 'mbe7000', hardwareVersion: '1'), true);
    });

    test('should handle invalid model numbers', () {
      expect(isNodeModel(modelNumber: 'INVALID', hardwareVersion: '1'), false);
      expect(isNodeModel(modelNumber: 'XYZ123', hardwareVersion: '1'), false);
    });
  });

  // The node pages and the quick panel lay a node out as Cognitive Mesh when
  // this is true.
  group('isCognitiveMeshRouter, for the rest of the Cognitive Mesh family', () {
    test('is true for Maple, Oak, Elm, Cherry, the LN series and Pinnacle',
        () {
      for (final model in [
        'MX6200',
        'MBE7000',
        'MBE7100',
        'LN11',
        'LN12',
        'LN14',
        'LN15',
        'LN16',
        'SPNM60',
        'SPNM61',
        'SPNM62',
      ]) {
        expect(isCognitiveMeshRouter(modelNumber: model, hardwareVersion: '1'),
            isTrue,
            reason: model);
      }
    });

    test('is false for a Velop node and a model it does not know', () {
      for (final model in ['WHW03', 'MX5300', 'MX4200', 'XYZ123', '']) {
        expect(isCognitiveMeshRouter(modelNumber: model, hardwareVersion: '1'),
            isFalse,
            reason: model);
      }
    });

    // EA9350 is listed for hardware version 3 only.
    test('is false for a model listed only for another hardware version', () {
      expect(isCognitiveMeshRouter(modelNumber: 'EA9350', hardwareVersion: '1'),
          isFalse);
    });
  });

  // The dashboard lays the router's ports out in a row when this is true
  // (dashboard_home_provider.dart).
  group('isHorizontalPorts', () {
    test('is true for Elm (LN11)', () {
      expect(isHorizontalPorts(modelNumber: 'LN11', hardwareVersion: '1'),
          isTrue);
      expect(isHorizontalPorts(modelNumber: 'LN11-EU', hardwareVersion: '1'),
          isTrue);
    });

    test('is false for every other router, and one it does not know', () {
      for (final model in ['LN12', 'LN16', 'M63', 'MX4200', 'MR9600', '']) {
        expect(isHorizontalPorts(modelNumber: model, hardwareVersion: '1'),
            isFalse,
            reason: model);
      }
    });
  });

  // The health check offers the speed test unless the model's rule turns it
  // off (speed_test_display.dart); no rule does today.
  group('isShowSpeedTest', () {
    test('shows the speed test on every model, known or not', () {
      for (final model in ['M63', 'LN11', 'MX4200', 'MR9600', 'XYZ123', '']) {
        expect(isShowSpeedTest(modelNumber: model), isTrue, reason: model);
      }
    });
  });
}
