import 'package:flutter_riverpod/flutter_riverpod.dart';

// Isolate the device detail target Id from DeviceDetailProvider in order to
// prevent reading its own "state" in the build()
final deviceDetailIdProvider = StateProvider<String>((ref) {
  return '';
});