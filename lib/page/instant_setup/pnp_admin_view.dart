import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_provider.dart';
import 'package:privacy_gui/page/instant_setup/providers/pnp_state.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

class PnpAdminView extends ArgumentsBaseConsumerStatefulView {
  const PnpAdminView({super.key, super.args});

  @override
  ConsumerState<PnpAdminView> createState() => _PnpAdminViewState();
}

class _PnpAdminViewState extends ConsumerState<PnpAdminView> {
  late final TextEditingController _textEditController;
  String? _password;

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();
    _password = widget.args['p'] as String?;

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

      // On success, navigate to the wizard
      if (nextStatus == PnpFlowStatus.adminInternetConnected ||
          nextStatus == PnpFlowStatus.wizardInitializing) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) context.goNamed(RouteNamed.pnpConfig);
        });
      }

      // On no internet, navigate to troubleshooter
      if (nextStatus == PnpFlowStatus.adminNeedsInternetTroubleshooting) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            var ssid = '';
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

      // On interrupt, navigate to the specified route
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

  Widget _loadingView(PnpFlowStatus status) {
    String message = status == PnpFlowStatus.adminCheckingInternet
        ? loc(context).launchCheckInternet
        : loc(context).processing;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const AppSpinner(),
          const AppGap.medium(),
          AppText.titleMedium(message),
        ],
      ),
    );
  }

  Widget _internetConnectedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LinksysIcons.globe,
            semanticLabel: 'globe',
            color: Theme.of(context).colorScheme.primary,
            size: 48,
          ),
          const AppGap.medium(),
          AppText.titleMedium(loc(context).launchInternetConnected),
        ],
      ),
    );
  }

  Widget _errorPage(Widget child) {
    return StyledAppPageView(
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      padding: EdgeInsets.zero,
      enableSafeArea: (bottom: true, top: false, left: true, right: false),
      child: (context, constraints) => AppBasicLayout(
        content: Center(
          child: AppCard(
            showBorder: false,
            color: Theme.of(context).colorScheme.background,
            padding: EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );
  }

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
              const AppGap.large5(),
              AppFilledButton(
                loc(context).tryAgain,
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

  Widget _mainView(PnpState pnpState) {
    final deviceInfo = pnpState.deviceInfo;
    return StyledAppPageView(
      scrollable: true,
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
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
                Image(
                  image: CustomTheme.of(context).getRouterImage(
                      deviceInfo.imageUrl),
                  height: 160,
                  width: 160,
                  fit: BoxFit.contain,
                ),
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

  Widget _unconfiguredView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.headlineSmall(loc(context).pnpFactoryResetTitle),
        const AppGap.medium(),
        AppText.bodyLarge(loc(context).factoryResetDesc),
        const AppGap.large5(),
        AppFilledButton(
          loc(context).textContinue,
          onTap: () {
            ref.read(pnpProvider.notifier).continueFromUnconfigured();
          },
        ),
      ],
    );
  }

  Widget _routerPasswordView(PnpState pnpState) {
    final isProcessing = pnpState.status == PnpFlowStatus.adminLoggingIn;
    final hasError =
        pnpState.status == PnpFlowStatus.adminLoginFailed && pnpState.error != null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.headlineSmall(loc(context).welcome),
        const AppGap.medium(),
        AppText.bodyLarge(loc(context).pnpRouterLoginDesc),
        const AppGap.large3(),
        AppPasswordField(
          hintText: loc(context).routerPassword,
          border: const OutlineInputBorder(),
          controller: _textEditController,
          onSubmitted: (_) {
            if (!isProcessing) {
              ref
                  .read(pnpProvider.notifier)
                  .submitPassword(_textEditController.text);
            }
          },
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: AppText.labelMedium(loc(context).incorrectPassword,
                color: Theme.of(context).colorScheme.error),
          ),
        const AppGap.large3(),
        AppTextButton.noPadding(
          loc(context).pnpRouterLoginWhereIsIt,
          onTap: () {
            _showRouterPasswordModal();
          },
        ),
        const AppGap.large5(),
        AppFilledButton(
          loc(context).login,
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

  _showRouterPasswordModal() {
    return showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: AppText.titleLarge(loc(context).routerPassword),
            actions: [
              AppTextButton(
                loc(context).close,
                onTap: () {
                  context.pop();
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