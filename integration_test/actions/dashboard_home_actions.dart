part of 'base_actions.dart';

class TestDashboardHomeActions extends CommonBaseActions {
  TestDashboardHomeActions(super.tester);

  Finder topologyCardFinder() {
    tester;
    final networkCardFinder = find.descendant(
      of: find.byType(DashboardNetworks),
      matching: find.byType(AppCard),
    );
    final topologyCard = networkCardFinder.at(1);
    expect(topologyCard, findsOneWidget);
    return topologyCard;
  }

  Finder devicesCardFinder() {
    final networkCardFinder = find.descendant(
      of: find.byType(DashboardNetworks),
      matching: find.byType(AppCard),
    );
    final devicesCard = networkCardFinder.at(2);
    expect(devicesCard, findsOneWidget);
    return devicesCard;
  }

  Finder masterNodeDetailFinder() {
    final nodeDetailFinder = find.descendant(
      of: find.byType(DashboardNetworks),
      matching: find.byType(SimpleTreeNodeItem),
    );
    // There may be more than one nodes in the network
    expect(nodeDetailFinder, findsAtLeastNWidgets(1));
    return nodeDetailFinder.first;
  }

  Finder nightModeInfoFinder() {
    final iconFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byIcon(Icons.info_outline),
        )
        .last;
    expect(iconFinder, findsOneWidget);
    return iconFinder;
  }

  Finder nightModeTooltipFinder() {
    return find.byTooltip(
      'When enabled, the LED light will turn off between 8:00 PM and 8:00 AM.',
    );
  }

  Finder nightModeSwitchFinder() {
    final nightModeSwitchFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(AppSwitch),
        )
        .last;
    expect(nightModeSwitchFinder, findsOneWidget);
    return nightModeSwitchFinder;
  }

  Finder instantPrivacyInfoFinder() {
    final iconFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byIcon(Icons.info_outline),
        )
        .first;
    expect(iconFinder, findsOneWidget);
    return iconFinder;
  }

  Finder instantPrivacyTooltipFinder() {
    return find.byTooltip(
      'Enabling Instant-Privacy prevents new devices from connecting to your network. To add a new device, disable Instant-Privacy, then re-enable it for enhanced security.',
    );
  }

  Finder instantPrivacySwitchFinder() {
    final instantPrivacySwitchFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(AppSwitch),
        )
        .first;
    expect(instantPrivacySwitchFinder, findsOneWidget);
    return instantPrivacySwitchFinder;
  }

  Finder instantPrivacyInkWellFinder() {
    final instantPrivacyFinder = find
        .descendant(
          of: find.byType(DashboardQuickPanel),
          matching: find.byType(InkWell),
        )
        .first;
    expect(instantPrivacyFinder, findsOneWidget);
    return instantPrivacyFinder;
  }

