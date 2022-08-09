import 'dart:ui';

import 'package:flutter/material.dart';

class BasePageView extends StatelessWidget {
  static const _containerPadding = EdgeInsets.fromLTRB(24, 0, 24, 30);
  static const _noPadding = EdgeInsets.all(0);

  final AppBar? appBar;
  final Widget? child;
  final EdgeInsets? padding;
  final bool? scrollable;
  final Widget? bottomSheet;
  final Widget? bottomNavigationBar;

  BasePageView.noNavigationBar({
    Key? key,
    this.child,
    this.padding = _containerPadding,
    this.scrollable = false,
    this.bottomNavigationBar,
  })  : appBar = AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        bottomSheet = null,
        super(key: key);

  BasePageView.withCloseButton(
    BuildContext context, {
    Key? key,
    this.child,
    this.padding = _containerPadding,
    this.scrollable = false,
  })  : appBar = AppBar(
          backgroundColor: Colors.transparent,
          iconTheme:
              IconThemeData(color: Theme.of(context).colorScheme.primary),
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: () =>
                  Navigator.pop(context), // TODO use NavigationCubit
            )
          ],
        ),
        bottomSheet = null,
        bottomNavigationBar = null,
        super(key: key);

  BasePageView.bottomSheetModal({
    Key? key,
    required this.bottomSheet,
    this.padding = _containerPadding,
    this.scrollable = false,
  })  : appBar = AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        child = BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        ),
        bottomNavigationBar = null,
        super(key: key);

  const BasePageView.onDashboardSecondary({
    Key? key,
    this.appBar,
    this.child,
    this.padding = _noPadding,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.scrollable = false,
  }) : super(key: key);

  const BasePageView({
    Key? key,
    this.appBar,
    this.child,
    this.padding = _containerPadding,
    this.bottomSheet,
    this.bottomNavigationBar,
    this.scrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bottomSheet == null
          ? Theme.of(context).scaffoldBackgroundColor
          : Colors.transparent,
      appBar: appBar ??
          AppBar(
            backgroundColor: Colors.transparent,
            iconTheme:
                IconThemeData(color: Theme.of(context).colorScheme.primary),
            elevation: 0,
          ),
      body: SafeArea(
        child: scrollable! ? _scrollableView() : _view(),
      ),
      bottomSheet: bottomSheet,
      bottomNavigationBar: bottomNavigationBar,
    );
  }

  Widget _view() {
    return Container(
      padding: padding,
      child: child,
    );
  }

  Widget _scrollableView() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints viewportConstraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: viewportConstraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Container(padding: padding, child: child),
            ),
          ),
        );
      },
    );
  }
}
