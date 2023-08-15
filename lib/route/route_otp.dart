part of 'router_provider.dart';

final otpRoutes = [
  GoRoute(
    name: RouteNamed.otpStart,
    path: RoutePath.otpStart,
    builder: (context, state) => OtpFlowView(
      args: state.uri.queryParameters,
    ),
  ),
  GoRoute(
    name: RouteNamed.otpSelectMethods,
    path: RoutePath.otpSelectMethods,
    builder: (context, state) => OTPMethodSelectorView(
      args: state.uri.queryParameters,
    ),
  ),
  GoRoute(
    name: RouteNamed.otpInputCode,
    path: RoutePath.otpInputCode,
    builder: (context, state) => OtpCodeInputView(
      args: state.uri.queryParameters,
    ),
  ),
];
