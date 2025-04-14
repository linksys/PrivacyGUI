part of 'base_actions.dart';

class TestAdvancedRoutingActions extends CommonBaseActions {
  TestAdvancedRoutingActions(super.tester);

  Finder addRoutingButtonFinder() {
    final buttonFinder = find.byType(AppTextButton);
    expect(buttonFinder, findsOneWidget);
    return buttonFinder;
  }

  Finder natRadioButtonFinder() {
    final radioButtonFinder =
        find.ancestor(of: find.text('NAT'), matching: find.byType(InkWell));
    expect(radioButtonFinder, findsOneWidget);
    return radioButtonFinder;
  }

  Finder dynamicRoutingRadioButtonFinder() {
    final radioButtonFinder = find.ancestor(
        of: find.text('Dynamic routing (RIP)'), matching: find.byType(InkWell));
    expect(radioButtonFinder, findsOneWidget);
    return radioButtonFinder;
  }

  Finder nameTextFieldFinder() {
    final nameFinder = find.byType(AppTextField);
    expect(nameFinder, findsOneWidget);
    return nameFinder;
  }

  Finder destinationIpFinder() {
    // Find destination IP address form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(3));
    final destinationFinder = ipFormFieldFinder.at(0);
    final ipTextFormFieldFinder = find.descendant(
        of: destinationFinder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder gatewayIpFinder() {
    // Find gateway IP address form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(3));
    final destinationFinder = ipFormFieldFinder.at(2);
    final ipTextFormFieldFinder = find.descendant(
        of: destinationFinder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder interfaceDropdownFinder() {
    // Find interface dropdown
    final dropdownFinder =
        find.byType(AppDropdownButton<RoutingSettingInterface>);
    expect(dropdownFinder, findsOneWidget);
    return dropdownFinder;
  }

  Finder checkIconButtonFinder() {
    final iconButtonFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.check),
      matching: find.byType(AppIconButton),
    );
    expect(iconButtonFinder, findsOneWidget);
    return iconButtonFinder;
  }

  Finder closeIconButtonFinder() {
    final iconButtonFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.close),
      matching: find.byType(AppIconButton),
    );
    expect(iconButtonFinder, findsOneWidget);
    return iconButtonFinder;
  }

  Finder editIconButtonFinder() {
    final iconButtonFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.edit),
      matching: find.byType(AppIconButton),
    );
    expect(iconButtonFinder, findsOneWidget);
    return iconButtonFinder;
  }

  Finder deleteIconButtonFinder() {
    final iconButtonFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.delete),
      matching: find.byType(AppIconButton),
    );
    expect(iconButtonFinder, findsOneWidget);
    return iconButtonFinder;
  }

  Finder saveButtonFinder() {
    final saveButton = find.byType(AppFilledButton);
    expect(saveButton, findsOneWidget);
    return saveButton;
  }

  Future<void> tapAddRoutingButton() async {
    // Find adding button
    final buttonFinder = addRoutingButtonFinder();
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapNatRadioButton() async {
    // Find the button
    final radioButtonFinder = natRadioButtonFinder();
    // Tap the button
    await tester.tap(radioButtonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapDynamicRoutingRadioButton() async {
    // Find the button
    final radioButtonFinder = dynamicRoutingRadioButtonFinder();
    // Tap the button
    await tester.tap(radioButtonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapRoutingNameField() async {
    final textFieldFinder = nameTextFieldFinder();
    await tester.tap(textFieldFinder);
    // await tester.pumpFrames(app(), Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> inputRoutingName() async {
    final textFieldFinder = nameTextFieldFinder();
    await tester.tap(textFieldFinder);
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder, 'Name1');
    await tester.pumpAndSettle();
  }

  Future<void> checkSavedRoutingName() async {
    final textFieldFinder = find.text('Name1');
    expect(textFieldFinder, findsOneWidget);
  }

  Future<void> tapLastDestinationIpField() async {
    final textFieldFinder = destinationIpFinder();
    await tester.tap(textFieldFinder.last);
    // await tester.pumpFrames(app(), Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> inputDestinationIp() async {
    final textFieldFinder = destinationIpFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '123');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '123');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(2), '123');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '123');
    await tester.pumpAndSettle();
  }

  Future<void> tapLastGatewayIpField() async {
    final textFieldFinder = gatewayIpFinder();
    await tester.tap(textFieldFinder.last);
    // await tester.pumpFrames(app(), Duration(seconds: 2));
    await tester.pumpAndSettle();
  }

  Future<void> inputGatewayIpForInternetInterface() async {
    final textFieldFinder = gatewayIpFinder();
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
    await tester.enterText(textFieldFinder.at(2), '3');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '1');
    await tester.pumpAndSettle();
  }

  Future<void> selectLanWirelessInterface() async {
    final dropdownFinder = interfaceDropdownFinder();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    final lanText = find.text('LAN/Wireless');
    expect(lanText, findsNWidgets(2));
    await tester.tap(lanText.first);
    await tester.pumpAndSettle();
    expect(find.text('LAN/Wireless'), findsOneWidget);
  }

  Future<void> selectInternetInterface() async {
    final dropdownFinder = interfaceDropdownFinder();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    final internetText = find.text('Internet');
    expect(internetText, findsOneWidget);
    await tester.tap(internetText);
    await tester.pumpAndSettle();
    expect(find.text('Internet'), findsOneWidget);
  }

  Future<void> tapCheckIconButton() async {
    final iconButtonFinder = checkIconButtonFinder();
    final iconButton = tester.widget<AppIconButton>(iconButtonFinder);
    expect(iconButton.onTap, isNotNull);
    await tester.tap(iconButtonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapCloseIconButton() async {
    final iconButtonFinder = closeIconButtonFinder();
    final iconButton = tester.widget<AppIconButton>(iconButtonFinder);
    expect(iconButton.onTap, isNotNull);
    await tester.tap(iconButtonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapEditIconButton() async {
    final iconButtonFinder = editIconButtonFinder();
    final iconButton = tester.widget<AppIconButton>(iconButtonFinder);
    expect(iconButton.onTap, isNotNull);
    await tester.tap(iconButtonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapDeleteIconButton() async {
    final iconButtonFinder = deleteIconButtonFinder();
    final iconButton = tester.widget<AppIconButton>(iconButtonFinder);
    expect(iconButton.onTap, isNotNull);
    await tester.tap(iconButtonFinder);
    await tester.pumpAndSettle();
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
