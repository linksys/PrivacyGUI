import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:privacy_gui/page/ai_assistant/services/aws_credentials_store.dart';

/// The one [AwsCredentialsStore] for the session — a plain [Provider], not
/// `autoDispose`, because the store's ordering guarantee depends on a single
/// instance (see [AwsCredentialsStore]).
final awsCredentialsStoreProvider = Provider<AwsCredentialsStore>((ref) {
  return AwsCredentialsStore(const FlutterSecureStorage());
});
