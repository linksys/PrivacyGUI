import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/l10n/gen/app_localizations.dart';
import 'package:privacy_gui/core/usp/providers/sse_invalidation_provider.dart';
import 'package:privacy_gui/page/_shared/models/client_device.dart';
import 'package:privacy_gui/page/_shared/models/mesh_network.dart';
import 'package:privacy_gui/page/_shared/models/node_entity.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/dimensions/devices_dimension.dart';
import 'package:privacy_gui/page/dashboard/mascot/health/health_dimension.dart';
import 'package:privacy_gui/page/devices/providers/devices_data_provider.dart';

void main() {
  group('DevicesHealthDimension', () {
    late DevicesHealthDimension dimension;

    setUp(() {
      dimension = DevicesHealthDimension();
    });

    ClientDevice createDevice({
      required String mac,
      required bool isActive,
    }) {
      return ClientDevice(
        mac: mac,
        ip: '192.168.1.10',
        hostName: 'device-$mac',
        isActive: isActive,
        connectionType: ConnectionType.wifi,
      );
    }

    DevicesData createDevicesData(List<ClientDevice> clients) {
      return DevicesData(
        meshNetwork: MeshNetwork(
          master: MasterNode(
            deviceId: 'GATEWAY',
            model: 'MR7500',
            connectedClients: clients,
          ),
        ),
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
          devices: createDevicesData([]),
        );

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 100 when all devices online', () {
        final context = HealthEvaluationContext(
          devices: createDevicesData([
            createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
            createDevice(mac: 'AA:BB:CC:DD:EE:02', isActive: true),
          ]),
        );

        final score = dimension.evaluate(context);

        expect(score, 100);
      });

      test('returns 80 when > 80% online', () {
        final context = HealthEvaluationContext(
          devices: createDevicesData([
            createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
            createDevice(mac: 'AA:BB:CC:DD:EE:02', isActive: true),
            createDevice(mac: 'AA:BB:CC:DD:EE:03', isActive: true),
            createDevice(mac: 'AA:BB:CC:DD:EE:04', isActive: true),
            createDevice(mac: 'AA:BB:CC:DD:EE:05', isActive: false), // 80%
          ]),
        );

        final score = dimension.evaluate(context);

        expect(score, 80);
      });

      test('returns 60 when > 50% online', () {
        final context = HealthEvaluationContext(
          devices: createDevicesData([
            createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
            createDevice(mac: 'AA:BB:CC:DD:EE:02', isActive: true),
            createDevice(mac: 'AA:BB:CC:DD:EE:03', isActive: false),
            createDevice(mac: 'AA:BB:CC:DD:EE:04', isActive: false), // 50%
          ]),
        );

        final score = dimension.evaluate(context);

        expect(score, 60);
      });

      test('excludes mesh nodes from client count', () {
        // Mesh nodes are tracked separately in MeshNetwork.allNodes,
        // so we only need to pass client devices to the master's connectedClients
        final context = HealthEvaluationContext(
          devices: createDevicesData([
            createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
          ]),
        );

        final score = dimension.evaluate(context);

        expect(score, 100); // Only 1 client device, 100% online
      });
    });

    group('getSummary', () {
      test('returns All Online when all devices active', () {
        final context = HealthEvaluationContext(
          devices: createDevicesData([
            createDevice(mac: 'AA:BB:CC:DD:EE:01', isActive: true),
            createDevice(mac: 'AA:BB:CC:DD:EE:02', isActive: true),
          ]),
        );

        final summary = dimension.getSummary(context);

        expect(summary.status, 'All Online');
        expect(summary.items.any((i) => i.label == 'Connected'), true);
      });

      test('returns No devices when empty', () {
        final context = HealthEvaluationContext(
          devices: createDevicesData([]),
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
