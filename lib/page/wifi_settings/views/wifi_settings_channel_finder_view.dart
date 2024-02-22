import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/wifi_settings/_wifi_settings.dart';
import 'package:linksys_widgets/hook/icon_hooks.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/base/gap.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';

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
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            title: 'Channel Finder',
            child: AppBasicLayout(
              content: isShowButton
                  ? _channelFinderButton()
                  : _channelFinderResult(state),
            ),
          );
  }

  Widget _channelFinderButton() {
    return Center(
      child: TextButton(
        onPressed: () {
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
        child: const Text('Start Channel Finder'),
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
      return const Text('Your wifi already at the best performance');
    }
  }

  Widget _listCell(OptimizedSelectedChannel channel) {
    return Row(
      children: [
        Image(
            image: CustomTheme.of(context)
                .images
                .devices
                .getByName(channel.deviceIcon!)),
        const AppGap.regular(),
        Text(channel.deviceName!)
      ],
    );
  }
}
