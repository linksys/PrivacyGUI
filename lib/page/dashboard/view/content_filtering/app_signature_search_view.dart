import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:linksys_moab/bloc/content_filter/cubit.dart';
import 'package:linksys_moab/model/app_signature.dart';
import 'package:linksys_moab/model/group_profile.dart';
import 'package:linksys_moab/model/secure_profile.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/customs/app_icon_view.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';
import 'package:linksys_moab/page/components/views/arguments_view.dart';
import 'package:linksys_moab/security/security_profile_manager.dart';
import 'package:linksys_moab/util/logger.dart';

import '_content_filtering.dart';

class AppSignatureSearchView extends ArgumentsStatefulView {
  const AppSignatureSearchView({super.key, super.args, super.next});

  @override
  State<AppSignatureSearchView> createState() => _AppSignatureSearchViewState();
}

class _AppSignatureSearchViewState extends State<AppSignatureSearchView> {
  final _searchTextController = TextEditingController();
  List<CloudAppSignature> _data = [];
  List<CloudAppSignature> _searchResult = [];
  final Debounce _debounce = Debounce(milliseconds: 1000);
  bool _isLoading = false;

  @override
  void initState() {
    setState(() {
      _isLoading = true;
    });
    SecurityProfileManager.instance().fetchAppSignature().then((value) {
      setState(() {
        _data = value;
        _isLoading = false;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _appBar(),
          SliverList(
            delegate: _mySliverChildBuilderDelegate(),
            // delegate: _mySliverChildListDelegate(),
          ),
        ],
      ),
    );
  }

  Widget _appBar() {
    return SliverAppBar(
      title: Text('App Search'),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
      ),
    );
  }

  Widget _buildSearchInput() {
    return _isLoading
        ? CircularProgressIndicator()
        : InputField(
            titleText: '',
            controller: _searchTextController,
            customPrimaryColor: Colors.black,
            onChanged: (value) {
              if (value.length < 3) {
                return;
              }
              _debounce.run(() {
                logger.d('Start search: $value');
                setState(() {
                  _searchResult = _data
                      .where((element) => element.name
                          .toLowerCase()
                          .contains(value.toLowerCase()))
                      .toList();
                });
              });
            },
            suffixIcon: IconButton(
              icon: Icon(
                _searchTextController.text.isEmpty ? Icons.search : Icons.close,
              ),
              onPressed: _searchTextController.text.isEmpty
                  ? null
                  : () {
                      setState(() {
                        _searchTextController.text = '';
                        _searchResult = [];
                      });
                    },
            ),
          );
  }

  final List<String> entries = <String>['A', 'B', 'C'];
  final List<int> colorCodes = <int>[600, 500, 100];

  Widget _buildSearchResult() {
    return _searchResult.isEmpty
        ? Center()
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Results'),
              ..._searchResult
                  .map(
                    (e) => CFAppSignature(
                        name: e.name,
                        icon: e.id,
                        category: e.categoryName,
                        status: context
                            .read<ContentFilterCubit>()
                            .checkSearchAppSignatureStatus(e.id),
                        raw: [e]),
                  )
                  .map((e) => ListTile(
                      leading: AppIconView(
                        appId: e.icon,
                      ),
                      title: Text(e.name),
                      subtitle: Text(e.category),
                      trailing:
                          createStatusButton(context, e.status, onPressed: () {
                        context.read<ContentFilterCubit>().updateSearchAppSignature(
                            e.copyWith(
                                status:
                                    CFSecureCategory.switchStatus(e.status)));
                        setState(() {});
                      })))
            ],
          );
  }

  _mySliverChildBuilderDelegate() {
    return SliverChildListDelegate([
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            box16(),
            _buildSearchInput(),
            box36(),
            _buildSearchResult(),
          ],
        ),
      ),
    ]);
  }
}

class Debounce {
  final int milliseconds;
  VoidCallback? action;
  Timer? _timer;

  Debounce({required this.milliseconds, this.action});

  run(VoidCallback action) {
    _timer?.cancel();
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }
}
