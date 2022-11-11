import 'package:equatable/equatable.dart';
import 'package:linksys_moab/model/web_filter.dart';

///
///         {
///           "id": "1",
///           "category": "2",
///           "action": "block",
///           "warn-duration": "5m",
///           "auth-usr-grp": [],
///           "log": "enable",
///           "override-replacemsg": "",
///           "warning-prompt": "per-category",
///           "warning-duration-type": "timeout"
///         },
///
class FCNWebFilter extends Equatable {
  final String id;
  final String category;
  final String action;
  final String warnDuration;
  final List<String> authUsrGrp;
  final String log;
  final String overrideReplaceMsg;
  final String warningPrompt;
  final String warningDurationType;

  @override
  List<Object?> get props => throw UnimplementedError();
  const FCNWebFilter({
    required this.id,
    required this.category,
    required this.action,
    this.warnDuration = '5m',
    this.authUsrGrp = const [],
    this.log = 'enable',
    this.overrideReplaceMsg = '',
    this.warningPrompt = 'per-category',
    this.warningDurationType = 'timeout',
  });

  FCNWebFilter copyWith({
    String? id,
    String? category,
    String? action,
    String? warnDuration,
    List<String>? authUsrGrp,
    String? log,
    String? overrideReplaceMsg,
    String? warningPrompt,
    String? warningDurationType,
  }) {
    return FCNWebFilter(
      id: id ?? this.id,
      category: category ?? this.category,
      action: action ?? this.action,
      warnDuration: warnDuration ?? this.warnDuration,
      authUsrGrp: authUsrGrp ?? this.authUsrGrp,
      log: log ?? this.log,
      overrideReplaceMsg: overrideReplaceMsg ?? this.overrideReplaceMsg,
      warningPrompt: warningPrompt ?? this.warningPrompt,
      warningDurationType: warningDurationType ?? this.warningDurationType,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'category': category,
      'action': action,
      'warn-duration': warnDuration,
      'auth-usr-grp': authUsrGrp,
      'log': log,
      'override-replacemsg': overrideReplaceMsg,
      'warning-prompt': warningPrompt,
      'warning-duration-type': warningDurationType,
    };
  }

  factory FCNWebFilter.fromJson(Map<String, dynamic> json) {
    return FCNWebFilter(
      id: json['id'],
      category: json['category'],
      action: json['action'],
      warnDuration: json['warn-duration'],
      authUsrGrp: List.from(json['auth-usr-grp']),
      log: json['log'],
      overrideReplaceMsg: json['override-replacemsg'],
      warningPrompt: json['warning-prompt'],
      warningDurationType: json['warning-duration-type'],
    );
  }

  factory FCNWebFilter.fromData(WebFilter cfWebFilter) {
    // Action should be always block. we only put block to fcn
    return FCNWebFilter(id: cfWebFilter.id, category: cfWebFilter.groupId, action: 'block');
  }
}