// input - 2.4, 5, 6 or guest
  Finder wifiCardFinderByBand(String band) {
    final wifiCardFinder = band == 'guest'
        ? find.byType(WiFiCard).last
        : find.ancestor(
            of: find.text('${band}GHz Band'),
            matching: find.byType(WiFiCard),
          );
    expect(wifiCardFinder, findsOneWidget);
    return wifiCardFinder;
  }

  // input - 2.4, 5, 6 or guest
  Finder wifiTooltipFinderByBand(String band) {
    final wifiCardFinder = wifiCardFinderByBand(band);
    expect(wifiCardFinder, findsOneWidget);

    final tooltipFinder = find.descendant(
      of: wifiCardFinder,
      matching: find.byType(SuperTooltip),
    );
    expect(tooltipFinder, findsOneWidget);
    return tooltipFinder;
  }

  // input - 2.4, 5, 6 or guest
  Finder wifiSwitchFinderByBand(String band) {
    final wifiCardFinder = wifiCardFinderByBand(band);
    expect(wifiCardFinder, findsOneWidget);

    final switchFinder = find.descendant(
      of: wifiCardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder wifi24gTooltipFinder() {
    return wifiTooltipFinderByBand('2.4');
  }

  Finder wifi24gSwitchFinder() {
    return wifiSwitchFinderByBand('2.4');
  }

  Finder wifi24gCardFinder() {
    return wifiCardFinderByBand('2.4');
  }

  Finder wifi5gTooltipFinder() {
    return wifiTooltipFinderByBand('5');
  }

  Finder wifi5gSwitchFinder() {
    return wifiSwitchFinderByBand('5');
  }

  Finder wifi5gCardFinder() {
    return wifiCardFinderByBand('5');
  }

  Finder wifi6gTooltipFinder() {
    return wifiTooltipFinderByBand('5');
  }

  Finder wifi6gSwitchFinder() {
    return wifiSwitchFinderByBand('6');
  }

  Finder wifi6gCardFinder() {
    return wifiCardFinderByBand('6');
  }

  Finder guestWifiTooltipFinder() {
    return wifiTooltipFinderByBand('guest');
  }

  Finder guestWifiSwitchFinder() {
    return wifiSwitchFinderByBand('guest');
  }

  Finder guestWifiCardFinder() {
    return wifiCardFinderByBand('guest');
  }

  Finder speedTestWidgetFinder() {
    final speedTestWidgetFinder = find.byType(SpeedTestWidget);
    expect(speedTestWidgetFinder, findsOneWidget);
    return speedTestWidgetFinder;
  }

  Finder speedTestGoButtonFinder() {
    final speedTestFinder = speedTestWidgetFinder();
    
    final goButtonFinder = find.descendant(
      of: speedTestFinder,
      matching: find.byKey(ValueKey('goBtn')),
    );
    expect(goButtonFinder, findsOneWidget);
    return goButtonFinder;
  }

  Finder speedTestDateTimeFinder() {
    final speedTestFinder = speedTestWidgetFinder();
    final dateTimeFinder = find.descendant(
      of: speedTestFinder,
      matching: find.byKey(ValueKey('speedTestDateTime')),
    );
    expect(dateTimeFinder, findsOneWidget);
    return dateTimeFinder;
  }

  Finder speedTestDownloadBandWidthFinder() {
    final speedTestFinder = speedTestWidgetFinder();
    final downloadBandWidthFinder = find.descendant(
      of: speedTestFinder,
      matching: find.byKey(ValueKey('downloadBandWidth')),
    );
    expect(downloadBandWidthFinder, findsOneWidget);
    return downloadBandWidthFinder;
  }

  Finder speedTestUploadBandWidthFinder() {
    final speedTestFinder = speedTestWidgetFinder();
    final uploadBandWidthFinder = find.descendant(
      of: speedTestFinder,
      matching: find.byKey(ValueKey('uploadBandWidth')),
    );
    expect(uploadBandWidthFinder, findsOneWidget);
    return uploadBandWidthFinder;
  }

  Finder speedTestTryAgainFinder() {
    final speedTestFinder = speedTestWidgetFinder();
    final tryAgainFinder = find.descendant(
      of: speedTestFinder,
      matching: find.byKey(ValueKey('speedTestTestAgain')),
    );
    expect(tryAgainFinder, findsOneWidget);
    return tryAgainFinder;
  }

  Future<void> checkTopologyPage() async {
    // Find topology card
    final topologyCard = topologyCardFinder();
    // Scroll the screen
    await scrollUntil(topologyCard);
    // Tap the card
    await tester.tap(topologyCard);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> checkDeviceListPage() async {
    // Find devices card
    final devicesCard = devicesCardFinder();
    // Tap the card
    await tester.tap(devicesCard);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> checkMasterNodeDetailPage() async {
    // Find tappable area of master node
    final masterFinder = masterNodeDetailFinder();
    // Scroll the screen
    await scrollUntil(masterFinder);
    // Tap the node detail
    await tester.tap(masterFinder);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> hoverToNightModeInfoIcon() async {
    // Find night mode info icon
    final iconFinder = nightModeInfoFinder();
    // scroll the screen
    await scrollUntil(iconFinder);
    await _hoverToCenter(iconFinder);
    expect(nightModeTooltipFinder(), findsOneWidget);
    await tester.pumpFrames(app(), Duration(seconds: 1));
  }

  Future<void> toggleNightMode() async {
    // Find night mode switch
    final switchFinder = nightModeSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> hoverToInstantPrivacyInfoIcon() async {
    // Find instant privacy info icon
    final iconFinder = instantPrivacyInfoFinder();
    await _hoverToCenter(iconFinder);
    expect(instantPrivacyTooltipFinder(), findsOneWidget);
    await tester.pumpFrames(app(), Duration(seconds: 1));
  }

  Future<void> toggleInstantPrivacy() async {
    // Find instant privacy switch
    final switchFinder = instantPrivacySwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    // Tap cancel button
    await _tapCancelOnInstantPrivacyDialog();
    // Again, tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
    await _tapOkOnInstantPrivacyDialog();
  }

  Future<void> checkInstantPrivacyPage() async {
    // Find tappable area of instant privacy
    final inkWellFinder = instantPrivacyInkWellFinder();
    // Tap the instant privacy
    await tester.tap(inkWellFinder);
    await tester.pumpAndSettle();
    await tapBackButton();
  }

  Future<void> hoverToWifi24gQrIcon() async {
    final switchFinder = wifi24gSwitchFinder();
    final isEnabled = tester.widget<AppSwitch>(switchFinder).value;
    // Find 2.4G Wifi QR code icon
    final tooltipFinder = wifi24gTooltipFinder();
    // scroll the screen
    await scrollUntil(tooltipFinder);
    await _hoverToCenter(tooltipFinder);
    expect(find.byType(QrImageView), isEnabled ? findsOneWidget : findsNothing);
    await tester.pumpAndSettle();
  }

  Future<void> toggle24gWifi() async {
    // Find Wifi 2.4G switch
    final switchFinder = wifi24gSwitchFinder();
    final switchWidget = tester.widget<AppSwitch>(switchFinder);
    final isEnabled = switchWidget.value;
    // Tap the switch
    await scrollAndTap(switchFinder);
    // Tap alert ok
    await tapAlertOkButton();
    await tester.pumpAndSettle();
    final switchValue = tester.widget<AppSwitch>(switchFinder).value;
    expect(switchValue, !isEnabled);
  }

  Future<void> checkWifi24gPage() async {
    // Find Wifi 2.4G card
    final wifiCardFinder = wifi24gCardFinder();
    // Tap the card
    await scrollAndTap(wifiCardFinder);
    await tapBackButton();
  }

  Future<void> hoverToWifi5gQrIcon() async {
    // Find 5G Wifi switch
    final switchFinder = wifi5gSwitchFinder();
    final isEnabled = tester.widget<AppSwitch>(switchFinder).value;
    final tooltipFinder = wifi5gTooltipFinder();
    // scroll the screen
    await scrollUntil(tooltipFinder);
    await _hoverToCenter(tooltipFinder);
    // If 5g wifi is disabled, there will be no QR code image
    expect(find.byType(QrImageView), isEnabled ? findsOneWidget : findsNothing);
    await tester.pumpAndSettle();
  }

  Future<void> toggle5gWifi() async {
    // Find 5G Wifi switch
    final switchFinder = wifi5gSwitchFinder();
    final switchWidget = tester.widget<AppSwitch>(switchFinder);
    final isEnabled = switchWidget.value;
    // Tap the switch
    await scrollAndTap(switchFinder);
    // Tap alert ok
    await tapAlertOkButton();
    await tester.pumpAndSettle();
    final switchValue = tester.widget<AppSwitch>(switchFinder).value;
    expect(switchValue, !isEnabled);
  }

  Future<void> checkWifi5gPage() async {
    // Find 5G Wifi card
    final wifiCardFinder = wifi5gCardFinder();
    // Tap the card
    await scrollAndTap(wifiCardFinder);
    await tapBackButton();
  }

  Future<void> hoverToWifi6gQrIcon() async {
    // Find 6G Wifi QR code icon
    final tooltipFinder = wifi6gTooltipFinder();
    // scroll the screen
    await scrollUntil(tooltipFinder);
    await _hoverToCenter(tooltipFinder);
    // If 6g wifi is disabled, there will be no QR code image
    final isEnabled = tester.widget<AppSwitch>(wifi6gSwitchFinder()).value;
    expect(find.byType(QrImageView), isEnabled ? findsOneWidget : findsNothing);
    await tester.pumpAndSettle();
  }

  Future<void> toggle6gWifi() async {
    // Find 6G Wifi switch
    final switchFinder = wifi6gSwitchFinder();
    final switchWidget = tester.widget<AppSwitch>(switchFinder);
    final isEnabled = switchWidget.value;
    // Tap the switch
    await scrollAndTap(switchFinder);
    // Tap alert ok
    await tapAlertOkButton();
    await tester.pumpAndSettle();
    final switchValue = tester.widget<AppSwitch>(switchFinder).value;
    expect(switchValue, !isEnabled);
  }

  Future<void> checkWifi6gPage() async {
    // Find 6G Wifi card
    final wifiCardFinder = wifi6gCardFinder();
    // Tap the card
    await scrollAndTap(wifiCardFinder);
    await tapBackButton();
  }

  Future<void> tapAlertOkButton() async {
    // Tap alert ok
    final alertFinder = find.byType(AlertDialog);
    expect(alertFinder, findsOneWidget);
    // Find the Ok button
    final dialogButtonFinder = find.descendant(
      of: alertFinder,
      matching: find.byType(AppTextButton),
    );
    expect(dialogButtonFinder, findsNWidgets(2));
    // Tap the Ok button
    await tester.tap(dialogButtonFinder.last);
    await tester.pumpAndSettle();
  }

  Future<void> hoverToGuestWifiQrIcon() async {
    // Find guest Wifi QR code icon
    final tooltipFinder = guestWifiTooltipFinder();
    // scroll the screen
    await scrollUntil(tooltipFinder);
    await _hoverToCenter(tooltipFinder);
    // If guest wifi is disabled, there will be no QR code image
    final isEnabled = tester.widget<AppSwitch>(guestWifiSwitchFinder()).value;
    expect(find.byType(QrImageView), isEnabled ? findsOneWidget : findsNothing);
    await tester.pumpAndSettle();
  }

  Future<void> toggleGuestWifi() async {
    // Find guest Wifi switch
    final switchFinder = guestWifiSwitchFinder();
    // Tap the switch
    await scrollAndTap(switchFinder);
    // Tap alert ok
    await tapAlertOkButton();
    await tester.pumpAndSettle();
  }

  Future<void> checkGuestWifiPage() async {
    // Find guest Wifi card
    final wifiCardFinder = guestWifiCardFinder();
    // Tap the card
    await scrollAndTap(wifiCardFinder);
    await tapBackButton();
  }

  Future<void> _tapCancelOnInstantPrivacyDialog() async {
    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);
    // Find the cancel button
    final dialogButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(dialogButtonFinder, findsNWidgets(2));
    // Tap the cancel button
    await tester.tap(dialogButtonFinder.first);
    await tester.pumpAndSettle();
  }

  Future<void> _tapOkOnInstantPrivacyDialog() async {
    final dialogFinder = find.byType(AlertDialog);
    expect(dialogFinder, findsOneWidget);
    // Find the Ok button
    final dialogButtonFinder = find.descendant(
      of: dialogFinder,
      matching: find.byType(AppTextButton),
    );
    expect(dialogButtonFinder, findsNWidgets(2));
    // Tap the Ok button
    await tester.tap(dialogButtonFinder.last);
    await tester.pumpAndSettle();
  }

  Future<void> _hoverToCenter(Finder finder) async {
    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer();
    addTearDown(gesture.removePointer);
    await gesture.moveTo(tester.getCenter(finder));
    await tester.pumpAndSettle();
    // Explicitly remove the pointer after the hover action
    await gesture.removePointer();
  }

  Future<void> startSpeedTest() async {
    // Find speed test switch
    final goButtonFinder = speedTestGoButtonFinder();
    await scrollUntil(goButtonFinder);
    // Tap the switch
    await scrollAndTap(goButtonFinder);
    await tester.pumpFrames(app(), const Duration(seconds: 10));
    await tester.pumpAndSettle();
  }

  Future<void> checkSpeedTestResult() async {
    final dateTimeFinder = speedTestDateTimeFinder();
    final dateTimeWidget = tester.widget<AppText>(dateTimeFinder);
    expect(dateTimeWidget.text, isNot('--'));
    final downloadBandWidthFinder = speedTestDownloadBandWidthFinder();
    final downloadBandWidthWidget = tester.widget<AppText>(downloadBandWidthFinder);
    expect(downloadBandWidthWidget.text, isNot('-'));
    final uploadBandWidthFinder = speedTestUploadBandWidthFinder();
    final uploadBandWidthWidget = tester.widget<AppText>(uploadBandWidthFinder);
    expect(uploadBandWidthWidget.text, isNot('-'));
    speedTestTryAgainFinder();
    
  }
}
