import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/route/constants.dart';
import 'package:linksys_app/validator_rules/rules.dart';
import 'package:linksys_app/validator_rules/validators.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/buttons/popup_button.dart';

class PnpAdminView extends ArgumentsBaseConsumerStatefulView {
  const PnpAdminView({super.key, super.args});

  @override
  ConsumerState<PnpAdminView> createState() => _PnpAdminViewState();
}

class _PnpAdminViewState extends ConsumerState<PnpAdminView> {
  late final TextEditingController _textEditController;
  final InputValidator _validator = InputValidator([
    RequiredRule(),
  ], required: true);

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
        }, test: (error) => error == 'ErrorCheckInternetConnection')
        .catchError((error, stackTrace) {
          setState(() {
            _internetChecked = true;
            _inputError = '';
          });
        }, test: (error) => error == 'ErrorInvalidAdminPassword');
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
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText.labelMedium('Internet connected'),
                AppGap.regular(),
                AppIcon.big(
                  icon: Icons.check_circle,
                ),
              ],
            ),
          )
        : const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppText.labelMedium('Checking your internet...'),
                AppGap.regular(),
                CircularProgressIndicator(),
              ],
            ),
          );
  }

  Widget _adminPasswordView() {
    return StyledAppPageView(
      backState: StyledBackState.none,
      child: Align(
        alignment: Alignment.topLeft,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image(
              image: CustomTheme.of(context)
                  .images
                  .devices
                  .getByName(routerIconTest(modelNumber: 'LN11')),
              height: 128,
            ),
            const AppText.bodyLarge("Enter your router's password to proceed"),
            const AppGap.semiSmall(),
            Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: AppPasswordField(
                hintText: 'Password',
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
            ),
            ..._checkError(context, _error),
            const AppGap.semiSmall(),
            const AppPopupButton(
                button: AppText.bodyMedium('Where is it?'),
                content: AppText.bodyMedium(
                    'Your router password is the same as your default Wi-Fi password, printed on the Quick Start Guide and on the bottom of your router')),
            const AppGap.extraBig(),
            AppFilledButton(
              'Next',
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
}
