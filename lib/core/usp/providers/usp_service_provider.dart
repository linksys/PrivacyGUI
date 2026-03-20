import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/di.dart';
import 'package:privacy_gui/core/usp/services/usp_service.dart';

/// Provides UspService instance via Riverpod.
///
/// Returns null on non-Web platforms since USP is only available
/// through the WASM transport layer.
final uspServiceProvider = Provider<UspService?>((ref) {
  if (!kIsWeb) return null;
  return getIt.isRegistered<UspService>() ? getIt<UspService>() : null;
});
