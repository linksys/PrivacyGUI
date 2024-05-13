import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:linksys_app/core/utils/extension.dart';
import 'package:linksys_app/localization/localization_hook.dart';
import 'package:linksys_app/page/advanced_settings/local_network_settings/_local_network_settings.dart';
import 'package:linksys_app/page/components/styled/styled_page_view.dart';
import 'package:linksys_app/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/widgets/_widgets.dart';
import 'package:linksys_widgets/widgets/input_field/ip_form_field.dart';
import 'package:linksys_widgets/widgets/page/layout/basic_layout.dart';

class LocalNetworkEditView extends ArgumentsConsumerStatefulView {
  const LocalNetworkEditView({
    Key? key,
    super.args,
  }) : super(key: key);

  @override
  ConsumerState<LocalNetworkEditView> createState() =>
      _LocalNetworkEditViewState();
}

class _LocalNetworkEditViewState extends ConsumerState<LocalNetworkEditView> {
  String _viewType = '';
  String _originalValue = '';
  String? _errorDesc;
  bool _enableButton = false;
  void Function() _onSave = () {};
  final _textController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _viewType = widget.args['viewType'] ?? '';
    _originalValue = getCurrentValue(_viewType);
    _textController.text = _originalValue;
    _setOnSaveFunction();
  }

  @override
  void dispose() {
    super.dispose();

    _textController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
      scrollable: true,
      title: getTitle(_viewType),
      bottomBar: PageBottomBar(
        isPositiveEnabled: _enableButton,
        onPositiveTap: _onSave,
      ),
      child: AppBasicLayout(
        content: _content(_viewType),
      ),
    );
  }

  String getCurrentValue(String viewType) {
    final state = ref.read(localNetworkSettingProvider);
    return switch (viewType) {
      'hostName' => state.hostName,
      'ipAddress' => state.ipAddress,
      'subnetMask' => state.subnetMask,
      _ => ''
    };
  }

  String getTitle(String viewType) {
    return switch (viewType) {
      'hostName' => loc(context).hostName,
      'ipAddress' => loc(context).ipAddress.capitalizeWords(),
      'subnetMask' => loc(context).subnetMask.capitalizeWords(),
      _ => ''
    };
  }

  void _setOnSaveFunction() {
    _onSave = switch (_viewType) {
      'hostName' => () {
          ref
              .read(localNetworkSettingProvider.notifier)
              .updateHostName(_textController.text);
          context.pop();
        },
      'ipAddress' => () {
          final state = ref.read(localNetworkSettingProvider);
          // Host IP input finishes
          final result = ref
              .read(localNetworkSettingProvider.notifier)
              .routerIpAddressFinished(
                _textController.text,
                state,
              );
          if (result.$1 == false) {
            setState(() {
              _errorDesc = 'Invalid IP address';
            });
          } else {
            ref
                .read(localNetworkSettingProvider.notifier)
                .updateState(result.$2);
            context.pop();
          }
        },
      'subnetMask' => () {
          final state = ref.read(localNetworkSettingProvider);
          // Host IP input finishes
          final result =
              ref.read(localNetworkSettingProvider.notifier).subnetMaskFinished(
                    _textController.text,
                    state,
                  );
          if (result.$1 == false) {
            setState(() {
              _errorDesc = 'Invalid subnet mask';
            });
          } else {
            ref
                .read(localNetworkSettingProvider.notifier)
                .updateState(result.$2);
            context.pop();
          }
        },
      _ => () {}
    };
  }

  Widget _content(String viewType) {
    return switch (viewType) {
      'hostName' => hostNameView(),
      'ipAddress' => ipAddressView(),
      'subnetMask' => subnetMaskView(),
      _ => throw Exception('Error view type')
    };
  }

  Widget hostNameView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppTextField(
          headerText: loc(context).hostName,
          controller: _textController,
          errorText: _errorDesc,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _enableButton = false;
                _errorDesc = 'Host name can not be empty.';
              });
            } else if (value != _originalValue) {
              setState(() {
                _enableButton = true;
                _errorDesc = null;
              });
            } else {
              setState(() {
                _enableButton = false;
                _errorDesc = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget ipAddressView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIPFormField(
          header: AppText.bodySmall(loc(context).ipAddress.capitalizeWords()),
          controller: _textController,
          errorText: _errorDesc,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _enableButton = false;
                _errorDesc = 'IP address can not be empty.';
              });
            } else if (value != _originalValue) {
              setState(() {
                _enableButton = true;
                _errorDesc = null;
              });
            } else {
              setState(() {
                _enableButton = false;
                _errorDesc = null;
              });
            }
          },
        ),
      ],
    );
  }

  Widget subnetMaskView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppIPFormField(
          header: AppText.bodySmall(loc(context).ipAddress.capitalizeWords()),
          octet1ReadOnly: true,
          octet2ReadOnly: true,
          controller: _textController,
          errorText: _errorDesc,
          border: const OutlineInputBorder(),
          onChanged: (value) {
            if (value.isEmpty) {
              setState(() {
                _enableButton = false;
                _errorDesc = 'IP address can not be empty.';
              });
            } else if (value != _originalValue) {
              setState(() {
                _enableButton = true;
                _errorDesc = null;
              });
            } else {
              setState(() {
                _enableButton = false;
                _errorDesc = null;
              });
            }
          },
        ),
      ],
    );
  }
}
