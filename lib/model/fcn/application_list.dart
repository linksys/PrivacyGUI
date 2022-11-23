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
  final String? comment;
  final List<FCNApplication> entries;

  @override
  List<Object?> get props => [name, comment, entries];

  const FCNApplicationList({
    required this.name,
    this.comment,
    required this.entries,
  });

  FCNApplicationList copyWith({
    String? name,
    String? comment,
    List<FCNApplication>? entries,
  }) {
    return FCNApplicationList(
      name: name ?? this.name,
      comment: comment ?? this.comment,
      entries: entries ?? this.entries,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'comment': comment,
      'entries': entries.map((e) => e.toJson()),
    };
  }

  factory FCNApplicationList.fromJson(Map<String, dynamic> json) {
    return FCNApplicationList(
      name: json['name'],
      comment: json['comment'],
      entries: List.from(json['entries'])
          .map((e) => FCNApplication.fromJson(e))
          .toList(),
    );
  }

  Map<String, dynamic> toFullJson() {
    return {
      "name": name,
      "comment": comment ?? "Monitor all applications.",
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
