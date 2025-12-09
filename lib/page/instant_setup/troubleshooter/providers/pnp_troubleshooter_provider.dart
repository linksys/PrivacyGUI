import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pnpTroubleshooterProvider =
    NotifierProvider<PnpTroubleshooterNotifier, PnpTroubleshooterState>(
        () => PnpTroubleshooterNotifier());

class PnpTroubleshooterNotifier extends Notifier<PnpTroubleshooterState> {
  @override
  PnpTroubleshooterState build() => PnpTroubleshooterState.init();

  void setEnterRoute(String route) {
    state = state.copyWith(enterRouteName: route);
  }
}

class PnpTroubleshooterState {
  final String enterRouteName;

  PnpTroubleshooterState({
    this.enterRouteName = '',
  });

  factory PnpTroubleshooterState.init() => PnpTroubleshooterState();

  PnpTroubleshooterState copyWith({String? enterRouteName}) {
    return PnpTroubleshooterState(
      enterRouteName: enterRouteName ?? this.enterRouteName,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{'enterRouteName': enterRouteName};
  }

  factory PnpTroubleshooterState.fromMap(Map<String, dynamic> map) {
    return PnpTroubleshooterState(
      enterRouteName: map['enterRouteName'] as String? ?? '',
    );
  }

  String toJson() => json.encode(toMap());

  factory PnpTroubleshooterState.fromJson(String source) =>
      PnpTroubleshooterState.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
