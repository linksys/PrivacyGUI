
import 'package:equatable/equatable.dart';

class FCNLevelObject extends Equatable {
  final String level;

  @override
  List<Object?> get props => [level];

  const FCNLevelObject({
    required this.level,
  });

  FCNLevelObject copyWith({
    String? level,
  }) {
    return FCNLevelObject(
      level: level ?? this.level,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'level': level,
    };
  }

  factory FCNLevelObject.fromJson(Map<String, dynamic> json) {
    return FCNLevelObject(
      level: json['level'],
    );
  }
}

class FCNIdObject extends Equatable {
  final String id;

  @override
  List<Object?> get props => [id];

  const FCNIdObject({
    required this.id,
  });

  FCNIdObject copyWith({
    String? id,
  }) {
    return FCNIdObject(
      id: id ?? this.id,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
    };
  }

  factory FCNIdObject.fromJson(Map<String, dynamic> json) {
    return FCNIdObject(
      id: json['id'],
    );
  }
}
class FCNNameObject extends Equatable {
  final String name;

  const FCNNameObject({
    required this.name,
  });

  FCNNameObject copyWith({
    String? name,
  }) {
    return FCNNameObject(
      name: name ?? this.name,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
    };
  }

  factory FCNNameObject.fromJson(Map<String, dynamic> json) {
    return FCNNameObject(
      name: json['name'],
    );
  }

  @override
  List<Object?> get props => [name];
}

class FCNFieldIdObject extends Equatable {
  final String fieldId;

  const FCNFieldIdObject({
    required this.fieldId,
  });

  FCNFieldIdObject copyWith({
    String? fieldId,
  }) {
    return FCNFieldIdObject(
      fieldId: fieldId ?? this.fieldId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fieldId': fieldId,
    };
  }

  factory FCNFieldIdObject.fromJson(Map<String, dynamic> json) {
    return FCNFieldIdObject(
      fieldId: json['fieldId'],
    );
  }

  @override
  List<Object?> get props => [fieldId];
}