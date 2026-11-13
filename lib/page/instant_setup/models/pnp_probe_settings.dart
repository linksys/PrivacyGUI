import 'package:equatable/equatable.dart';

/// **#1511 P6's probe — test-only, never shipped.** What a third setting step
/// edits: one switch. It exists to measure what adding a step before Save
/// touches, and is removed by the commit after the one that adds it.
class PnpProbeSettings extends Equatable {
  const PnpProbeSettings({required this.enabled});

  final bool enabled;

  @override
  List<Object?> get props => [enabled];
}
