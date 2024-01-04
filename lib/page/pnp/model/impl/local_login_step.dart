import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/jnap/result/jnap_result.dart';
import 'package:linksys_app/core/utils/icon_rules.dart';
import 'package:linksys_widgets/widgets/buttons/popup_button.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class LocalLoginStep extends PnpStep {
  late final TextEditingController _textEditController;

  LocalLoginStep({required super.index});

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);
    _textEditController = TextEditingController();
    if (_textEditController.text.isEmpty) {
      ref
          .read(pnpProvider.notifier)
          .setStepStatus(index, status: StepViewStatus.error);
    }
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    final password = _textEditController.text;

    /// admin password validation
    // await ref.read(pnpProvider.notifier).checkAdminPassword(password);

    return {'password': password};
  }

  @override
  void onDispose() {
    _textEditController.dispose();
  }

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    final error = ref.watch(pnpProvider).stepStateList[index]?.error;

    return Align(
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
              onChanged: (value) {
                if (value.isEmpty) {
                  ref
                      .read(pnpProvider.notifier)
                      .setStepStatus(index, status: StepViewStatus.error);
                } else {
                  ref
                      .read(pnpProvider.notifier)
                      .setStepStatus(index, status: StepViewStatus.data);
                }
              },
            ),
          ),
          ..._checkError(context, error),
          const AppGap.semiSmall(),
          const AppPopupButton(
              button: AppText.bodyMedium('Where is it?'),
              content: AppText.bodyMedium(
                  'Your router password is the same as your default Wi-Fi password, printed on the Quick Start Guide and on the bottom of your router')),
        ],
      ),
    );
  }

  @override
  String title(BuildContext context) => 'Welcome';

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
