import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/content_filter/cubit.dart';
import 'package:linksys_moab/bloc/content_filter/state.dart';
import 'package:linksys_moab/bloc/network/cubit.dart';
import 'package:linksys_moab/bloc/profiles/cubit.dart';
import 'package:linksys_moab/design/colors.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/model/profile_service_data.dart';
import 'package:linksys_moab/model/secure_profile.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/model/content_filter_path.dart';
import 'package:linksys_moab/route/model/_model.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/route/navigations_notifier.dart';
import 'package:linksys_moab/security/security_profile_manager.dart';
import 'package:linksys_moab/util/logger.dart';

import 'component.dart';

class ContentFilteringPresetsView extends ArgumentsConsumerStatefulView {
  const ContentFilteringPresetsView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  ConsumerState<ContentFilteringPresetsView> createState() =>
      _ContentFilteringPresetsViewState();
}

class _ContentFilteringPresetsViewState
    extends ConsumerState<ContentFilteringPresetsView> {
  List<CFSecureProfile> _presets = const [];
  late final String? _profileId;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _profileId = widget.args['profileId'];
    SecurityProfileManager.instance().fetchDefaultPresets().then((value) {
      setState(() {
        _presets = value;
        isLoading = false;
      });
      if (context.read<ContentFilterCubit>().state.selectedSecureProfile ==
          null) {
        context.read<ContentFilterCubit>().selectSecureProfile(_presets[1]);
      }
    });
    setState(() {
      isLoading = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return isLoading
        ? FullScreenSpinner(
            text: getAppLocalizations(context).processing,
          )
        : BlocBuilder<ContentFilterCubit, ContentFilterState>(
            builder: (context, state) {
            return BasePageView.onDashboardSecondary(
              scrollable: true,
              appBar: AppBar(
                automaticallyImplyLeading: false,
                backgroundColor: Colors.transparent,
                elevation: 0,
                title: Text(
                    getAppLocalizations(context).content_filter_presets_title,
                    style:
                        TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                leading: BackButton(onPressed: () {
                  ref.read(navigationsProvider.notifier).pop();
                }),
                actions: [
                  TextButton(
                      onPressed: () {
                        final profileId = _profileId;
                        if (profileId != null) {
                          final networkId =
                              context.read<NetworkCubit>().state.selected!.id;
                          context
                              .read<ProfilesCubit>()
                              .updateContentFilterDetails(
                                profileId,
                                networkId,
                                state.selectedSecureProfile!,
                                state.searchAppSignatureSet,
                              )
                              .then((value) =>
                                  ref.read(navigationsProvider.notifier).pop());
                        } else {
                          logger.e('No profile id');
                        }
                      },
                      child: const Text('Save',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: MoabColor.textButtonBlue))),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  box16(),
                  _presetsSelector(state),
                  box36(),
                  Offstage(
                    offstage: state.selectedSecureProfile == null,
                    child: Column(
                      children: [
                        Text(state.selectedSecureProfile?.description ?? ''),
                        box36(),
                        InkWell(
                          onTap: () {
                            ref
                                .read(navigationsProvider.notifier)
                                .push(CFAppSearchPath());
                          },
                          child: Container(
                            decoration: BoxDecoration(
                                color: MoabColor.dashboardTileBackground),
                            child: Padding(
                              padding: const EdgeInsets.all(16.0),
                              child: Row(
                                children: [
                                  Icon(Icons.search),
                                  Text('Search by app name')
                                ],
                              ),
                            ),
                          ),
                        ),
                        box36(),
                        _secureCategoryList(state),
                      ],
                    ),
                  ),
                  box36(),
                  SimpleTextButton(
                    text: 'Send feedback',
                    onPressed: () {},
                    padding: EdgeInsets.zero,
                  ),
                  Text('Suggest a category or app'),
                ],
              ),
            );
          });
  }

  Widget _presetsSelector(ContentFilterState state) {
    return SizedBox(
      width: double.infinity,
      height: 80,
      child: Center(
        child: ListView.separated(
          itemBuilder: (context, index) => InkWell(
              onTap: () {
                setState(() {
                  int prevIndex = _presets.indexWhere((element) =>
                      element.id == state.selectedSecureProfile!.id);
                  if (prevIndex != -1) {
                    final latest = _presets
                        .firstWhere((element) =>
                            element.id == state.selectedSecureProfile!.id)
                        .copyWith(
                            securityCategories: state
                                .selectedSecureProfile!.securityCategories);
                    _presets[prevIndex] = latest;
                  }
                  if (state.selectedSecureProfile != _presets[index]) {
                    context
                        .read<ContentFilterCubit>()
                        .selectSecureProfile(_presets[index]);
                  }
                });
              },
              child: _presetItem(state, _presets[index], true)),
          separatorBuilder: (_, __) => SizedBox(
            width: 16,
          ),
          itemCount: _presets.length,
          scrollDirection: Axis.horizontal,
          shrinkWrap: true,
        ),
      ),
    );
  }

  Widget _presetItem(
      ContentFilterState state, CFSecureProfile preset, bool isSelected) {
    return Column(
      children: [
        Hero(
          tag: 'preset_${preset.name}',
          child: Container(
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: state.selectedSecureProfile?.id == preset.id
                        ? Colors.white
                        : SecurityProfileManager.colorMapping(preset.id),
                    width: 3)),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: SecurityProfileManager.colorMapping(preset.id),
              ),
              width: 49,
              height: 49,
            ),
          ),
        ),
        Text(preset.name)
      ],
    );
  }

  Widget _secureCategoryList(ContentFilterState state) {
    return Column(
      children: [
        ...?state.selectedSecureProfile?.securityCategories
            .where((category) => category.id != "SECURITYRISK")
            .map((category) => InkWell(
                onTap: () async {
                  final newCategory = await showPopup(
                      ref: ref,
                      config: CFFilterCategoryPath()
                        ..args = {'selected': category}) as CFSecureCategory;
                  final index = state.selectedSecureProfile?.securityCategories
                          .indexOf(category) ??
                      -1;
                  if (index != -1) {
                    final list = List<CFSecureCategory>.from(
                        state.selectedSecureProfile?.securityCategories ?? []);
                    setState(() {
                      list.replaceRange(index, index + 1, [newCategory]);
                      context.read<ContentFilterCubit>().selectSecureProfile(
                          state.selectedSecureProfile!
                              .copyWith(securityCategories: list));
                    });
                  }
                },
                child: FilterItem(
                  name: category.name,
                  status: _checkStatus(category),
                )))
      ],
    );
  }

  FilterStatus _checkStatus(CFSecureCategory category) {
    return category.apps.fold<FilterStatus>(
        category.status,
        (value, element) =>
            (value != FilterStatus.force && value != element.status)
                ? FilterStatus.someAllowed
                : value);
  }
}

class FilterItem extends ConsumerWidget {
  const FilterItem({Key? key, required this.name, required this.status})
      : super(key: key);

  final String name;
  final FilterStatus status;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return (Row(
      children: [
        Icon(Icons.add),
        box8(),
        Expanded(child: Text(name)),
        createStatusButton(context, status),
      ],
    ));
  }
}
