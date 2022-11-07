import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/add_nodes/cubit.dart';
import 'package:linksys_moab/bloc/add_nodes/state.dart';
import 'package:linksys_moab/bloc/setup/event.dart';
import 'package:linksys_moab/bloc/setup/state.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/base_components/base_page_view.dart';
import 'package:linksys_moab/page/components/base_components/text/description_text.dart';
import 'package:linksys_moab/page/components/layouts/basic_header.dart';
import 'package:linksys_moab/page/components/layouts/basic_layout.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/route/_route.dart';
import 'package:linksys_moab/util/logger.dart';

import '../../../bloc/setup/bloc.dart';
import '../../components/base_components/button/primary_button.dart';
import '../../components/base_components/button/simple_text_button.dart';
import 'package:linksys_moab/route/model/_model.dart';

class SetupNodeListView extends ArgumentsStatefulView {
  const SetupNodeListView({
    Key? key,
    super.next,
    super.args,
  }) : super(key: key);

  @override
  State<SetupNodeListView> createState() => _SetupNodeListViewState();
}

class _SetupNodeListViewState extends State<SetupNodeListView> {
  bool _isFetchNodes = false;
  late final AddNodesCubit _cubit;

  @override
  void initState() {
    _cubit = context.read<AddNodesCubit>();
    if (widget.args['init'] as bool? ?? true) {
      _cubit.init();
    }

    final mode = widget.args['mode'] as AddNodesMode?;
    if (mode != null) {
      _cubit.setMode(mode);
    }

    setState(() {
      _isFetchNodes = true;
    });
    _cubit.fetchDevices().then((_) {
      setState(() {
        _isFetchNodes = false;
      });
    });
    context
        .read<SetupBloc>()
        .add(const ResumePointChanged(status: SetupResumePoint.addChildNode));
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    double width = 200;
    return BlocBuilder<AddNodesCubit, AddNodesState>(builder: (context, state) {
      return BasePageView(
        scrollable: true,
        child: BasicLayout(
          header: BasicHeader(
            title: getAppLocalizations(context).good_work,
            description:
                getAppLocalizations(context).nodes_success_multi_description,
          ),
          content: Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 57),
                // Center(
                //     child: GestureDetector(
                //         onTap: () {
                //           NavigationCubit.of(context)
                //               .push(SetupParentLocationPath());
                //         },
                //         child: Image.asset(
                //           'assets/images/nodes_topology.png',
                //           width: width,
                //           height: width,
                //         ))),
                _isFetchNodes
                    ? const CircularProgressIndicator()
                    : Column(
                        children: [
                          ...state.properties.map((e) => Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: ListTile(
                                  leading: Container(
                                    width: 36,
                                    height: 80,
                                    padding: EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      // borderRadius: BorderRadius.circular(100),
                                      color: Colors.grey,
                                    ),
                                  ),
                                  title: Text(e.location ?? ''),
                                  trailing: Container(
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.grey),
                                    child: IconButton(
                                        onPressed: () async {
                                          final String? result =
                                              await NavigationCubit.of(context)
                                                  .pushAndWait(
                                                      SetupParentLocationPath());
                                          if (result != null) {
                                            logger.d('Set location: $result');
                                            _cubit.updateNodeLocation(
                                                e.deviceId, result);
                                          }
                                        },
                                        icon: const Icon(
                                          Icons.edit,
                                          size: 24,
                                          color: Colors.white,
                                        )),
                                  ),
                                ),
                              ))
                        ],
                      ),
                if (state.mode == AddNodesMode.addNodeOnly)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(0, 48, 0, 48), // TODO
                    child: Center(
                      child: SimpleTextButton(
                          text: getAppLocalizations(context).add_a_node,
                          onPressed: () {
                            NavigationCubit.of(context)
                                .popToOrPush(SetupNthChildPlacePath()
                                  ..next =
                                      NavigationCubit.of(context).currentPath()
                                  ..args = {'isAddonsNode': true});
                          }),
                    ),
                  ),
              ],
            ),
          ),
          footer: Column(
            children: [
              state.mode == AddNodesMode.setup
                  ? _createButtonForSetup(state)
                  : _createButtonForAddNodes(state),
            ],
          ),
          crossAxisAlignment: CrossAxisAlignment.start,
        ),
      );
    });
  }

  Widget _createButtonForSetup(AddNodesState state) {
    return PrimaryButton(
      text: getAppLocalizations(context)
          .nodes_success_multi_add_wifi_name_button_text,
      onPress: () {
        context
            .read<SetupBloc>()
            .add(SetRouterProperties(properties: state.properties));
        NavigationCubit.of(context).push(SetupCustomizeSSIDPath());
      },
    );
  }

  Widget _createButtonForAddNodes(AddNodesState state) {
    return PrimaryButton(
      text: getAppLocalizations(context).save,
      onPress: () async {
        await _cubit.save();
        NavigationCubit.of(context).popToOrPush(widget.next ?? UnknownPath());
      },
    );
  }
}
