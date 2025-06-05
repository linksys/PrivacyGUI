part of 'base_actions.dart';

class TestAdvancedSettingsActions extends CommonBaseActions {
  TestAdvancedSettingsActions(super.tester);
  
  Finder internetSettingsCardFinder() {
    final cardFinder = find.ancestor(
      of: find.text(TestInternetSettingsActions(tester).title),
      matching: find.byType(AppCard),
    );
    expect(cardFinder, findsOneWidget);
    return cardFinder;
  }

  Finder advancedRoutingCardFinder() {
    final cardFinder = find.ancestor(
      of: find.text(TestAdvancedRoutingActions(tester).title),
      matching: find.byType(AppSettingCard),
    );
    expect(cardFinder, findsOneWidget);
    return cardFinder;
  }
  
  Finder firewallCardFinder() {
    final cardFinder = find.ancestor(
      of: find.text(TestFirewallActions(tester).title),
      matching: find.byType(AppCard),
    );
    expect(cardFinder, findsOneWidget);
    return cardFinder;
  }

  Finder appsAndGamingCardFinder() {
    final cardFinder = find.ancestor(
      of: find.text(TestAppsAndGamingActions(tester).title),
      matching: find.byType(AppCard),
    );
    expect(cardFinder, findsOneWidget);
    return cardFinder;
  }

  Finder administrationCardFinder() {
    final cardFinder = find.ancestor(
      of: find.text(TestAdministrationActions(tester).title),
      matching: find.byType(AppCard),
    );
    expect(cardFinder, findsOneWidget);
    return cardFinder;
  }

  Finder localNetworkCardFinder() {
    final cardFinder = find.ancestor(
      of: find.text(TestLocalNetworkSettingsActions(tester).title),
      matching: find.byType(AppCard),
    );
    expect(cardFinder, findsOneWidget);
    return cardFinder;
  }

  Finder dmzCardFinder() {
    final tappableFinder = find.ancestor(
      of: find.text(TestDmzActions(tester).title),
      matching: find.byType(InkWell),
    );
    expect(tappableFinder, findsOneWidget);
    return tappableFinder;
  }

  Future<void> enterInternetSettingsPage() async {
    final finder = internetSettingsCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterAdvancedRoutingPage() async {
    final finder = advancedRoutingCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterFirewallPage() async {
    final finder = firewallCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterAppsAndGamingPage() async {
    final finder = appsAndGamingCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterAdministrationPage() async {
    final finder = administrationCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterLocalNetworkSettingsPage() async {
    final finder = localNetworkCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> enterDmzPage() async {
    final finder = dmzCardFinder();
    // Tap the card
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }
}
