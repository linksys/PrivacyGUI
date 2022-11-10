import 'package:equatable/equatable.dart';

import 'application.dart';

///
/// {
///     "name": "default",
///     "comment": "Monitor all applications.",
///     "replacemsg-group": "",
///     "extended-log": "disable",
///     "other-application-action": "pass",
///     "app-replacemsg": "enable",
///     "other-application-log": "disable",
///     "enforce-default-app-port": "disable",
///     "force-inclusion-ssl-di-sigs": "disable",
///     "unknown-application-action": "pass",
///     "unknown-application-log": "disable",
///     "p2p-block-list": "",
///     "deep-app-inspection": "enable",
///     "options": "allow-dns",
///     "entries": [
///       ...
///     ],
///     "control-default-network-services": "disable",
///     "default-network-services": []
///  }
///
class FCNApplicationList extends Equatable {
  final String name;
  final List<FCNApplication> entries;

  @override
  List<Object?> get props => [name, entries];

  const FCNApplicationList({
    required this.name,
    required this.entries,
  });

  FCNApplicationList copyWith({
    String? name,
    List<FCNApplication>? entries,
  }) {
    return FCNApplicationList(
      name: name ?? this.name,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'entries': entries.map((e) => e.toJson()),
    };
  }

  factory FCNApplicationList.fromJson(Map<String, dynamic> json) {
    return FCNApplicationList(
      name: json['name'],
      entries: List.from(json['entries'])
          .map((e) => FCNApplication.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toFullJson() {
    return {
      "name": name,
      "comment": "Monitor all applications.",
      "replacemsg-group": "",
      "extended-log": "disable",
      "other-application-action": "pass",
      "app-replacemsg": "enable",
      "other-application-log": "disable",
      "enforce-default-app-port": "disable",
      "force-inclusion-ssl-di-sigs": "disable",
      "unknown-application-action": "pass",
      "unknown-application-log": "disable",
      "p2p-block-list": "",
      "deep-app-inspection": "enable",
      "options": "allow-dns",
      "entries": [
        ...entries.map((e) => e.toJson()),
      ],
      "control-default-network-services": "disable",
      "default-network-services": []
    };
  }
}
