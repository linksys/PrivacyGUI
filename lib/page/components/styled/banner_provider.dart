import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/core/utils/logger.dart';
import 'package:linksys_app/page/components/styled/banner_info.dart';
import 'package:linksys_app/route/router_provider.dart';
import 'package:linksys_widgets/widgets/banner/banner_style.dart';

final bannerProvider =
    NotifierProvider<BannerNotifier, BannerInfo>(() => BannerNotifier());

class BannerNotifier extends Notifier<BannerInfo> {
  @override
  build() {
    final routerInformationProvider = ref.read(routerProvider).routerDelegate;
    routerInformationProvider.addListener(() {
      logger.d('Route changed');
      hideBanner();
    });
    return const BannerInfo(
        isDiaplay: false, style: BannerStyle.success, text: '');
  }

  void showBanner({
    required BannerStyle style,
    required text,
  }) {
    if (!state.isDiaplay) {
      state = state.copyWith(isDiaplay: true, style: style, text: text);
    }
  }

  void hideBanner() {
    if (state.isDiaplay) {
      state = state.copyWith(isDiaplay: false);
    }
  }
}