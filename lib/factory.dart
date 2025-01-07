import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/constants/jnap_const.dart';
import 'package:privacy_gui/core/jnap/actions/better_action.dart';
import 'package:privacy_gui/core/jnap/models/power_table_settings.dart';
import 'package:privacy_gui/core/jnap/router_repository.dart';
import 'package:privacy_gui/page/instant_admin/providers/power_table_provider.dart';
import 'package:privacy_gui/utils.dart';
import 'package:privacygui_widgets/widgets/_widgets.dart';

class FactoryView extends ConsumerStatefulWidget {
  const FactoryView({super.key});

  @override
  ConsumerState<FactoryView> createState() => _FactoryViewState();
}

class _FactoryViewState extends ConsumerState<FactoryView> {
  late final TextEditingController _editingController;
  List<PowerTableCountries> powerTable = [];
  PowerTableCountries? _selected;

  @override
  void initState() {
    super.initState();
    _editingController = TextEditingController()..text = 'admin';
  }

  @override
  void dispose() {
    _editingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AppText.titleMedium('Factory Settings'),
        AppGap.large2(),
        AppPasswordField(
          border: const OutlineInputBorder(),
          controller: _editingController,
        ),
        Expanded(
          child: ListView.builder(
              itemCount: powerTable.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: AppText.bodyLarge(
                      powerTable[index].resolveDisplayText(context)),
                  trailing: powerTable[index] == _selected
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    setState(() {
                      _selected = powerTable[index];
                    });
                  },
                );
              }),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            AppFilledButton(
              'Get Power Table',
              onTap: () {
                final repo = ref.read(routerRepositoryProvider);
                repo.send(JNAPAction.getPowerTableSettings, extraHeaders: {
                  kJNAPAuthorization:
                      'Basic ${Utils.stringBase64Encode('admin:${_editingController.text}')}'
                }).then((success) {
                  final result = PowerTableSettings.fromMap(success.output);
                  setState(() {
                    powerTable = result.supportedCountries
                        .map((e) => PowerTableCountries.resolve(e))
                        .toList();
                  });
                });
              },
            ),
            AppFilledButton(
              'Set Country',
              onTap: _selected == null
                  ? null
                  : () {
                      final repo = ref.read(routerRepositoryProvider);
                      repo.send(
                        JNAPAction.setPowerTableSettings,
                        extraHeaders: {
                          kJNAPAuthorization:
                              'Basic ${Utils.stringBase64Encode('admin:${_editingController.text}')}'
                        },
                        data: {'country': _selected?.name.toUpperCase()},
                      );
                    },
            )
          ],
        ),
        AppGap.large2(),
      ],
    );
  }
}
