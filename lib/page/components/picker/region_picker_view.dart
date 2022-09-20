import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/auth/bloc.dart';
import 'package:linksys_moab/network/http/model/region_code.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';
import 'package:linksys_moab/route/navigation_cubit.dart';

class RegionPickerView extends StatefulWidget {
  const RegionPickerView({Key? key}) : super(key: key);

  @override
  _RegionPickerViewState createState() => _RegionPickerViewState();
}

class _RegionPickerViewState extends State<RegionPickerView> {

  @override
  Widget build(BuildContext context) {
    return BasePageView.withCloseButton(
      context,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Select region',
          description: 'If your region is not listed, we can’t send text messages in your region yet.',
        ),
        content: FutureBuilder<List<RegionCode>>(
          future: context.read<AuthBloc>().fetchRegionCodes(),
          initialData: null,
          builder: (context, snapshot) {
            return snapshot.hasData ?
              ListView.builder(
                itemCount: snapshot.data?.length,
                itemBuilder: (context, index) => InkWell(
                  child: Container(
                    child: Row(
                      children: [
                        Text(
                          '${snapshot.data?[index].flagCode}',
                          style: Theme.of(context).textTheme.headline1?.copyWith(
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        const SizedBox(
                          width: 10,
                        ),
                        Text(
                          '${snapshot.data?[index].countryName} +${snapshot.data?[index].countryCallingCode}',
                          style: Theme.of(context).textTheme.bodyText1?.copyWith(
                              color: Theme.of(context).primaryColor
                          ),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  onTap: () {
                    NavigationCubit.of(context).popWithResult(snapshot.data?[index]);
                  },
                )
            ) :
            const FullScreenSpinner();
          }
        ),
      ),
    );
  }
}

