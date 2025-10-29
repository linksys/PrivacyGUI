import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/providers/_providers.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_exception.dart';
import 'package:privacy_gui/page/instant_setup/data/pnp_provider.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/gap/const/spacing.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

class PnpIspAuthView extends ArgumentsConsumerStatefulView {
  const PnpIspAuthView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<PnpIspAuthView> createState() => _PnpIspAuthViewState();
}

class _PnpIspAuthViewState extends ConsumerState<PnpIspAuthView> {
  final _passwordController = TextEditingController();
  late final InternetSettingsState newSettings;
  bool _isLoading = false;
  String? _spinnerText; //TODO: all spinner text is not confirmed
  String? _inputPasswordError;
  StreamSubscription? subscription;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login(String password) {
    setState(() {
      _spinnerText = loc(context).processing;
    });
    return ref
        .read(pnpProvider.notifier)
        .checkAdminPassword(password)
        .then((value) {
      logger.i('[PnP]: Troubleshooter - Login succeeded');
      // Login succeeded
      context.pop(true);
    }).catchError((error) {
      logger
          .e('[PnP]: Troubleshooter - Login failed - Invalid admin password!');
      // Login failed, show password input form with an error
      setState(() {
        _inputPasswordError = loc(context).errorIncorrectPassword;
        _isLoading = false;
      });
    }, test: (error) => error is ExceptionInvalidAdminPassword).onError(
            (error, stackTrace) {
      logger
          .e('[PnP]: Troubleshooter - Login failed - Invalid admin password!');
      // Unexcept error, show password input form with an error
      setState(() {
        _inputPasswordError = loc(context).generalError;
        _isLoading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? AppFullScreenSpinner(text: _spinnerText)
        : StyledAppPageView.withSliver(
            title: loc(context).pnpIspSettingsAuthTitle,
            child: (context, constraints) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppGap.large2(),
                AppPasswordField(
                  border: OutlineInputBorder(),
                  headerText: loc(context).password,
                  controller: _passwordController,
                  onSubmitted: (_) {
                    _login(_passwordController.text);
                  },
                ),
                if (_inputPasswordError != null)
                  Padding(
                    padding: const EdgeInsets.only(
                      top: Spacing.medium,
                    ),
                    child: AppText.bodyLarge(
                      _inputPasswordError!,
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: Spacing.large3 + Spacing.small2,
                  ),
                  child: AppTextButton.noPadding(
                    loc(context).pnpRouterLoginWhereIsIt,
                    onTap: () {
                      _showRouterPasswordModal();
                    },
                  ),
                ),
                AppFilledButton(
                  loc(context).next,
                  onTap: () {
                    setState(() {
                      _isLoading = true;
                    });
                    _login(_passwordController.text);
                  },
                ),
              ],
            ),
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
