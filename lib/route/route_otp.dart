part of 'router_provider.dart';

final otpRoutes = [
  LinksysRoute(
    name: RouteNamed.otpStart,
    path: RoutePath.otpStart,
    builder: (context, state) => OtpFlowView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
  LinksysRoute(
    name: RouteNamed.otpSelectMethods,
    path: RoutePath.otpSelectMethods,
    builder: (context, state) => OTPMethodSelectorView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
  LinksysRoute(
    name: RouteNamed.otpInputCode,
    path: RoutePath.otpInputCode,
    builder: (context, state) => OtpCodeInputView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
  LinksysRoute(
    name: RouteNamed.otpAddPhone,
    path: RoutePath.otpAddPhone,
    builder: (context, state) => OtpAddPhoneView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  )
];
