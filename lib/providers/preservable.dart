import 'package:equatable/equatable.dart';

/// A generic wrapper for data that needs dirty-checking.
/// `T` represents the settings data class.
class Preservable<T extends Equatable> extends Equatable {
  final T original;
  final T current;

  const Preservable({required this.original, required this.current});

  /// True if the current data is different from the original.
  bool get isDirty => original != current;

  /// Returns a new instance with an updated `current` value.
  Preservable<T> update(T newCurrent) => copyWith(current: newCurrent);

  /// Returns a new instance where `original` is updated to match `current`.
  /// This is called after a successful save operation.
  Preservable<T> saved() => copyWith(original: current);

  Preservable<T> copyWith({T? original, T? current}) {
    return Preservable<T>(
      original: original ?? this.original,
      current: current ?? this.current,
    );
  }

  @override
  List<Object?> get props => [original, current];
}
