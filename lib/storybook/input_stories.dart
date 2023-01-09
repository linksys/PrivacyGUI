part of 'storybook.dart';

Iterable<Story> inputStories() {
  return [
    Story(
      name: 'Input/Pin code input',
      description: 'A custom Text widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPinCodeInput(
              length: 4,
              onChanged: (value) {},
              onCompleted: (value) {},
            ),
          ],
        ),
      ),
    ),
    Story(
      name: 'Input/Search bar',
      description: 'A custom search bar widget used in app',
      builder: (context) => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppPinCodeInput(
              length: 4,
              enabled: false,
              onChanged: (value) {},
              onCompleted: (value) {},
            ),
            const AppGap.big(),
            AppSearchBar(
              hint: 'Search',
            ),
          ],
        ),
      ),
    ),
  ];
}
