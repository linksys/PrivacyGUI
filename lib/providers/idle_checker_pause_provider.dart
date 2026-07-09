import 'package:flutter_riverpod/flutter_riverpod.dart';

final idleCheckerPauseProvider = StateProvider<bool>((ref) {
  return false;
});
