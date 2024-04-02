import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_app/util/extensions.dart';
import 'package:linksys_widgets/icons/linksys_icons.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';

class LanguageTile extends ConsumerStatefulWidget {
  final void Function()? onTap;
  final Locale locale;
  final IconData icon;

  const LanguageTile({
    super.key,
    this.onTap,
    required this.locale,
    this.icon = LinksysIcons.language,
  });

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _LanguageTileState();
}

class _LanguageTileState extends ConsumerState<LanguageTile> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: widget.onTap,
      child: _displayLocale(widget.locale),
    );
  }

  Widget _displayLocale(Locale locale) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(widget.icon),
        const AppGap.regular(),
        Flexible(child: AppText.labelMedium(locale.displayText)),
      ],
    );
  }
}
