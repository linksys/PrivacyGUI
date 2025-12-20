import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:ui_kit_library/ui_kit.dart';

/// A view responsible for the initial administrative setup and login process
/// of the Plug and Play (PnP) flow.
///
/// This widget handles checking the router's status (configured/unconfigured,
/// internet connection), prompting for admin password if necessary, and
/// navigating to the appropriate next step in the PnP wizard or troubleshooter.
///
/// **Test Scenarios (PnpFlowStatus):**
///
/// - **`adminInitializing`**:
///   - Displays a loading spinner and "Processing..." text.
///   - Elements: `AppSpinner`, `AppText` (`loc(context).processing`).
///
/// - **`adminCheckingInternet`**:
///   - Displays a loading spinner and "Checking Internet Connection..." text.
///   - Elements: `AppSpinner`, `AppText` (`loc(context).launchCheckInternet`).
///
/// - **`adminInternetConnected`**:
///   - Displays a globe icon and "Internet Connected" text.
///   - Elements: `LinksysIcons.globe`, `AppText` (`loc(context).launchInternetConnected`).
///
/// - **`adminError`**:
///   - Displays a generic error page with "An Error Occurred" text and a "Try Again" button.
///   - Elements: `AppText` (`loc(context).generalError`), `AppFilledButton` (`loc(context).tryAgain`).
///
/// - **`adminUnconfigured`**:
///   - Displays router image, model name, "Router Unconfigured" title, description, and a "Start Setup" button.
///   - Elements: `Image` (router), `AppText` (`deviceInfo.modelName`, `loc(context).pnpFactoryResetTitle`, `loc(context).factoryResetDesc`), `AppFilledButton` (`loc(context).textContinue`).
///
/// - **`adminAwaitingPassword`**:
///   - Displays router image, model name, "Welcome" title, description, password input field, "Where is it?" button, and "Login" button.
///   - Elements: `Image` (router), `AppText` (`deviceInfo.modelName`, `loc(context).welcome`, `loc(context).pnpRouterLoginDesc`), `AppPasswordField` (key: `admin_password_input_field`), `AppTextButton` (`loc(context).pnpRouterLoginWhereIsIt`), `AppFilledButton` (`loc(context).login`).
///
/// - **`adminLoggingIn`**:
///   - Similar to `adminAwaitingPassword`, but the "Login" button is disabled (processing state).
///   - Elements: Same as `adminAwaitingPassword`, `AppFilledButton` is disabled.
///
/// - **`adminLoginFailed`**:
///   - Similar to `adminAwaitingPassword`, but displays an "Incorrect Password" error message.
///   - Elements: Same as `adminAwaitingPassword`, plus `AppText` (`loc(context).incorrectPassword`).
///
/// - **Modal Dialog (`_showRouterPasswordModal`)**:
///   - Triggered by tapping "Where is it?" button.
///   - Displays an `AlertDialog` with "Router Password" title, location description, and a "Close" button.
///   - Elements: `AlertDialog`, `AppText` (`loc(context).routerPassword`, `loc(context).modalRouterPasswordLocation`), `AppTextButton` (`loc(context).close`).
class PnpAdminView extends ArgumentsBaseConsumerStatefulView {
  const PnpAdminView({super.key, super.args});

  @override
  ConsumerState<PnpAdminView> createState() => _PnpAdminViewState();
}

class _PnpAdminViewState extends ConsumerState<PnpAdminView> {
  /// Controller for the admin password input field.
  late final TextEditingController _textEditController;

  /// Stores the password passed as an argument, if any.
  String? _password;

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    // Extract password from widget arguments, typically from a deep link or initial setup.
    _password = widget.args['p'] as String?;

