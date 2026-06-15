import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/page/_shared/models/system_info_ui_model.dart';
import 'package:privacy_gui/page/admin/providers/system_info_data_provider.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/dimensions/system_dimension.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';

void main() {
  group('SystemHealthDimension', () {
    late SystemHealthDimension dimension;

    setUp(() {
      dimension = SystemHealthDimension();
    });

    SystemInfoData createSystemInfo({
      int cpuUsage = 30,
      int totalMemory = 512000,
      int freeMemory = 256000,
    }) {
      return SystemInfoData(
        model: SystemInfoUIModel(
          manufacturer: 'Linksys',
          modelName: 'MR7350',
          serialNumber: '123456',
          hardwareVersion: '1.0',
          softwareVersion: '1.0.0',
          uptime: 86400,
          totalMemory: totalMemory,
          freeMemory: freeMemory,
          cpuUsage: cpuUsage,
        ),
      );
    }

    group('evaluate', () {
      test('returns 100 when systemInfo is null (assume healthy)', () {
        const context = HealthEvaluationContext();

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 100 when CPU and memory are low (< 50%)', () {
        final context = HealthEvaluationContext(
          systemInfo: createSystemInfo(
            cpuUsage: 30,
            totalMemory: 512000,
            freeMemory: 307200, // 40% used
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 80 when max usage is between 50-70%', () {
        final context = HealthEvaluationContext(
          systemInfo: createSystemInfo(
            cpuUsage: 65,
            totalMemory: 512000,
            freeMemory: 256000, // 50% used
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 80);
      });

      test('returns 60 when max usage is between 70-85%', () {
        final context = HealthEvaluationContext(
          systemInfo: createSystemInfo(
            cpuUsage: 80,
            totalMemory: 512000,
            freeMemory: 256000,
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 60);
      });

      test('returns 40 when max usage is between 85-95%', () {
        final context = HealthEvaluationContext(
          systemInfo: createSystemInfo(
            cpuUsage: 90,
            totalMemory: 512000,
            freeMemory: 256000,
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 40);
      });

      test('returns 20 when max usage is >= 95%', () {
        final context = HealthEvaluationContext(
          systemInfo: createSystemInfo(
            cpuUsage: 98,
            totalMemory: 512000,
            freeMemory: 256000,
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 20);
      });

      test('uses memory percent when higher than CPU', () {
        final context = HealthEvaluationContext(
          systemInfo: createSystemInfo(
            cpuUsage: 30,
            totalMemory: 512000,
            freeMemory: 25600, // 95% used
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 20); // Based on memory, not CPU
      });
    });

    group('getSummary', () {
      test('returns loading state when systemInfo is null', () {
        const context = HealthEvaluationContext();

        final summary = dimension.getSummary(context);

        expect(summary.status, 'Loading...');
      });

      test('returns Healthy status when usage is low', () {
        final context = HealthEvaluationContext(
          systemInfo: createSystemInfo(
            cpuUsage: 30,
            totalMemory: 512000,
            freeMemory: 307200, // 40% used, max(30, 40) = 40 < 50
          ),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'Healthy');
        expect(summary.items.any((i) => i.label == 'CPU'), true);
        expect(summary.items.any((i) => i.label == 'Memory'), true);
      });

      test('returns High Load status when usage is high', () {
        final context = HealthEvaluationContext(
          systemInfo: createSystemInfo(cpuUsage: 90),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'High Load');
      });
    });

    group('watchedDomains', () {
      test('has no SSE domains (polls only)', () {
        expect(dimension.watchedDomains, isEmpty);
      });
    });

    group('getActions', () {
      testWidgets('returns reboot and system info actions', (tester) async {
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));

        final actions = dimension.getActions(context);

        expect(actions.length, 2);
        expect(actions.any((a) => a.id == 'reboot_router'), true);
        expect(actions.any((a) => a.id == 'system_info'), true);
      });
    });
  });
}
