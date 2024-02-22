
import 'package:equatable/equatable.dart';

class AppRootConfig extends Equatable {
  final String? spinnerTag;
  final bool force;
  final Map<int, String>? messages;
  final String? singleMessage;
  const AppRootConfig({
    this.spinnerTag,
    this.force = false,
    this.messages,
    this.singleMessage,
  });

  AppRootConfig copyWith({
    String? spinnerTag,
    bool? force,
    String? singleMessage,
    Map<int, String>? messages,
  }) {
    return AppRootConfig(
      spinnerTag: spinnerTag ?? this.spinnerTag,
      force: force ?? this.force,
      singleMessage: singleMessage ?? this.singleMessage,
      messages: messages ?? this.messages,
    );
  }

  @override
  List<Object?> get props => [
        spinnerTag,
        force,
        singleMessage,
        messages,
      ];
}
