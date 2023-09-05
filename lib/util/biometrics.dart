import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:linksys_app/constants/pref_key.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:local_auth/local_auth.dart';

const AuthenticationOptions _defaultOptions =
    AuthenticationOptions(biometricOnly: true);

enum CanAuthenticateResponse {
  success,
  errorHwUnavailable,
  errorNoBiometricEnrolled,
  errorNoHardware,
  unsupported,
}

class BiometricsHelp {
  static final BiometricsHelp _help = BiometricsHelp._();
  factory BiometricsHelp() => _help;
  BiometricsHelp._();

  Future<CanAuthenticateResponse> canAuthenticate() async {
    return canUseBiometrics();
  }

  Future<bool> _authenticate({required String localizedReason}) =>
      LocalAuthentication().authenticate(
        localizedReason: localizedReason,
        options: _defaultOptions,
      );

  Future<bool> _write({
    required String key,
    required String data,
    String reason = 'Authenticate to access data',
  }) {
    return _authenticate(localizedReason: reason).then((value) {
      if (value) {
        const FlutterSecureStorage().write(key: key, value: data);
      }
      return value;
    });
  }

  Future<String?> _read({
    required String key,
    String reason = 'Authenticate to access data',
  }) {
    return _authenticate(localizedReason: reason).then((value) {
      if (value) {
        return const FlutterSecureStorage().read(
          key: key,
        );
      }
      throw Exception(); // TODO
    });
  }

  Future<void> _delete({
    required String key,
    String reason = 'Authenticate to access data',
  }) {
    return _authenticate(localizedReason: reason).then((value) {
      if (value) {
        const FlutterSecureStorage().delete(
          key: key,
        );
      }
    });
  }

  Future<List<String>> getKeyList() async {
    final data = await const FlutterSecureStorage().read(key: pBiometrics);
    return data == null ? [] : data.split(',');
  }

  Future saveBiometrics(String username, String password) async {
    const storage = FlutterSecureStorage();
    final keys = await storage.read(key: pBiometrics);
    final keyList = keys == null ? <String>[] : keys.split(',');

    await _write(key: _getKey(username), data: password);
    await storage.write(
        key: pBiometrics, value: (keyList..add(username)).join(','));
  }

  Future<String> loadBiometrics(String username) async {
    return _read(key: _getKey(username)).then((value) => value ?? '');
  }

  Future deleteBiometrics(String username) async {
    const storage = FlutterSecureStorage();
    final keys = await storage.read(key: pBiometrics);
    if (keys == null) {
      return;
    }
    final keyList = keys.split(',');
    final key = _getKey(username);

    await _delete(key: key);
    keyList.remove(username);
    if (keyList.isEmpty) {
      await storage.delete(key: pBiometrics);
    } else {
      await storage.write(
          key: pBiometrics, value: (keyList..remove(username)).join(','));
    }
  }

  String _getKey(String username) {
    return '$pBiometrics-$username'.toMd5();
  }

  Future<CanAuthenticateResponse> canUseBiometrics() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool canAuthenticateWithBiometrics = await auth.canCheckBiometrics;
    final bool isDeviceSupported = await auth.isDeviceSupported();
    final List<BiometricType> availableList =
        await auth.getAvailableBiometrics();

    if (!isDeviceSupported) {
      return CanAuthenticateResponse.errorNoHardware;
    }
    if (!canAuthenticateWithBiometrics) {
      return CanAuthenticateResponse.errorHwUnavailable;
    }
    if (availableList.isEmpty) {
      return CanAuthenticateResponse.errorNoBiometricEnrolled;
    } else if (availableList.contains(BiometricType.strong) ||
        availableList.contains(BiometricType.face)) {
      return CanAuthenticateResponse.success;
    } else {
      return CanAuthenticateResponse.unsupported;
    }
  }

  Future<bool> doLocalAuthenticate() async {
    final LocalAuthentication auth = LocalAuthentication();
    final bool didAuthenticate = await auth.authenticate(
        localizedReason: "Please authenticate to go to next step");
    return didAuthenticate;
  }
}
