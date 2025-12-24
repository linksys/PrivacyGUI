import 'package:flutter_riverpod/flutter_riverpod.dart';

// Isolate the access of target device Id from NodeDetailProvider and
// ExternalDeviceDetailProvider in order to prevent reading
// its own "state" in the build()
final deviceDetailIdProvider = StateProvider<String>((ref) {
  return '';
});
