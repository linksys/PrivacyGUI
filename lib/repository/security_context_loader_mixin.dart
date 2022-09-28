import 'dart:io';

import 'package:linksys_moab/constants/_constants.dart';
import 'package:linksys_moab/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

mixin SCLoader {
  Future<SecurityContext> get() async {

    if (!await Utils.checkCertValidation()) {
      throw InvalidCertException();
    }
    final pref = await SharedPreferences.getInstance();
    final publicKey = pref.getString(moabPrefCloudPublicKey)?.codeUnits;
    final privateKey = pref.getString(moabPrefCloudPrivateKey)?.codeUnits;

    SecurityContext securityContext = SecurityContext(withTrustedRoots: true);
    securityContext.useCertificateChainBytes(publicKey!);
    securityContext.usePrivateKeyBytes(privateKey!);
    return securityContext;
  }
}

class InvalidCertException extends Error {}
