
import 'package:flutter/widgets.dart';
import 'package:linksys_moab/page/dashboard/view/content_filtering/_content_filtering.dart';
import 'package:linksys_moab/route/_route.dart';


import '_model.dart';

class ContentFilterPath extends DashboardPath {
  @override
  Widget buildPage(NavigationCubit cubit) {
    switch (runtimeType) {
      case ContentFilteringOverviewPath:
        return ContentFilterOverviewView(
          args: args,
          next: next,
        );
      case CFPresetsPath:
        return ContentFilteringPresetsView(
          args: args,
          next: next,
        );
      case CFFilterCategoryPath:
        return ContentFilteringCategoryView(
          args: args,
          next: next,
        );
      case CFFilteredContentPath:
        return const FilteredContentView();
      case CFAppSearchPath:
        return AppSignatureSearchView(
          args: args,
          next: next,
        );
      default:
        return Center();
    }
  }
}

class ContentFilteringOverviewPath extends ContentFilterPath {}

class CFPresetsPath extends ContentFilterPath {}

class CFFilterCategoryPath extends ContentFilterPath with ReturnablePath {
  @override
  PageConfig get pageConfig => super.pageConfig..isFullScreenDialog = true;
}
class CFFilteredContentPath extends ContentFilterPath {}

class CFAppSearchPath extends ContentFilterPath {}