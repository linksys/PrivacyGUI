import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/support/providers/support_provider.dart';
import 'package:privacy_gui/page/support/providers/support_state.dart';
import 'package:privacy_gui/page/support/views/call_log_view.dart';
import 'package:privacy_gui/page/support/views/callback_request_view.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';

class CallbackView extends ArgumentsConsumerStatefulView {
  const CallbackView({Key? key}) : super(key: key);

  @override
  ConsumerState<CallbackView> createState() => _CallbackViewState();
}

class _CallbackViewState extends ConsumerState<CallbackView> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTickets();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(supportProvider);
    return isLoading ? const AppFullScreenSpinner() : callbackView(state);
  }

  Widget callbackView(SupportState state) {
    return switch (state.callbackViewType) {
      CallbackViewType.callLog => CallLogView(
          actions: [
            AppTextButton(
              loc(context).requestCallback,
              icon: LinksysIcons.call,
              onTap: () {
                if (state.hasOpenTicket) {
                  showSimpleAppOkDialog(
                    context,
                    title: loc(context).only1CallbackCaseCanBeOpenedAtATime,
                    content: AppText.bodyMedium(loc(context).only1CallbackCaseDescription),
                    okLabel: loc(context).okay,
                  );
                } else {
                  ref
                      .read(supportProvider.notifier)
                      .updateCallbackViewType(CallbackViewType.request);
                }
              },
            )
          ],
        ),
      CallbackViewType.request => CallbackRequestView(
          actions: [
            AppTextButton(
              loc(context).callLog,
              icon: LinksysIcons.call,
              onTap: () {
                ref
                    .read(supportProvider.notifier)
                    .updateCallbackViewType(CallbackViewType.callLog);
              },
            )
          ],
        ),
      _ => const Center(),
    };
  }

  Future<void> _fetchTickets() async {
    setState(() {
      isLoading = true;
    });
    ref.read(supportProvider.notifier).fetchTickets().whenComplete(() {
      setState(() {
        isLoading = false;
      });
    });
  }
}
