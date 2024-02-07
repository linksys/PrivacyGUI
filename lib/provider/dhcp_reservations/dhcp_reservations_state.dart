// ignore_for_file: public_member_api_docs, sort_constructors_first


import 'package:equatable/equatable.dart';

import 'package:linksys_app/core/jnap/models/lan_settings.dart';
import 'package:linksys_app/provider/troubleshooting/dhcp_client.dart';

class DHCPReservationsState extends Equatable {
  final List<DHCPReservation> dhcpReservationList;
  final List<DhcpClientModel> dhcpClientList;

  @override
  List<Object> get props => [dhcpReservationList, dhcpClientList];

  const DHCPReservationsState({
    required this.dhcpReservationList,
    required this.dhcpClientList,
  });

  DHCPReservationsState copyWith({
    List<DHCPReservation>? dhcpReservationList,
    List<DhcpClientModel>? dhcpClientList,
  }) {
    return DHCPReservationsState(
      dhcpReservationList: dhcpReservationList ?? this.dhcpReservationList,
      dhcpClientList: dhcpClientList ?? this.dhcpClientList,
    );
  }

  @override
  bool get stringify => true;
}
