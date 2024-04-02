import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class AccountStep extends PnpStep {
  late final TextEditingController _accountCreateEditController;
  late final TextEditingController _usernameEditController;
  late final TextEditingController _passwordEditController;
  late final TextEditingController _localPasswordCreateEditController;

  AccountStep({required super.index});

  @override
  String nextLable(BuildContext context) => 'Finish';

  @override
  Future<void> onInit(WidgetRef ref) async {
    await super.onInit(ref);
    _accountCreateEditController = TextEditingController();
    _usernameEditController = TextEditingController();
    _passwordEditController = TextEditingController();
    _localPasswordCreateEditController = TextEditingController();
  }

  @override
  Future<Map<String, dynamic>> onNext(WidgetRef ref) async {
    return {};
  }

  @override
  void onDispose() {
    _accountCreateEditController.dispose();
    _usernameEditController.dispose();
    _passwordEditController.dispose();
    _localPasswordCreateEditController.dispose();
  }

  @override
  Widget content({
    required BuildContext context,
    required WidgetRef ref,
    Widget? child,
  }) {
    String auth = ref
            .watch(pnpProvider.select((value) => value.stepStateList))[index]
            ?.data['auth'] ??
        'create';
    if (auth == 'local') {
      return _localWiget(context, ref);
    } else if (auth == 'cloud') {
      return _loginWiget(context, ref);
    } else {
      return _accountCreationWidget(context, ref);
    }
  }

  @override
  String title(BuildContext context) => 'Linksys Account';

  Widget _localWiget(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.headlineSmall('Create router password'),
        Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AppPasswordField(
            hintText: 'password',
            controller: _localPasswordCreateEditController,
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
        const AppGap.regular(),
        AppTextButton.noPadding(
          'Create a new account',
          onTap: () {
            update(ref, key: 'auth', value: 'create');
          },
        ),
        const AppGap.big(),
      ],
    );
  }

  Widget _loginWiget(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.headlineSmall('Log in'),
        Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AppPasswordField(
            hintText: 'Email',
            controller: _usernameEditController,
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
        const AppGap.semiSmall(),
        Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AppPasswordField(
            hintText: 'Password',
            controller: _passwordEditController,
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
        const AppGap.regular(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppTextButton.noPadding(
              'Reset password',
              onTap: () {},
            ),
            AppTextButton.noPadding(
              'Create a new account',
              onTap: () {
                update(ref, key: 'auth', value: 'create');
              },
            ),
          ],
        ),
        const AppGap.big(),
      ],
    );
  }

  Widget _accountCreationWidget(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppText.headlineSmall('Create a Linksys Account'),
        Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: AppPasswordField(
            hintText: 'Email',
            controller: _accountCreateEditController,
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
        const AppGap.semiSmall(),
        AppTextButton.noPadding(
          'I already have an account',
          onTap: () {
            update(ref, key: 'auth', value: 'cloud');
          },
        ),
        const AppGap.big(),
        const AppText.bodySmall("An account is required for"),
        const AppGap.regular(),
        Row(
          children: [
            Image(
              image: CustomTheme.of(context).images.iconEllipseGreen,
            ),
            const AppGap.semiSmall(),
            const AppText.bodySmall(
              'Automatically tracking your 3 year warranty',
            )
          ],
        ),
        Row(
          children: [
            Image(
              image: CustomTheme.of(context).images.iconEllipseGreen,
            ),
            const AppGap.semiSmall(),
            const AppText.bodySmall(
              'Getting notified when internet is down',
            )
          ],
        ),
        Row(
          children: [
            Image(
              image: CustomTheme.of(context).images.iconEllipseGreen,
            ),
            const AppGap.semiSmall(),
            const AppText.bodySmall(
              'Remote Access',
            )
          ],
        ),
        Row(
          children: [
            Image(
              image: CustomTheme.of(context).images.iconEllipseGreen,
            ),
            const AppGap.semiSmall(),
            const AppText.bodySmall(
              'Premium customer support',
            )
          ],
        ),
        const AppGap.big(),
        AppTextButton.noPadding(
          'No thanks, use router password',
          onTap: () {
            update(ref, key: 'auth', value: 'local');
          },
        ),
      ],
    );
  }

  void update(WidgetRef ref, {required String key, dynamic value}) {
    if (value == null) {
      return;
    }
    final currentData = ref.read(pnpProvider).stepStateList[index]?.data ?? {};
    ref
        .read(pnpProvider.notifier)
        .setStepData(index, data: Map.from(currentData)..[key] = value);
  }
}
