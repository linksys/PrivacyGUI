import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_app/page/safe_browsing/providers/_providers.dart';
import 'package:linksys_widgets/theme/_theme.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:linksys_widgets/widgets/radios/radio_list.dart';

class SafeBrowsingView extends ArgumentsConsumerStatefulView {
  const SafeBrowsingView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<SafeBrowsingView> createState() => _SafeBrowsingViewState();
}

class _SafeBrowsingViewState extends ConsumerState<SafeBrowsingView> {
  late final SafeBrowsingNotifier _notifier;
  bool enableSafeBrowsing = false;
  SafeBrowsingType currentSafeBrowsingType = SafeBrowsingType.fortinet;

  @override
  void initState() {
    _fetchData();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(safeBrowsingProvider);
    return state.isLoading
        ? const AppFullScreenSpinner()
        : StyledAppPageView(
            scrollable: true,
            title: getAppLocalizations(context).safe_browsing,
            actions: [
              AppTextButton(
                getAppLocalizations(context).save,
                onTap: _edited(state.safeBrowsingType)
                    ? () {
                        ref.read(safeBrowsingProvider.notifier).setSafeBrowsing(
                            enableSafeBrowsing
                                ? currentSafeBrowsingType
                                : SafeBrowsingType.off);
                      }
                    : null,
              ),
            ],
            child: AppBasicLayout(
              content: Column(
                children: [
                  _safeBrowsingToggle(state),
                  const AppGap.regular(),
                  AppText.bodyMedium(
                      getAppLocalizations(context).safe_browsing_desc),
                  const AppGap.regular(),
                  if (enableSafeBrowsing) _dnsOption(state),
                ],
              ),
            ),
          );
  }

  _safeBrowsingToggle(SafeBrowsingState state) {
    return Row(
      children: [
        AppText.bodyMedium(getAppLocalizations(context).safe_browsing),
        const AppGap.small(),
        // beta img
        const Spacer(),
        AppSwitch(
          value: enableSafeBrowsing,
          onChanged: (enable) {
            setState(() {
              enableSafeBrowsing = enable;
            });
          },
        ),
      ],
    );
  }

  _dnsOption(SafeBrowsingState state) {
    return AppRadioList(
      initial: currentSafeBrowsingType,
      items: [
        if (state.hasFortinet)
          AppRadioListItem(
            title: 'Fortinet',
            value: SafeBrowsingType.fortinet,
            titleWidget: Row(
              children: [
                Image(image: CustomTheme.of(context).images.fortinetDns),
                const AppGap.small(),
                const AppText.bodyMedium('Secure DNS'),
              ],
            ),
            subtitleWidget: AppText.bodyMedium(
                getAppLocalizations(context).fortinet_secure_dns),
          ),
        AppRadioListItem(
          title: 'OpenDNS',
          value: SafeBrowsingType.openDNS,
          titleWidget: Row(
            children: [
              Image(image: CustomTheme.of(context).images.openDns),
            ],
          ),
          subtitleWidget:
              AppText.bodyMedium(getAppLocalizations(context).opendns_by_cisco),
        ),
      ],
      onChanged: (index, type) {
        setState(() {
          if (type != null) {
            currentSafeBrowsingType = type;
          }
        });
      },
    );
  }

  Future _fetchData() async {
    _notifier = ref.read(safeBrowsingProvider.notifier);
    _notifier.fetchLANSettings().then((_) {
      setState(() {
        final stateSafeBrowsingType =
            ref.read(safeBrowsingProvider).safeBrowsingType;
        enableSafeBrowsing = !(stateSafeBrowsingType == SafeBrowsingType.off);
        if (stateSafeBrowsingType == SafeBrowsingType.off) {
          currentSafeBrowsingType = ref.read(safeBrowsingProvider).hasFortinet
              ? SafeBrowsingType.fortinet
              : SafeBrowsingType.openDNS;
        } else {
          currentSafeBrowsingType = stateSafeBrowsingType;
        }
      });
    });
  }

  bool _edited(SafeBrowsingType stateSafeBrowsingType) {
    if (stateSafeBrowsingType == SafeBrowsingType.off) {
      return enableSafeBrowsing;
    } else {
      return !enableSafeBrowsing ||
          (stateSafeBrowsingType != currentSafeBrowsingType);
    }
  }
}
