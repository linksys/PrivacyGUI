// ignore_for_file: public_member_api_docs, sort_constructors_first
class JNAPRetryOptions {
  const JNAPRetryOptions({
    this.retries = 1,
    this.retryDelays = const [Duration(seconds: 3)],
  });

  final int retries;
  final List<Duration> retryDelays;

  bool exceedMaxRetry(int current) {
    return current >= retries;
  }

  Duration getRetryDelay(int current) =>
      current >= retryDelays.length ? retryDelays.last : retryDelays[current];

  JNAPRetryOptions copyWith({
    int? retries,
    List<Duration>? retryDelays,
  }) {
    return JNAPRetryOptions(
      retries: retries ?? this.retries,
      retryDelays: retryDelays ?? this.retryDelays,
    );
  }
}
