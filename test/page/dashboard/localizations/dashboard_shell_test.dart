import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:privacy_gui/page/components/styled/consts.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';

import '../../../common/test_responsive_widget.dart';
import '../../../common/testable_router.dart';

void main() async {

  testLocalizations('Dashboard Navigation', (tester, locale) async {
    await tester.pumpWidget(
      testableRouteShellWidget(
        child: StyledAppPageView(
            appBarStyle: AppBarStyle.none, child: Container()),
        locale: locale,
      ),
    );
    await tester.pumpAndSettle();
  });
}
