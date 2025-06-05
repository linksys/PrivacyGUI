part of 'base_actions.dart';

class TestInstantPrivacyActions extends CommonBaseActions {
  TestInstantPrivacyActions(super.tester);

  Finder enableSwitchFinder() {
    final finder = find.byType(AppSwitch);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder turnOnButtonFinder() {
    final context = getContext();
    final finder = find.text(loc(context).turnOn);
    expect(finder, findsOneWidget);
    return finder;
  }

  Future tapEnableSwitch() async {
    final finder = enableSwitchFinder();
    await scrollAndTap(finder);
  }

  Future tapTurnOnButton() async {
    final finder = turnOnButtonFinder();
    await scrollAndTap(finder);
  }
}