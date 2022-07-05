
import 'package:flutter/widgets.dart';
import 'package:moab_poc/page/components/base_components/base_components.dart';
import 'package:moab_poc/page/components/layouts/layout.dart';
import 'package:moab_poc/page/components/views/arguments_view.dart';

class DashboardView extends ArgumentsStatefulView {
  const DashboardView({Key? key}) : super(key: key);

  @override
  _DashboardViewState createState() => _DashboardViewState();
}

class _DashboardViewState extends State<DashboardView> {


  @override
  void initState() {

  }

  @override
  Widget build(BuildContext context) {
    return _contentView();
  }

  Widget _contentView() {
    return BasePageView(
      child: BasicLayout(
        alignment: CrossAxisAlignment.start,
        header: const BasicHeader(
          title: 'Dashboard',
        ),
        content: Column(
          children: const [
            TitleText(text: 'Dashboard'),
          ],
        ),
      ),
    );
  }
}