part of 'base_actions.dart';

class TestTopbarActions extends CommonBaseActions {
  TestTopbarActions(super.tester);

  Finder homeBtnFinder() {
    final restartBtnFinder = find.byIcon(LinksysIcons.home);
    expect(restartBtnFinder, findsOneWidget);
    return restartBtnFinder;
  }

  Finder menuBtnFinder() {
    final restartBtnFinder = find.byIcon(LinksysIcons.menu);
    expect(restartBtnFinder, findsOneWidget);
    return restartBtnFinder;
  }

  Finder supportBtnFinder() {
    final restartBtnFinder = find.byIcon(LinksysIcons.help);
    expect(restartBtnFinder, findsOneWidget);
    return restartBtnFinder;
  }

  Future<void> tapHomeButton() async {
    final finder = homeBtnFinder();
    await tester.tap(finder);
    await tester.pumpFrames(app(), Duration(seconds: 2));
  }

  Future<void> tapMenuButton() async {
    final finder = menuBtnFinder();
    await tester.tap(finder);
    await tester.pumpFrames(app(), Duration(seconds: 2));
  }

  Future<void> tapSupportButton() async {
    final finder = supportBtnFinder();
    await tester.tap(finder);
    await tester.pumpFrames(app(), Duration(seconds: 2));
  }
}
