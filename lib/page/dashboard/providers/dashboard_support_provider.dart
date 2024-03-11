import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/cloud/linksys_cloud_repository.dart';
import 'package:linksys_app/core/cloud/model/create_ticket.dart';
import 'package:linksys_app/core/jnap/extensions/_extensions.dart';
import 'package:linksys_app/core/jnap/providers/device_manager_provider.dart';
import 'package:linksys_app/core/jnap/router_repository.dart';
import 'package:linksys_app/core/utils/devices.dart';
import 'package:linksys_app/page/dashboard/providers/dashboard_support_state.dart';
import 'package:linksys_app/page/troubleshooting/providers/troubleshooting_provider.dart';

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
    final router = ref
        .read(deviceManagerProvider)
        .deviceList
        .firstWhereOrNull((element) => element.isAuthority);
    final serialNumber = router?.unit.serialNumber ?? '';
    final modelNumber = router?.modelNumber ?? '';
    final macAddress = router?.getMacAddress() ?? '';
    String token = state.linksysToken;
    if (token.isEmpty) {
      token = await deviceRegistrations(
          serialNumber: serialNumber,
          modelNumber: modelNumber,
          macAddress: macAddress);
    }

    // Collect data
    final repo = ref.read(routerRepositoryProvider);
    final results = await repo.fetchCreateTicketDeviceInfo();
    Map<String, String> dataMap = {};
    results.forEach((element) {
      dataMap[element.key.actionValue] = element.value.result;
    });
    dataMap['serialNumber'] = serialNumber;
    dataMap['modelNumber'] = modelNumber;
    dataMap['macAddress'] = macAddress;

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
        data: dataMap.toString());
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
}
