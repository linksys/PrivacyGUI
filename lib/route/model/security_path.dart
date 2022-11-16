import 'package:flutter/widgets.dart';
import 'package:linksys_moab/route/_route.dart';


import '../../page/dashboard/view/security/_security.dart';
import '../../page/dashboard/view/security/security_content_filter_introduction_view.dart';
import '_model.dart';

class SecurityPath extends DashboardPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch(runtimeType) {
      case SecurityProtectionStatusPath:
        return const SecurityProtectionStatusView();
      case SecurityCyberThreatPath:
        return SecurityCyberThreatView(
          args: args,
        );
      case VulnerabilityIntroductionPath:
        return const VulnerabilityIntroductionView();
      case SecurityMarketingPath:
        return const SecurityMarketingView();
      case SecuritySubscribePath:
        return const SecuritySubscribeView();
      case SecurityContentFilterIntroductionPath:
        return SecurityContentFilterIntroductionView();
      default:
        return const Center();
    }
  }

}

class SecurityProtectionStatusPath extends SecurityPath {}

class SecurityCyberThreatPath extends SecurityPath {}

class VulnerabilityIntroductionPath extends SecurityPath {}

class SecurityMarketingPath extends SecurityPath {}

class SecuritySubscribePath extends SecurityPath {}

class SecurityContentFilterIntroductionPath extends SecurityPath {}

