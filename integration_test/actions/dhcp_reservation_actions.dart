part of 'base_actions.dart';

class TestDHCPReservationActions extends CommonBaseActions {
  TestDHCPReservationActions(super.tester);

  Finder dhcpReservationEnteranceFinder() {
    final finder = find.text(loc(getContext()).dhcpReservations);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder addReservationButtonFinder() {
    final finder = find.byKey(Key('addReservationButton'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder macAddressFieldFinder() {
    final finder = find.byKey(Key('macAddressTextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder ipAddressFieldFinder() {
    final finder = find.byKey(Key('ipAddressTextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder deviceNameFieldFinder() {
    final finder = find.byKey(Key('deviceNameTextField'));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder saveButtonFinder() {
    final finder = find.byType(AppFilledButton);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder alertDialogFinder() {
    final finder = find.byType(AlertDialog);
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder alertSaveBtnFinder() {
    final context = getContext();
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(loc(context).save),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder alertUpdateBtnFinder() {
    final context = getContext();
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(loc(context).update),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder alertCancelBtnFinder() {
    final context = getContext();
    final finder = find.descendant(
      of: alertDialogFinder(),
      matching: find.text(loc(context).cancel),
    );
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder reservationCardFinder(String deviceName) {
    final finder = find.ancestor(
        of: find.text(deviceName), matching: find.byType(AppListCard));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder editButtonFinder(String deviceName) {
    final finder = find.descendant(
        of: reservationCardFinder(deviceName),
        matching: find.byIcon(LinksysIcons.edit));
    expect(finder, findsOneWidget);
    return finder;
  }

  Finder macAddressError() => find.text(loc(getContext()).invalidMACAddress);
  Finder ipAddressError() =>
      find.text(loc(getContext()).invalidIpOrSameAsHostIp);
  Finder deviceNameInList(String name) => find.text(name);
  Finder ipAndMacAddressInList(String ip, String mac) =>
      find.text("IP: $ip\nMAC: $mac");

  Future<void> tapDHCPReservationEnterance() async {
    final finder = dhcpReservationEnteranceFinder();
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapAddReservationButton() async {
    await tester.tap(addReservationButtonFinder());
    await tester.pumpAndSettle();
  }

  Future<void> inputMacAddress(String mac) async {
    await tester.enterText(macAddressFieldFinder(), mac);
    await tester.pumpAndSettle();
  }

  Future<void> inputIPAddress(String ip) async {
    final field = ipAddressFieldFinder();
    final ipFields =
        find.descendant(of: field, matching: find.byType(TextFormField));
    final parts = ip.split('.');
    await tester.enterText(ipFields.last, parts.last);
    await tester.pumpAndSettle();
  }

  Future<void> inputDeviceName(String name) async {
    await tester.enterText(deviceNameFieldFinder(), name);
    await tester.pumpAndSettle();
  }

  Future<void> tapSaveButton() async {
    await tester.tap(saveButtonFinder());
    await tester.pumpAndSettle();
  }

  Future<void> tapAlertSaveButton() async {
    await tester.tap(alertSaveBtnFinder());
    await tester.pumpAndSettle();
  }

  Future<void> tapAlertUpdateButton() async {
    await tester.tap(alertUpdateBtnFinder());
    await tester.pumpAndSettle();
  }

  Future<void> tapAlertCancelButton() async {
    await tester.tap(alertCancelBtnFinder());
    await tester.pumpAndSettle();
  }

  Future<void> tapReservation(String deviceName) async {
    final finder = reservationCardFinder(deviceName);
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  Future<void> tapEditReservation(String deviceName) async {
    final finder = editButtonFinder(deviceName);
    await scrollUntil(finder);
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  // Validation
  Future<void> verifyMacAddressError() async {
    expect(macAddressError(), findsOneWidget);
  }

  Future<void> verifyIPAddressError() async {
    expect(ipAddressError(), findsOneWidget);
  }

  Future<void> verifyNoReservation() async {
    final finder = find.text(loc(getContext()).nReservedAddresses(0));
    expect(finder, findsOneWidget);
  }

  Future<void> verifyHasOneReservation() async {
    final finder = find.text(loc(getContext()).nReservedAddresses(1));
    expect(finder, findsOneWidget);
  }

  // List verification
  Future<void> verifyReservationInList(
      String deviceName, String ip, String mac) async {
    expect(deviceNameInList(deviceName), findsOneWidget);
    expect(ipAndMacAddressInList(ip, mac), findsOneWidget);
  }

  Future<void> verifyReservationNotInList(String deviceName) async {
    expect(deviceNameInList(deviceName), findsNothing);
  }
}
