import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/pnp/data/pnp_error.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/validator_rules/rules.dart';
import 'package:linksys_app/validator_rules/input_validators.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/card/card.dart';
import 'package:linksys_widgets/widgets/progress_bar/spinner.dart';

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
  bool _processing = false;
  String? _inputError;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _textEditController = TextEditingController();

    final pnp = ref.read(pnpProvider.notifier);
    // check path include local password
    final password = widget.args['password'] as String?;

    // verify admin password is valid
    pnp
        .fetchDeviceInfo()
        .then((_) => pnp.checkInternetConnection())
        .then((value) {
          setState(() {
            _internetConnected = true;
          });
        })
        .then((_) => pnp.checkAdminPassword(password))
        .then((_) {
          context.goNamed(RouteNamed.pnpConfig);
        })
        .catchError((error, stackTrace) {
          context.goNamed(RouteNamed.pnpNoInternetConnection);
        }, test: (error) => error is ErrorCheckInternetConnection)
        .catchError((error, stackTrace) {
          setState(() {
            _internetChecked = true;
            _inputError = '';
          });
        }, test: (error) => error is ErrorInvalidAdminPassword);
  }

  @override
  void dispose() {
    super.dispose();

    _textEditController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _internetChecked ? _adminPasswordView() : _checkInternetView();
  }

  Widget _checkInternetView() {
    return _internetConnected
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText.labelMedium(loc(context).launchInternetConnected),
                const AppGap.regular(),
                Icon(
                  LinksysIcons.signalWifi4Bar,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          )
        : Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const AppSpinner(),
                const AppGap.regular(),
                AppText.labelMedium(loc(context).launchCheckInternet),
              ],
            ),
          );
  }

  Widget _adminPasswordView() {
    return StyledAppPageView(
      backState: StyledBackState.none,
      child: Center(
        child: AppCard(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Image(
                image: CustomTheme.of(context)
                    .images
                    .devices
                    .getByName(routerIconTestByModel(modelNumber: 'LN11')),
                height: 160,
                width: 160,
                fit: BoxFit.fitWidth,
              ),
              AppText.headlineSmall(loc(context).welcome),
              const AppGap.regular(),
              AppText.bodyLarge(loc(context).pnpRouterLoginDesc),
              const AppGap.big(),
              AppPasswordField(
                hintText: loc(context).routerPassword,
                border: const OutlineInputBorder(),
                controller: _textEditController,
                errorText: _inputError?.isEmpty ?? true ? null : _inputError,
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
                        ref
                            .read(pnpProvider.notifier)
                            .checkAdminPassword(_textEditController.text)
                            .then((_) {
                          context.goNamed(RouteNamed.pnpConfig);
                        }).onError((error, stackTrace) {
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
    if (error is JNAPError) {
      return [
        AppText.labelMedium('Invalid password',
            color: Theme.of(context).colorScheme.error)
      ];
    }
    return [
      AppText.labelMedium('Unknown error',
          color: Theme.of(context).colorScheme.error)
    ];
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
