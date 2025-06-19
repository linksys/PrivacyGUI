import 'package:flutter/material.dart';
import 'package:privacy_gui/page/modular_apps/models/modular_app_data.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:url_launcher/url_launcher.dart';

class ModularAppInfoWidget extends StatefulWidget {
  final ModularAppData app;

  const ModularAppInfoWidget({
    Key? key,
    required this.app,
  }) : super(key: key);

  @override
  State<ModularAppInfoWidget> createState() => _ModularAppInfoWidgetState();
}

class _ModularAppInfoWidgetState extends State<ModularAppInfoWidget> {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      color: widget.app.color.color,
      onTap: () {
        launchUrl(Uri.parse(widget.app.link));
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    widget.app.icon.toIcon(),
                    AppGap.small2(),
                    AppText.labelLarge(
                      widget.app.name,
                      overflow: TextOverflow.clip,
                      maxLines: 1,
                    ),
                    AppText.labelSmall(
                      widget.app.description,
                      overflow: TextOverflow.clip,
                      maxLines: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
          AppGap.small2(),
          AppText.labelSmall(
            'Version: ${widget.app.version}',
            overflow: TextOverflow.clip,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}
