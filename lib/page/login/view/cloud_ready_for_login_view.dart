import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/localization/localization_hook.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_widgets/widgets/page/base_page_view.dart';
import 'package:linksys_widgets/widgets/progress_bar/full_screen_spinner.dart';


class CloudReadyForLoginView extends ArgumentsConsumerStatefulView {
  const CloudReadyForLoginView({Key? key, super.args, super.next})
      : super(key: key);

  @override
  _CloudReadyForLoginViewState createState() => _CloudReadyForLoginViewState();
}

class _CloudReadyForLoginViewState
    extends ConsumerState<CloudReadyForLoginView> {
  @override
  void initState() {
    super.initState();
    _processLogin();
  }

  @override
  Widget build(BuildContext context) {
    return AppPageView.noNavigationBar(
              child: AppFullScreenSpinner(
                  text: getAppLocalizations(context).processing),
            );
  }

  Future<void> _processLogin() async {
    // context.read<AuthBloc>().add(CloudLogin());
  }
}
