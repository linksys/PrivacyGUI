class IntegrationTestConfig {
  static const String password =
      String.fromEnvironment('password', defaultValue: 'Linksys123!');
  static const String recoveryCode =
      String.fromEnvironment('recoveryCode', defaultValue: '00000');
  static const String newPassword =
      String.fromEnvironment('newPassword', defaultValue: 'Linksys123!');
  static const String passwordHint =
      String.fromEnvironment('passwordHint', defaultValue: 'Password hint');
  static const String wifiBands =
      String.fromEnvironment('wifiBands', defaultValue: '2.4,5,guest');
}
