part of 'base_actions.dart';

class TestLocalNetworkSettingsActions extends CommonBaseActions {
  TestLocalNetworkSettingsActions(super.tester);

  // Tabs

  Finder hostNameTabFinder() {
    final finder = find.text(loc(getContext()).hostName).first;
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder lanIPAddressTabFinder() {
    final finder = find.text(loc(getContext()).lanIPAddress);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder dhcpServerTabFinder() {
    final finder = find.text(loc(getContext()).dhcpServer).first;
    expect(finder, findsOneWidget);
    return finder;
  }

  Future<void> tapHostNameTab() async {
    await tester.tap(hostNameTabFinder());
    await tester.pumpAndSettle();
  }

  Future<void> tapLanIPAddressTab() async {
    await tester.tap(lanIPAddressTabFinder());
    await tester.pumpAndSettle();
  }

  Future<void> tapDHCPServerTab() async {
    await tester.tap(dhcpServerTabFinder());
    await tester.pumpAndSettle();
  }

  // Host name

  Finder hostNameTextFieldFinder() {
    final finder = find.byKey(Key('hostNameTextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Future<void> inputHostName(String hostName) async {
    await tester.enterText(hostNameTextFieldFinder(), hostName);
    await tester.pumpAndSettle();
  }

  Future<void> verifyHostName(String expectedHostName) async {
    expect(
        tester.widget<AppTextField>(hostNameTextFieldFinder()).controller?.text,
        expectedHostName);
  }

  Future<void> verifyInvalidHostName() async {
    final finder = find.text(loc(getContext()).invalidHostname);
    expect(finder, findsOneWidget);
  }

  Future<void> verifyEmptyHostName() async {
    final finder = find.text(loc(getContext()).hostNameCannotEmpty);
    expect(finder, findsOneWidget);
  }

  // Lan IP Address

  Finder ipAddressFieldFinder() {
    final finder = find.byKey(Key('lanIpAddressTextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder subnetMaskFieldFinder() {
    final finder = find.byKey(Key('lanSubnetMaskTextField'));
    return finder;
  }

  Future<void> inputIPAddress(String ipAddress) async {
    final finder = find.descendant(
        of: ipAddressFieldFinder(), matching: find.byType(TextFormField));
    expect(finder, findsNWidgets(4));
    int i = 0;
    for (String ip in ipAddress.split('.')) {
      await tester.enterText(finder.at(i), ip);
      await tester.pumpAndSettle();
      i++;
    }
    await tester.pumpAndSettle();
  }

  Future<void> verifyIPAddress(String expectedIPAddress) async {
    expect(
        tester.widget<AppIPFormField>(ipAddressFieldFinder()).controller?.text,
        expectedIPAddress);
  }

  Future<void> inputSubnetMask(String subnetMask) async {
    final finder = find.descendant(
        of: subnetMaskFieldFinder(), matching: find.byType(TextFormField));
    expect(finder, findsNWidgets(2));
    final ip = subnetMask.split('.');
    await tester.enterText(finder.at(0), ip[2]);
    await tester.pumpAndSettle();
    await tester.enterText(finder.at(1), ip[3]);
    await tester.pumpAndSettle();
  }

  Future<void> verifySubnetMask(String expectedSubnetMask) async {
    expect(
        tester.widget<AppIPFormField>(subnetMaskFieldFinder()).controller?.text,
        expectedSubnetMask);
  }

  Future<void> verifyIpAddressInvalid() async {
    final finder = find.text(loc(getContext()).invalidIpAddress);
    expect(finder, findsOneWidget);
  }

  Future<void> verifySubnetMaskInvalid() async {
    final finder = find.text(loc(getContext()).invalidSubnetMask);
    expect(finder, findsOneWidget);
  }

  Future<void> dhcpRangeErrorFinder() async {
    final finder = find.text(loc(getContext()).invalidIPAddressSubnet);
    expect(finder, findsOneWidget);
  }

  // DHCP Server

  Finder dhcpServerSwitchFinder() {
    final finder = find.byType(AppSwitch).first;
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder startIPAddressFieldFinder() {
    final finder = find.byKey(Key('startIpAddressTextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder maxUsersFieldFinder() {
    final finder = find.byKey(Key('maxUsersTextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder clientLeaseTimeFieldFinder() {
    final finder = find.byKey(Key('clientLeaseTimeTextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder dns1FieldFinder() {
    final finder = find.byKey(Key('dns1TextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder dns2FieldFinder() {
    final finder = find.byKey(Key('dns2TextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder dns3FieldFinder() {
    final finder = find.byKey(Key('dns3TextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder winsFieldFinder() {
    final finder = find.byKey(Key('winsTextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Future<void> toggleDHCPServer(bool enable) async {
    final switchWidget = tester.widget<AppSwitch>(dhcpServerSwitchFinder());
    if (switchWidget.value != enable) {
      await tester.tap(dhcpServerSwitchFinder());
      await tester.pumpAndSettle();
    }
  }

  Future<void> verifyDHCPServerEnable() async {
    startIPAddressFieldFinder();
  }

  Future<void> verifyDHCPServerDisable() async {
    final finder = find.byKey(Key('startIpAddressTextField'));
    expect(finder, findsNothing);
  }

  Future<void> inputStartIPAddress(String ipAddress) async {
    await scrollUntil(startIPAddressFieldFinder());
    final finder = find.descendant(
        of: startIPAddressFieldFinder(), matching: find.byType(TextFormField));
    expect(finder, findsNWidgets(2));
    final ip = ipAddress.split('.');
    await tester.enterText(finder.at(0), ip[2]);
    await tester.pumpAndSettle();
    await tester.enterText(finder.at(1), ip[3]);
    await tester.pumpAndSettle();
  }

  Future<void> verifyStartIPAddress(String expectedIPAddress) async {
    expect(
        tester
            .widget<AppIPFormField>(startIPAddressFieldFinder())
            .controller
            ?.text,
        expectedIPAddress);
  }

  Future<void> verifyStartIPAddressInvalid() async {
    final finder = find.text(loc(getContext()).invalidIpOrSameAsHostIp);
    expect(finder, findsOneWidget);
  }

  Future<void> verifyStartIPAddressNotInValidRange() async {
    expect(tester.widget<AppIPFormField>(startIPAddressFieldFinder()).errorText,
        isNotNull);
  }

  Future<void> inputMaxUsers(String maxUsers) async {
    final finder = maxUsersFieldFinder();
    await scrollUntil(finder);
    await tester.enterText(finder, maxUsers);
    await tester.pumpAndSettle();
  }

  Future<void> verifyMaxUsers(String expectedMaxUsers) async {
    expect(tester.widget<AppTextField>(maxUsersFieldFinder()).controller?.text,
        expectedMaxUsers);
  }

  Future<void> inputClientLeaseTime(String leaseTime) async {
    final finder = clientLeaseTimeFieldFinder();
    await scrollUntil(finder);
    await tester.enterText(finder, leaseTime);
    await tester.pumpAndSettle();
  }

  Future<void> verifyClientLeaseTime(String expectedLeaseTime) async {
    expect(
        tester
            .widget<AppTextField>(clientLeaseTimeFieldFinder())
            .controller
            ?.text,
        expectedLeaseTime);
  }

  Future<void> inputDNS1(String dns) async {
    await scrollUntil(dns1FieldFinder());
    final finder = find.descendant(
        of: dns1FieldFinder(), matching: find.byType(TextFormField));
    expect(finder, findsNWidgets(4));
    int i = 0;
    for (String ip in dns.split('.')) {
      await tester.enterText(finder.at(i), ip);
      await tester.pumpAndSettle();
      i++;
    }
    await tester.pumpAndSettle();
  }

  Future<void> verifyDNS1(String expectedDNS) async {
    expect(tester.widget<AppIPFormField>(dns1FieldFinder()).controller?.text,
        expectedDNS);
  }

  Future<void> inputDNS2(String dns) async {
    await scrollUntil(dns2FieldFinder());
    final finder = find.descendant(
        of: dns2FieldFinder(), matching: find.byType(TextFormField));
    expect(finder, findsNWidgets(4));
    int i = 0;
    for (String ip in dns.split('.')) {
      await tester.enterText(finder.at(i), ip);
      await tester.pumpAndSettle();
      i++;
    }
    await tester.pumpAndSettle();
  }

  Future<void> verifyDNS2(String expectedDNS) async {
    expect(tester.widget<AppIPFormField>(dns2FieldFinder()).controller?.text,
        expectedDNS);
  }

  Future<void> inputDNS3(String dns) async {
    await scrollUntil(dns3FieldFinder());
    final finder = find.descendant(
        of: dns3FieldFinder(), matching: find.byType(TextFormField));
    expect(finder, findsNWidgets(4));
    int i = 0;
    for (String ip in dns.split('.')) {
      await tester.enterText(finder.at(i), ip);
      await tester.pumpAndSettle();
      i++;
    }
    await tester.pumpAndSettle();
  }

  Future<void> verifyDNS3(String expectedDNS) async {
    expect(tester.widget<AppIPFormField>(dns3FieldFinder()).controller?.text,
        expectedDNS);
  }

  Future<void> inputWINS(String wins) async {
    await scrollUntil(winsFieldFinder());
    final finder = find.descendant(
        of: winsFieldFinder(), matching: find.byType(TextFormField));
    expect(finder, findsNWidgets(4));
    int i = 0;
    for (String ip in wins.split('.')) {
      await tester.enterText(finder.at(i), ip);
      await tester.pumpAndSettle();
      i++;
    }
    await tester.pumpAndSettle();
  }

  Future<void> verifyWINS(String expectedWINS) async {
    expect(tester.widget<AppIPFormField>(winsFieldFinder()).controller?.text,
        expectedWINS);
  }

  Future<void> verifyDnsAndWinsInvalid() async {
    final finder = find.text(loc(getContext()).invalidIpAddress);
    expect(finder, findsNWidgets(4));
  }

  // Common

  Finder saveButtonFinder() {
    final finder = find.byType(AppFilledButton);
    expect(finder, findsOneWidget);
    return finder;
  }

  Future<void> tapSaveButton() async {
    await tester.tap(saveButtonFinder());
    await tester.pumpAndSettle();
  }
}
