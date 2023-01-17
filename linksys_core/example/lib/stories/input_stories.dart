part of '../storybook.dart';

Iterable<Story> inputStories() {
  TextEditingController controller = TextEditingController();
  TextEditingController errorStyleController = TextEditingController();
  errorStyleController.text = 'johndoe@gmailcom';
  TextEditingController approvedStyleController = TextEditingController();
  TextEditingController filledStyleController = TextEditingController();
  filledStyleController.text = 'johndoe@gmailcom';
  TextEditingController errorFilledStyleController = TextEditingController();
  errorFilledStyleController.text = 'johndoe@gmailcom';
  return [
    Story(
      name: 'Input/Pin code input',
      description: 'A custom Text widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPinCodeInput(
              length: 4,
              onChanged: (value) {},
              onCompleted: (value) {},
            ),
            AppPinCodeInput(
              length: 4,
              enabled: false,
              onChanged: (value) {},
              onCompleted: (value) {},
            ),
            const AppGap.big(),
          ],
        ),
      ),
    ),
    Story(
      name: 'Input/Search bar',
      description: 'A custom search bar widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSearchBar(
              hint: 'Search',
            ),
          ],
        ),
      ),
    ),
    Story(
      name: 'Input/Input field - Default',
      description: 'A custom Text widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textFieldDisplay(
              'basic',
              LinksysInputField(
                controller: controller,
                hintText: 'Email or phone number',
              ),
            ),
            _textFieldDisplay(
              'w/ icon',
              LinksysInputField(
                controller: controller,
                hintText: 'Email or phone number',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
              ),
            ),
            _textFieldDisplay(
              'w/ header',
              LinksysInputField(
                controller: controller,
                hintText: 'Email or phone number',
                headerText: 'Password',
              ),
            ),
            _textFieldDisplay(
              'w/ header and icon',
              LinksysInputField(
                controller: controller,
                hintText: 'Email or phone number',
                headerText: 'Password',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
              ),
            ),
            _textFieldDisplay(
              'w/ header, link and icon',
              LinksysInputField(
                controller: controller,
                hintText: 'Email or phone number',
                headerText: 'Password',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
              ),
            ),
            _textFieldDisplay(
              'w/ header and link',
              LinksysInputField(
                controller: controller,
                hintText: 'Email or phone number',
                headerText: 'Password',
                ctaText: 'CTA Text',
                onCtaTap: () {},
              ),
            ),
            _textFieldDisplay(
              'w/ subheader and link',
              LinksysInputField(
                controller: controller,
                hintText: 'Email or phone number',
                headerText: 'Header',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                useSubHeader: true,
              ),
            ),
            _textFieldDisplay(
              'w/ subheader',
              LinksysInputField(
                controller: controller,
                hintText: 'Email or phone number',
                headerText: 'Header',
                useSubHeader: true,
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader',
              LinksysInputField.small(
                controller: controller,
                hintText: 'Content',
                headerText: 'Header',
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader and text',
              LinksysInputField.small(
                controller: controller,
                hintText: 'Content',
                headerText: 'Header',
                descriptionText: 'text here',
              ),
            ),
          ],
        ),
      ),
    ),
    Story(
      name: 'Input/Input field - Error - Flavor Text',
      description: 'A custom Text widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textFieldDisplay(
              'basic',
              LinksysInputField(
                controller: errorStyleController,
                hintText: 'Email or phone number',
                errorText: 'Invalid email address',
              ),
            ),
            _textFieldDisplay(
              'w/ icon',
              LinksysInputField(
                controller: errorStyleController,
                hintText: 'Email or phone number',
                errorText: 'Invalid email address',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
              ),
            ),
            _textFieldDisplay(
              'w/ header',
              LinksysInputField(
                controller: errorStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                errorText: 'Invalid email address',
              ),
            ),
            _textFieldDisplay(
              'w/ header and icon',
              LinksysInputField(
                controller: errorStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                errorText: 'Invalid email address',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
              ),
            ),
            _textFieldDisplay(
              'w/ header, link and icon',
              LinksysInputField(
                controller: errorStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                errorText: 'Invalid email address',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
              ),
            ),
            _textFieldDisplay(
              'w/ header and link',
              LinksysInputField(
                controller: errorStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                errorText: 'Invalid email address',
                ctaText: 'CTA Text',
                onCtaTap: () {},
              ),
            ),
            _textFieldDisplay(
              'w/ subheader and link',
              LinksysInputField(
                controller: errorStyleController,
                hintText: 'Email or phone number',
                headerText: 'Header',
                errorText: 'Invalid email address',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                useSubHeader: true,
              ),
            ),
            _textFieldDisplay(
              'w/ subheader',
              LinksysInputField(
                controller: errorStyleController,
                hintText: 'Email or phone number',
                headerText: 'Header',
                errorText: 'Invalid email address',
                useSubHeader: true,
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader',
              LinksysInputField.small(
                controller: errorStyleController,
                hintText: 'Content',
                headerText: 'Header',
                errorText: 'Invalid email address',
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader and text',
              LinksysInputField.small(
                controller: errorStyleController,
                hintText: 'Content',
                headerText: 'Header',
                errorText: 'Invalid email address',
                descriptionText: 'text here',
              ),
            ),
          ],
        ),
      ),
    ),
    Story(
      name: 'Input/Input field - Approved - Filled Input Field with Flavor Text',
      description: 'A custom Text widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textFieldDisplay(
              'basic',
              LinksysInputField(
                controller: approvedStyleController,
                hintText: 'Email or phone number',
                approvedText: 'Promo code applied',
              ),
            ),
            _textFieldDisplay(
              'w/ icon',
              LinksysInputField(
                controller: approvedStyleController,
                hintText: 'Email or phone number',
                approvedText: 'Promo code applied',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
              ),
            ),
            _textFieldDisplay(
              'w/ header',
              LinksysInputField(
                controller: approvedStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                approvedText: 'Promo code applied',
              ),
            ),
            _textFieldDisplay(
              'w/ header and icon',
              LinksysInputField(
                controller: approvedStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                approvedText: 'Promo code applied',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
              ),
            ),
            _textFieldDisplay(
              'w/ header, link and icon',
              LinksysInputField(
                controller: approvedStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                approvedText: 'Promo code applied',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
              ),
            ),
            _textFieldDisplay(
              'w/ header and link',
              LinksysInputField(
                controller: approvedStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                approvedText: 'Promo code applied',
                ctaText: 'CTA Text',
                onCtaTap: () {},
              ),
            ),
            _textFieldDisplay(
              'w/ subheader and link',
              LinksysInputField(
                controller: approvedStyleController,
                hintText: 'Email or phone number',
                headerText: 'Header',
                approvedText: 'Promo code applied',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                useSubHeader: true,
              ),
            ),
            _textFieldDisplay(
              'w/ subheader',
              LinksysInputField(
                controller: approvedStyleController,
                hintText: 'Email or phone number',
                headerText: 'Header',
                approvedText: 'Promo code applied',
                useSubHeader: true,
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader',
              LinksysInputField.small(
                controller: approvedStyleController,
                hintText: 'Content',
                headerText: 'Header',
                approvedText: 'Promo code applied',
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader and text',
              LinksysInputField.small(
                controller: approvedStyleController,
                hintText: 'Content',
                headerText: 'Header',
                approvedText: 'Promo code applied',
                descriptionText: 'text here',
              ),
            ),
          ],
        ),
      ),
    ),
    Story(
      name: 'Input/Input field - Filled',
      description: 'A custom Text widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textFieldDisplay(
              'basic',
              LinksysInputField(
                controller: filledStyleController,
                hintText: 'Email or phone number',
                enable: false,
              ),
            ),
            _textFieldDisplay(
              'w/ icon',
              LinksysInputField(
                controller: filledStyleController,
                hintText: 'Email or phone number',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
                enable: false,
              ),
            ),
            _textFieldDisplay(
              'w/ header',
              LinksysInputField(
                controller: filledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                enable: false,
              ),
            ),
            _textFieldDisplay(
              'w/ header and icon',
              LinksysInputField(
                controller: filledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
                enable: false,
              ),
            ),
            _textFieldDisplay(
              'w/ header, link and icon',
              LinksysInputField(
                controller: filledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
                enable: false,
              ),
            ),
            _textFieldDisplay(
              'w/ header and link',
              LinksysInputField(
                controller: filledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                enable: false,
              ),
            ),
            _textFieldDisplay(
              'w/ subheader and link',
              LinksysInputField(
                controller: filledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Header',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                useSubHeader: true,
                enable: false,
              ),
            ),
            _textFieldDisplay(
              'w/ subheader',
              LinksysInputField(
                controller: filledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Header',
                useSubHeader: true,
                enable: false,
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader',
              LinksysInputField.small(
                controller: filledStyleController,
                hintText: 'Content',
                headerText: 'Header',
                enable: false,
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader and text',
              LinksysInputField.small(
                controller: filledStyleController,
                hintText: 'Content',
                headerText: 'Header',
                descriptionText: 'text here',
                enable: false,
              ),
            ),
          ],
        ),
      ),
    ),
    Story(
      name: 'Input/Input field - Error - Filled Input Field',
      description: 'A custom Text widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _textFieldDisplay(
              'basic',
              LinksysInputField(
                controller: errorFilledStyleController,
                hintText: 'Email or phone number',
                textValidator: _validator,
              ),
            ),
            _textFieldDisplay(
              'w/ icon',
              LinksysInputField(
                controller: errorFilledStyleController,
                hintText: 'Email or phone number',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
                textValidator: _validator,
              ),
            ),
            _textFieldDisplay(
              'w/ header',
              LinksysInputField(
                controller: errorFilledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                textValidator: _validator,
              ),
            ),
            _textFieldDisplay(
              'w/ header and icon',
              LinksysInputField(
                controller: errorFilledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
                textValidator: _validator,
              ),
            ),
            _textFieldDisplay(
              'w/ header, link and icon',
              LinksysInputField(
                controller: errorFilledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                suffixIcon: AppIconButton.noPadding(
                  icon: AppTheme.of(context).icons.characters.helpRound,
                  onTap: () {},
                ),
                textValidator: _validator,
              ),
            ),
            _textFieldDisplay(
              'w/ header and link',
              LinksysInputField(
                controller: errorFilledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Password',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                textValidator: _validator,
              ),
            ),
            _textFieldDisplay(
              'w/ subheader and link',
              LinksysInputField(
                controller: errorFilledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Header',
                ctaText: 'CTA Text',
                onCtaTap: () {},
                useSubHeader: true,
                textValidator: _validator,
              ),
            ),
            _textFieldDisplay(
              'w/ subheader',
              LinksysInputField(
                controller: errorFilledStyleController,
                hintText: 'Email or phone number',
                headerText: 'Header',
                useSubHeader: true,
                textValidator: _validator,
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader',
              LinksysInputField.small(
                controller: errorFilledStyleController,
                hintText: 'Content',
                headerText: 'Header',
                textValidator: _validator,
              ),
            ),
            _textFieldDisplay(
              'small box w/ subheader and text',
              LinksysInputField.small(
                controller: errorFilledStyleController,
                hintText: 'Content',
                headerText: 'Header',
                descriptionText: 'text here',
                textValidator: _validator,
              ),
            ),
          ],
        ),
      ),
    ),
  ];
}

Widget _textFieldDisplay(String style, LinksysInputField inputField) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText.tags(style),
        const AppGap.semiSmall(),
        inputField,
      ],
    ),
  );
}

bool _validator() => false;
