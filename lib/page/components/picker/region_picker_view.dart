import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/bloc/auth/auth_provider.dart';
import 'package:linksys_moab/network/http/model/region_code.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/base_components/progress_bars/full_screen_spinner.dart';
import 'package:linksys_moab/page/components/layouts/layout.dart';

import '../../../route/navigations_notifier.dart';

class RegionPickerView extends ConsumerStatefulWidget {
  const RegionPickerView({Key? key}) : super(key: key);

  @override
  _RegionPickerViewState createState() => _RegionPickerViewState();
}

class _RegionPickerViewState extends ConsumerState<RegionPickerView> {
  @override
  Widget build(BuildContext context) {
    return BasePageView.withCloseButton(
      context,
      ref,
      child: BasicLayout(
        header: const BasicHeader(
          title: 'Select region',
          description:
              'If your region is not listed, we can’t send text messages in your region yet.',
        ),
        content: FutureBuilder<List<RegionCode>>(
            future: ref.read(authProvider.notifier).fetchRegionCodes(),
            initialData: null,
            builder: (context, snapshot) {
              return snapshot.hasData
                  ? ListView.builder(
                      itemCount: snapshot.data?.length,
                      itemBuilder: (context, index) => InkWell(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              child: Row(
                                children: [
                                  Text(
                                    '${snapshot.data?[index].flagCode}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .displayLarge
                                        ?.copyWith(
                                          color: Theme.of(context).primaryColor,
                                        ),
                                  ),
                                  const SizedBox(
                                    width: 10,
                                  ),
                                  Text(
                                    '${snapshot.data?[index].countryName} +${snapshot.data?[index].countryCallingCode}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyLarge
                                        ?.copyWith(
                                            color:
                                                Theme.of(context).primaryColor),
                                  ),
                                ],
                              ),
                            ),
                            onTap: () {
                              ref
                                  .read(navigationsProvider.notifier)
                                  .popWithResult(snapshot.data?[index]);
                            },
                          ))
                  : const FullScreenSpinner();
            }),
      ),
    );
  }
}
