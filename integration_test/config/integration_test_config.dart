class IntegrationTestConfig {
  static const String password =
      String.fromEnvironment('password', defaultValue: 'Linksys123!');
  static const String recoveryCode =
      String.fromEnvironment('recoveryCode', defaultValue: '00000');
  static const String newPassword =
      String.fromEnvironment('newAdminPassword', defaultValue: 'Linksys123!');
  static const String passwordHint =
      String.fromEnvironment('passwordHint', defaultValue: 'Password hint');
  static const String wifiBands =
      String.fromEnvironment('wifiBands', defaultValue: '2.4,5,guest');
  static const String newWifiName =
      String.fromEnvironment('newWifiName', defaultValue: 'Linksys00019');
  static const String newWifiPassword =
      String.fromEnvironment('newWifiPassword', defaultValue: '3rEzbu27c@');
  static const String newGuestWifiName =
      String.fromEnvironment('newGuestWifiName', defaultValue: 'Linksys00019-guest');
  static const String newGuestWifiPassword =
      String.fromEnvironment('newGuestWifiPassword', defaultValue: 'BeMyGuest!');
}
