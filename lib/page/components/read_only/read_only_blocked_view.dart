import 'package:flutter/material.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

/// Stands in for a flow that only writes to the router, in a read-only build.
///
/// Leaving it pops with no result, which is how every caller of those flows
/// already treats a user who backed out.
class ReadOnlyBlockedView extends StatelessWidget {
  const ReadOnlyBlockedView({super.key});

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      title: loc(context).readOnlyModeUnavailable,
      child: (context, constraints) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: AppText.bodyLarge(loc(context).readOnlyModeBanner),
        ),
      ),
    );
  }
}
