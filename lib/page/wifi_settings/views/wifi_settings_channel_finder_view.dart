import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/core/utils/device_image_helper.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/page/wifi_settings/_wifi_settings.dart';
import 'package:ui_kit_library/ui_kit.dart';

class WifiSettingsChannelFinderView extends ArgumentsConsumerStatefulView {
  const WifiSettingsChannelFinderView({Key? key, super.args}) : super(key: key);

  @override
  ConsumerState<ConsumerStatefulWidget> createState() =>
      _WifiSettingsChannelFinderViewState();
}

class _WifiSettingsChannelFinderViewState
    extends ConsumerState<WifiSettingsChannelFinderView> {
  bool isLoading = false;
  bool isShowButton = true;

  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(channelFinderProvider);
    return isLoading
        ? Scaffold(
            body: Center(
              child: AppLoader(),
            ),
          )
        : UiKitPageView.withSliver(
            title: 'Channel Finder',
            child: (context, constraints) => isShowButton
                ? _channelFinderButton()
                : _channelFinderResult(state),
          );
  }

  Widget _channelFinderButton() {
    return Center(
      child: AppButton.primary(
        label: 'Start Channel Finder',
        onTap: () {
          setState(() {
            isLoading = true;
            isShowButton = false;
          });
          ref
              .read(channelFinderProvider.notifier)
              .optimizeChannels()
              .then((value) {
            setState(() {
              isLoading = false;
            });
          });
        },
      ),
    );
  }

  Widget _channelFinderResult(ChannelFinderState state) {
    if (state.result.isNotEmpty) {
      return ListView.builder(
        itemCount: state.result.length,
        itemBuilder: (context, index) => _listCell(state.result[index]),
      );
    } else {
      return AppText.bodyMedium('Your wifi already at the best performance');
    }
  }

  Widget _listCell(OptimizedSelectedChannel channel) {
    return Row(
      children: [
        AppImage.provider(
          imageProvider:
              DeviceImageHelper.getRouterImage(channel.deviceIcon!, xl: false),
          width: 40,
          height: 40,
        ),
        AppGap.lg(),
        AppText.bodyMedium(channel.deviceName!)
      ],
    );
  }
}
