import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:mockito/mockito.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/firmware_update_notifier_mocks.dart';
import '../../../test_data/firmware_update_test_state.dart';
import '../../../test_data/node_details_data.dart';
import '../../../mocks/node_detail_notifier_mocks.dart';

void main() {
  late NodeDetailNotifier mockNodeDetailNotifier;
  late FirmwareUpdateNotifier mockFirmwareUpdateNotifier;

  setUp(() {
    mockNodeDetailNotifier = MockNodeDetailNotifier();
    mockFirmwareUpdateNotifier = MockFirmwareUpdateNotifier();
    // when(mockNodeDetailNotifier.isSupportLedBlinking()).thenReturn(true);
    // when(mockNodeDetailNotifier.isSupportLedMode()).thenReturn(true);
  });
  testLocalizations(
    'Node details view - master node',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);
      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - slave node',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState2));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - firmware update avaliable',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
      when(mockFirmwareUpdateNotifier.build()).thenReturn(
          FirmwareUpdateState.fromMap(firmwareUpdateHasFirmwareTestData));
      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - edit name modal',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await tester.pumpAndSettle();
        final editFinder = find.byIcon(LinksysIcons.edit);
        await tester.tap(editFinder);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - edit name modal, blink node',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);
      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await tester.pumpAndSettle();
      });
      final editFinder = find.byIcon(LinksysIcons.edit);
      await tester.tap(editFinder);
      await tester.pumpAndSettle();
      final blinkFinder = find.descendant(
          of: find.byType(AlertDialog), matching: find.byKey(const ValueKey('blinkNodeButton')));
      await tester.tap(blinkFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testLocalizations(
    'Node details view - more info modal',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await tester.pumpAndSettle();
        final moreFinder = find.byType(AppTextButton).first;
        await tester.tap(moreFinder);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - node light settings',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      await tester.runAsync(() async {
        final widget = testableSingleRoute(
          overrides: [
            nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
            firmwareUpdateProvider
                .overrideWith(() => mockFirmwareUpdateNotifier),
          ],
          locale: locale,
          child: const NodeDetailView(),
        );
        await tester.pumpWidget(widget);
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await tester.pumpAndSettle();
        final nodeLightFinder = find.byKey(const ValueKey('nodeLightSettings'));
        await tester.tap(nodeLightFinder);
        await tester.pumpAndSettle();
      });
    },
  );

  testLocalizations(
    'Node details view - blink node light',
    (tester, locale) async {
      when(mockNodeDetailNotifier.build())
          .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
      when(mockFirmwareUpdateNotifier.build())
          .thenReturn(FirmwareUpdateState.empty());
      final widget = testableSingleRoute(
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        ],
        locale: locale,
        child: const NodeDetailView(),
      );
      await tester.pumpWidget(widget);
      await tester.runAsync(() async {
        final context = tester.element(find.byType(NodeDetailView));

        await precacheImage(
            CustomTheme.of(context).images.devices.routerMx6200, context);
        await tester.pumpAndSettle();
      });
      final blinkFinder = find.byType(AppTextButton).last;
      await tester.tap(blinkFinder);
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();
    },
  );

  testLocalizations('Node details view - devices tab for mobile layout',
      (tester, locale) async {
    when(mockNodeDetailNotifier.build())
        .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    final widget = testableSingleRoute(
      overrides: [
        nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
        firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
      ],
      locale: locale,
      child: const NodeDetailView(),
    );
    await tester.pumpWidget(widget);
    await tester.runAsync(() async {
      final context = tester.element(find.byType(NodeDetailView));

      await precacheImage(
          CustomTheme.of(context).images.devices.routerMx6200, context);
      await tester.pumpAndSettle();

      final devicesTab = find.byType(Tab).last;
      await tester.tap(devicesTab);
      await tester.pumpAndSettle();
    });
  }, screens: responsiveMobileScreens);
}
