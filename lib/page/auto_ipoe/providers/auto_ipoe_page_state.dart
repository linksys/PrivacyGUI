import 'package:equatable/equatable.dart';
import 'package:privacy_gui/core/errors/service_error.dart';
import 'package:privacy_gui/framework/feature_state.dart';
import 'package:privacy_gui/framework/preservable.dart';
import '../models/auto_ipoe_models.dart';
import '../models/auto_ipoe_snapshot.dart';

class AutoIPoEPageStatus extends Equatable {
  const AutoIPoEPageStatus(
      {this.snapshot = const AutoIPoESnapshot(),
      this.loading = false,
      this.saving = false,
      this.error});
  final AutoIPoESnapshot snapshot;
  final bool loading;
  final bool saving;
  final ServiceError? error;
  @override
  List<Object?> get props => [snapshot, loading, saving, error];
}

class AutoIPoEPageState
    extends FeatureState<AutoIPoESettings, AutoIPoEPageStatus> {
  const AutoIPoEPageState({required super.settings, required super.status});
  factory AutoIPoEPageState.initial() => AutoIPoEPageState(
        settings: const Preservable(
            original: AutoIPoESettings.init(),
            current: AutoIPoESettings.init()),
        status: const AutoIPoEPageStatus(loading: true),
      );
  @override
  AutoIPoEPageState copyWith(
          {Preservable<AutoIPoESettings>? settings,
          AutoIPoEPageStatus? status}) =>
      AutoIPoEPageState(
          settings: settings ?? this.settings, status: status ?? this.status);
  @override
  Map<String, dynamic> toMap() => {}; // Never serialize entered ISP secrets.
}
