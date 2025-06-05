part of 'base_actions.dart';

class TestDmzActions extends CommonBaseActions {
  TestDmzActions(super.tester);

  Finder dmzSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder automaticRadioFinder() {
    final radioItemFinder = find.ancestor(
      of: find.text('Automatic'),
      matching: find.byType(InkWell),
    );
    expect(radioItemFinder, findsOneWidget);
    return radioItemFinder;
  }

  Finder specifiedRangeRadioFinder() {
    final radioItemFinder = find.ancestor(
      of: find.text('Specified Range'),
      matching: find.byType(InkWell),
    );
    expect(radioItemFinder, findsOneWidget);
    return radioItemFinder;
  }

  Finder destinationIpAddressRadioFinder() {
    final radioItemFinder = find.ancestor(
      of: find.text('IP address'),
      matching: find.byType(InkWell),
    );
    expect(radioItemFinder, findsOneWidget);
    return radioItemFinder;
  }

  Finder destinationMacAddressRadioFinder() {
    final radioItemFinder = find.ancestor(
      of: find.text('MAC Address'),
      matching: find.byType(InkWell),
    );
    expect(radioItemFinder, findsOneWidget);
    return radioItemFinder;
  }

  Finder startSpecifiedIpFinder() {
    // Find the start specified IP address form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(3));
    final startFieldFinder = ipFormFieldFinder.at(0);
    final ipTextFormFieldFinder = find.descendant(
        of: startFieldFinder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder endSpecifiedIpFinder() {
    // Find the end specified IP address form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(3));
    final endFieldFinder = ipFormFieldFinder.at(1);
    final ipTextFormFieldFinder = find.descendant(
        of: endFieldFinder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder lastDestinationIpFormFieldFinder() {
    // Find the destination IP address form field
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(3));
    final destinationFieldFinder = ipFormFieldFinder.at(2);
    final ipTextFormFieldFinder = find.descendant(
      of: destinationFieldFinder,
      matching: find.byType(TextFormField),
    );
    expect(ipTextFormFieldFinder, findsWidgets);
    return ipTextFormFieldFinder.last;
  }

  Finder macTextFieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsOneWidget);
    return textfieldFinder;
  }

  Finder dhcpClientButtonFinder() {
    final buttonFinder = find.byType(AppTextButton);
    expect(buttonFinder, findsOneWidget);
    return buttonFinder;
  }

  Future<void> inputStartSpecifiedIp() async {
    final textFieldFinder = startSpecifiedIpFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '192');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '168');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(2), '2');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '1');
    await tester.pumpAndSettle();
  }

  Future<void> inputEndSpecifiedIp() async {
    final textFieldFinder = endSpecifiedIpFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '192');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '168');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(2), '2');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '5');
    await tester.pumpAndSettle();
  }

  Future<void> inputLastDestinationIpField() async {
    final textFieldFinder = lastDestinationIpFormFieldFinder();
    await tester.tap(textFieldFinder);
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder, '10');
    await tester.pumpAndSettle();
  }

  Future<void> inputMacAddress() async {
    final textfieldFinder = macTextFieldFinder();
    await tester.enterText(textfieldFinder, 'AABBCCDDEE22');
    await tester.pumpAndSettle();
  }

  bool isDmzEnabled() {
    // Find the switch
    final switchFinder = dmzSwitchFinder();
    final instantSafetySwitch = tester.widget<AppSwitch>(switchFinder);
    return instantSafetySwitch.value;
  }

  Finder saveButtonFinder() {
    final saveButton = find.byType(AppFilledButton);
    expect(saveButton, findsOneWidget);
    return saveButton;
  }

  Future<void> toggleDmzSwitch() async {
    // Find the switch
    final switchFinder = dmzSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapAutomaticRadio() async {
    // Find the radio
    final radioFinder = automaticRadioFinder();
    // Tap the radio
    await tester.tap(radioFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapSpecifiedRangeRadio() async {
    // Find the radio
    final radioFinder = specifiedRangeRadioFinder();
    // Tap the radio
    await tester.tap(radioFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapDestinationIpRadio() async {
    // Find the radio
    final radioFinder = destinationIpAddressRadioFinder();
    // Tap the radio
    await tester.tap(radioFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapDestinationMacRadio() async {
    // Find the radio
    final radioFinder = destinationMacAddressRadioFinder();
    // Tap the radio
    await tester.tap(radioFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapViewDhcpClientButton() async {
    // Find the DHCP client button
    final buttonFinder = dhcpClientButtonFinder();
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> checkSelectDevicesScreen() async {
    expect(find.text('Select devices'), findsOneWidget);
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
