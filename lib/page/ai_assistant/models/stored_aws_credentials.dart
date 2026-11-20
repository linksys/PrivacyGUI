/// Credentials loaded from storage.
class StoredAwsCredentials {
  const StoredAwsCredentials({
    required this.accessKeyId,
    required this.secretAccessKey,
    this.modelId,
  });

  final String accessKeyId;
  final String secretAccessKey;

  /// Model chosen when these credentials were saved, if any.
  final String? modelId;
}
