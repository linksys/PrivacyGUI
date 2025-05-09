part of 'base_actions.dart';

class TestAdministrationActions extends CommonBaseActions {
  TestAdministrationActions(super.tester);

  Finder upnpSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsNWidgets(3));
    return switchFinder.at(0);
  }

  bool isUpnpSwitchEnabled() {
    final switchFinder = upnpSwitchFinder();
    final switchWidget = tester.widget<AppSwitch>(switchFinder);
    return switchWidget.value;
  }

  Finder sipSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsNWidgets(3));
    return switchFinder.at(1);
  }

  bool isSipSwitchEnabled() {
    final switchFinder = sipSwitchFinder();
    final switchWidget = tester.widget<AppSwitch>(switchFinder);
    return switchWidget.value;
  }

  Finder expressForwardingSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsNWidgets(3));
    return switchFinder.at(2);
  }

  bool isExpressForwardingSwitchEnabled() {
    final switchFinder = expressForwardingSwitchFinder();
    final switchWidget = tester.widget<AppSwitch>(switchFinder);
    return switchWidget.value;
  }

  Finder allowToConfigureCheckboxFinder() {
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsNWidgets(2));
    return checkboxFinder.first;
  }

  bool isAllowToConfigureChecked() {
    final checkboxFinder = allowToConfigureCheckboxFinder();
    final checkboxWidget = tester.widget<Checkbox>(checkboxFinder);
    return checkboxWidget.value!;
  }

  Finder allowToInternetCheckboxFinder() {
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsNWidgets(2));
    return checkboxFinder.last;
  }

  bool isAllowToInternetChecked() {
    final checkboxFinder = allowToInternetCheckboxFinder();
    final checkboxWidget = tester.widget<Checkbox>(checkboxFinder);
    return checkboxWidget.value!;
  }

  Finder saveButtonFinder() {
    final saveButton = find.byType(AppFilledButton);
    expect(saveButton, findsOneWidget);
    return saveButton;
  }

  Future<void> toggleUpnpSwitch() async {
    // Find UPnP switch
    final switchFinder = upnpSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleSipSwitch() async {
    // Find SIP switch
    final switchFinder = sipSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleExpressForwardingSwitch() async {
    // Find Express Forwarding switch
    final switchFinder = expressForwardingSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapAllowToConfigureCheckbox() async {
    // Find the checkbox
    final checkboxFinder = allowToConfigureCheckboxFinder();
    // Tap the checkbox
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapAllowToDisableInternetCheckbox() async {
    // Find the checkbox
    final checkboxFinder = allowToInternetCheckboxFinder();
    // Tap the checkbox
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();
  }

  void checkAllCheckboxHidden() {
    // Find the checkbox
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsNothing);
  }

  Future<void> tapSaveButton() async {
    // Find save button
    Finder buttonFinder = saveButtonFinder();
    // Ensure that the button is enabled
    final button = tester.widget<AppFilledButton>(buttonFinder);
    expect(button.onTap, isNotNull);
    // Tap the save button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }
}
