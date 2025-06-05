part of 'base_actions.dart';

class TestFirewallActions extends CommonBaseActions {
  TestFirewallActions(super.tester);

  Finder firewallTabFinder() {
    final tabFinder = find.ancestor(
      of: find.text('Firewall'),
      matching: find.byType(Tab),
    );
    expect(tabFinder, findsOneWidget);
    return tabFinder;
  }

  Finder vpnPassthroughTabFinder() {
    final tabFinder = find.ancestor(
      of: find.text('VPN Passthrough'),
      matching: find.byType(Tab),
    );
    expect(tabFinder, findsOneWidget);
    return tabFinder;
  }

  Finder internetFiltersTabFinder() {
    final tabFinder = find.ancestor(
      of: find.text('Internet filters'),
      matching: find.byType(Tab),
    );
    expect(tabFinder, findsOneWidget);
    return tabFinder;
  }

  Finder ipv6PortServicesTabFinder() {
    final tabFinder = find.ancestor(
      of: find.text('IPv6 port services'),
      matching: find.byType(Tab),
    );
    expect(tabFinder, findsOneWidget);
    return tabFinder;
  }

  Finder ipv4SpiSwitchFinder() {
    final ipv4CardFinder = find.ancestor(
      of: find.text('IPv4 SPI firewall protection'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: ipv4CardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder ipv6SpiSwitchFinder() {
    final ipv6CardFinder = find.ancestor(
      of: find.text('IPv6 SPI firewall protection'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: ipv6CardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder ipSecSwitchFinder() {
    final ipSecCardFinder = find.ancestor(
      of: find.text('IPSec Passthrough'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: ipSecCardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder pptpSwitchFinder() {
    final pptpCardFinder = find.ancestor(
      of: find.text('PPTP Passthrough'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: pptpCardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder l2tpSwitchFinder() {
    final l2tpCardFinder = find.ancestor(
      of: find.text('L2TP Passthrough'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: l2tpCardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder anonymousSwitchFinder() {
    final anonymousCardFinder = find.ancestor(
      of: find.text('Filter anonymous Internet requests'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: anonymousCardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder multicastSwitchFinder() {
    final multicastCardFinder = find.ancestor(
      of: find.text('Filter multicast'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: multicastCardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder natRedirectionSwitchFinder() {
    final redirectionCardFinder = find.ancestor(
      of: find.text('Filter Internet NAT redirection'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: redirectionCardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder identSwitchFinder() {
    final identCardFinder = find.ancestor(
      of: find.text('Filter ident (Port 113)'),
      matching: find.byType(AppCard),
    );
    final switchFinder = find.descendant(
      of: identCardFinder,
      matching: find.byType(AppSwitch),
    );
    expect(switchFinder, findsOneWidget);
    return switchFinder;
  }

  Finder addTextButtonFinder() {
    final addButtonFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.add),
      matching: find.byType(AppTextButton),
    );
    expect(addButtonFinder, findsOneWidget);
    return addButtonFinder;
  }

  Finder closeIconButtonFinder() {
    final iconButtonFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.close),
      matching: find.byType(AppIconButton),
    );
    expect(iconButtonFinder, findsOneWidget);
    return iconButtonFinder;
  }

  Finder checkIconButtonFinder() {
    final iconButtonFinder = find.ancestor(
      of: find.byIcon(LinksysIcons.check),
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

  Finder nameTextFieldFinder() {
    final nameFinder = find.byType(AppTextField);
    expect(nameFinder, findsNWidgets(3));
    return nameFinder.at(0);
  }

  Finder protocolDropdownFinder() {
    final dropdownFinder = find.byType(AppDropdownButton<String>);
    expect(dropdownFinder, findsOneWidget);
    return dropdownFinder;
  }

  Finder ipv6FormFieldFinder() {
    final formFieldFinder = find.byType(AppIPv6FormField);
    expect(formFieldFinder, findsOneWidget);
    final ipTextFormFieldFinder = find.descendant(
      of: formFieldFinder,
      matching: find.byType(TextFormField),
    );
    expect(ipTextFormFieldFinder, findsNWidgets(8));
    return ipTextFormFieldFinder;
  }

  Finder startPortTextFieldFinder() {
    final nameFinder = find.byType(AppTextField);
    expect(nameFinder, findsNWidgets(3));
    return nameFinder.at(1);
  }

  Finder endPortTextFieldFinder() {
    final nameFinder = find.byType(AppTextField);
    expect(nameFinder, findsNWidgets(3));
    return nameFinder.at(2);
  }

  Finder saveButtonFinder() {
    final saveButton = find.byType(AppFilledButton);
    expect(saveButton, findsOneWidget);
    return saveButton;
  }

  Future<void> tapFirewallTab() async {
    // Find tab
    final tabFinder = firewallTabFinder();
    // Tap the tab
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapVpnPassthroughTab() async {
    // Find tab
    final tabFinder = vpnPassthroughTabFinder();
    // Tap the tab
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapInternetFiltersTab() async {
    // Find tab
    final tabFinder = internetFiltersTabFinder();
    // Tap the tab
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapIpv6PortServicesTab() async {
    // Find tab
    final tabFinder = ipv6PortServicesTabFinder();
    // Tap the tab
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleIpv4ProtectionSwitch() async {
    // Find switch
    final switchFinder = ipv4SpiSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleIpv6ProtectionSwitch() async {
    // Find switch
    final switchFinder = ipv6SpiSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleIpSecSwitch() async {
    // Find switch
    final switchFinder = ipSecSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> togglePptpSwitch() async {
    // Find switch
    final switchFinder = pptpSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleL2tpSwitch() async {
    // Find switch
    final switchFinder = l2tpSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleAnonymousSwitch() async {
    // Find switch
    final switchFinder = anonymousSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleMulticastSwitch() async {
    // Find switch
    final switchFinder = multicastSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleInternetNatRedirectionSwitch() async {
    // Find switch
    final switchFinder = natRedirectionSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleIdentSwitch() async {
    // Find switch
    final switchFinder = identSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapAddIpv6Button() async {
    // Find the button
    final buttonFinder = addTextButtonFinder();
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapCloseIconButton() async {
    final iconButtonFinder = closeIconButtonFinder();
    final iconButton = tester.widget<AppIconButton>(iconButtonFinder);
    expect(iconButton.onTap, isNotNull);
    await tester.tap(iconButtonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapCheckIconButton() async {
    final iconButtonFinder = checkIconButtonFinder();
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

  Future<void> tapNameTextField() async {
    final textFieldFinder = nameTextFieldFinder();
    await tester.tap(textFieldFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputName() async {
    final textFieldFinder = nameTextFieldFinder();
    await tester.tap(textFieldFinder);
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder, 'Name1');
    await tester.pumpAndSettle();
  }

  Future<void> selectTcpProtocol() async {
    final dropdownFinder = protocolDropdownFinder();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    final tcpText = find.text('TCP');
    expect(tcpText, findsAtLeastNWidgets(1));
    await tester.tap(tcpText);
    await tester.pumpAndSettle();
    expect(find.text('TCP'), findsOneWidget);
  }

  Future<void> selectUdpProtocol() async {
    final dropdownFinder = protocolDropdownFinder();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    final udpText = find.text('UDP');
    expect(udpText, findsAtLeastNWidgets(1));
    await tester.tap(udpText);
    await tester.pumpAndSettle();
    expect(find.text('UDP'), findsOneWidget);
  }

  Future<void> selectBothProtocol() async {
    final dropdownFinder = protocolDropdownFinder();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    final bothText = find.text('UDP and TCP');
    expect(bothText, findsAtLeastNWidgets(1));
    await tester.tap(bothText.first);
    await tester.pumpAndSettle();
    expect(find.text('UDP and TCP'), findsOneWidget);
  }

  Future<void> tapStartPortTextField() async {
    final textFieldFinder = startPortTextFieldFinder();
    await tester.tap(textFieldFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputStartPort() async {
    final textFieldFinder = startPortTextFieldFinder();
    await tester.tap(textFieldFinder);
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder, '1');
    await tester.pumpAndSettle();
  }

  Future<void> tapEndPortTextField() async {
    final textFieldFinder = endPortTextFieldFinder();
    await tester.tap(textFieldFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputEndPort() async {
    final textFieldFinder = endPortTextFieldFinder();
    await tester.tap(textFieldFinder);
    await tester.pumpAndSettle();
    await tester.enterText(textFieldFinder, '10');
    await tester.pumpAndSettle();
  }

  Future<void> inputIncorrectPorts() async {
    final endTextFieldFinder = endPortTextFieldFinder();
    await tester.tap(endTextFieldFinder);
    await tester.pumpAndSettle();
    await tester.enterText(endTextFieldFinder, '1');
    await tester.pumpAndSettle();
    final startTextFieldFinder = startPortTextFieldFinder();
    await tester.tap(startTextFieldFinder);
    await tester.pumpAndSettle();
    await tester.enterText(startTextFieldFinder, '11');
    await tester.pumpAndSettle();
  }

  Future<void> tapLastIpv6FormField() async {
    final ipv6TextFormFieldFinder = ipv6FormFieldFinder();
    await tester.tap(ipv6TextFormFieldFinder.last);
    await tester.pumpAndSettle();
  }

  Future<void> inputIpv6Address() async {
    final ipv6TextFormFieldFinder = ipv6FormFieldFinder();
    await tester.tap(ipv6TextFormFieldFinder.at(0));
    await tester.pumpAndSettle();
    await tester.enterText(ipv6TextFormFieldFinder.at(0), 'ace0');
    await tester.pumpAndSettle();
    await tester.tap(ipv6TextFormFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(ipv6TextFormFieldFinder.at(1), 'ace0');
    await tester.pumpAndSettle();
    await tester.tap(ipv6TextFormFieldFinder.at(1));
    await tester.pumpAndSettle();
    await tester.enterText(ipv6TextFormFieldFinder.at(2), 'ace0');
    await tester.pumpAndSettle();
    await tester.tap(ipv6TextFormFieldFinder.at(3));
    await tester.pumpAndSettle();
    await tester.enterText(ipv6TextFormFieldFinder.at(3), 'ace0');
    await tester.pumpAndSettle();
    await tester.tap(ipv6TextFormFieldFinder.at(4));
    await tester.pumpAndSettle();
    await tester.enterText(ipv6TextFormFieldFinder.at(4), 'ace0');
    await tester.pumpAndSettle();
    await tester.tap(ipv6TextFormFieldFinder.at(5));
    await tester.pumpAndSettle();
    await tester.enterText(ipv6TextFormFieldFinder.at(5), 'ace0');
    await tester.pumpAndSettle();
    await tester.tap(ipv6TextFormFieldFinder.at(6));
    await tester.pumpAndSettle();
    await tester.enterText(ipv6TextFormFieldFinder.at(6), 'ace0');
    await tester.pumpAndSettle();
    await tester.tap(ipv6TextFormFieldFinder.at(7));
    await tester.pumpAndSettle();
    await tester.enterText(ipv6TextFormFieldFinder.at(7), 'ace0');
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

  Future<void> checkSavedApplicationName() async {
    final textFieldFinder = find.text('Name1');
    expect(textFieldFinder, findsOneWidget);
  }
}
