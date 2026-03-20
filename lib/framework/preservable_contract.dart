import 'package:equatable/equatable.dart';

// The Interface (The "What")
// This defines the contract that LinksysRoute and the Mixin will check for.
abstract class PreservableContract<TSettings extends Equatable,
    TStatus extends Equatable> {
  void revert();
  bool isDirty();

  // Methods to be implemented by the concrete notifier.
  Future<(TSettings?, TStatus?)> performFetch({
    bool forceRemote = false,
    bool updateStatusOnly = false,
  });
  Future<void> performSave();
}
