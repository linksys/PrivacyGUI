import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';

class IpDetailsView extends ArgumentsStatelessView {
  const IpDetailsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        // iconTheme:
        // IconThemeData(color: Theme.of(context).colorScheme.primary),
        elevation: 0,
        title: Text(
          getAppLocalizations(context).ip_details,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          SimpleTextButton(
            text: getAppLocalizations(context).save,
            onPressed: () {},
          ),
        ],
      ),
      body: BasicLayout(
        crossAxisAlignment: CrossAxisAlignment.start,
        content: Column(
          children: [
            box24(),
            _wanSection(context),
            box24(),
            _lanSection(context),
          ],
        ),
      ),
    );
  }

  Widget _wanSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
            title: getAppLocalizations(context).node_detail_label_wan),
        _ipDetailTile(
          title: getAppLocalizations(context).connection_type,
          value: 'DHCP',
        ),
        _ipDetailTile(
          title: getAppLocalizations(context).ip_address,
          value: '192.168.2.100',
          spacing: 0,
          button: SimpleTextButton(
            text: getAppLocalizations(context).release_and_renew,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onTertiary,
            ),
            padding: EdgeInsets.zero,
            onPressed: () {},
          ),
        ),
        _ipDetailTile(
          title: getAppLocalizations(context).ipv6_address,
          value: getAppLocalizations(context).release_ip_description('ssid'),
          spacing: 0,
          button: SimpleTextButton(
            text: getAppLocalizations(context).release_and_renew,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onTertiary,
            ),
            padding: EdgeInsets.zero,
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _lanSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(
            title: getAppLocalizations(context).node_detail_label_lan),
        _ipDetailTile(
          title: getAppLocalizations(context).ip_address,
          value: '192.168.1.1',
        ),
      ],
    );
  }

  Widget _sectionTitle({required String title}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 24),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color.fromRGBO(0, 0, 0, 0.5),
        ),
      ),
    );
  }

  Widget _ipDetailTile({
    required String title,
    required String value,
    Widget? button,
    double spacing = 4,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 24),
      color: const Color.fromRGBO(0, 0, 0, 0.05),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 15),
              ),
              const Spacer(),
              if (button != null) button,
            ],
          ),
          box(spacing),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              color: Color.fromRGBO(102, 102, 102, 1.0),
            ),
          ),
        ],
      ),
    );
  }
}
