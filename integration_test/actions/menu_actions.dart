part of 'base_actions.dart';

class TestMenuActions extends CommonBaseActions {
  TestMenuActions(super.tester);

  Finder wifiCardFinder() {
    final wifiCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.wifi),
      matching: find.byType(AppCard),
    );
    expect(wifiCardFinder, findsOneWidget);
    return wifiCardFinder;
  }

  Finder adminCardFinder() {
    final adminCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.accountCircle),
      matching: find.byType(AppCard),
    );
    expect(adminCardFinder, findsOneWidget);
    return adminCardFinder;
  }

  Finder topologyCardFinder() {
    final topologyCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.router),
      matching: find.byType(AppCard),
    );
    expect(topologyCardFinder, findsOneWidget);
    return topologyCardFinder;
  }

  Finder safetyCardFinder() {
    final safetyCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.encrypted),
      matching: find.byType(AppCard),
    );
    expect(safetyCardFinder, findsOneWidget);
    return safetyCardFinder;
  }

  Finder privacyCardFinder() {
    final privacyCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.smartLock),
      matching: find.byType(AppCard),
    );
    expect(privacyCardFinder, findsOneWidget);
    return privacyCardFinder;
  }

  Finder devicesCardFinder() {
    final devicesCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.devices),
      matching: find.byType(AppCard),
    );
    expect(devicesCardFinder, findsOneWidget);
    return devicesCardFinder;
  }

  Finder advancedSettingsCardFinder() {
    final advancedSettingsCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.settings),
      matching: find.byType(AppCard),
    );
    expect(advancedSettingsCardFinder, findsOneWidget);
    return advancedSettingsCardFinder;
  }

  Finder verifyCardFinder() {
    final verifyCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.technician),
      matching: find.byType(AppCard),
    );
    expect(verifyCardFinder, findsOneWidget);
    return verifyCardFinder;
  }

  Finder externalSpeedTestCardFinder() {
    final externalSpeedTestCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.networkCheck),
      matching: find.byType(AppCard),
    );
    expect(externalSpeedTestCardFinder, findsOneWidget);
    return externalSpeedTestCardFinder;
  }

  Finder speedTestCardFinder() {
    final speedTestCardFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.networkCheck),
      matching: find.byType(AppCard),
    );
    expect(speedTestCardFinder, findsOneWidget);
    return speedTestCardFinder;
  }

  Finder restartBtnFinder() {
    final restartBtnFinder = find.byIcon(LinksysIcons.restartAlt);
    expect(restartBtnFinder, findsOneWidget);
    return restartBtnFinder;
  }

  Finder addNodeBtnFinder() {
    final restartBtnFinder = find.byIcon(LinksysIcons.add);
    expect(restartBtnFinder, findsOneWidget);
    return restartBtnFinder;
  }

  Finder privacyBetaLabelFinder() {
    final privacyBetaLabelFinder = find.descendant(
      of: privacyCardFinder(),
      matching: find.byType(StatusLabel),
    );
    expect(privacyBetaLabelFinder, findsOneWidget);
    return privacyBetaLabelFinder;
  }

  Finder cancelBtnFinder() {
    final cancelBtnFinder = find.byType(AppOutlinedButton);
    expect(cancelBtnFinder, findsOneWidget);
    return cancelBtnFinder;
  }

  Future<void> enterWifiPage() async {
    final finder = wifiCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterAdminPage() async {
    final finder = adminCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterTopologyPage() async {
    final finder = topologyCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterSafetyPage() async {
    final finder = safetyCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterPrivacyPage() async {
    final finder = privacyCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterDevicesPage() async {
    final finder = devicesCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterAdvancedSettingsPage() async {
    final finder = advancedSettingsCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterVerifyPage() async {
    final finder = verifyCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterExternalSpeedTestPage() async {
    final finder = externalSpeedTestCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterSpeedTestPage() async {
    final finder = speedTestCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterAddNodePage() async {
    final finder = addNodeBtnFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapRestartBtn() async {
    final finder = restartBtnFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelBtn() async {
    final finder = cancelBtnFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}