    // Start the PnP flow after the first frame is rendered.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pnpProvider.notifier).startPnpFlow(_password);
    });
  }

  @override
  void dispose() {
    _textEditController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Listen for state changes that trigger navigation or one-off events.
    ref.listen<PnpState>(pnpProvider, (previous, next) {
      final prevStatus = previous?.status;
      final nextStatus = next.status;

      if (prevStatus == nextStatus) return; // Only act on status changes

      // On successful internet connection or wizard initialization, navigate to the PnP configuration.
      if (nextStatus == PnpFlowStatus.adminInternetConnected ||
          nextStatus == PnpFlowStatus.wizardInitializing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.goNamed(RouteNamed.pnpConfig);
        });
      }

      // If no internet connection is detected, navigate to the internet troubleshooting screen.
      if (nextStatus == PnpFlowStatus.adminNeedsInternetTroubleshooting) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            var ssid = '';
            // If a password was attached, get the default WiFi name for display in troubleshooting.
            if (next.attachedPassword != null) {
              ssid = ref
                  .read(pnpProvider.notifier)
                  .getDefaultWiFiNameAndPassphrase()
                  .name;
            }
            context.goNamed(
              RouteNamed.pnpNoInternetConnection,
              extra: ssid.isEmpty ? null : {'ssid': ssid},
            );
          }
        });
      }

      // If the wizard initialization fails due to an interrupt, navigate to the specified route.
      if (nextStatus == PnpFlowStatus.wizardInitFailed &&
          next.error is ExceptionInterruptAndExit) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            final route = (next.error as ExceptionInterruptAndExit).route;
            context.goNamed(route);
          }
        });
      }
    });

    final pnpState = ref.watch(pnpProvider);

    // Render different UI based on the current PnP flow status.
    switch (pnpState.status) {
      case PnpFlowStatus.adminInitializing:
      case PnpFlowStatus.adminCheckingInternet:
        return _loadingView(pnpState.status);
      case PnpFlowStatus.adminInternetConnected:
        return _internetConnectedView();
      case PnpFlowStatus.adminError:
        return _errorPage(_errorView());
      case PnpFlowStatus.adminUnconfigured:
      case PnpFlowStatus.adminAwaitingPassword:
      case PnpFlowStatus.adminLoggingIn:
      case PnpFlowStatus.adminLoginFailed:
        return _mainView(pnpState);
      default:
        return _loadingView(pnpState.status);
    }
  }

  /// Displays a loading spinner with a message based on the current status.
  Widget _loadingView(PnpFlowStatus status) {
    String message = status == PnpFlowStatus.adminCheckingInternet
        ? loc(context).launchCheckInternet
        : loc(context).processing;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppLoader(),
          AppGap.lg(),
          AppText.titleMedium(message),
        ],
      ),
    );
  }

  /// Displays a confirmation view when the internet connection is established.
  Widget _internetConnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppIcon.font(
            AppFontIcons.globe,
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          AppGap.lg(),
          AppText.titleMedium(loc(context).launchInternetConnected),
        ],
      ),
    );
  }

  /// Wraps an error view in a styled page layout.
  Widget _errorPage(Widget child) {
    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      backState: UiKitBackState.none,
      padding: EdgeInsets.zero,
      enableSafeArea: (bottom: true, top: false, left: true, right: false),
      child: (context, constraints) => Center(
        child: AppSurface(
          child: Padding(
            padding: EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }

  /// Displays a generic error message with a "Try Again" button.
  Widget _errorView() {
    return Container(
      color: Theme.of(context).colorScheme.background,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AppText.headlineSmall(loc(context).generalError),
              AppGap.xxxl(),
              AppButton(
                label: loc(context).tryAgain,
                variant: SurfaceVariant.highlight,
                onTap: () {
                  context.goNamed(RouteNamed.home);
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  /// The main view for handling unconfigured routers or admin password input.
  Widget _mainView(PnpState pnpState) {
    final deviceInfo = pnpState.deviceInfo;
    return UiKitPageView(
      scrollable: true,
      appBarStyle: UiKitAppBarStyle.none,
      backState: UiKitBackState.none,
      enableSafeArea: (bottom: true, top: false, left: true, right: false),
      child: (context, constraints) => Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (deviceInfo != null)
                AppImage.provider(
                  imageProvider:
                      DeviceImageHelper.getRouterImage(deviceInfo.image),
                  height: 160,
                  width: 160,
                  fit: BoxFit.contain,
                ),
              // Animates the transition between unconfigured view and password view.
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                child: pnpState.status == PnpFlowStatus.adminUnconfigured
                    ? _unconfiguredView()
                    : _routerPasswordView(pnpState),
              )
            ],
          ),
        ),
      ),
    );
  }

  /// Displays a view for an unconfigured router, prompting the user to continue.
  Widget _unconfiguredView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.headlineSmall(loc(context).pnpFactoryResetTitle),
        AppGap.lg(),
        AppText.bodyLarge(loc(context).factoryResetDesc),
        AppGap.xxxl(),
        AppButton(
          label: loc(context).textContinue,
          variant: SurfaceVariant.highlight,
          onTap: () {
            ref.read(pnpProvider.notifier).continueFromUnconfigured();
          },
        ),
      ],
    );
  }

  /// Displays the admin password input form.
  Widget _routerPasswordView(PnpState pnpState) {
    final isProcessing = pnpState.status == PnpFlowStatus.adminLoggingIn;
    final hasError = pnpState.status == PnpFlowStatus.adminLoginFailed &&
        pnpState.error != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.headlineSmall(loc(context).welcome),
        AppGap.lg(),
        AppText.bodyLarge(loc(context).pnpRouterLoginDesc),
        AppGap.xxl(),
        AppPasswordInput(
          key: const Key('admin_password_input_field'),
          label: loc(context).routerPassword,
          controller: _textEditController,
          onSubmitted: (_) {
            if (!isProcessing) {
              ref
                  .read(pnpProvider.notifier)
                  .submitPassword(_textEditController.text);
            }
          },
        ),
        // Display error message if login failed.
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AppText.labelMedium(loc(context).incorrectPassword,
                color: Theme.of(context).colorScheme.error),
          ),
        AppGap.xxl(),
        AppButton.text(
          label: loc(context).pnpRouterLoginWhereIsIt,
          onTap: () {
            _showRouterPasswordModal();
          },
        ),
        AppGap.xxxl(),
        AppButton(
          label: loc(context).login,
          variant: SurfaceVariant.highlight,
          onTap: !isProcessing
              ? () {
                  ref
                      .read(pnpProvider.notifier)
                      .submitPassword(_textEditController.text);
                }
              : null,
        ),
      ],
    );
  }

  /// Shows a modal dialog explaining where to find the router password.
  _showRouterPasswordModal() {
    return showAppDialog(
        context: context,
        builder: (context) {
          return AppDialog(
            title: AppText.titleLarge(loc(context).routerPassword),
            actions: [
              AppButton.text(
                label: loc(context).close,
                onTap: () {
                  Navigator.of(context).pop();
                },
              )
            ],
            content: SizedBox(
              width: 312,
              child:
                  AppText.bodyMedium(loc(context).modalRouterPasswordLocation),
            ),
          );
        });
  }
}
