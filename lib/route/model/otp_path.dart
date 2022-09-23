import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/otp_flow/view/_view.dart';
import 'package:linksys_moab/route/_route.dart';


import 'base_path.dart';

abstract class OtpPath extends BasePath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case OtpPreparePath:
        return OtpFlowView(
          args: args,
          next: next,
        );
      case OtpMethodChoosesPath:
        return OTPMethodSelectorView(
          args: args,
          next: next,
        );
      case OtpInputCodePath:
        return OtpCodeInputView(
          args: args,
          next: next,
        );
      case OtpAddPhonePath:
        return OtpAddPhoneView(
          args: args,
          next: next,
        );
      default:
        return const Center();
    }
  }
}

class OtpPreparePath extends OtpPath {
  @override
  PathConfig get pathConfig => super.pathConfig..removeFromHistory = true;
}

class OtpMethodChoosesPath extends OtpPath {}

class OtpInputCodePath extends OtpPath {}

class OtpAddPhonePath extends OtpPath {}
