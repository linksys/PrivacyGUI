import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/constants/_constants.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/route/constants.dart';
import 'package:ui_kit_library/ui_kit.dart' hide AppBarStyle, AppStyledText;

class HomeView extends ArgumentsConsumerStatefulView {
  const HomeView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends ConsumerState<HomeView> {
  final bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return UiKitPageView(
      backState: UiKitBackState.none,
      pageFooter: _footer(context),
      child: (context, constraints) => _isLoading
          ? AppFullScreenLoader(
              title: 'Loading...',
            )
          : _content(context),
    );
  }

  Widget _content(BuildContext context) {
    return Stack(
      children: [
        Center(
          child: Assets.images.linksysWordmark.svg(),
        ),
      ],
    );
  }

  Widget _footer(BuildContext context) {
    return Column(children: [
      SizedBox(
        width: double.infinity,
        child: AppButton(
          label: loc(context).login,
          variant: SurfaceVariant.highlight,
          key: const Key('home_view_button_login'),
          onTap: () {
            context.pushNamed(RouteNamed.localLoginPassword);
          },
        ),
      ),
      AppGap.md(),
      FutureBuilder(
          future: getVersion(),
          initialData: '-',
          builder: (context, data) {
            var version = 'version ${data.data}';
            if (kIsWeb) {
              version = '$version - local';
            }
            return AppText.bodySmall(
              version,
            );
          }),
    ]);
  }
}
