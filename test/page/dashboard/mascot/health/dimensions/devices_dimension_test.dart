import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/_shared/models/device_ui_model.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/dimensions/devices_dimension.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

void main() {
  group('DevicesHealthDimension', () {
    late DevicesHealthDimension dimension;

    setUp(() {
      dimension = DevicesHealthDimension();
    });

    DeviceUIModel createDevice({
      required String mac,
      required bool isActive,
      String? deviceRole,
    }) {
      return DeviceUIModel(
        mac: mac,
        ip: '192.168.1.10',
        hostName: 'device-$mac',
        isActive: isActive,
        isWifi: true,
        deviceRole: deviceRole,
      );
    }

    group('evaluate', () {
      test('returns 100 when devices data is null', () {
        const context = HealthEvaluationContext();

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 100 when no devices', () {
        final context = HealthEvaluationContext(
          devices: const DevicesData(deviceModels: []),
        );

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 100 when all devices online', () {
        final context = HealthEvaluationContext(
          devices: DevicesData(
            deviceModels: [
              createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
              createDevice(mac: 'AA:BB:CC:DD:EE:02', isActive: true),
            ],
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 80 when > 80% online', () {
        final context = HealthEvaluationContext(
          devices: DevicesData(
            deviceModels: [
              createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
              createDevice(mac: 'AA:BB:CC:DD:EE:02', isActive: true),
              createDevice(mac: 'AA:BB:CC:DD:EE:03', isActive: true),
              createDevice(mac: 'AA:BB:CC:DD:EE:04', isActive: true),
              createDevice(mac: 'AA:BB:CC:DD:EE:05', isActive: false), // 80%
            ],
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 80);
      });

      test('returns 60 when > 50% online', () {
        final context = HealthEvaluationContext(
          devices: DevicesData(
            deviceModels: [
              createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
              createDevice(mac: 'AA:BB:CC:DD:EE:02', isActive: true),
              createDevice(mac: 'AA:BB:CC:DD:EE:03', isActive: false),
              createDevice(mac: 'AA:BB:CC:DD:EE:04', isActive: false), // 50%
            ],
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 60);
      });

      test('excludes mesh nodes from client count', () {
        final context = HealthEvaluationContext(
          devices: DevicesData(
            deviceModels: [
              createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
              createDevice(
                  mac: 'AA:BB:CC:DD:EE:02',
                  isActive: true,
                  deviceRole: 'master'),
              createDevice(
                  mac: 'AA:BB:CC:DD:EE:03',
                  isActive: true,
                  deviceRole: 'slave'),
            ],
          ),
        );

        final score = dimension.evaluate(context);

        expect(score, 100); // Only 1 client device, 100% online
      });
    });

    group('getSummary', () {
      test('returns All Online when all devices active', () {
        final context = HealthEvaluationContext(
          devices: DevicesData(
            deviceModels: [
              createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
              createDevice(mac: 'AA:BB:CC:DD:EE:02', isActive: true),
            ],
          ),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'All Online');
        expect(summary.items.any((i) => i.label == 'Connected'), true);
      });

      test('returns No devices when empty', () {
        final context = HealthEvaluationContext(
          devices: const DevicesData(deviceModels: []),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'No devices');
      });
    });

    group('watchedDomains', () {
      test('watches device-related domains', () {
        expect(dimension.watchedDomains,
            contains(InvalidationDomain.connectedDevices));
        expect(
            dimension.watchedDomains, contains(InvalidationDomain.wifiClients));
      });
    });

    group('getActions', () {
      testWidgets('returns view devices action', (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: const SizedBox(),
          ),
        );
        final context = tester.element(find.byType(SizedBox));

        final actions = dimension.getActions(context);

        expect(actions.any((a) => a.id == 'view_devices'), true);
      });
    });
  });
}
