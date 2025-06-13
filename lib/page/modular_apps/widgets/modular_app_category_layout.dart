import 'package:flutter/material.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_data.dart';
import 'package:privacy_gui/page/modular_apps/widgets/modular_app_info_widget.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class ModularAppCategoryLayout extends StatefulWidget {
  final String title;
  final List<ModularAppData> apps;

  const ModularAppCategoryLayout({
    Key? key,
    required this.title,
    required this.apps,
  }) : super(key: key);

  @override
  State<ModularAppCategoryLayout> createState() =>
      _ModularAppCategoryLayoutState();
}

class _ModularAppCategoryLayoutState extends State<ModularAppCategoryLayout> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.titleSmall('${widget.title} (${widget.apps.length})'),
        AppGap.medium(),
        if (widget.apps.isEmpty)
          AppText.labelMedium('No apps available')
        else
          SizedBox(
            height: 200,
            child: CarouselView(
              itemExtent: 200,
              itemSnapping: true,
              children: widget.apps
                  .map((app) => ModularAppInfoWidget(app: app))
                  .toList(),
            ),
          ),
      ],
    );
  }
}
