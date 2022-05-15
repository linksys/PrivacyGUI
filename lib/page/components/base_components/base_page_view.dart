import 'package:flutter/material.dart';

class BasePageView extends StatelessWidget {
  final AppBar? appBar;
  final Widget? child;
  final EdgeInsets? padding;
  final bool? scrollable;

  const BasePageView({
    Key? key,
    this.appBar,
    this.child,
    this.padding = const EdgeInsets.fromLTRB(24, 0, 24, 30),
    this.scrollable = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
