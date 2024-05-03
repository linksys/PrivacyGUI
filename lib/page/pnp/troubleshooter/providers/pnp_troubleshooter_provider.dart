import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pnpTroubleshooterProvider =
    NotifierProvider<PnpTroubleshooterNotifier, PnpTroubleshooterState>(
        () => PnpTroubleshooterNotifier());

class PnpTroubleshooterNotifier extends Notifier<PnpTroubleshooterState> {
  @override
  PnpTroubleshooterState build() => PnpTroubleshooterState.init();

  void resetModem(bool hasReset) {
    state = state.copyWith(
      hasResetModem: hasReset,
    );
  }
}

class PnpTroubleshooterState {
  final bool hasResetModem;

  PnpTroubleshooterState({
    required this.hasResetModem,
  });

  factory PnpTroubleshooterState.init() {
    return PnpTroubleshooterState(
      hasResetModem: false,
    );
  }

  PnpTroubleshooterState copyWith({
    bool? hasResetModem,
  }) {
    return PnpTroubleshooterState(
      hasResetModem: hasResetModem ?? this.hasResetModem,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'hasResetModem': hasResetModem,
    };
  }

  factory PnpTroubleshooterState.fromMap(Map<String, dynamic> map) {
    return PnpTroubleshooterState(
      hasResetModem: map['hasResetModem'] as bool,
    );
  }

  String toJson() => json.encode(toMap());

  factory PnpTroubleshooterState.fromJson(String source) =>
      PnpTroubleshooterState.fromMap(
        json.decode(source) as Map<String, dynamic>,
      );
}
