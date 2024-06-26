import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/support/providers/support_provider.dart';
import 'package:privacy_gui/page/support/providers/support_state.dart';
import 'package:privacy_gui/page/support/views/call_log_card.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class CallLogView extends ArgumentsConsumerStatefulView {
  final List<Widget>? actions;

  const CallLogView({
    Key? key,
    this.actions,
  }) : super(key: key);

  @override
  ConsumerState<CallLogView> createState() => _CallLogViewState();
}

class _CallLogViewState extends ConsumerState<CallLogView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final ticketList =
        ref.watch(supportProvider.select((value) => value.ticketList));
    ref.listen(supportProvider.select((value) => value.justCreatedANewIssue),
        (previous, next) {});
    return StyledAppPageView(
      scrollable: true,
      actions: widget.actions,
      title: loc(context).callLog,
      child: ticketList.isEmpty ? emptyView() : ticketListView(ticketList),
    );
  }

  Widget ticketListView(List<Ticket> ticketList) {
    return ResponsiveLayout(
      desktop: desktopTicketListView(ticketList),
      mobile: mobileTicketListView(ticketList),
    );
  }

  Widget emptyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          LinksysIcons.phoneDisabled,
          size: 66,
        ),
        const AppGap.large3(),
        AppText.bodyLarge(loc(context).noCallbacksDescription),
      ],
    );
  }

  Widget desktopTicketListView(List<Ticket> ticketList) {
    return Column(
      children: [
        SizedBox(
          height: 60,
          child: CallLogCard(ticket: ticketList.first, isDesktopHeader: true),
        ),
        ...ticketList.map(
          (ticket) => SizedBox(
            height: 60,
            child: CallLogCard(
              ticket: ticket,
              onCancel: onCancel,
              onReopen: onReopen,
              onDescriptionTap: onDescriptionTap,
            ),
          ),
        ),
      ],
    );
  }

  Widget mobileTicketListView(List<Ticket> ticketList) {
    return Column(
      children: [
        ...ticketList.map(
          (ticket) => CallLogCard(
            ticket: ticket,
            onCancel: onCancel,
            onReopen: onReopen,
          ),
        ),
      ],
    );
  }

  Future onCancel(Ticket ticket) async {
    showSimpleAppDialog(
      context,
      title: loc(context).cancelCallbackRequest,
      content:
          AppText.bodyMedium(loc(context).areYouSureYouWantToCancelThisRequest),
      actions: [
        AppTextButton(
          loc(context).back,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          onTap: () => context.pop(),
        ),
        AppTextButton(
          loc(context).yesCancel,
          onTap: () {
            // TODO: cancel
            context.pop();
          },
        ),
      ],
    );
  }

  Future onReopen(Ticket ticket) async {
    // TODO: reopen
  }

  void onDescriptionTap(Ticket ticket) {
    showSimpleAppOkDialog(
      context,
      title: loc(context).issue,
      content: Expanded(
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: AppText.bodyMedium(ticket.description),
        ),
      ),
      okLabel: loc(context).cancel,
    );
  }
}
