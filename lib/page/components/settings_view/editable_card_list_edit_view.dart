import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:privacy_gui/page/components/styled/styled_page_view.dart';
import 'package:privacy_gui/page/components/views/arguments_view.dart';
import 'package:privacygui_widgets/widgets/card/card.dart';

class EditableCardListEditView extends ArgumentsBaseConsumerStatefulView {
  const EditableCardListEditView({
    super.key,
    super.args,
  });

  @override
  ConsumerState<EditableCardListEditView> createState() =>
      _EditableCardListEditViewState();
}

class _EditableCardListEditViewState
    extends ConsumerState<EditableCardListEditView> {
  String? _title;
  dynamic _data;
  Widget Function(BuildContext, dynamic)? _builder;
  bool Function(dynamic)? _isDataValid;
  @override
  void initState() {
    super.initState();
    _title = widget.args['title'];
    _data = widget.args['data'];
    _builder = widget.args['builder'] as Widget Function(BuildContext, dynamic);
    _isDataValid = widget.args['validator'];
  }

  @override
  Widget build(BuildContext context) {
    return StyledAppPageView(
        bottomBar: PageBottomBar(
            isPositiveEnabled: _isDataValid?.call(_data) ?? false,
            onPositiveTap: () {
              context.pop(true);
            }),
        title: _title,
        child: (context, constraints) => AppCard(
                child: _builder!.call(
              context,
              _data!,
            )));
  }
}
