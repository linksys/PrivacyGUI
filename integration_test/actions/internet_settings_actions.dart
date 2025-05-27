part of 'base_actions.dart';

class TestInternetSettingsActions extends CommonBaseActions {
  TestInternetSettingsActions(super.tester);

  Finder ipv4TabFinder() {
    final tabsFinder = find.byType(Tab);
    expect(tabsFinder, findsNWidgets(3));
    return tabsFinder.at(0);
  }

  Finder ipv6TabFinder() {
    final tabsFinder = find.byType(Tab);
    expect(tabsFinder, findsNWidgets(3));
    return tabsFinder.at(1);
  }

  Finder releaseTabFinder() {
    final tabsFinder = find.byType(Tab);
    expect(tabsFinder, findsNWidgets(3));
    return tabsFinder.at(2);
  }

  Finder editIconButtonFinder() {
    final iconButtonFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.edit),
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

  Finder connectionTypeDropdownFinder() {
    final dropdownFinder = find.byKey(const ValueKey('ipv4ConnectionDropdown'));
    expect(dropdownFinder, findsOneWidget);
    return dropdownFinder;
  }

  Finder mtuDropdownFinder() {
    final dropdownFinder = find.byKey(const ValueKey('mtuDropdown'));
    expect(dropdownFinder, findsOneWidget);
    return dropdownFinder;
  }

  Finder mtuSizeTextfieldFinder() {
    final textfieldFinder = find.byKey(const ValueKey('mtuManualSizeText'));
    expect(textfieldFinder, findsOneWidget);
    return textfieldFinder;
  }

  Finder macCloneSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder cloneTextButtonFinder() {
    final textButtonFinder = find.ancestor(
      of: find.text("Clone current client's MAC"),
      matching: find.byType(AppTextButton),
    );
    expect(textButtonFinder, findsOneWidget);
    return textButtonFinder;
  }

  Finder ipv4StaticAddressFieldFinder() {
    // Find static IPv4 address form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(6));
    final ipv4Finder = ipFormFieldFinder.at(0);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4StaticSubmaskFieldFinder() {
    // Find static IPv4 subnet mask form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(6));
    final ipv4Finder = ipFormFieldFinder.at(1);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4StaticGatewaysFieldFinder() {
    // Find static IPv4 default gateway form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(6));
    final ipv4Finder = ipFormFieldFinder.at(2);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4StaticDns1FieldFinder() {
    // Find static DNS 1 form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(6));
    final ipv4Finder = ipFormFieldFinder.at(3);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4StaticDns2FieldFinder() {
    // Find static DNS 2 form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(6));
    final ipv4Finder = ipFormFieldFinder.at(4);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4StaticDns3FieldFinder() {
    // Find static DNS 3 form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(6));
    final ipv4Finder = ipFormFieldFinder.at(5);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder pppoeUserTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(8));
    return textfieldFinder.at(0);
  }

  Finder pppoePasswordTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(8));
    return textfieldFinder.at(1);
  }

  Finder pppoeVlanIdTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(8));
    return textfieldFinder.at(2);
  }

