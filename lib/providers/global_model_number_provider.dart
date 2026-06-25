import 'package:flutter_riverpod/flutter_riverpod.dart';

///
/// Suppose the model number with suffix is 'M60DU-EU'
/// {Model}{SP suffix}-{Region suffix}
///

final globalModelNumberProvider = StateProvider<String>((ref) {
  return '';
});
