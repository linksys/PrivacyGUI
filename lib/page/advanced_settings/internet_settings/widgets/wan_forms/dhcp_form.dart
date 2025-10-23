import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:privacy_gui/page/advanced_settings/internet_settings/widgets/wan_forms/base_wan_form.dart';

class DHCPForm extends BaseWanForm {
  const DHCPForm({
    Key? key,
    required super.isEditing,
  }) : super(key: key);

  @override
  ConsumerState<DHCPForm> createState() => _DHCPFormState();
}

class _DHCPFormState extends BaseWanFormState<DHCPForm> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget buildDisplayFields(BuildContext context) {
    return const SizedBox.shrink();
  }

  @override
  Widget buildEditableFields(BuildContext context) {
    return const SizedBox.shrink();
  }
}
