
void Function(String)? onSmartDeviceVerification;
void pushNotificationHandler(Map<String, dynamic> data) {
  // Smart device token
  if (data.containsKey('verificationToken')) {
    final token = data['verificationToken'];
    onSmartDeviceVerification?.call(token);
    
  
  } else {}
}
