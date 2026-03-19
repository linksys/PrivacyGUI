// Re-export the original PreservableContract.
//
// This interface is the bridge between feature notifiers and the route
// dirty-check system (LinksysRoute). Both sides must use the same type,
// so we re-export rather than copy.
export 'package:privacy_gui/providers/preservable_contract.dart';
