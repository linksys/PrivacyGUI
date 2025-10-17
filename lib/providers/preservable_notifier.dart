import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:equatable/equatable.dart';
import 'feature_state.dart';
import 'preservable.dart';

// The Interface (The "What")
// This defines the contract that LinksysRoute will check for.
abstract class PreservableContract {
  void revert();
  bool isDirty();
}

// The Mixin (The "How")
// This provides the reusable implementation for any Notifier.
mixin PreservableNotifierMixin<
    TSettings extends Equatable,
    TStatus extends Equatable,
    TState extends FeatureState<TSettings, TStatus>> on Notifier<TState> implements PreservableContract {
  @override
  void revert() {
    state = state.copyWith(
      settings: state.settings.copyWith(current: state.settings.original),
    ) as TState;
  }

  @override
  bool isDirty() => state.isDirty;

  void markAsSaved() {
    state = state.copyWith(settings: state.settings.saved()) as TState;
  }
}