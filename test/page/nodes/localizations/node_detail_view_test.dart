import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/jnap_service_supported.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_provider.dart';
import 'package:privacy_gui/core/jnap/providers/device_manager_state.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_device/providers/device_filtered_list_state.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_provider.dart';
import 'package:privacy_gui/page/wifi_settings/providers/wifi_bundle_state.dart';
import 'package:privacy_gui/providers/preservable.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:mockito/mockito.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../mocks/wifi_bundle_settings_notifier_mocks.dart';
import '../../../test_data/device_filter_config_test_state.dart';
import '../../../test_data/device_filtered_list_test_data.dart';
import '../../../test_data/device_manager_test_state.dart';
import '../../../test_data/firmware_update_test_state.dart';
import '../../../test_data/node_details_data.dart';
import '../../../test_data/wifi_bundle_test_state.dart';

void main() {
  late NodeDetailNotifier mockNodeDetailNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;
  late DeviceFilterConfigNotifier mockDeviceFilterConfigNotifier;
  late MockDeviceManagerNotifier mockDeviceManagerNotifier;
  late MockWifiBundleNotifier mockWifiBundleNotifier;

  mockDependencyRegister();
  ServiceHelper mockServiceHelper = getIt.get<ServiceHelper>();

  setUp(() {
    mockNodeDetailNotifier = MockNodeDetailNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    mockDeviceFilterConfigNotifier = MockDeviceFilterConfigNotifier();
    mockDeviceManagerNotifier = MockDeviceManagerNotifier();
    mockWifiBundleNotifier = MockWifiBundleNotifier();

    final settings = WifiBundleSettings.fromMap(wifiBundleTestState['settings'] as Map<String, dynamic>);
    final status = WifiBundleStatus.fromMap(wifiBundleTestState['status'] as Map<String, dynamic>);

    final initialState = WifiBundleState(
      settings: Preservable(original: settings, current: settings),
      status: status,
    );

    when(mockDeviceManagerNotifier.build())
        .thenReturn(DeviceManagerState.fromMap(deviceManagerCherry7TestState));
    when(mockWifiBundleNotifier.build()).thenReturn(initialState);
    when(mockWifiBundleNotifier.state).thenReturn(initialState);

    when(mockDeviceManagerNotifier.getBandConnectedBy(any))
        .thenReturn('2.4GHz');
  });
  testLocalizations(
    'Node details view - master node',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    },
  );
  testLocalizations(
    'Node details view - master node without devices',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) => []),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    },
    screens: responsiveDesktopScreens,
  );

  testLocalizations(
    'Node details view - master node with one device',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .take(1)
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    },
    screens: responsiveDesktopScreens,
  );

  testLocalizations(
    'Node details view - master node with filter',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });

      await tester.tap(find.byIcon(LinksysIcons.filter).first);
      await tester.pumpAndSettle();
    },
    screens: responsiveDesktopScreens,
  );

  testLocalizations(
    'Node details view - master node',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });

      final devicesTab = find.byType(Tab).last;
      await tester.tap(devicesTab);
      await tester.pumpAndSettle();
    },
    screens: responsiveMobileScreens,
  );
  testLocalizations(
    'Node details view - master node without devices',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) => []),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });

      final devicesTab = find.byType(Tab).last;
      await tester.tap(devicesTab);
      await tester.pumpAndSettle();
    },
    screens: responsiveMobileScreens,
  );

  testLocalizations(
    'Node details view - master node with one device',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .take(1)
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
        final devicesTab = find.byType(Tab).last;
        await tester.tap(devicesTab);
        await tester.pumpAndSettle();
      });
    },
    screens: responsiveMobileScreens,
  );

  testLocalizations(
    'Node details view - master node with filter',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);

      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });

      final devicesTab = find.byType(Tab).last;
      await tester.tap(devicesTab);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LinksysIcons.filter).first);
      await tester.pumpAndSettle();
    },
    screens: responsiveMobileScreens,
  );

  testLocalizations(
    'Node details view - slave node',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState2));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - slave node with MLO label',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build()).thenReturn(
          NodeDetailState.fromMap(fakeNodeDetailsState2).copyWith(isMLO: true));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - MLO modal',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build()).thenReturn(
          NodeDetailState.fromMap(fakeNodeDetailsState2).copyWith(isMLO: true));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
      final mloLabelFinder = find.descendant(
          of: find.byType(AppCard).first, matching: find.byType(AppTextButton));
      await tester.tap(mloLabelFinder);
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'Node details view - firmware update avaliable',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceFilterConfigProvider
                .overrideWith(() => mockDeviceFilterConfigNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
            filteredDeviceListProvider.overrideWith((ref) =>
                deviceFilteredTestData
                    .map((e) => DeviceListItem.fromMap(e))
                    .toList()),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - edit name modal',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
      when(mockServiceHelper.isSupportLedBlinking()).thenReturn(true);

      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceFilterConfigProvider
                .overrideWith(() => mockDeviceFilterConfigNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
            filteredDeviceListProvider.overrideWith((ref) =>
                deviceFilteredTestData
                    .map((e) => DeviceListItem.fromMap(e))
                    .toList()),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
        final editFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editFinder);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - edit name modal - empty error',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
      when(mockServiceHelper.isSupportLedBlinking()).thenReturn(true);

      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceFilterConfigProvider
                .overrideWith(() => mockDeviceFilterConfigNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
            filteredDeviceListProvider.overrideWith((ref) =>
                deviceFilteredTestData
                    .map((e) => DeviceListItem.fromMap(e))
                    .toList()),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
        final editFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editFinder);
        await tester.pumpAndSettle();

        final inputFieldFinder = find.bySemanticsLabel('node name').last;
        await tester.tap(inputFieldFinder);
        await tester.enterText(inputFieldFinder, '');
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - edit name modal - over name size error',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
      when(mockServiceHelper.isSupportLedBlinking()).thenReturn(true);

      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceFilterConfigProvider
                .overrideWith(() => mockDeviceFilterConfigNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
            filteredDeviceListProvider.overrideWith((ref) =>
                deviceFilteredTestData
                    .map((e) => DeviceListItem.fromMap(e))
                    .toList()),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
        final editFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editFinder);
        await tester.pumpAndSettle();

        final inputFieldFinder = find.bySemanticsLabel('node name').last;
        await tester.tap(inputFieldFinder);
        await tester.enterText(inputFieldFinder,
            'fjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nmfjwkle23m3n,nm');
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - edit name modal, blink node',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
          deviceFilterConfigProvider
              .overrideWith(() => mockDeviceFilterConfigNotifier),
          deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
          wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
          filteredDeviceListProvider.overrideWith((ref) =>
              deviceFilteredTestData
                  .map((e) => DeviceListItem.fromMap(e))
                  .toList()),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);
      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
      });
      final editFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editFinder);
      await tester.pumpAndSettle();
      final blinkFinder = find.descendant(
          of: find.byType(AlertDialog),
          matching: find.byKey(const ValueKey('blinkNodeButton')));
      await tester.tap(blinkFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'Node details view - node light settings',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      when(mockDeviceFilterConfigNotifier.build()).thenReturn(
          DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
      when(mockServiceHelper.isSupportLedMode()).thenReturn(true);
      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
            deviceFilterConfigProvider
                .overrideWith(() => mockDeviceFilterConfigNotifier),
            deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
            wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
            filteredDeviceListProvider.overrideWith((ref) =>
                deviceFilteredTestData
                    .map((e) => DeviceListItem.fromMap(e))
                    .toList()),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerLn12, context);
        await tester.pumpAndSettle();
        final nodeLightFinder = find.byKey(const ValueKey('nodeLightSettings'));
        await tester.tap(nodeLightFinder);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
      'Node details view - devices tab for mobile layout',
      (tester, locale) async {
    when(mockNodeDetailNotifier.build())
        .thenReturn(NodeDetailState.fromMap(nodeDetailsCherry7TestState));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    when(mockDeviceFilterConfigNotifier.build()).thenReturn(
        DeviceFilterConfigState.fromMap(deviceFilterConfigTestState));
    final widget = testableSingleRoute(
      overrides: [
        nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        deviceFilterConfigProvider
            .overrideWith(() => mockDeviceFilterConfigNotifier),
        deviceManagerProvider.overrideWith(() => mockDeviceManagerNotifier),
        wifiBundleProvider.overrideWith(() => mockWifiBundleNotifier),
        filteredDeviceListProvider.overrideWith((ref) => deviceFilteredTestData
            .map((e) => DeviceListItem.fromMap(e))
            .toList()),
      ],
      locale: locale,
      child: const NodeDetailView(),
    );
    await tester.pumpWidget(widget);
    await tester.runAsync(() async {
      final context = tester.element(find.byType(NodeDetailView));

      await precacheImage(
          CustomTheme.of(context).images.devices.routerLn12, context);
      await tester.pumpAndSettle();

      final devicesTab = find.byType(Tab).last;
      await tester.tap(devicesTab);
      await tester.pumpAndSettle();
    });
  }, screens: responsiveMobileScreens);
}
