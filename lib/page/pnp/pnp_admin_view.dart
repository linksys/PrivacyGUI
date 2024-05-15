import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/icon_rules.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/pnp/data/pnp_exception.dart';
import 'package:privacy_gui/page/pnp/data/pnp_provider.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/validator_rules/rules.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/hook/icon_hooks.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';

class PnpAdminView extends ArgumentsBaseConsumerStatefulView {
  const PnpAdminView({super.key, super.args});

  @override
  ConsumerState<PnpAdminView> createState() => _PnpAdminViewState();
}

class _PnpAdminViewState extends ConsumerState<PnpAdminView> {
  late final TextEditingController _textEditController;
  final InputValidator _validator = InputValidator([
    RequiredRule(),
  ]);

  bool _internetChecked = false;
  bool _internetConnected = false;
  bool _isFactoryReset = false;
  bool _processing = false;
  String? _inputError;
  Object? _error;
  String? _password;

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();

    final pnp = ref.read(pnpProvider.notifier);
    // check path include local password
    _password = widget.args['p'] as String?;
    if (_password != null) {
      // keep the admin password anyway if it exists
      pnp.setAttachedPassword(_password!);
    }
    // verify admin password is valid
    pnp
        .fetchDeviceInfo()
        .then((_) => pnp.checkInternetConnection())
        .then((_) {
          setState(() {
            _internetConnected = true;
          });
        })
        .then((_) => pnp.checkRouterConfigured())
        .then((_) => adminPasswordFlow(_password))
        .catchError((error, stackTrace) {},
            test: (error) => error is ExceptionInvalidAdminPassword)
        .catchError((error, stackTrace) {
          logger.e(
              '[PNP Troubleshooter]: Internet connection failed - initiate troubleshooter ${(_password != null) ? 'with' : 'without'} credential');
          if (_password != null) {
            pnp.fetchData().then((value) {
              final ssid = pnp.getDefaultWiFiNameAndPassphrase().name;
              context.goNamed(
                RouteNamed.pnpNoInternetConnection,
                extra: {'ssid': ssid},
              );
            }).onError((error, stackTrace) {
              logger.e(
                  '[PNP Troubleshooter]: fetch data failed (Getting SSID): $error');
              context.goNamed(RouteNamed.pnpNoInternetConnection);
            });
          } else {
            context.goNamed(RouteNamed.pnpNoInternetConnection);
          }
        }, test: (error) => error is ExceptionNoInternetConnection)
        .catchError((error, stackTrace) {
          setState(() {
            _internetChecked = true;
            _isFactoryReset = true;
            _inputError = '';
          });
        }, test: (error) => error is ExceptionRouterUnconfigured)
        .onError((error, stackTrace) {
          logger.e('[pnp] Uncaught Error',
              error: error, stackTrace: stackTrace);
          context.goNamed(RouteNamed.pnpNoInternetConnection);
        });
  }

  @override
  void dispose() {
    super.dispose();

    _textEditController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _internetChecked ? _mainView() : _checkInternetView();
  }

  Widget _checkInternetView() {
    return _internetConnected
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LinksysIcons.globe,
                  color: Theme.of(context).colorScheme.primary,
                  size: 48,
                ),
                const AppGap.regular(),
                AppText.titleMedium(loc(context).launchInternetConnected),
              ],
            ),
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppSpinner(),
                const AppGap.regular(),
                AppText.titleMedium(loc(context).launchCheckInternet),
              ],
            ),
          );
  }

  Widget _factoryResetView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.headlineSmall(loc(context).pnpFactoryResetTitle),
        const AppGap.regular(),
        AppText.bodyLarge(loc(context).pnpFactoryResetDesc),
        const AppGap.extraBig(),
        AppFilledButton(
          loc(context).textContinue,
          onTap: () {
            adminPasswordFlow(_password).then((_) {
              context.goNamed(RouteNamed.pnpConfig);
            });
          },
        ),
      ],
    );
  }

  Widget _routerPasswordView() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.headlineSmall(loc(context).welcome),
        const AppGap.regular(),
        AppText.bodyLarge(loc(context).pnpRouterLoginDesc),
        const AppGap.big(),
        AppPasswordField(
          hintText: loc(context).routerPassword,
          border: const OutlineInputBorder(),
          controller: _textEditController,
          errorText: _inputError?.isEmpty ?? true ? null : _inputError,
          onFocusChanged: (focused) {
            if (focused) {
              setState(() {
                _inputError = null;
                _error = null;
              });
            }
          },
          onChanged: (value) {
            setState(() {
              _inputError = value.isEmpty
                  ? ''
                  : _validator.validate(value)
                      ? null
                      : 'Password should not be empty';
            });
          },
        ),
        ..._checkError(context, _error),
        const AppGap.big(),
        AppTextButton.noPadding(
          loc(context).pnpRouterLoginWhereIsIt,
          onTap: () {
            _showRouterPasswordModal();
          },
        ),
        const AppGap.extraBig(),
        AppFilledButton(
          loc(context).login,
          onTap: _inputError == null && !_processing
              ? () {
                  setState(() {
                    _processing = true;
                  });
                  adminPasswordFlow(_textEditController.text)
                  .then((_) {
                    context.goNamed(RouteNamed.pnpConfig);
                  })
                      .onError((error, stackTrace) {
                    setState(() {
                      _error = error;
                    });
                  }).whenComplete(() {
                    setState(() {
                      _processing = false;
                    });
                  });
                }
              : null,
        ),
      ],
    );
  }

  Widget _mainView() {
    final deviceInfo =
        ref.watch(pnpProvider.select((value) => value.deviceInfo));
    return StyledAppPageView(
      scrollable: true,
      appBarStyle: AppBarStyle.none,
      backState: StyledBackState.none,
      enableSafeArea: (bottom: true, top: false, left: true, right: false),
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image(
                image: CustomTheme.of(context).images.devices.getByName(
                    routerIconTestByModel(
                        modelNumber: deviceInfo?.modelNumber ?? 'LN11')),
                height: 160,
                width: 160,
                fit: BoxFit.fitWidth,
              ),
              AnimatedContainer(
                duration: const Duration(seconds: 1),
                child: _isFactoryReset
                    ? _factoryResetView()
                    : _routerPasswordView(),
              )
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _checkError(BuildContext context, Object? error) {
    if (error == null) {
      return [];
    }
    if (error is ExceptionInvalidAdminPassword) {
      return [
        AppText.labelMedium(loc(context).incorrectPassword,
            color: Theme.of(context).colorScheme.error)
      ];
    }
    return [
      AppText.labelMedium('Unknown error',
          color: Theme.of(context).colorScheme.error)
    ];
  }

  Future adminPasswordFlow(String? password) => ref
          .read(pnpProvider.notifier)
          .checkAdminPassword(password)
          .catchError((error, stackTrace) {
        setState(() {
          _internetChecked = true;
          _isFactoryReset = false;
          _inputError = '';
          _password = null;
        });
        throw error;
      }, test: (error) => error is ExceptionInvalidAdminPassword);

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
