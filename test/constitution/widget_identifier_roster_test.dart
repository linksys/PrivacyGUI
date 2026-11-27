import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';
import 'package:privacygui_widgets/widgets/buttons/popup_button.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';
import 'package:privacygui_widgets/widgets/card/device_list_card.dart';
import 'package:privacygui_widgets/widgets/card/expansion_card.dart';
import 'package:privacygui_widgets/widgets/card/info_card.dart';
import 'package:privacygui_widgets/widgets/card/information_card.dart';
import 'package:privacygui_widgets/widgets/card/list_card.dart';
import 'package:privacygui_widgets/widgets/card/list_expand_card.dart';
import 'package:privacygui_widgets/widgets/card/node_list_card.dart';
import 'package:privacygui_widgets/widgets/card/selection_card.dart';
import 'package:privacygui_widgets/widgets/card/setting_card.dart';
import 'package:privacygui_widgets/widgets/container/animated_meter.dart';
import 'package:privacygui_widgets/widgets/dialogs/multiple_page_alert_dialog.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_button.dart';
import 'package:privacygui_widgets/widgets/dropdown/dropdown_menu.dart';
import 'package:privacygui_widgets/widgets/fab/expandable_fab.dart';
import 'package:privacygui_widgets/widgets/input_field/ip_form_field.dart';
import 'package:privacygui_widgets/widgets/input_field/ipv6_form_field.dart';
import 'package:privacygui_widgets/widgets/input_field/validator_widget.dart';
import 'package:privacygui_widgets/widgets/label/status_label.dart';
import 'package:privacygui_widgets/widgets/label/text_label.dart';
import 'package:privacygui_widgets/widgets/loadable_widget/loadable_widget.dart';
import 'package:privacygui_widgets/widgets/page/layout/tab_layout.dart';
import 'package:privacygui_widgets/widgets/panel/general_expansion.dart';
import 'package:privacygui_widgets/widgets/panel/general_section.dart';
import 'package:privacygui_widgets/widgets/panel/switch_trigger_tile.dart';
import 'package:privacygui_widgets/widgets/progress_bar/full_screen_spinner.dart';
import 'package:privacygui_widgets/widgets/progress_bar/spinner.dart';
import 'package:privacygui_widgets/widgets/radios/radio_list.dart';
import 'package:privacygui_widgets/widgets/semantics/identifier_semantics.dart';
import 'package:privacygui_widgets/widgets/stepper/app_stepper.dart';
import 'package:privacygui_widgets/widgets/table/card_list_settings_view.dart';
import 'package:privacygui_widgets/widgets/table/table_settings_view.dart';
import 'package:privacygui_widgets/widgets/tip/tip.dart';

import '../common/testable_widget.dart';
import 'identifier_scanner.dart';
import 'semantics_identifier.dart';
import 'source_scan.dart';

/// Where the components of `plugins/widgets` are.
const _widgetsLibrary = 'plugins/widgets/lib/widgets';

/// The kinds of component the constitution 11.4 excluded list may name.
const _exclusionKinds = {'animation', 'layout', 'spacing', 'base'};

/// The identifier each constructor is given. A part's identifier replaces
/// `{id}` in its pattern with it.
const _id = 'roster';

/// The steps of the roster's `AppStepper`.
final _steps = [
  const Step(title: Text('A'), content: Text('a')),
  const Step(title: Text('B'), content: Text('b')),
];

/// The trailing control of the roster's `LinksysAppBar`.
final _trailing = [AppIconButton(icon: Icons.settings, onTap: _noop)];

/// A one-pixel transparent PNG, for a component that shows an image.
final _pixel = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

