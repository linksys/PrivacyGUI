part of 'router_provider.dart';

final otpRoutes = [
  GoRoute(
    name: RouteNamed.otpStart,
    path: RoutePath.otpStart,
    builder: (context, state) => OtpFlowView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
  GoRoute(
    name: RouteNamed.otpSelectMethods,
    path: RoutePath.otpSelectMethods,
    builder: (context, state) => OTPMethodSelectorView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
  GoRoute(
    name: RouteNamed.otpInputCode,
    path: RoutePath.otpInputCode,
    builder: (context, state) => OtpCodeInputView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  ),
  GoRoute(
    name: RouteNamed.otpAddPhone,
    path: RoutePath.otpAddPhone,
    builder: (context, state) => OtpAddPhoneView(
      args: state.extra as Map<String, dynamic>? ?? {},
    ),
  )
];
