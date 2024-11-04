// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:privacy_gui/localization/localization_hook.dart';

import 'package:privacy_gui/page/support/providers/support_state.dart';
import 'package:privacygui_widgets/icons/linksys_icons.dart';
import 'package:privacygui_widgets/theme/_theme.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/container/responsive_layout.dart';

class CallLogCard extends StatefulWidget {
  final Ticket ticket;
  final bool isDesktopHeader;
  final Future Function(Ticket)? onCancel;
  final Future Function(Ticket)? onReopen;
  final void Function(Ticket)? onDescriptionTap;

  const CallLogCard({
    Key? key,
    required this.ticket,
    this.isDesktopHeader = false,
    this.onCancel,
    this.onReopen,
    this.onDescriptionTap,
  }) : super(key: key);

  factory CallLogCard.desktopHeader({
    Key? key,
    required Ticket ticket,
  }) =>
      CallLogCard(
        key: key,
        ticket: ticket,
        isDesktopHeader: true,
      );

  @override
  State<CallLogCard> createState() => _CallLogCardState();
}

class _CallLogCardState extends State<CallLogCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    return ResponsiveLayout(
      desktop: desktopCallLogCard(
        ticket: widget.ticket,
        isHeader: widget.isDesktopHeader,
      ),
      mobile: mobileCallLogCard(widget.ticket),
    );
  }

  Widget desktopCallLogCard({required Ticket ticket, bool isHeader = false}) {
    final List<Widget> content = isHeader
        ? [
            SizedBox(
              width: 129,
              child: AppText.labelLarge(loc(context).date),
            ),
            SizedBox(
              width: 129,
              child: AppText.labelLarge(loc(context).caseNum),
            ),
            Expanded(
              child: AppText.labelLarge(loc(context).description),
            ),
            SizedBox(
              width: 129,
              child: AppText.labelLarge(loc(context).status),
            ),
            SizedBox(
              width: 129,
              child: AppText.labelLarge(loc(context).action),
            ),
          ]
        : [
            SizedBox(
              width: 129,
              child: AppText.bodyMedium(_getDateString(ticket.createdAt)),
            ),
            SizedBox(
              width: 129,
              child: AppText.bodyMedium(ticket.salesforceCaseNumber),
            ),
            Expanded(
              child: InkWell(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 0, 8, 0),
                  child: AppText.bodyMedium(
                    ticket.description,
                    color: Theme.of(context).colorScheme.primary,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                onTap: () {
                  widget.onDescriptionTap?.call(ticket);
                },
              ),
            ),
            SizedBox(
              width: 129,
              child: _getStatusWidget(ticket.status),
            ),
            SizedBox(
              width: 129,
              child: _getActionButton(ticket),
            ),
          ];
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outlineVariant,
          ),
        ),
      ),
      child: Card(
        elevation: 0,
        margin: EdgeInsets.zero,
        color: isHeader ? Theme.of(context).colorScheme.surfaceVariant : null,
        shape: isHeader
            ? const RoundedRectangleBorder(
                side: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
              )
            : const RoundedRectangleBorder(
                side: BorderSide(color: Colors.transparent),
                borderRadius: BorderRadius.only(),
              ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: content,
          ),
        ),
      ),
    );
  }

  Widget mobileCallLogCard(Ticket ticket) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LinksysIcons.calendar),
              const AppGap.small2(),
              AppText.bodyMedium(
                _getDateString(ticket.createdAt),
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const AppGap.large2(),
              const Icon(
                LinksysIcons.confirmationNumber,
                semanticLabel: 'confirmation Number icon',
              ),
              const AppGap.small2(),
              AppText.bodyMedium(
                '#${ticket.salesforceCaseNumber}',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const Spacer(),
              _getStatusWidget(ticket.status)
            ],
          ),
          const AppGap.large2(),
          AppText.bodyMedium(
            ticket.description,
            maxLines: expanded ? 2000 : 2,
            overflow: TextOverflow.ellipsis,
          ),
          const AppGap.large2(),
          Row(
            children: [
              AppIconButton(
                icon: expanded
                    ? LinksysIcons.arrowDropUp
                    : LinksysIcons.arrowDropDown,
                semanticLabel: expanded ? 'arrow Drop Up' : 'arrow Drop Down',
                onTap: () {
                  setState(() {
                    expanded = !expanded;
                  });
                },
              ),
              const Spacer(),
              _getActionButton(ticket),
            ],
          ),
        ],
      ),
    );
  }

  String _getDateString(String createAt) {
    DateTime tempDate = DateFormat("yyyy-MM-ddThh:mm:ssZ").parse(createAt);
    return DateFormat("MM/dd/yyyy").format(tempDate);
  }

  Widget _getStatusWidget(String status) {
    final (String, Color?) result = switch (status) {
      'Timeout' => (
          loc(context).failedExclamation,
          Theme.of(context).colorScheme.error
        ),
      'Failed' => (
          loc(context).failedExclamation,
          Theme.of(context).colorScheme.error
        ),
      'Resolved' => (
          loc(context).closed,
          Theme.of(context).colorScheme.outline
        ),
      _ => (loc(context).open, Theme.of(context).colorSchemeExt.green),
    };
    return AppText.bodyMedium(
      result.$1,
      color: result.$2,
    );
  }

  Widget _getActionButton(Ticket ticket) {
    return switch (ticket.status) {
      'Timeout' => _reopenButton(ticket),
      'Failed' => _reopenButton(ticket),
      'Resolved' => _reopenButton(ticket),
      _ => _cancelButton(ticket),
    };
  }

  Widget _reopenButton(Ticket ticket) {
    return InkWell(
      onTap: widget.onReopen != null
          ? () {
              widget.onReopen?.call(ticket);
            }
          : null,
      child: AppText.labelLarge(
        loc(context).reopen,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  Widget _cancelButton(Ticket ticket) {
    return InkWell(
      onTap: widget.onCancel != null
          ? () {
              widget.onCancel?.call(ticket);
            }
          : null,
      child: AppText.labelLarge(
        loc(context).cancel,
        color: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
