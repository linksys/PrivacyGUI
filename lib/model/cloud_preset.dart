import 'package:equatable/equatable.dart';

class MoabPreset extends Equatable {

  const MoabPreset(
      {required this.name, required this.identifier, required this.rules});

  factory MoabPreset.fromJson(Map<String, dynamic> json) {
    return MoabPreset(name: json['name'],
        identifier: json['identifier'],
        rules: List.from(List.from(json['rules']).map((e) => PresetRule.fromJson(e))));
  }

  final String name;
  final String identifier;
  final List<PresetRule> rules;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'identifier': identifier,
      'rules': rules.map((e) => e.toJson()),
    };
  }

  MoabPreset copyWith(String? name, String? identifier,
      List<PresetRule>? rules) {
    return MoabPreset(name: name ?? this.name,
        identifier: identifier ?? this.identifier,
        rules: rules ?? this.rules);
  }

  @override
  List<Object?> get props => [name, identifier, rules,];
}

class PresetRule extends Equatable {
  const PresetRule({
    required this.target,
    this.identifier = '',
    required this.expression,
  });

  factory PresetRule.fromJson(Map<String, dynamic> json) {
    return PresetRule(
      target: json['target'],
      identifier: json.containsKey('identifier') ? json['identifier'] : '',
      expression: PresetRuleExpression.fromJson(json['expression']),
    );
  }

  final String target;
  final String identifier;
  final PresetRuleExpression expression;

  Map<String, dynamic> toJson() {
    var result = {
      'target': target,
      'expression': expression.toJson(),
    };
    if (identifier.isNotEmpty) {
      result['identifier'] = identifier;
    }
    return result;
  }

  PresetRule copyWith(String? target,
      PresetRuleExpression? expression) {
    return PresetRule(target: target ?? this.target,
      expression: expression ?? this.expression,);
  }

  @override
  List<Object?> get props => [target, expression];
}

class PresetRuleExpression extends Equatable {

  const PresetRuleExpression(
      {required this.field, required this.value,});

  factory PresetRuleExpression.fromJson(Map<String, dynamic> json) {
    return PresetRuleExpression(
      field: json['field'], value: json['value'],);
  }

  final String field;
  final String value;

  Map<String, dynamic> toJson() {
    return {
      'field': field,
      'value': value,
    };
  }

  PresetRuleExpression copyWith(String? field, String? value) {
    return PresetRuleExpression(
      field: field ?? this.field, value: value ?? this.value,);
  }

  @override
  List<Object?> get props => [field, value];

}
