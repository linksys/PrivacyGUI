import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/bottom_bar.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/instant_admin/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:ui_kit_library/ui_kit.dart';

class LocalRouterRecoveryView extends ArgumentsConsumerStatefulView {
  const LocalRouterRecoveryView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<LocalRouterRecoveryView> createState() =>
      _LocalRouterRecoveryViewState();
}

class _LocalRouterRecoveryViewState
    extends ConsumerState<LocalRouterRecoveryView> {
  final TextEditingController _otpController = TextEditingController();
  String userInputCode = '';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
    _otpController.dispose();
  }

  @override
  Widget build(BuildContext context) => _contentView();

  Widget _contentView() {
    MediaQuery.of(context);
    final state = ref.watch(routerPasswordProvider);
    return UiKitPageView(
      appBarStyle: UiKitAppBarStyle.none,
      padding: EdgeInsets.zero,
      scrollable: true,
      pageFooter: const BottomBar(),
      child: (context, constraints) => Center(
        child: SizedBox(
          width: context.colWidth(4),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                AppText.headlineSmall(loc(context).forgotPassword),
                AppGap.lg(),
                AppText.bodyMedium(loc(context).localRouterRecoveryDescription),
                AppGap.xxxl(),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: AppPinInput(
                      length: 5,
                      controller: _otpController,
                      stayOnLastField: true,
                      onChanged: (String value) {
                        setState(() {
                          userInputCode = value;
                        });
                      },
                      onSubmitted: () {
                        if (userInputCode.length == 5) {
                          _validateCode(userInputCode);
                        }
                      },
                    ),
                  ),
                ),
                if (state.remainingErrorAttempts != null)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.sm),
                    child: AppText.bodyMedium(
                      _getErrorString(state.remainingErrorAttempts!),
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                AppGap.xxxl(),
                AppButton(
                  label: loc(context).textContinue,
                  variant: SurfaceVariant.highlight,
                  onTap: userInputCode.length == 5
                      ? () {
                          _validateCode(userInputCode);
                        }
                      : null,
                )
              ],
            ),
          ),
        ),
      ),
    );
  }

  _validateCode(String code) {
    ref
        .read(routerPasswordProvider.notifier)
        .checkRecoveryCode(code)
        .then((isCodeValid) {
      if (isCodeValid) {
        if (!mounted) return;
        context.pushNamed(
          RouteNamed.localPasswordReset,
          extra: {'code': code},
        );
      }
    });
  }

  String _getErrorString(int remaining) {
    switch (remaining) {
      case 1:
        return '${loc(context).localRouterRecoveryKeyErorr}\n${loc(context).localRouterRecoveryKeyLastChance}';
      case 0:
        return '${loc(context).localRouterRecoveryKeyErorr}\n${loc(context).localRouterRecoveryKeyLocked}';
      default:
        return '${loc(context).localRouterRecoveryKeyErorr}\n${loc(context).localLoginRemainingAttempts(remaining)}';
    }
  }
}
