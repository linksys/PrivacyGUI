/// Represents specific errors that can occur during a speed test.
enum SpeedTestError {
  /// Error related to the speed test configuration.
  configuration,

  /// Error related to the speed test license.
  license,

  /// General execution error during the speed test.
  execution,

  /// The speed test was aborted by the user.
  aborted,

  /// Error related to the database.
  dbError,

  /// The operation timed out.
  timeout,

  /// An unknown or unspecified error occurred.
  unknown,

  /// The result ID from the speed test was empty.
  emptyResultId,
}

/// Represents the overall status of the health check process.
enum HealthCheckStatus {
  /// The health check is not currently running.
  idle,

  /// The health check is in progress.
  running,

  /// The health check has finished.
  complete
}

/// Represents the specific stage of the health check process.
enum HealthCheckStep {
  /// Measuring the latency (ping).
  latency,

  /// Measuring the download bandwidth.
  downloadBandwidth,

  /// Measuring the upload bandwidth.
  uploadBandwidth,

  /// The process finished with an error.
  error,

  /// The process finished successfully.
  success
}
