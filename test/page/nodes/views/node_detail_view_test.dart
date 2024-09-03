import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_provider.dart';
import 'package:privacy_gui/core/jnap/providers/firmware_update_state.dart';
import 'package:privacy_gui/page/nodes/_nodes.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:mockito/mockito.dart';

import '../../../common/config.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_widget.dart';
import '../../../mocks/firmware_update_notifier_mocks.dart';
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
  testResponsiveWidgets('Test node details view with mobile layout',
      (tester) async {
    when(mockNodeDetailNotifier.build())
        .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    final widget = testableWidget(
        themeMode: ThemeMode.dark,
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        ],
        child: const NodeDetailView());
    await tester.pumpWidget(widget);

    final nameFinder = find.text('Router123');
    expect(nameFinder, findsOneWidget);
  }, variants: responsiveMobileVariants);
  testResponsiveWidgets('Test node details view with desktop layout',
      (tester) async {
    when(mockNodeDetailNotifier.build())
        .thenReturn(NodeDetailState.fromMap(fakeNodeDetailsState1));
    when(mockFirmwareUpdateNotifier.build())
        .thenReturn(FirmwareUpdateState.empty());
    final widget = testableWidget(
        themeMode: ThemeMode.dark,
        overrides: [
          nodeDetailProvider.overrideWith(() => mockNodeDetailNotifier),
          firmwareUpdateProvider.overrideWith(() => mockFirmwareUpdateNotifier),
        ],
        child: const NodeDetailView());
    await tester.pumpWidget(widget);

    BuildContext context = tester.element(find.byType(NodeDetailView));
    final nameFinder = find.text('Router123');
    expect(nameFinder, findsOneWidget);

    final routerImageFinder =
        find.image(CustomTheme.of(context).images.devices.routerMx6200);
    expect(routerImageFinder, findsOneWidget);
  }, variants: responsiveDesktopVariants);
}
