import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';

import '../../../test_data/device_info_test_data.dart';

void main() {
  test('better action - test sorting', () {
    final services =
        List.from(jsonDecode(testDeviceInfo)['output']['services']);
    final List<JNAPService> supportedServices = services
        .where((routerService) => JNAPService.appSupportedServices
            .any((supportedService) => routerService == supportedService.value))
        .map((service) => JNAPService.appSupportedServices.firstWhere(
            (supportedService) => supportedService.value == service))
        .toList();
    final serviceMap = groupAndSortJNAPServices(supportedServices);

    final setupServiceList = List<JNAPService>.from(serviceMap['setup'] ?? []);
    final routerServiceList =
        List<JNAPService>.from(serviceMap['router'] ?? []);

    final indexOfSetup = setupServiceList.indexOf(JNAPService.setup);
    final indexOfSetup5 = setupServiceList.indexOf(JNAPService.setup5);
    final indexOfSetup11 = setupServiceList.indexOf(JNAPService.setup11);
    expect(true, indexOfSetup11 > indexOfSetup);
    expect(true, indexOfSetup11 > indexOfSetup5);
    expect(true, indexOfSetup5 > indexOfSetup);

    final indexOfRouter = routerServiceList.indexOf(JNAPService.router);
    final indexOfRouter8 = routerServiceList.indexOf(JNAPService.router8);
    final indexOfRouter10 = routerServiceList.indexOf(JNAPService.router10);
    expect(true, indexOfRouter10 > indexOfRouter);
    expect(true, indexOfRouter10 > indexOfRouter8);
    expect(true, indexOfRouter8 > indexOfRouter);
  });

  test('test update better actions', () {
    initBetterActions();
    final services =
        List<String>.from(jsonDecode(testDeviceInfo)['output']['services']);
    buildBetterActions(services);
    expect('http://linksys.com/jnap/router/GetWANSettings5', JNAPAction.getWANSettings.actionValue);
  });
}
