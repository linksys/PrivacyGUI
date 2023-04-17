import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:linksys_moab/page/components/base_components/base_components.dart';
import 'package:linksys_moab/page/components/shortcuts/sized_box.dart';

enum FilteredContentType {
  category,
  timeline,
}

class CFRecord {
  const CFRecord({
    required this.description,
    required this.categoryName,
    required this.categoryImagePath,
    required this.date,
    required this.time,
    required this.profile,
  });

  final String description;
  final String categoryName;
  final String categoryImagePath;
  final String date;
  final String time;
  final CFProfile profile;
}

class CFProfile {
  const CFProfile(
    this.imagePath,
    this.name,
  );

  final String imagePath;
  final String name;
}

class FilteredContentView extends ConsumerStatefulWidget {
  const FilteredContentView({Key? key}) : super(key: key);

  @override
  ConsumerState<FilteredContentView> createState() =>
      _FilteredContentViewState();
}

class _FilteredContentViewState extends ConsumerState<FilteredContentView> {
  FilteredContentType? _selectedSegment = FilteredContentType.category;

  //TODO: Remove the dummy data
  List<Map<String, String>> dummyCategories = [
    {
      'category': 'Mature topics',
      'number': '3',
    },
    {
      'category': 'Social media',
      'number': '3',
    },
    {
      'category': 'Streaming',
      'number': '1',
    },
  ];
  List<CFRecord> dummyRecords = [
    const CFRecord(
      description: 'MeetandGreetSingleGirls',
      categoryName: 'Mature topics',
      categoryImagePath: 'assets/images/icon_webpage.png',
      date: '2022/09/07',
      time: '11:20 pm',
      profile: CFProfile(
        'assets/images/sparker.png',
        'Timmy',
      ),
    ),
    const CFRecord(
      description: 'Facebook',
      categoryName: 'Social media',
      categoryImagePath: 'assets/images/icon_app_facebook.png',
      date: '2022/09/07',
      time: '10:20 pm',
      profile: CFProfile(
        'assets/images/sparker.png',
        'Timmy',
      ),
    ),
    const CFRecord(
      description: 'TikTok',
      categoryName: 'Social media',
      categoryImagePath: 'assets/images/icon_app_tiktok.png',
      date: '2022/09/06',
      time: '7:20 pm',
      profile: CFProfile(
        'assets/images/sparker.png',
        'Timmy',
      ),
    ),
    const CFRecord(
      description: 'Streamingsitehere',
      categoryName: 'Streaming',
      categoryImagePath: 'assets/images/icon_app_tiktok.png',
      date: '2022/09/05',
      time: '6:20 pm',
      profile: CFProfile(
        'assets/images/sparker.png',
        'Timmy',
      ),
    ),
  ];
  ////End of dummy data

  Widget _segmentControl() {
    return FractionallySizedBox(
      widthFactor: 1.0,
      child: CupertinoSlidingSegmentedControl<FilteredContentType>(
        groupValue: _selectedSegment,
        onValueChanged: (value) {
          setState(() {
            _selectedSegment = value;
          });
        },
        children: <FilteredContentType, Widget>{
          FilteredContentType.category: Container(
            child: Text(
              'Categories',
              style: Theme.of(context).textTheme.headline4?.copyWith(
                    color: Theme.of(context).primaryColor,
                  ),
            ),
            height: 36,
            alignment: Alignment.center,
          ),
          FilteredContentType.timeline: Text(
            'Timeline',
            style: Theme.of(context).textTheme.headline4?.copyWith(
                  color: Theme.of(context).primaryColor,
                ),
          ),
        },
      ),
    );
  }

  Widget _categoryPage() {
    return Expanded(
      child: ListView.builder(
        itemCount: dummyCategories.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dummyCategories[index]['category']!,
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Container(
                      height: 6,
                      width: double.infinity,
                      color: Colors.blue,
                    ),
                  ],
                ),
              ),
              box16(),
              Text(
                dummyCategories[index]['number']!,
                style: Theme.of(context).textTheme.headline4?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _timelinePage() {
    return Expanded(
      child: ListView.builder(
        itemCount: dummyRecords.length,
        itemBuilder: (context, index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Image.asset(dummyRecords[index].categoryImagePath),
              box12(),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dummyRecords[index].description,
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    box4(),
                    Text(
                      dummyRecords[index].categoryName,
                      style: Theme.of(context).textTheme.headline4?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ],
                ),
              ),
              box16(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    dummyRecords[index].date,
                    style: Theme.of(context).textTheme.headline4?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  box4(),
                  Row(
                    children: [
                      Image.asset(
                        dummyRecords[index].profile.imagePath,
                        height: 16,
                        width: 16,
                      ),
                      Text(
                        dummyRecords[index].profile.name,
                        style: Theme.of(context).textTheme.headline4?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                      )
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BasePageView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _segmentControl(),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Sep 1-7',
              style: Theme.of(context).textTheme.headline1?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
            ),
          ),
          _selectedSegment == FilteredContentType.category
              ? _categoryPage()
              : _timelinePage(),
        ],
      ),
    );
  }
}