  Finder pppoeServiceTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(8));
    return textfieldFinder.at(3);
  }

  Finder connectOnDemandRadioFinder() {
    final radioItemFinder = find.ancestor(
      of: find.text('Connect on demand'),
      matching: find.byType(InkWell),
    );
    expect(radioItemFinder, findsOneWidget);
    return radioItemFinder;
  }

  Finder maxIdleTimeTextfieldFinder() {
    final textfieldFinder = find.byKey(const Key('maxIdleTimeText'));
    expect(textfieldFinder, findsOneWidget);
    return textfieldFinder;
  }

  Finder keepAliveRadioFinder() {
    final radioItemFinder = find.ancestor(
      of: find.text('Keep alive'),
      matching: find.byType(InkWell),
    );
    expect(radioItemFinder, findsOneWidget);
    return radioItemFinder;
  }

  Finder redialPeriodTextfieldFinder() {
    final textfieldFinder = find.byKey(const ValueKey('redialPeriodText'));
    expect(textfieldFinder, findsOneWidget);
    return textfieldFinder;
  }

  Finder pptpAutoIpRadioFinder() {
    final radioItemFinder = find.ancestor(
      of: find.text('Obtain an IPv4 address automatically (DHCP)'),
      matching: find.byType(InkWell),
    );
    expect(radioItemFinder, findsOneWidget);
    return radioItemFinder;
  }

  Finder pptpSpecifyIpRadioFinder() {
    final radioItemFinder = find.ancestor(
      of: find.text('Specify an IPv4 address'),
      matching: find.byType(InkWell),
    );
    expect(radioItemFinder, findsOneWidget);
    return radioItemFinder;
  }

  Finder ipv4PptpAddressFieldFinder() {
    // Find PPTP IPv4 address form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(7));
    final ipv4Finder = ipFormFieldFinder.at(0);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4PptpSubmaskFieldFinder() {
    // Find PPTP IPv4 subnet mask form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(7));
    final ipv4Finder = ipFormFieldFinder.at(1);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4PptpGatewaysFieldFinder() {
    // Find PPTP IPv4 default gateway form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(7));
    final ipv4Finder = ipFormFieldFinder.at(2);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4PptpDns1FieldFinder() {
    // Find PPTP DNS 1 form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(7));
    final ipv4Finder = ipFormFieldFinder.at(3);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4PptpDns2FieldFinder() {
    // Find PPTP DNS 2 form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(7));
    final ipv4Finder = ipFormFieldFinder.at(4);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4PptpDns3FieldFinder() {
    // Find PPTP DNS 3 form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsNWidgets(7));
    final ipv4Finder = ipFormFieldFinder.at(5);
    final ipTextFormFieldFinder =
        find.descendant(of: ipv4Finder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder serverIpv4AddressFieldFinder() {
    // Find IP address form
    final ipFormFieldFinder =
        find.byKey(const ValueKey('ipv4ServerAddressField'));
    expect(ipFormFieldFinder, findsOneWidget);
    final ipTextFormFieldFinder = find.descendant(
        of: ipFormFieldFinder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv4UserNameTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(6));
    return textfieldFinder.at(0);
  }

  Finder ipv4PasswordTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(6));
    return textfieldFinder.at(1);
  }

  Finder ipv6ConnectionTypeDropdownFinder() {
    final dropdownFinder = find.byKey(const ValueKey('ipv6ConnectionDropdown'));
    expect(dropdownFinder, findsOneWidget);
    return dropdownFinder;
  }

  Finder ipv6AutomaticCheckboxFinder() {
    final checkboxFinder = find.byType(AppCheckbox);
    expect(checkboxFinder, findsOneWidget);
    return checkboxFinder;
  }

  Finder ipv6TunnelDropdownFinder() {
    final dropdownFinder = find.byKey(const ValueKey('ipv6TunnelDropdown'));
    expect(dropdownFinder, findsOneWidget);
    return dropdownFinder;
  }

  Finder ipv6PrefixTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(5));
    return textfieldFinder.at(0);
  }

  Finder ipv6PrefixLengthTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(5));
    return textfieldFinder.at(1);
  }

  Finder ipv6BorderRelayIpFieldFinder() {
    // Find IPv6 border relay IP address form
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsOneWidget);
    final ipTextFormFieldFinder = find.descendant(
        of: ipFormFieldFinder, matching: find.byType(TextFormField));
    expect(ipTextFormFieldFinder, findsNWidgets(4));
    return ipTextFormFieldFinder;
  }

  Finder ipv6BorderRelayLengthTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(5));
    return textfieldFinder.at(2);
  }

  Finder ipv4ReleaseAndRenewButtonFinder() {
    final textfieldFinder = find.descendant(
        of: find.byType(AppListCard), matching: find.byType(AppTextButton));
    expect(textfieldFinder, findsNWidgets(2));
    return textfieldFinder.first;
  }

  Finder ipv6ReleaseAndRenewButtonFinder() {
    final textfieldFinder = find.descendant(
        of: find.byType(AppListCard), matching: find.byType(AppTextButton));
    expect(textfieldFinder, findsNWidgets(2));
    return textfieldFinder.last;
  }

  Finder saveButtonFinder() {
    final saveButton = find.byType(AppFilledButton);
    expect(saveButton, findsOneWidget);
    return saveButton;
  }

  Finder cancelButtonFinder() {
    final cancelButtonFinder = find.ancestor(
      of: find.text('Cancel'),
      matching: find.byType(AppTextButton),
    );
    expect(cancelButtonFinder, findsOneWidget);
    return cancelButtonFinder;
  }

  Finder restartButtonFinder() {
    final restartButtonFinder = find.ancestor(
      of: find.text('Restart'),
      matching: find.byType(AppTextButton),
    );
    expect(restartButtonFinder, findsOneWidget);
    return restartButtonFinder;
  }

  Finder errorAlertDialogFinder() {
    final alertFinder = find.ancestor(
      of: find.text('Error'),
      matching: find.byType(AlertDialog),
    );
    expect(alertFinder, findsOneWidget);
    return alertFinder;
  }

  Finder okDialogButtonFinder() {
    final buttonFinder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(AppTextButton),
    );
    expect(buttonFinder, findsOneWidget);
    return buttonFinder;
  }

  Finder cancelDialogButtonFinder() {
    final buttonFinder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(AppTextButton),
    );
    expect(buttonFinder, findsNWidgets(2));
    return buttonFinder.first;
  }

  Finder releaseDialogButtonFinder() {
    final buttonFinder = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(AppTextButton),
    );
    expect(buttonFinder, findsNWidgets(2));
    return buttonFinder.last;
  }

  //////////////////////////////

  Future<void> tapIpv4Tab() async {
    final tabFinder = ipv4TabFinder();
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapIpv6Tab() async {
    final tabFinder = ipv6TabFinder();
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapReleaseTab() async {
    final tabFinder = releaseTabFinder();
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapEditIconButton() async {
    final buttonFinder = editIconButtonFinder();
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapCloseIconButton() async {
    final buttonFinder = closeIconButtonFinder();
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> selectDhcpType() async {
    // Find dropdown
    final dropdownFinder = connectionTypeDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Automatic Configuration - DHCP'), findsAny);
    await tester.tap(find.text('Automatic Configuration - DHCP').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectStaticIpType() async {
    // Find dropdown
    final dropdownFinder = connectionTypeDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Static IP'), findsAny);
    await tester.tap(find.text('Static IP').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectPppoeType() async {
    // Find dropdown
    final dropdownFinder = connectionTypeDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('PPPoE'), findsAny);
    await tester.tap(find.text('PPPoE').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectPptpType() async {
    // Find dropdown
    final dropdownFinder = connectionTypeDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('PPTP'), findsAny);
    await tester.tap(find.text('PPTP').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectL2tpType() async {
    // Find dropdown
    final dropdownFinder = connectionTypeDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('L2TP'), findsAny);
    await tester.tap(find.text('L2TP').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectBridgeType() async {
    // Find dropdown
    final dropdownFinder = connectionTypeDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Bridge Mode'), findsAny);
    await tester.tap(find.text('Bridge Mode').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectAutoMtu() async {
    final dropdownFinder = mtuDropdownFinder();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Auto'), findsAny);
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectManualMtu() async {
    final dropdownFinder = mtuDropdownFinder();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Manual'), findsAny);
    await tester.tap(find.text('Manual').last);
    await tester.pumpAndSettle();
  }

  Future<void> inputMtuSize() async {
    final textfieldFinder = mtuSizeTextfieldFinder();
    await tester.enterText(textfieldFinder, '1000');
    await tester.pumpAndSettle();
  }

  Future<void> toggleMacCloneSwitch() async {
    // Find the MAC Address Clone switch
    final switchFinder = macCloneSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapCloneMacButton() async {
    // Find the text button
    final buttonFinder = cloneTextButtonFinder();
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv4StaticAddress() async {
    final textFieldFinder = ipv4StaticAddressFieldFinder();
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
    await tester.enterText(textFieldFinder.at(3), '10');
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv4StaticSubmask() async {
    final textFieldFinder = ipv4StaticSubmaskFieldFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '255');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '255');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(2), '255');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '0');
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv4StaticGateway() async {
    final textFieldFinder = ipv4StaticGatewaysFieldFinder();
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

  Future<void> inputIpv4StaticDns1() async {
    final textFieldFinder = ipv4StaticDns1FieldFinder();
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

  Future<void> inputIpv4StaticDns2() async {
    final textFieldFinder = ipv4StaticDns2FieldFinder();
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

  Future<void> inputIpv4StaticDns3() async {
    final textFieldFinder = ipv4StaticDns3FieldFinder();
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

  Future<void> inputPppoeUserName() async {
    final textfieldFinder = pppoeUserTextfieldFinder();
    await tester.enterText(textfieldFinder, 'MyName');
    await tester.pumpAndSettle();
  }

  Future<void> inputPppoePassword() async {
    final textfieldFinder = pppoePasswordTextfieldFinder();
    await tester.enterText(textfieldFinder, 'linksys');
    await tester.pumpAndSettle();
  }

  Future<void> inputPppoeVlanId() async {
    final textfieldFinder = pppoeVlanIdTextfieldFinder();
    await tester.enterText(textfieldFinder, '123');
    await tester.pumpAndSettle();
  }

  Future<void> inputPppoeServiceName() async {
    final textfieldFinder = pppoeServiceTextfieldFinder();
    await tester.enterText(textfieldFinder, 'MyService');
    await tester.pumpAndSettle();
  }

  Future<void> tapPPtpAutoIpRadio() async {
    // Find radio item
    final radioFinder = pptpAutoIpRadioFinder();
    // Tap the raio item
    await tester.tap(radioFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapPPtpSpecifyIpRadio() async {
    // Find radio item
    final radioFinder = pptpSpecifyIpRadioFinder();
    // Tap the raio item
    await tester.tap(radioFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv4PptpAddress() async {
    final textFieldFinder = ipv4PptpAddressFieldFinder();
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
    await tester.enterText(textFieldFinder.at(2), '5');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '10');
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv4PptpSubmask() async {
    final textFieldFinder = ipv4PptpSubmaskFieldFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '255');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '255');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(2), '255');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '0');
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv4PptpGateway() async {
    final textFieldFinder = ipv4PptpGatewaysFieldFinder();
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
    await tester.enterText(textFieldFinder.at(2), '5');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '1');
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv4PptpDns1() async {
    final textFieldFinder = ipv4PptpDns1FieldFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '111');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '111');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(2), '111');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '111');
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv4PptpDns2() async {
    final textFieldFinder = ipv4PptpDns2FieldFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '111');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '111');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(2), '111');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '111');
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv4PptpDns3() async {
    final textFieldFinder = ipv4PptpDns3FieldFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '111');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '111');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(2), '111');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '111');
    await tester.pumpAndSettle();
  }

  Future<void> inputServerIpv4Address() async {
    final textFieldFinder = serverIpv4AddressFieldFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '222');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '222');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(2));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(2), '222');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(3), '222');
    await tester.pumpAndSettle();
  }

  Future<void> inputUserName() async {
    final textfieldFinder = ipv4UserNameTextfieldFinder();
    await tester.enterText(textfieldFinder, 'MyName');
    await tester.pumpAndSettle();
  }

  Future<void> inputPassword() async {
    final textfieldFinder = ipv4PasswordTextfieldFinder();
    await tester.enterText(textfieldFinder, 'Linksys123');
    await tester.pumpAndSettle();
  }

  Future<void> inputMaxIdleTime() async {
    final textfieldFinder = maxIdleTimeTextfieldFinder();
    await tester.enterText(textfieldFinder, '20');
    await tester.pumpAndSettle();
  }

  Future<void> inputRedialPeriod() async {
    final textfieldFinder = redialPeriodTextfieldFinder();
    await tester.enterText(textfieldFinder, '40');
    await tester.pumpAndSettle();
  }

  Future<void> checkIpv4DhcpType() async {
    final dhcpTextFinder = find.descendant(
        of: find.byType(AppSettingCard), matching: find.text('DHCP'));
    expect(dhcpTextFinder, findsOneWidget);
    await tester.pumpAndSettle();
  }

  Future<void> selectIPv6AutomaticType() async {
    // Find dropdown
    final dropdownFinder = ipv6ConnectionTypeDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Automatic'), findsAny);
    await tester.tap(find.text('Automatic').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectIPv6PppoeType() async {
    // Find dropdown
    final dropdownFinder = ipv6ConnectionTypeDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('PPPoE'), findsAny);
    await tester.tap(find.text('PPPoE').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectIPv6PassThroughType() async {
    // Find dropdown
    final dropdownFinder = ipv6ConnectionTypeDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Pass-through'), findsAny);
    await tester.tap(find.text('Pass-through').last);
    await tester.pumpAndSettle();
  }

  Future<void> tapIpv6AutomaticCheckbox() async {
    // Find checkbox
    final dropdownFinder = ipv6AutomaticCheckboxFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
  }

  Future<void> selectIpv6TunnelDisabled() async {
    // Find dropdown
    final dropdownFinder = ipv6TunnelDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Disabled'), findsAny);
    await tester.tap(find.text('Disabled').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectIpv6TunnelAutomatic() async {
    // Find dropdown
    final dropdownFinder = ipv6TunnelDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Automatic'), findsAny);
    await tester.tap(find.text('Automatic').last);
    await tester.pumpAndSettle();
  }

  Future<void> selectIpv6TunnelManual() async {
    // Find dropdown
    final dropdownFinder = ipv6TunnelDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Manual'), findsAny);
    await tester.tap(find.text('Manual').last);
    await tester.pumpAndSettle();
  }

  Future<void> inputPrefix() async {
    final textfieldFinder = ipv6PrefixTextfieldFinder();
    await tester.enterText(textfieldFinder, '2001:db8::');
    await tester.pumpAndSettle();
  }

  Future<void> inputPrefixLength() async {
    final textfieldFinder = ipv6PrefixLengthTextfieldFinder();
    await tester.enterText(textfieldFinder, '32');
    await tester.pumpAndSettle();
  }

  Future<void> inputBorderRelay() async {
    final textFieldFinder = ipv6BorderRelayIpFieldFinder();
    await tester.tap(textFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(0), '192');
    await tester.pumpAndSettle();
    await tester.tap(textFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder.at(1), '0');
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

  Future<void> inputBorderRelayLength() async {
    final textfieldFinder = ipv6BorderRelayLengthTextfieldFinder();
    await tester.enterText(textfieldFinder, '32');
    await tester.pumpAndSettle();
  }

  Future<void> tapIpv4RleaseButton() async {
    final buttonFinder = ipv4ReleaseAndRenewButtonFinder();
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapIpv6RleaseButton() async {
    final buttonFinder = ipv6ReleaseAndRenewButtonFinder();
    await tester.tap(buttonFinder);
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

  Future<void> tapCancelButton() async {
    // Find the cancel button
    final buttonFinder = cancelButtonFinder();
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapRestartButton() async {
    // Find the restart button
    final buttonFinder = restartButtonFinder();
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapOkOnErrorAlertDialog() async {
    // Tap the OK button on the dialog
    await tester.tap(okDialogButtonFinder());
    await tester.pumpAndSettle();
  }

  Future<void> tapCancelOnReleaseAlertDialog() async {
    // Tap the Cancel button on the Release and Renew dialog
    await tester.tap(cancelDialogButtonFinder());
    await tester.pumpAndSettle();
  }

  Future<void> tapReleaseOnReleaseAlertDialog() async {
    // Tap the Release button on the Release and Renew dialog
    await tester.tap(releaseDialogButtonFinder());
    await tester.pumpAndSettle();
  }
}
