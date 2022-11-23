import 'package:equatable/equatable.dart';

import 'objects.dart';

///
/// {
///     "name": "Timmy",
///     "type": "default",
///     "category": "default",
///     "member": [
///       {
///         "name": "ASTWP-028031"
///       }
///     ],
///     "comment": "string",
///     "exclude": "disable",
///     "exclude-member": []
/// }
///
class FCNAddressGroup extends Equatable {
  final String name;
  final String type;
  final String category;
  final List<FCNNameObject> member;
  final String comment;
  final String exclude;
  final List<FCNNameObject> excludeMember;

  const FCNAddressGroup({
    required this.name,
    this.type = "default",
    this.category = "default",
    required this.member,
    this.comment = "",
    this.exclude = "disable",
    this.excludeMember = const [],
  });

  FCNAddressGroup copyWith({
    String? name,
    String? type,
    String? category,
    List<FCNNameObject>? member,
    String? comment,
    String? exclude,
    List<FCNNameObject>? excludeMember,
  }) {
    return FCNAddressGroup(
      name: name ?? this.name,
      type: type ?? this.type,
      category: category ?? this.category,
      member: member ?? this.member,
      comment: comment ?? this.comment,
      exclude: exclude ?? this.exclude,
      excludeMember: excludeMember ?? this.excludeMember,
    );
  }

  @override
  List<Object?> get props => [
        name,
        type,
        category,
        member,
        comment,
        exclude,
        excludeMember,
      ];

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'category': category,
      'member': member.map((e) => e.toJson()).toList(),
      'comment': comment,
      'exclude': exclude,
      'exclude-member': excludeMember.map((e) => e.toJson()).toList(),
    };
  }

  factory FCNAddressGroup.fromJson(Map<String, dynamic> json) {
    return FCNAddressGroup(
      name: json['name'],
      type: json['type'],
      category: json['category'],
      member: List.from(json['member'])
          .map((e) => FCNNameObject.fromJson(e))
          .toList(),
      comment: json['comment'],
      exclude: json['exclude'],
      excludeMember: List.from(json['exclude-member'])
          .map((e) => FCNNameObject.fromJson(e))
          .toList(),
    );
  }
}


