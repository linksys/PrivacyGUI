import 'package:collection/collection.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/core/cloud/model/cloud_account.dart';
import 'package:privacy_gui/core/cloud/model/cloud_communication_method.dart';
import 'package:privacy_gui/core/utils/logger.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/otp_flow/providers/_providers.dart';
import 'package:privacy_gui/page/account/providers/_providers.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';

class TwoStepVerificationView extends ArgumentsConsumerStatefulView {
  const TwoStepVerificationView({super.key, super.args});

  @override
  ConsumerState<TwoStepVerificationView> createState() =>
      _TwoStepVerificationViewState();
}

class _TwoStepVerificationViewState
    extends ConsumerState<TwoStepVerificationView> {
  @override
  Widget build(BuildContext context) {
    ref.listen(otpProvider.select((value) => (value.step, value.extras)),
        (previous, next) {
      if (next.$1 == previous?.$1) {
        return;
      }
      if (next.$1 == OtpStep.finish) {
        logger.d('2FA: Otp pass! $next');
        final method = CommunicationMethod.fromJson(next.$2);
        ref.read(accountProvider.notifier).addMfaMethod(method);
        context.replaceNamed(RouteNamed.twoStepVerification);
      }
    });
    final state = ref.watch(accountProvider);
    return StyledAppPageView(
        scrollable: true,
        title: '2-Step Verification',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSection.withLabel(
                title: '2-Step Verification',
                content: const AppText.bodyMedium(
                    '2-step verification adds a layer of secutrity to your account. When you log in from a new device. we\'ll ask you to enter a verification code sent via email or SMS')),
            AppGap.big(),
            AppText.labelLarge('Delivery Methods'),
            AppPanelWithSwitch(
              value: state.methods.firstWhereOrNull(
                      (element) => element.method.toLowerCase() == 'email') !=
                  null,
              title: 'Email',
              description:
                  'You\'ll receive verification codes via the email address associated with your account.',
              onChangedEvent: (value) {
                final method = state.methods.firstWhereOrNull(
                        (element) => element.method.toLowerCase() == 'email') ??
                    CommunicationMethod(
                        method: 'EMAIL', target: state.username);

                if (value) {
                  context.pushNamed(
                    RouteNamed.otpStart,
                    extra: {
                      'function': 'add',
                      'selected': method,
                      'commMethods': [method],
                    },
                  );
                } else {
                  ref
                      .read(accountProvider.notifier)
                      .removeMfaMethod(method.id!);
                }
              },
            ),
            AppPanelWithSwitch(
              value: state.methods.firstWhereOrNull(
                      (element) => element.method.toLowerCase() == 'sms') !=
                  null,
              title: 'Text Message',
              description:
                  'You\'ll receive verification codes via the SMS message to your phone number.',
              onChangedEvent: (value) {
                final method = state.methods.firstWhereOrNull(
                        (element) => element.method.toLowerCase() == 'sms') ??
                    CommunicationMethod(
                        method: 'SMS',
                        target: /*state.mobile?.fullFormat ??*/ '');

                if (value) {
                  // check phone number
                  if (method.target.isEmpty) {
                    context
                        .pushNamed<CommunicationMethod?>(RouteNamed.otpAddPhone)
                        .then((result) {
                      if (result == null) {
                        return;
                      }
                      ref
                          .read(accountProvider.notifier)
                          .setPhoneNumber(CAMobile(
                            countryCode: result.phone?.countryCallingCode,
                            phoneNumber: result.phone?.phoneNumber,
                          ))
                          .then((_) {
                        context.pushNamed(
                          RouteNamed.otpStart,
                          extra: {
                            'function': 'add',
                            'selected': result,
                            'commMethods': [result],
                          },
                        );
                      });
                    });
                  } else {
                    context.pushNamed(
                      RouteNamed.otpStart,
                      extra: {
                        'function': 'add',
                        'selected': method,
                        'commMethods': [method],
                      },
                    );
                  }
                } else {
                  ref
                      .read(accountProvider.notifier)
                      .removeMfaMethod(method.id!);
                }
              },
            ),
            AppSection.noHeader(
                content: AppText.bodyMedium(
                    'If you turn on both options. we\'ll ask you how you want to receive your code when you log in.'))
          ],
        ));
  }
}
