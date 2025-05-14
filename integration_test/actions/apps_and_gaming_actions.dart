part of 'base_actions.dart';

class TestAppsAndGamingActions extends CommonBaseActions {
  TestAppsAndGamingActions(super.tester);

  Finder ddnsTabFinder() {
    final tabsFinder = find.byType(Tab);
    expect(tabsFinder, findsNWidgets(4));
    return tabsFinder.at(0);
  }

  Finder portForwardingTabFinder() {
    final tabsFinder = find.byType(Tab);
    expect(tabsFinder, findsNWidgets(4));
    return tabsFinder.at(1);
  }

  Finder rangeForwardingTabFinder() {
    final tabsFinder = find.byType(Tab);
    expect(tabsFinder, findsNWidgets(4));
    return tabsFinder.at(2);
  }

  Finder rangeTriggeringTabFinder() {
    final tabsFinder = find.byType(Tab);
    expect(tabsFinder, findsNWidgets(4));
    return tabsFinder.at(3);
  }

  Finder providerDropdownFinder() {
    final dropdownFinder = find.byType(AppDropdownButton<String>);
    expect(dropdownFinder, findsOneWidget);
    return dropdownFinder;
  }

  Finder usernametextFieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(4));
    return textfieldFinder.at(0);
  }

  Finder passwordtextFieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(4));
    return textfieldFinder.at(1);
  }

  Finder hostnametextFieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(4));
    return textfieldFinder.at(2);
  }

  Finder mailtextFieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(4));
    return textfieldFinder.at(3);
  }

  Finder systemDropdownFinder() {
    final dropdownFinder = find.byType(AppDropdownButton<DynDDNSSystem>);
    expect(dropdownFinder, findsOneWidget);
    return dropdownFinder.last;
  }

  Finder backupSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsNWidgets(2));
    return switchFinder.first;
  }

  Finder wildcardSwitchFinder() {
    final switchFinder = find.byType(AppSwitch);
    expect(switchFinder, findsNWidgets(2));
    return switchFinder.last;
  }

  Finder addNewButtonFinder() {
    final buttonFinder = find.byType(AppTextButton);
    expect(buttonFinder, findsOneWidget);
    return buttonFinder;
  }

  Finder forwardingAppNameFieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(3));
    return textfieldFinder.at(0);
  }

  Finder triggeringAppNameFieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(5));
    return textfieldFinder.at(0);
  }

  Finder internalPortTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(3));
    return textfieldFinder.at(1);
  }

  Finder externalPortTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(3));
    return textfieldFinder.at(2);
  }

  Finder protocolDropdownFinder() {
    final dropdownFinder = find.byType(AppDropdownButton<String>);
    expect(dropdownFinder, findsOneWidget);
    return dropdownFinder;
  }

  Finder lastDeviceIpFieldFinder() {
    final ipFormFieldFinder = find.byType(AppIPFormField);
    expect(ipFormFieldFinder, findsOneWidget);
    final lastField = find
        .descendant(
          of: ipFormFieldFinder,
          matching: find.byType(TextFormField),
        )
        .last;
    return lastField;
  }

  Finder startPortTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(3));
    return textfieldFinder.at(1);
  }

  Finder endPortTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(3));
    return textfieldFinder.at(2);
  }

  Finder startTriggeredRangeTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(5));
    return textfieldFinder.at(1);
  }

  Finder endTriggeredRangeTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(5));
    return textfieldFinder.at(2);
  }

  Finder startForwardedRangeTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(5));
    return textfieldFinder.at(3);
  }

  Finder endForwardedRangeTextfieldFinder() {
    final textfieldFinder = find.byType(AppTextField);
    expect(textfieldFinder, findsNWidgets(5));
    return textfieldFinder.at(4);
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

  Future<void> tapDdnsTab() async {
    // Find DDNS tab
    final tabFinder = ddnsTabFinder();
    // Tap the tab
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapPortForwardingTab() async {
    // Find single port forwarding tab
    final tabFinder = portForwardingTabFinder();
    // Tap the tab
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapRangeForwardingTab() async {
    // Find port range forwarding tab
    final tabFinder = rangeForwardingTabFinder();
    // Tap the tab
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapRangeTriggeringTab() async {
    // Find port range triggering tab
    final tabFinder = rangeTriggeringTabFinder();
    // Tap the tab
    await tester.tap(tabFinder);
    await tester.pumpAndSettle();
  }

  Future<void> selectDisableProvider() async {
    // Find dropdown
    final dropdownFinder = providerDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Disabled'), findsOneWidget);
    await tester.tap(find.text('Disabled'));
    await tester.pumpAndSettle();
  }

  Future<void> selectDynProvider() async {
    // Find dropdown
    final dropdownFinder = providerDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('dyn.com'), findsOneWidget);
    await tester.tap(find.text('dyn.com'));
    await tester.pumpAndSettle();
    // Check the system dropdown is available
    expect(find.byType(AppDropdownButton<DynDDNSSystem>), findsOneWidget);
  }

  Future<void> selectNoIpProvider() async {
    // Find dropdown
    final dropdownFinder = providerDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('No-IP.com'), findsOneWidget);
    await tester.tap(find.text('No-IP.com'));
    await tester.pumpAndSettle();
    // Check the system dropdown is NOT available
    expect(find.byType(AppDropdownButton<DynDDNSSystem>), findsNothing);
  }

  Future<void> inputUsername() async {
    final textfieldFinder = usernametextFieldFinder();
    await tester.enterText(textfieldFinder, 'MyName');
    await tester.pumpAndSettle();
  }

  Future<void> inputPassword() async {
    final textfieldFinder = passwordtextFieldFinder();
    await tester.enterText(textfieldFinder, 'Linksys123');
    await tester.pumpAndSettle();
  }

  Future<void> inputHostname() async {
    final textfieldFinder = hostnametextFieldFinder();
    await tester.enterText(textfieldFinder, 'Host');
    await tester.pumpAndSettle();
  }

  Future<void> inputMailExchange() async {
    final textfieldFinder = mailtextFieldFinder();
    await tester.enterText(textfieldFinder, '123');
    await tester.pumpAndSettle();
  }

  Future<void> selectDynamicSystem() async {
    // Find dropdown
    final dropdownFinder = systemDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Dynamic'), findsOneWidget);
    await tester.tap(find.text('Dynamic'));
    await tester.pumpAndSettle();
  }

  Future<void> selectStaticSystem() async {
    // Find dropdown
    final dropdownFinder = systemDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Static'), findsOneWidget);
    await tester.tap(find.text('Static'));
    await tester.pumpAndSettle();
  }

  Future<void> selectCustomSystem() async {
    // Find dropdown
    final dropdownFinder = systemDropdownFinder();
    // Tap the item
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    expect(find.text('Custom'), findsOneWidget);
    await tester.tap(find.text('Custom'));
    await tester.pumpAndSettle();
  }

  Future<void> toggleBackMxSwitch() async {
    // Find the Backup MX switch
    final switchFinder = backupSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> toggleWildcardSwitch() async {
    // Find the Wildcard switch
    final switchFinder = wildcardSwitchFinder();
    // Tap the switch
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();
  }

  Future<void> tapAddNewButton() async {
    // Find the add button
    final buttonFinder = addNewButtonFinder();
    // Tap the button
    await tester.tap(buttonFinder);
    await tester.pumpAndSettle();
  }

  Future<void> inputForwardingAppName() async {
    // Find the application name field
    final textfieldFinder = forwardingAppNameFieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, 'MyName');
    await tester.pumpAndSettle();
  }

  Future<void> inputTriggeringAppName() async {
    // Find the application name field
    final textfieldFinder = triggeringAppNameFieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, 'MyName');
    await tester.pumpAndSettle();
  }

  Future<void> inputInternalPort() async {
    // Find the internal port field
    final textfieldFinder = internalPortTextfieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, '11');
    await tester.pumpAndSettle();
  }

  Future<void> inputExternalPort() async {
    // Find the external port field
    final textfieldFinder = externalPortTextfieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, '22');
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
    expect(tcpText, findsOneWidget);
  }

  Future<void> selectUdpProtocol() async {
    final dropdownFinder = protocolDropdownFinder();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    final udpText = find.text('UDP');
    expect(udpText, findsAtLeastNWidgets(1));
    await tester.tap(udpText);
    await tester.pumpAndSettle();
    expect(udpText, findsOneWidget);
  }

  Future<void> selectBothProtocol() async {
    final dropdownFinder = protocolDropdownFinder();
    await tester.tap(dropdownFinder);
    await tester.pumpAndSettle();
    final bothText = find.text('UDP and TCP');
    expect(bothText, findsAtLeastNWidgets(1));
    await tester.tap(bothText.first);
    await tester.pumpAndSettle();
    expect(bothText, findsOneWidget);
  }

  Future<void> inputLastDeviceIp() async {
    final lastIpFieldFinder = lastDeviceIpFieldFinder();
    await tester.enterText(lastIpFieldFinder, '10');
    await tester.pumpAndSettle();
  }

  Future<void> inputStartPort() async {
    // Find the start port field
    final textfieldFinder = startPortTextfieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, '33');
    await tester.pumpAndSettle();
  }

  Future<void> inputEndPort() async {
    // Find the end port field
    final textfieldFinder = externalPortTextfieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, '44');
    await tester.pumpAndSettle();
  }

  Future<void> inputStartTriggeredRange() async {
    // Find the start triggered range
    final textfieldFinder = startTriggeredRangeTextfieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, '11');
    await tester.pumpAndSettle();
  }

  Future<void> inputEndTriggeredRange() async {
    // Find the end triggered range
    final textfieldFinder = endTriggeredRangeTextfieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, '22');
    await tester.pumpAndSettle();
  }

  Future<void> inputStartForwardedRange() async {
    // Find the start forwarded range
    final textfieldFinder = startForwardedRangeTextfieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, '33');
    await tester.pumpAndSettle();
  }

  Future<void> inputEndForwardedRange() async {
    // Find the end forwarded range
    final textfieldFinder = endForwardedRangeTextfieldFinder();
    // Input the text
    await tester.enterText(textfieldFinder, '44');
    await tester.pumpAndSettle();
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

  Future<void> checkSavedItems() async {
    expect(find.text('MyName'), findsOneWidget);
  }
}
