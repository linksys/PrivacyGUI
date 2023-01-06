import 'package:flutter/cupertino.dart';
import 'package:linksys_core/theme/_theme.dart';
import 'package:linksys_core/widgets/_widgets.dart';
import 'package:linksys_core/widgets/base/gap.dart';
import 'package:linksys_core/widgets/base/padding.dart';

class ButtonData {
  const ButtonData({required this.text, this.onClicked});

  final VoidCallback? onClicked;
  final String text;
}

class AppModalLayout extends StatelessWidget {
  final VoidCallback? closeCallback;
  final ImageProvider? image;
  final String? title;
  final String? description;
  final ButtonData? positiveButton;
  final ButtonData? negativeButton;

  const AppModalLayout({
    super.key,
    this.closeCallback,
    this.image,
    this.title,
    this.description,
    this.positiveButton,
    this.negativeButton,
  }) : assert((title != null || description != null) && positiveButton != null);

  @override
  Widget build(BuildContext context) {
    final theme = AppTheme.of(context);
    final image = this.image;
    final title = this.title;
    final description = this.description;
    final positiveButton = this.positiveButton;
    final negativeButton = this.negativeButton;
    //
    return AppPadding.regular(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIconButton(
            icon: theme.icons.characters.crossDefault,
            padding: const AppEdgeInsets.only(),
            onTap: closeCallback,
          ),
          if (image != null) ...[
            const AppGap.big(),
            Center(
              child: Image(
                image: image,
                height: 250,
                fit: BoxFit.fitHeight,
              ),
            ),
          ],
          if (title != null || description != null) const AppGap.big(),
          if (title != null) AppText.screenName(title),
          if (title != null && description != null) const AppGap.regular(),
          if (description != null) AppText.descriptionMain(description, color: ConstantColors.tertiaryTextGray,),
          if (positiveButton != null || negativeButton != null)
            const AppGap.big(),
          if (positiveButton != null)
            AppPrimaryButton(
              positiveButton.text,
              onTap: positiveButton.onClicked,
            ),
          if (negativeButton != null)
            AppSecondaryButton(
              negativeButton.text,
              onTap: negativeButton.onClicked,
            ),
        ],
      ),
    );
  }
}