/// The roster (constitution 11.4): every public widget class of
/// `plugins/widgets` that the 11.4 excluded list does not name (issue #1936).
///
/// A constructor that ignores `id` has no identifier parameter yet, and its
/// component has a row in the constitution 11.4 roster table until it gets
/// one, unless its identifiers are fixed ones, as `LinksysAppBar`'s are.
final Map<String, _Component> _roster = {
  'AppTextField': (
    constructors: {
      'AppTextField': (id) =>
          AppTextField(identifier: id, onChanged: _noopValue),
      'AppTextField.outline': (id) =>
          AppTextField.outline(identifier: id, onChanged: _noopValue),
      'AppTextField.macAddress': (id) =>
          AppTextField.macAddress(identifier: id, onChanged: _noopValue),
      'AppTextField.minMaxNumber': (id) => AppTextField.minMaxNumber(
          identifier: id, max: 10, onChanged: _noopValue),
    },
    identifiers: ['{id}'],
  ),
  'AppPasswordField': (
    constructors: {
      'AppPasswordField': (id) =>
          AppPasswordField(identifier: id, onChanged: _noopValue),
      'AppPasswordField.withValidator': (id) => AppPasswordField.withValidator(
            identifier: id,
            onChanged: _noopValue,
            validations: [
              Validation(description: 'Long', validator: (_) => true),
            ],
          ),
    },
    identifiers: ['{id}', '{id}-visibility'],
  ),
  'AppIPFormField': (
    constructors: {
      'AppIPFormField': (id) => AppIPFormField(
            identifier: id,
            controller: TextEditingController(),
            onChanged: _noopValue,
          ),
    },
    identifiers: [for (var i = 0; i < 4; i++) '{id}-octet-$i'],
  ),
  'AppIPv6FormField': (
    constructors: {
      'AppIPv6FormField': (id) =>
          AppIPv6FormField(identifier: id, onChanged: _noopValue),
    },
    identifiers: ['{id}'],
  ),
  'AppPinCodeInput': (
    constructors: {
      'AppPinCodeInput': (id) =>
          AppPinCodeInput(identifier: id, length: 3, onChanged: _noopValue),
    },
    identifiers: ['{id}', for (var i = 0; i < 3; i++) '{id}-cell-$i'],
  ),
  'AppValidatorWidget': (
    constructors: {
      'AppValidatorWidget': (id) => AppValidatorWidget(
            identifier: id,
            textToValidate: 'abc',
            validations: [
              Validation(description: 'Long', validator: (_) => true),
            ],
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppDropdownMenu': (
    constructors: {
      'AppDropdownMenu': (id) => AppDropdownMenu<String>(
            identifier: id,
            items: const ['a', 'b'],
            label: (item) => item,
            itemKey: (item) => item,
            onChanged: _noopValue,
          ),
    },
    // Both are in the open menu only.
    identifiers: ['{id}', '{id}-item-a', '{id}-item-b'],
  ),
  'AppRadioList': (
    constructors: {
      'AppRadioList': (id) => AppRadioList<String>(
            identifier: id,
            items: [
              AppRadioListItem(title: 'A', value: 'a'),
              AppRadioListItem(title: 'B', value: 'b'),
            ],
            initial: 'a',
            itemKey: (value) => value,
            onChanged: (_, __) {},
          ),
    },
    identifiers: ['{id}', '{id}-item-a', '{id}-item-b'],
  ),
  'AppDropdownButton': (
    constructors: {
      'AppDropdownButton': (id) => AppDropdownButton<String>(
            identifier: id,
            items: const ['a', 'b'],
            label: (item) => item,
            itemKey: (item) => item,
            onChanged: _noopValue,
          ),
    },
    // `a` is the selected item, `b` is not. Both are in the open menu only.
    identifiers: ['{id}', '{id}-item-a', '{id}-item-b'],
  ),
  'AppSwitch': (
    constructors: {
      'AppSwitch': (id) =>
          AppSwitch(identifier: id, value: true, onChanged: _noopValue),
      'AppSwitch.withIcon': (id) => AppSwitch.withIcon(
          identifier: id, value: true, onChanged: _noopValue),
    },
    identifiers: ['{id}'],
  ),
  'AppIconButton': (
    constructors: {
      'AppIconButton': (id) =>
          AppIconButton(icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.noPadding': (id) => AppIconButton.noPadding(
          icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.filled': (id) =>
          AppIconButton.filled(icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.noPaddingFilled': (id) => AppIconButton.noPaddingFilled(
          icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.outlined': (id) =>
          AppIconButton.outlined(icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.noPaddingOutlined': (id) =>
          AppIconButton.noPaddingOutlined(
              icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.tonal': (id) =>
          AppIconButton.tonal(icon: Icons.add, identifier: id, onTap: _noop),
      'AppIconButton.noPaddingTonal': (id) => AppIconButton.noPaddingTonal(
          icon: Icons.add, identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppTextButton': (
    constructors: {
      'AppTextButton': (id) =>
          AppTextButton('Save', identifier: id, onTap: _noop),
      'AppTextButton.noPadding': (id) =>
          AppTextButton.noPadding('Save', identifier: id, onTap: _noop),
      'AppTextButton.fillWidth': (id) =>
          AppTextButton.fillWidth('Save', identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppFilledButton': (
    constructors: {
      'AppFilledButton': (id) =>
          AppFilledButton('Save', identifier: id, onTap: _noop),
      'AppFilledButton.fillWidth': (id) =>
          AppFilledButton.fillWidth('Save', identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppElevatedButton': (
    constructors: {
      'AppElevatedButton': (id) =>
          AppElevatedButton('Save', identifier: id, onTap: _noop),
      'AppElevatedButton (icon)': (id) => AppElevatedButton('Save',
          icon: Icons.add, identifier: id, onTap: _noop),
      'AppElevatedButton.fillWidth': (id) =>
          AppElevatedButton.fillWidth('Save', identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppTonalButton': (
    constructors: {
      'AppTonalButton': (id) =>
          AppTonalButton('Save', identifier: id, onTap: _noop),
      'AppTonalButton (icon)': (id) =>
          AppTonalButton('Save', icon: Icons.add, identifier: id, onTap: _noop),
      'AppTonalButton.fillWidth': (id) =>
          AppTonalButton.fillWidth('Save', identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppOutlinedButton': (
    constructors: {
      'AppOutlinedButton': (id) =>
          AppOutlinedButton('Save', identifier: id, onTap: _noop),
      'AppOutlinedButton (icon)': (id) => AppOutlinedButton('Save',
          icon: Icons.add, identifier: id, onTap: _noop),
      'AppOutlinedButton.fillWidth': (id) =>
          AppOutlinedButton.fillWidth('Save', identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppFilledButtonWithLoading': (
    constructors: {
      'AppFilledButtonWithLoading': (id) =>
          AppFilledButtonWithLoading('Save', identifier: id, onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppIconToggleButton': (
    constructors: {
      'AppIconToggleButton': (id) => AppIconToggleButton(
            icon1: Icons.add,
            icon2: Icons.remove,
            identifier: id,
            onTap: _noopValue,
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppPopupButton': (
    constructors: {
      // A borderRadius, which keeps initState from reading the theme.
      'AppPopupButton': (id) => AppPopupButton(
            identifier: id,
            borderRadius: BorderRadius.zero,
            button: const AppText('Open'),
            builder: (_) => const AppText('Item'),
          ),
    },
    identifiers: ['{id}', '{id}-menu'],
  ),
  'AppCard': (
    constructors: {
      'AppCard': (id) => AppCard(
            identifier: id,
            onTap: _noop,
            child: const AppText('Card'),
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppInfoCard': (
    constructors: {
      'AppInfoCard': (id) =>
          AppInfoCard(identifier: id, title: 'Card', onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppInformationCard': (
    constructors: {
      'AppInformationCard': (id) =>
          AppInformationCard(identifier: id, title: 'Card'),
    },
    identifiers: ['{id}'],
  ),
  'AppListExpandCard': (
    constructors: {
      'AppListExpandCard': (id) => AppListExpandCard(
          identifier: id, title: const AppText('Card'), onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppSelectionCard': (
    constructors: {
      'AppSelectionCard': (id) => AppSelectionCard<String>(
            identifier: id,
            title: 'Card',
            description: 'Description',
            value: 'a',
            groupValue: 'b',
            onTap: _noop,
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppExpansionCard': (
    constructors: {
      'AppExpansionCard': (id) => AppExpansionCard(
            identifier: id,
            title: 'Card',
            children: const [AppText('Content')],
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppDeviceListCard': (
    constructors: {
      'AppDeviceListCard': (id) => AppDeviceListCard(
            identifier: id,
            leading: Icons.devices,
            title: 'Device',
            trailing: null,
            onTap: _noop,
            onSelected: _noopValue,
          ),
    },
    identifiers: ['{id}', '{id}-select'],
  ),
  'AppNodeListCard': (
    constructors: {
      'AppNodeListCard': (id) => AppNodeListCard(
            identifier: id,
            leading: MemoryImage(_pixel),
            title: 'Node',
            trailing: null,
            onTap: _noop,
            onSelected: _noopValue,
          ),
    },
    identifiers: ['{id}', '{id}-select'],
  ),
  'AppCheckbox': (
    constructors: {
      'AppCheckbox': (id) =>
          AppCheckbox(identifier: id, value: true, onChanged: _noopValue),
      'AppCheckbox (text)': (id) => AppCheckbox(
          identifier: id, value: true, text: 'Agree', onChanged: _noopValue),
    },
    identifiers: ['{id}'],
  ),
  'AppListCard': (
    constructors: {
      'AppListCard': (id) => AppListCard(
          identifier: id, title: const AppText('Card'), onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppSettingCard': (
    constructors: {
      'AppSettingCard': (id) =>
          AppSettingCard(identifier: id, title: 'Card', onTap: _noop),
      'AppSettingCard.noBorder': (id) =>
          AppSettingCard.noBorder(identifier: id, title: 'Card', onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppText': (
    constructors: {
      'AppText': (id) => AppText('Text', identifier: id),
      // A selectable text is a read-only text field to the engine.
      'AppText (selectable)': (id) =>
          AppText('Text', identifier: id, selectable: true),
      'AppText.displayLarge': (id) =>
          AppText.displayLarge('Text', identifier: id),
      'AppText.displayMedium': (id) =>
          AppText.displayMedium('Text', identifier: id),
      'AppText.displaySmall': (id) =>
          AppText.displaySmall('Text', identifier: id),
      'AppText.headlineLarge': (id) =>
          AppText.headlineLarge('Text', identifier: id),
      'AppText.headlineMedium': (id) =>
          AppText.headlineMedium('Text', identifier: id),
      'AppText.headlineSmall': (id) =>
          AppText.headlineSmall('Text', identifier: id),
      'AppText.titleLarge': (id) => AppText.titleLarge('Text', identifier: id),
      'AppText.titleMedium': (id) =>
          AppText.titleMedium('Text', identifier: id),
      'AppText.titleSmall': (id) => AppText.titleSmall('Text', identifier: id),
      'AppText.labelLarge': (id) => AppText.labelLarge('Text', identifier: id),
      'AppText.labelMedium': (id) =>
          AppText.labelMedium('Text', identifier: id),
      'AppText.labelSmall': (id) => AppText.labelSmall('Text', identifier: id),
      'AppText.bodyLarge': (id) => AppText.bodyLarge('Text', identifier: id),
      'AppText.bodyMedium': (id) => AppText.bodyMedium('Text', identifier: id),
      'AppText.bodySmall': (id) => AppText.bodySmall('Text', identifier: id),
      'AppText.bodyExtraSmall': (id) =>
          AppText.bodyExtraSmall('Text', identifier: id),
    },
    identifiers: ['{id}'],
  ),
  'AppStatusLabel': (
    constructors: {
      'AppStatusLabel': (id) => AppStatusLabel(identifier: id),
    },
    identifiers: ['{id}'],
  ),
  'AppLabelText': (
    constructors: {
      'AppLabelText': (id) => AppLabelText(identifier: id, label: 'Beta'),
    },
    identifiers: ['{id}'],
  ),
  'AppStyledText': (
    constructors: {
      'AppStyledText': (id) => AppStyledText(
            'Read <a>this</a>',
            identifier: id,
            styleTags: const {},
            callbackTags: {'a': (_, __) {}},
          ),
      'AppStyledText.bold': (id) => AppStyledText.bold(
            'Read <b>this</b>',
            identifier: id,
            defaultTextStyle: const TextStyle(),
            tags: const ['b'],
          ),
      'AppStyledText.link': (id) => AppStyledText.link(
            'Read <a>this</a>',
            identifier: id,
            defaultTextStyle: const TextStyle(),
            tags: const ['a'],
            callbackTags: {'a': (_, __) {}},
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppSectionLabel': (
    constructors: {
      'AppSectionLabel': (id) =>
          AppSectionLabel(identifier: id, label: 'Section'),
    },
    identifiers: ['{id}'],
  ),
  'AppTips': (
    constructors: {
      'AppTips': (id) => AppTips(
            identifier: id,
            tips: 'Tip',
            showTips: true,
            child: const AppText('Child'),
          ),
    },
    identifiers: ['{id}'],
  ),
  'AnimatedMeter': (
    constructors: {
      'AnimatedMeter': (id) => AnimatedMeter(
            identifier: id,
            value: 50,
            centerBuilder: (_, value) => AppText('$value'),
          ),
      'AnimatedMeter.withDefaultMarks': (id) => AnimatedMeter.withDefaultMarks(
            identifier: id,
            value: 50,
            centerBuilder: (_, value) => AppText('$value'),
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppSpinner': (
    constructors: {
      'AppSpinner': (id) => AppSpinner(identifier: id),
    },
    identifiers: ['{id}'],
  ),
  'AppProgressBar': (
    constructors: {
      'AppProgressBar': (id) => AppProgressBar(identifier: id),
      'AppProgressBar (circular)': (id) =>
          AppProgressBar(identifier: id, style: AppProgressBarStyle.circular),
    },
    identifiers: ['{id}'],
  ),
  'AppSimplePanel': (
    constructors: {
      'AppSimplePanel': (id) =>
          AppSimplePanel(identifier: id, title: 'Panel', onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppPanelWithValueCheck': (
    constructors: {
      'AppPanelWithValueCheck': (id) => AppPanelWithValueCheck(
          identifier: id, title: 'Panel', valueText: 'On', isChecked: true),
    },
    identifiers: ['{id}'],
  ),
  'AppSwitchTriggerTile': (
    constructors: {
      'AppSwitchTriggerTile': (id) => AppSwitchTriggerTile(
            identifier: id,
            title: const AppText('Tile'),
            value: true,
            onChanged: _noopValue,
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppExpansion': (
    constructors: {
      'AppExpansion': (id) => AppExpansion(
          identifier: id, title: 'Expansion', children: const [AppText('A')]),
    },
    identifiers: ['{id}'],
  ),
  'AppTabBar': (
    constructors: {
      'AppTabBar': (id) => DefaultTabController(
            length: 2,
            child: AppTabBar(
              identifier: id,
              tabs: const [Tab(text: 'A'), Tab(text: 'B')],
              tabKeys: const ['a', 'b'],
            ),
          ),
    },
    identifiers: ['{id}', '{id}-tab-a', '{id}-tab-b'],
  ),
  'AppTabLayout': (
    constructors: {
      'AppTabLayout': (id) => AppTabLayout(
            identifier: id,
            tabs: const [Tab(text: 'A'), Tab(text: 'B')],
            tabKeys: const ['a', 'b'],
            tabContentViews: const [AppText('a'), AppText('b')],
          ),
    },
    identifiers: ['{id}', '{id}-tab-a', '{id}-tab-b'],
  ),
  'AppStepper': (
    constructors: {
      'AppStepper': (id) => AppStepper(
            identifier: id,
            steps: _steps,
            stepKeys: const ['a', 'b'],
            onStepContinue: _noop,
            onStepCancel: _noop,
          ),
      'AppStepper (horizontal)': (id) => AppStepper(
            identifier: id,
            type: StepperType.horizontal,
            steps: _steps,
            stepKeys: const ['a', 'b'],
            onStepContinue: _noop,
            onStepCancel: _noop,
          ),
    },
    identifiers: [
      '{id}',
      '{id}-step-a',
      '{id}-step-b',
      '{id}-continue',
      '{id}-cancel',
    ],
  ),
  'MultiplePagesAlertDialog': (
    constructors: {
      'MultiplePagesAlertDialog': (id) => MultiplePagesAlertDialog(
            identifier: id,
            pages: [
              MultipleAlertDialogPage(
                title: 'Page',
                buttonText: 'Close',
                contentBuilder: (_, __, ___) => const AppText('Content'),
              ),
            ],
          ),
    },
    identifiers: ['{id}', '{id}-action'],
  ),
  'ExpandableFab': (
    constructors: {
      'ExpandableFab': (id) => ExpandableFab(
            identifier: id,
            distance: 100,
            icon: Icons.add,
            children: const [
              ActionButton(icon: Icon(Icons.edit)),
              ActionButton(icon: Icon(Icons.delete)),
            ],
          ),
    },
    identifiers: ['{id}', '{id}-close'],
  ),
  'ActionButton': (
    constructors: {
      'ActionButton': (id) => ActionButton(
          identifier: id, icon: const Icon(Icons.edit), onPressed: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppSlideActionContainer': (
    constructors: {
      'AppSlideActionContainer': (id) => AppSlideActionContainer(
            identifier: id,
            rightMenuItems: [
              AppMenuItem(label: 'Delete', identifier: '$id-delete'),
            ],
            child: const AppText('Row'),
          ),
    },
    // `{id}-delete` is the item's own, which the container passes on.
    identifiers: ['{id}', '{id}-delete'],
  ),
  'AppSliderMenuItem': (
    constructors: {
      'AppSliderMenuItem': (id) =>
          AppSliderMenuItem(identifier: id, label: 'Delete', onTap: _noop),
    },
    identifiers: ['{id}'],
  ),
  'AppLoadableWidget': (
    constructors: {
      'AppLoadableWidget': (id) => AppLoadableWidget(
          identifier: id,
          type: LoadableWidgetType.textButton,
          title: 'Save',
          onTap: _noopAsync),
      'AppLoadableWidget.elevatedButton': (id) =>
          AppLoadableWidget.elevatedButton(
              identifier: id, title: 'Save', onTap: _noopAsync),
      'AppLoadableWidget.filledButton': (id) => AppLoadableWidget.filledButton(
          identifier: id, title: 'Save', onTap: _noopAsync),
      'AppLoadableWidget.outlineButton': (id) =>
          AppLoadableWidget.outlineButton(
              identifier: id, title: 'Save', onTap: _noopAsync),
      'AppLoadableWidget.textButton': (id) => AppLoadableWidget.textButton(
          identifier: id, title: 'Save', onTap: _noopAsync),
      'AppLoadableWidget.appSwitch': (id) => AppLoadableWidget.appSwitch(
          identifier: id, value: true, onChanged: (_, __) async {}),
    },
    identifiers: ['{id}'],
  ),
  'AppCardListSettingsView': (
    constructors: {
      'AppCardListSettingsView': (id) => AppCardListSettingsView<String>(
            identifier: id,
            dataList: const ['a'],
            itemCardBuilder: (_, item) => AppText(item),
          ),
    },
    identifiers: ['{id}'],
  ),
  'AppTableSettingsView': (
    constructors: {
      'AppTableSettingsView': (id) => AppTableSettingsView<String>(
            identifier: id,
            headers: const ['Name'],
            dataList: const ['a'],
            cellBuilder: (_, __, item) => AppText(item),
          ),
      // A table cell makes no node of its own, so a text field in it, which
      // has no identifier, would merge into the table's.
      'AppTableSettingsView (text field)': (id) => AppTableSettingsView<String>(
            identifier: id,
            headers: const ['Name'],
            dataList: const ['a'],
            cellBuilder: (_, __, ___) => const TextField(),
          ),
    },
    identifiers: ['{id}'],
  ),
  // Its identifiers are the page's, the same on every page: it takes none.
  'LinksysAppBar': (
    constructors: {
      'LinksysAppBar': (_) =>
          LinksysAppBar(title: const AppText('Title'), trailing: _trailing),
      'LinksysAppBar.withBack': (_) => Builder(
            builder: (context) => LinksysAppBar.withBack(
              context: context,
              title: const AppText('Title'),
              trailing: _trailing,
              onBackTap: _noop,
            ),
          ),
      'LinksysAppBar.withClose': (_) => Builder(
            builder: (context) => LinksysAppBar.withClose(
              context: context,
              title: const AppText('Title'),
              trailing: _trailing,
              onBackTap: _noop,
            ),
          ),
    },
    identifiers: ['page-title', 'page-trailing', 'page-back', 'page-close'],
  ),
  'IdentifierSemantics': (
    constructors: {
      'IdentifierSemantics': (id) => IdentifierSemantics(
          identifier: id, child: AppTextButton('Save', onTap: _noop)),
      'IdentifierSemantics.textField': (id) => IdentifierSemantics.textField(
          identifier: id, child: const TextField()),
    },
    identifiers: ['{id}'],
  ),
  'AppFullScreenSpinner': (
    constructors: {
      'AppFullScreenSpinner': (id) => AppFullScreenSpinner(identifier: id),
    },
    identifiers: ['{id}'],
  ),
};

/// The constructors that build a part, keyed as the rows of the 11.4 roster table
/// are: `<component> -> <pattern>`. The other constructors of the component
/// do not build it, and the roster does not look for it there.
const Map<String, Set<String>> _onlyFrom = {
  'LinksysAppBar -> page-back': {'LinksysAppBar.withBack'},
  'LinksysAppBar -> page-close': {'LinksysAppBar.withClose'},
};

/// What the roster does before it looks for an identifier that a component
/// shows only after an interaction, keyed as the rows of the 11.4 roster table are:
/// `<component> -> <pattern>`.
final Map<String, Future<void> Function(WidgetTester tester)> _reveal = {
  'AppDropdownButton -> {id}-item-a': _tapAndSettle(_dropdownButton),
  'AppDropdownButton -> {id}-item-b': _tapAndSettle(_dropdownButton),
  'AppPopupButton -> {id}-menu': _tapAndSettle(find.text('Open')),
  'AppDropdownMenu -> {id}-item-a': _tapAndSettle(_dropdownMenu),
  'AppDropdownMenu -> {id}-item-b': _tapAndSettle(_dropdownMenu),
  'AppSlideActionContainer -> {id}-delete': _slideOpen,
};

final _dropdownButton = find.byType(AppDropdownButton<String>);

final _dropdownMenu = find.byType(AppDropdownMenu<String>);

/// Slides the roster's `AppSlideActionContainer` open, to its right menu.
Future<void> _slideOpen(WidgetTester tester) async {
  await tester.drag(find.text('Row'), const Offset(-300, 0));
  await tester.pumpAndSettle();
}

/// Taps what [finder] finds, and lets what it opens settle.
Future<void> Function(WidgetTester tester) _tapAndSettle(Finder finder) =>
    (tester) async {
      await tester.tap(finder);
      await tester.pumpAndSettle();
    };

/// A component of `plugins/widgets` that the roster pumps: each public
/// constructor, given an identifier, and the identifiers the component
/// exposes for it, as patterns over `{id}`.
typedef _Component = ({
  Map<String, Widget Function(String id)> constructors,
  List<String> identifiers,
});

void _noop() {}

Future<void> _noopAsync(Object? _) async {}

void _noopValue(Object? _) {}

/// Holds `plugins/widgets` to `constitution.md` 11.4: every identifier of every
/// component in the roster reaches the DOM, from every constructor, except for
/// the rows of the roster table in 11.4, and every public widget class is in
/// the roster or on the excluded list.
void main() {
  final constitution = File('constitution.md').readAsStringSync();
  final listed = readExceptionTable(constitution, 'identifier-roster');
  final excluded = {
    for (final row in readExceptionRows(constitution, 'identifier-excluded'))
      row.from: row.to,
  };

  for (final MapEntry(key: component, value: (:constructors, :identifiers))
      in _roster.entries) {
    for (final pattern in identifiers) {
      final row = '$component -> $pattern';
      testWidgets('$component exposes $pattern where the web engine writes it',
          (tester) async {
        final semantics = tester.ensureSemantics();
        final identifier = pattern.replaceAll('{id}', _id);
        final problems = <String>[];
        for (final MapEntry(key: constructor, value: build)
            in constructors.entries) {
          if (_onlyFrom[row]?.contains(constructor) == false) continue;
          await tester.pumpWidget(testableWidget(child: build(_id)));
          await tester.pump();
          await _reveal[row]?.call(tester);
          final problem = identifierProblem(tester, identifier);
          if (problem != null) problems.add('$constructor: $problem');
        }
        // Before any expect: flutter_test checks for a live handle before
        // tear-down runs.
        semantics.dispose();

        if (listed.contains(row)) {
          expect(problems, isNotEmpty,
              reason:
                  'The row `$row` of the constitution.md 11.4 roster table no '
                  'longer matches: every constructor of $component exposes '
                  '$pattern now. Delete the row.');
        } else {
          expect(problems, isEmpty,
              reason: '$component breaks constitution.md 11.4 and has no row '
                  'for $pattern in its table:\n'
                  '${problems.map((p) => '  - $p').join('\n')}\n'
                  'Put the identifier on a node of its own (11.4). Adding a '
                  'row instead is an amendment (Article IX).');
        }
      });
    }
  }

  test('every row of the constitution.md 11.4 roster table is in the roster',
      () {
    final rostered = {
      for (final MapEntry(
            key: component,
            value: (:identifiers, constructors: _)
          ) in _roster.entries)
        for (final pattern in identifiers) '$component -> $pattern',
    };
    final stale = listed.difference(rostered);

    expect(stale, isEmpty,
        reason: 'These rows of the constitution.md 11.4 roster table name no '
            'component and identifier in the roster. Delete them:\n'
            '${bulletList(stale)}');
  });

  group('the roster covers plugins/widgets', () {
    late Set<String> widgets;

    setUpAll(() => widgets = widgetClassesIn(
          dartSources(_widgetsLibrary),
          bases: {'Widget', ...flutterWidgetClasses()},
        ));

    test('every public widget class is in the roster or the excluded list', () {
      final unlisted = widgets.difference({..._roster.keys, ...excluded.keys});

      expect(unlisted, isEmpty,
          reason: 'These public widget classes of $_widgetsLibrary are '
              'neither in the roster nor on the constitution.md 11.4 '
              'excluded list:\n${bulletList(unlisted)}\n'
              'Add each to the roster, with every public constructor and the '
              'identifiers it exposes (11.4). Excluding one instead is an '
              'amendment (Article IX).');
    });

    test('the roster and the excluded list name public widget classes', () {
      final unknown = {..._roster.keys, ...excluded.keys}.difference(widgets);

      expect(unknown, isEmpty,
          reason: 'These are in the roster or on the constitution.md 11.4 '
              'excluded list, but $_widgetsLibrary has no public widget class '
              'of that name. Delete them:\n${bulletList(unknown)}');
    });

    test('no component is both in the roster and on the excluded list', () {
      final both = _roster.keys.toSet().intersection(excluded.keys.toSet());

      expect(both, isEmpty,
          reason: 'These pass the roster, so they are not excluded. Delete '
              'their rows from the constitution.md 11.4 excluded list:\n'
              '${bulletList(both)}');
    });

    test('each excluded component is of a kind that 11.4 excludes', () {
      final misfiled = {
        for (final MapEntry(key: component, value: kind) in excluded.entries)
          if (!_exclusionKinds.contains(kind)) '$component -> $kind',
      };

      expect(misfiled, isEmpty,
          reason: 'constitution.md 11.4 excludes only these kinds of '
              'component: ${_exclusionKinds.join(', ')}. These rows name '
              'another:\n${bulletList(misfiled)}');
    });
  });
}
