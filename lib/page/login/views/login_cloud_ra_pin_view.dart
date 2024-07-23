import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/providers/auth/_auth.dart';
import 'package:privacy_gui/providers/auth/ra_session.dart';
import 'package:privacy_gui/providers/auth/ra_session_provider.dart';
import 'package:privacy_gui/validator_rules/input_validators.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';
import 'package:privacygui_widgets/widgets/page/layout/basic_layout.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';

class CloudRAPinView extends ArgumentsConsumerStatefulView {
  const CloudRAPinView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<CloudRAPinView> createState() => _CloudRAPinViewState();
}

class _CloudRAPinViewState extends ConsumerState<CloudRAPinView> {
  String _error = '';
  String? _method;
  bool? _isValidEmail;
  final _emailValidator = EmailValidator();

  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _serialController = TextEditingController()
    ..text = '59A10M28D00110';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();

    _passwordController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(raSessionProvider);
    final methods = [('EMAIL', state.email ?? '')];
    methods
      ..add(('SMS', state.mobile!.fullFormat ?? ''))
      ..add(('WEB', 'Web'))
      ..removeWhere((element) => element.$2.isEmpty);

    return StyledAppPageView(
      padding: EdgeInsets.zero,
      scrollable: true,
      child: AppBasicLayout(
        content: Center(
          child: SizedBox(
            width: ResponsiveLayout.isMobileLayout(context) ? 4.col : 6.col,
            child: AppCard(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 36.0, vertical: 40.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AppText.labelLarge('Send by'),
                    const AppGap.small2(),
                    AppRadioList(
                        onChanged: ((index, value) {
                          _method = value;
                        }),
                        items: methods
                            .map((e) =>
                                AppRadioListItem(title: e.$2, value: e.$1))
                            .toList()),
                    const AppGap.large4(),
                    AppFilledButton(
                      loc(context).send,
                      onTap: () {
                        if (_method == null) {
                          return;
                        }
                        if (_method == 'WEB') {
                          _showInputPinModal();
                          return;
                        }
                        ref
                            .read(raSessionProvider.notifier)
                            .raSendPin(method: _method!)
                            .then((value) {
                          _showInputPinModal();
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        footer: const BottomBar(),
      ),
    );
  }

  _showInputPinModal() {
    final ctx = context;
    TextEditingController controller = TextEditingController();
    String? error;
    showSubmitAppDialog(context, title: 'Input PIN',
            contentBuilder: (context, setState) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          PinCodeTextField(
            errorTextSpace: 0,
            onChanged: (String value) {
              // setState(() {
              //   userInputCode = value;
              // });
            },
            length: 6,
            cursorColor: Theme.of(context).colorScheme.primary,
            appContext: context,
            controller: controller,
            keyboardType: TextInputType.number,
            autoDisposeControllers: false,
            autoDismissKeyboard: true,
            pinTheme: PinTheme(
              shape: PinCodeFieldShape.box,
              borderRadius:
                  CustomTheme.of(context).radius.asBorderRadius().small,
              borderWidth: 1,
              fieldHeight: 60,
              fieldWidth: 48,
              activeColor: Theme.of(context).colorScheme.outline,
              selectedColor: Theme.of(context).colorScheme.outline,
              inactiveColor: Theme.of(context).colorScheme.outline,
            ),
          ),
          const AppGap.small2(),
          if (error != null)
            AppText.bodyMedium(
              error!,
              color: Theme.of(context).colorScheme.error,
            )
        ],
      );
    }, event: () {
      return ref
          .read(raSessionProvider.notifier)
          .raPinVerify(pin: controller.text)
          .then((value) => ref.read(authProvider.notifier).raLogin(
                value.token,
                value.networkId,
                value.serialNumber,
              ));
    }, onError: (err, stackTrace) {
      error = err?.toString();
    }, positiveLabel: 'Submit')
        .then((value) {
      controller.dispose();
      return value;
    }).then((value) {});
  }
}
