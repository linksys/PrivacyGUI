import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/cloud/model/create_ticket.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/page/dashboard/providers/dashboard_support_state.dart';
import 'package:linksys_app/page/troubleshooting/providers/troubleshooting_provider.dart';
import '../../../util/export_selector/export_base.dart'
    if (dart.library.io) '../../../util/export_selector/export_mobile.dart'
    if (dart.library.html) '../../../util/export_selector/export_web.dart';

final supportProvider =
    NotifierProvider<SupportNotifier, SupportState>(() => SupportNotifier());

class SupportNotifier extends Notifier<SupportState> {
  @override
  SupportState build() => SupportState.init();

  Future startCreateTicket(
      {required String email,
      required String firstName,
      required String lastName,
      required String phoneRegionCode,
      required String phoneNumber,
      required String subject}) async {
    // Device registrations
    final routerIdentityInfo = getDeviceIdentityInfo();
    final serialNumber = routerIdentityInfo['serialNumber'] ?? '';
    final modelNumber = routerIdentityInfo['modelNumber'] ?? '';
    final macAddress = routerIdentityInfo['macAddress'] ?? '';
    String token = await deviceRegistrations(
        serialNumber: serialNumber,
        modelNumber: modelNumber,
        macAddress: macAddress);

    // Collect data
    final dataMap = await fetchDeviceInfo();

    // Cloud api tickets to get ticketId
    final ticketId = await createTicket(
      createTicketInput: CreateTicketInput(
          emailAddress: email,
          firstName: firstName,
          lastName: lastName,
          phoneRegionCode: phoneRegionCode,
          phoneNumber: phoneNumber,
          description: subject),
      linksysToken: token,
      serialNumber: serialNumber,
    );

    // Uplodad collected data and do jnap SendSysinfoEmail with ticketId
    await upload(
        ticketId: ticketId,
        linksysToken: token,
        serialNumber: serialNumber,
        data: jsonEncode(dataMap));
  }

  Map<String, String> getDeviceIdentityInfo() {
    final router = ref
        .read(deviceManagerProvider)
        .deviceList
        .firstWhereOrNull((element) => element.isAuthority);
    return {
      'serialNumber': router?.unit.serialNumber ?? '',
      'modelNumber': router?.modelNumber ?? '',
      'macAddress': router?.getMacAddress() ?? '',
    };
  }

  Future<String> deviceRegistrations(
      {required String serialNumber,
      required String modelNumber,
      required String macAddress}) async {
    final cloudRepository = ref.read(cloudRepositoryProvider);
    final token = await cloudRepository.deviceRegistrations(
        serialNumber: serialNumber,
        modelNumber: modelNumber,
        macAddress: macAddress);

    state = state.copyWith(linksysToken: token);
    return token;
  }

  Future<Map<String, dynamic>> fetchDeviceInfo() async {
    final repo = ref.read(routerRepositoryProvider);
    final results = await repo.fetchCreateTicketDeviceInfo();
    Map<String, dynamic> dataMap = {};
    results.forEach((element) {
      dataMap[element.key.actionValue] = (element.value as JNAPSuccess).output;
    });
    final routerIdentityInfo = getDeviceIdentityInfo();
    dataMap['serialNumber'] = routerIdentityInfo['serialNumber'] ?? '';
    dataMap['modelNumber'] = routerIdentityInfo['modelNumber'] ?? '';
    dataMap['macAddress'] = routerIdentityInfo['macAddress'] ?? '';
    return dataMap;
  }

  Future<String> createTicket(
      {required CreateTicketInput createTicketInput,
      required String linksysToken,
      required String serialNumber}) async {
    final cloudRepository = ref.read(cloudRepositoryProvider);

    final ticketId = await cloudRepository.createTicket(
      createTicketInput: createTicketInput,
      linksysToken: linksysToken,
      serialNumber: serialNumber,
    );

    return ticketId;
  }

  Future upload(
      {required String ticketId,
      required String linksysToken,
      required String serialNumber,
      required String data}) async {
    // Send router sysInfo to ticket email
    ref
        .read(troubleshootingProvider.notifier)
        .sendRouterInfo(userEmailList: '$ticketId@tickets.linksys.com');

    // Upload router info data to the ticket
    final cloudRepository = ref.read(cloudRepositoryProvider);
    cloudRepository.uploadToTicket(
      ticketId: ticketId,
      linksysToken: linksysToken,
      serialNumber: serialNumber,
      data: data,
    );
  }

  Future download(BuildContext context) async {
    final dataMap = await fetchDeviceInfo();
    await exportFile(content: jsonEncode(dataMap), fileName: 'device-jnap');
  }
}
