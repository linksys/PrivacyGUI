const btErrorServicesNotFound = 'services_not_found';
const btErrorJNAPServiceNotFound = 'jnap_service_not_found';
const btErrorInvalidJNAPCommand = 'invalid_jnap_command';
const btErrorNoConnectedDevice = 'no_connected_device';
const btErrorNoCharacteristicFound = 'no_characteristic_found';
const btErrorNoResponse = 'no_response';

class BTError implements Exception{

  final String code;
  final String message;

  const BTError({
    required this.code,
    required this.message,
  });
}

class BTNoServicesFoundError extends BTError {
  BTNoServicesFoundError(String deviceId): super(code: btErrorServicesNotFound,
      message: 'BT connected device<$deviceId> no services found');
}


class BTJNAPServiceNotFoundError extends BTError {
  BTJNAPServiceNotFoundError(String deviceId): super(code: btErrorJNAPServiceNotFound,
      message: 'BT connected device<$deviceId> no jnap service found');
}

class BTInvalidJNAPCommandError extends BTError {
  BTInvalidJNAPCommandError(): super(code: btErrorInvalidJNAPCommand,
      message: 'BT invalid jnap command');
}

class BTNoConnectedDeviceError extends BTError {
  BTNoConnectedDeviceError(): super(code: btErrorNoConnectedDevice,
      message: 'BT No device connected');
}

class BTNoCharacteristicFoundError extends BTError {
  BTNoCharacteristicFoundError(): super(code: btErrorNoCharacteristicFound,
      message: 'BT No characteristic found');
}

class BTNoResponseError extends BTError {
  BTNoResponseError(): super(code: btErrorNoResponse, message: 'BT No response');
}