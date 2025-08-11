part of 'base_actions.dart';

class TestAdministrationActions extends CommonBaseActions {
  TestAdministrationActions(super.tester);

  bool isManageWirelesslySupported() {
    return tester.any(find.text('Allow local management wirelessly'));
  }

  Finder manageWirelesslySwitchFinder() {
    final cardFinder = find.ancestor(
      of: find.text('Allow local management wirelessly'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: cardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  bool isManageWirelesslySwitchEnabled() {
    final switchFinder = manageWirelesslySwitchFinder();
    final switchWidget = tester.widget<AppSwitch>(switchFinder);
    return switchWidget.value;
  }

  Finder upnpSwitchFinder() {
    final tileFinder = find.ancestor(
      of: find.text('UPnP'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: tileFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  bool isUpnpSwitchEnabled() {
    final switchFinder = upnpSwitchFinder();
    final switchWidget = tester.widget<AppSwitch>(switchFinder);
    return switchWidget.value;
  }

  Finder sipSwitchFinder() {
    final cardFinder = find.ancestor(
      of: find.text('Application Layer Gateway (SIP)'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: cardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  bool isSipSwitchEnabled() {
    final switchFinder = sipSwitchFinder();
    final switchWidget = tester.widget<AppSwitch>(switchFinder);
    return switchWidget.value;
  }

  Finder expressForwardingSwitchFinder() {
    final cardFinder = find.ancestor(
      of: find.text('Express Forwarding'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: cardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
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

  Finder allowToDisableCheckboxFinder() {
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsNWidgets(2));
    return checkboxFinder.last;
  }

  bool isAllowToDisableChecked() {
    final checkboxFinder = allowToDisableCheckboxFinder();
    final checkboxWidget = tester.widget<Checkbox>(checkboxFinder);
    return checkboxWidget.value!;
  }

  Finder saveButtonFinder() {
    final saveButton = find.byType(AppFilledButton);
    expect(saveButton, findsOneWidget);
    return saveButton;
  }

  Future<void> toggleManageWirelesslySwitch() async {
    // Find local management wirelessly switch
    final switchFinder = manageWirelesslySwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
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
    final checkboxFinder = allowToDisableCheckboxFinder();
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
