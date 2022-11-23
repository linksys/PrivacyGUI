import 'package:equatable/equatable.dart';

///
/// {
///     "id": "1",
///     "name": "Drug Abuse",
///     "group": "Potentially Liable",
///     "rating": "R",
///     "desc": "Websites that feature information on illegal drug activities including: drug promotion, preparation, cultivation, trafficking, distribution, solicitation, etc.",
///     "example": "magic-mushrooms.net,erowid.org,mushmagic.de",
///     "active": true,
///     "group_id": "1",
///     "blocked_in_ratings": [
///       "G",
///       "PG-13"
///     ]
///   }
///
class WebFilter extends Equatable {
  const WebFilter({
    required this.id,
    required this.name,
    required this.group,
    required this.rating,
    required this.desc,
    required this.example,
    required this.groupId,
    required this.blockedInRatings,
  });

  factory WebFilter.fromJson(Map<String, dynamic> json) {
    return WebFilter(
      id: json['id'],
      name: json['name'],
      group: json['group'],
      rating: json['rating'],
      desc: json['desc'],
      example: json['example'],
      groupId: json['groupId'] ?? '',
      blockedInRatings: json['blockedInRatings'] == null
          ? []
          : List.from(json['blockedInRatings']),
    );
  }

  final String id;
  final String name;
  final String group;
  final String rating;
  final String desc;
  final String example;
  final String groupId;
  final List<String> blockedInRatings;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'group': group,
      'rating': rating,
      'desc': desc,
      'example': example,
      'groupId': groupId,
      'blockedInRatings': blockedInRatings,
    };
  }

  WebFilter copyWith(
      String? id,
      String? name,
      String? group,
      String? rating,
      String? desc,
      String? example,
      String? groupId,
      List<String>? blockedInRatings) {
    return WebFilter(
      id: id ?? this.id,
      name: name ?? this.name,
      group: group ?? this.group,
      rating: rating ?? this.rating,
      desc: desc ?? this.desc,
      example: example ?? this.example,
      groupId: groupId ?? this.groupId,
      blockedInRatings: blockedInRatings ?? this.blockedInRatings,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, group, rating, desc, example, groupId, blockedInRatings];
}
