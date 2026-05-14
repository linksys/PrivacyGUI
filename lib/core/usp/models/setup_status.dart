class SetupStatus {
  final bool userAcknowledgedAutoConfiguration;

  const SetupStatus({required this.userAcknowledgedAutoConfiguration});

  factory SetupStatus.fromJson(Map<String, dynamic> json) {
    return SetupStatus(
      userAcknowledgedAutoConfiguration:
          json['user_acknowledged_auto_configuration'] as bool? ?? false,
    );
  }

  bool get needsPnp => !userAcknowledgedAutoConfiguration;
}
