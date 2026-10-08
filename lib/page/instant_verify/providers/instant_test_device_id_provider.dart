import 'package:flutter_riverpod/flutter_riverpod.dart';

// The device a help flow opens with, as deviceDetailIdProvider does for
// Device details: set before pushing the help route. Holds the MAC address;
// the help page resolves it against the Instant-Test client list.
final instantTestDeviceIdProvider = StateProvider<String>((ref) {
  return '';
});
