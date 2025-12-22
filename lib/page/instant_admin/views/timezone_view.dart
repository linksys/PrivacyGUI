import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/localization/localization_hook.dart';
import 'package:privacy_gui/page/components/mixin/page_snackbar_mixin.dart';
import 'package:privacy_gui/page/components/shortcuts/dialogs.dart';
import 'package:privacy_gui/page/instant_admin/providers/timezone_provider.dart';
import 'package:privacy_gui/page/components/ui_kit_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacy_gui/util/timezone.dart';
import 'package:ui_kit_library/ui_kit.dart';

class TimezoneView extends ArgumentsConsumerStatefulView {
  const TimezoneView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<TimezoneView> createState() => _TimezoneContentViewState();
}

class _TimezoneContentViewState extends ConsumerState<TimezoneView>
    with PageSnackbarMixin {
  late final TimezoneNotifier _notifier;

  @override
  void initState() {
    super.initState();

    _notifier = ref.read(timezoneProvider.notifier);
    doSomethingWithSpinner(
      context,
      _notifier.fetch(),
    ).onError((error, stackTrace) {
      showErrorMessageSnackBar(error);
      return null;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(timezoneProvider);
    return UiKitPageView.withSliver(
      title: loc(context).timezone,
      onBackTap: _notifier.isDirty()
          ? () async {
              final goBack = await showUnsavedAlert(context);
              if (goBack == true) {
                _notifier.revert();
                context.pop();
              }
            }
          : null,
      bottomBar: UiKitBottomBarConfig(
          isPositiveEnabled: _notifier.isDirty(),
          onPositiveTap: () {
            doSomethingWithSpinner(
              context,
              _notifier.save(),
              title: loc(context).savingChanges,
            ).then((value) {
              if (context.mounted) {
                context.pop(true);
                showChangesSavedSnackBar();
              }
            }).onError((error, stackTrace) {
              showErrorMessageSnackBar(error);
            });
          }),
      child: (context, constraints) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            child: _buildSwitchTile(
              title: loc(context).daylightSavingsTime,
              value: state.settings.current.isDaylightSaving,
              onChanged: _notifier.isSupportDaylightSaving()
                  ? (value) {
                      _notifier.setDaylightSaving(value);
                    }
                  : null,
            ),
          ),
          AppGap.lg(),
          SizedBox(
            height: (70.0) * state.status.supportedTimezones.length +
                17 * (state.status.supportedTimezones.length - 1),
            child: AppCard(
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.status.supportedTimezones.length,
                itemBuilder: (context, index) => ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 70.0),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: _buildListRow(
                        title: getTimeZoneRegionName(context,
                            state.status.supportedTimezones[index].timeZoneID),
                        titleColor: _notifier.isSelectedTimezone(index)
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        description: getTimezoneGMT(
                            state.status.supportedTimezones[index].description),
                        descriptionColor: _notifier.isSelectedTimezone(index)
                            ? Theme.of(context).colorScheme.primary
                            : null,
                        trailing: _notifier.isSelectedTimezone(index)
                            ? AppIcon.font(
                                AppFontIcons.check,
                                color: Theme.of(context).colorScheme.primary,
                              )
                            : null,
                        onTap: () {
                          _notifier.setSelectedTimezone(index);
                        }),
                  ),
                ),
                separatorBuilder: (BuildContext context, int index) {
                  return index != (state.status.supportedTimezones.length - 1)
                      ? const Divider()
                      : const Center();
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Composed SwitchTile
  Widget _buildSwitchTile({
    required String title,
    required bool value,
    void Function(bool)? onChanged,
  }) {
    return Row(
      children: [
        Expanded(child: AppText.labelLarge(title)),
        AppSwitch(
          value: value,
          onChanged: onChanged,
        ),
      ],
    );
  }

  /// Composed ListRow
  Widget _buildListRow({
    required String title,
    Color? titleColor,
    String? description,
    Color? descriptionColor,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.zero,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppText.labelLarge(title, color: titleColor),
                  if (description != null) ...[
                    AppGap.xs(),
                    AppText.bodyMedium(description, color: descriptionColor),
                  ],
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Future<bool?> showUnsavedAlert(BuildContext context,
      {String? title, String? message}) {
    return showMessageAppDialog<bool>(
      context,
      title: title ?? loc(context).unsavedChangesTitle,
      message: message ?? loc(context).unsavedChangesDesc,
      actions: [
        AppButton.text(
          label: loc(context).goBack,
          onTap: () {
            context.pop();
          },
        ),
        AppButton.text(
          label: loc(context).discardChanges,
          onTap: () {
            context.pop(true);
          },
        ),
      ],
    );
  }
}
