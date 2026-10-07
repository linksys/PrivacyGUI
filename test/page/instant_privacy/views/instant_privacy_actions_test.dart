// Instant Privacy's direct write controls with full access.
//
// This page has no Save bar: its enable switch saves from a confirm dialog and
// each device's delete icon saves from its own. These tests pin that with full
// access both are live and both reach the save once confirmed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:privacy_gui/page/instant_device/_instant_device.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_device_list_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_provider.dart';
import 'package:privacy_gui/page/instant_privacy/providers/instant_privacy_state.dart';
import 'package:privacy_gui/page/instant_privacy/views/instant_privacy_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

import '../../../common/config.dart';
import '../../../common/di.dart';
import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';
import '../../../mocks/_index.dart';
import '../../../test_data/_index.dart';
import '../../../test_data/instant_privacy_test_data.dart';

void main() {
  late MockInstantPrivacyNotifier mockInstantPrivacyNotifier;

  mockDependencyRegister();

  // A device that is not the one viewing the page, so its delete is a real one.
  final otherDevice = DeviceListItem.fromMap(deviceFilteredTestData.first);

  void seed(Map<String, dynamic> map) {
    final state = InstantPrivacyState.fromMap(map);
    when(mockInstantPrivacyNotifier.build()).thenReturn(state);
    when(mockInstantPrivacyNotifier.fetch()).thenAnswer((_) async => state);
    when(mockInstantPrivacyNotifier.save()).thenAnswer((_) async => state);
  }

  setUp(() {
    mockInstantPrivacyNotifier = MockInstantPrivacyNotifier();
    when(mockInstantPrivacyNotifier.doPolling()).thenAnswer((_) async {});
  });

  Future<void> pumpPage(WidgetTester tester) async {
    await tester.setScreenSize(device1440w);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(testableSingleRoute(
      locale: const Locale('en'),
      overrides: [
        instantPrivacyProvider.overrideWith(() => mockInstantPrivacyNotifier),
        instantPrivacyDeviceListProvider.overrideWith((ref) => [otherDevice]),
      ],
      child: const InstantPrivacyView(),
    ));
    await tester.pumpAndSettle();
  }

  final toggle = find.byWidgetPredicate(
      (w) => w is AppSwitch && w.semanticLabel == 'instant privacy');

  testWidgets('enabling asks first, then saves', (tester) async {
    seed(instantPrivacyInitState);
    await pumpPage(tester);

    expect(tester.widget<AppSwitch>(toggle).onChanged, isNotNull);
    await tester.tap(toggle);
    await tester.pumpAndSettle();
    verifyNever(mockInstantPrivacyNotifier.save());

    await tester.tap(find.widgetWithText(AppTextButton, 'Turn On'));
    await tester.pumpAndSettle();
    verify(mockInstantPrivacyNotifier.setEnable(true)).called(1);
    verify(mockInstantPrivacyNotifier.save()).called(1);
  });

  testWidgets('deleting a device asks first, then saves', (tester) async {
    seed(instantPrivacyOnState);
    await pumpPage(tester);

    await tester.tap(find.byIcon(LinksysIcons.delete));
    await tester.pumpAndSettle();
    verifyNever(mockInstantPrivacyNotifier.save());

    await tester.tap(find.widgetWithText(AppTextButton, 'Delete'));
    await tester.pumpAndSettle();
    verify(mockInstantPrivacyNotifier.removeSelection([otherDevice.macAddress]))
        .called(1);
    verify(mockInstantPrivacyNotifier.save()).called(1);
  });

  testWidgets('the delete icon only appears while enabled', (tester) async {
    seed(instantPrivacyInitState);
    await pumpPage(tester);

    expect(find.byIcon(LinksysIcons.delete), findsNothing);
  });
}
