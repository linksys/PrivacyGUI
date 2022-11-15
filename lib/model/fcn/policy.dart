import 'package:equatable/equatable.dart';

import 'objects.dart';

///
///   {
///     "policyid": "30",
///     "status": "enable",
///     "utm-status": "enable",
///     "name": "main",
///     "comments": "",
///     "srcintf": [
///       {
///         "name": "any"
///       }
///     ],
///     "dstintf": [
///       {
///         "name": "eth0"
///       }
///     ],
///     "srcaddr": [
///       {
///         "name": "all"
///       }
///     ],
///     "dstaddr": [
///       {
///         "name": "all"
///       }
///     ],
///     "srcaddr6": [],
///     "dstaddr6": [],
///     "service": [],
///     "ssl-ssh-profile": "certificate-inspection",
///     "profile-type": "single",
///     "profile-group": "",
///     "profile-protocol-options": "default",
///     "av-profile": "default",
///     "webfilter-profile": "default",
///     "dnsfilter-profile": "",
///     "emailfilter-profile": "",
///     "dlp-sensor": "",
///     "file-filter-profile": "",
///     "ips-sensor": "",
///     "application-list": "",
///     "action": "accept",
///     "nat": "disable",
///     "custom-log-fields": [],
///     "logtraffic": "utm"
///   }
///
class FCNPolicy extends Equatable {
  final String policyid;
  final String status;
  final String name;
  final String addressGroup;
  final String webFilterProfile;
  final String applicationList;
  final List<String> devices;

  const FCNPolicy({
    required this.policyid,
    required this.status,
    required this.name,
    required this.addressGroup,
    required this.webFilterProfile,
    required this.applicationList,
    required this.devices,
  });

  FCNPolicy copyWith({
    String? policyid,
    String? status,
    String? name,
    String? addressGroup,
    String? webFilterProfile,
    String? applicationList,
    List<String>? devices,
  }) {
    return FCNPolicy(
      policyid: policyid ?? this.policyid,
      status: status ?? this.status,
      name: name ?? this.name,
      addressGroup: addressGroup ?? this.addressGroup,
      webFilterProfile: webFilterProfile ?? this.webFilterProfile,
      applicationList: applicationList ?? this.applicationList,
      devices: devices ?? this.devices,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'policyid': policyid,
      'status': status,
      'name': name,
      'addressGroup': addressGroup,
      'webFilterProfile': webFilterProfile,
      'applicationList': applicationList,
      'devices': devices,
    };
  }

  factory FCNPolicy.fromJson(Map<String, dynamic> json) {
    return FCNPolicy(
      policyid: json['policyid'],
      status: json['status'],
      name: json['name'],
      addressGroup: json['addressGroup'],
      webFilterProfile: json['webFilterProfile'],
      applicationList: json['applicationList'],
      devices: List.from(json['devices']),
    );
  }

  Map<String, dynamic> toFullJson() {
    return {
      "policyid": policyid,
      "status": status,
      "utm-status": "enable",
      "name": name,
      "comments": "",
      "srcintf": [
        {"name": "any"}
      ],
      "dstintf": [
        {"name": "eth4"}
      ],
      "srcaddr": [
        {"name": addressGroup}
      ],
      "dstaddr": [
        {"name": "all"}
      ],
      "srcaddr6": [],
      "dstaddr6": [],
      "service": [],
      "ssl-ssh-profile": "certificate-inspection",
      "profile-type": "single",
      "profile-group": "",
      "profile-protocol-options": "default",
      "av-profile": "default",
      "webfilter-profile": webFilterProfile,
      "dnsfilter-profile": "",
      "emailfilter-profile": "",
      "dlp-sensor": "",
      "file-filter-profile": "",
      "ips-sensor": "",
      "application-list": applicationList,
      "action": "accept",
      "nat": "disable",
      "custom-log-fields": [
        const FCNFieldIdObject(fieldId: 'gid').toJson(),
        const FCNFieldIdObject(fieldId: 'nid').toJson(),
        ...devices.map(
          (e) => FCNFieldIdObject(fieldId: e).toJson(),
        ),
      ],
      "logtraffic": "utm"
    };
  }

  @override
  List<Object?> get props => [
        policyid,
        status,
        name,
        addressGroup,
        webFilterProfile,
        applicationList,
        devices,
      ];
}
