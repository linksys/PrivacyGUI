import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/styled/consts.dart';
import 'package:linksys_app/page/pnp/data/pnp_provider.dart';
import 'package:linksys_app/page/pnp/model/impl/guest_wifi_step.dart';
import 'package:linksys_app/page/pnp/model/impl/night_mode_step.dart';
import 'package:linksys_app/page/pnp/model/impl/personal_wifi_step.dart';
import 'package:linksys_app/page/pnp/model/impl/safe_browsing_step.dart';
import 'package:linksys_app/page/pnp/model/pnp_step.dart';
import 'package:linksys_app/page/pnp/pnp_stepper.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/container/responsive_layout.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';

class PnpNoInternetConnectionView extends ConsumerStatefulWidget {
  const PnpNoInternetConnectionView({Key? key}) : super(key: key);

  @override
  ConsumerState<PnpNoInternetConnectionView> createState() =>
      _PnpNoInternetConnectionState();
}

class _PnpNoInternetConnectionState
    extends ConsumerState<PnpNoInternetConnectionView> {
  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      backState: StyledBackState.none,
      child: AppBasicLayout(
        header: SvgPicture(CustomTheme.of(context).images.noInternetConnection),
      ),
    );
  }
}
