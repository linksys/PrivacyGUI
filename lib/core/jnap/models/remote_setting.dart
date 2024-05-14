// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'package:equatable/equatable.dart';

class RemoteSetting extends Equatable {
  final bool isEnabled;
  const RemoteSetting({
    required this.isEnabled,
  });

  RemoteSetting copyWith({
    bool? isEnabled,
  }) {
    return RemoteSetting(
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'isEnabled': isEnabled,
    }..removeWhere((key, value) => value == null);
  }

  factory RemoteSetting.fromJson(Map<String, dynamic> map) {
    return RemoteSetting(
      isEnabled: map['isEnabled'] as bool,
    );
  }

  @override
  List<Object?> get props => [isEnabled];
}
